const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onCall } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { MercadoPagoConfig, Payment } = require('mercadopago');
const admin = require('firebase-admin');

const mpAccessToken = defineSecret('MP_ACCESS_TOKEN');

admin.initializeApp();

/**
 * Triggered when a booking document is created or updated in the `bookings` collection.
 * Sends an FCM push notification to all admin users when a new active booking is registered.
 *
 * Fires on:
 *   - Document created with status != 'cancelled'
 *   - Document updated where status changed FROM 'cancelled' TO 'pending'|'confirmed'
 *
 * Firestore structure used:
 *   /users/{userId}                   — { role: "admin"|"client", displayName, ... }
 *   /users/{userId}/fcmTokens/{token} — { token, createdAt, platform }
 *   /bookings/{bookingId}             — { slotId, date, startTime, userDisplayName, status, ... }
 */
exports.notifyAdminNewBooking = onDocumentWritten('bookings/{bookingId}', async (event) => {
  const before = event.data.before?.data();
  const after = event.data.after?.data();

  if (!after) return; // document deleted — ignore

  const isActive = after.status !== 'cancelled';

  // Only notify on new active bookings:
  // - Document just created (no before) with active status
  // - Status changed from 'cancelled' to active (rebook)
  const isNewBooking = !before && isActive;
  const isRebook = before && before.status === 'cancelled' && isActive;

  if (!isNewBooking && !isRebook) {
    console.log(`Skipping — status: ${before?.status ?? 'new'} → ${after.status}`);
    return;
  }

  const clientName = after.userDisplayName || 'Cliente';
  const startTime = after.startTime || '';
  const date = after.date || '';

  // Only send to users with role == 'admin'
  const adminsSnap = await admin.firestore()
    .collection('users')
    .where('role', '==', 'admin')
    .get();

  if (adminsSnap.empty) {
    console.log('No admin users found — skipping notification');
    return;
  }

  // Collect all FCM tokens from all admin users
  const tokenEntries = []; // [{ token, userId }]
  for (const adminDoc of adminsSnap.docs) {
    const tokensSnap = await admin.firestore()
      .collection('users')
      .doc(adminDoc.id)
      .collection('fcmTokens')
      .get();

    for (const tokenDoc of tokensSnap.docs) {
      const token = tokenDoc.data().token;
      if (token) {
        tokenEntries.push({ token, userId: adminDoc.id });
      }
    }
  }

  if (tokenEntries.length === 0) {
    console.log('No admin FCM tokens found — skipping notification');
    return;
  }

  const tokens = tokenEntries.map((e) => e.token);
  const dateFormatted = date ? ` (${date})` : '';

  const bookingId = event.params.bookingId;
  const projectId = process.env.GCLOUD_PROJECT || 'vida-ativa-staging';
  const domain = projectId === 'vida-ativa-94ba0'
    ? 'https://vida-ativa-94ba0.web.app'
    : 'https://vida-ativa-staging.web.app';

  const multicastMessage = {
    notification: {
      title: isRebook ? 'Reserva Refeita' : 'Nova Reserva',
      body: `${clientName} — ${startTime}${dateFormatted}`,
    },
    data: {
      bookingId,
      date: date,
    },
    webpush: {
      fcmOptions: {
        link: `${domain}/admin`,
      },
    },
    tokens,
  };

  const response = await admin.messaging().sendEachForMulticast(multicastMessage);

  console.log(`FCM result: ${response.successCount} sent, ${response.failureCount} failed`);

  // Clean up invalid tokens to prevent accumulation
  const deletePromises = [];
  response.responses.forEach((resp, idx) => {
    if (!resp.success) {
      const errorCode = resp.error?.code;
      if (
        errorCode === 'messaging/invalid-registration-token' ||
        errorCode === 'messaging/registration-token-not-registered'
      ) {
        const { token, userId } = tokenEntries[idx];
        console.log(`Removing invalid token for user ${userId}`);
        deletePromises.push(
          admin.firestore()
            .collection('users')
            .doc(userId)
            .collection('fcmTokens')
            .doc(token)
            .delete()
        );
      }
    }
  });

  await Promise.all(deletePromises);
});

/**
 * Callable function: generates a Mercado Pago Pix QR code for a pending_payment booking.
 *
 * Request data: { bookingId: string }
 * Returns: { qrCode: string, qrCodeBase64: string, expiresAt: string (ISO 8601) }
 *
 * Flow:
 *  1. Validate auth + bookingId
 *  2. Read booking — verify status == 'pending_payment' AND userId == caller
 *  3. Call Mercado Pago Pix API (sandbox credentials from Secret Manager)
 *  4. Save PaymentRecord to /bookings/{bookingId}/payment/{txId}
 *  5. Update booking with paymentId + expiresAt
 *  6. Return QR data to Flutter
 *
 * Idempotency: bookingId used as MP idempotencyKey — duplicate calls return existing payment.
 * Secret: MP_ACCESS_TOKEN must be set in Firebase Secret Manager before deploying.
 */
exports.createPixPayment = onCall(
  { secrets: [mpAccessToken] },
  async (request) => {
    if (!request.auth) {
      throw new Error('unauthenticated');
    }

    const { bookingId } = request.data;
    if (!bookingId || typeof bookingId !== 'string') {
      throw new Error('invalid_argument: bookingId required');
    }

    const callerId = request.auth.uid;
    const db = admin.firestore();

    // 1. Read and validate booking
    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingSnap = await bookingRef.get();

    if (!bookingSnap.exists) {
      throw new Error('not_found: booking does not exist');
    }

    const booking = bookingSnap.data();

    if (booking.userId !== callerId) {
      throw new Error('permission_denied: booking belongs to different user');
    }

    if (booking.status !== 'pending_payment') {
      throw new Error(`invalid_status: expected pending_payment, got ${booking.status}`);
    }

    // 2. Get payer email for MP API (required even in sandbox)
    // Prefer Firebase Auth token email; fall back to user doc; then sandbox placeholder
    const payerEmail =
      request.auth.token.email ||
      `user_${callerId}@sandbox.mp.test`;

    // 3. Call Mercado Pago Pix API
    const client = new MercadoPagoConfig({
      accessToken: mpAccessToken.value(),
      options: { timeout: 10000 },
    });
    const paymentApi = new Payment(client);

    const now = new Date();
    const expiresAt = new Date(now.getTime() + 30 * 60 * 1000); // now + 30 min

    const result = await paymentApi.create({
      body: {
        transaction_amount: booking.price || 0,
        payment_method_id: 'pix',
        date_of_expiration: expiresAt.toISOString(),
        payer: { email: payerEmail },
        description: `Reserva ${bookingId}`,
        external_reference: bookingId,
      },
      requestOptions: { idempotencyKey: bookingId },
    });

    const txId = String(result.id);
    const qrCode = result.point_of_interaction.transaction_data.qr_code;
    const qrCodeBase64 = result.point_of_interaction.transaction_data.qr_code_base64;

    // 4. Save PaymentRecord subcollection
    await db
      .collection('bookings').doc(bookingId)
      .collection('payment').doc(txId)
      .set({
        qrCode,
        qrCodeBase64,
        expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    // 5. Update booking with paymentId and expiresAt
    await bookingRef.update({
      paymentId: txId,
      expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
    });

    // 6. Return QR data to Flutter
    return {
      qrCode,
      qrCodeBase64,
      expiresAt: expiresAt.toISOString(),
    };
  }
);

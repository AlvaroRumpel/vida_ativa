const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineSecret } = require('firebase-functions/params');
const { MercadoPagoConfig, Payment } = require('mercadopago');
const admin = require('firebase-admin');
const crypto = require('crypto');

const mpAccessToken = defineSecret('MP_ACCESS_TOKEN');
const mpWebhookSecret = defineSecret('MP_WEBHOOK_SECRET');

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
      throw new HttpsError('unauthenticated', 'Authentication required');
    }

    const { bookingId } = request.data;
    if (!bookingId || typeof bookingId !== 'string') {
      throw new HttpsError('invalid-argument', 'bookingId required');
    }

    const callerId = request.auth.uid;
    const db = admin.firestore();

    // 1. Read and validate booking
    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingSnap = await bookingRef.get();

    if (!bookingSnap.exists) {
      throw new HttpsError('not-found', 'Booking does not exist');
    }

    const booking = bookingSnap.data();

    if (booking.userId !== callerId) {
      throw new HttpsError('permission-denied', 'Booking belongs to different user');
    }

    if (booking.status !== 'pending_payment') {
      throw new HttpsError('failed-precondition', `Expected pending_payment, got ${booking.status}`);
    }

    const transactionAmount = typeof booking.price === 'number' && booking.price > 0
      ? booking.price
      : null;

    if (!transactionAmount) {
      console.error(`createPixPayment: booking ${bookingId} has no valid price (${booking.price})`);
      throw new HttpsError('failed-precondition', 'Booking has no valid price for payment');
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

    let result;
    try {
      result = await paymentApi.create({
        body: {
          transaction_amount: transactionAmount,
          payment_method_id: 'pix',
          date_of_expiration: expiresAt.toISOString(),
          payer: { email: payerEmail },
          description: `Reserva ${bookingId}`,
          external_reference: bookingId,
        },
        requestOptions: { idempotencyKey: bookingId },
      });
    } catch (mpError) {
      console.error('createPixPayment: Mercado Pago API error:', JSON.stringify(mpError));
      throw new HttpsError('internal', `Payment API error: ${mpError?.message || mpError}`);
    }

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

/**
 * Verifies the Mercado Pago webhook HMAC-SHA256 signature.
 * x-signature header format: "ts=<timestamp>,v1=<hmac>"
 * MP manifest format: "id:{dataId};request-id:{xRequestId};ts:{timestamp};"
 */
function verifyMpSignature(xSignature, xRequestId, dataId, secret) {
  if (!xSignature) return false;
  const parts = xSignature.split(',');
  if (parts.length < 2) return false;
  const tsValue = parts[0].replace('ts=', '');
  const v1Value = parts[1].replace('v1=', '');
  const manifest = `id:${dataId};request-id:${xRequestId};ts:${tsValue};`;
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(manifest)
    .digest('hex');
  try {
    return crypto.timingSafeEqual(
      Buffer.from(v1Value, 'hex'),
      Buffer.from(expectedSignature, 'hex')
    );
  } catch {
    return false;
  }
}

/**
 * HTTP trigger that receives Mercado Pago payment notifications (webhooks).
 * Returns 202 immediately to prevent MP retry, then processes the event.
 *
 * Flow:
 *  1. Return 202 immediately
 *  2. Verify HMAC-SHA256 signature using MP_WEBHOOK_SECRET
 *  3. Check idempotency — skip if transactionId already processed
 *  4. On approved payment: atomically update booking to confirmed + PaymentRecord to paid
 *
 * Secret: MP_WEBHOOK_SECRET must be set in Firebase Secret Manager before deploying.
 */
exports.handlePixWebhook = onRequest(
  { secrets: [mpWebhookSecret] },
  async (req, res) => {
    // 1. Return 202 immediately — prevent Mercado Pago retry
    res.status(202).send({ success: true });

    // 2. Only process POST
    if (req.method !== 'POST') return;

    // 3. Verify MP signature
    const xSignature = req.headers['x-signature'];
    const xRequestId = req.headers['x-request-id'] || '';
    const dataId = req.body?.data?.id;

    if (!dataId) {
      console.log('handlePixWebhook: missing data.id — ignoring');
      return;
    }

    const isValid = verifyMpSignature(
      xSignature,
      xRequestId,
      String(dataId),
      mpWebhookSecret.value()
    );
    if (!isValid) {
      console.error('handlePixWebhook: invalid signature — ignoring');
      return;
    }

    // 4. Only process payment.updated or payment.created events
    const action = req.body?.action;
    if (action !== 'payment.updated' && action !== 'payment.created') {
      console.log(`handlePixWebhook: action ${action} — ignoring`);
      return;
    }

    const transactionId = String(dataId);
    const bookingId = req.body?.data?.external_reference;

    if (!bookingId) {
      console.log('handlePixWebhook: missing external_reference — ignoring');
      return;
    }

    const db = admin.firestore();
    const bookingRef = db.collection('bookings').doc(bookingId);
    const paymentRef = bookingRef.collection('payment').doc(transactionId);

    // 5. Idempotency check
    const paymentSnap = await paymentRef.get();
    if (paymentSnap.exists && paymentSnap.data().status === 'paid') {
      console.log(`handlePixWebhook: transactionId ${transactionId} already processed — skipping`);
      return;
    }

    // 6. Only proceed on approved status
    const mpStatus = req.body?.data?.status;
    if (mpStatus !== 'approved') {
      console.log(`handlePixWebhook: payment status ${mpStatus} — not approved, ignoring`);
      return;
    }

    // 7. Atomic update: booking → confirmed, PaymentRecord → paid
    await db.runTransaction(async (transaction) => {
      const bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) return;
      const bookingData = bookingSnap.data();
      if (bookingData.status === 'confirmed') return; // already confirmed

      transaction.update(bookingRef, {
        status: 'confirmed',
        confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      if (paymentSnap.exists) {
        transaction.update(paymentRef, {
          status: 'paid',
          paidAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    });

    console.log(`handlePixWebhook: booking ${bookingId} confirmed via webhook`);
  }
);

/**
 * Scheduled function that runs every 15 minutes.
 * Finds all bookings where status == 'pending_payment' AND expiresAt < now,
 * and marks them as expired — freeing the slot for new bookings.
 */
exports.expireUnpaidBookings = onSchedule('every 15 minutes', async (event) => {
  const now = admin.firestore.Timestamp.now();
  const db = admin.firestore();

  const query = await db
    .collection('bookings')
    .where('status', '==', 'pending_payment')
    .where('expiresAt', '<', now)
    .get();

  if (query.empty) {
    console.log('expireUnpaidBookings: no expired bookings found');
    return;
  }

  // Process in batches of 500 (Firestore batch limit)
  const BATCH_SIZE = 500;
  const docs = query.docs;

  for (let i = 0; i < docs.length; i += BATCH_SIZE) {
    const batch = db.batch();
    const chunk = docs.slice(i, i + BATCH_SIZE);
    chunk.forEach((doc) => {
      batch.update(doc.ref, {
        status: 'expired',
        expiredAt: now,
      });
    });
    await batch.commit();
    console.log(`expireUnpaidBookings: expired ${chunk.length} bookings`);
  }

  console.log(`expireUnpaidBookings: total expired = ${docs.length}`);
});

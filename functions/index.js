const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineSecret } = require('firebase-functions/params');
const { MercadoPagoConfig, Order } = require('mercadopago');
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

  const isActive = after.status !== 'cancelled' && after.status !== 'refunded';

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

    // 0. Check if Pix is enabled
    const configSnap = await db.collection('config').doc('booking').get();
    const pixEnabled = configSnap.data()?.pixEnabled ?? true;
    if (!pixEnabled) {
      throw new HttpsError('failed-precondition', 'Pix payments are currently disabled');
    }

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

    // 2. Get payer email and name for MP API
    const payerEmail = request.auth.token.email || `user_${callerId}@example.com`;
    const displayName = (booking.userDisplayName || '').trim();
    const nameParts = displayName.split(/\s+/);
    const firstName = nameParts[0] || payerEmail;
    const lastName = nameParts.length > 1 ? nameParts.slice(1).join(' ') : firstName;

    // 3. Call Mercado Pago Orders API (required for Pix in Brazil sandbox)
    const client = new MercadoPagoConfig({
      accessToken: mpAccessToken.value(),
      options: { timeout: 10000 },
    });
    const orderApi = new Order(client);

    const now = new Date();
    const expiresAt = new Date(now.getTime() + 30 * 60 * 1000); // now + 30 min
    const amountStr = transactionAmount.toFixed(2);

    let result;
    try {
      result = await orderApi.create({
        body: {
          type: 'online',
          external_reference: bookingId,
          total_amount: amountStr,
          payer: { email: payerEmail, first_name: firstName, last_name: lastName },
          transactions: {
            payments: [{
              amount: amountStr,
              payment_method: {
                id: 'pix',
                type: 'bank_transfer',
              },
              expiration_time: 'PT30M',
            }],
          },
        },
        requestOptions: { idempotencyKey: `${bookingId}_${booking.createdAt?.seconds ?? Date.now()}` },
      });
    } catch (mpError) {
      console.error('createPixPayment: Mercado Pago API error:', JSON.stringify(mpError));
      throw new HttpsError('internal', `Payment API error: ${mpError?.message || mpError}`);
    }

    const paymentResult = result.transactions?.payments?.[0];
    const txId = String(paymentResult?.id || result.id);
    const qrCode = paymentResult?.payment_method?.qr_code;
    const qrCodeBase64 = paymentResult?.payment_method?.qr_code_base64;

    // 4. Save PaymentRecord subcollection
    await db
      .collection('bookings').doc(bookingId)
      .collection('payment').doc(txId)
      .set({
        qrCode,
        qrCodeBase64,
        orderId: String(result.id),
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
      paymentId: txId,
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
 * HTTP trigger that receives Mercado Pago order notifications (webhooks).
 * Returns 202 immediately to prevent MP retry, then processes the event.
 *
 * Flow:
 *  1. Return 202 immediately
 *  2. Read data.id from query param (MP sends it there) or body
 *  3. Verify HMAC-SHA256 signature using MP_WEBHOOK_SECRET (lowercase data.id per MP docs)
 *  4. Only process type=order webhooks
 *  5. Fetch full order details from MP Orders API
 *  6. On status=processed: atomically update booking to confirmed + PaymentRecord to paid
 *
 * Secrets: MP_WEBHOOK_SECRET and MP_ACCESS_TOKEN must be set in Firebase Secret Manager.
 */
exports.handlePixWebhook = onRequest(
  { secrets: [mpWebhookSecret, mpAccessToken] },
  async (req, res) => {
    // 2. Only process POST
    if (req.method !== 'POST') {
      res.status(202).send({ success: true });
      return;
    }

    // MP sends data.id as query param AND in body; read from both
    const dataId = req.query['data.id'] || req.body?.data?.id;
    const xSignature = req.headers['x-signature'];
    const xRequestId = req.headers['x-request-id'] || '';

    if (!dataId) {
      console.log('handlePixWebhook: missing data.id — ignoring');
      res.status(202).send({ success: true });
      return;
    }

    // 3. Verify MP signature — MP docs require lowercase data.id in the manifest
    const isValid = verifyMpSignature(
      xSignature,
      xRequestId,
      String(dataId).toLowerCase(),
      mpWebhookSecret.value()
    );
    if (!isValid) {
      console.error('handlePixWebhook: invalid signature — ignoring');
      res.status(202).send({ success: true });
      return;
    }

    // 4. Orders API fires type=order webhooks, not payment.updated
    const type = req.body?.type;
    const action = req.body?.action;

    if (type !== 'order') {
      console.log(`handlePixWebhook: type=${type} — not an order event, ignoring`);
      res.status(202).send({ success: true });
      return;
    }

    // Ignore initial order creation notification (no payment yet)
    if (action === 'order.action_required') {
      console.log('handlePixWebhook: order.action_required — waiting for Pix payment, ignoring');
      res.status(202).send({ success: true });
      return;
    }

    // 5. Fetch full order details from MP API (status/external_reference not in webhook body)
    const client = new MercadoPagoConfig({ accessToken: mpAccessToken.value() });
    const orderApi = new Order(client);

    let orderData;
    try {
      orderData = await orderApi.get({ id: String(dataId) });
    } catch (err) {
      console.error('handlePixWebhook: failed to fetch order:', JSON.stringify(err));
      res.status(202).send({ success: true });
      return;
    }

    const orderStatus = orderData.status;
    const bookingId = orderData.external_reference;
    const paymentId = orderData.transactions?.payments?.[0]?.id;

    console.log(`handlePixWebhook: order=${dataId} status=${orderStatus} bookingId=${bookingId}`);

    if (!bookingId) {
      console.log('handlePixWebhook: no external_reference in order — ignoring');
      res.status(202).send({ success: true });
      return;
    }

    // 6. Only handle processed (confirm) and refunded statuses
    if (orderStatus !== 'processed' && orderStatus !== 'refunded') {
      console.log(`handlePixWebhook: order status ${orderStatus} — ignoring`);
      res.status(202).send({ success: true });
      return;
    }

    const db = admin.firestore();
    const bookingRef = db.collection('bookings').doc(bookingId);
    const paymentRef = bookingRef.collection('payment').doc(String(paymentId || dataId));
    const paymentSnap = await paymentRef.get();

    // 6a. Refund: mark booking as refunded, free the slot
    if (orderStatus === 'refunded') {
      if (paymentSnap.exists && paymentSnap.data().status === 'refunded') {
        console.log(`handlePixWebhook: order ${dataId} already refunded — skipping`);
        res.status(202).send({ success: true });
        return;
      }
      await db.runTransaction(async (transaction) => {
        const bookingSnap = await transaction.get(bookingRef);
        if (!bookingSnap.exists) return;
        if (bookingSnap.data().status === 'refunded') return;
        transaction.update(bookingRef, {
          status: 'refunded',
          refundedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        if (paymentSnap.exists) {
          transaction.update(paymentRef, {
            status: 'refunded',
            refundedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      });
      console.log(`handlePixWebhook: booking ${bookingId} refunded via webhook`);
      res.status(202).send({ success: true });
      return;
    }

    // 6b. Processed: confirm booking
    // Idempotency check
    if (paymentSnap.exists && paymentSnap.data().status === 'paid') {
      console.log(`handlePixWebhook: order ${dataId} already processed — skipping`);
      res.status(202).send({ success: true });
      return;
    }

    // 7. Atomic update: booking → confirmed, PaymentRecord → paid
    await db.runTransaction(async (transaction) => {
      const bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) return;
      if (bookingSnap.data().status === 'confirmed') return;

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
    // Return 202 after processing — Cloud Run terminates after response,
    //    so all async work must complete before sending.
    res.status(202).send({ success: true });
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

/**
 * Cancels a pending PIX payment booking.
 *
 * 1. Validates auth, booking ownership, and status (pending_payment + pix only)
 * 2. Reads payment subcollection to find orderId
 * 3. Cancels the Mercado Pago order (best-effort — failure is logged, not thrown)
 * 4. Updates payment record status to 'cancelled'
 * 5. Updates booking status to 'cancelled'
 */
exports.cancelPixPayment = onCall(
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

    if (booking.paymentMethod !== 'pix') {
      throw new HttpsError('failed-precondition', 'Booking is not a PIX payment');
    }

    // Try to cancel MP order if payment record exists
    const paymentSnap = await bookingRef.collection('payment').limit(1).get();

    if (!paymentSnap.empty) {
      const paymentDoc = paymentSnap.docs[0];
      const orderId = paymentDoc.data().orderId;

      if (orderId) {
        const client = new MercadoPagoConfig({
          accessToken: mpAccessToken.value(),
          options: { timeout: 10000 },
        });
        const orderApi = new Order(client);

        try {
          await orderApi.cancel({ id: orderId });
          console.log(`cancelPixPayment: cancelled MP order ${orderId} for booking ${bookingId}`);
        } catch (mpError) {
          // Log but don't fail — booking should still be cancelled in Firestore
          // MP order will expire naturally on its own
          console.error(`cancelPixPayment: failed to cancel MP order ${orderId}:`, JSON.stringify(mpError));
        }
      }

      await paymentDoc.ref.update({
        status: 'cancelled',
        cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await bookingRef.update({
      status: 'cancelled',
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`cancelPixPayment: booking ${bookingId} cancelled`);
    return { success: true };
  }
);

/**
 * Callable function: admin manually confirms a pending PIX payment.
 *
 * 1. Validates auth + admin role
 * 2. Validates booking status == 'pending_payment'
 * 3. Cancels the Mercado Pago order (best-effort — failure is logged, not thrown)
 * 4. Updates payment record status to 'paid'
 * 5. Updates booking status to 'confirmed'
 */
exports.adminConfirmPixPayment = onCall(
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

    // Verify caller is admin
    const callerDoc = await db.collection('users').doc(callerId).get();
    if (!callerDoc.exists || callerDoc.data().role !== 'admin') {
      throw new HttpsError('permission-denied', 'Admin role required');
    }

    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingSnap = await bookingRef.get();

    if (!bookingSnap.exists) {
      throw new HttpsError('not-found', 'Booking does not exist');
    }

    const booking = bookingSnap.data();

    if (booking.status !== 'pending_payment') {
      throw new HttpsError('failed-precondition', `Expected pending_payment, got ${booking.status}`);
    }

    // Cancel MP order (best-effort) — use booking.paymentId to get the current payment doc,
    // not limit(1) which may return a stale doc from a previous booking on the same slot.
    const currentPaymentId = booking.paymentId;
    const paymentDocRef = currentPaymentId
      ? bookingRef.collection('payment').doc(currentPaymentId)
      : null;
    const paymentDocSnap = paymentDocRef ? await paymentDocRef.get() : null;

    if (paymentDocSnap && paymentDocSnap.exists) {
      const paymentDoc = paymentDocSnap;
      const orderId = paymentDoc.data().orderId;

      if (orderId) {
        const client = new MercadoPagoConfig({
          accessToken: mpAccessToken.value(),
          options: { timeout: 10000 },
        });
        const orderApi = new Order(client);

        try {
          await orderApi.cancel({ id: orderId });
          console.log(`adminConfirmPixPayment: cancelled MP order ${orderId} for booking ${bookingId}`);
        } catch (mpError) {
          console.error(`adminConfirmPixPayment: failed to cancel MP order ${orderId}:`, JSON.stringify(mpError));
        }
      }

      await paymentDoc.ref.update({
        status: 'paid',
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await bookingRef.update({
      status: 'confirmed',
      confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`adminConfirmPixPayment: booking ${bookingId} confirmed manually by admin ${callerId}`);
    return { success: true };
  }
);

/**
 * Updates prices of future unbooked slots based on current pricing tiers.
 * Called by the admin after saving pricing tiers.
 *
 * Rules:
 *   - Only updates slots with date >= today
 *   - Skips slots with active bookings (pending, confirmed, pending_payment)
 *   - If no tier covers the slot hour → keeps current price
 *   - Returns { updatedCount }
 */
exports.updateSlotPricesFromTiers = onCall({}, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Not authenticated.');

  const db = admin.firestore();
  const userDoc = await db.collection('users').doc(uid).get();
  if (userDoc.data()?.role !== 'admin') {
    throw new HttpsError('permission-denied', 'Admins only.');
  }

  try {
    // Read current tiers
    const pricingDoc = await db.collection('config').doc('pricing').get();
    const tiers = pricingDoc.data()?.tiers ?? [];

    // Today in YYYY-MM-DD (UTC, same as slot dates)
    const todayStr = new Date().toISOString().split('T')[0];

    // Fetch future slots
    const slotsSnap = await db.collection('slots').where('date', '>=', todayStr).get();

    // Build set of booked slot keys: "{slotId}_{date}"
    const bookingsSnap = await db.collection('bookings')
      .where('date', '>=', todayStr)
      .where('status', 'in', ['pending', 'confirmed', 'pending_payment'])
      .get();
    const bookedKeys = new Set(bookingsSnap.docs.map(d => `${d.data().slotId}_${d.data().date}`));

    // Price calculator — mirrors _priceFor() in slot_batch_sheet.dart
    function calcPrice(dateStr, startTime) {
      const [y, m, d] = dateStr.split('-').map(Number);
      const jsDay = new Date(Date.UTC(y, m - 1, d)).getUTCDay();
      const weekday = jsDay === 0 ? 7 : jsDay; // 1=Mon, 7=Sun (matches Dart DateTime.weekday)
      const hour = parseInt(startTime.split(':')[0], 10);
      let best = null;
      for (const tier of tiers) {
        const dayOk = !tier.daysOfWeek?.length || tier.daysOfWeek.includes(weekday);
        if (dayOk && hour >= tier.fromHour && hour < tier.toHour) {
          best = best === null ? tier.price : Math.max(best, tier.price);
        }
      }
      return best; // null if no tier covers this slot
    }

    // Batch update
    let batch = db.batch();
    let batchCount = 0;
    let updatedCount = 0;

    for (const slotDoc of slotsSnap.docs) {
      const slot = slotDoc.data();
      const key = `${slotDoc.id}_${slot.date}`;
      if (bookedKeys.has(key)) continue;

      const newPrice = calcPrice(slot.date, slot.startTime);
      if (newPrice === null || newPrice === slot.price) continue;

      batch.update(slotDoc.ref, { price: newPrice });
      batchCount++;
      updatedCount++;

      if (batchCount === 499) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
      }
    }
    if (batchCount > 0) await batch.commit();

    console.log(`updateSlotPricesFromTiers: updated ${updatedCount} slots`);
    return { updatedCount };
  } catch (error) {
    console.error('updateSlotPricesFromTiers error:', error);
    throw new HttpsError('internal', error.message);
  }
});

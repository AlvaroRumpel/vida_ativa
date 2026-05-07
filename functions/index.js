const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

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

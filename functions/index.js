const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Triggered when a new booking document is created in the `bookings` collection.
 * Sends an FCM push notification to all admin users who have stored FCM tokens.
 *
 * Firestore structure used:
 *   /users/{userId}                   — { role: "admin"|"client", displayName, ... }
 *   /users/{userId}/fcmTokens/{token} — { token, createdAt, platform }
 *   /bookings/{bookingId}             — { slotId, date, startTime, userDisplayName, ... }
 */
exports.notifyAdminNewBooking = onDocumentCreated('bookings/{bookingId}', async (event) => {
  const bookingData = event.data.data();

  if (!bookingData) {
    console.log('No booking data found — skipping');
    return;
  }

  const clientName = bookingData.userDisplayName || 'Cliente';
  const startTime = bookingData.startTime || '';
  const date = bookingData.date || '';

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

  const multicastMessage = {
    notification: {
      title: 'Nova Reserva',
      body: `${clientName} — ${startTime}${dateFormatted}`,
    },
    webpush: {
      fcmOptions: {
        link: '/admin',
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

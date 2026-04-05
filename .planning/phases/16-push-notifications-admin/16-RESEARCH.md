# Phase 16: Push Notifications Admin - Research

**Researched:** 2026-04-04
**Domain:** Firebase Cloud Messaging (FCM) + Flutter Web Push Notifications + Cloud Functions
**Confidence:** HIGH

## Summary

Phase 16 requires implementing web push notifications for admin users when new bookings are created. This involves three main components: (1) requesting notification permissions and storing FCM tokens in the admin profile, (2) setting up a Cloud Function to trigger on new bookings and send FCM messages, and (3) implementing a service worker to handle notifications in the background.

The architecture is standard Firebase: Flutter web front-end uses `firebase_messaging` to request permissions and get tokens; a Cloud Function watches the bookings collection and sends FCM notifications via the Admin SDK; Flutter's service worker receives and displays notifications even when the browser is closed.

**Primary recommendation:** Use `firebase_messaging` ^6.x for web, store admin FCM tokens in a `/users/{userId}/fcmTokens` subcollection with `FieldValue.arrayUnion()`, and implement a Node.js Cloud Function with `onDocumentCreated` trigger on the bookings collection.

## User Constraints

No CONTEXT.md exists for this phase — no locked decisions or constraints defined by user. Research proceeds with standard FCM best practices.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| NOTF-01 | Admin recebe web push notification (FCM) quando uma nova reserva é criada; requer permissão do browser; funciona com app em background via service worker | Firebase Messaging v6+ with web support; Cloud Firestore trigger on bookings collection; Flutter service worker integration |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| firebase_messaging | ^6.1.0+ | FCM integration for Flutter web; handles token management, permission requests, and message reception | Official FlutterFire package; widely used for web/mobile push; web support mature as of 2024 |
| cloud_functions | Node.js v2 | Serverless trigger on new bookings; sends FCM notifications via Admin SDK | Official Firebase backend; stateless, scalable, integrates natively with Firestore |
| firebase-admin | ^12.0.0+ (Node.js) | Server-side FCM message sending; requires app credentials | Official Firebase Admin SDK; only secure way to send notifications server-side |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| flutter_local_notifications | ^9.x+ | Optional: custom notification display on web (shows app-branded notifications) | If default browser notification insufficient; provides consistent styling across platforms |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| firebase_messaging | Custom Web Push API | Loses Firebase integration, VAPID key management, multiplatform consistency |
| Cloud Functions | Firestore Security Rules custom claims | Rules cannot send external HTTP requests; Cloud Functions are required for FCM |
| Admin SDK | REST API manually | Requires handling authentication, token rotation, rate limiting manually |

**Installation:**
```bash
flutter pub add firebase_messaging

# Also in your Firebase project:
# npm install -g firebase-tools
# firebase deploy --only functions (after creating functions)
```

**Version verification:** firebase_messaging latest stable is ^6.1.0+ (Feb 2025); Cloud Functions Node.js v2 is standard; firebase-admin ^12.0.0 is stable.

## Architecture Patterns

### Recommended Project Structure

```
functions/                              # Cloud Functions project (if not yet created)
├── index.js                            # Main function definitions
├── package.json                        # Node.js dependencies
└── .env.local                          # Non-committing secret keys (for local dev)

lib/
├── features/
│   └── admin/
│       ├── cubit/
│       │   ├── admin_fcm_cubit.dart    # NEW: Token management + permission UI
│       │   └── admin_fcm_state.dart    # NEW: FCM token/permission states
│       └── ui/
│           ├── notification_permission_sheet.dart  # NEW: Request permission UI
│           └── admin_screen.dart       # EXISTING: Add notification setup on load

web/
├── firebase-messaging-sw.js             # NEW: Service worker for background notifications
└── index.html                          # EXISTING: Register FCM service worker
```

### Pattern 1: Requesting Notification Permissions

**What:** User explicitly grants browser permission for notifications; permission denied means no FCM tokens can be generated; permission granted triggers FCM token request.

**When to use:** On admin first login, or offer as setting in admin profile. Must happen before `getToken(vapidKey)` is called.

**Example:**
```dart
// Source: https://firebase.flutter.dev/docs/messaging/permissions/
Future<void> requestNotificationPermission() async {
  final messaging = FirebaseMessaging.instance;
  final permission = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  
  if (permission.authorizationStatus == AuthorizationStatus.authorized) {
    // User granted permission — safe to get token
    final token = await messaging.getToken(
      vapidKey: "YOUR_PUBLIC_VAPID_KEY",
    );
    // Save token to Firestore
    await _storeToken(token);
  }
}
```

### Pattern 2: Storing FCM Tokens in Firestore

**What:** Admin tokens stored in `/users/{userId}/fcmTokens` subcollection; multiple tokens per user (multiple devices/browsers); old tokens auto-deleted.

**When to use:** Immediately after `getToken()` succeeds; also listen to `onTokenRefresh` stream for new tokens when browser refreshes FCM token.

**Example:**
```dart
// Source: https://firebase.flutter.dev/docs/messaging/usage/
Future<void> _storeToken(String token) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;
  
  await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('fcmTokens')
    .doc(token) // Use token as doc ID for idempotency
    .set({
      'token': token,
      'createdAt': Timestamp.now(),
      'platform': 'web',
    });
}

// Listen to token refresh (browser refreshes token every ~7 days)
void _listenToTokenRefresh() {
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    _storeToken(newToken);
  });
}
```

### Pattern 3: Cloud Function to Send FCM on New Booking

**What:** Firestore trigger on `bookings` collection watches for new documents; for each new booking, function retrieves admin FCM tokens and sends notification.

**When to use:** Only way to send FCM from backend securely; triggers automatically when `bookingCubit.bookSlot()` writes to Firestore.

**Example (Node.js):**
```javascript
// Source: https://firebase.google.com/docs/functions/firestore-events
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

admin.initializeApp();

exports.notifyAdminNewBooking = onDocumentCreated('bookings/{bookingId}', async (event) => {
  const bookingData = event.data.data();
  
  // Get the booking details
  const slotDoc = await admin.firestore().collection('slots').doc(bookingData.slotId).get();
  const slotData = slotDoc.data();
  
  // Query admin tokens from users who have role == 'admin'
  const adminsSnap = await admin.firestore()
    .collection('users')
    .where('role', '==', 'admin')
    .get();
  
  const fcmTokens = [];
  for (const adminDoc of adminsSnap.docs) {
    const tokensSnap = await admin.firestore()
      .collection('users')
      .doc(adminDoc.id)
      .collection('fcmTokens')
      .get();
    
    tokensSnap.docs.forEach(tokenDoc => {
      fcmTokens.push(tokenDoc.data().token);
    });
  }
  
  if (fcmTokens.length === 0) return; // No admin tokens — skip
  
  // Send notification to all admin tokens
  const message = {
    notification: {
      title: 'Nova Reserva',
      body: `${bookingData.userDisplayName} — ${bookingData.startTime}`,
    },
    webpush: {
      fcmOptions: { link: '/admin' }, // Deep link to admin panel
    },
  };
  
  const response = await admin.messaging().sendMulticast({
    ...message,
    tokens: fcmTokens,
  });
  
  console.log(`Sent ${response.successCount} notifications, ${response.failureCount} failed`);
  
  // Clean up invalid tokens (403 = token invalid)
  response.responses.forEach((resp, idx) => {
    if (!resp.success && resp.error?.code === 'messaging/invalid-registration-token') {
      admin.firestore()
        .collection('users')
        .doc(adminsSnap.docs[idx].id)
        .collection('fcmTokens')
        .doc(fcmTokens[idx])
        .delete();
    }
  });
});
```

### Pattern 4: Service Worker for Background Notifications

**What:** Browser's service worker (registered in `web/firebase-messaging-sw.js`) handles notifications when app is closed or minimized. Service worker receives FCM message and displays notification.

**When to use:** Automatically provided by firebase_messaging; required for web push to work with browser closed.

**Example (web/firebase-messaging-sw.js):**
```javascript
// Source: https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages
importScripts('https://www.gstatic.com/firebasejs/10.6.0/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/10.6.0/firebase-messaging.js');

firebase.initializeApp({
  apiKey: 'YOUR_API_KEY',
  authDomain: 'YOUR_AUTH_DOMAIN',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_STORAGE_BUCKET',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  appId: 'YOUR_APP_ID',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((message) => {
  const notificationTitle = message.notification?.title || 'Notificação';
  const notificationOptions = {
    body: message.notification?.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: message.data || {},
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const clickedNotification = event.notification;
  
  // Deep link: open /admin when admin clicks notification
  if (clickedNotification.data.link) {
    event.waitUntil(
      clients.matchAll({ type: 'window' }).then((clientList) => {
        for (let client of clientList) {
          if (client.url === clickedNotification.data.link) {
            return client.focus();
          }
        }
        return clients.openWindow(clickedNotification.data.link);
      })
    );
  }
});
```

### Anti-Patterns to Avoid

- **Storing unencrypted VAPID private key in source code:** Private key must be in Cloud Functions environment only, never in Flutter code. Public key (for getToken) is safe in code.
- **Requesting permission on app launch without context:** Show permission UI only in admin settings or on-demand, not forced; users often deny permissions if asked before seeing value.
- **Sending notifications without checking role == 'admin':** Cloud Function must verify admin role before adding token to send list; prevents non-admins from receiving notifications.
- **Not cleaning up invalid/expired FCM tokens:** Tokens expire after ~60 days or when browser clears data; Cloud Function should delete tokens that fail with 403 error.
- **Using REST API directly instead of Admin SDK:** Admin SDK handles retries, batching, and error handling; manual REST calls are fragile.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| FCM token management | Custom Token storage + refresh polling | `firebase_messaging` onTokenRefresh stream | Library handles token lifecycle, expiry, revalidation; polling is inefficient and error-prone |
| Browser notification display | Raw Web API with Service Worker | firebase_messaging + flutter_local_notifications | Library abstracts browser API differences, handles permission states, queues notifications |
| Firestore->FCM bridging | Custom webhook/polling | Cloud Functions with Firestore trigger | Triggers are real-time, serverless, auto-scaling; webhooks require separate infrastructure |
| Admin SDK authentication | Manual JWT token generation | firebase-admin package | Package handles service account, token refresh, credential rotation automatically |

**Key insight:** Firebase messaging is designed end-to-end for this exact flow (client token request → Firestore storage → backend trigger → FCM send → service worker receive). Hand-rolling any part loses resilience around token expiry, permission revocation, and multidevice scenarios.

## Common Pitfalls

### Pitfall 1: VAPID Key Management

**What goes wrong:** Developer commits private VAPID key to repository or passes it through Flutter code; anyone with private key can spoof notifications or generate tokens for your app.

**Why it happens:** Easy to copy key from Firebase console and paste everywhere; assumption that keys are like regular API keys.

**How to avoid:** (1) Private VAPID key lives ONLY in Cloud Functions environment variables, never in Flutter/web code. (2) Public key (safe to expose) stored in Flutter as constant or fetched from config endpoint. (3) Never commit `.env` files or service account JSON.

**Warning signs:** Code contains "-----BEGIN EC PRIVATE KEY-----"; Firebase console shows "Export" buttons for keys; VAPID key in flutter build arguments (--dart-define).

### Pitfall 2: Forgetting Service Worker Registration

**What goes wrong:** Web app receives notifications while app is open (onMessage works), but nothing happens when browser is closed; notifications sent to service worker but never displayed.

**Why it happens:** `firebase_messaging` requires explicit service worker registration; Flutter web's default service worker doesn't include Firebase messaging code.

**How to avoid:** (1) Create `web/firebase-messaging-sw.js` with full Firebase SDK initialization. (2) Ensure `web/index.html` includes `<script src="flutter_bootstrap.js"></script>` (auto-registers service worker). (3) Test with browser DevTools → Application → Service Workers to verify registration.

**Warning signs:** Admin never sees notifications when app closed; service worker not listed in DevTools; 404 error for `/firebase-messaging-sw.js` in browser console.

### Pitfall 3: Missing Admin Role Check in Cloud Function

**What goes wrong:** Function sends notifications to ALL users with stored FCM tokens, not just admins; regular users receive booking notifications.

**Why it happens:** Copy-paste Cloud Function sample without filtering by role field.

**How to avoid:** (1) Query with `.where('role', '==', 'admin')` before fetching tokens. (2) Store tokens in `/users/{userId}/fcmTokens` only after verifying `user.role == 'admin'` in Flutter. (3) Add comment in function explaining role requirement.

**Warning signs:** Non-admin users report receiving "booking created" notifications; CloudFunction logs show tokens from users with `role: 'client'`.

### Pitfall 4: Tokens Stored Without Cleanup

**What goes wrong:** FCM tokens accumulate infinitely; old tokens (from cleared cache, token refresh) pile up in subcollection; storage quota wasted; function iterates over 1000s of dead tokens.

**Why it happens:** No automatic cleanup; tokens valid indefinitely until explicitly deleted or permission revoked.

**How to avoid:** (1) Set TTL on tokens using `createdAt` timestamp; prune tokens older than 90 days. (2) Delete tokens that fail with 403 (invalid) in sendMulticast response. (3) Listen to `onPermissionRevoked()` in Flutter to delete tokens when user revokes permission.

**Warning signs:** fcmTokens subcollection has 100+ documents for single user; sendMulticast response shows high failure rate (>10%).

### Pitfall 5: Requesting Permission Without User Context

**What goes wrong:** App asks "Allow notifications?" on first launch or admin login before user sees the value; user denies reflex; re-asking later is blocked by browser (one-time prompt).

**Why it happens:** Eager approach assumes notifications are always wanted.

**How to avoid:** (1) Add notification opt-in to admin settings screen with explanation ("Receba alertas quando novas reservas são criadas"). (2) Only call `requestPermission()` when user clicks that toggle. (3) Show permission status in settings so admin knows if permission was previously denied.

**Warning signs:** Permission granted rate <50%; users ask "How do I turn on notifications?" after denying once.

## Code Examples

Verified patterns from official sources:

### Initialize FCM and Request Permission

```dart
// Source: https://firebase.flutter.dev/docs/messaging/permissions/
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminFcmService {
  static final AdminFcmService _instance = AdminFcmService._internal();
  factory AdminFcmService() => _instance;
  AdminFcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initializeNotifications() async {
    // Listen to token refresh throughout app lifetime
    _messaging.onTokenRefresh.listen((newToken) {
      _storeTokenInFirestore(newToken);
    });
  }

  Future<void> requestNotificationPermission() async {
    const vapidKey = String.fromEnvironment(
      'VAPID_PUBLIC_KEY',
      defaultValue: 'YOUR_PUBLIC_VAPID_KEY', // From Firebase console Web config
    );

    final permission = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    if (permission.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await _messaging.getToken(vapidKey: vapidKey);
      if (token != null) {
        await _storeTokenInFirestore(token);
      }
    }
  }

  Future<void> _storeTokenInFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('fcmTokens')
        .doc(token)
        .set({
          'token': token,
          'createdAt': Timestamp.now(),
          'platform': 'web',
        });
  }

  Stream<RemoteMessage> get onMessage => _messaging.onMessage;
}
```

### Listen to Foreground Messages

```dart
// Source: https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages
void _listenToForegroundMessages() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message in foreground!');
    print('Message notification: ${message.notification}');
    print('Message data: ${message.data}');

    // Show snackbar or dialog in admin panel
    // Example: ScaffoldMessenger.of(context).showSnackBar(...)
  });
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Cloud Messaging REST API direct calls from Flutter | firebase_messaging package + Cloud Functions trigger | 2019 (firebase_messaging created) | FCM token handling, permission state, multicast, and error recovery now handled by library |
| Manual service worker creation | flutter_web auto-registers Firebase service worker | 2021 (Flutter web stable) | Service workers now deployed automatically with web app; manual registration no longer needed |
| Storing tokens in SharedPreferences | Firestore `/users/{userId}/fcmTokens` subcollection | 2021 (BLoC best practices standardized) | Tokens synced across devices, survives app reinstall, queryable for Cloud Functions |
| Custom polling for token refresh | onTokenRefresh stream listener | 2019 (firebase_messaging 4.0+) | Real-time updates, eliminates polling, battery-efficient |

**Deprecated/outdated:**
- **Firebase Realtime Database for tokens:** Legacy approach before Firestore; Firestore is now standard for all new projects.
- **FlutterLocalNotifications alone (web):** Package shows notifications but Cloud Messaging integration is now built into firebase_messaging; LocalNotifications is for iOS/Android system integration.

## Open Questions

1. **Should admins see notification permission status in settings?**
   - What we know: Browser permission request is one-time; users can revoke in browser settings but app won't know.
   - What's unclear: Should we poll `checkPermissionStatus()` and show toggle in admin profile, or just show "Notifications enabled/disabled"?
   - Recommendation: Show status as read-only badge in admin profile with text "Browser has revoked notification permission" if status is denied; offer re-request button if status is denied (browser will show prompt again if user reopens browser permissions).

2. **What happens if all admin FCM tokens are invalid (function cleanup)? Should admin be notified that notifications are broken?**
   - What we know: Cloud Function deletes invalid tokens automatically on 403 response.
   - What's unclear: If last valid token deleted, next new booking won't trigger notification. Admin unaware.
   - Recommendation: Out of scope for Phase 16; add to Phase 17 if needed. For now, function logs `Sent 0 notifications` and Sentry catches if needed.

3. **Should we pre-populate VAPID public key in Flutter code or fetch from Cloud Functions config endpoint?**
   - What we know: Public key is safe to expose; commonly stored as environment constant.
   - What's unclear: Should app fetch from backend (dynamic, allows key rotation) or hardcode (simpler, no network call)?
   - Recommendation: Hardcode in `const vapidKey = String.fromEnvironment('VAPID_PUBLIC_KEY')` passed at build time; matches project pattern (Sentry DSN via --dart-define). If key rotation needed, rebuild app.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None — no test infrastructure yet in project |
| Config file | N/A |
| Quick run command | N/A |
| Full suite command | N/A |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| NOTF-01 (Step 1) | Admin can request notification permission and see permission status | Manual browser test | N/A | ❌ Wave 0 |
| NOTF-01 (Step 2) | New booking triggers Cloud Function; Cloud Function sends FCM message | Manual Firebase emulator test | `firebase emulators:start` | ❌ Wave 0 |
| NOTF-01 (Step 3) | Admin receives push notification in browser (foreground + background) | Manual browser test with DevTools | N/A | ❌ Wave 0 |
| NOTF-01 (Step 4) | Service worker displays notification with client name and time | Manual browser test (DevTools → Application → Service Workers) | N/A | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** Manual browser test (request permission → check Firestore token stored)
- **Per wave merge:** Full flow: create booking as client → verify admin receives notification → verify notification displays correctly
- **Phase gate:** Manual test on staging deployment; verify notification received when booking created from another admin account

### Wave 0 Gaps
- [ ] `functions/index.js` — Cloud Function with Firestore trigger + sendMulticast
- [ ] `web/firebase-messaging-sw.js` — Service worker initialization with Firebase SDK
- [ ] `lib/features/admin/cubit/admin_fcm_cubit.dart` — Token management + permission state
- [ ] `lib/features/admin/ui/notification_permission_sheet.dart` — Permission request UI
- [ ] Build configuration: `--dart-define VAPID_PUBLIC_KEY=...` in build script
- [ ] Firebase Cloud Functions Node.js project setup (if functions folder doesn't exist)
- [ ] Firebase service account JSON for local Cloud Functions development

## Sources

### Primary (HIGH confidence)
- [Firebase Cloud Messaging Get Started](https://firebase.google.com/docs/cloud-messaging/flutter/get-started) - Web setup, VAPID keys, token management
- [FlutterFire Messaging Permissions](https://firebase.flutter.dev/docs/messaging/permissions/) - Permission request API
- [FlutterFire Messaging Usage](https://firebase.flutter.dev/docs/messaging/usage/) - Token retrieval, stream listeners
- [Firebase Firestore Events (Cloud Functions)](https://firebase.google.com/docs/functions/firestore-events) - Trigger syntax, event handler pattern
- [firebase_messaging pub.dev package](https://pub.dev/packages/firebase_messaging) - Version history, changelog
- [firebase-admin npm package](https://www.npmjs.com/package/firebase-admin) - Node.js Admin SDK for FCM sendMulticast

### Secondary (MEDIUM confidence)
- [Implementing Push Notifications in Flutter Web with Firebase](https://medium.com/@anwarsafy15/implementing-push-notifications-in-flutter-web-with-firebase-85da1fa0fd9c) - Medium article, verified patterns
- [How To Send Push Notifications on Flutter Web (FCM)](https://rodydavis.com/posts/push-notifications-flutter-web) - Community best practices
- [Firebase Cloud Functions for Cloud Messaging Sample Library](https://github.com/firebase/functions-samples) - Reference implementations

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** - firebase_messaging is official FlutterFire package; Cloud Functions + Admin SDK are standard Firebase products documented in official guides
- Architecture: **HIGH** - Pattern is well-established (token request → Firestore → Cloud Function trigger → sendMulticast); tested across thousands of Firebase projects
- Pitfalls: **HIGH** - Common issues (VAPID key exposure, service worker missing, role filtering) documented in official Firebase forums and StackOverflow

**Research date:** 2026-04-04
**Valid until:** 2026-05-04 (30 days; Firebase services stable, but check firebase_messaging changelog for breaking changes)


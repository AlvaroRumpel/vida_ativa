# Stack Research: Pix Payment + Feature Toggles v4.0

**Project:** Vida Ativa v4.0 — Feature Toggles & Pix Automatic Payment  
**Researched:** 2026-04-06  
**Confidence:** HIGH (Mercado Pago), MEDIUM (custom feature flags via Firestore)

---

## Executive Summary

### Pix Payment Gateway

**Recommendation: Mercado Pago** with Cloud Functions (Node.js 20, existing)

Mercado Pago is the best choice because:
- Mature Pix QR code API (generates single-use codes with amounts embedded)
- Standardized webhook notifications (POST to notification_url)
- Extensive GitHub examples for Node.js + Cloud Functions integration
- Ecosystem maturity outweighs 1-2% higher fees vs PagSeguro

**Alternative:** PagSeguro (0.99% vs 1.99% Pix fee) if fees become critical in production. Integration flow is identical; drop-in replacement.

### Feature Toggles

**Recommendation: Custom Firestore-based approach** (no new packages)

Custom implementation because:
- You already read academy config from Firestore on app init
- Feature flags logically belong in the same config document hierarchy
- Avoids second Firebase service (Firebase Remote Config adds operational overhead)
- Admin UI can reuse existing Firestore form patterns
- Implementation: ~50 lines of Dart in custom FeatureFlagsService

---

## New Stack for v4.0

### 1. Pix Payment Integration

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **@mercadopago/sdk-node** | ^2.0.0 | Server: Pix QR generation, status polling | Official SDK; handles Pix API complexity; direct Node.js integration |
| **http** | ^1.1.0 (Flutter) | Client: POST to Cloud Function for payment initiation | Flutter Web standard for HTTPS; already used in project |
| **qr** | ^2.2.0 | Display QR code in Flutter UI | Lightweight QR rendering; no scanning needed (user scans from phone) |
| **Cloud Functions (Node.js 20)** | Blaze plan (existing) | Webhook receiver + Firestore updater | Existing infrastructure; handles async payment confirmation |
| **Firestore** | Existing | Payment status storage (`pending_payment` → `confirmed`) | Single source of truth; already integrated with BookingModel |
| **firebase_messaging** | ^14.7.0 (existing) | FCM push notification on payment confirmed | Reuse existing setup; notify admin + client |

#### Pix Integration Flow

```
Client (Flutter Web)
  ↓ POST /functions/createPixPayment?bookingId=X&amount=Y
  
Cloud Function (Node.js 20)
  ├→ Load Mercado Pago SDK with ACCESS_TOKEN (from Firebase secrets)
  ├→ Call mercadopago.payment.create({ amount, description })
  ├→ Extract qr_data + transaction_id
  ├→ Write to Firestore: booking.paymentStatus='pending_payment', booking.pixTransactionId=txId
  └→ Return { qrCode, copyPasteCode, transactionId } to client

Client displays QR in modal + copy-paste code option

User scans QR with Pix app → Pays instantly

Payment settled
  ↓ Mercado Pago webhook POST to /functions/handlePixWebhook
  
Cloud Function webhook handler
  ├→ Verify webhook signature (Mercado Pago provides X-Signature header)
  ├→ Query Mercado Pago API to confirm payment status (idempotency)
  ├→ Find booking by pixTransactionId
  ├→ Update Firestore: booking.paymentStatus='confirmed', booking.paidAt=now()
  ├→ Send FCM to admin (existing integration)
  └→ Return HTTP 200 OK to Mercado Pago

Client polls Firestore every 3-5 sec (or listens to real-time updates)
  ├→ Detects paymentStatus change to 'confirmed'
  └→ Close modal, show success message
```

#### Why Mercado Pago Over Alternatives

| Gateway | Pix Fee | API Maturity | Webhook Support | Community Examples | Notes |
|---------|---------|--------------|-----------------|-------------------|-------|
| **Mercado Pago** | 1.99% | HIGH — Official Pix QR API | Yes, standard POST | Multiple GitHub repos | **RECOMMENDED** |
| **PagSeguro** | 0.99% | MEDIUM — Newer API via PagBank | Yes, Orders API | Limited public examples | Lower fee; similar flow |
| **Asaas** | R$0.80 fixed | MEDIUM — Simpler; smaller ecosystem | Yes, webhook tokens | Minimal CF examples | Feature-light; higher risk |

**Decision:** Mercado Pago for v4.0 MVP. If production fees exceed budget, PagSeguro is a same-day drop-in replacement with identical webhook architecture.

---

### 2. Feature Toggles

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **cloud_firestore** | Existing | Read `/config/features` doc on app init | Single source of truth; already used for booking config |
| **Custom FeatureFlagsService** | N/A | Dart service: parse flags, cache in memory | Lightweight; integrates with existing BLoC patterns |
| **Optional: flutter_bloc** | ^8.0.0 (existing) | Emit state if flags change (optional real-time) | For admin UI to watch flag changes without restart |

#### Firestore Document Structure

```yaml
/academies/{academyId}/config/features
{
  "pix_enabled": true,
  "notifications_enabled": true,
  "recurring_bookings_enabled": true,
  "social_features_enabled": true,
  "admin_approval_required": false,
  "updatedAt": "2026-04-06T12:00:00Z"
}
```

#### Custom FeatureFlagsService Implementation

Create `lib/core/services/feature_flags_service.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class FeatureFlags {
  final bool pixEnabled;
  final bool notificationsEnabled;
  final bool recurringBookingsEnabled;
  final bool socialFeaturesEnabled;
  final bool adminApprovalRequired;

  FeatureFlags({
    required this.pixEnabled,
    required this.notificationsEnabled,
    required this.recurringBookingsEnabled,
    required this.socialFeaturesEnabled,
    required this.adminApprovalRequired,
  });

  factory FeatureFlags.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return FeatureFlags(
      pixEnabled: data?['pix_enabled'] ?? false,
      notificationsEnabled: data?['notifications_enabled'] ?? true,
      recurringBookingsEnabled: data?['recurring_bookings_enabled'] ?? true,
      socialFeaturesEnabled: data?['social_features_enabled'] ?? true,
      adminApprovalRequired: data?['admin_approval_required'] ?? false,
    );
  }

  factory FeatureFlags.defaults() => FeatureFlags(
    pixEnabled: false,
    notificationsEnabled: true,
    recurringBookingsEnabled: true,
    socialFeaturesEnabled: true,
    adminApprovalRequired: false,
  );
}

class FeatureFlagsService {
  final FirebaseFirestore _firestore;
  final String academyId;

  late FeatureFlags _cached;
  bool _initialized = false;

  FeatureFlagsService({
    required this.academyId,
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  /// Call once on app init (in main() before BLoC setup)
  Future<void> initialize() async {
    try {
      final doc = await _firestore
          .collection('academies')
          .doc(academyId)
          .collection('config')
          .doc('features')
          .get();
      _cached = doc.exists
          ? FeatureFlags.fromFirestore(doc)
          : FeatureFlags.defaults();
      _initialized = true;
    } catch (e, st) {
      // Log to Sentry; app continues with defaults
      await Sentry.captureException(e, stackTrace: st);
      _cached = FeatureFlags.defaults();
      _initialized = true;
    }
  }

  /// Get cached flags (call after initialize())
  FeatureFlags get flags {
    assert(_initialized, 'Call initialize() first');
    return _cached;
  }

  /// Optional: Real-time listener for admin UI (avoid on client)
  Stream<FeatureFlags> watchFlags() {
    return _firestore
        .collection('academies')
        .doc(academyId)
        .collection('config')
        .doc('features')
        .snapshots()
        .map((doc) => doc.exists
            ? FeatureFlags.fromFirestore(doc)
            : FeatureFlags.defaults())
        .handleError((e, st) {
          Sentry.captureException(e, stackTrace: st);
          return _cached; // Return last known value on error
        });
  }

  /// Admin: Update flags
  Future<void> updateFlags(FeatureFlags flags) async {
    await _firestore
        .collection('academies')
        .doc(academyId)
        .collection('config')
        .doc('features')
        .set({
          'pix_enabled': flags.pixEnabled,
          'notifications_enabled': flags.notificationsEnabled,
          'recurring_bookings_enabled': flags.recurringBookingsEnabled,
          'social_features_enabled': flags.socialFeaturesEnabled,
          'admin_approval_required': flags.adminApprovalRequired,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }
}
```

#### Usage in UI

```dart
// lib/main.dart — Initialize on app startup
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize feature flags before BLoC setup
  final ffService = FeatureFlagsService(
    academyId: 'academia-id', // From config or auth context
    firestore: FirebaseFirestore.instance,
  );
  await ffService.initialize();
  
  runApp(MyApp(featureFlagsService: ffService));
}

// lib/features/booking/ui/booking_page.dart — Conditional UI
class BookingPage extends StatelessWidget {
  final FeatureFlagsService _ffService;

  const BookingPage({required FeatureFlagsService ffService})
      : _ffService = ffService;

  @override
  Widget build(BuildContext context) {
    if (_ffService.flags.pixEnabled) {
      return Column(
        children: [
          // Show Pix payment button
          ElevatedButton(
            onPressed: () => _showPixQRModal(context),
            child: const Text('Pagar com Pix'),
          ),
        ],
      );
    } else {
      return Text('Pagamento não disponível neste momento');
    }
  }
}

// lib/features/admin/ui/settings_page.dart — Admin toggle (listens for real-time)
class AdminSettingsPage extends StatelessWidget {
  final FeatureFlagsService _ffService;

  const AdminSettingsPage({required FeatureFlagsService ffService})
      : _ffService = ffService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FeatureFlags>(
      stream: _ffService.watchFlags(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final flags = snapshot.data!;

        return Column(
          children: [
            SwitchListTile(
              title: const Text('Habilitar Pix'),
              value: flags.pixEnabled,
              onChanged: (val) async {
                final updated = FeatureFlags(
                  pixEnabled: val,
                  notificationsEnabled: flags.notificationsEnabled,
                  recurringBookingsEnabled: flags.recurringBookingsEnabled,
                  socialFeaturesEnabled: flags.socialFeaturesEnabled,
                  adminApprovalRequired: flags.adminApprovalRequired,
                );
                await _ffService.updateFlags(updated);
              },
            ),
            // ... more toggles
          ],
        );
      },
    );
  }
}
```

#### Why Custom Firestore Over Alternatives

| Approach | Setup | Overhead | Integration | Recommendation |
|----------|-------|----------|-------------|-----------------|
| **Custom Firestore** | LOW | ZERO — single read on init | HIGH — reuses existing Firestore + rules | **RECOMMENDED** |
| Firebase Remote Config | MEDIUM | LOW | MEDIUM — separate service, async fetch | Simpler if not in Firestore |
| firebase_feature_flag pkg | MEDIUM | LOW | MEDIUM | Uses Realtime Database (not Firestore) |
| Flagsmith / ConfigCat | HIGH | MEDIUM | LOW | External vendor; overkill for v4.0 |

**Rationale:** You already read `/config/booking` from Firestore on init. Flags belong in the same document hierarchy because (1) admin manages both in same UI, (2) single Firestore permission check, (3) no second Firebase service.

---

## 3. Installation & Setup

### Pix Payment Dependencies

```bash
# In Flutter project root
flutter pub add http qr

# In Firebase functions directory
cd functions
npm install @mercadopago/sdk-node

# Set Mercado Pago credentials via Firebase secrets (NOT in .env)
firebase functions:secrets:set MERCADO_PAGO_ACCESS_TOKEN
# Follow prompt; paste your API key from Mercado Pago dashboard

# Optional: If Mercado Pago provides webhook signing secret
firebase functions:secrets:set WEBHOOK_SIGNING_SECRET
```

### Feature Flags

No new packages needed. Create file `lib/core/services/feature_flags_service.dart` from code above. Initialize in `main()` before BLoC setup.

---

## 4. Cloud Functions Implementation (Node.js 20)

Create two functions:

### Function 1: Create Pix Payment

```javascript
// functions/src/createPixPayment.js

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const MercadoPago = require('@mercadopago/sdk-node');

const client = new MercadoPago.client({
  accessToken: process.env.MERCADO_PAGO_ACCESS_TOKEN,
});

exports.createPixPayment = functions.https.onCall(async (data, context) => {
  // Verify auth
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  const { bookingId, amount, email } = data;

  if (!bookingId || !amount || amount <= 0) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid booking or amount');
  }

  try {
    // Create payment request to Mercado Pago
    const payment = await client.payment.create({
      body: {
        transaction_amount: amount,
        description: `Agendamento Vida Ativa #${bookingId}`,
        payment_method_id: 'pix',
        payer: {
          email: email,
        },
        external_reference: bookingId,
      },
    });

    const txId = payment.body.id;
    const qrCode = payment.body.point_of_interaction.transaction_data.qr_code;

    // Write to Firestore
    await admin.firestore()
      .collection('bookings')
      .doc(bookingId)
      .update({
        paymentStatus: 'pending_payment',
        pixTransactionId: txId,
        pixCreatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    return {
      success: true,
      qrCode,
      transactionId: txId,
      expiresAt: new Date(Date.now() + 30 * 60 * 1000).toISOString(), // 30 min
    };
  } catch (error) {
    console.error('Mercado Pago error:', error);
    throw new functions.https.HttpsError('internal', 'Payment creation failed');
  }
});
```

### Function 2: Webhook Handler

```javascript
// functions/src/handlePixWebhook.js

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');

exports.handlePixWebhook = functions.https.onRequest(async (req, res) => {
  // Only POST
  if (req.method !== 'POST') {
    return res.status(405).send('Method not allowed');
  }

  try {
    // Optional: Verify webhook signature if Mercado Pago provides
    const signature = req.headers['x-signature'];
    if (signature && process.env.WEBHOOK_SIGNING_SECRET) {
      const hash = crypto
        .createHmac('sha256', process.env.WEBHOOK_SIGNING_SECRET)
        .update(JSON.stringify(req.body))
        .digest('hex');

      if (hash !== signature) {
        functions.logger.warn('Invalid webhook signature');
        return res.status(403).send('Invalid signature');
      }
    }

    const { type, data } = req.body;

    // Handle payment updates
    if (type === 'payment' && data.status === 'approved') {
      const bookingId = data.external_reference;
      const pixTxId = data.id;

      // Find booking by transaction ID
      const booking = await admin.firestore()
        .collection('bookings')
        .where('pixTransactionId', '==', pixTxId)
        .limit(1)
        .get();

      if (booking.empty) {
        functions.logger.warn(`Booking not found for tx ${pixTxId}`);
        return res.status(404).send('Booking not found');
      }

      // Idempotency: Check if already confirmed
      const bookingData = booking.docs[0].data();
      if (bookingData.paymentStatus === 'confirmed') {
        return res.status(200).send('Already processed');
      }

      // Update payment status
      await booking.docs[0].ref.update({
        paymentStatus: 'confirmed',
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
        pixConfirmedAt: new Date(data.date_approved),
      });

      // Send FCM notification to admin
      const userId = bookingData.userId;
      const user = await admin.firestore().collection('users').doc(userId).get();
      if (user.exists && user.data().role === 'admin') {
        // Send FCM notification (reuse existing FCM logic)
        await admin.messaging().sendToDevice(user.data().fcmToken, {
          notification: {
            title: 'Pagamento Confirmado',
            body: `Reserva #${bookingId} foi paga`,
          },
          data: { bookingId },
        });
      }

      return res.status(200).send('Payment confirmed');
    }

    // Handle expired payments
    if (type === 'payment' && data.status === 'rejected') {
      const booking = await admin.firestore()
        .collection('bookings')
        .where('pixTransactionId', '==', data.id)
        .limit(1)
        .get();

      if (!booking.empty) {
        await booking.docs[0].ref.update({
          paymentStatus: 'failed',
          pixFailedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      return res.status(200).send('Payment failed');
    }

    return res.status(200).send('OK');
  } catch (error) {
    functions.logger.error('Webhook error:', error);
    return res.status(500).send('Internal error');
  }
});
```

---

## 5. Firestore Security Rules Updates

Add these rules to allow Cloud Function writes to payment fields:

```javascript
match /bookings/{bookingId} {
  allow read: if isAuthenticated() &&
    (request.auth.uid == resource.data.userId || isAdmin());
  
  allow create: if isAuthenticated() &&
    request.auth.uid == request.resource.data.userId;
  
  allow update: if isAuthenticated() && (
    // Client can only update participants field
    (request.auth.uid == resource.data.userId &&
     request.resource.data.diff(resource.data).affectedKeys().hasOnly(['participants']))
    ||
    // Cloud Function can update payment status
    (request.auth == null && // Unauthenticated = Cloud Function (no auth context)
     request.resource.data.diff(resource.data).affectedKeys()
       .hasOnly(['paymentStatus', 'paidAt', 'pixTransactionId', 'pixConfirmedAt', 'pixCreatedAt', 'pixFailedAt']))
    ||
    // Admin can do anything
    isAdmin()
  );
  
  allow delete: if isAuthenticated() &&
    (request.auth.uid == resource.data.userId || isAdmin());
}
```

---

## 6. What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| **Stripe** | Pix not supported; credit card only | Mercado Pago |
| **Manual Pix code only** | Poor UX; QR is standard in Brazil | QR code + copy-paste options |
| **Polling every 500ms** | Wastes Firebase quota | 3-5 second polling |
| **Hardcoded MP credentials** | Security risk | Firebase secrets manager |
| **Firebase Remote Config** | Adds operational overhead; not in existing Firestore hierarchy | Custom Firestore service |
| **Trusting webhook without verification** | Spoofing risk | Verify signature OR query API |
| **Realtime flags for clients** | Unnecessary bandwidth | Cache on init; update on next session |

---

## 7. Version Compatibility

| Package | Version | Notes |
|---------|---------|-------|
| Flutter | 3.x | Use `flutter_web` build target |
| firebase_core | 2.24.0+ | Existing |
| cloud_firestore | 4.14.0+ | Existing |
| firebase_messaging | 14.7.0+ | Existing |
| http | 1.1.0+ | Standard Flutter HTTP client |
| qr | 2.2.0+ | QR code rendering |
| Node.js (Cloud Functions) | 20 | Blaze plan (existing) |
| @mercadopago/sdk-node | 2.0.0+ | New dependency |

---

## 8. Pre-Launch Checklist

- [ ] Mercado Pago sandbox account created
- [ ] API key stored in Firebase secrets: `MERCADO_PAGO_ACCESS_TOKEN`
- [ ] Cloud Functions `createPixPayment` and `handlePixWebhook` deployed
- [ ] Webhook URL registered in Mercado Pago dashboard
- [ ] Pix flow tested end-to-end in sandbox
- [ ] `FeatureFlagsService` created and initialized in `main()`
- [ ] Feature flag checks added to: PaymentButton, NotificationService, RecurringBookingForm, SocialFeatures
- [ ] Admin UI form for feature flags created and tested
- [ ] Firestore rules updated to allow Cloud Function writes
- [ ] FCM notification on payment confirmed tested
- [ ] Sentry logging for webhook failures enabled
- [ ] Production: Mercado Pago credentials swapped to live keys

---

## 9. Performance & Reliability

### Pix Payment

- **QR Code generation latency:** Mercado Pago API ~200-300ms
- **Webhook retry:** Mercado Pago retries for ~24 hours; function must be idempotent
- **Polling interval:** 3-5 seconds is reasonable for user experience
- **Quota impact:** Each Firestore update = 1 write operation (minimal at scale)

### Feature Flags

- **Init latency:** Single Firestore read on startup (~100ms)
- **Cache strategy:** Flags cached in memory; no refresh until next app session
- **Admin listener:** `watchFlags()` stream costs 1 Firestore read per update; dispose when UI closes
- **No real-time client updates:** Intentional; avoids constant network traffic

---

## 10. Security Considerations

### Pix Payment

1. **Webhook Verification:**
   ```javascript
   const hash = crypto.createHmac('sha256', SECRET).update(payload).digest('hex');
   if (hash !== req.headers['x-signature']) throw new Error('Invalid signature');
   ```

2. **Credential Storage:**
   ```bash
   firebase functions:secrets:set MERCADO_PAGO_ACCESS_TOKEN
   # NOT in source code or .env files
   ```

3. **Idempotent Webhook Handler:**
   ```javascript
   if (booking.paymentStatus === 'confirmed') return res.status(200).send('Already processed');
   ```

4. **Firestore Rules:** Cloud Function is unauthenticated (no auth context); restrict write fields:
   ```
   request.auth == null && 
   request.resource.data.diff(resource.data).affectedKeys()
     .hasOnly(['paymentStatus', 'paidAt', 'pixTransactionId', ...])
   ```

### Feature Flags

1. **Admin-Only Writes:**
   ```
   allow update: if isAdmin()
   ```

2. **No Secrets in Flags:** Feature flags are client-readable; never store API keys, tokens, or passwords.

3. **Read Cache Locally:** Flags fetched once on init and cached; no continuous polling.

---

## 11. Sources

**Pix Payment Gateway:**
- [Mercado Pago Developers — Pix Integration](https://www.mercadopago.com.br/developers/en/docs/checkout-api/integration-configuration/integrate-with-pix)
- [Mercado Pago Webhooks](https://www.mercadopago.com.br/developers/en/docs/your-integrations/notifications/webhooks)
- [Mercado Pago vs PagSeguro Comparison (2026)](https://www.index.dev/skill-vs-skill/payment-processing-mercado-pago-vs-pagseguro-vs-payu-latam)
- [GitHub: Mercado Pago Pix Examples](https://github.com/Kramergg/Api-de-pagamento-Pix-Mercado-Pago-2024)
- [PagBank (PagSeguro) Webhooks API](https://developer.pagbank.com.br/reference/webhooks)
- [Asaas Webhooks Documentation](https://docs.asaas.com/docs/receive-asaas-events-at-your-webhook-endpoint)

**Feature Flags:**
- [Firebase Remote Config — Flutter Docs](https://firebase.flutter.dev/docs/remote-config/overview/)
- [Feature Flags Best Practices — Toggly](https://toggly.io/blog/feature-flags-in-flutter/)
- [Firebase Remote Config + Flutter (Medium)](https://medium.com/tarmac/feature-flags-setup-in-flutter-with-firebase-remote-config-9c5fea6c31a)

**Security:**
- [Firebase Security Checklist](https://firebase.google.com/support/guides/security-checklist)
- [Cloud Functions Security Best Practices](https://firebase.google.com/docs/functions)
- [Firebase App Check for Cloud Functions](https://firebase.google.com/docs/app-check/cloud-functions)

---

## Context: Existing Stack (v1-v3)

This research builds on the existing validated stack:

| Package | Version | Role |
|---------|---------|------|
| firebase_core | 2.24.0+ | Firebase bootstrap |
| firebase_auth | ^6.2.0 | Auth (Google + email/password) |
| cloud_firestore | 4.14.0+ | Primary database |
| flutter_bloc | ^8.0.0 | State management |
| go_router | ^14.0.0 | Routing |
| firebase_messaging | ^14.7.0 | Push notifications (FCM) |
| sentry_flutter | Latest | Error monitoring |

v4.0 adds only: `http`, `qr`, and custom `FeatureFlagsService`. No breaking changes to existing code.

---

**Research Complete: Vida Ativa v4.0 Stack**  
*Researched: 2026-04-06*

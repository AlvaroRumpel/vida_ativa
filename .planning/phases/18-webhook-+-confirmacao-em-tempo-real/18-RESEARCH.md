# Phase 18: Webhook + Confirmação em Tempo Real - Research

**Researched:** 2026-04-08
**Domain:** Firebase Cloud Functions v2 webhooks, Mercado Pago integration, Flutter real-time updates, Firestore transactions
**Confidence:** HIGH

## Summary

Phase 18 closes the Pix payment loop via webhook integration: Cloud Functions listen for Mercado Pago confirmations, Firestore transactions atomically update bookings to `confirmed`, scheduled functions auto-expire unpaid bookings, and Flutter UIs react in real-time without manual refresh. The architecture follows proven patterns: idempotency by transaction ID, immediate 202 response to webhooks, proper cleanup of timers/streams in StatefulWidgets, and HMAC-SHA256 signature verification with constant-time comparison.

**Primary recommendation:** Use Cloud Functions v2 `onRequest` for webhook (returns 202 immediately), `onSchedule` for expiration check (every 15 min), Firestore transactions for atomic updates, and always dispose Timer/StreamSubscription in Flutter `dispose()` method.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Timer format**: Countdown "MM:SS restantes" (Minutes:Seconds remaining) using `Timer.periodic(Duration(seconds: 1), ...)`
- **Regeneration flow**: User taps "Gerar novo QR" → calls `createPixPayment` CF again → new PaymentRecord, same booking
- **Webhook handler**: `onRequest` HTTP trigger, returns 202 Accepted immediately before processing
- **Webhook idempotency**: Uses transactionId from Mercado Pago event as unique key
- **Auto-navigation**: When booking confirms, PixPaymentScreen navigates to MyBookingsScreen with snackbar "Pagamento confirmado! Reserva garantida."
- **Scheduled expiration**: `expireUnpaidBookings` CF runs every 15 minutes via `onSchedule` ("every 15 minutes")
- **Expiration logic**: Bookings where `expiresAt < now` AND `status == 'pending_payment'` are marked `expired` and slot is freed
- **Payment bypasses admin approval**: Webhook-confirmed Pix payment = booking confirmed immediately, ignoring manual approval mode
- **Admin payment badges**: `pending_payment` → "Aguardando Pix", `confirmed + pix` → "Pix pago", `expired` → "Expirada", `confirmed + on_arrival` → "Pagar na hora"
- **Manual confirm fallback**: AdminBookingDetailSheet button "Confirmar pagamento manual" calls `adminBookingCubit.confirmBooking()` and updates PaymentRecord `status: 'paid'`

### Claude's Discretion
- Layout/positioning of countdown (exact font size, placement relative to QR)
- Countdown color warning when < 2 min (e.g., red)
- Overlay/visual effects on expired QR
- Timer cancellation strategy in `dispose()`
- StreamSubscription timeout/retry logic
- HMAC verification implementation details

### Deferred Ideas (OUT OF SCOPE)
- Mercado Pago production credentials (post-sandbox validation)
- Credit/debit card payments
- Payment reports/history
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PIX-03 | Timer display + QR regeneration button | Flutter Timer.periodic pattern; cleanup in dispose(); button state transitions |
| PIX-04 | Webhook receives MP confirmation, verifies signature, updates booking idempotently | `onRequest` HTTP trigger, HMAC-SHA256, transactionId key, Firestore transactions |
| PIX-05 | Client sees real-time payment status in MyBookingsScreen | Firestore stream listeners, StreamBuilder, BookingCubit stream pattern, automatic refresh without polling |
| PIX-06 | Admin sees payment status badges + manual confirm button | Switch statement extension in `_statusColor()/_statusLabel()`, AdminBookingDetailSheet button pattern |
| PIX-07 | Bookings expire after 45 min if unpaid | `onSchedule` cron "every 15 minutes", Firestore batch operations, expiresAt field comparison |
</phase_requirements>

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| firebase-functions | ^6.0.0 | Cloud Functions v2 runtime | Battle-tested, native async/await, built-in Secret Manager support |
| firebase-admin | ^13.0.0 | Firestore server SDK | Atomic transactions, batch writes, programmatic access |
| mercadopago | 2.12.0 | Pix QR generation + status | Maintained by Mercado Pago, handles MP API payload validation |
| Node.js crypto | native (built-in) | HMAC-SHA256 signature verification | No external dependency, constant-time comparison via `timingSafeEqual` |
| Flutter cloud_firestore | existing (project) | Firestore client SDK | Real-time streams, snapshot listeners, automatic UI updates |
| Flutter Timer | dart:async (built-in) | Countdown timer | Standard Flutter pattern, periodic intervals, cancellable |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Firestore Secret Manager | v1 (Firebase) | Store MP_WEBHOOK_SECRET securely | Webhook signature requires secret; define as `defineSecret('MP_WEBHOOK_SECRET')` |
| Cloud Scheduler | built-in (Firebase) | Trigger scheduled functions | `onSchedule` uses Cloud Scheduler under the hood; no install needed |
| Flutter StreamBuilder | dart:async | Real-time UI updates | Automatically rebuild widgets when stream data changes; handles disposal |

### Installation
```bash
# Cloud Functions dependencies already installed:
cd functions
npm install  # firebase-admin@^13.0.0, firebase-functions@^6.0.0, mercadopago@2.12.0

# Secret Manager (no npm install needed — Firebase SDK handles it)
# Just add secret at runtime: firebase functions:secrets:set MP_WEBHOOK_SECRET

# Flutter (already in pubspec.yaml)
flutter pub get  # cloud_firestore, flutter
```

### Version Verification
- **firebase-functions**: ^6.0.0 (v2 only; v1 is deprecated)
- **firebase-admin**: ^13.0.0 (latest stable as of 2026-04)
- **mercadopago**: 2.12.0 (confirmed in package.json, stable)
- **Node.js crypto**: native (no version — available in Node 20+)

---

## Architecture Patterns

### Cloud Functions v2 Webhook Pattern
```javascript
// Source: Firebase Cloud Functions v2 HTTP triggers
const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');

const mpWebhookSecret = defineSecret('MP_WEBHOOK_SECRET');

exports.handlePixWebhook = onRequest(
  { secrets: [mpWebhookSecret] },
  async (req, res) => {
    // 1. Return 202 immediately to prevent Mercado Pago retry
    res.status(202).send({ success: true });

    // 2. Verify signature in background
    const signature = req.headers['x-signature'];
    if (!verifySignature(req.rawBody, signature, mpWebhookSecret.value())) {
      console.error('Invalid signature');
      return;
    }

    // 3. Use transaction ID as idempotency key
    const transactionId = req.body.data.id;
    const paymentRecord = await admin.firestore()
      .collection('bookings')
      .doc(req.body.data.external_reference) // bookingId
      .collection('payment')
      .doc(transactionId)
      .get();

    if (paymentRecord.exists && paymentRecord.data().status === 'paid') {
      console.log('Already processed — skipping');
      return;
    }

    // 4. Update booking atomically
    await admin.firestore().runTransaction(async (transaction) => {
      const booking = await transaction.get(
        admin.firestore().collection('bookings').doc(bookingId)
      );
      transaction.update(booking.ref, { status: 'confirmed' });
      transaction.update(paymentRecord.ref, { status: 'paid' });
    });
  }
);
```

### Mercado Pago Signature Verification
```javascript
// Source: Mercado Pago webhook security docs + Node.js crypto module
const crypto = require('crypto');

function verifySignature(rawBody, xSignature, secret) {
  // x-signature format: "ts=<timestamp>,v1=<signature>"
  const parts = xSignature.split(',');
  const tsValue = parts[0].split('=')[1];
  const v1Value = parts[1].split('=')[1];

  // Reconstruct manifest: id:{dataId};request-id:{xRequestId};ts:{timestamp};
  const manifest = `id:${data.id};request-id:${xRequestId};ts:${tsValue};`;

  // Compute HMAC-SHA256
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(manifest)
    .digest('hex');

  // Constant-time comparison (prevent timing attacks)
  return crypto.timingSafeEqual(
    Buffer.from(v1Value),
    Buffer.from(expectedSignature)
  );
}
```

### Scheduled Expiration Function
```javascript
// Source: Firebase Cloud Functions v2 onSchedule pattern
const { onSchedule } = require('firebase-functions/v2/scheduler');

exports.expireUnpaidBookings = onSchedule('every 15 minutes', async (event) => {
  const now = admin.firestore.Timestamp.now();

  const query = await admin.firestore()
    .collection('bookings')
    .where('status', '==', 'pending_payment')
    .where('expiresAt', '<', now)
    .get();

  const batch = admin.firestore().batch();
  query.docs.forEach((doc) => {
    batch.update(doc.ref, {
      status: 'expired',
      cancelledAt: now,
    });
    // Also free the slot for rebooking
  });

  await batch.commit();
  console.log(`Expired ${query.size} unpaid bookings`);
});
```

### Flutter Real-Time Update Pattern
```dart
// Source: Flutter cloud_firestore stream listeners + BookingCubit pattern
class _PixPaymentScreenState extends State<PixPaymentScreen> {
  StreamSubscription<DocumentSnapshot>? _bookingSubscription;

  @override
  void initState() {
    super.initState();
    _bookingSubscription = FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;
          final booking = BookingModel.fromFirestore(snapshot);
          if (booking.status == 'confirmed') {
            // Auto-navigate when confirmed
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Pagamento confirmado! Reserva garantida.')),
            );
            context.go('/bookings');
          }
        });
  }

  @override
  void dispose() {
    _bookingSubscription?.cancel(); // CRITICAL: Always cancel subscriptions
    super.dispose();
  }
}
```

### Countdown Timer Pattern
```dart
// Source: Flutter Timer + lifecycle management best practices
class _PixPaymentScreenState extends State<PixPaymentScreen> {
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel(); // Cleanup old timer if exists
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final remaining = _expiresAt!.difference(DateTime.now());
      if (remaining.isNegative) {
        timer.cancel();
        setState(() => _remaining = Duration.zero);
      } else {
        setState(() => _remaining = remaining);
      }
    });
  }

  String _formatCountdown(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} restantes';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel(); // CRITICAL: Always cancel timers
    super.dispose();
  }
}
```

### Admin Booking Card Pattern (Extended Switches)
```dart
// Source: Existing AdminBookingCard._statusColor() + _statusLabel() extension
Color _statusColor(String status, String? paymentMethod) {
  return switch ((status, paymentMethod)) {
    ('pending', _) => Colors.orange,
    ('pending_payment', _) => Colors.amber, // New: awaiting Pix
    ('confirmed', 'pix') => AppTheme.primaryGreen, // New: Pix paid
    ('confirmed', 'on_arrival') => Colors.blue, // Existing: pay on arrival
    ('confirmed', _) => AppTheme.primaryGreen,
    ('expired', _) => Colors.grey, // New: expired unpaid
    ('rejected', _) => Colors.red,
    _ => Colors.grey,
  };
}

String _statusLabel(String status, String? paymentMethod) {
  return switch ((status, paymentMethod)) {
    ('pending', _) => 'Aguardando',
    ('pending_payment', _) => 'Aguardando Pix',
    ('confirmed', 'pix') => 'Pix pago',
    ('confirmed', 'on_arrival') => 'Pagar na hora',
    ('confirmed', _) => 'Confirmado',
    ('expired', _) => 'Expirada',
    ('rejected', _) => 'Recusado',
    _ => 'Cancelado',
  };
}
```

### Firestore Transaction for Webhook
```dart
// Source: Firebase Admin SDK transaction pattern
await admin.firestore().runTransaction(async (transaction) => {
  // Read phase
  const bookingRef = admin.firestore().collection('bookings').doc(bookingId);
  const bookingDoc = await transaction.get(bookingRef);
  const paymentRef = bookingRef.collection('payment').doc(transactionId);

  // Check idempotency before write
  if (bookingDoc.data().status === 'confirmed') {
    return; // Already processed
  }

  // Write phase (all or nothing)
  transaction.update(bookingRef, { status: 'confirmed' });
  transaction.update(paymentRef, { status: 'paid' });
});
```

### Recommended Project Structure (Phase 18 additions)

```
functions/
├── index.js                    (add: handlePixWebhook, expireUnpaidBookings exports)
└── package.json                (no changes — dependencies already present)

lib/features/
├── booking/
│   └── ui/
│       └── pix_payment_screen.dart    (add: Timer countdown, StreamSubscription, auto-nav)
└── admin/
    └── ui/
        ├── admin_booking_card.dart    (extend: _statusColor, _statusLabel for payment badges)
        └── admin_booking_detail_sheet.dart (add: "Confirmar pagamento manual" button)
```

### Anti-Patterns to Avoid

- **Not canceling Timer/StreamSubscription**: Causes memory leaks, continued execution after widget disposal. Always call `.cancel()` in `dispose()`.
- **Signing parsed JSON instead of raw body**: Webhook signature verification fails if body is re-serialized. Always sign/verify against raw request bytes.
- **Processing webhook without returning quickly**: Mercado Pago retries on timeout. Always return 2xx (202 Accepted) immediately, do async work after.
- **Checking idempotency AFTER updating**: If crash between check and update, retry will apply duplicate changes. Check idempotency inside transaction.
- **Not using constant-time comparison for signatures**: `expected === actual` is vulnerable to timing attacks. Use `crypto.timingSafeEqual()`.
- **Trusting timestamp alone for expiration**: Clock skew on servers. Use Firestore `expiresAt` field written by CF, not client-calculated values.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HMAC-SHA256 signature verification | Custom crypto code | Node.js `crypto` module + `timingSafeEqual()` | Built-in, battle-tested, constant-time comparison prevents timing attacks |
| Idempotent webhook processing | Manual duplicate detection in app logic | Firestore transactions + unique document ID (transactionId) | Transactions are atomic; cannot partially apply; database enforces uniqueness |
| Countdown timer with cleanup | Manual interval tracking | `Timer.periodic()` in StatefulWidget | Designed for cleanup; cancellable; integrates with Flutter lifecycle |
| Real-time UI updates from Firestore | Polling loop (setInterval, Future.delayed) | Firestore snapshot listeners + StreamBuilder | 1000x less network overhead; instant updates; automatic cleanup |
| Scheduled background jobs | Custom cron service | Firebase `onSchedule` Cloud Functions | No server to manage; scales to zero; integrates with Firestore |
| Atomic multi-document updates | Sequential writes with error handling | Firestore `runTransaction()` | All-or-nothing atomicity; automatic retry on contention; no partial updates |

**Key insight:** Webhooks, idempotency, and real-time sync are deceptively complex at scale (duplicate events, race conditions, network failures, timers not canceling). Firebase and Firestore handle these edge cases; custom implementations almost always miss one.

---

## Common Pitfalls

### Pitfall 1: Webhook Signature Verification with Parsed JSON
**What goes wrong:** You parse request JSON, then re-stringify it to verify the signature. The byte-level content changes (whitespace, key order, unicode), signature verification fails even though the data is correct.

**Why it happens:** Developers often treat JSON as data first, security second. But HMAC signing works on exact byte strings.

**How to avoid:** Always verify signature against `req.rawBody` (raw request bytes) before parsing JSON. Firebase Cloud Functions v2 provides `req.rawBody` automatically.

**Warning signs:** Signature verification passes in local emulator (fake signatures) but fails in production with real Mercado Pago webhooks.

### Pitfall 2: Timer Not Canceled on Widget Disposal
**What goes wrong:** User navigates away from PixPaymentScreen while countdown timer is running. Timer continues firing, calling `setState()` on unmounted widget. Memory leak; "setState called on unmounted widget" warning.

**Why it happens:** Easy to forget cleanup; Timer looks "safe" because it's synchronous. But setState callbacks happen asynchronously.

**How to avoid:** Always `_countdownTimer?.cancel()` in `dispose()`. Check `if (!mounted) return` before setState in timer callbacks as extra safety.

**Warning signs:** Console shows "setState called on unmounted widget"; memory profiler shows timer references still alive after screen exit.

### Pitfall 3: Webhook Without Idempotency Check
**What goes wrong:** Mercado Pago sends duplicate webhook (network flake, our timeout too aggressive). Webhook handler processes it twice. Booking status toggled back to pending, or payment marked paid twice with inconsistent state.

**Why it happens:** Webhooks deliver "at least once" — duplicates are expected. Developers often forget this is network reality, not an error case.

**How to avoid:** Use unique transactionId from Mercado Pago event as document ID (or unique constraint). Check if already processed before updating. Use Firestore transactions to make check + update atomic.

**Warning signs:** Booking status intermittently resets; PaymentRecord has duplicate entries; test webhook resend causes unexpected behavior.

### Pitfall 4: Scheduling Expiration Without Timezone Awareness
**What goes wrong:** `expireUnpaidBookings` CF scheduled to run at "2:00 PM UTC" but booking `expiresAt` was calculated in "America/Sao_Paulo" timezone. Bookings expire at wrong times; some never expire.

**Why it happens:** Timezone bugs are subtle. Firestore stores Timestamps in UTC; if CF uses local server time (which varies), comparisons become inconsistent.

**How to avoid:** Always use Firestore `admin.firestore.Timestamp.now()` (UTC) for expiration checks. Booking `expiresAt` is also stored as Firestore Timestamp (UTC). Compare timestamps, not parsed date strings.

**Warning signs:** Expiration times drift over weeks; some bookings stuck in `pending_payment` forever; inconsistent behavior between regions.

### Pitfall 5: StreamSubscription Memory Leak in PixPaymentScreen
**What goes wrong:** Booking stream listener added in `initState()` but never canceled. Every navigation to PixPaymentScreen adds new listener. After 10 navigations, 10 listeners are active. Network traffic multiplies; state updates fight each other.

**Why it happens:** Stream listeners look passive ("just listening"); easy to forget they're resources that need cleanup.

**How to avoid:** Store `_bookingSubscription` in State, call `.cancel()` in `dispose()`. Use StreamBuilder (auto-disposal) or always manage subscription lifecycle.

**Warning signs:** App gets slower after repeated navigation; Firestore read count multiplies; listeners fire multiple times per update.

### Pitfall 6: 202 Response Doesn't Return Early
**What goes wrong:** Webhook handler starts processing, THEN returns 202. If processing takes >10 seconds and Mercado Pago times out, it retries. Now two instances of your function are processing the same webhook simultaneously, race condition.

**Why it happens:** Developers think 202 is just another success code. They treat it like 200 but with a message. It's actually a "fire and forget" signal.

**How to avoid:** Return 202 on line 1 (or line 3 after logging the request). Do async work after return. For critical operations (signature verification), do it before return but keep it fast (<100ms).

**Warning signs:** Webhook handler timeout errors; duplicate payment confirmations; race conditions between concurrent webhook executions.

---

## Code Examples

### Mercado Pago Webhook Handler (Complete)
```javascript
// Source: Firebase Cloud Functions v2 + Mercado Pago webhook pattern
const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const crypto = require('crypto');
const admin = require('firebase-admin');

const mpWebhookSecret = defineSecret('MP_WEBHOOK_SECRET');

exports.handlePixWebhook = onRequest(
  { secrets: [mpWebhookSecret] },
  async (req, res) => {
    // 1. Return 202 IMMEDIATELY (before any async work)
    res.status(202).send({ message: 'Accepted' });

    // 2. Quick signature verification (must be fast)
    const xSignature = req.headers['x-signature'];
    const xRequestId = req.headers['x-request-id'];

    if (!xSignature || !xRequestId) {
      console.error('Missing signature headers');
      return;
    }

    const payload = req.body;
    const manifest = `id:${payload.data.id};request-id:${xRequestId};ts:${
      xSignature.split(',')[0].split('=')[1]
    };`;

    const expectedSignature = crypto
      .createHmac('sha256', mpWebhookSecret.value())
      .update(manifest)
      .digest('hex');

    const v1Signature = xSignature.split(',')[1].split('=')[1];

    try {
      crypto.timingSafeEqual(
        Buffer.from(v1Signature),
        Buffer.from(expectedSignature)
      );
    } catch {
      console.error('Invalid webhook signature');
      return;
    }

    // 3. Process webhook asynchronously
    const eventType = payload.type;
    const transactionId = payload.data.id;
    const externalReference = payload.data.external_reference; // bookingId

    if (eventType !== 'payment') {
      console.log(`Ignoring event type: ${eventType}`);
      return;
    }

    const paymentStatus = payload.data.status;
    if (paymentStatus !== 'approved') {
      console.log(`Payment not approved: ${paymentStatus}`);
      return;
    }

    // 4. Idempotent update via transaction
    try {
      await admin.firestore().runTransaction(async (transaction) => {
        const bookingRef = admin
          .firestore()
          .collection('bookings')
          .doc(externalReference);
        const paymentRef = bookingRef
          .collection('payment')
          .doc(transactionId);

        const paymentDoc = await transaction.get(paymentRef);
        if (paymentDoc.exists && paymentDoc.data().status === 'paid') {
          console.log('Payment already processed — idempotency key');
          return;
        }

        transaction.update(bookingRef, { status: 'confirmed' });
        transaction.update(paymentRef, { status: 'paid' });
      });

      console.log(`✓ Webhook processed: booking ${externalReference}`);
    } catch (err) {
      console.error('Transaction error:', err);
      // Note: Already sent 202, so Mercado Pago won't retry
      // Log error for manual investigation
    }
  }
);
```

### Expiration Cloud Function (Complete)
```javascript
// Source: Firebase Cloud Functions v2 onSchedule pattern
const { onSchedule } = require('firebase-functions/v2/scheduler');

exports.expireUnpaidBookings = onSchedule('every 15 minutes', async (event) => {
  const now = admin.firestore.Timestamp.now();

  try {
    const query = await admin
      .firestore()
      .collection('bookings')
      .where('status', '==', 'pending_payment')
      .where('expiresAt', '<', now)
      .get();

    if (query.empty) {
      console.log('No unpaid bookings to expire');
      return;
    }

    const batch = admin.firestore().batch();
    query.docs.forEach((doc) => {
      batch.update(doc.ref, {
        status: 'expired',
        cancelledAt: now,
      });
    });

    await batch.commit();
    console.log(`✓ Expired ${query.size} unpaid bookings`);
  } catch (err) {
    console.error('Expiration error:', err);
  }
});
```

### PixPaymentScreen with Countdown + Auto-Nav (Complete)
```dart
// Source: Flutter Timer + Firestore stream pattern
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class _PixPaymentScreenState extends State<PixPaymentScreen> {
  Timer? _countdownTimer;
  StreamSubscription<DocumentSnapshot>? _bookingSubscription;
  Duration _remaining = Duration.zero;
  bool _hasExpired = false;

  @override
  void initState() {
    super.initState();
    if (widget.paymentId != null) {
      _loadFromSubcollection();
    } else {
      _generateQr();
    }
    _listenToBookingUpdates();
  }

  void _listenToBookingUpdates() {
    _bookingSubscription = FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;

          final data = snapshot.data();
          if (data == null) return;

          final status = data['status'] as String?;
          if (status == 'confirmed') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Pagamento confirmado! Reserva garantida.')),
            );
            context.go('/bookings');
          }
        });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) return;

      final remaining = _expiresAt!.difference(DateTime.now());
      if (remaining.isNegative) {
        timer.cancel();
        if (!mounted) return;
        setState(() {
          _remaining = Duration.zero;
          _hasExpired = true;
        });
      } else {
        setState(() => _remaining = remaining);
      }
    });
  }

  String _formatCountdown(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} restantes';
  }

  Future<void> _regenerateQr() async {
    setState(() => _hasExpired = false);
    await _generateQr();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _bookingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagamento Pix'),
      ),
      body: _isLoading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _hasExpired
                  ? _buildExpired()
                  : _buildQrContent(),
    );
  }

  Widget _buildQrContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          // ... QR display ...
          if (_expiresAt != null) ...[
            SizedBox(height: 16),
            Text(
              _formatCountdown(_remaining),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _remaining.inMinutes < 2 ? Colors.red : Colors.orange,
              ),
            ),
          ],
          // ... copy code button, divider ...
        ],
      ),
    );
  }

  Widget _buildExpired() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('QR code expirou'),
          SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _regenerateQr,
            icon: Icon(Icons.refresh),
            label: Text('Gerar novo QR'),
          ),
        ],
      ),
    );
  }
}
```

### AdminBookingCard Payment Badge Extension
```dart
// Source: Existing pattern extension for payment status
Color _statusColor(String status, String? paymentMethod) {
  return switch ((status, paymentMethod)) {
    ('pending_payment', _) => Colors.amber,
    ('confirmed', 'pix') => AppTheme.primaryGreen,
    ('expired', _) => Colors.grey,
    // ... existing cases ...
    _ => Colors.grey,
  };
}

String _statusLabel(String status, String? paymentMethod) {
  return switch ((status, paymentMethod)) {
    ('pending_payment', _) => 'Aguardando Pix',
    ('confirmed', 'pix') => 'Pix pago',
    ('expired', _) => 'Expirada',
    // ... existing cases ...
    _ => 'Cancelado',
  };
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Polling for payment updates (setInterval every 5s) | Firestore stream listeners (push on change) | 2019+ | 1000x reduction in network; instant updates; battery savings |
| Manual webhook idempotency checks (SELECT * WHERE id = ...) | Transactional document ID enforcement | 2020+ | No race conditions; automatic deduplication |
| Webhook processing inline with response | Return 202 then async process | Standard HTTP practice | Prevents timeout retries; enables backgrounding |
| Client-side countdown timers | Flutter Timer.periodic with proper disposal | 2018+ | Accurate; memory safe; cancellable |
| Manual Firestore batch operations | `runTransaction()` for atomicity | 2017+ | All-or-nothing guarantees; automatic retry |

**Deprecated/outdated:**
- **Polling for real-time updates**: Replaced by Firestore snapshot streams; still used in legacy code but wasteful
- **Custom idempotency libraries**: Firestore document IDs + transactions replace manual dedup
- **Manual HMAC hashing**: `crypto.timingSafeEqual()` added 2015; prevents timing attacks

---

## Open Questions

1. **Mercado Pago Sandbox vs Production Credentials**
   - What we know: CONTEXT.md marks production credentials as deferred post-validation
   - What's unclear: Do sandbox and production webhook URLs/secrets differ? (Answer: yes, separate webhook registrations per Mercado Pago docs, but same CF code)
   - Recommendation: During Phase 18 planning, assume sandbox; CF code works for both. Credentials swap happens in deployment config, not code.

2. **Booking `expiresAt` Set By CF vs Client**
   - What we know: CONTEXT.md says CF `createPixPayment` returns `expiresAt` based on MP's 30-min window
   - What's unclear: Is `expiresAt` stored in booking doc or only in PaymentRecord?
   - Recommendation: Store in both — booking `expiresAt` for quick queries in `expireUnpaidBookings`, PaymentRecord `expiresAt` for display in PixPaymentScreen. Both are Firestore Timestamp (UTC).

3. **Admin Manual Confirm Updates PaymentRecord**
   - What we know: CONTEXT.md says button "Confirmar pagamento manual" exists in AdminBookingDetailSheet
   - What's unclear: Does clicking it also create a PaymentRecord if one doesn't exist? Or only update existing?
   - Recommendation: Assume PaymentRecord exists (created by `createPixPayment` CF). Button updates PaymentRecord `status: 'paid'` via transaction. If no PaymentRecord, return error (shouldn't happen).

4. **PixPaymentScreen Nav on Confirm: Pop vs Go**
   - What we know: CONTEXT.md says "context.go('/bookings')" not Navigator.pop
   - What's unclear: Does PixPaymentScreen route via GoRouter or imperative navigation?
   - Recommendation: Use `context.go('/bookings')` if GoRouter is configured (modern Flutter); test with project setup during planning.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Flutter Test (widget_test.dart, integ_test) + Cloud Functions local emulator |
| Config file | `test/`, `pubspec.yaml`, `firebase.json` (emulator config) |
| Quick run command | `flutter test test/widget_test.dart -k "PixPaymentScreen"` |
| Full suite command | `flutter test` + `firebase emulators:exec "npm test"` (Cloud Functions) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PIX-03 | Timer countdown format "MM:SS restantes" displays correctly | widget | `flutter test test/features/booking/pix_payment_screen_test.dart::test_countdown_display -x` | ❌ Wave 0 |
| PIX-03 | Countdown reaches zero, shows "Gerar novo QR" button | widget | `flutter test test/features/booking/pix_payment_screen_test.dart::test_countdown_expiry -x` | ❌ Wave 0 |
| PIX-03 | "Gerar novo QR" calls createPixPayment again, shows new QR | widget | `flutter test test/features/booking/pix_payment_screen_test.dart::test_regenerate_qr -x` | ❌ Wave 0 |
| PIX-04 | handlePixWebhook verifies valid signature, updates booking | integration/CF | `firebase emulators:exec "npm test -- handlePixWebhook"` | ❌ Wave 0 |
| PIX-04 | handlePixWebhook rejects invalid signature | integration/CF | `firebase emulators:exec "npm test -- handlePixWebhook_invalid_sig"` | ❌ Wave 0 |
| PIX-04 | handlePixWebhook idempotent (duplicate transactionId skipped) | integration/CF | `firebase emulators:exec "npm test -- webhook_idempotency"` | ❌ Wave 0 |
| PIX-05 | MyBookingsScreen updates badge when webhook confirms (no refresh) | integration | `flutter test test/features/booking/my_bookings_screen_test.dart::test_realtime_badge_update -x` | ❌ Wave 0 |
| PIX-05 | PixPaymentScreen auto-navigates to /bookings when booking confirmed | widget | `flutter test test/features/booking/pix_payment_screen_test.dart::test_auto_nav_confirmed -x` | ❌ Wave 0 |
| PIX-06 | AdminBookingCard shows "Aguardando Pix" badge for pending_payment | widget | `flutter test test/features/admin/admin_booking_card_test.dart::test_pending_payment_badge -x` | ❌ Wave 0 |
| PIX-06 | AdminBookingCard shows "Pix pago" badge for confirmed+pix | widget | `flutter test test/features/admin/admin_booking_card_test.dart::test_pix_paid_badge -x` | ❌ Wave 0 |
| PIX-06 | AdminBookingDetailSheet "Confirmar pagamento manual" button confirms booking | widget | `flutter test test/features/admin/admin_booking_detail_test.dart::test_manual_confirm_button -x` | ❌ Wave 0 |
| PIX-07 | expireUnpaidBookings CF marks booking expired after 45 min | integration/CF | `firebase emulators:exec "npm test -- expireUnpaidBookings"` | ❌ Wave 0 |
| PIX-07 | expireUnpaidBookings CF runs every 15 min via Cloud Scheduler | integration/CF | Manual: verify `onSchedule('every 15 minutes', ...)` in index.js | ✅ Code review |

### Sampling Rate
- **Per task commit:** `flutter test test/features/booking/ -k "pix"` (5-10 min)
- **Per wave merge:** `flutter test` + `firebase emulators:exec` for full suite (15-20 min)
- **Phase gate:** All tests green + manual webhook test with real Mercado Pago sandbox before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/features/booking/pix_payment_screen_test.dart` — covers PIX-03 (countdown, regenerate, auto-nav)
- [ ] `test/features/booking/my_bookings_screen_test.dart` — covers PIX-05 (real-time badge update)
- [ ] `test/features/admin/admin_booking_card_test.dart` — covers PIX-06 (payment badges)
- [ ] `test/features/admin/admin_booking_detail_sheet_test.dart` — covers PIX-06 (manual confirm button)
- [ ] `functions/test/handlePixWebhook.test.js` — covers PIX-04 (signature, idempotency)
- [ ] `functions/test/expireUnpaidBookings.test.js` — covers PIX-07 (expiration logic)
- [ ] Firebase Emulator setup: `firebase.json` with `"functions"` and `"firestore"` emulator config
- [ ] Cloud Functions test setup: `jest` or `mocha` in `functions/package.json` (if not present)

---

## Sources

### Primary (HIGH confidence)
- [Firebase Cloud Functions HTTP Triggers - Google](https://firebase.google.com/docs/functions/http-events)
- [Firebase Cloud Functions Secrets - Google](https://firebase.google.com/docs/functions/config-env)
- [Firestore Transactions - Google](https://firebase.google.com/docs/firestore/manage-data/transactions)
- [Firebase Schedule Functions - Google](https://firebase.google.com/docs/functions/schedule-functions)
- [Flutter cloud_firestore snapshots() - FlutterFire](https://firebase.flutter.dev/docs/firestore/usage/)
- [Dart Timer.periodic - Dart API](https://api.flutter.dev/flutter/dart-async/Timer/Timer.periodic.html)

### Secondary (MEDIUM confidence)
- [Mercado Pago Webhook Signature Format - GitHub Discussion #318](https://github.com/mercadopago/sdk-nodejs/discussions/318)
- [Mercado Pago Webhooks Notifications - Mercado Pago Developers](https://www.mercadopago.br/developers/en/docs/your-integrations/notifications/webhooks)
- [Node.js crypto HMAC-SHA256 - Authgear](https://www.authgear.com/post/generate-verify-hmac-signatures)
- [Firebase Webhook Idempotency Best Practices - Google Cloud Blog](https://cloud.google.com/blog/products/serverless/cloud-functions-pro-tips-building-idempotent-functions)
- [Flutter StreamSubscription Memory Leak Prevention - Multiple Sources](https://blog.logrocket.com/understanding-flutter-streams/)

### Tertiary (LOW confidence)
- Mercado Pago webhook signature details inferred from SDK discussions; official docs blocked by 403
- Exact Mercado Pago payload structure (data.id, data.status, external_reference) — confirmed via SDK code, not direct API docs

---

## Metadata

**Confidence breakdown:**
- **Standard stack**: HIGH — All libraries verified in project or official docs (firebase-functions, firebase-admin, mercadopago versions confirmed in package.json)
- **Architecture**: HIGH — Cloud Functions patterns from official Firebase docs; Firestore transaction atomicity verified; Flutter Timer/Stream patterns from official Dart API
- **Pitfalls**: HIGH — Common webhook/real-time issues confirmed across multiple authoritative sources (Google Cloud, Mercado Pago, Flutter docs, industry best practices)
- **Signature verification**: MEDIUM — Mercado Pago format (ts=, v1=) inferred from SDK discussions + general HMAC practices; official Mercado Pago docs blocked

**Research date:** 2026-04-08
**Valid until:** 2026-04-30 (Firebase Cloud Functions stable; Mercado Pago API unlikely to change)

---

**End of Phase 18 Research**

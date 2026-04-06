# Architecture: Feature Toggles + Pix Payment Integration

**Domain:** Flutter Web PWA booking system — adding feature flags and Pix payment to existing BLoC architecture
**Researched:** 2026-04-06
**Milestone:** v4.0 Modularização & Pagamento Pix
**Confidence:** HIGH (BLoC patterns are mature; Pix webhook patterns verified against Firebase docs)

---

## Recommended Architecture

### System Overview

Feature toggles and Pix payment integrate into the **existing flutter_bloc architecture** by:

1. **Feature toggles:** Load Firestore config at app startup → expose via ConfigCubit → accessed immutably by widgets
2. **Pix payment:** Decouple payment from booking → store payment state separately → webhook updates Firestore → listener streams updates to UI

```
App Startup
  ↓
Firebase.initializeApp()
  ↓
Load /config/booking doc from Firestore
  ↓
Create ConfigCubit with config
  ↓
Provide to widget tree via BlocProvider
  ↓
Home screen loads → feature flags govern tab visibility, UI options
  ↓
---
  ↓
User creates booking
  ↓
CreateBooking(slotId, date)
  ↓
If enablePixPayment:
  Create /bookings/{id} with status: "pending_payment"
  Create /bookings/{id}/payment/{txId} with QR code details
  Display QR code screen
  ↓
User scans/pays via Pix
  ↓
Pix provider sends webhook
  ↓
Cloud Function updates /bookings/{id}/payment.status = "paid"
  ↓
Listener fires → BookingCubit emits state update
  ↓
UI shows "Payment confirmed"
  ↓
If autoConfirm: status → "confirmed" automatically (Cloud Function trigger)
If manual: Admin clicks confirm button → status → "confirmed"
```

---

## Component Boundaries

| Component | Responsibility | Communicates With | New/Existing |
|-----------|---------------|-------------------|---|
| **ConfigRepository** | Fetch `/config/booking` doc from Firestore once | Firestore | NEW |
| **ConfigCubit** | Expose `FeatureConfig` as immutable state after app init | Widget tree via BlocProvider | NEW |
| **PixPaymentRepository** | Track payment status via `/bookings/{id}/payment` listener | Firestore, BookingCubit | NEW |
| **BookingRepository** | Create booking with `status: pending_payment` if Pix enabled | Firestore, PixPaymentRepository | MODIFIED |
| **BookingCubit** | Orchestrate booking + payment creation; emit state updates | BookingRepository, ConfigCubit | MODIFIED |
| **AdminBookingCubit** | Stream admin booking list; add payment status to details | Firestore, ConfigCubit | MODIFIED |
| **Cloud Function (Webhook)** | Receive webhook from Pix provider; update Firestore | Pix provider, Firestore | NEW |
| **Firestore** | Source of truth for bookings, payments, config | All repositories | MODIFIED (new /payment subcollection) |

---

## Data Flow

### Feature Config Loading (App Startup)

```
main.dart:
  1. WidgetsFlutterBinding.ensureInitialized()
  2. await Firebase.initializeApp()
  3. Configure dependency injection:
     - Register services (FirebaseFirestore, FirebaseAuth)
     - Register repositories
     - Create ConfigRepository
     - Create ConfigCubit
  4. runApp(MyApp())
  ↓
_setupServiceLocator():
  getIt.registerSingleton<ConfigRepository>(...)
  getIt.registerSingleton<ConfigCubit>(...)
  ↓
AppShell / Home Screen's initState():
  context.read<ConfigCubit>().loadConfig()
  ↓
ConfigCubit.loadConfig():
  - Call ConfigRepository.fetchConfig(academyId)
  - Firestore: GET /config/booking
  - Deserialize to FeatureConfig model
  - emit(ConfigLoaded(config))
  ↓
Widgets rebuild with config available:
  context.read<ConfigCubit>().state.config.enablePixPayment
  context.read<ConfigCubit>().state.config.enablePushNotifications
  etc.
```

**Decision: Load at app startup, not lazy.**

Why: Feature flags govern major UI sections (payment tab, notification settings, social features). Loading mid-session causes UI flicker and complexity. Single immutable snapshot per session simplifies state management. Config changes require app restart anyway.

---

### Booking + Payment Flow (Happy Path)

```
Schedule Screen:
  User taps slot
  ↓
BookingCubit.createBooking(slotId, date, participants):
  ↓
  [Inside BLoC method]
  1. Get config from ConfigCubit
  2. BookingRepository.createBooking(slotId, date, participants)
       ↓
       [Inside Repository - atomic transaction]
       a. Check anti-double-booking (existing logic)
       b. Create /bookings/{id} with:
          {
            slotId, date, userId, participants,
            status: enablePixPayment ? "pending_payment" : "confirmed",
            createdAt, expiresAt: now + 15min
          }
       c. If enablePixPayment:
          - Generate/fetch Pix QR code (backend pre-generates)
          - Create /bookings/{id}/payment/{txId} with:
            {
              transactionId, provider: "pix",
              status: "pending",
              qrCode: "[64-char EMV code]",
              copyPaste: "[formatted code]",
              createdAt, expiresAt: now + 15min
            }
  3. Return BookingModel + PaymentRecord
  ↓
BookingCubit.emit(BookingCreated(booking, payment))
  ↓
UI (BookingConfirmationScreen):
  If payment != null and status == "pending":
    - Display QR code (via qr_flutter)
    - Display "Escaneie o QR ou copie a chave"
    - Listen to payment status changes
  ↓
[Background] User scans QR and pays via Pix app
  ↓
[After user returns to app]
BookingCubit.watchPaymentStatus(bookingId):
  PixPaymentRepository.watchPaymentStatus(bookingId)
    ↓
    Listener on /bookings/{id}/payment collection
    ↓
    emits PaymentRecord every update
  ↓
  if payment.status == "paid":
    emit(BookingPaymentConfirmed(payment))
  ↓
UI shows:
  ✓ Pagamento Confirmado!
  - Status: Confirmed / Awaiting confirmation
```

### Webhook Processing Flow (Backend)

```
Pix Provider:
  Sends webhook POST /functions/handlePixPaymentWebhook
  Body: {
    transactionId: "pix-abc123",
    bookingId: "slot-123_2026-04-20",
    status: "PAID",
    amount: 150.00,
    paidAt: "2026-04-06T15:30:00Z",
    signature: "hmac-sha256-..."
  }
  ↓
Cloud Function (handlePixPaymentWebhook):
  1. Verify HMAC signature (critical for security)
  2. Find /bookings/{bookingId}/payment/{transactionId}
  3. Update payment.status = "paid"
  4. Update booking:
     - If autoConfirm enabled:
       → Set booking.status = "confirmed"
       → Send FCM to admin (optional)
     - Else:
       → Set booking.status = "pending_confirmation"
       → Send FCM to admin: "Payment received, confirm to activate"
  5. Log webhook receipt for audit
  ↓
Firestore updated
  ↓
[App running]
Listener on /bookings/{id}/payment fires
  ↓
PaymentRecord emitted with status: "paid"
  ↓
BookingCubit receives update
  ↓
emit(BookingPaymentConfirmed(...))
  ↓
UI refreshes: Shows "Confirmado!"
```

---

## Data Model Changes

### 1. New ConfigCubit + FeatureConfig Model

**Firestore document:** `/config/booking` (expand existing)

```dart
// lib/core/models/feature_config.dart
@immutable
class FeatureConfig extends Equatable {
  final String academyId;
  
  // Existing fields (from v2.0)
  final bool autoConfirmBooking;
  
  // NEW in v4.0
  final bool enablePixPayment;
  final bool enablePushNotifications;
  final bool enableRecurringBooking;
  final bool enableSocialFeatures;
  final int paymentExpiryMinutes;

  const FeatureConfig({
    required this.academyId,
    required this.autoConfirmBooking,
    required this.enablePixPayment,
    required this.enablePushNotifications,
    required this.enableRecurringBooking,
    required this.enableSocialFeatures,
    this.paymentExpiryMinutes = 15,
  });

  @override
  List<Object?> get props => [
    academyId,
    autoConfirmBooking,
    enablePixPayment,
    enablePushNotifications,
    enableRecurringBooking,
    enableSocialFeatures,
    paymentExpiryMinutes,
  ];

  factory FeatureConfig.fromFirestore(Map<String, dynamic> data) {
    return FeatureConfig(
      academyId: data['academyId'] as String? ?? '',
      autoConfirmBooking: data['autoConfirmBooking'] as bool? ?? true,
      enablePixPayment: data['enablePixPayment'] as bool? ?? false,
      enablePushNotifications: data['enablePushNotifications'] as bool? ?? false,
      enableRecurringBooking: data['enableRecurringBooking'] as bool? ?? false,
      enableSocialFeatures: data['enableSocialFeatures'] as bool? ?? false,
      paymentExpiryMinutes: data['paymentExpiryMinutes'] as int? ?? 15,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'academyId': academyId,
    'autoConfirmBooking': autoConfirmBooking,
    'enablePixPayment': enablePixPayment,
    'enablePushNotifications': enablePushNotifications,
    'enableRecurringBooking': enableRecurringBooking,
    'enableSocialFeatures': enableSocialFeatures,
    'paymentExpiryMinutes': paymentExpiryMinutes,
  };
}
```

**Firestore document content:**

```json
{
  "academyId": "vida-ativa-94ba0",
  "autoConfirmBooking": true,
  "enablePixPayment": true,
  "enablePushNotifications": true,
  "enableRecurringBooking": true,
  "enableSocialFeatures": true,
  "paymentExpiryMinutes": 15,
  "updatedAt": "2026-04-06T00:00:00Z"
}
```

---

### 2. New PaymentRecord Model

**Firestore subcollection:** `/bookings/{bookingId}/payment/{transactionId}`

```dart
// lib/core/models/payment_record.dart
@immutable
class PaymentRecord extends Equatable {
  final String transactionId;      // "pix-abc123"
  final String provider;            // "pix" (future: "card", etc)
  final String status;              // "pending" | "paid" | "expired" | "failed"
  final String qrCode;              // 64-char EMV code for display
  final String copyPaste;           // Formatted Pix key
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? paidAt;
  final Map<String, dynamic>? metadata; // Provider-specific data

  const PaymentRecord({
    required this.transactionId,
    required this.provider,
    required this.status,
    required this.qrCode,
    required this.copyPaste,
    required this.createdAt,
    required this.expiresAt,
    this.paidAt,
    this.metadata,
  });

  @override
  List<Object?> get props => [
    transactionId,
    provider,
    status,
    qrCode,
    copyPaste,
    createdAt,
    expiresAt,
    paidAt,
    metadata,
  ];

  factory PaymentRecord.fromFirestore(Map<String, dynamic> data) {
    return PaymentRecord(
      transactionId: data['transactionId'] as String? ?? '',
      provider: data['provider'] as String? ?? 'pix',
      status: data['status'] as String? ?? 'pending',
      qrCode: data['qrCode'] as String? ?? '',
      copyPaste: data['copyPaste'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(minutes: 15)),
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'transactionId': transactionId,
    'provider': provider,
    'status': status,
    'qrCode': qrCode,
    'copyPaste': copyPaste,
    'createdAt': Timestamp.fromDate(createdAt),
    'expiresAt': Timestamp.fromDate(expiresAt),
    if (paidAt != null) 'paidAt': Timestamp.fromDate(paidAt!),
    if (metadata != null) 'metadata': metadata,
  };
}
```

**Firestore subcollection content:**

```json
{
  "transactionId": "pix-abc123",
  "provider": "pix",
  "status": "pending",
  "qrCode": "00020126580014br.gov.bcb.pix...",
  "copyPaste": "00020126.58001...",
  "createdAt": "2026-04-06T15:20:00Z",
  "expiresAt": "2026-04-06T15:35:00Z",
  "paidAt": null,
  "metadata": {
    "pixKey": "academy@vida-ativa.com.br"
  }
}
```

---

### 3. Update BookingModel

Add payment reference to existing BookingModel:

```dart
// lib/core/models/booking_model.dart (EXISTING - MODIFY)

@immutable
class BookingModel extends Equatable {
  final String id;
  final String slotId;
  final String userId;
  final DateTime date;
  final List<String> participants;
  final String status; // Now: "pending_payment" | "pending_confirmation" | "confirmed" | "cancelled"
  final DateTime createdAt;
  final DateTime? expiresAt;      // NEW: expiry for pending_payment bookings
  final String? paymentTransactionId; // NEW: FK to /bookings/{id}/payment/{txId}

  const BookingModel({
    required this.id,
    required this.slotId,
    required this.userId,
    required this.date,
    required this.participants,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    this.paymentTransactionId,
  });

  @override
  List<Object?> get props => [
    id,
    slotId,
    userId,
    date,
    participants,
    status,
    createdAt,
    expiresAt,
    paymentTransactionId,
  ];

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      slotId: data['slotId'] as String,
      userId: data['userId'] as String,
      date: DateTime.parse(data['date'] as String),
      participants: List<String>.from(data['participants'] as List? ?? []),
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      paymentTransactionId: data['paymentTransactionId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'slotId': slotId,
    'userId': userId,
    'date': date.toIso8601String().split('T').first,
    'participants': participants,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
    if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
    if (paymentTransactionId != null) 'paymentTransactionId': paymentTransactionId,
  };
}
```

**Updated Firestore document:**

```json
{
  "id": "slot-123_2026-04-20",
  "slotId": "slot-123",
  "date": "2026-04-20",
  "userId": "user-xyz",
  "status": "pending_payment",
  "participants": ["Ana", "Bruno"],
  "createdAt": "2026-04-06T15:20:00Z",
  "expiresAt": "2026-04-06T15:35:00Z",
  "paymentTransactionId": "pix-abc123"
}
```

**Status values (expanded):**
- `pending_payment`: Booking created, awaiting Pix confirmation
- `pending_confirmation`: Payment received, admin approval pending
- `confirmed`: Ready (payment done + admin approved, or auto-confirmed)
- `cancelled`: User or admin cancelled

---

## Integration Patterns

### Pattern 1: Feature Config at App Startup

**Where:** Load in `AppShell` or home screen's `initState()`.

**How:** Synchronously after Firebase init.

```dart
// lib/core/cubits/config_cubit.dart
class ConfigCubit extends Cubit<ConfigState> {
  final ConfigRepository configRepository;
  final String academyId;

  ConfigCubit({
    required this.configRepository,
    required this.academyId,
  }) : super(const ConfigState.initial());

  Future<void> loadConfig() async {
    try {
      emit(const ConfigState.loading());
      final config = await configRepository.fetchConfig(academyId);
      emit(ConfigState.loaded(config));
    } catch (e) {
      emit(ConfigState.error('Failed to load config: $e'));
    }
  }
}

// lib/core/states/config_state.dart
class ConfigState extends Equatable {
  final FeatureConfig? config;
  final bool isLoading;
  final String? error;

  const ConfigState({
    this.config,
    this.isLoading = false,
    this.error,
  });

  const ConfigState.initial() : this();
  const ConfigState.loading() : this(isLoading: true);

  factory ConfigState.loaded(FeatureConfig config) {
    return ConfigState(config: config);
  }

  factory ConfigState.error(String message) {
    return ConfigState(error: message);
  }

  @override
  List<Object?> get props => [config, isLoading, error];
}

// lib/core/repositories/config_repository.dart
class ConfigRepository {
  final FirebaseFirestore firestore;

  ConfigRepository(this.firestore);

  Future<FeatureConfig> fetchConfig(String academyId) async {
    try {
      final doc = await firestore.collection('config').doc('booking').get();
      if (!doc.exists) {
        throw Exception('Config document not found');
      }
      return FeatureConfig.fromFirestore(doc.data()!);
    } catch (e) {
      rethrow;
    }
  }
}

// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  _setupServiceLocator();
  
  runApp(const MyApp());
}

void _setupServiceLocator() {
  // Register singletons
  getIt.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);
  getIt.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);
  
  getIt.registerSingleton<ConfigRepository>(
    ConfigRepository(getIt<FirebaseFirestore>()),
  );
  
  getIt.registerSingleton<ConfigCubit>(
    ConfigCubit(
      configRepository: getIt<ConfigRepository>(),
      academyId: 'vida-ativa-94ba0', // Or load dynamically
    ),
  );
  
  // ... register other BLoCs and repositories
}

// lib/app_shell.dart or main screen
class AppShell extends StatefulWidget {
  const AppShell({Key? key}) : super(key: key);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    // Load config once at app startup
    context.read<ConfigCubit>().loadConfig();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigCubit, ConfigState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (state.error != null) {
          return Scaffold(
            body: Center(child: Text('Erro ao carregar configuração: ${state.error}')),
          );
        }
        
        // Config loaded — render rest of app with flags available
        return const HomePage();
      },
    );
  }
}

// Access in any widget
class PaymentFeatureExample extends StatelessWidget {
  const PaymentFeatureExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = context.read<ConfigCubit>().state.config;
    
    if (config?.enablePixPayment ?? false) {
      return const Text('Pix is enabled');
    }
    return const SizedBox.shrink();
  }
}
```

---

### Pattern 2: Pix Payment in Booking Flow

**Where:** `BookingCubit.createBooking()` → `BookingRepository.createBooking()`

**How:** Check feature flag, create payment record if enabled.

```dart
// lib/features/booking/cubits/booking_cubit.dart
class BookingCubit extends Cubit<BookingState> {
  final BookingRepository bookingRepository;
  final PixPaymentRepository pixPaymentRepository;
  final ConfigCubit configCubit;

  BookingCubit({
    required this.bookingRepository,
    required this.pixPaymentRepository,
    required this.configCubit,
  }) : super(const BookingState.initial());

  Future<void> createBooking({
    required String slotId,
    required DateTime date,
    required List<String> participants,
  }) async {
    try {
      emit(const BookingState.creating());

      final config = configCubit.state.config;
      if (config == null) {
        emit(const BookingState.error('Config not loaded'));
        return;
      }

      // Create booking (status depends on payment enabled)
      final booking = await bookingRepository.createBooking(
        slotId: slotId,
        date: date,
        participants: participants,
        enablePixPayment: config.enablePixPayment,
      );

      // If Pix is enabled, start watching payment status
      if (config.enablePixPayment && booking.paymentTransactionId != null) {
        _watchPaymentStatus(booking.id);
        emit(BookingState.createdWithPayment(booking));
      } else {
        emit(BookingState.created(booking));
      }
    } catch (e) {
      emit(BookingState.error('Booking creation failed: $e'));
    }
  }

  void _watchPaymentStatus(String bookingId) {
    pixPaymentRepository.watchPaymentStatus(bookingId).listen(
      (payment) {
        if (payment == null) return;
        
        if (payment.status == 'paid') {
          emit(BookingState.paymentConfirmed(payment));
        } else if (pixPaymentRepository.isPaymentExpired(payment)) {
          emit(BookingState.paymentExpired());
        }
      },
      onError: (e) => emit(BookingState.error('Payment update error: $e')),
    );
  }
}

// lib/features/booking/repositories/booking_repository.dart (EXISTING - MODIFY)
class BookingRepository {
  final FirebaseFirestore firestore;
  final PixPaymentRepository pixPaymentRepository;

  BookingRepository(this.firestore, this.pixPaymentRepository);

  Future<BookingModel> createBooking({
    required String slotId,
    required DateTime date,
    required List<String> participants,
    required bool enablePixPayment,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final bookingId = BookingModel.generateId(slotId, date);

      // Atomic transaction for anti-double-booking
      return await firestore.runTransaction((transaction) async {
        final slotRef = firestore.collection('slots').doc(slotId);
        final bookingRef = firestore.collection('bookings').doc(bookingId);

        final slotSnap = await transaction.get(slotRef);
        if (!slotSnap.exists) throw Exception('Slot not found');

        final existingBooking = await transaction.get(bookingRef);
        if (existingBooking.exists) throw Exception('Booking already exists');

        // Determine status based on payment requirement
        final status = enablePixPayment ? 'pending_payment' : 'confirmed';

        final booking = BookingModel(
          id: bookingId,
          slotId: slotId,
          userId: userId,
          date: date,
          participants: participants,
          status: status,
          createdAt: DateTime.now(),
          expiresAt: enablePixPayment ? DateTime.now().add(const Duration(minutes: 15)) : null,
          paymentTransactionId: null, // Will be set if payment created successfully
        );

        transaction.set(bookingRef, booking.toFirestore());

        return booking;
      });
    } catch (e) {
      rethrow;
    }
  }
}

// lib/features/booking/repositories/pix_payment_repository.dart (NEW)
class PixPaymentRepository {
  final FirebaseFirestore firestore;

  PixPaymentRepository(this.firestore);

  /// Create a Pix payment record (QR code pre-generated by backend)
  Future<PaymentRecord> createPixPayment({
    required String bookingId,
    required String qrCode,
    required String copyPaste,
    required String pixKey,
  }) async {
    try {
      final txId = 'pix-${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(minutes: 15));

      final payment = PaymentRecord(
        transactionId: txId,
        provider: 'pix',
        status: 'pending',
        qrCode: qrCode,
        copyPaste: copyPaste,
        createdAt: now,
        expiresAt: expiresAt,
        metadata: {'pixKey': pixKey},
      );

      final paymentRef = firestore
          .collection('bookings')
          .doc(bookingId)
          .collection('payment')
          .doc(txId);

      await paymentRef.set(payment.toFirestore());

      // Update booking with payment transaction ID
      await firestore
          .collection('bookings')
          .doc(bookingId)
          .update({'paymentTransactionId': txId});

      return payment;
    } catch (e) {
      rethrow;
    }
  }

  /// Stream payment status (real-time listener)
  Stream<PaymentRecord?> watchPaymentStatus(String bookingId) {
    return firestore
        .collection('bookings')
        .doc(bookingId)
        .collection('payment')
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          // Return most recent payment record
          final doc = snapshot.docs.first;
          return PaymentRecord.fromFirestore(doc.data());
        });
  }

  bool isPaymentExpired(PaymentRecord payment) {
    return DateTime.now().isAfter(payment.expiresAt);
  }
}
```

---

### Pattern 3: Cloud Function Webhook (Pix Provider → Firestore)

**Where:** `functions/src/webhooks/pixPayment.ts`

**How:** Verify signature → Update payment status → Trigger booking confirmation.

```typescript
// functions/src/webhooks/pixPayment.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';

const db = admin.firestore();

/**
 * Webhook handler for Pix payment confirmations
 * Called by Pix provider (e.g., Pismo, Cielo, PagBrasil) when payment received
 * 
 * Expected payload:
 * {
 *   transactionId: "pix-abc123",
 *   bookingId: "slot-123_2026-04-20",
 *   status: "PAID",
 *   amount: 150.00,
 *   paidAt: "2026-04-06T15:30:00Z",
 *   signature: "hmac-sha256-hash"
 * }
 */
export const handlePixPaymentWebhook = functions.https.onRequest(
  async (req, res) => {
    if (req.method !== 'POST') {
      return res.status(405).send('Method not allowed');
    }

    try {
      // 1. Verify webhook signature (CRITICAL)
      const signature = req.headers['x-pix-signature'] as string;
      const payload = JSON.stringify(req.body);
      const secret = functions.config().pix.webhook_secret || '';
      const expectedSignature = crypto
        .createHmac('sha256', secret)
        .update(payload)
        .digest('hex');

      if (!crypto.timingSafeEqual(signature, expectedSignature)) {
        console.error('Invalid webhook signature');
        return res.status(401).send('Unauthorized');
      }

      const { transactionId, bookingId, status, paidAt } = req.body;

      // 2. Validate required fields
      if (!transactionId || !bookingId || !status) {
        return res.status(400).send('Missing required fields');
      }

      // 3. Update payment record
      const paymentRef = db
        .collection('bookings')
        .doc(bookingId)
        .collection('payment')
        .doc(transactionId);

      const paymentDoc = await paymentRef.get();
      if (!paymentDoc.exists) {
        console.error(`Payment not found: ${transactionId}`);
        return res.status(404).send('Payment not found');
      }

      const isPaid = status === 'PAID';

      // Update payment status
      await paymentRef.update({
        status: isPaid ? 'paid' : 'failed',
        ...(isPaid && { paidAt: new Date(paidAt) }),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 4. Handle booking confirmation if payment successful
      if (isPaid) {
        await handleBookingConfirmation(bookingId);
      }

      // 5. Log for audit trail
      await db.collection('webhookLogs').add({
        provider: 'pix',
        transactionId,
        bookingId,
        status,
        success: isPaid,
        receivedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      res.status(200).json({ success: true });
    } catch (error) {
      console.error('Webhook processing error:', error);
      // Return 500 so provider can retry
      res.status(500).send('Internal server error');
    }
  }
);

async function handleBookingConfirmation(bookingId: string): Promise<void> {
  try {
    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
      throw new Error(`Booking not found: ${bookingId}`);
    }

    // Get academy config to check auto-confirm setting
    const configDoc = await db.collection('config').doc('booking').get();
    const config = configDoc.data() as any;

    const autoConfirm = config?.autoConfirmBooking ?? false;

    if (autoConfirm) {
      // Auto-confirm: directly set status to confirmed
      await bookingRef.update({
        status: 'confirmed',
        confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
        paymentConfirmedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Optionally notify admin of confirmed booking
      if (config?.enablePushNotifications) {
        await notifyAdminBookingConfirmed(bookingId);
      }
    } else {
      // Manual confirmation: set to pending_confirmation
      // Admin will see this in dashboard and click "Confirmar"
      await bookingRef.update({
        status: 'pending_confirmation',
        paymentConfirmedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Notify admin: "Pagamento recebido — confirme para ativar"
      await notifyAdminPaymentReceived(bookingId);
    }
  } catch (error) {
    console.error('handleBookingConfirmation error:', error);
    throw error;
  }
}

async function notifyAdminPaymentReceived(bookingId: string): Promise<void> {
  // TODO: Send FCM notification to admin devices
  // Fetch admin users with FCM tokens
  // Send multi-cast message
  console.log(`[TODO] FCM notification: Payment received for ${bookingId}`);
}

async function notifyAdminBookingConfirmed(
  bookingId: string
): Promise<void> {
  // TODO: Send FCM notification if enabled
  console.log(`[TODO] FCM notification: Booking auto-confirmed ${bookingId}`);
}
```

**Deploy:**

```bash
firebase deploy --only functions:handlePixPaymentWebhook
```

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Loading Config on Every Widget Build

**What:** `await configRepository.fetchConfig()` in widget's build method.

**Why bad:** Firestore quota exhausted; UI flickers; unnecessary network traffic.

**Instead:** Load once at app init. Store in ConfigCubit. Access immutably via `context.read<ConfigCubit>().state.config`.

---

### Anti-Pattern 2: Blocking Booking on Payment Failure

**What:** Fail entire booking transaction if payment QR generation fails.

**Why bad:** User sees "booking failed" even though booking was created. Payment retry becomes impossible.

**Instead:** Create booking first → then create payment record separately. Payment and booking are decoupled.

---

### Anti-Pattern 3: Deleting Payment Records After Webhook

**What:** Delete `/bookings/{id}/payment/{txId}` after status updated to "paid".

**Why bad:** No audit trail; can't reconcile if provider and app disagree; webhook retry fails.

**Instead:** Keep payment record indefinitely. Webhook just updates status field. Audit log for compliance.

---

### Anti-Pattern 4: Generating QR Code in App

**What:** Use `qr_flutter` + manual EMV encoding to generate Pix QR in Flutter.

**Why bad:** QR generation is complex (checksums, encoding specs); requires private key; adds app complexity.

**Instead:** Pre-generate QR code backend/server-side. Return as string. App displays via `QrImage()`.

---

### Anti-Pattern 5: Hardcoding Academy ID

**What:** `const academyId = "vida-ativa-94ba0"` in `main.dart`.

**Why bad:** Not scalable to multi-tenant; code duplication per academy.

**Instead:** (Current) Pass via `--dart-define=ACADEMY_ID=...` at build time.  
(Future) Detect from subdomain or load from backend API.

---

## Firestore Security Rules

Extend existing rules for payment records and config:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions (existing)
    function isSignedIn() {
      return request.auth != null;
    }

    function isAdmin() {
      return exists(/databases/$(database)/documents/users/$(request.auth.uid))
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    function isBookingOwner(bookingId) {
      return isSignedIn()
        && get(/databases/$(database)/documents/bookings/$(bookingId)).data.userId == request.auth.uid;
    }

    // NEW: Config collection (read-only for users; write for admins)
    match /config/{document=**} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
    }

    // Bookings (EXISTING — add payment subcollection)
    match /bookings/{bookingId} {
      allow read: if isSignedIn() && (isAdmin() || isBookingOwner(bookingId));
      allow create: if isSignedIn() && request.auth.uid == request.resource.data.userId;
      allow update: if isAdmin()
                    || (isBookingOwner(bookingId) && request.resource.data.status == 'cancelled');
      allow delete: if false; // Soft deletes only

      // NEW: Payment subcollection (users read own; admins read all; only Cloud Functions write)
      match /payment/{paymentId} {
        allow read: if isSignedIn()
                    && (isAdmin() || isBookingOwner(bookingId));
        allow create: if false; // Cloud Functions only
        allow update: if false; // Cloud Functions only
        allow delete: if false;
      }
    }

    // NEW: Webhook audit logs (admin-only read; Cloud Functions write)
    match /webhookLogs/{logId} {
      allow read: if isAdmin();
      allow write: if false; // Cloud Functions only
    }
  }
}
```

---

## Integration Points Summary

| Component | Existing? | Changes | Integrates With |
|-----------|-----------|---------|-----------------|
| **ConfigRepository** | ✗ | NEW | Firestore `/config/booking` |
| **ConfigCubit** | ✗ | NEW | BlocProvider, widgets via `context.read()` |
| **PixPaymentRepository** | ✗ | NEW | BookingRepository, Firestore `/payment` subcoll |
| **PaymentRecord** | ✗ | NEW | Firestore serialization |
| **BookingModel** | ✓ | MODIFY | Add `expiresAt`, `paymentTransactionId` fields |
| **BookingRepository** | ✓ | MODIFY | Accept `enablePixPayment` flag; create payment record |
| **BookingCubit** | ✓ | MODIFY | Watch payment status; emit payment events |
| **AdminBookingCubit** | ✓ | MODIFY | Stream payment status; show in details UI |
| **BookingConfirmationScreen** | ✓ | MODIFY | Display QR code; listen to payment updates |
| **Admin booking detail** | ✓ | MODIFY | Show payment status badge; add "Confirmar manualmente" |
| **Cloud Function (Webhook)** | ✗ | NEW | Pix provider → Firestore |
| **Firestore rules** | ✓ | MODIFY | Add `/config` and `/payment` rules |
| **Firebase config doc** | ✓ | MODIFY | Expand with feature flags |

---

## Build Order Recommendation

### Phase 1: Feature Config Infrastructure
- Create `ConfigRepository` + `ConfigCubit` + `FeatureConfig` model
- Expand `/config/booking` document with feature flag fields
- Load config at app startup
- Access flags in widgets (no payment yet)
- Admin can edit flags in admin panel

### Phase 2: Payment Data Model
- Create `PaymentRecord` model
- Update `BookingModel` with payment fields
- Create Firestore rules for `/payment` subcollection
- Update `BookingRepository` to handle payment creation

### Phase 3: Payment UI
- Create `PixPaymentRepository`
- Modify `BookingConfirmationScreen` to display QR code
- Add real-time payment status listener
- Implement payment expiry + retry logic

### Phase 4: Webhook Infrastructure
- Deploy `handlePixPaymentWebhook` Cloud Function
- Test with Pix provider sandbox
- Implement webhook signature verification
- Add webhook audit logging

### Phase 5: Admin Integration
- Show payment status in admin booking list
- Add "Confirmar manualmente" button for manual mode
- Display payment badges (received, pending, failed)
- Link to webhook logs for debugging

---

## Sources

- [Firebase Firestore With Bloc in Flutter | Medium](https://medium.com/@muhammadrahman2042/firebase-firestore-with-bloc-in-flutter-18d27876a885)
- [How to Use flutter_bloc in Flutter with Full Example (2026 Guide)](https://flutterfever.com/how-to-use-flutter_bloc-in-flutter/)
- [Process payments with Firebase - Google](https://firebase.google.com/docs/tutorials/payments-stripe)
- [Working with Stripe Webhooks & Firebase Cloud Functions | Medium](https://medium.com/@GaryHarrower/working-with-stripe-webhooks-firebase-cloud-functions-5366c206c6c)
- [API PIX Integration manual](https://developercielo.github.io/en/manual/apipix)
- [Pix instant payments (Brazil) - Pismo Developers Portal](https://developers.pismo.io/pismo-docs/docs/pix-instant-payments)
- [Pix payments | Stripe Documentation](https://docs.stripe.com/payments/pix)
- [How does Pix QRCode work? - DEV Community](https://dev.to/woovi/how-does-pix-qrcode-work-5e3k)
- [Feature Toggles (aka Feature Flags) - Martin Fowler](https://martinfowler.com/articles/feature-toggles.html)
- [How to Implement Feature Flags The Right Way in 2026 - Nerdify Blog](https://getnerdify.com/blog/how-to-implement-feature-flags)
- [get_it | Dart package](https://pub.dev/packages/get_it)
- [flutter_bloc | Flutter package](https://pub.dev/packages/flutter_bloc)
- [RepositoryProvider class - flutter_bloc library - Dart API](https://pub.dev/documentation/flutter_bloc/latest/flutter_bloc/RepositoryProvider-class.html)
- [Flutter Bloc Concepts | Bloc](https://bloclibrary.dev/flutter-bloc-concepts/)
- [Secure data access for users and groups | Firestore | Firebase](https://firebase.google.com/docs/firestore/solutions/role-based-access)
- [How to Write Firestore Security Rules for Role-Based Access Control](https://oneuptime.com/blog/post/2026-02-17-how-to-write-firestore-security-rules-for-role-based-access-control/view)
- [Cloud Firestore Data model | Firebase - Google](https://firebase.google.com/docs/firestore/data-model)

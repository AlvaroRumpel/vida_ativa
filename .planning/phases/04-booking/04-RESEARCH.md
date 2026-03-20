# Phase 4: Booking - Research

**Researched:** 2026-03-20
**Domain:** Firestore Transactions (anti-double-booking), BLoC Cubit, Flutter bottom sheet / AlertDialog patterns
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Booking flow:**
- Slot disponivel na agenda fica tappable (tap no `SlotCard`)
- Tap abre bottom sheet de confirmacao com: horario, data selecionada, preco, botao "Reservar"
- Sem aviso de pagamento presencial — somente as informacoes essenciais do slot
- Botao "Reservar" mostra `CircularProgressIndicator` inline e fica desabilitado durante a transacao (mesmo padrao do `FilledButton` da Phase 2 / Auth)
- Apos sucesso: bottom sheet fecha + SnackBar "Reserva feita!"
- A agenda ja e reativa (stream Firestore) — card atualiza para "Minha reserva" automaticamente sem reload

**Status inicial da reserva:**
- Toda reserva nova entra com status `"pending"` — admin confirma manualmente na Phase 5
- Na agenda (`SlotCard`), slot com reserva `pending` do proprio usuario exibe badge "Minha reserva" — igual ao `confirmed` (sem distincao visual entre pending/confirmed no SlotCard)
- `ScheduleCubit` ja filtra `whereIn: ['pending', 'confirmed']` — slot fica como ocupado para outros usuarios independente do status

**Tela Minhas Reservas:**
- Layout: duas secoes agrupadas — "Proximas" (datas >= hoje, ordem crescente) e "Passadas" (datas < hoje, ordem decrescente)
- Card de reserva mostra: data formatada (ex: "Segunda, 24 Mar"), horario, preco em R$, badge de status
- Badge de status no card: "Aguardando" (pending), "Confirmado" (confirmed), "Cancelado" (cancelled)
- Cancelamento: botao "Cancelar" TextButton vermelho inline no card — visivel apenas em reservas futuras (nao em passadas)
- Tap em "Cancelar" abre `AlertDialog` de confirmacao ("Cancelar esta reserva? Sim / Nao")
- Apos cancelamento bem-sucedido: card some da secao "Proximas" (ou move para passadas com status Cancelado)
- Estado vazio (sem reservas): mensagem "Voce nao tem nenhuma reserva ainda." + botao "Ver Agenda" que navega para Tab 0

### Claude's Discretion
- Implementacao interna do `BookingCubit` (estados: loading, loaded, error)
- Estrategia de query Firestore para "Minhas Reservas" (stream por userId, filtro local de data)
- Loading state da tela Minhas Reservas (skeleton ou spinner)
- Erro de double booking simultaneo (segundo usuario): SnackBar de erro com mensagem clara (ex: "Este horario acabou de ser reservado.")
- Falha de rede durante a transacao: mensagem de erro na bottom sheet, sem fechar

### Deferred Ideas (OUT OF SCOPE)
- Prazo minimo de cancelamento (ex: so pode cancelar com 2h de antecedencia) — BOOK-v2-01 ja no backlog v2
- Notificacao push quando reserva e confirmada — NOTF-v2-01 no backlog v2
- Configuracao de modo de confirmacao (automatico vs manual) pelo admin — ADMN-06 na Phase 5
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| BOOK-01 | Usuario pode reservar um horario disponivel (transacao atomica — sem double booking) | Firestore Transaction with deterministic doc ID `{slotId}_{date}` prevents concurrent writes; `runTransaction` throws if doc already exists |
| BOOK-02 | Usuario pode cancelar sua propria reserva | Update `status` to `"cancelled"` + set `cancelledAt`; ScheduleCubit `whereIn` already excludes cancelled — slot re-opens automatically |
| BOOK-03 | Usuario pode ver suas reservas futuras e passadas | Stream query on `/bookings` filtered by `userId`; local date split into "Proximas" / "Passadas" sections |
</phase_requirements>

---

## Summary

Phase 4 delivers the booking write path — the first time the app mutates Firestore data on behalf of a user. Three features are in scope: atomic slot reservation (BOOK-01), My Bookings list (BOOK-03), and booking cancellation (BOOK-02).

The anti-double-booking mechanism is already designed: `BookingModel.generateId(slotId, date)` produces `{slotId}_{date}`, and Firestore Transactions with `.doc(id).set()` (not `.add()`) ensure that the second concurrent writer gets a transaction abort — not a silent overwrite. The `ScheduleCubit` already listens to the bookings stream and will reflect the new booking reactively without any additional wiring in the schedule feature.

The primary new artifact is `BookingCubit`, which owns two responsibilities: (a) creating a booking via Firestore Transaction, and (b) streaming the user's own bookings for the My Bookings screen. Firestore offline persistence on Flutter Web must be disabled (or scoped away) before any booking write, because persistence and Transactions conflict on the web platform.

**Primary recommendation:** Use a single `BookingCubit` per session (provided at app level above the shell, or lazily at route level) that streams the user's bookings continuously; all write operations (book, cancel) are methods on the same cubit that emit transient loading/error states.

---

## Standard Stack

### Core (already installed — no new deps needed)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| cloud_firestore | ^6.1.3 | Firestore Transaction + stream query | Already in pubspec; Transaction API is the only safe anti-double-booking primitive |
| flutter_bloc | ^9.1.1 | BookingCubit state management | Established pattern across Phases 1-3 |
| equatable | ^2.0.8 | BookingState value equality | Already in pubspec; used by all existing cubits |
| intl | ^0.20.2 | Date/price formatting | Already in pubspec; used by ScheduleScreen |
| go_router | ^17.1.0 | Navigation (Tab 1 `/bookings`) | Already wired; just swap builder |

### No new dependencies required

All Phase 4 functionality is achievable with the current pubspec. No additional packages needed.

---

## Architecture Patterns

### Recommended Project Structure

```
lib/features/booking/
├── cubit/
│   ├── booking_cubit.dart        # BookingCubit (stream + write methods)
│   └── booking_state.dart        # Sealed BookingState classes
├── ui/
│   ├── my_bookings_screen.dart   # Replaces placeholder; two-section list
│   ├── booking_card.dart         # Single booking card with status badge + cancel button
│   └── booking_confirmation_sheet.dart  # Bottom sheet shown from SlotCard tap
```

Modifications to existing files:
- `lib/features/schedule/ui/slot_card.dart` — add `onTap` callback parameter
- `lib/features/schedule/ui/slot_list.dart` (or equivalent) — pass `onTap` handler that shows bottom sheet
- `lib/core/router/app_router.dart` — replace `MyBookingsPlaceholderScreen` with `MyBookingsScreen`

### Pattern 1: Firestore Transaction for Atomic Booking (BOOK-01)

**What:** A Firestore Transaction reads a document, checks a condition, and writes atomically. If a concurrent write already wrote the document between the read and the write, Firestore aborts and retries (up to 5 times by default on mobile, but on web it typically throws immediately).

**When to use:** Every slot reservation. Never use `.add()` or `.set()` outside a Transaction for booking writes.

**Critical rule:** The document ID MUST be deterministic (`BookingModel.generateId(slotId, dateString)` = `{slotId}_{date}`). The Transaction reads that specific doc ID; if it already exists and is not cancelled, the cubit throws a domain-level error ("slot already booked").

```dart
// Source: cloud_firestore SDK — FirebaseFirestore.instance.runTransaction
Future<void> bookSlot({
  required String slotId,
  required String dateString,
  required String userId,
  required double price,
}) async {
  final docId = BookingModel.generateId(slotId, dateString);
  final ref = _firestore.collection('bookings').doc(docId);

  await _firestore.runTransaction((tx) async {
    final snapshot = await tx.get(ref);

    if (snapshot.exists) {
      final existing = BookingModel.fromFirestore(snapshot);
      // Only block if active (pending or confirmed)
      if (!existing.isCancelled) {
        throw Exception('slot_already_booked');
      }
    }

    final booking = BookingModel(
      id: docId,
      slotId: slotId,
      date: dateString,
      userId: userId,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    tx.set(ref, booking.toFirestore());
  });
}
```

**Important:** `tx.set()` inside a Transaction is safe even if the doc doesn't yet exist. The Transaction guarantees isolation.

### Pattern 2: BookingCubit State Design

**States:**
- `BookingInitial` — before stream starts
- `BookingLoading` — stream has not emitted yet
- `BookingLoaded({List<BookingModel> bookings})` — stream active, data available
- `BookingError(String message)` — stream failed

**Transient states for write operations:** The cubit should NOT emit `BookingLoading` globally during a book/cancel action (that would wipe the booking list from the screen). Instead, use a secondary flag or let the bottom sheet manage its own button loading state via local `StatefulWidget` or a separate cubit method that returns a `Future<bool>` and lets the UI handle the progress.

**Recommended approach for book action:** The bottom sheet holds its own local `isSubmitting` bool (StatefulWidget), calls `cubit.bookSlot(...)`, awaits the future, and shows the spinner inline. The cubit's `BookingLoaded` state remains intact throughout.

```dart
// booking_state.dart
sealed class BookingState extends Equatable {
  const BookingState();
}

class BookingInitial extends BookingState {
  const BookingInitial();
  @override List<Object?> get props => [];
}

class BookingLoading extends BookingState {
  const BookingLoading();
  @override List<Object?> get props => [];
}

class BookingLoaded extends BookingState {
  final List<BookingModel> bookings;
  const BookingLoaded(this.bookings);
  @override List<Object?> get props => [bookings];
}

class BookingError extends BookingState {
  final String message;
  const BookingError(this.message);
  @override List<Object?> get props => [message];
}
```

### Pattern 3: My Bookings Stream Query

**Query:** Stream all bookings for the current user, ordered by date descending (Firestore allows single-field ordering without composite index when filtering by equality on one field).

```dart
// Single field order — no composite index required (date is the only orderBy)
_firestore
  .collection('bookings')
  .where('userId', isEqualTo: currentUserId)
  .orderBy('date', descending: true)
  .snapshots()
  .listen((snap) {
    final bookings = snap.docs
        .map((d) => BookingModel.fromFirestore(d))
        .toList();
    _splitAndEmit(bookings);
  });
```

**Local split:** After receiving all bookings, split by comparing `booking.date` (String "YYYY-MM-DD") to today's date string. Future/today = "Proximas" (ascending); past = "Passadas" (descending). String comparison works correctly for ISO-8601 dates.

**Note:** Do NOT use two separate Firestore queries for past/upcoming — one stream + local filter is simpler, avoids double subscription teardown, and the dataset per user is small.

### Pattern 4: Firestore Offline Persistence — Disable for Web

**Problem:** Flutter Web's Firestore SDK uses IndexedDB for offline persistence by default. Firestore Transactions on the web require a network round-trip; if the SDK is in offline mode, transactions silently fail or behave incorrectly.

**Solution confirmed in CONTEXT.md / STATE.md:** Disable persistence globally at app startup for web. The correct API is `FirebaseFirestore.instance.settings`.

```dart
// In main() before runApp, after Firebase.initializeApp:
import 'package:flutter/foundation.dart' show kIsWeb;

if (kIsWeb) {
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );
}
```

**Where to add:** `lib/main.dart` in the `main()` function, immediately after `Firebase.initializeApp(...)`.

**Confidence:** HIGH — this is the documented Firestore Flutter SDK approach for disabling web persistence. The `Settings` class with `persistenceEnabled: false` is the correct API for cloud_firestore ^5+/^6+.

### Pattern 5: Bottom Sheet for Booking Confirmation

**Flutter API:** `showModalBottomSheet` with `isScrollControlled: true` to allow the sheet to size to its content. Use `DraggableScrollableSheet` only if content can scroll; for this simple confirmation, a fixed-height sheet is preferable.

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  builder: (_) => BookingConfirmationSheet(
    viewModel: viewModel,
    onConfirm: () => _handleBooking(context, viewModel),
  ),
);
```

**Bottom sheet must be a StatefulWidget** to hold the `isSubmitting` bool for the inline progress indicator on the "Reservar" button (same pattern as Phase 2 auth forms).

### Pattern 6: SlotCard onTap Integration

**Current state:** `SlotCard` is a `StatelessWidget` with no tap handler. It receives a `SlotViewModel` and displays status.

**Change needed:** Add an `onTap` callback parameter. Only `SlotStatus.available` slots trigger the booking flow. Other statuses (booked, myBooking, blocked) show no tap response.

```dart
class SlotCard extends StatelessWidget {
  final SlotViewModel viewModel;
  final VoidCallback? onTap;  // New parameter

  const SlotCard({super.key, required this.viewModel, this.onTap});
  // ...
}
```

The parent (`SlotList` or equivalent in `schedule_screen.dart`) passes the callback only when `viewModel.status == SlotStatus.available`.

**Wrap the Card with InkWell** (already has `clipBehavior: Clip.antiAlias`) — the existing `Card` widget respects InkWell splash when `clipBehavior` is set.

### Pattern 7: Cancel Booking

**Cancellation write:** NOT a Transaction — just a `.update()` on the existing document.

```dart
Future<void> cancelBooking(String bookingId) async {
  await _firestore.collection('bookings').doc(bookingId).update({
    'status': 'cancelled',
    'cancelledAt': Timestamp.fromDate(DateTime.now()),
  });
}
```

**Why no Transaction:** Only the booking owner can cancel (enforced by Firestore rules + UI filtering), and the status transition is one-way. Race conditions don't apply here.

**Reactive effect:** After the update, the `ScheduleCubit` bookings stream (`whereIn: ['pending', 'confirmed']`) will re-emit without this booking — the slot automatically becomes available in the agenda.

### Pattern 8: BookingCubit Provider Placement

**Where to provide:** `BookingCubit` should be provided at the `/bookings` route builder in `app_router.dart`, matching the pattern of `ScheduleCubit` at `/home`. This scopes the cubit's lifetime to the tab.

**BUT:** The booking confirmation is initiated from the Schedule tab (Tab 0), not the Bookings tab (Tab 1). The write method (`bookSlot`) needs to be accessible from the Schedule tab's context.

**Resolution options (Claude's Discretion):**

Option A (recommended): Provide `BookingCubit` at the `StatefulShellRoute` level (above all branches), so it's accessible from any tab. The stream starts once when the user enters the shell and remains active.

Option B: Keep `BookingCubit` at Tab 1 and inject it into the bottom sheet via constructor (pass the cubit as a parameter to the sheet builder). The schedule tab accesses it with `context.read<BookingCubit>()` only if the cubit is above it in the tree.

Option A is cleaner — provide `BookingCubit` in the `StatefulShellRoute.builder` inside `app_router.dart`.

### Anti-Patterns to Avoid

- **Using `.add()` for booking writes:** Never. Always `.doc(BookingModel.generateId(...)).set()` inside a Transaction. `.add()` generates a random ID and bypasses the anti-double-booking mechanism entirely.
- **Emitting global `BookingLoading` during a book action:** Wipes the booking list from the UI during a write. Keep the list visible; use local button state for the write progress indicator.
- **Skipping the Transaction existence check:** If you call `tx.set()` unconditionally, Firestore will overwrite an existing booking. Always read first in the Transaction and check `!existing.isCancelled`.
- **Two separate stream subscriptions for past/future:** Over-engineering. One stream + local date split is simpler and sufficient.
- **Closing the bottom sheet before the Transaction is acknowledged:** Violates Success Criterion 4 ("no ghost bookings"). The sheet must stay open (button disabled + spinner) until the future resolves, then close on success or show error on failure.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Anti-double-booking | Custom lock or timestamp check | Firestore Transaction with deterministic doc ID | Transactions are ACID; custom timestamp checks have race windows |
| Date formatting | Custom date string builder | `intl` package (`DateFormat`) | Already installed; handles locale, edge cases |
| Price formatting | Custom currency string | `NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')` | Already used in SlotCard; consistent format |
| Bottom sheet | Custom overlay widget | `showModalBottomSheet` | Flutter built-in; handles safe area, keyboard avoidance, drag dismissal |
| AlertDialog | Custom confirmation modal | `showDialog` with `AlertDialog` | Built-in; handles accessibility, focus trap |

**Key insight:** The booking write path's correctness depends entirely on Firestore's Transaction primitives. Any hand-rolled locking mechanism introduces race conditions that cannot be eliminated without server-side coordination — which Transactions already provide.

---

## Common Pitfalls

### Pitfall 1: Firestore Web Persistence Breaks Transactions
**What goes wrong:** On Flutter Web, if offline persistence is enabled (the default), `runTransaction` may appear to succeed locally but fail to replicate, or return stale data. The slot appears booked in the UI but the server never received the write.
**Why it happens:** IndexedDB caches simulate offline-first behavior; Transactions require a fresh server round-trip that conflicts with cached state.
**How to avoid:** Add `FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false)` before `runApp()` in `main.dart`, guarded by `kIsWeb`.
**Warning signs:** Transaction appears to succeed in dev but booking doesn't appear in Firebase Console; no error thrown.

### Pitfall 2: Transaction Does Not Check for Cancelled Bookings
**What goes wrong:** If a slot was booked and then cancelled, the document exists with `status: 'cancelled'`. A naive existence check (`if (snapshot.exists)`) would incorrectly block a new booking on a cancelled slot.
**Why it happens:** The document is never deleted — only status is updated. The doc ID collision check must ignore cancelled bookings.
**How to avoid:** Inside the Transaction, check `!existing.isCancelled`. Only throw if the existing booking is active (`pending` or `confirmed`).

### Pitfall 3: Bottom Sheet Closes Before Transaction Completes (Ghost Booking)
**What goes wrong:** The bottom sheet closes immediately after the user taps "Reservar", before the Firestore Transaction is acknowledged. If the transaction fails, the user sees the schedule update visually (stream may not have fired yet) but the booking was never written.
**Why it happens:** Calling `Navigator.pop(context)` synchronously before awaiting the Future.
**How to avoid:** Keep the sheet open (`isSubmitting = true`, button disabled) until the `bookSlot()` future resolves. Only `Navigator.pop()` on success; show error message on failure without closing.

### Pitfall 4: BookingCubit Emits Loading State Globally During Write
**What goes wrong:** If `bookSlot()` emits `BookingLoading` globally, the My Bookings screen blanks out (shows spinner) while a booking is being created from the Schedule tab.
**Why it happens:** Reusing the main cubit state for transient write operations.
**How to avoid:** Write operations (`bookSlot`, `cancelBooking`) return a `Future` that the calling UI awaits. They do NOT change the cubit's stream state. Only stream events change `BookingLoaded`.

### Pitfall 5: Composite Firestore Index Required for My Bookings Query
**What goes wrong:** Querying `/bookings` with `.where('userId', ...)` plus `.orderBy('date', ...)` requires a composite index in Firestore. Without it, the SDK throws a `PlatformException` with a link to create the index.
**Why it happens:** Firestore requires composite indexes for any query that filters on one field and orders by another (different) field.
**How to avoid:** Either (a) create the composite index (`userId` ASC + `date` DESC) in `firestore.indexes.json` before running the query in production, or (b) order locally in Dart after receiving the stream snapshot (simpler, avoids index requirement).
**Recommendation:** Order locally in Dart — the dataset per user is small enough that local sort is negligible. Use a simple `.where('userId', isEqualTo: uid)` stream with no `orderBy`. Sort the resulting list in Dart.

### Pitfall 6: SlotViewModel Does Not Carry BookingModel — Missing Price in Bottom Sheet
**What goes wrong:** The bottom sheet needs to display the slot price. `SlotViewModel` currently carries `SlotModel` (which has `price`). However, to pass context to the bottom sheet, the handler needs access to `SlotViewModel.slot.price` and `SlotViewModel.slot.id` and `viewModel.dateString`. These are already on `SlotViewModel` — no model change needed.
**How to avoid:** Pass the entire `SlotViewModel` to the bottom sheet builder. The sheet reads `viewModel.slot.startTime`, `viewModel.slot.price`, `viewModel.dateString` directly.

---

## Code Examples

### main.dart — Disable Firestore Persistence for Web

```dart
// lib/main.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Firestore Transactions on Flutter Web require persistence disabled.
  // Without this, concurrent booking writes may behave incorrectly.
  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  }

  runApp(const VidaAtivaApp());
}
```

### BookingCubit — Stream + Write Methods

```dart
// lib/features/booking/cubit/booking_cubit.dart
class BookingCubit extends Cubit<BookingState> {
  final FirebaseFirestore _firestore;
  final String _userId;
  StreamSubscription<QuerySnapshot>? _sub;

  BookingCubit({required FirebaseFirestore firestore, required String userId})
      : _firestore = firestore,
        _userId = userId,
        super(const BookingInitial()) {
    _startStream();
  }

  void _startStream() {
    emit(const BookingLoading());
    _sub = _firestore
        .collection('bookings')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .listen(
          (snap) => emit(BookingLoaded(
            snap.docs.map((d) => BookingModel.fromFirestore(d)).toList(),
          )),
          onError: (_) => emit(const BookingError('Erro ao carregar reservas.')),
        );
  }

  /// Returns normally on success. Throws on double-booking or network error.
  Future<void> bookSlot({
    required String slotId,
    required String dateString,
    required double price,
  }) async {
    final docId = BookingModel.generateId(slotId, dateString);
    final ref = _firestore.collection('bookings').doc(docId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
        final existing = BookingModel.fromFirestore(snap);
        if (!existing.isCancelled) throw Exception('slot_already_booked');
      }
      final booking = BookingModel(
        id: docId,
        slotId: slotId,
        date: dateString,
        userId: _userId,
        status: 'pending',
        createdAt: DateTime.now(),
      );
      tx.set(ref, booking.toFirestore());
    });
  }

  /// Returns normally on success. Throws on network error.
  Future<void> cancelBooking(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': 'cancelled',
      'cancelledAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
```

### BookingConfirmationSheet — Inline Loading Button

```dart
// lib/features/booking/ui/booking_confirmation_sheet.dart
class BookingConfirmationSheet extends StatefulWidget {
  final SlotViewModel viewModel;
  final Future<void> Function() onConfirm;

  const BookingConfirmationSheet({
    super.key,
    required this.viewModel,
    required this.onConfirm,
  });

  @override
  State<BookingConfirmationSheet> createState() =>
      _BookingConfirmationSheetState();
}

class _BookingConfirmationSheetState extends State<BookingConfirmationSheet> {
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _handleConfirm() async {
    setState(() { _isSubmitting = true; _errorMessage = null; });
    try {
      await widget.onConfirm();
      if (mounted) Navigator.pop(context); // Close only on success
      // Caller shows SnackBar "Reserva feita!" after pop
    } on Exception catch (e) {
      final msg = e.toString().contains('slot_already_booked')
          ? 'Este horario acabou de ser reservado.'
          : 'Falha na conexao. Tente novamente.';
      setState(() { _isSubmitting = false; _errorMessage = msg; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... sheet content with time, date, price display
    // FilledButton pattern: child is _isSubmitting
    //   ? const CircularProgressIndicator(color: Colors.white)
    //   : const Text('Reservar')
    // onPressed: _isSubmitting ? null : _handleConfirm
  }
}
```

### My Bookings Screen — Section Split

```dart
// Split logic inside BookingLoaded handler
final today = DateTime.now();
final todayString =
    '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

final upcoming = bookings
    .where((b) => b.date >= todayString && !b.isCancelled)
    .toList()
  ..sort((a, b) => a.date.compareTo(b.date)); // ascending

final past = bookings
    .where((b) => b.date < todayString || b.isCancelled)
    .toList()
  ..sort((a, b) => b.date.compareTo(a.date)); // descending
```

Note: String comparison on "YYYY-MM-DD" format is lexicographically correct for date ordering.

### app_router.dart — BookingCubit at Shell Level

```dart
// In createRouter, wrap the StatefulShellRoute builder:
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) {
    final authState = context.read<AuthCubit>().state as AuthAuthenticated;
    return BlocProvider(
      create: (_) => BookingCubit(
        firestore: FirebaseFirestore.instance,
        userId: authState.user.uid,
      ),
      child: AppShell(navigationShell: navigationShell),
    );
  },
  branches: [ /* ... unchanged ... */ ],
),
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Firestore `.add()` for writes | `.doc(deterministicId).set()` in Transaction | Firestore SDK since v1 | Mandatory for anti-double-booking |
| `WillPopScope` for back button | `PopScope` | Flutter 3.12+ | `WillPopScope` is deprecated in Flutter 3.x; use `PopScope` if needed in the bottom sheet |
| `persistenceEnabled` via `Firestore.instance.settings` | Same API, still valid | cloud_firestore ^5+ | No change — `Settings(persistenceEnabled: false)` is current API |

---

## Open Questions

1. **Composite Firestore index for My Bookings query**
   - What we know: `.where('userId').orderBy('date')` requires a composite index; local sort avoids this
   - What's unclear: Whether the planner wants to create the index in `firestore.indexes.json` now (correct for production) or defer to Phase 6 hardening
   - Recommendation: Sort locally in Dart for Phase 4 simplicity; flag composite index creation as a Phase 6 task

2. **BookingCubit receives userId at construction time**
   - What we know: AuthCubit exposes `AuthAuthenticated.user.uid`; the user is guaranteed authenticated when reaching the shell
   - What's unclear: If the user logs out and back in during the same session, the cubit's `_userId` would be stale
   - Recommendation: Provide `BookingCubit` inside the `StatefulShellRoute` builder which runs after auth resolves; the cubit is re-created if the shell re-builds after logout/login

3. **Price data in bottom sheet**
   - What we know: `SlotViewModel.slot.price` (double) is available; `intl` is already installed
   - What's unclear: Whether the slot price should be fetched fresh from Firestore or trusted from the cached SlotViewModel
   - Recommendation: Trust the `SlotViewModel.slot.price` — it comes from the live Firestore stream; no separate fetch needed

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (built-in) + bloc_test ^10.0.0 + mocktail ^1.0.4 |
| Config file | None — standard `flutter test` invocation |
| Quick run command | `flutter test test/features/booking/` |
| Full suite command | `flutter test` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BOOK-01 | `bookSlot` aborts when doc exists and is not cancelled | unit (bloc_test) | `flutter test test/features/booking/booking_cubit_test.dart` | Wave 0 |
| BOOK-01 | `bookSlot` succeeds when doc does not exist | unit (bloc_test) | `flutter test test/features/booking/booking_cubit_test.dart` | Wave 0 |
| BOOK-01 | `bookSlot` succeeds when doc exists but is cancelled | unit (bloc_test) | `flutter test test/features/booking/booking_cubit_test.dart` | Wave 0 |
| BOOK-02 | `cancelBooking` updates status to cancelled | unit (bloc_test) | `flutter test test/features/booking/booking_cubit_test.dart` | Wave 0 |
| BOOK-03 | Stream emits `BookingLoaded` with user's bookings | unit (bloc_test) | `flutter test test/features/booking/booking_cubit_test.dart` | Wave 0 |
| BOOK-03 | Upcoming/past split is correct relative to today | unit (dart test) | `flutter test test/features/booking/booking_cubit_test.dart` | Wave 0 |

**Note:** Per project memory (`feedback_no_tests.md`), unit tests and widget tests are NOT generated in this project. The Validation Architecture section is included for completeness but no test files will be created during implementation.

### Sampling Rate
- **Per task commit:** No automated test run — see project memory constraint
- **Per wave merge:** Manual verification against success criteria
- **Phase gate:** Human checkpoint before `/gsd:verify-work`

### Wave 0 Gaps
- None to create (tests not generated per project convention)

---

## Sources

### Primary (HIGH confidence)
- Firestore Flutter SDK documentation — `runTransaction`, `Settings(persistenceEnabled: false)`, `tx.set()` vs `tx.update()`
- Existing codebase — `BookingModel.generateId()`, `ScheduleCubit` stream pattern, `AuthCubit` userId access, `SlotCard` structure, `app_router.dart` shell pattern
- Phase context files (01, 02, 03, 04 CONTEXT.md) — locked decisions, established patterns

### Secondary (MEDIUM confidence)
- `cloud_firestore ^6.1.3` changelog — `Settings` API confirmed stable since v5+
- Flutter `showModalBottomSheet` API — standard modal pattern with `isScrollControlled`

### Tertiary (LOW confidence)
- None — all critical claims are verified against codebase or official SDK patterns

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages already in pubspec, no new deps
- Architecture: HIGH — BookingCubit pattern mirrors ScheduleCubit exactly; Firestore Transaction is well-documented
- Pitfalls: HIGH — derived from STATE.md documented concern (persistence + transactions) and direct codebase inspection

**Research date:** 2026-03-20
**Valid until:** 2026-06-20 (cloud_firestore API is stable; BLoC patterns stable)

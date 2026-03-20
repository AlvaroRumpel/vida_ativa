# Phase 5: Admin - Research

**Researched:** 2026-03-20
**Domain:** Flutter admin panel — Firestore CRUD for slots/blocked-dates, booking management, config document pattern
**Confidence:** HIGH

---

## Summary

Phase 5 delivers a protected admin interface built entirely on the patterns already established in Phases 1–4. No new packages are required: the existing `flutter_bloc`, `cloud_firestore`, `go_router`, and `intl` stack covers every requirement. The core technical work is three cubit/Firestore clusters — AdminSlotCubit (slot CRUD + toggle active), AdminBlockedDateCubit (date blocking), and AdminBookingCubit (all-bookings stream + confirm/reject/config) — wired behind the `/admin` route that already has an auth guard.

The most architecturally novel element is ADMN-06 (confirmation mode toggle). The cleanest design follows the existing `blockedDates` pattern: a single Firestore document `/config/booking` with a `confirmationMode` field (`"automatic"` | `"manual"`). `BookingCubit.bookSlot()` reads this document before each booking write to set the initial status. This is a one-document Firestore read, not a stream, so it is cheap and requires no index.

The admin UI has no existing visual pattern in the codebase to reuse directly, but it can be scaffolded as a standard `DefaultTabController` (Slots | Bloqueios | Reservas) inside a `Scaffold`+`AppBar`, matching Material 3 conventions already used in all other screens.

**Primary recommendation:** Build three focused cubits (AdminSlotCubit, AdminBlockedDateCubit, AdminBookingCubit), one config document in Firestore, and a tab-based admin screen. No new packages.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| ADMN-01 | Admin pode criar e editar slots recorrentes (dia da semana + horário + preço) | Firestore `.set()` / `.update()` on `/slots/{id}` — same collection ScheduleCubit already reads. Create uses `.add()` (admin-only, no deterministic ID needed here). Edit uses `.doc(id).update()`. |
| ADMN-02 | Admin pode desativar um slot recorrente sem excluí-lo | `SlotModel.isActive` already exists. Single `.update({'isActive': false})` on `/slots/{id}`. ScheduleCubit already filters `where('isActive', isEqualTo: true)` so inactive slots vanish immediately from user schedule. |
| ADMN-03 | Admin pode bloquear datas específicas (feriados, manutenção, eventos) | `BlockedDateModel` already exists. Doc ID = date string. `.doc(dateString).set(model.toFirestore())` to block; `.doc(dateString).delete()` to unblock. ScheduleCubit already reacts to `/blockedDates/{date}`. |
| ADMN-04 | Admin pode ver todas as reservas filtradas por data | Query `/bookings` `.where('date', isEqualTo: selectedDateString)` — no composite index needed (single field). Stream it reactively. Display UserModel data requires a secondary read of `/users/{userId}` per booking (or store displayName at booking time). |
| ADMN-05 | Admin pode confirmar ou recusar reservas pendentes | `.update({'status': 'confirmed'})` or `.update({'status': 'rejected'})` on `/bookings/{id}`. `BookingModel.status` field supports string values. Adding `'rejected'` as a valid status — consistent with existing pattern. BookingCubit stream on client side reacts automatically. |
| ADMN-06 | Admin pode configurar o modo de confirmação (automático ou aprovação manual) | Firestore doc `/config/booking` with field `confirmationMode: "automatic" | "manual"`. BookingCubit reads it once before each `bookSlot()` call to determine initial status ("confirmed" vs "pending"). |
</phase_requirements>

---

## Standard Stack

### Core (all already installed)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_bloc | ^9.1.1 | AdminSlotCubit, AdminBlockedDateCubit, AdminBookingCubit | Established pattern — every feature uses Cubit<State> |
| cloud_firestore | ^6.1.3 | All Firestore reads/writes for admin operations | Already wired; persistence disabled on Web (main.dart) |
| go_router | ^17.1.0 | Route `/admin` already declared with isAdmin guard | No change needed |
| intl | ^0.20.2 | Date formatting in admin booking list | Already a direct dep |
| equatable | ^2.0.8 | Admin state classes | All state classes use Equatable |

### No New Packages Required

All Phase 5 functionality fits within the current pubspec. The admin interface is CRUD on existing collections using existing widgets and patterns.

**Installation:** None — no `flutter pub add` needed.

---

## Architecture Patterns

### Recommended File Structure

```
lib/features/admin/
├── cubit/
│   ├── admin_slot_cubit.dart
│   ├── admin_slot_state.dart
│   ├── admin_blocked_date_cubit.dart
│   ├── admin_blocked_date_state.dart
│   ├── admin_booking_cubit.dart
│   └── admin_booking_state.dart
├── ui/
│   ├── admin_screen.dart             # DefaultTabController wrapper
│   ├── slot_management_tab.dart      # ADMN-01, ADMN-02
│   ├── blocked_dates_tab.dart        # ADMN-03
│   ├── booking_management_tab.dart   # ADMN-04, ADMN-05, ADMN-06
│   ├── slot_form_sheet.dart          # Create/edit slot bottom sheet
│   └── admin_booking_card.dart       # BookingCard variant with confirm/reject
└── ui/admin_placeholder_screen.dart  # Already exists — to be replaced
```

### Pattern 1: Three-Cubit Admin Screen

Each admin tab owns its cubit, provided at the `AdminScreen` level so all tabs share the same instance without recreation on tab switch.

```dart
// admin_screen.dart — provide all three cubits at screen level
BlocProvider(
  create: (_) => AdminSlotCubit(firestore: FirebaseFirestore.instance),
  child: BlocProvider(
    create: (_) => AdminBlockedDateCubit(firestore: FirebaseFirestore.instance),
    child: BlocProvider(
      create: (_) => AdminBookingCubit(
        firestore: FirebaseFirestore.instance,
        authCubit: context.read<AuthCubit>(),
      ),
      child: const _AdminScreenBody(),
    ),
  ),
);
```

`_AdminScreenBody` uses `DefaultTabController(length: 3)` with tabs: Slots | Bloqueios | Reservas.

### Pattern 2: Slot CRUD with Stream

AdminSlotCubit streams ALL slots (not filtered by isActive or dayOfWeek) so the admin sees inactive ones too.

```dart
// admin_slot_cubit.dart
_sub = _firestore
    .collection('slots')
    .snapshots()
    .listen((snap) {
  final slots = snap.docs.map(SlotModel.fromFirestore).toList();
  // Sort by dayOfWeek then startTime
  slots.sort((a, b) {
    final cmp = a.dayOfWeek.compareTo(b.dayOfWeek);
    return cmp != 0 ? cmp : a.startTime.compareTo(b.startTime);
  });
  emit(AdminSlotLoaded(slots));
});

Future<void> createSlot({
  required int dayOfWeek,
  required String startTime,
  required double price,
}) async {
  await _firestore.collection('slots').add({
    'dayOfWeek': dayOfWeek,
    'startTime': startTime,
    'price': price,
    'isActive': true,
  });
}

Future<void> updateSlot(String slotId, {
  required int dayOfWeek,
  required String startTime,
  required double price,
}) async {
  await _firestore.collection('slots').doc(slotId).update({
    'dayOfWeek': dayOfWeek,
    'startTime': startTime,
    'price': price,
  });
}

Future<void> setSlotActive(String slotId, bool isActive) async {
  await _firestore.collection('slots').doc(slotId).update({'isActive': isActive});
}
```

Note: slot creation uses `.add()` (auto-ID) — the deterministic ID rule only applies to BookingModel to enable the anti-double-booking transaction.

### Pattern 3: Config Document for ADMN-06

Single Firestore document at `/config/booking` holds the confirmation mode.

```dart
// Reading mode before bookSlot (in BookingCubit):
final configSnap = await _firestore.collection('config').doc('booking').get();
final mode = configSnap.data()?['confirmationMode'] ?? 'manual';
final initialStatus = mode == 'automatic' ? 'confirmed' : 'pending';

// AdminBookingCubit toggles it:
Future<void> setConfirmationMode(String mode) async {
  // mode: 'automatic' | 'manual'
  await _firestore.collection('config').doc('booking').set(
    {'confirmationMode': mode},
    SetOptions(merge: true),
  );
}
```

The config document must be initialized (bootstrapped) if it doesn't exist — `SetOptions(merge: true)` on write handles this gracefully.

### Pattern 4: Admin Booking List (ADMN-04, ADMN-05)

AdminBookingCubit streams bookings for a selected date, providing all statuses (not filtered like ScheduleCubit).

```dart
// admin_booking_cubit.dart
void selectDate(DateTime date) {
  _sub?.cancel();
  final dateString = _toDateString(date);
  _sub = _firestore
      .collection('bookings')
      .where('date', isEqualTo: dateString)
      .snapshots()
      .listen((snap) {
    final bookings = snap.docs.map(BookingModel.fromFirestore).toList();
    emit(AdminBookingLoaded(bookings, selectedDate: date));
  });
}

Future<void> confirmBooking(String bookingId) async {
  await _firestore.collection('bookings').doc(bookingId).update({
    'status': 'confirmed',
  });
}

Future<void> rejectBooking(String bookingId) async {
  await _firestore.collection('bookings').doc(bookingId).update({
    'status': 'rejected',
  });
}
```

**Important:** `rejected` is a new status value not yet in BookingModel. BookingModel.dart needs `bool get isRejected => status == 'rejected';` getter added. The `_statusBadge` in BookingCard also needs a `rejected` case.

### Pattern 5: Router Wiring

`/admin` is already declared in `app_router.dart` with the isAdmin guard. Phase 5 replaces `AdminPlaceholderScreen` with `AdminScreen`:

```dart
GoRoute(
  path: '/admin',
  builder: (context, _) => BlocProvider(
    create: (_) => AdminSlotCubit(firestore: FirebaseFirestore.instance),
    child: /* ... */,
  ),
),
```

### Anti-Patterns to Avoid

- **Providing admin cubits inside the tab builders**: Each tab switch would recreate the cubit. Provide at `AdminScreen` level (same as `BookingCubit` at `StatefulShellRoute` level).
- **Using `.add()` for bookings**: BookingModel ID must be deterministic — the anti-double-booking transaction depends on it. Admin never creates bookings directly.
- **Storing userId lookup per booking in the list**: Do not query `/users/{uid}` for each booking in the list — it causes N reads per render. Instead store `displayName` at booking creation time (same pattern as `startTime` and `price` stored in `BookingModel`). However, current `BookingModel` does NOT include `userDisplayName`. Plan must decide: add field to BookingModel (requires migration) OR show userId only in admin view.
- **Forgetting `SetOptions(merge: true)` on config doc**: Without it, the first write creates the document but subsequent calls overwrite all fields — safe in this case since there is only one field, but merge is the correct pattern for partial config updates.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Date picker for blocked dates | Custom date grid | `showDatePicker()` (Flutter built-in) | Material date picker handles locale, accessibility, min/max date constraints |
| Time picker for slot startTime | Custom time input | `showTimePicker()` (Flutter built-in) | Returns `TimeOfDay`; format with `'${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}'` |
| Config persistence | Local SharedPreferences or memory | Firestore `/config/booking` doc | Survives app restarts, syncs across admin devices, reactive |
| Role enforcement in UI | Manual role checks in every widget | GoRouter guard already wired at `/admin` | Guard is the single enforcement point — UI widgets under `/admin` trust the route is admin-only |
| Booking status display for admin | New widget from scratch | Extend `BookingCard` or create `AdminBookingCard` with confirm/reject buttons | `BookingCard` already handles status badge, date/time formatting — add action buttons on top |

---

## Common Pitfalls

### Pitfall 1: userDisplayName Missing from BookingModel

**What goes wrong:** Admin booking list (ADMN-04) needs to show "who booked" for each booking. `BookingModel` stores `userId` but not `displayName`.

**Why it happens:** Phase 4 designed BookingModel for client-side use (client only sees their own bookings, so userId is enough). Admin needs to display the requester name.

**How to avoid:** Two options — pick one and commit:
- **Option A (preferred):** Add `userDisplayName` field to `BookingModel.toFirestore()` / `fromFirestore()` and populate it in `BookingCubit.bookSlot()` from `AuthCubit.state` at booking time. Admin reads it directly. Zero extra Firestore reads.
- **Option B:** In admin view, show only the userId truncated (e.g., "UID: abc...xyz") with a note that names appear in Phase 6 or v2. Avoids model change.

**Warning signs:** `BookingModel` shows `userId` in admin UI but admin cannot identify the client.

### Pitfall 2: `rejected` Status Not in BookingModel

**What goes wrong:** `confirmBooking` writes `status: 'confirmed'` — fine. `rejectBooking` writes `status: 'rejected'` — but `BookingModel.isCancelled` only checks for `'cancelled'`, and `_statusBadge` in `BookingCard` falls through to `default: 'Cancelado'`. Client sees "Cancelado" badge instead of "Recusado".

**Why it happens:** Phase 4 only defined three statuses: pending/confirmed/cancelled.

**How to avoid:** Add `bool get isRejected => status == 'rejected';` to `BookingModel`. Update `_statusColor` and `_statusLabel` in `BookingCard` (and new `AdminBookingCard`) to handle `'rejected'` explicitly.

**Warning signs:** A rejected booking displays as "Cancelado" in the client's My Bookings screen.

### Pitfall 3: Config Document Doesn't Exist Yet

**What goes wrong:** `BookingCubit.bookSlot()` reads `/config/booking` — but no admin has ever opened the admin panel to set the mode. `configSnap.data()` returns `null`. Code throws a null-reference or defaults incorrectly.

**Why it happens:** The document only exists after the first admin write. On a fresh deployment, it won't be there.

**How to avoid:** Always use null-safe fallback: `configSnap.data()?['confirmationMode'] ?? 'manual'`. Default to `'manual'` (safest — admin must explicitly confirm bookings). Document this in the config write as well.

**Warning signs:** First booking on a fresh deployment enters with unexpected status.

### Pitfall 4: Slot `.add()` vs `.doc().set()` Confusion

**What goes wrong:** Developer applies the "always use `.doc(id).set()`" rule from BookingModel to SlotModel. Tries to generate a deterministic slot ID (e.g., `{dayOfWeek}_{startTime}`) and fails when the same time is added twice for the same day (duplicate slot prevention).

**Why it happens:** The deterministic-ID rule in STATE.md applies ONLY to BookingModel for anti-double-booking. SlotModel has no such requirement.

**How to avoid:** Use `.add()` for new slots — Firestore auto-generates a unique ID. The slot ID is stored as `SlotModel.id` (already the document ID in `fromFirestore()`).

### Pitfall 5: Admin Booking Filter Requires No Composite Index

**What goes wrong:** Adding `.orderBy()` to the admin booking query (e.g., to sort by time) while also using `.where('date', isEqualTo: ...)` creates a composite index requirement that must be deployed to Firestore.

**Why it happens:** Firestore requires composite indexes for queries combining `where` + `orderBy` on different fields.

**How to avoid:** Follow the established Phase 4 pattern — query with single `.where()` only, sort locally in Dart. `STATE.md` explicitly notes: "BookingCubit queries without .orderBy() to avoid composite index — sorted locally in Dart."

### Pitfall 6: Context Capture in Admin Action Dialogs

**What goes wrong:** Admin taps "Confirmar" in a dialog, the dialog closes, then `context.read<AdminBookingCubit>()` is called — but the context is from the now-disposed dialog subtree.

**Why it happens:** Dialogs and bottom sheets create their own widget subtrees without the parent's `BlocProvider` tree.

**How to avoid:** Follow the established Phase 4 pattern: capture the cubit reference BEFORE showing the dialog/sheet. `STATE.md` notes: "context.read<BookingCubit>() captured before showModalBottomSheet builder."

```dart
final cubit = context.read<AdminBookingCubit>(); // capture before showDialog
showDialog(
  context: context,
  builder: (dialogCtx) => AlertDialog(
    actions: [
      TextButton(
        onPressed: () => cubit.confirmBooking(bookingId), // use captured ref
        child: const Text('Confirmar'),
      ),
    ],
  ),
);
```

---

## Code Examples

### Slot Form Sheet (Create + Edit)

```dart
// slot_form_sheet.dart — StatefulWidget for inline validation
class SlotFormSheet extends StatefulWidget {
  final SlotModel? existing; // null = create mode

  const SlotFormSheet({super.key, this.existing});
}

class _SlotFormSheetState extends State<SlotFormSheet> {
  late int _dayOfWeek;
  late String _startTime; // "HH:mm"
  late double _price;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dayOfWeek = widget.existing?.dayOfWeek ?? 1;
    _startTime = widget.existing?.startTime ?? '08:00';
    _price = widget.existing?.price ?? 0.0;
  }

  Future<void> _submit() async {
    setState(() { _isSubmitting = true; _error = null; });
    try {
      final cubit = context.read<AdminSlotCubit>();
      if (widget.existing == null) {
        await cubit.createSlot(dayOfWeek: _dayOfWeek, startTime: _startTime, price: _price);
      } else {
        await cubit.updateSlot(widget.existing!.id, dayOfWeek: _dayOfWeek, startTime: _startTime, price: _price);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _isSubmitting = false; _error = 'Erro ao salvar. Tente novamente.'; });
    }
  }
}
```

### Time Picker Integration

```dart
// Convert Flutter TimeOfDay to "HH:mm" string
Future<void> _pickTime() async {
  final initial = _parseTime(_startTime); // TimeOfDay.fromDateTime(...)
  final picked = await showTimePicker(context: context, initialTime: initial);
  if (picked != null) {
    setState(() {
      _startTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    });
  }
}

TimeOfDay _parseTime(String hhmm) {
  final parts = hhmm.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}
```

### Day of Week Picker

```dart
// Simple DropdownButton — no new package needed
const _days = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];

DropdownButton<int>(
  value: _dayOfWeek,
  items: List.generate(7, (i) => DropdownMenuItem(
    value: i + 1,
    child: Text(_days[i]),
  )),
  onChanged: (v) => setState(() => _dayOfWeek = v!),
)
```

### Blocked Date Management

```dart
// admin_blocked_date_cubit.dart
class AdminBlockedDateCubit extends Cubit<AdminBlockedDateState> {
  final FirebaseFirestore _firestore;
  StreamSubscription? _sub;

  AdminBlockedDateCubit({required FirebaseFirestore firestore})
      : _firestore = firestore,
        super(const AdminBlockedDateInitial()) {
    _startStream();
  }

  void _startStream() {
    _sub = _firestore
        .collection('blockedDates')
        .snapshots()
        .listen((snap) {
      final dates = snap.docs.map(BlockedDateModel.fromFirestore).toList();
      dates.sort((a, b) => a.date.compareTo(b.date));
      emit(AdminBlockedDateLoaded(dates));
    });
  }

  Future<void> blockDate(String dateString, String adminUid) async {
    final model = BlockedDateModel(date: dateString, createdBy: adminUid);
    await _firestore
        .collection('blockedDates')
        .doc(dateString)
        .set(model.toFirestore());
  }

  Future<void> unblockDate(String dateString) async {
    await _firestore.collection('blockedDates').doc(dateString).delete();
  }
}
```

### BookingModel Extension for `rejected` Status

```dart
// Add to booking_model.dart
bool get isRejected => status == 'rejected';

// Update _statusLabel and _statusColor in booking_card.dart:
String _statusLabel(String status) => switch (status) {
  'pending' => 'Aguardando',
  'confirmed' => 'Confirmado',
  'rejected' => 'Recusado',
  _ => 'Cancelado',
};

Color _statusColor(String status) => switch (status) {
  'pending' => Colors.orange,
  'confirmed' => AppTheme.primaryGreen,
  'rejected' => Colors.red,
  _ => Colors.grey,
};
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Admin in BottomNav (3 tabs) | `/admin` as separate route, not in BottomNav | Phase 1 decision | Admin panel is "hidden" — regular users never see it; accessed by direct URL or a link in ProfileScreen |
| Confirmation always manual | Configurable via `/config/booking` Firestore doc | Phase 5 (ADMN-06) | BookingCubit must read config doc before each booking write |
| 3 booking statuses (pending/confirmed/cancelled) | 4 statuses (+ rejected) | Phase 5 (ADMN-05) | BookingModel, BookingCard, and any status switch must be updated |

**Deprecated/outdated:**
- `AdminPlaceholderScreen`: replace entirely with `AdminScreen` — do not modify the placeholder.

---

## Architecture Decision: Admin Route Wiring

The `/admin` route in `app_router.dart` currently returns `AdminPlaceholderScreen` directly. Phase 5 replaces it with a builder that provides all admin cubits:

```dart
GoRoute(
  path: '/admin',
  builder: (context, _) {
    final authState = context.read<AuthCubit>().state as AuthAuthenticated;
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AdminSlotCubit(firestore: FirebaseFirestore.instance)),
        BlocProvider(create: (_) => AdminBlockedDateCubit(firestore: FirebaseFirestore.instance)),
        BlocProvider(create: (_) => AdminBookingCubit(
          firestore: FirebaseFirestore.instance,
          adminUid: authState.user.uid,
        )),
      ],
      child: const AdminScreen(),
    );
  },
),
```

`MultiBlocProvider` (available in `flutter_bloc`) reduces nesting vs nested `BlocProvider` calls.

---

## Architecture Decision: Admin Navigation Entry Point

The admin panel at `/admin` is accessed via a button in `ProfileScreen`. An admin user tapping "Painel Admin" in their profile navigates to `/admin`. Non-admin users never see this button (conditional on `authState.user.isAdmin`). This is already enforced by the GoRouter guard — the button is defense-in-depth.

---

## Open Questions

1. **userDisplayName in admin booking list**
   - What we know: `BookingModel` stores `userId` but not `displayName`. Admin needs to show who booked (ADMN-04 says "see the requester").
   - What's unclear: Should we add `userDisplayName` to `BookingModel` (changes the booking write in `BookingCubit`) or accept showing only userId in Phase 5?
   - Recommendation: Add `userDisplayName` to `BookingModel` — store it at booking creation time alongside `startTime` and `price`. Small change, matches existing pattern, makes admin view genuinely useful. Requires `BookingCubit.bookSlot()` to receive `userDisplayName` from `AuthCubit`.

2. **Admin entry point in ProfileScreen**
   - What we know: `/admin` exists as a route with isAdmin guard. There is no link to it from any screen yet.
   - What's unclear: Should the "Painel Admin" button live in ProfileScreen or in a separate admin BottomNav item?
   - Recommendation: Add a conditional "Painel Admin" button in `ProfileScreen` (visible only when `authState.user.isAdmin`). Simpler than changing `AppShell` or adding a 4th tab.

3. **Confirmation mode default**
   - What we know: `/config/booking` doc may not exist on first run.
   - Recommendation: Default to `'manual'` when doc is absent or field is missing. Document this as the safe default.

---

## Validation Architecture

> nyquist_validation is enabled (config.json: `"nyquist_validation": true`). However, per project memory feedback (`feedback_no_tests.md`): **do not generate unit or widget tests for this project**. Validation is manual/smoke only.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (present but not used per project feedback) |
| Config file | none |
| Quick run command | N/A — manual smoke test |
| Full suite command | N/A — manual smoke test |

### Phase Requirements -> Validation Map

Per project feedback, no automated tests are generated. Validation is manual:

| Req ID | Behavior | Validation Method |
|--------|----------|-------------------|
| ADMN-01 | Create slot → appears in ScheduleScreen next matching day | Manual: create slot, check schedule tab |
| ADMN-02 | Deactivate slot → disappears from ScheduleScreen | Manual: toggle isActive, verify schedule tab |
| ADMN-03 | Block date → all slots hidden for that date | Manual: block today's date, verify schedule tab |
| ADMN-04 | Admin sees all bookings for a date | Manual: pick a date with known bookings, verify list |
| ADMN-05 | Confirm/reject → client booking status updates | Manual: confirm booking, check My Bookings badge |
| ADMN-06 | Toggle mode → new bookings enter with correct status | Manual: switch to automatic, book a slot, verify "Confirmado" status |

### Wave 0 Gaps

None — no test files to create per project feedback. Validation is manual smoke testing at phase gate.

---

## Sources

### Primary (HIGH confidence)

- Direct codebase reading — all Dart files in `lib/` confirmed current implementation state
- `firestore.rules` — confirmed Phase 1 bootstrap rules; Phase 6 adds `isAdmin()` granularity
- `.planning/STATE.md` — accumulated decisions, especially: no `.orderBy()` on booking queries; `.add()` vs `.doc(id).set()` rule; BookingCubit stream-reactive pattern; context capture before bottom sheet
- `.planning/phases/01-04/*/CONTEXT.md` — locked decisions for models, patterns, router

### Secondary (MEDIUM confidence)

- Flutter Material documentation for `showDatePicker()`, `showTimePicker()`, `DefaultTabController` — standard Flutter built-ins, behavior is stable
- `cloud_firestore` Dart SDK — `SetOptions(merge: true)`, single-field `.update()`, `.delete()` — standard Firestore operations consistent with Phase 3/4 usage

### Tertiary (LOW confidence)

- None — all findings derived from existing codebase and established patterns.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — confirmed from pubspec.yaml; no new packages needed
- Architecture patterns: HIGH — derived directly from existing cubits and router in codebase
- Pitfalls: HIGH — derived from STATE.md accumulated decisions and direct code inspection
- Open questions: MEDIUM — userDisplayName gap is a real design hole requiring a decision; others are clear

**Research date:** 2026-03-20
**Valid until:** Phase-specific research — valid for the lifetime of Phase 5 planning and execution

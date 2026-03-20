# Phase 3: Schedule - Research

**Researched:** 2026-03-19
**Domain:** Flutter BLoC + Firestore reactive streams + weekly calendar UI
**Confidence:** HIGH

## Summary

Phase 3 is a pure read-only view that assembles data from three Firestore collections — `/slots`, `/bookings`, `/blockedDates` — and renders a weekly calendar picker with a day-scoped slot list. All models are already implemented and serialization is proven. No new packages are needed; the stack (`flutter_bloc`, `cloud_firestore`, `equatable`) is already installed and working.

The critical design challenge is computing **slot status** correctly for the selected day. Status depends on: (1) whether the slot is active, (2) whether a booking exists for that slot+date (via deterministic ID lookup), (3) whether that booking belongs to the current user, and (4) whether the date itself is blocked. The Cubit owns this logic and exposes a single `List<SlotViewModel>` to the UI — the UI never inspects raw Firestore data.

The second challenge is **Firestore query strategy**. Querying the entire `/bookings` collection for a week at a time is inefficient. The deterministic `BookingModel.generateId(slotId, date)` means we can resolve booking status per-slot using `.doc(id).get()` or a targeted date-filtered stream, without a full collection scan.

**Primary recommendation:** One `ScheduleCubit` that listens to streams for the selected day: all active slots (filtered client-side by `dayOfWeek`), all bookings for that date, and all blocked dates for the week. Status computation happens in the cubit, not the widget.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Phase boundary:** Read-only display only. No booking button or placeholder for Phase 4.

**Slot card visual:**
- Card with colored left border by status (not solid fill background)
- Content: time + price + status label only (`SlotModel` has no `duration` or `name`)
- `isActive = false` slots disappear completely from the list — never shown

**Status colors:**
- Available → green (`#2E7D32`, `AppTheme.primaryGreen`)
- Booked → neutral grey (no distinction of who booked, except current user)
- Blocked → red/rose
- My booking → same grey as "Booked" but with badge/label "Minha reserva"
- Pending → treated same as Booked — slot is not available regardless of booking status

**Week day selector:**
- Horizontal scrollable chip row: `Seg 17`, `Ter 18`, etc. (abbreviated day + date number, Portuguese)
- Selected chip = highlighted with primary green
- On open: today selected by default
- Header above chips: `< | Semana de 17–23 Mar | >` with navigation arrows
- Left arrow disabled when on current week (no past navigation)
- Limit of 8 weeks ahead — right arrow disabled at limit

**Empty/missing states:**
- Day with no slots → centered message: "Nenhum horário disponível para este dia."
- Blocked date → on select: "Dia bloqueado — sem horários disponíveis."
- Loading → skeleton cards (3–4 grey pulsing cards) in slot area while loading from Firestore

### Claude's Discretion

- Internal implementation of ScheduleCubit (states: loading, loaded, error)
- Exact Firestore query format (stream per day vs full week)
- Logic for determining slot status (available/booked/my booking/blocked)
- Day-switching transition animation
- Exact style of skeleton loader

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within Phase 3 boundaries.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SCHED-01 | User can view available and occupied slots organized by week | WeekSelector widget with week navigation; ScheduleCubit streams slots filtered by dayOfWeek for the selected day |
| SCHED-02 | User can select a day to see slots for that day | Day chip selection drives cubit state; cubit re-fetches/re-filters for new day |
| SCHED-03 | Slot price is displayed in the slot listing | `SlotModel.price` (double) displayed as "R$ 50,00" using `NumberFormat.currency` or manual formatting — no extra package needed |
</phase_requirements>

---

## Standard Stack

### Core (already installed — no new packages needed)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_bloc | ^9.1.1 | ScheduleCubit state management | Project standard; AuthCubit pattern to replicate |
| cloud_firestore | ^6.1.3 | Real-time slot/booking/blockedDate streams | Project standard; all models already have `fromFirestore` |
| equatable | ^2.0.8 | State equality in Cubit | Project standard; prevents duplicate rebuilds |

### Supporting (already installed)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| flutter_bloc BlocConsumer | (part of flutter_bloc) | Listen + build in one widget | Exactly as Phase 2 auth screens do |

### New Packages Needed

**None.** All required functionality is covered by installed packages. Skeleton loading is implemented using `AnimatedContainer` or a custom widget with `shimmer`-style animation built from Flutter primitives (`Container` + `AnimatedOpacity` or a simple loop). No `shimmer` package is needed unless the team prefers it.

**Installation:** No changes to `pubspec.yaml` required.

---

## Architecture Patterns

### Recommended Project Structure

```
lib/features/schedule/
├── cubit/
│   ├── schedule_cubit.dart      # Cubit with Firestore stream subscriptions
│   └── schedule_state.dart      # ScheduleInitial / ScheduleLoading / ScheduleLoaded / ScheduleError
├── models/
│   └── slot_view_model.dart     # Computed view model: SlotModel + resolved status + date
└── ui/
    ├── schedule_screen.dart     # Root: BlocProvider + BlocBuilder scaffold
    ├── week_header.dart         # "< Semana de 17–23 Mar >" navigation row
    ├── day_chip_row.dart        # Horizontal scrollable chip list
    ├── slot_list.dart           # Loaded/empty/error state switcher
    ├── slot_card.dart           # Individual card with colored left border
    └── slot_skeleton.dart       # 3–4 grey pulsing skeleton cards
```

### Pattern 1: SlotViewModel — Computed Status Object

**What:** The cubit computes a `SlotViewModel` that carries the resolved `SlotStatus` enum alongside the raw `SlotModel`. The UI only reads `SlotViewModel`.

**Why:** Separates Firestore data fetching from status inference. The widget never touches `userId` comparisons or booking status strings.

```dart
// lib/features/schedule/models/slot_view_model.dart
enum SlotStatus { available, booked, myBooking, blocked }

class SlotViewModel extends Equatable {
  final SlotModel slot;
  final SlotStatus status;
  final String dateString; // "YYYY-MM-DD"

  const SlotViewModel({
    required this.slot,
    required this.status,
    required this.dateString,
  });

  @override
  List<Object?> get props => [slot, status, dateString];
}
```

### Pattern 2: ScheduleCubit — Three-Stream Architecture

**What:** The cubit manages subscriptions to three Firestore sources. On day selection change, it cancels old subscriptions and starts new ones for the selected date.

**Firestore queries for selected date (`selectedDate` is a `DateTime`):**

```dart
// Stream 1: All active slots (filter by dayOfWeek client-side)
// Slots are recurrent — no date field — query whole collection once or use .where()
_firestore
  .collection('slots')
  .where('isActive', isEqualTo: true)
  .where('dayOfWeek', isEqualTo: selectedDate.weekday)  // 1=Mon..7=Sun
  .snapshots()

// Stream 2: Bookings for this date (not cancelled)
// Using deterministic ID means we CAN'T use .doc() for a stream of all bookings.
// Instead, query by date string:
_firestore
  .collection('bookings')
  .where('date', isEqualTo: dateString)  // "YYYY-MM-DD"
  .where('status', whereIn: ['pending', 'confirmed'])
  .snapshots()

// Stream 3: Blocked date — single doc lookup (doc ID = date string)
_firestore
  .collection('blockedDates')
  .doc(dateString)
  .snapshots()
```

**Status resolution logic (inside cubit, called when any stream emits):**

```dart
SlotStatus _resolveStatus({
  required SlotModel slot,
  required bool isBlocked,
  required List<BookingModel> bookings,
  required String currentUserId,
}) {
  if (isBlocked) return SlotStatus.blocked;
  final booking = bookings.firstWhereOrNull((b) => b.slotId == slot.id);
  if (booking == null) return SlotStatus.available;
  if (booking.userId == currentUserId) return SlotStatus.myBooking;
  return SlotStatus.booked;
}
```

**Note:** `pending` bookings are treated as `booked` (slot not available). This is enforced by the `whereIn` filter above which excludes `cancelled`.

### Pattern 3: Week Navigation State

**What:** Week navigation is local UI state (not in Cubit). The Cubit receives the selected date and is unaware of weeks.

```dart
// In ScheduleScreen (StatefulWidget or local state)
DateTime _weekStart = _currentWeekMonday(); // computed once on init
DateTime _selectedDay = DateTime.now();

// Constraints:
// _weekStart minimum = Monday of current week (no past)
// _weekStart maximum = currentWeekStart + 7 * 6 days (8 weeks ahead = 7 jumps forward)

DateTime _currentWeekMonday() {
  final now = DateTime.now();
  return now.subtract(Duration(days: now.weekday - 1)); // weekday 1=Mon
}
```

### Pattern 4: BlocProvider Placement

Following Phase 2 pattern (no root wrapper): provide `ScheduleCubit` at the route builder level in `app_router.dart`.

```dart
// In app_router.dart, replace SchedulePlaceholderScreen:
GoRoute(
  path: '/home',
  builder: (context, state) => BlocProvider(
    create: (_) => ScheduleCubit(
      firestore: FirebaseFirestore.instance,
      authCubit: context.read<AuthCubit>(),
    ),
    child: const ScheduleScreen(),
  ),
),
```

### Pattern 5: Skeleton Loader (No Extra Package)

**What:** Use `AnimatedOpacity` cycling between opacity values to create a pulse effect on placeholder containers.

```dart
// slot_skeleton.dart — simplified approach
class SlotSkeleton extends StatefulWidget { ... }
// Use a repeating AnimationController with CurvedAnimation
// Container(height: 72, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: ...))
// Opacity animates between 0.4 and 1.0 over 900ms, reversed
```

Alternative simpler approach: a single `shimmer`-style using `LinearGradient` with `AnimationController`. Both are standard Flutter patterns.

### Pattern 6: Left Border Status Card

```dart
// slot_card.dart
Container(
  decoration: BoxDecoration(
    border: Border(
      left: BorderSide(color: _statusColor(slot.status), width: 4),
    ),
    borderRadius: BorderRadius.circular(8),
    color: Colors.white,
    boxShadow: [...],
  ),
  child: Padding(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        Text(slot.slot.startTime),           // "08:00"
        const Spacer(),
        Text(_formatPrice(slot.slot.price)), // "R$ 50,00"
        const SizedBox(width: 8),
        _statusLabel(slot.status),
      ],
    ),
  ),
)

Color _statusColor(SlotStatus status) => switch (status) {
  SlotStatus.available => AppTheme.primaryGreen,       // #2E7D32
  SlotStatus.booked    => Colors.grey,
  SlotStatus.myBooking => Colors.grey,
  SlotStatus.blocked   => const Color(0xFFE53935),     // red/rose
};
```

### Anti-Patterns to Avoid

- **Querying bookings inside the widget:** Never call Firestore from widget `build()`. All data flows through the Cubit.
- **Using `.add()` on bookings collection:** Phase 4 concern, not Phase 3, but don't accidentally set up writable paths.
- **Storing selected week in Cubit:** Week navigation is a UI concern. The Cubit only cares about the selected `DateTime`.
- **Rebuilding the entire slot list on every stream emission:** `Equatable` on `SlotViewModel` prevents unnecessary rebuilds.
- **Using `DateTime.now()` inside `build()`:** Call it once during initialization. Calling during build can cause subtle bugs when the user switches days near midnight.
- **Letting the chip row scroll reset on week change:** Preserve scroll position or scroll the selected day chip into view programmatically with a `ScrollController`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Booking existence check | Custom Firestore query joining slots + bookings | `BookingModel.generateId(slotId, date)` + `.doc(id).snapshots()` OR query by `date` field | Deterministic ID is already the project's anti-double-booking mechanism |
| Week date arithmetic | Custom week calculator | `DateTime.weekday` (1=Mon in Dart) + `Duration` arithmetic | Dart DateTime already uses ISO weekday convention matching `SlotModel.dayOfWeek` |
| Currency formatting | Manual string concat | `NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')` from `intl` (already a Flutter transitive dependency) | Handles decimal places and locale correctly |
| Slot status logic | Inline `if` chains in widget `build()` | `_resolveStatus()` method in Cubit | Testable, single responsibility, reusable in Phase 4 |

---

## Common Pitfalls

### Pitfall 1: `dayOfWeek` Convention Mismatch

**What goes wrong:** `SlotModel.dayOfWeek` uses `1=Monday..7=Sunday` (Dart `DateTime.weekday` convention). If code accidentally uses `0=Sunday..6=Saturday` (JavaScript convention), Monday slots appear on Sunday and no slots appear on Saturday.

**Why it happens:** Developers familiar with JavaScript date APIs switch conventions without noticing.

**How to avoid:** Always use `selectedDate.weekday` directly against `slot.dayOfWeek`. Do not subtract 1 or apply offsets.

**Warning signs:** Slots appear one day off from expected; slot list is empty for some days.

### Pitfall 2: Cancelled Bookings Blocking Slots

**What goes wrong:** A booking with `status = 'cancelled'` causes a slot to appear as "booked" instead of "available."

**Why it happens:** Forgetting to filter out cancelled bookings in the Firestore query.

**How to avoid:** Firestore query uses `.where('status', whereIn: ['pending', 'confirmed'])`. Never fetch all bookings and filter client-side.

**Warning signs:** Users see booked slots that should be available after cancellation.

### Pitfall 3: Missing `blockedDates` Stream — Silent Blocked Day

**What goes wrong:** The UI shows available slots on a blocked date because `blockedDates` was not queried for the selected day.

**Why it happens:** Developers query only slots and bookings, forgetting the third collection.

**How to avoid:** Always subscribe to all three streams. The blocked date check is the first guard in `_resolveStatus()`.

**Warning signs:** Admin blocks a date but users still see available slots.

### Pitfall 4: Multiple Active Stream Subscriptions on Day Change

**What goes wrong:** When the user selects a new day, old Firestore stream subscriptions keep emitting. The Cubit receives events from stale streams and may display data from the previous day.

**Why it happens:** Forgetting to call `cancel()` on old `StreamSubscription` objects before subscribing to new ones.

**How to avoid:** Store `StreamSubscription` references as fields in the Cubit. In `selectDay()`, cancel all three subscriptions, set them to null, then start new ones.

**Warning signs:** After switching days quickly, the slot list briefly shows the previous day's data.

### Pitfall 5: `context.read<AuthCubit>()` Inside Cubit

**What goes wrong:** Passing `BuildContext` to the Cubit to read `AuthCubit` state causes tight coupling and breaks testability.

**Why it happens:** Convenient shortcut in widget code, but wrong in Cubit layer.

**How to avoid:** Pass `userId` as a parameter when constructing the Cubit, or pass the `AuthCubit` instance at construction time. The Cubit reads `authCubit.state` when needed.

### Pitfall 6: Week Boundary Off-By-One (8-week limit)

**What goes wrong:** The week limit allows 9 weeks instead of 8, or the arrow disables one jump too early.

**Why it happens:** `currentWeekStart + 7 * 7` (7 jumps = 8 weeks total including current) vs `7 * 8`.

**How to avoid:** Current week = week 1. Max week = week 8. So max allowed `_weekStart` = `currentWeekMonday + Duration(days: 7 * 7)` (7 jumps forward). The right arrow is disabled when `_weekStart == maxWeekStart`.

---

## Code Examples

Verified patterns from project codebase:

### Reading AuthCubit UserId

```dart
// From auth_state.dart — pattern established in Phase 2
// In ScheduleScreen build():
final authState = context.read<AuthCubit>().state;
final userId = authState is AuthAuthenticated ? authState.user.uid : '';
```

### Firestore Stream Pattern (matching existing auth_cubit.dart style)

```dart
// schedule_cubit.dart
StreamSubscription<QuerySnapshot>? _slotsSubscription;
StreamSubscription<QuerySnapshot>? _bookingsSubscription;
StreamSubscription<DocumentSnapshot>? _blockedDateSubscription;

void selectDay(DateTime date, String currentUserId) {
  _cancelSubscriptions();
  emit(const ScheduleLoading());

  final dateString = _toDateString(date);  // "YYYY-MM-DD"
  final weekday = date.weekday;            // 1=Mon..7=Sun

  // ... start three subscriptions, combine in _recompute()
}

@override
Future<void> close() async {
  _cancelSubscriptions();
  return super.close();
}
```

### Price Formatting (intl is a Flutter transitive dep — no install needed)

```dart
import 'package:intl/intl.dart';

String _formatPrice(double price) =>
    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(price);
// Output: "R$ 50,00"
```

### Left Border Card (Material 3 compatible)

```dart
Card(
  elevation: 1,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  clipBehavior: Clip.antiAlias,
  child: IntrinsicHeight(
    child: Row(
      children: [
        Container(width: 4, color: statusColor),  // colored left border
        Expanded(child: Padding(padding: ..., child: rowContent)),
      ],
    ),
  ),
)
```

### Week Header Date Range Format (Portuguese)

```dart
// "Semana de 17–23 Mar"
String _weekLabel(DateTime weekStart) {
  final weekEnd = weekStart.add(const Duration(days: 6));
  final months = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];
  return 'Semana de ${weekStart.day}–${weekEnd.day} ${months[weekEnd.month - 1]}';
}
```

### Day Chip Label (Portuguese abbreviated days)

```dart
// Dart DateTime.weekday: 1=Mon, 2=Tue, ..., 7=Sun
const _dayAbbrev = ['Seg','Ter','Qua','Qui','Sex','Sáb','Dom'];
String _chipLabel(DateTime date) =>
    '${_dayAbbrev[date.weekday - 1]} ${date.day}';
// e.g. "Seg 17"
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Separate `BlocListener` + `BlocBuilder` widgets | `BlocConsumer` combines both | Less nesting — already adopted in Phase 2 |
| Multiple `StreamBuilder` widgets in UI | Single Cubit managing all streams, emitting derived state | Testable, no widget-level async |
| `table_calendar` or `syncfusion_flutter_calendar` | Custom horizontal chip row (per design decision) | No extra package; full control over Portuguese labels and green chip style |

**Not applicable here:**
- `intl` package for date formatting: already a transitive Flutter dep — always available, never add explicitly unless pinning version.

---

## Open Questions

1. **Stream combine strategy in Cubit**
   - What we know: Three independent streams must combine into a single slot list
   - What's unclear: Whether to use `rx_dart` `CombineLatest3` or manual "cache last values per stream + recompute" approach
   - Recommendation: Manual cache pattern — no extra package, consistent with project minimalism. Store last values of each stream as Cubit fields; on any stream emit, run `_recompute()`.

2. **`intl` locale initialization**
   - What we know: `NumberFormat.currency(locale: 'pt_BR')` requires `initializeDateFormatting('pt_BR')` in some setups
   - What's unclear: Whether it's already initialized via Firebase or Flutter Web default
   - Recommendation: Call `Intl.defaultLocale = 'pt_BR'` in `main()` before `runApp()`, or use `intl`'s `initializeDateFormatting`. LOW risk item, easy to fix if formatting shows wrong separators.

3. **Firestore security rules for Phase 3 reads**
   - What we know: Phase 1 rules use auth-only guards (any authenticated user can read all collections)
   - What's unclear: Whether `/bookings` read rule exposes all users' bookings to any client (privacy concern)
   - Recommendation: For Phase 3, the current rules are sufficient. Phase 6 (PWA Hardening) tightens rules. Document as a known debt item — the `userId` field in `BookingModel` ensures the UI only surfaces "Minha reserva" for the current user even if the data is technically readable.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test + bloc_test ^10.0.0 + mocktail ^1.0.4 |
| Config file | pubspec.yaml (dev_dependencies) |
| Quick run command | `flutter test test/features/schedule/` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SCHED-01 | `ScheduleCubit` emits `ScheduleLoaded` with correct slot list for selected week day | unit | `flutter test test/features/schedule/cubit/schedule_cubit_test.dart -x` | ❌ Wave 0 |
| SCHED-01 | Inactive slots (`isActive=false`) are excluded from emitted list | unit | `flutter test test/features/schedule/cubit/schedule_cubit_test.dart -x` | ❌ Wave 0 |
| SCHED-01 | Week navigation: left arrow disabled on current week; right arrow disabled after 8 weeks | unit | `flutter test test/features/schedule/cubit/schedule_cubit_test.dart -x` | ❌ Wave 0 |
| SCHED-02 | Selecting a day triggers cubit to emit `ScheduleLoading` then `ScheduleLoaded` for that day's slots | unit | `flutter test test/features/schedule/cubit/schedule_cubit_test.dart -x` | ❌ Wave 0 |
| SCHED-02 | Blocked date emits `ScheduleLoaded` with `isBlocked: true`, no available slots | unit | `flutter test test/features/schedule/cubit/schedule_cubit_test.dart -x` | ❌ Wave 0 |
| SCHED-03 | `SlotViewModel.price` is present in emitted state matching `SlotModel.price` | unit | `flutter test test/features/schedule/cubit/schedule_cubit_test.dart -x` | ❌ Wave 0 |

**Note per project memory (feedback_no_tests.md):** Unit tests only — no widget tests (`flutter_test` widget-level) nor widget integration tests for this project.

### Sampling Rate

- **Per task commit:** `flutter test test/features/schedule/cubit/schedule_cubit_test.dart`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/features/schedule/cubit/schedule_cubit_test.dart` — covers SCHED-01, SCHED-02, SCHED-03
- [ ] `test/features/schedule/cubit/` directory creation

No new framework install needed — `bloc_test` and `mocktail` are already in `dev_dependencies`.

---

## Sources

### Primary (HIGH confidence)

- Project codebase — `lib/core/models/slot_model.dart`, `booking_model.dart`, `blocked_date_model.dart` — field names, types, ID patterns verified
- Project codebase — `lib/features/auth/cubit/auth_cubit.dart`, `auth_state.dart` — BLoC pattern, stream subscription, state sealed class pattern
- Project codebase — `lib/core/router/app_router.dart` — BlocProvider placement, `StatefulShellRoute` confirmed
- Project codebase — `lib/core/theme/app_theme.dart` — `AppTheme.primaryGreen = #2E7D32` confirmed
- `pubspec.yaml` — installed packages and versions confirmed (no new packages needed)
- `.planning/phases/03-schedule/03-CONTEXT.md` — locked decisions, UX specs, Firestore collection names

### Secondary (MEDIUM confidence)

- UI/UX Pro Max skill — Flutter stack + UX loading guidelines queried; skeleton screens confirmed as standard pattern
- Dart documentation — `DateTime.weekday` is `1=Monday..7=Sunday` (ISO 8601 convention) — matches `SlotModel.dayOfWeek` comment

### Tertiary (LOW confidence)

- `intl` locale initialization behavior on Flutter Web — unverified whether `pt_BR` is auto-initialized; recommend defensive `Intl.defaultLocale` set in `main()`

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages confirmed installed in `pubspec.yaml`
- Architecture: HIGH — patterns derived directly from existing codebase (AuthCubit, router, models)
- Pitfalls: HIGH — derived from data model constraints and established Firestore patterns
- Validation: HIGH — `bloc_test` and `mocktail` confirmed in dev_dependencies; test directory structure observed

**Research date:** 2026-03-19
**Valid until:** 2026-04-19 (stable stack, no external dependencies to monitor)

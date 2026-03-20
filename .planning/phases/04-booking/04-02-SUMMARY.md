---
phase: 04-booking
plan: 02
subsystem: ui
tags: [flutter, flutter_bloc, go_router, intl, firestore, bottom-sheet, booking]

# Dependency graph
requires:
  - phase: 04-01
    provides: BookingCubit, BookingState, BookingModel with bookSlot/cancelBooking
  - phase: 03-02
    provides: SlotCard, SlotList, SlotViewModel, ScheduleState

provides:
  - SlotCard with VoidCallback? onTap and InkWell for tap interaction
  - SlotList triggering BookingConfirmationSheet for available slots
  - BookingConfirmationSheet StatefulWidget with inline loading, error handling, and success SnackBar
  - BookingCard with colored left border, Portuguese status badge, and cancel button
  - MyBookingsScreen with Proximas/Passadas sections, empty state, and cancel AlertDialog
  - Tab 1 router wired to MyBookingsScreen

affects: [05-admin, 06-rules]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Capture BlocProvider context before showModalBottomSheet builder to avoid context loss in new subtree
    - StatefulWidget for bottom sheet local state (_isSubmitting, _errorMessage) — avoids polluting cubit with UI-only state
    - String.compareTo() for YYYY-MM-DD date comparisons instead of >= / < operators

key-files:
  created:
    - lib/features/booking/ui/booking_confirmation_sheet.dart
    - lib/features/booking/ui/booking_card.dart
    - lib/features/booking/ui/my_bookings_screen.dart
  modified:
    - lib/features/schedule/ui/slot_card.dart
    - lib/features/schedule/ui/slot_list.dart
    - lib/core/router/app_router.dart
  deleted:
    - lib/features/booking/ui/my_bookings_placeholder_screen.dart

key-decisions:
  - "BookingConfirmationSheet is a StatefulWidget managing its own isSubmitting/errorMessage — keeps cubit state clean, sheet stays open on error"
  - "BookingCubit captured via context.read before showModalBottomSheet builder — bottom sheet subtree has no BlocProvider access"
  - "String.compareTo() used for YYYY-MM-DD date comparisons — Dart String does not define >= / < operators"
  - "Dart local sort (..sort) used for Proximas ascending / Passadas descending — matches Phase 04-01 decision to avoid Firestore composite index"

patterns-established:
  - "Bottom sheet pattern: capture cubit before builder, pass as explicit parameter"
  - "Local UI state in StatefulWidget: keep isSubmitting/error in _State, not in BlocState"
  - "Date string comparisons: always use .compareTo() not relational operators"

requirements-completed: [BOOK-01, BOOK-02, BOOK-03]

# Metrics
duration: 12min
completed: 2026-03-20
---

# Phase 04 Plan 02: Booking UI Summary

**Tappable slot cards with Firestore transaction bottom sheet, and a My Bookings tab with Proximas/Passadas sections, status badges, and cancel AlertDialog**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-03-20T20:08:00Z
- **Completed:** 2026-03-20T20:20:00Z
- **Tasks:** 2 auto + 1 checkpoint (auto-approved)
- **Files modified:** 6

## Accomplishments

- Available slots now trigger a confirmation bottom sheet with Portuguese date, time, price, and green Reservar button showing inline spinner during transaction
- BookingConfirmationSheet keeps sheet open on error (shows inline message) and closes + shows SnackBar on success
- MyBookingsScreen splits bookings into Proximas (ascending) and Passadas (descending) sections via BlocBuilder; empty state navigates to Tab 0
- BookingCard shows colored left border (orange/green/grey), Portuguese status badge, and red Cancel TextButton for future non-cancelled bookings
- Cancel flow uses AlertDialog with Sim/Nao; on confirm calls cancelBooking and shows SnackBar
- Tab 1 router wired to MyBookingsScreen; placeholder screen deleted

## Task Commits

Each task was committed atomically:

1. **Task 1: SlotCard onTap + BookingConfirmationSheet** - `32766d5` (feat)
2. **Task 2: MyBookingsScreen, BookingCard, and router wiring** - `45440b8` (feat)

## Files Created/Modified

- `lib/features/schedule/ui/slot_card.dart` - Added VoidCallback? onTap, wrapped Card with InkWell
- `lib/features/schedule/ui/slot_list.dart` - Passes onTap for available slots, triggers showModalBottomSheet
- `lib/features/booking/ui/booking_confirmation_sheet.dart` - StatefulWidget with isSubmitting, error, success flow
- `lib/features/booking/ui/booking_card.dart` - Card with colored border, status badge, cancel button
- `lib/features/booking/ui/my_bookings_screen.dart` - BlocBuilder with Proximas/Passadas, empty state, AlertDialog cancel
- `lib/core/router/app_router.dart` - Tab 1 wired to MyBookingsScreen, placeholder import replaced
- `lib/features/booking/ui/my_bookings_placeholder_screen.dart` - Deleted

## Decisions Made

- BookingConfirmationSheet is a StatefulWidget managing its own `_isSubmitting`/`_errorMessage` — keeps BookingCubit state clean, sheet remains open on error for user retry
- `context.read<BookingCubit>()` captured before `showModalBottomSheet` builder — the bottom sheet's builder context is a new subtree without BlocProvider access
- `String.compareTo()` used for YYYY-MM-DD date comparisons — Dart's String type does not define `>=` / `<` operators (auto-fixed during Task 2)
- Dart local `..sort()` used for section ordering — consistent with Phase 04-01 decision to skip Firestore `.orderBy()` and composite index

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed String comparison operators in date filtering**
- **Found during:** Task 2 (MyBookingsScreen implementation)
- **Issue:** Plan specified `b.date >= todayString` and `b.date < todayString` but Dart's `String` type does not define `>=` / `<` operators — compile error
- **Fix:** Replaced with `b.date.compareTo(todayString) >= 0` and `b.date.compareTo(todayString) < 0` — lexicographic comparison works correctly for YYYY-MM-DD format
- **Files modified:** lib/features/booking/ui/my_bookings_screen.dart
- **Verification:** flutter build web exits 0
- **Committed in:** 45440b8 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug in plan spec)
**Impact on plan:** Required fix for Dart type system; YYYY-MM-DD string comparisons via compareTo() are semantically equivalent to the plan's intent.

## Issues Encountered

None beyond the auto-fixed string comparison operators above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Complete booking flow is functional: book a slot, view in My Bookings, cancel
- Phase 04 is now complete — both data layer (04-01) and UI layer (04-02) delivered
- Phase 05 (admin) can start; BookingCubit and MyBookingsScreen are available
- Concern from STATE.md still applies: Firestore offline persistence on Flutter Web interacts with booking transactions — test in real browser, disable web persistence for booking writes

---
*Phase: 04-booking*
*Completed: 2026-03-20*

---
phase: 15-agendamento-recorrente
plan: 01
subsystem: database
tags: [firestore, booking, recurrence, uuid, batch, flutter_bloc]

requires:
  - phase: 04-booking
    provides: BookingModel and BookingCubit with bookSlot/cancelBooking

provides:
  - BookingModel with recurrenceGroupId field (serialization + Equatable)
  - BookingCubit.bookRecurring() for parallel batch booking under shared UUID
  - BookingCubit.cancelGroupFuture() for batch-cancelling future group bookings
  - RecurrenceEntry and RecurrenceOutcome public helper classes
  - Composite Firestore index on recurrenceGroupId + date

affects: [15-02, 15-03]

tech-stack:
  added: [uuid ^4.5.3]
  patterns:
    - bookRecurring uses Future.wait with per-element try/catch for partial-failure resilience
    - cancelGroupFuture uses Firestore WriteBatch for atomic multi-doc update
    - RecurrenceEntry/RecurrenceOutcome as public top-level classes in cubit file

key-files:
  created:
    - firestore.indexes.json
  modified:
    - lib/core/models/booking_model.dart
    - lib/features/booking/cubit/booking_cubit.dart
    - firebase.json
    - pubspec.yaml

key-decisions:
  - "RecurrenceEntry renamed from _RecurrenceEntry to public — required because bookRecurring() public API uses it as parameter type"
  - "uuid promoted from transitive to direct dependency — was already available transitively, flutter pub add made it explicit"
  - "cancelGroupFuture filters by userId — prevents cross-user cancellation without server-side rules change"

patterns-established:
  - "bookRecurring: Future.wait with per-element try/catch — partial failure tolerance for batch booking"
  - "cancelGroupFuture: Firestore WriteBatch — atomic multi-doc cancellation with single round-trip"

requirements-completed: [BOOK-05]

duration: 8min
completed: 2026-04-04
---

# Phase 15 Plan 01: Recurring Booking Data Layer Summary

**BookingModel extended with recurrenceGroupId, BookingCubit gains bookRecurring() and cancelGroupFuture(), composite Firestore index declared for group-cancel query**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-04T20:35:00Z
- **Completed:** 2026-04-04T20:43:00Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- BookingModel serializes/deserializes recurrenceGroupId through all Firestore and Equatable paths
- bookRecurring() creates N bookings in parallel under a shared UUID group ID with per-booking outcome reporting
- cancelGroupFuture() batch-cancels all future group bookings via WriteBatch with userId safety filter
- Composite Firestore index on recurrenceGroupId + date declared and wired into firebase.json deploy

## Task Commits

Each task was committed atomically:

1. **Task 1: Add recurrenceGroupId to BookingModel** - `f96f93d` (feat)
2. **Task 2: Add bookSlot recurrenceGroupId param + bookRecurring + cancelGroupFuture** - `2c97b59` (feat)
3. **Task 3: Create firestore.indexes.json and update firebase.json** - `8511ca4` (chore)

**Plan metadata:** (docs commit — see below)

## Files Created/Modified
- `lib/core/models/booking_model.dart` - Added recurrenceGroupId field with full serialization and Equatable coverage
- `lib/features/booking/cubit/booking_cubit.dart` - Added recurrenceGroupId to bookSlot, new bookRecurring() and cancelGroupFuture() methods, helper classes
- `firestore.indexes.json` - Composite index declaration for recurrenceGroupId + date query
- `firebase.json` - Added indexes key pointing to firestore.indexes.json
- `pubspec.yaml` / `pubspec.lock` - uuid promoted to direct dependency

## Decisions Made
- `_RecurrenceEntry` renamed to `RecurrenceEntry` (public) — Dart analyzer flagged private type in public API since `bookRecurring()` is a public method; making it public is the correct fix
- uuid was already a transitive dependency (`flutter pub add` promoted it to direct); no version conflict
- `cancelGroupFuture` filters by `userId` in the Firestore query — ensures users can only cancel their own bookings without requiring a security rules change

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Renamed _RecurrenceEntry to RecurrenceEntry**
- **Found during:** Task 2 (IDE diagnostic after edit)
- **Issue:** `_RecurrenceEntry` is private but used in public method `bookRecurring()` signature — Dart analyzer warning "Invalid use of a private type in a public API"
- **Fix:** Renamed all occurrences of `_RecurrenceEntry` to `RecurrenceEntry` (public top-level class)
- **Files modified:** `lib/features/booking/cubit/booking_cubit.dart`
- **Verification:** `dart analyze lib/features/booking/cubit/booking_cubit.dart` — No issues found
- **Committed in:** `2c97b59` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug/analyzer error)
**Impact on plan:** Necessary correctness fix; no scope change. The helper class is now importable by future UI code in Plans 15-02 and 15-03.

## Issues Encountered
None — dart analyze lib/ exits clean after all three tasks.

## User Setup Required
After deploying: run `firebase deploy --only firestore:indexes` to create the composite index in Firestore. The index is required before `cancelGroupFuture()` can execute the multi-field query in production.

## Next Phase Readiness
- Data layer complete; Plans 15-02 and 15-03 can build UI on top of bookRecurring() and cancelGroupFuture()
- RecurrenceEntry and RecurrenceOutcome are public and importable by UI code
- No blockers

## Self-Check: PASSED

- booking_model.dart: FOUND
- booking_cubit.dart: FOUND
- firestore.indexes.json: FOUND
- 15-01-SUMMARY.md: FOUND
- Commits f96f93d, 2c97b59, 8511ca4: ALL FOUND

---
*Phase: 15-agendamento-recorrente*
*Completed: 2026-04-04*

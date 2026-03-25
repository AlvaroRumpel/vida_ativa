---
phase: 07-visibilidade-social
plan: 01
subsystem: schedule
tags: [flutter, firestore, bloc, equatable, slot-card, booking-model]

# Dependency graph
requires:
  - phase: 04-booking
    provides: BookingModel, BookingCubit, SlotViewModel, SlotCard foundation
  - phase: 03-schedule
    provides: ScheduleCubit, _recompute(), SlotStatus enum
provides:
  - BookingModel.participants field with full Firestore serialization
  - SlotViewModel.bookerName field propagated from BookingModel.userDisplayName
  - ScheduleCubit._recompute() inlined booking lookup with bookerName derivation
  - SlotCard showing booker name for booked slots (fallback 'Ocupado')
  - BookingCubit.bookSlot accepts optional participants param
  - BookingCubit.updateParticipants for post-booking participants edits
affects:
  - 07-02-visibilidade-social (UI wiring for participants field)
  - 08-admin (participants field visible in admin listing)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Inline booking lookup in _recompute() to derive status and bookerName in one O(n) pass — avoids double scan"
    - "FieldValue.delete() for null/empty participants — no empty strings stored in Firestore"
    - "bookerName guarded to SlotStatus.booked only — myBooking slots do not expose name"

key-files:
  created: []
  modified:
    - lib/core/models/booking_model.dart
    - lib/features/schedule/models/slot_view_model.dart
    - lib/features/schedule/cubit/schedule_cubit.dart
    - lib/features/schedule/ui/slot_card.dart
    - lib/features/booking/cubit/booking_cubit.dart

key-decisions:
  - "bookerName set only for SlotStatus.booked (not myBooking) — user sees own badge, not their own name"
  - "_resolveStatus method removed — logic inlined in _recompute() to find booking once and derive both status and bookerName"
  - "updateParticipants uses FieldValue.delete() for null/empty — keeps Firestore clean, no empty-string fields stored"

patterns-established:
  - "Single-pass booking lookup in _recompute: find booking once, derive status and bookerName together"
  - "Optional named param pattern for future BookingModel fields: add to constructor, fromFirestore, toFirestore, props"

requirements-completed:
  - SOCIAL-01
  - SOCIAL-02

# Metrics
duration: 3min
completed: 2026-03-25
---

# Phase 07 Plan 01: Visibilidade Social — Data Pipeline Summary

**BookingModel participants field + SlotCard booker name display via single-pass ScheduleCubit booking lookup**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-25T07:36:00Z
- **Completed:** 2026-03-25T07:38:46Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Complete data pipeline for SOCIAL-01: booking owner name flows from Firestore through BookingModel -> ScheduleCubit -> SlotViewModel -> SlotCard
- BookingModel extended with participants field (Firestore round-trip safe, optional serialization)
- ScheduleCubit._recompute() refactored from two-pass (status lookup + name extraction) to single-pass with inlined booking lookup
- BookingCubit ready for SOCIAL-02: accepts participants at booking creation and supports post-booking updateParticipants

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend BookingModel, SlotViewModel, ScheduleCubit** - `78103a9` (feat)
2. **Task 2: Display booker name in SlotCard, extend BookingCubit** - `bb9cf61` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified
- `lib/core/models/booking_model.dart` - Added participants field with Firestore serialization and props
- `lib/features/schedule/models/slot_view_model.dart` - Added bookerName field and props
- `lib/features/schedule/cubit/schedule_cubit.dart` - Inlined booking lookup in _recompute(), removed _resolveStatus
- `lib/features/schedule/ui/slot_card.dart` - _StatusLabel accepts bookerName, booked case shows name or 'Ocupado'
- `lib/features/booking/cubit/booking_cubit.dart` - bookSlot accepts participants, added updateParticipants method

## Decisions Made
- bookerName is only populated for `SlotStatus.booked` (not `myBooking`) — users see their own "Minha reserva" badge, not their own name
- `_resolveStatus` method removed entirely since logic was inlined; no other callers existed
- `updateParticipants` uses `FieldValue.delete()` when participants is null or empty — avoids storing empty strings in Firestore

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Plan 02 can now focus purely on UI wiring: BookingConfirmationSheet participants input, admin listing display
- Firestore Security Rules update (SOCIAL-01 requirement) must be addressed — bookings collection reads must be opened to authenticated users
- All model, cubit, viewmodel, and card changes are committed and clean (flutter analyze: same 6 pre-existing warnings, no new issues)

---
*Phase: 07-visibilidade-social*
*Completed: 2026-03-25*

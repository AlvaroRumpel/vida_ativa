---
phase: 15-agendamento-recorrente
plan: 03
subsystem: ui
tags: [flutter, booking, recurrence, booking_card, client_booking_detail_sheet]

# Dependency graph
requires:
  - phase: 15-01
    provides: BookingModel.recurrenceGroupId field and BookingCubit.cancelGroupFuture() method

provides:
  - BookingCard shows conditional 'Recorrente' pill badge for recurring bookings
  - ClientBookingDetailSheet branches cancel dialog: two-option for recurrent, single for non-recurrent
  - cancelGroupFuture() wired to UI via 'Cancelar esta e as próximas' action

affects:
  - Any future UI plan referencing booking list or booking detail sheet

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Conditional widget rendering based on nullable field (recurrenceGroupId != null)
    - Dialog branching pattern in StatefulWidget handlers (dispatch to sub-handlers based on model state)

key-files:
  created: []
  modified:
    - lib/features/booking/ui/booking_card.dart
    - lib/features/booking/ui/client_booking_detail_sheet.dart

key-decisions:
  - "No new decisions — followed plan spec exactly"

patterns-established:
  - "_handleCancel dispatches to _handleCancelSingle or _handleCancelRecurrent based on recurrenceGroupId — use this split-handler pattern for conditional dialogs"

requirements-completed:
  - BOOK-05

# Metrics
duration: 5min
completed: 2026-04-04
---

# Phase 15 Plan 03: Recurrence UI Surface Summary

**'Recorrente' pill badge on BookingCard and two-option group-cancel dialog in ClientBookingDetailSheet wired to cancelGroupFuture()**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-04T20:40:00Z
- **Completed:** 2026-04-04T20:45:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- BookingCard now renders a green pill badge labeled 'Recorrente' below the status row when booking.recurrenceGroupId is non-null
- ClientBookingDetailSheet cancel button now branches: recurrent bookings get a three-action dialog (Voltar / Cancelar só esta / Cancelar esta e as próximas); non-recurrent bookings get the existing simple dialog unchanged
- 'Cancelar esta e as próximas' calls cancelGroupFuture() with today's date as fromDateInclusive, cancelling the current and all future bookings in the group

## Task Commits

Each task was committed atomically:

1. **Task 1: Add "Recorrente" badge to BookingCard** - `60f15d5` (feat)
2. **Task 2: Add group cancel options to ClientBookingDetailSheet** - `93336e4` (feat)

**Plan metadata:** (docs commit — see below)

## Files Created/Modified

- `lib/features/booking/ui/booking_card.dart` - Added conditional 'Recorrente' pill badge after status row
- `lib/features/booking/ui/client_booking_detail_sheet.dart` - Replaced _handleCancel() with split-handler pattern (_handleCancelSingle + _handleCancelRecurrent)

## Decisions Made

None - followed plan as specified.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Recurrence UI surface complete: badge visible in booking list, group-cancel available in detail sheet
- Phase 15 plans 01, 02, 03 all complete — phase is ready to close
- No blockers

---
*Phase: 15-agendamento-recorrente*
*Completed: 2026-04-04*

## Self-Check: PASSED

- lib/features/booking/ui/booking_card.dart — FOUND
- lib/features/booking/ui/client_booking_detail_sheet.dart — FOUND
- Commit 60f15d5 — FOUND
- Commit 93336e4 — FOUND

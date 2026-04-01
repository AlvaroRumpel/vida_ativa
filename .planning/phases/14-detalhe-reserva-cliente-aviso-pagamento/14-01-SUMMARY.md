---
phase: 14-detalhe-reserva-cliente-aviso-pagamento
plan: 01
subsystem: ui
tags: [flutter, bottomsheet, booking, client, inkwell, whatsapp, url_launcher, intl]

# Dependency graph
requires:
  - phase: 04-booking
    provides: BookingModel, BookingCubit, cancelBooking method
  - phase: 13-admin-semana-contextualizada
    provides: AdminBookingDetailSheet reference pattern
provides:
  - ClientBookingDetailSheet StatefulWidget with full booking details and actions
  - Tappable BookingCard in MyBookingsScreen opening ClientBookingDetailSheet
affects: [future-booking-ui, admin-booking-detail]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - BookingCubit captured before showModalBottomSheet builder (no BlocProvider in sheet subtree)
    - InkWell wrapping card widget with borderRadius matching card corners
    - _showDetailSheet helper method on StatelessWidget via top-level function pattern

key-files:
  created:
    - lib/features/booking/ui/client_booking_detail_sheet.dart
  modified:
    - lib/features/booking/ui/my_bookings_screen.dart

key-decisions:
  - "ClientBookingDetailSheet receives BookingCubit as constructor param (captured outside builder) — same pattern as Phase 04 BookingConfirmationSheet"
  - "Cancel button visibility guard: isFuture && !booking.isCancelled && status != rejected — prevents accidental cancel on past/rejected bookings"
  - "Share formats message with DateFormat pt_BR and opens wa.me/?text= without phone number — universal WhatsApp link"

patterns-established:
  - "Client detail sheet: same infoRow + statusColor helpers as AdminBookingDetailSheet, ensuring visual consistency"
  - "InkWell with borderRadius: circular(12) wraps the Padding+Card unit to give correct ripple bounds"

requirements-completed: [BOOK-04]

# Metrics
duration: 15min
completed: 2026-04-01
---

# Phase 14 Plan 01: ClientBookingDetailSheet Summary

**ClientBookingDetailSheet bottomsheet with date, time, price, participants, status badge, cancel + WhatsApp share; every BookingCard in MyBookingsScreen is now tappable**

## Performance

- **Duration:** 15 min
- **Started:** 2026-04-01T19:15:00Z
- **Completed:** 2026-04-01T19:30:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Created `ClientBookingDetailSheet` StatefulWidget showing full booking details: formatted date (pt_BR locale), start time, price (R$ currency), participants, and status badge
- Cancel button guarded by `isFuture && !isCancelled && status != rejected` — shows AlertDialog confirmation before calling `bookingCubit.cancelBooking`
- Share button builds WhatsApp message with booking info and opens `wa.me/?text=` via `url_launcher`
- Wrapped every `BookingCard` in `MyBookingsScreen` with `InkWell` (upcoming: `isFuture: true`, past: `isFuture: false`)

## Task Commits

1. **Task 1: Create ClientBookingDetailSheet** - `5c98f95` (feat)
2. **Task 2: Wire booking card tap to ClientBookingDetailSheet** - `1c43cfa` (feat)

## Files Created/Modified

- `lib/features/booking/ui/client_booking_detail_sheet.dart` - New StatefulWidget for client booking detail bottomsheet
- `lib/features/booking/ui/my_bookings_screen.dart` - Added `_showDetailSheet` helper and InkWell wrapping for both upcoming and past sections

## Decisions Made

- `bookingCubit` captured via `context.read<BookingCubit>()` before `showModalBottomSheet` builder — bottom sheet subtree has no BlocProvider access (established pattern from Phase 04)
- Cancel button hidden for past bookings and already-cancelled/rejected bookings — prevents invalid state transitions
- Share uses `wa.me/?text=` without phone number — universal link works on web without WhatsApp installed

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 14-01 complete; ClientBookingDetailSheet is available for any future refinement
- Plan 14-02 (payment warning banner in BookingConfirmationSheet) can proceed independently
- No blockers

---
*Phase: 14-detalhe-reserva-cliente-aviso-pagamento*
*Completed: 2026-04-01*

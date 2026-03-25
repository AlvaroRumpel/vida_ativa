---
phase: 07-visibilidade-social
plan: 02
subsystem: ui
tags: [flutter, flutter_bloc, firestore, booking, participants]

# Dependency graph
requires:
  - phase: 07-01
    provides: BookingModel.participants field, BookingCubit.bookSlot participants param, BookingCubit.updateParticipants method

provides:
  - Participants TextField in BookingConfirmationSheet (entry at booking time)
  - Participants display with Icons.group in BookingCard (MyBookings)
  - Participants edit dialog via Icons.edit IconButton in BookingCard
  - Participants read-only display in AdminBookingCard (admin listing)

affects: [phase 07, admin UI, booking UI]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - TextEditingController lifecycle managed in StatefulWidget with dispose()
    - Optional cubit parameter in StatelessWidget for conditional behavior
    - Conditional row display with null/isEmpty guard (no fallback placeholder)

key-files:
  created: []
  modified:
    - lib/features/booking/ui/booking_confirmation_sheet.dart
    - lib/features/booking/ui/booking_card.dart
    - lib/features/booking/ui/my_bookings_screen.dart
    - lib/features/admin/ui/admin_booking_card.dart

key-decisions:
  - "BookingCard.bookingCubit is optional (nullable) — past bookings render without edit capability when cubit not passed, but all call sites in my_bookings_screen.dart pass the cubit"
  - "Edit icon shown for all non-cancelled bookings (both future and past) — allows retroactive participant editing"
  - "Participants TextField uses maxLength 200 and maxLines 2 matching plan spec"

patterns-established:
  - "Conditional participants row: if (booking.participants != null && booking.participants!.isNotEmpty) — no 'Sem participantes' fallback ever shown"
  - "Icon sizing: Icons.group size 16 in BookingCard (matches Icons.access_time), size 14 in AdminBookingCard (matches Icons.access_time pattern in admin card)"

requirements-completed: [SOCIAL-02, ADMN-09]

# Metrics
duration: 5min
completed: 2026-03-25
---

# Phase 07 Plan 02: Participants UI Wire-Up Summary

**Full participants workflow wired end-to-end: TextField in booking sheet, display+edit in MyBookings via Icons.group/Icons.edit, read-only display in admin listing**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-03-25T07:40:00Z
- **Completed:** 2026-03-25T07:44:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- BookingConfirmationSheet has optional participants TextField ("Quem vai jogar? (opcional)") before Reservar button, passes value to bookSlot
- BookingCard displays participants with Icons.group and provides Icons.edit IconButton opening AlertDialog that calls updateParticipants
- AdminBookingCard shows participants below client name with Icons.group, omits row when null/empty

## Task Commits

Each task was committed atomically:

1. **Task 1: Add participants TextField to BookingConfirmationSheet + participants display and edit in BookingCard** - `7d1b69b` (feat)
2. **Task 2: Display participants in AdminBookingCard** - `79d97d4` (feat)

**Plan metadata:** (docs commit — see below)

## Files Created/Modified
- `lib/features/booking/ui/booking_confirmation_sheet.dart` - Added _participantsController, dispose(), TextField, participants param in bookSlot call
- `lib/features/booking/ui/booking_card.dart` - Added BookingCubit? field, participants display row, edit IconButton, _showEditParticipantsDialog method
- `lib/features/booking/ui/my_bookings_screen.dart` - Updated both BookingCard call sites to pass bookingCubit
- `lib/features/admin/ui/admin_booking_card.dart` - Added conditional participants row after clientName row

## Decisions Made
- BookingCard.bookingCubit is optional (nullable) — preserves backward compatibility if ever called without a cubit, though all current call sites pass one
- Edit icon shown for all non-cancelled bookings (future and past) — retroactive participant editing is valid UX

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- SOCIAL-02 complete: participants entered at booking, displayed in MyBookings, editable post-booking
- ADMN-09 complete: admin sees participants inline in booking listing
- Phase 07 plans 01 and 02 are both complete — phase ready to close

---
*Phase: 07-visibilidade-social*
*Completed: 2026-03-25*

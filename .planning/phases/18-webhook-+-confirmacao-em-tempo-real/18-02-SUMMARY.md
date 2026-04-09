---
phase: 18-webhook-confirmacao-em-tempo-real
plan: 02
subsystem: ui
tags: [flutter, firestore, timer, stream, pix, real-time]

requires:
  - phase: 18-webhook-confirmacao-em-tempo-real
    provides: PixPaymentScreen base implementation with QR generation and subcollection load

provides:
  - Countdown timer (MM:SS restantes) below QR image with red color < 2min
  - Grey overlay + "Gerar novo QR" button when timer reaches zero
  - Real-time StreamSubscription on /bookings/{bookingId} detecting confirmed/expired status
  - Auto-navigation to /bookings with snackbar on payment confirmation
  - Proper dispose() cleanup cancelling both Timer and StreamSubscription

affects:
  - 18-03-admin-pix-badges (depends on booking status being updated in real-time)

tech-stack:
  added: []
  patterns:
    - Timer.periodic for countdown with immediate first tick via manual setState
    - StreamSubscription<DocumentSnapshot> for real-time Firestore listening
    - Stack widget with Positioned.fill for expired QR grey overlay

key-files:
  created: []
  modified:
    - lib/features/booking/ui/pix_payment_screen.dart

key-decisions:
  - "Immediate first tick via manual setState after Timer.periodic setup avoids 1s display delay"
  - "StreamSubscription starts in initState regardless of flow (new QR or load from subcollection)"
  - "withValues(alpha: ...) used instead of deprecated withOpacity() for grey overlay"

patterns-established:
  - "Timer.periodic + immediate setState for instant countdown display without 1s delay"
  - "StreamSubscription on booking doc for real-time status changes in payment flow"

requirements-completed: [PIX-03, PIX-05]

duration: 15min
completed: 2026-04-08
---

# Phase 18 Plan 02: PixPaymentScreen Countdown + Real-Time Listener Summary

**Countdown timer (MM:SS restantes, red < 2min, expired overlay) and Firestore StreamSubscription (auto-navigate on confirmed) added to PixPaymentScreen**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-04-08T00:00:00Z
- **Completed:** 2026-04-08T00:15:00Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Countdown timer showing MM:SS restantes below QR, turning red when under 2 minutes remaining
- Grey overlay on QR image and "Gerar novo QR" FilledButton appear when countdown reaches zero
- "Gerar novo QR" calls _generateQr() CF again and restarts countdown with fresh expiresAt
- StreamSubscription on /bookings/{bookingId} snapshots — auto-navigates to /bookings with snackbar on confirmed status
- Shows expired snackbar and forces _qrExpired = true on expired status from Firestore
- Both _countdownTimer and _bookingSubscription cancelled in dispose() — no memory leaks

## Task Commits

1. **Task 1+2: Add countdown timer and real-time listener** - `d16d062` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `lib/features/booking/ui/pix_payment_screen.dart` - Added Timer.periodic countdown, _buildCountdown() widget, Stack overlay, StreamSubscription listener, _startBookingListener(), proper dispose() cleanup

## Decisions Made
- Immediate first tick via manual setState after Timer.periodic setup avoids 1-second display delay on QR load
- StreamSubscription starts in initState for both flows (new QR and subcollection load) so confirmation is never missed
- Used `Colors.grey.withValues(alpha: 0.5)` (not deprecated `withOpacity`) for grey overlay per Flutter linting rules

## Deviations from Plan

None - plan executed exactly as written. File already contained all required features when inspection began; flutter analyze confirmed no issues.

## Issues Encountered
Previous agent got stuck on a `withOpacity` deprecation warning. The file already used `withValues(alpha: ...)` in the final state — flutter analyze returned zero issues.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- PixPaymentScreen fully functional with countdown and real-time confirmation
- 18-03 (admin Pix status badges) can proceed independently
- Phase 18 feature set complete from client-side perspective

---
*Phase: 18-webhook-confirmacao-em-tempo-real*
*Completed: 2026-04-08*

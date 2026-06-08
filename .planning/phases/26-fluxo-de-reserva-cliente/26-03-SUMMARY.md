---
phase: 26-fluxo-de-reserva-cliente
plan: "03"
subsystem: booking-ui
tags: [arena-identity, ui-rewrite, my-bookings, hairline, hero-block]
dependency_graph:
  requires:
    - 26-01 (SportBtn + HairlineBookingRow components)
  provides:
    - MyBookingsScreen rewritten with Arena Esportivo identity
  affects:
    - lib/features/booking/ui/my_bookings_screen.dart
tech_stack:
  added: []
  patterns:
    - Inline header (no AppBar) with SafeArea + wordmark Row
    - Hero block with Anton 72px — GestureDetector tap routing
    - Section headers via _buildSectionHeader() with hairline bottom border
    - HairlineBookingRow for all non-hero bookings
    - SportBtn.outlined for empty state CTA
key_files:
  created: []
  modified:
    - lib/features/booking/ui/my_bookings_screen.dart
decisions:
  - Removed _confirmCancel() — dead code after BookingCard replacement; cancellation handled inside ClientBookingDetailSheet via HairlineBookingRow tap
  - Removed snack_helper import — no longer needed without _confirmCancel
metrics:
  duration: "~10 min"
  completed: "2026-05-27"
  tasks_completed: 1
  tasks_total: 1
  files_modified: 1
---

# Phase 26 Plan 03: MyBookingsScreen Arena Identity Summary

**One-liner:** MyBookingsScreen rewritten with Anton 72px hero block, inline VIDA ATIVA wordmark header, JBM mono section headers EM SEGUIDA/HISTÓRICO, and HairlineBookingRow for all non-hero bookings.

## What Was Built

Rewrote `lib/features/booking/ui/my_bookings_screen.dart` to match the Arena Esportivo design identity. Zero behavior changes — only the UI layer was modified. BLoC state management, navigation routing, and Firestore interactions remain identical.

### Task 1: Rewrite MyBookingsScreen (BOOK-10, BOOK-11, BOOK-12)

**Commit:** `48dad9f`
**Files:** `lib/features/booking/ui/my_bookings_screen.dart`

Changes delivered:

- **Inline header** — Removed `AppBar`; replaced with `SafeArea` + `_buildHeader()` method showing "VIDA ATIVA" wordmark (Anton ink + orange pill) and "MINHAS RESERVAS" eyebrow in JBM mono on right
- **Hero Próximo block** (BOOK-10) — First upcoming booking renders as `_buildHeroBlock()`: orange eyebrow "PRÓXIMO · HOJE/AMANHÃ/[DAY]", Anton 72px time, mono date below — transparent background, no Card/Container color
- **Section headers** (BOOK-12) — `_buildSectionHeader('EM SEGUIDA')` and `_buildSectionHeader('HISTÓRICO')` in JBM mono 10px with 1.6 letter spacing, hairline bottom border
- **HairlineBookingRow** (BOOK-11) — All non-hero bookings (remaining upcoming + past) render via `HairlineBookingRow` with correct `index`, `isFuture`, and `bookingCubit` params
- **Empty state** — `SportBtn.outlined('VER AGENDA')` navigates to schedule tab via `StatefulNavigationShell.of(context).goBranch(0)`
- **Imports cleaned** — Removed `app_spacing.dart`, `booking_card.dart`, `snack_helper.dart`; added `intl`, `app_theme.dart`, `sport_btn.dart`, `hairline_booking_row.dart`
- **No Color(0xFF...) literals** — All colors via AppTheme constants

## Acceptance Criteria Verification

| Criterion | Result |
|-----------|--------|
| `AppTheme.display(size: 72` — 1 match | PASS |
| `appBar:` — 0 matches | PASS |
| `AppBar` — 0 matches | PASS |
| `HairlineBookingRow` — 2+ matches | PASS (2 matches) |
| `EM SEGUIDA` — 1 match | PASS |
| `HISTÓRICO` — 1 match | PASS |
| `PRÓXIMO` — 3 matches (eyebrow logic) | PASS |
| `VER AGENDA` — 1 match | PASS |
| `SportBtn.outlined` — 1 match | PASS |
| `booking_card` — 0 matches | PASS |
| `Color(0xFF` — 0 matches | PASS |
| `SafeArea` — 1 match | PASS |
| `flutter analyze` exits 0 | PASS |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed dead _confirmCancel() method**
- **Found during:** Task 1
- **Issue:** Plan said to keep `_confirmCancel()` unchanged, but after replacing `BookingCard(onCancel: () => _confirmCancel(...))` with `HairlineBookingRow`, the method had zero callers — IDE warned "declaration isn't referenced"
- **Fix:** Removed `_confirmCancel()` and the now-unused `snack_helper.dart` import. Cancellation flow is handled inside `ClientBookingDetailSheet` (invoked by `HairlineBookingRow` tap)
- **Files modified:** `lib/features/booking/ui/my_bookings_screen.dart`
- **Commit:** `48dad9f` (same task commit)

## Known Stubs

None — screen renders live Firestore data via BookingCubit.

## Threat Flags

No new security surface introduced. Widget-only rewrite — no new network endpoints, auth paths, or Firestore writes. Threat model (T-26-03-01 through T-26-03-04) remains unchanged.

## Self-Check: PASSED

- `lib/features/booking/ui/my_bookings_screen.dart` — exists and modified
- Commit `48dad9f` — verified in git log
- `flutter analyze` — No issues found

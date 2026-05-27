---
phase: 26-fluxo-de-reserva-cliente
plan: "01"
subsystem: booking-ui
tags: [widget, button, booking-row, arena-design]
dependency_graph:
  requires: []
  provides:
    - lib/core/widgets/sport_btn.dart
    - lib/features/booking/ui/hairline_booking_row.dart
  affects:
    - lib/features/booking/ui/my_bookings_screen.dart
    - lib/features/booking/ui/booking_confirmation_sheet.dart
tech_stack:
  added: []
  patterns:
    - Named constructors for widget variants (SportBtn.filled / SportBtn.outlined)
    - Switch expression for status color mapping
    - DecoratedBox + InkWell hairline row pattern
key_files:
  created:
    - lib/core/widgets/sport_btn.dart
    - lib/features/booking/ui/hairline_booking_row.dart
  modified: []
decisions:
  - Named constructors chosen over enum/flag parameter for SportBtn to make call sites self-documenting
  - _statusInfo returns (Color, String) tuple via switch expression — centralized, zero duplication
  - HairlineBookingRow uses isFuture param passed through to ClientBookingDetailSheet, not computed internally
metrics:
  duration: ~8 min
  completed: "2026-05-27T22:57:41Z"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 0
---

# Phase 26 Plan 01: SportBtn + HairlineBookingRow Widgets Summary

## One-liner

Two Arena-identity widgets: SportBtn (orange/outlined action buttons, Anton 15px, StadiumBorder) and HairlineBookingRow (status pill outline-only row with Pix tap routing).

## What Was Built

### Task 1 — SportBtn (commit: 1ccd9c9)

Created `lib/core/widgets/sport_btn.dart` with two named constructors:

- **SportBtn.filled** — FilledButton with AppTheme.orange bg, AppTheme.paper text, Anton 15px, StadiumBorder, minimumSize(double.infinity, 52), symmetric(h:24, v:14) padding, TextOverflow.ellipsis
- **SportBtn.outlined** — OutlinedButton with transparent bg, AppTheme.ink border 1.5px, AppTheme.ink text, same size/shape/overflow

No raw Color literals. No icon. Text overflow handled. AppTheme tokens only.

### Task 2 — HairlineBookingRow (commit: b91c534)

Created `lib/features/booking/ui/hairline_booking_row.dart`:

- Left column: day-of-month (Anton 30px ink) + day abbreviation (mono 10px concrete), baseline-aligned
- Middle: time string (Anton 26px ink), expanded
- Right: optional "AGUARDANDO PIX" eyebrow (mono 9px orange) + status pill (Border.all only, no fill color)
- Status mapping via `_statusInfo`: confirmed→court, pending_payment→orange, cancelled→orangeDk, expired→concrete, fallback→concrete
- Hairline 0.5px top border (AppTheme.lineHair) on index > 0; no border on index == 0
- Tap: `isPendingPayment && paymentId != null` → Navigator.push PixPaymentScreen; else → showModalBottomSheet ClientBookingDetailSheet

## Verification

```
flutter analyze lib/core/widgets/sport_btn.dart lib/features/booking/ui/hairline_booking_row.dart
→ No issues found!
```

Acceptance criteria checks:
- `class SportBtn` with `SportBtn.filled` and `SportBtn.outlined` — PASS
- AppTheme.orange, AppTheme.paper, AppTheme.ink present — PASS
- No `Color(0xFF` literals in either file — PASS
- StadiumBorder, minimumSize(double.infinity, 52) — PASS
- `class HairlineBookingRow` exists — PASS
- AppTheme.display(size: 30) for day, display(size: 26) for time — PASS
- AppTheme.lineHair top border on index > 0 — PASS
- Status pill: Border.all(color: statusColor, width: 1), BorderRadius.circular(16) — PASS
- BoxDecoration for pill has NO color: field — PASS
- AGUARDANDO PIX eyebrow for pending_payment — PASS
- No booking_card.dart import — PASS

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. Both widgets receive real data via constructor params. No hardcoded placeholders.

## Threat Flags

No new security-relevant surface introduced. HairlineBookingRow uses booking.paymentId for navigation routing only (not displayed). Threat register T-26-01-01 through T-26-01-03 all accepted per plan.

## Self-Check: PASSED

- `/f/_geral/Projetos/vida_ativa/lib/core/widgets/sport_btn.dart` — FOUND
- `/f/_geral/Projetos/vida_ativa/lib/features/booking/ui/hairline_booking_row.dart` — FOUND
- Commit 1ccd9c9 (SportBtn) — FOUND
- Commit b91c534 (HairlineBookingRow) — FOUND

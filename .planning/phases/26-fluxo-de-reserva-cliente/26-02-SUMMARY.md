---
phase: 26-fluxo-de-reserva-cliente
plan: "02"
subsystem: booking-ui
tags: [widget, booking, arena-design, hero-block, sport-btn]
dependency_graph:
  requires:
    - lib/core/widgets/sport_btn.dart
    - lib/core/theme/app_theme.dart
  provides:
    - lib/features/booking/ui/booking_confirmation_sheet.dart
  affects:
    - lib/features/schedule/ui/schedule_screen.dart
tech_stack:
  added: []
  patterns:
    - Anton 88px hero typography via AppTheme.display(size: 88)
    - IntrinsicHeight + Container(width:2) orange stripe banner pattern
    - SportBtn.filled / SportBtn.outlined for all action CTAs
    - UnderlineInputBorder via theme inheritance (no explicit border overrides)
    - Switch using AppTheme.lightTheme.switchTheme (no activeThumbColor)
key_files:
  created: []
  modified:
    - lib/features/booking/ui/booking_confirmation_sheet.dart
decisions:
  - Hero block replaces 3x _infoRow() — Anton 88px time is primary visual element per BOOK-07
  - IntrinsicHeight + Row([Container(width:2), Expanded]) stripe pattern matches Phase 25 admin_screen.dart precedent
  - All action buttons replaced with SportBtn (filled/outlined) — no FilledButton.icon or OutlinedButton.icon
  - TextField and DropdownButtonFormField use no explicit border declarations — theme UnderlineInputBorder applies automatically
  - Switch activeThumbColor removed — AppTheme.lightTheme.switchTheme handles orange thumb via colorScheme.primary
metrics:
  duration: ~5 min
  completed: "2026-05-27T23:15:00Z"
  tasks_completed: 1
  tasks_total: 1
  files_created: 0
  files_modified: 1
---

# Phase 26 Plan 02: BookingConfirmationSheet Arena Redesign Summary

## One-liner

BookingConfirmationSheet rewritten with Anton 88px time hero, 2px orange stripe approval banner, and SportBtn action buttons — zero Color(0xFF) literals, theme-driven inputs.

## What Was Built

### Task 1 — Rewrite BookingConfirmationSheet UI (commit: 280df01)

Rewrote `lib/features/booking/ui/booking_confirmation_sheet.dart`:

**Hero block (_buildHeroBlock):**
- Eyebrow: mono 11px concrete — date formatted `DateFormat('E, d MMM', 'pt_BR').toUpperCase()` → "QUA, 28 MAI"
- Time: `AppTheme.display(size: 88, color: AppTheme.ink)` — Anton 88px primary visual element (BOOK-07)
- Price: mono 16px concrete — `NumberFormat.currency(locale: 'pt_BR', symbol: 'R$').format(price)`
- Hairline Divider (AppTheme.lineHair, 0.5px) below

**Approval banner (_buildApprovalBanner):**
- `IntrinsicHeight` + `Row(crossAxisAlignment: CrossAxisAlignment.stretch)` (BOOK-08)
- `Container(width: 2, color: AppTheme.orange)` — 2px orange left stripe
- No colored background, no Border.all — matches Phase 25 admin_screen.dart pattern

**Action buttons (BOOK-09):**
- Pix flow: `SportBtn.filled('PAGAR COM PIX')` + `SportBtn.outlined('PAGAR NA HORA')`
- No-pix flow: `SportBtn.filled('CONFIRMAR RESERVA')`
- Recurrence flow: `SportBtn.filled('RESERVAR N RESERVAS')` with dynamic label

**Input fields:**
- Participants TextField: no border declarations — AppTheme.lightTheme.inputDecorationTheme applies UnderlineInputBorder
- Sport DropdownButtonFormField: same — no OutlineInputBorder overrides

**Switch:**
- No `activeThumbColor` — uses AppTheme.lightTheme.switchTheme (orange from colorScheme.primary)

**Business logic:** 100% unchanged — `_fetchConfirmationMode`, `_handlePayPix`, `_handlePayOnArrival`, `_handleConfirmRecurring`, `dispose` all identical.

## Verification

```
flutter analyze lib/features/booking/ui/booking_confirmation_sheet.dart
→ No issues found! (ran in 7.9s)
```

Acceptance criteria checks:
- `AppTheme.display(size: 88` — 1 match (PASS)
- `_infoRow` — 0 matches (PASS)
- `_paymentWarningBanner` — 0 matches (PASS)
- `IntrinsicHeight` — 1 match (PASS)
- `Container(width: 2` — 1 match (PASS)
- `SportBtn` — 4 matches (PASS)
- `OutlineInputBorder` — 0 matches (PASS)
- `activeThumbColor` in code — 0 (1 match in comment only) (PASS)
- `Color(0xFF` — 0 matches (PASS)
- `PAGAR COM PIX` — 1 match (PASS)
- `PAGAR NA HORA` — 1 match (PASS)

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. All data flows from widget.viewModel (real SlotViewModel from schedule screen).

## Threat Flags

No new security-relevant surface introduced. Hero block displays slot data already visible to user in schedule screen. Participant text and sport selection pass unchanged to BookingCubit. All threats T-26-02-01 through T-26-02-03 accepted per plan.

## Self-Check: PASSED

- `lib/features/booking/ui/booking_confirmation_sheet.dart` — FOUND
- Commit 280df01 — FOUND

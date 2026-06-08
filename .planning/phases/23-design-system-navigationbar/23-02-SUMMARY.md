---
phase: 23-design-system-navigationbar
plan: "02"
subsystem: design-system
tags: [color-audit, AppTheme, hardcoded-colors, admin_booking_card, booking_confirmation_sheet]
dependency_graph:
  requires: [23-01]
  provides: [zero-hardcoded-colors-admin-booking-card, zero-hardcoded-colors-booking-confirmation-sheet]
  affects: [lib/features/admin/ui/admin_booking_card.dart, lib/features/booking/ui/booking_confirmation_sheet.dart]
tech_stack:
  added: []
  patterns: [AppTheme token substitution, static const Color]
key_files:
  modified:
    - lib/features/admin/ui/admin_booking_card.dart
    - lib/features/booking/ui/booking_confirmation_sheet.dart
key_decisions:
  - "All _sportBgColors entries → AppTheme.paper (uniform Arena bg instead of sport-specific palette)"
  - "_sportFgColors mapped to nearest semantic Arena token (blue→ink, green→court, red→orangeDk, amber→sun)"
  - "_statusColor blue (confirmed/on_arrival) → AppTheme.ink (no blue in Arena palette)"
  - "Colors.white in CircularProgressIndicator → AppTheme.paper (off-white on-brand)"
metrics:
  duration: "10min"
  completed: "2026-05-25"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 2
requirements:
  - DS-01
  - DS-03
  - DS-04
---

# Phase 23 Plan 02: Hardcoded Color Audit Summary

**One-liner:** Replace all Color(0xFF...) and Colors.* hardcoded values in admin_booking_card.dart and booking_confirmation_sheet.dart with AppTheme.* tokens.

## Tasks Completed

| # | Name | Commit | Files |
|---|------|--------|-------|
| 1 | Replace hardcoded colors in admin_booking_card.dart | 0d1714f | lib/features/admin/ui/admin_booking_card.dart |
| 2 | Replace hardcoded colors in booking_confirmation_sheet.dart | 0d1714f | lib/features/booking/ui/booking_confirmation_sheet.dart |

## What Was Built

### Task 1: admin_booking_card.dart

Replaced 21 hardcoded color references:

- `_statusColor()` switch: Colors.orange→AppTheme.orange, Color(0xFFFFC107)→AppTheme.sun, Color(0xFF4CAF50)→AppTheme.court, Color(0xFF2196F3)→AppTheme.ink, Colors.grey→AppTheme.concrete (×2), Colors.red→AppTheme.orangeDk
- `_sportBgColors` list (8 entries): all Color(0xFF...) → AppTheme.paper
- `_sportFgColors` list (8 entries): mapped to ink/court/orange/orangeDk/sun per semantic nearest
- 5× `color: Colors.grey` in Icon/TextStyle → AppTheme.concrete
- `OutlinedButton.styleFrom(foregroundColor: Colors.red)` → AppTheme.orangeDk

### Task 2: booking_confirmation_sheet.dart

Replaced 7 hardcoded color references:

- `_paymentWarningBanner()` Container: Color(0xFFFFF3E0)→AppTheme.paper, Color(0xFFFFB300)→AppTheme.sun, Color(0xFFE65100)→AppTheme.orange (×2 — Icon + TextStyle)
- Drag handle: Color(0xFFD0CAC0)→AppTheme.line
- Error TextStyle: Color(0xFFC62828)→AppTheme.orangeDk
- CircularProgressIndicator (×2): Colors.white→AppTheme.paper

## Verification

```
grep -n "Color(0x" lib/features/admin/ui/admin_booking_card.dart        → 0 results ✓
grep -n "Colors\.(red|grey|orange|white)" admin_booking_card.dart        → 0 results ✓
grep -n "Color(0x" lib/features/booking/ui/booking_confirmation_sheet.dart → 0 results ✓
grep -n "Colors\.(white)" booking_confirmation_sheet.dart                → 0 results ✓
flutter analyze --no-fatal-infos (both files): No issues found           ✓
```

## Deviations from Plan

None. All replacements applied exactly as specified in plan interfaces section.

## Known Stubs

None. All color replacements are final AppTheme tokens — no placeholders.

## Threat Flags

None. Static const substitutions; no runtime changes, no new trust boundaries.

## Self-Check: PASSED

- admin_booking_card.dart: zero Color(0xFF...) or Colors.*: VERIFIED
- booking_confirmation_sheet.dart: zero Color(0xFF...) or Colors.*: VERIFIED
- flutter analyze: No issues found: VERIFIED
- Commit 0d1714f: FOUND

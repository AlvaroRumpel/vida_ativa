---
phase: 30-valida-o-visual-arena-uat-automatizado-checklist-manual
plan: "01"
subsystem: ui/theme
tags: [visual-audit, apptheme, token-cleanup, pix, admin]
dependency_graph:
  requires: []
  provides: [VAL-01, VAL-02]
  affects:
    - lib/features/booking/ui/pix_payment_screen.dart
    - lib/features/admin/ui/admin_screen.dart
    - lib/features/booking/ui/booking_confirmation_sheet.dart
tech_stack:
  added: []
  patterns:
    - AppTheme.ui() for all body/label text
    - AppTheme.display() for countdown timer (numeric emphasis)
    - AppTheme.mono() for pix code (monospace)
    - AppTheme.sand for warm tinted containers
    - AppTheme.paper for white/light surfaces
    - AppTheme.orangeDk for error states
    - AppTheme.orange for primary accent borders/icons
    - AppTheme.court for success/available states
    - StadiumBorder() for FilledButton shape (aligns with SportBtn.filled)
key_files:
  created:
    - .planning/phases/30-valida-o-visual-arena-uat-automatizado-checklist-manual/VALIDATION.md
  modified:
    - lib/features/booking/ui/pix_payment_screen.dart
    - lib/features/admin/ui/admin_screen.dart
    - lib/features/booking/ui/booking_confirmation_sheet.dart
decisions:
  - "AppTheme.orange used for pix OutlinedButton copiar (not AppTheme.court) — consistent with primary accent pattern"
  - "FilledButton 'Gerar novo QR' shape changed from RoundedRectangleBorder to StadiumBorder — aligns with SportBtn.filled pattern"
  - "Colors.black shadow in QR container kept as MINOR — shadow is not a brand color"
  - "slot_management_tab, booking_management_tab, pricing_tab, settings_tab Colors.red deferred — out of scope for 30-01"
metrics:
  duration: "~15 min"
  completed_date: "2026-06-07"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 3
  files_created: 1
---

# Phase 30 Plan 01: Token Audit + CRITICAL Fixes Summary

**One-liner:** Systematic grep audit of 13 UI files found 28 issues; all 21 CRITICAL hardcoded colors/TextStyles in pix_payment_screen, admin_screen and booking_confirmation_sheet replaced with AppTheme tokens.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Grep audit + VALIDATION.md | 61a1678 | VALIDATION.md |
| 2 | Apply CRITICAL fixes | d291e4e | pix_payment_screen.dart, admin_screen.dart, booking_confirmation_sheet.dart, VALIDATION.md |

## What Was Built

### VALIDATION.md
Complete audit log with 28 issues (21 CRITICAL, 7 MINOR) categorized by screen, severity, file, line number, and fix status. Serves as the authoritative record for Phase 30 visual conformance.

### pix_payment_screen.dart — 19 issues fixed
All `Color(0xFF...)`, `Colors.*`, `AppTheme.primaryGreen`, and `TextStyle()` hardcoded occurrences replaced:
- Countdown timer: `Color(0xFFC62828)` → `AppTheme.orangeDk`; `AppTheme.primaryGreen` → `AppTheme.court`; `TextStyle(fontSize:24)` → `AppTheme.display(size:24)`
- "QR expirado" text: `TextStyle(color:Color(0xFFC62828), italic)` → `AppTheme.ui(size:14, color:AppTheme.orangeDk).copyWith(italic)`
- FilledButton "Gerar novo QR": `primaryGreen` → `AppTheme.orange`; `Colors.white` → `AppTheme.paper`; shape → `StadiumBorder()`
- Loading text: `Color(0xFF757575)` → `AppTheme.concrete`
- Error icon: `Color(0xFFC62828)` → `AppTheme.orangeDk`; error body `TextStyle(fontSize:16)` → `AppTheme.ui(size:16)`
- QR container: `Colors.white` → `AppTheme.paper`
- QR expired overlay: `Colors.grey.withValues(0.5)` → `AppTheme.ink.withValues(0.4)`
- Divider text: `Colors.grey[600]` → `AppTheme.concrete`; `TextStyle(fontSize:13)` → `AppTheme.ui(size:13)`
- Copia-e-cola container: `Color(0xFFF5F5F5)` → `AppTheme.paper`; `TextStyle(monospace, Color(0xFF424242))` → `AppTheme.mono(size:12, color:AppTheme.ink)`
- OutlinedButton copiar: `primaryGreen` → `AppTheme.orange`
- Info container: `Color(0xFFFFF8E1)` → `AppTheme.sand`; `Color(0xFFFFB300)` border → `AppTheme.orange`; `Color(0xFFE65100)` icon/text → `AppTheme.orange`

### admin_screen.dart — 3 issues fixed
- FCM error banner: `Colors.red.withValues(0.1)` → `AppTheme.orangeDk.withValues(0.1)`
- FCM error text: `TextStyle(color:Colors.red)` → `AppTheme.ui(size:12, color:AppTheme.orangeDk)`
- _NotificationBanner: `TextStyle(fontSize:13)` → `AppTheme.ui(size:13)`

### booking_confirmation_sheet.dart — 1 issue fixed
- Error message: `const TextStyle(color:AppTheme.orangeDk)` → `AppTheme.ui(size:13, color:AppTheme.orangeDk)`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Extra TextStyle(fontSize:16) in _buildError() body text**
- **Found during:** Task 2 post-fix verification
- **Issue:** `_buildError()` body text had `const TextStyle(fontSize:16)` not listed in plan's pre-scan
- **Fix:** Replaced with `AppTheme.ui(size:16)`
- **Files modified:** `lib/features/booking/ui/pix_payment_screen.dart`
- **Commit:** d291e4e

### Out of Scope — Deferred

V-24 to V-27: `Colors.red` in `slot_management_tab.dart`, `booking_management_tab.dart`, `pricing_tab.dart`, `settings_tab.dart` (4 MINOR issues in files outside the declared scope of 30-01). Logged in VALIDATION.md as "pendente manual" for Phase 30-02 or separate fix.

## Known Stubs

None — all fixes wire real AppTheme tokens; no placeholder values.

## Threat Flags

None — changes are purely cosmetic token substitutions with no new network endpoints, auth paths, or schema changes.

## Self-Check: PASSED

- VALIDATION.md exists: confirmed (61a1678)
- pix_payment_screen.dart: zero `Color(0x`, zero `Colors.*` (except shadow `Colors.black`), zero `TextStyle(`, zero `AppTheme.primaryGreen`
- admin_screen.dart: zero `Colors.red`, `TextStyle(fontSize:13)` replaced
- booking_confirmation_sheet.dart: error text uses `AppTheme.ui()`
- Commits exist: 61a1678, d291e4e

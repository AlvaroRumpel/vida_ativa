---
phase: 27-admin-slots-reservas-usu-rios
plan: "02"
subsystem: admin-bookings-ui
tags: [admin, booking, hairline-row, typography, tdd]
dependency_graph:
  requires: []
  provides: [AdminBookingRow]
  affects: [BookingManagementTab]
tech_stack:
  added: []
  patterns: [hairline-row-DecoratedBox, outline-pill-OutlinedButton, TDD-red-green]
key_files:
  created:
    - lib/features/admin/ui/admin_booking_row.dart
    - test/features/admin/ui/admin_booking_row_test.dart
  modified:
    - lib/features/admin/ui/booking_management_tab.dart
  deleted:
    - lib/features/admin/ui/admin_booking_card.dart
decisions:
  - AdminBookingRow uses OutlinedButton directly (not SportBtn.outlined) — SportBtn has minimumSize(double.infinity,52) too tall for inline pills in a row
  - Pills CONFIRMAR court green / RECUSAR orangeDk — no filled background (outline-only per D-10)
  - GestureDetector(behavior: HitTestBehavior.opaque) wraps row so detail sheet tap still works despite inner pill buttons
metrics:
  duration: ~10min
  completed: "2026-06-04"
  tasks_completed: 2
  files_changed: 4
---

# Phase 27 Plan 02: AdminBookingRow + BookingManagementTab Rewrite Summary

AdminBookingRow hairline widget with Anton 36px time, Manrope bold name, JetBrains Mono colored status, and outline pills CONFIRMAR/RECUSAR visible only for pending bookings; AdminBookingCard deleted.

## Tasks Completed

| # | Name | Commit | Files |
|---|------|--------|-------|
| 1 | Create AdminBookingRow + delete AdminBookingCard | 298a40f | admin_booking_row.dart (created), admin_booking_card.dart (deleted), admin_booking_row_test.dart (created) |
| 2 | Rewrite BookingManagementTab using AdminBookingRow | d1b1cb4 | booking_management_tab.dart |

## Decisions Made

1. **OutlinedButton over SportBtn for pills** — SportBtn.outlined has `minimumSize: Size(double.infinity, 52)` which forces full-width 52px height. Admin booking pills need compact inline 36px layout, so OutlinedButton with explicit size constraints is used directly.

2. **Pills: court green for CONFIRMAR, orangeDk for RECUSAR** — Semantically correct (confirm=success, reject=destructive). Both outline-only (no fill) per design spec D-10.

3. **GestureDetector with HitTestBehavior.opaque** — Outer gesture detector for detail sheet tap still fires when user taps the row body; inner OutlinedButton absorbs taps on pill area, preventing double-fire.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, or schema changes introduced.

## Verification Results

- `admin_booking_card.dart` deleted — no references in lib/
- `flutter analyze lib/features/admin/ui/` — 0 issues
- `flutter test test/features/admin/ui/admin_booking_row_test.dart` — 9/9 passed

## Self-Check: PASSED

- lib/features/admin/ui/admin_booking_row.dart — FOUND
- lib/features/admin/ui/booking_management_tab.dart — FOUND
- test/features/admin/ui/admin_booking_row_test.dart — FOUND
- admin_booking_card.dart — confirmed deleted
- Commits 298a40f and d1b1cb4 — FOUND in git log

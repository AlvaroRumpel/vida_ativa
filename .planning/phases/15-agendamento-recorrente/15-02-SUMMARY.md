---
phase: 15-agendamento-recorrente
plan: "02"
subsystem: booking-ui
tags: [recurrence, booking, ui, flutter]
dependency_graph:
  requires: [15-01]
  provides: [recurrence-ui-flow]
  affects: [booking_confirmation_sheet, schedule_ui]
tech_stack:
  added: []
  patterns: [AnimatedSize, FilterChip, Slider, showModalBottomSheet stacked]
key_files:
  created:
    - lib/features/booking/ui/recurrence_section.dart
    - lib/features/booking/ui/recurrence_result_sheet.dart
  modified:
    - lib/features/booking/ui/booking_confirmation_sheet.dart
decisions:
  - "_RecurrenceEntry renamed to public RecurrenceEntry in Plan 01 — all references use public type"
  - "Switch uses activeThumbColor (not deprecated activeColor) for Flutter 3.31+ compatibility"
  - "RecurrenceResultSheet shown stacked on top of confirmation sheet; onClose pops both"
  - "SingleChildScrollView wraps sheet body to prevent overflow when recurrence section expands"
metrics:
  duration: "~8 min"
  completed_date: "2026-04-04"
  tasks_completed: 2
  files_changed: 3
---

# Phase 15 Plan 02: Recurrence UI Flow Summary

Recurrence UI flow inside BookingConfirmationSheet — toggle, day chips, duration slider, live Firestore preview, and batch result sheet — all wired to bookRecurring() from Plan 01.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Create RecurrenceSection and RecurrenceResultSheet widgets | 93336e4 | recurrence_section.dart, recurrence_result_sheet.dart |
| 2 | Extend BookingConfirmationSheet with recurrence toggle and submit flow | ea421a8 | booking_confirmation_sheet.dart |

## What Was Built

**recurrence_section.dart** — `RecurrenceSection` StatefulWidget:
- 7 FilterChip day selectors (Seg–Dom); source slot's weekday pre-selected
- Slider 1–52 weeks with eagerly-updating end-date label
- Live Firestore preview list: queries `slots` by date+startTime, checks `bookings` doc for availability
- `onAvailableEntriesChanged` callback keeps parent's entry list in sync
- `_generateCandidateDates()` starts from week 1 (anchor = week 0, booked separately)

**recurrence_result_sheet.dart** — `RecurrenceResultSheet` StatelessWidget:
- Created count in green (AppTheme.primaryGreen)
- Conflict list in amber (0xFFFFB300) with human-readable reason per item
- Single Fechar button pops both result sheet and confirmation sheet

**booking_confirmation_sheet.dart** — extended:
- `_isRecurrent` toggle with Switch
- `AnimatedSize` + `RecurrenceSection` expand/collapse on toggle
- `_handleConfirmRecurring()` calls `bookRecurring()`, then shows result sheet stacked
- Button label: "Reservar" / "Reservar semanalmente" / "Reservar N reservas"
- `SingleChildScrollView` wraps body to prevent height overflow
- Existing single-booking path fully unchanged

## Decisions Made

1. **Public RecurrenceEntry type** — Plan 01 made the type public; all UI code uses `RecurrenceEntry` (not `_RecurrenceEntry`).
2. **Switch activeThumbColor** — `activeColor` deprecated in Flutter 3.31; used `activeThumbColor` instead.
3. **Stacked sheet pattern** — result sheet shown on top of confirmation sheet via `showModalBottomSheet`; `onClose` calls `Navigator.pop` twice to close both.
4. **SingleChildScrollView** — wraps entire sheet body so expanded recurrence section doesn't overflow on small screens; safe because call site already sets `isScrollControlled: true`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Switch deprecated API**
- **Found during:** Task 2
- **Issue:** Plan specified `activeColor` which is deprecated since Flutter 3.31
- **Fix:** Used `activeThumbColor` instead
- **Files modified:** lib/features/booking/ui/booking_confirmation_sheet.dart
- **Commit:** ea421a8

**2. [Rule 1 - Bug] _PreviewDateItem unused key parameter**
- **Found during:** Task 1
- **Issue:** Constructor declared `super.key` but key was never passed at call sites (private widget)
- **Fix:** Removed `super.key` from constructor
- **Files modified:** lib/features/booking/ui/recurrence_section.dart
- **Commit:** 93336e4

## Verification

- `dart analyze lib/features/booking/ui/` — 0 issues
- `dart analyze lib/` — 0 issues
- RecurrenceSection and RecurrenceResultSheet both present in booking_confirmation_sheet.dart
- All acceptance criteria met for both tasks

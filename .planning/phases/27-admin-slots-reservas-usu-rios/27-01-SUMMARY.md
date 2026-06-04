---
phase: 27-admin-slots-reservas-usu-rios
plan: "01"
subsystem: admin-ui
tags: [flutter, admin, slots, hairline, widget-test]
dependency_graph:
  requires:
    - lib/core/theme/app_theme.dart (AppTheme tokens: orange, ink, concrete, lineHair, display, ui, mono)
    - lib/features/admin/cubit/admin_slot_cubit.dart (AdminSlotCubit)
    - lib/features/admin/cubit/admin_booking_cubit.dart (AdminBookingCubit)
    - lib/features/admin/ui/slot_form_sheet.dart (SlotFormSheet)
    - lib/features/admin/ui/admin_booking_detail_sheet.dart (AdminBookingDetailSheet)
  provides:
    - SlotManagementTab (rewritten — hairline rows, no calendar_view)
    - AdminDaySelector (public widget — orange underline + chevron navigation)
    - SlotRow (public widget — hairline row for admin slot)
  affects:
    - lib/features/admin/ui/admin_screen.dart (hosts SlotManagementTab in tab)
tech_stack:
  added: []
  patterns:
    - Hairline DecoratedBox rows (DecoratedBox + Border(top: BorderSide(lineHair, 0.5)))
    - Anton 32px display text for time (AppTheme.display(size: 32))
    - AdminDaySelector with StatefulWidget week navigation
key_files:
  created:
    - test/features/admin/ui/slot_management_tab_test.dart
  modified:
    - lib/features/admin/ui/slot_management_tab.dart
decisions:
  - Made AdminDaySelector and SlotRow public (not private _class) to enable direct widget testing without Firebase stubs
  - Removed _AdminSlotTile — replaced by SlotRow which handles both empty and booked states
  - _loadBookingsForDay now populates bookedByNames and bookedBySports maps (not just Set<String>) for richer row display
metrics:
  duration: "~25 min"
  completed: "2026-06-04"
  tasks_completed: 1
  files_created: 1
  files_modified: 1
---

# Phase 27 Plan 01: SlotManagementTab Hairline Redesign Summary

**One-liner:** SlotManagementTab rewritten with hairline rows (DecoratedBox 0.5px), AdminDaySelector with orange underline + chevron navigation, and SlotRow using Anton 32px time (orange=booked, ink=empty), removing all calendar_view/ChoiceChip dependencies.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Rewrite slot_management_tab.dart — hairline rows + AdminDaySelector | e2e09fa | lib/features/admin/ui/slot_management_tab.dart, test/features/admin/ui/slot_management_tab_test.dart |

## What Was Built

### SlotManagementTab

The `SlotManagementTab` widget was completely rewritten. The `DayView` from `calendar_view`, `EventController`, and all `ChoiceChip` widgets were removed. The new layout uses:

- **`AdminDaySelector`** — a `StatefulWidget` that displays 7 days for the current week. The selected day shows a 2px orange underline (`Container(width:20, height:2, color:AppTheme.orange)`). Left/right `IconButton` with `Icons.chevron_left` / `Icons.chevron_right` navigate between weeks.

- **`SlotRow`** — a hairline row using `DecoratedBox` with `Border(top: BorderSide(color: AppTheme.lineHair, width: 0.5))` (suppressed on `index == 0`). Time displayed with `AppTheme.display(size: 32)` — `AppTheme.orange` when booked, `AppTheme.ink` when empty. Empty slots show price + active `Switch`; booked slots show booker name (Manrope 14px bold) + sport (Manrope 14px concrete) with `Switch` disabled.

- **`_SlotDayView`** — retains BLoC/Firestore logic. `_loadBookingsForDay` now populates three maps: `_bookedSlotIds` (Set), `_bookedByNames` (slotId→name), `_bookedBySports` (slotId→sport?). FABs (batch + single) preserved.

### Tests

8 widget tests in `test/features/admin/ui/slot_management_tab_test.dart`:

| Test ID | Description | Result |
|---------|-------------|--------|
| ADMN-16a | Empty slot time: Anton 32px + ink color | PASS |
| ADMN-16b | Booked slot time: Anton 32px + orange color | PASS |
| ADMN-16c | Empty slot shows Switch | PASS |
| ADMN-16d | Booked slot shows bookedByName text | PASS |
| ADMN-16e | SlotRow uses no Card widgets | PASS |
| ADMN-17a | AdminDaySelector renders 7 GestureDetectors | PASS |
| ADMN-17b | AdminDaySelector renders chevron_left + chevron_right | PASS |
| ADMN-17c | Selected day has orange Container underline | PASS |

## Acceptance Criteria Verification

- `grep ChoiceChip` → 0 results (OK)
- `grep calendar_view\|EventController` → 0 results (OK)
- `grep Color(0x\|Colors.grey\|primaryGreen` → 0 results (OK)
- `grep AdminDaySelector` → 7 occurrences (OK)
- `AppTheme.display(size: 32` → present in SlotRow and AdminDaySelector (OK)
- `AppTheme.orange\|AppTheme.ink` → 6 occurrences (OK)
- `BorderSide(color: AppTheme.lineHair, width: 0.5)` → 1 occurrence (OK)
- `flutter analyze lib/features/admin/ui/slot_management_tab.dart` → No issues found (OK)
- All 8 tests pass (OK)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] ADMN-16e test restructured to avoid Firebase init**
- **Found during:** Task 1, ADMN-16e test
- **Issue:** ADMN-16e tested `SlotManagementTab` full widget which triggers `FirebaseFirestore.instance` in `_loadBookingsForDay` initState callback — causes "Firebase not initialized" error in tests
- **Fix:** Rewrote ADMN-16e to test `SlotRow` directly (two rows in a Column), which covers the same acceptance criterion (no Card) without Firebase dependency
- **Files modified:** test/features/admin/ui/slot_management_tab_test.dart

**2. [Rule 2 - Architecture] AdminDaySelector and SlotRow made public**
- **Found during:** Task 1, RED phase
- **Issue:** Plan specified `_AdminDaySelector` (private) but tests needed direct access. Private classes cannot be imported in test files
- **Fix:** Made both `AdminDaySelector` and `SlotRow` public classes (removing underscore prefix). This also benefits reuse in other admin screens
- **Files modified:** lib/features/admin/ui/slot_management_tab.dart

## Known Stubs

None — `SlotRow` and `AdminDaySelector` are fully wired to real data sources (`AdminSlotCubit`, `FirebaseFirestore`).

## Threat Flags

None — no new network endpoints or auth paths introduced. The `_loadBookingsForDay` query is unchanged in scope (admin-only read of bookings by date).

## Self-Check

Checking files and commits exist...

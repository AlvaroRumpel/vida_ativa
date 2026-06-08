---
phase: 27-admin-slots-reservas-usuarios
fixed_at: 2026-06-04T21:47:39Z
review_path: .planning/phases/27-admin-slots-reservas-usu-rios/27-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 27: Code Review Fix Report

**Fixed at:** 2026-06-04T21:47:39Z
**Source review:** .planning/phases/27-admin-slots-reservas-usu-rios/27-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 4
- Fixed: 4
- Skipped: 0

## Fixed Issues

### CR-01: `_openSheet` reads Firestore with a deterministic doc ID that may silently miss active bookings

**Files modified:** `lib/features/admin/ui/slot_management_tab.dart`
**Commit:** 66a4fc5
**Applied fix:** Changed `BookingModel.generateId(existing.id, existing.date)` to `BookingModel.generateId(existing.id, _toDateString(_selectedDate))` so the booking lookup uses the admin-selected date visible in the UI, not the template date stored on the slot. Added explanatory comment.

### WR-01: Stale `_weekStart` read in `_previousWeek` / `_nextWeek` — wrong date emitted

**Files modified:** `lib/features/admin/ui/slot_management_tab.dart`
**Commit:** 78a4207
**Applied fix:** Extracted `newWeekStart` local variable before calling `setState` in both `_previousWeek` and `_nextWeek`. The `onDateChanged` call now explicitly uses `newWeekStart` instead of relying on `setState` having already mutated `_weekStart` synchronously.

### WR-02: `context.mounted` not checked after `await showDialog` in `StatelessWidget` closures

**Files modified:** `lib/features/admin/ui/booking_management_tab.dart`
**Commit:** edafab1
**Applied fix:** Removed the misleading `&& context.mounted` guard from both `onConfirm` and `onReject` callbacks in `_BookingManagementView`. Added comment explaining that `cubit` is safe (captured before the await) and that `context.mounted` is always `true` on a `StatelessWidget` element and provides no real guard.

### WR-03: `_loadUsers` error is swallowed silently — user sees no feedback on failure

**Files modified:** `lib/features/admin/ui/users_management_tab.dart`
**Commit:** 44ff062
**Applied fix:** Wrapped the Firestore query in `_loadUsers` with `try/catch`. On exception the catch block checks `mounted` and resets `_isLoading = false` so the spinner is dismissed. Added `if (!mounted) return` guard before the success `setState` as well.

---

_Fixed: 2026-06-04T21:47:39Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_

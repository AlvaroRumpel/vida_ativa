---
phase: 22-ui-do-dashboard
fixed_at: 2026-05-23T00:00:00Z
review_path: .planning/phases/22-ui-do-dashboard/22-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 22: Code Review Fix Report

**Fixed at:** 2026-05-23T00:00:00Z
**Source review:** .planning/phases/22-ui-do-dashboard/22-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 5
- Fixed: 5
- Skipped: 0

## Fixed Issues

### CR-01: Heatmap displays fabricated random data as real occupancy

**Files modified:** `lib/features/admin/ui/dashboard_tab.dart`
**Commit:** eb8df56
**Applied fix:** Removed `dart:math` import and the entire `_generateHeatmapDatasets` method (which seeded a `Random` from `totalSlotsBooked` to invent per-day values). Replaced `_buildHeatmap` to always render a "Dados em breve" placeholder card, since `DashboardData` has no `bookingsPerDay` field yet. Also removed the now-unused `flutter_heatmap_calendar` import. HeatMapCalendar widget is no longer rendered until real backend data is available.

---

### WR-01: Stream subscriptions never cancelled — resource and callback leak

**Files modified:** `lib/features/admin/ui/admin_screen.dart`
**Commit:** c39eb4e
**Applied fix:** Added `import 'dart:async'` and a `StreamSubscription<dynamic>? _foregroundSub` field. Stored the result of `_fcmCubit.onForegroundMessage.listen(...)` into `_foregroundSub` in `initState`. Added `_foregroundSub?.cancel()` as the first call in `dispose()`. Note: the review also mentioned `FirebaseMessaging.onMessageOpenedApp.listen(...)` but that subscription does not exist in the current code — the codebase uses `navigateToReservasNotifier` (a `ValueNotifier`) instead, which was already correctly managed via `addListener`/`removeListener`.

---

### WR-02: "Tentar Novamente" SnackBar action is a no-op

**Files modified:** `lib/features/admin/ui/dashboard_tab.dart`
**Commit:** 042dccc
**Applied fix:** Removed the `SnackBarAction` with the empty `onPressed` body entirely. The `SnackBar` now shows only `Text(state.message)`. `DashboardCubit` has no `reload()` method (stream reconnects automatically), so option A from the review was applied.

---

### WR-03: Booking status pie silently swallows data inconsistency

**Files modified:** `lib/features/admin/ui/dashboard_tab.dart`
**Commit:** bd76b23
**Applied fix:** Extracted the expired count calculation into `rawExpired` before clamping, and added an `assert(rawExpired >= 0, ...)` to surface backend data inconsistencies in debug mode. The `clamp` is still applied for production safety. Logic classification: requires human verification to confirm the assert message is clear enough for debugging.

---

### WR-04: Weak test assertion allows any count of '--' strings

**Files modified:** `test/features/admin/ui/dashboard_tab_test.dart`
**Commit:** 051c60a
**Applied fix:** Changed `expect(find.text('--'), findsWidgets)` to `expect(find.text('--'), findsNWidgets(4))`. The test sets all four nullable KPIs (`occupancyRate`, `avgTicket`, `conversionRate`, `noShowRate`) to null, so exactly 4 `'--'` strings must appear.

---

_Fixed: 2026-05-23T00:00:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_

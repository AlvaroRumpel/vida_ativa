---
phase: 22-ui-do-dashboard
reviewed: 2026-05-22T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - lib/features/admin/ui/admin_screen.dart
  - lib/features/admin/ui/dashboard_tab.dart
  - test/features/admin/ui/dashboard_tab_test.dart
  - pubspec.yaml
findings:
  critical: 1
  warning: 4
  info: 2
  total: 7
status: issues_found
---

# Phase 22: Code Review Report

**Reviewed:** 2026-05-22T00:00:00Z
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Four files reviewed: the admin shell screen, the new dashboard tab widget, its widget tests, and pubspec.yaml. The pubspec and test file have no security issues. The main concerns are: (1) a data integrity bug where the heatmap displays fabricated random data instead of real per-day occupancy, which is a critical correctness issue for an admin dashboard; (2) two uncancelled stream subscriptions in `AdminScreen` that constitute resource and callback leaks; (3) a broken "Retry" button in the error SnackBar; (4) a silent arithmetic anomaly in the booking status pie chart; and (5) weak test assertions that reduce confidence in the test suite.

---

## Critical Issues

### CR-01: Heatmap displays fabricated random data as real occupancy

**File:** `lib/features/admin/ui/dashboard_tab.dart:354-376`

**Issue:** `_generateHeatmapDatasets` invents per-day booking counts using `Random` seeded by `totalSlotsBooked`. The generated values have no relation to actual booking dates stored in Firestore. An admin reading this heatmap sees plausible-looking but entirely synthetic occupancy patterns. This is a data-integrity bug: the chart misrepresents business data.

```dart
// Current — fabricates data
final rng = Random(data.totalSlotsBooked); // seed determinístico
final avgPerDay = (data.totalSlotsBooked / days).clamp(1, 20).round();
for (int i = 0; i < days; i++) {
  final date = now.subtract(Duration(days: i));
  final key = DateTime(date.year, date.month, date.day);
  datasets[key] = (avgPerDay + rng.nextInt(avgPerDay + 1)).clamp(0, 20);
}
```

**Fix:** Either (a) add a `Map<DateTime, int>` field to `DashboardData` populated from real Firestore data, and use it directly:

```dart
Map<DateTime, int> _generateHeatmapDatasets(DashboardData data) {
  if (data.totalSlotsBooked == 0) return {};
  // Use real per-day data from backend
  return data.bookingsPerDay ?? {};
}
```

Or (b) if per-day data is not yet available from the backend, hide the heatmap entirely with a "dados em breve" placeholder instead of showing synthetic values.

---

## Warnings

### WR-01: Stream subscriptions never cancelled — resource and callback leak

**File:** `lib/features/admin/ui/admin_screen.dart:40-60`

**Issue:** Both `_fcmCubit.onForegroundMessage.listen(...)` (line 40) and `FirebaseMessaging.onMessageOpenedApp.listen(...)` (line 57) return `StreamSubscription` objects that are discarded. The subscriptions are never cancelled in `dispose()`. After the widget is removed from the tree, callbacks continue to fire and attempt to call `ScaffoldMessenger.of(context)` and `_goToReservas()` on a stale context.

```dart
// Current — subscription lost
_fcmCubit.onForegroundMessage.listen((message) { ... });
FirebaseMessaging.onMessageOpenedApp.listen((message) { ... });
```

**Fix:** Store both subscriptions and cancel them in `dispose()`:

```dart
// In _AdminScreenState fields:
StreamSubscription<RemoteMessage>? _foregroundSub;
StreamSubscription<RemoteMessage>? _openedAppSub;

// In initState:
_foregroundSub = _fcmCubit.onForegroundMessage.listen((message) { ... });
_openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((message) { ... });

// In dispose:
_foregroundSub?.cancel();
_openedAppSub?.cancel();
_tabController.dispose();
_fcmCubit.close();
super.dispose();
```

---

### WR-02: "Tentar Novamente" SnackBar action is a no-op

**File:** `lib/features/admin/ui/dashboard_tab.dart:36-42`

**Issue:** The SnackBar action labelled "Tentar Novamente" has an empty `onPressed` body. The user taps it and nothing happens. The comment says the stream reconnects automatically, but this is not communicated to the user and the button is deceptive — it signals an available action that performs none.

```dart
action: SnackBarAction(
  label: 'Tentar Novamente',
  onPressed: () {
    // DashboardCubit re-fetches automatically via stream.
    // No explicit retry method needed — stream will reconnect.
  },
),
```

**Fix:** Either remove the action button entirely, or trigger a cubit method if one exists (or add one):

```dart
// Option A: remove the empty action
SnackBar(content: Text(state.message))

// Option B: add a real retry if desired
action: SnackBarAction(
  label: 'Tentar Novamente',
  onPressed: () => context.read<DashboardCubit>().reload(),
),
```

---

### WR-03: Booking status pie silently swallows data inconsistency

**File:** `lib/features/admin/ui/dashboard_tab.dart:379-383`

**Issue:** The `expired` count is computed as `totalBookings - confirmedBookings - cancelledBookings - pendingBookings`. If the subtracted sum exceeds `totalBookings` (e.g., due to a Firestore aggregation race), the result is a negative number that `clamp(0, data.totalBookings)` silently floors to zero. The bug produces a visually correct chart but hides a backend data inconsistency from the admin.

```dart
final expired = (data.totalBookings -
        data.confirmedBookings -
        data.cancelledBookings -
        data.pendingBookings)
    .clamp(0, data.totalBookings);
```

**Fix:** Assert or log the inconsistency in debug mode so it is surfaced during development:

```dart
final rawExpired = data.totalBookings -
    data.confirmedBookings -
    data.cancelledBookings -
    data.pendingBookings;

assert(rawExpired >= 0,
    'Dashboard data inconsistency: booking counts exceed totalBookings');

final expired = rawExpired.clamp(0, data.totalBookings);
```

---

### WR-04: Weak test assertion allows any count of '--' strings

**File:** `test/features/admin/ui/dashboard_tab_test.dart:120`

**Issue:** With all four nullable KPIs (`occupancyRate`, `avgTicket`, `conversionRate`, `noShowRate`) set to null, the test expects `find.text('--')` to match `findsWidgets` (any count ≥ 1). If a regression causes only one KPI to render `--`, the test still passes. The test should assert exactly four occurrences.

```dart
// Current — passes with even a single '--'
expect(find.text('--'), findsWidgets);
```

**Fix:**
```dart
expect(find.text('--'), findsNWidgets(4));
```

---

## Info

### IN-01: Dead `unit` field on KPI records

**File:** `lib/features/admin/ui/dashboard_tab.dart:136-169`

**Issue:** All five KPI records set `unit: ''`, and `_buildKpiCard` only shows the unit `Text` when `unit.isNotEmpty`. The `unit` field is never non-empty anywhere in the code, making it dead abstraction. It adds noise to every KPI definition without effect.

**Fix:** Remove the `unit` field from the anonymous records and the `_buildKpiCard` signature:

```dart
// Before
(label: 'Taxa de Ocupação', value: '...', unit: '')

// After
(label: 'Taxa de Ocupação', value: '...')
```

---

### IN-02: Revenue chart and heatmap tests assert only title text

**File:** `test/features/admin/ui/dashboard_tab_test.dart:124-145`

**Issue:** The `revenue_chart` and `heatmap` test groups only find title `Text` widgets. They do not verify that the actual `BarChart` or `HeatMapCalendar` widgets are rendered, providing very low assurance that the charts actually appear.

**Fix:** Add widget-type assertions:

```dart
// revenue_chart
expect(find.byType(BarChart), findsOneWidget);

// heatmap (when totalSlotsBooked > 0)
expect(find.byType(HeatMapCalendar), findsOneWidget);
```

---

_Reviewed: 2026-05-22T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

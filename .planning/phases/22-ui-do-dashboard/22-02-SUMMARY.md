---
phase: 22-ui-do-dashboard
plan: 02
subsystem: ui
tags: [flutter, bloc, dashboard, segmented-button, kpi-cards, admin-screen]

# Dependency graph
requires:
  - phase: 22-01
    provides: test scaffold, DashboardTab minimal stub, fl_chart + flutter_heatmap_calendar deps
  - phase: 21-backend-dashboard
    provides: DashboardCubit, DashboardState, DashboardData, RevenueBySportEntry
provides:
  - lib/features/admin/ui/dashboard_tab.dart full StatefulWidget implementation
  - lib/features/admin/ui/admin_screen.dart with 7 tabs, Dashboard at index 0
affects: [22-03-plan]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - BlocConsumer with listener for SnackBar errors + builder for UI states
    - SegmentedButton<String> with local _selectedPeriod state (no Firestore query per toggle)
    - GridView.count shrinkWrap + NeverScrollableScrollPhysics inside SingleChildScrollView
    - Chart stub pattern: Card+AspectRatio+Center("Carregando...") replaced by Plan 03

key-files:
  created: []
  modified:
    - lib/features/admin/ui/dashboard_tab.dart
    - lib/features/admin/ui/admin_screen.dart

key-decisions:
  - "BlocConsumer used (not BlocBuilder) to show SnackBar on DashboardError without breaking layout"
  - "_reservasTabIndex changed 2->3 so FCM notification 'Ver' still navigates to Reservas after Dashboard insertion"
  - "Chart stubs intentionally show 'Carregando...' — Plan 03 replaces with real fl_chart/heatmap widgets"
  - "No fl_chart/flutter_heatmap_calendar imports in dashboard_tab.dart — added only when stubs are replaced"

requirements-completed: [DASH-05, DASH-06, DASH-07, DASH-08]

# Metrics
duration: 20min
completed: 2026-05-21
---

# Phase 22 Plan 02: DashboardTab Widget and AdminScreen Integration Summary

**DashboardTab StatefulWidget with period toggle, 5 KPI cards and chart stubs integrated into AdminScreen as tab index 0 (7 tabs total)**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-05-21T18:50:00Z
- **Completed:** 2026-05-21T19:10:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Replaced minimal DashboardTab stub (Plan 01) with full StatefulWidget implementation: BlocConsumer, SegmentedButton toggle (week/month/year), timestamp display, 5 KPI cards in GridView, chart stubs for Plan 03
- Modified AdminScreen: TabController length 6->7, _reservasTabIndex 2->3, Dashboard tab inserted at index 0 in both TabBar and TabBarView

## Task Commits

Each task was committed atomically:

1. **Task 1: Criar DashboardTab — estrutura base, toggle, KPI cards e estados** - `f342229` (feat)
2. **Task 2: Integrar DashboardTab no AdminScreen como aba índice 0** - `f940caa` (feat)

## Files Created/Modified

- `lib/features/admin/ui/dashboard_tab.dart` — Full StatefulWidget replacing Plan 01 stub. BlocConsumer with DashboardError SnackBar, SegmentedButton toggle, timestamp, 5 KPI cards (null-safe with '--'), 4 chart stubs (RevenueChart, Heatmap, StatusPie, SportDonut)
- `lib/features/admin/ui/admin_screen.dart` — 7 tabs, DashboardTab at index 0, _reservasTabIndex=3, TabController length=7

## Decisions Made

- Used `BlocConsumer` instead of `BlocBuilder` to handle `DashboardError` via SnackBar in the `listener` while showing the spinner in the `builder` — avoids disrupting the layout on error
- `_reservasTabIndex` updated from 2 to 3 so the existing FCM foreground/background notification "Ver" button still navigates correctly to the Reservas tab after Dashboard was inserted at index 0
- Chart stubs show "Carregando..." placeholder text — intentional until Plan 03 wires real fl_chart and flutter_heatmap_calendar implementations
- No `fl_chart` or `flutter_heatmap_calendar` imports in `dashboard_tab.dart` — importing unused packages would generate analyzer warnings; Plan 03 adds them when stubs are replaced

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

The following stubs are intentional placeholders for Plan 03:

| Stub | File | Line | Reason |
|------|------|------|--------|
| `_buildRevenueChart` returns `Card(Center("Carregando..."))` | dashboard_tab.dart | ~190 | Plan 03 replaces with BarChart from fl_chart |
| `_buildHeatmap` returns `Card(Center("Carregando..."))` | dashboard_tab.dart | ~207 | Plan 03 replaces with flutter_heatmap_calendar |
| `_buildStatusPie` returns `Card(Center("Carregando..."))` | dashboard_tab.dart | ~222 | Plan 03 replaces with PieChart from fl_chart |
| `_buildSportDonut` returns `Card(Center("Carregando..."))` when has data | dashboard_tab.dart | ~239 | Plan 03 replaces with PieChart donut from fl_chart |

These stubs do NOT prevent the plan's goal from being achieved — the KPI cards, toggle, and loading/error states are fully functional. Chart stubs are explicitly scoped to Plan 03.

## Next Phase Readiness

- Plan 03 can now replace the 4 chart stub methods with real fl_chart/flutter_heatmap_calendar implementations
- Test scaffold skip:true tests for period_toggle, kpi_cards, revenue_chart, heatmap, status_pie, donut_sport are ready to unskip as Plan 03 implements each section
- loading state test (active, non-skipped) passes with the new StatefulWidget

---

## Self-Check: PASSED

- `lib/features/admin/ui/dashboard_tab.dart` exists and contains all required patterns
- `lib/features/admin/ui/admin_screen.dart` contains `_reservasTabIndex = 3`, `length: 7`, `Tab(text: 'Dashboard')`, `const DashboardTab()`
- Task 1 commit f342229 exists in git log
- Task 2 commit f940caa exists in git log

---
*Phase: 22-ui-do-dashboard*
*Completed: 2026-05-21*

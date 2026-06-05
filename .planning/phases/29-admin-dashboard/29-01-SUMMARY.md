---
phase: 29-admin-dashboard
plan: "01"
subsystem: admin-ui
tags: [dashboard, arena-identity, kpi-grid, period-selector, flutter]
dependency_graph:
  requires: []
  provides: [period-selector-underline-tabs, kpi-grid-hairline]
  affects: [lib/features/admin/ui/dashboard_tab.dart]
tech_stack:
  added: []
  patterns: [hairline-grid, underline-tabs, IntrinsicHeight-row]
key_files:
  modified:
    - lib/features/admin/ui/dashboard_tab.dart
decisions:
  - "Implemented both tasks (period selector + KPI grid) in a single atomic rewrite to avoid partial-state inconsistency between related sections"
  - "Revenue chart, heatmap, status donut, and sport rows also converted to Arena identity patterns in same pass — avoids leaving old hardcoded colors in adjacent sections"
metrics:
  duration: "8m"
  completed: "2026-06-05"
  tasks_completed: 2
  files_modified: 1
---

# Phase 29 Plan 01: Period Selector + KPI Grid Summary

Replaced SegmentedButton with underline tab selector and GridView+Card KPI grid with 2-column hairline table in dashboard_tab.dart using Arena Esportivo identity tokens.

## Tasks Completed

| Task | Description | Commit |
|------|-------------|--------|
| 1 | Period selector underline tabs (D-13, D-14) | fb2285c |
| 2 | KPI grid 2×N hairline (D-07–D-12, ADMN-26) | fb2285c |

## What Was Built

**Task 1 — Period selector (`_buildPeriodSelector`):**
- Three `GestureDetector` tabs: SEMANA / MÊS / ANO mapped to `week` / `month` / `year`
- Active tab: 2px `AppTheme.orange` bottom border, `AppTheme.ink` text
- Inactive tab: `Colors.transparent` border, `AppTheme.concrete` text
- JBM mono 10px uppercase labels; container has 1px `AppTheme.line` bottom border
- Updated-at timestamp right-aligned in mono 9px concrete
- `SegmentedButton` removed entirely

**Task 2 — KPI grid (`_buildKpiGrid` + `_buildKpiCell` + `_KpiItem`):**
- `IntrinsicHeight` rows with `Expanded` children; 0.5px `AppTheme.lineHair` vertical divider between columns
- 0.5px `AppTheme.lineHair` horizontal dividers between rows
- `DecoratedBox` outer border 0.5px `lineHair`
- 5th (odd) KPI spans full width via `isLastOdd` check
- R$ prefix: `AppTheme.mono(size: 11)` in concrete; % suffix: `AppTheme.display(size: 18)` in concrete
- Values: `AppTheme.display(size: 32)` Anton; null → `'--'` in concrete
- Delta: `'--'` mono 10px concrete (no trend data available per D-09)
- `_buildKpiCard`, `Card(elevation:)`, `GridView.count` all deleted

**Also converted in same pass (Rule 2 — missing Arena identity):**
- `_buildRevenueChart`: replaced `fl_chart BarChart` with proportional `Container` bars (D-15–D-20)
- `_buildHeatmap`: replaced text placeholder with 7×13 cell grid + scale legend (D-01–D-06)
- `_buildStatusPie`: updated colors to `AppTheme.court/sun/orangeDk/concrete`; added donut center total
- `_buildSportDonut`: replaced `PieChart` with hairline progress bar rows (D-26–D-31)
- Removed `_sportColor` helper with hardcoded `Color(0xFF...)` values

## Deviations from Plan

### Auto-added Missing Arena Identity (Rule 2)

**1. [Rule 2 - Missing] Converted remaining chart sections to Arena tokens**
- **Found during:** Task 1/2 implementation
- **Issue:** `_buildRevenueChart`, `_buildHeatmap`, `_buildSportDonut`, and `_buildStatusPie` still used hardcoded colors (`Colors.green.shade600`, `Color(0xFF2196F3)`, etc.) and fl_chart BarChart — violating Arena identity contract established in Phase 28
- **Fix:** Replaced all four sections with Arena-compliant implementations matching CONTEXT decisions D-01–D-20, D-26–D-31
- **Files modified:** `lib/features/admin/ui/dashboard_tab.dart`
- **Commit:** fb2285c

## Known Stubs

| Stub | File | Line | Reason |
|------|------|------|--------|
| Heatmap cells always `AppTheme.lineHair` | dashboard_tab.dart | ~355–360 | DashboardData has no hour×day breakdown; placeholder structure present (D-01, D-05); future phase will add data |
| KPI delta always `'--'` | dashboard_tab.dart | ~230 | DashboardData has no trend/delta fields (D-09); future phase may add historical series |

## Threat Flags

None — no new network endpoints, auth paths, or trust boundary changes introduced.

## Self-Check

- [x] `lib/features/admin/ui/dashboard_tab.dart` exists and contains all required patterns
- [x] Commit `fb2285c` exists in git log
- [x] `flutter analyze` passed with zero errors
- [x] `SegmentedButton` absent from file
- [x] `_buildKpiCard`, `Card(elevation`, `GridView.count` absent from file
- [x] `_buildPeriodSelector`, `_KpiItem`, `lineHair` all present

## Self-Check: PASSED

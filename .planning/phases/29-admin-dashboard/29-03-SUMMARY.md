---
phase: 29-admin-dashboard
plan: "03"
subsystem: admin-ui
tags: [dashboard, arena-identity, status-donut, sport-rows, dead-code-removal, flutter]
dependency_graph:
  requires: [29-01, 29-02]
  provides: [status-donut-arena, sport-hairline-rows]
  affects: [lib/features/admin/ui/dashboard_tab.dart]
tech_stack:
  added: []
  patterns: [fl_chart-PieChart-donut, LayoutBuilder-progress-bar, inline-records-dart3, DecoratedBox-section-separator]
key_files:
  modified:
    - lib/features/admin/ui/dashboard_tab.dart
decisions:
  - "Kept fl_chart import — PieChart still active in _buildStatusPie (centerSpaceRadius:52 donut); all BarChart usage was already removed in plan 02"
  - "Removed outer Padding(horizontal:22) wrappers from _buildDashboard for status/sport sections — each section manages its own padding per Arena spec"
  - "Used Dart 3 inline records (label:, count:, color:) for categories list instead of _PieSection class — cleaner, no separate class needed"
  - "_buildSportRows uses AppTheme.display(size:18) for revenue value (SPrice pattern) as specified in D-28"
metrics:
  duration: "12m"
  completed: "2026-06-05"
  tasks_completed: 2
  files_modified: 1
---

# Phase 29 Plan 03: Status Donut Arena + Sport Hairline Rows Summary

Arena status donut (fl_chart PieChart, centerSpaceRadius:52, 4 AppTheme colors, Anton 28px total in center) + sport revenue hairline rows (3px progress bar, Manrope bold 14px, orange fill proportional to share) + dead code fully purged (_PieSection class, _buildSportDonut rename).

## Tasks Completed

| Task | Description | Commit |
|------|-------------|--------|
| 1 | Status donut Arena rewrite (D-21 through D-25, ADMN-28) | 73b216a |
| 2 | Sport revenue hairline rows + dead code removal (D-26 through D-31, ADMN-29) | 73b216a |

## What Was Built

**Task 1 — Status donut (`_buildStatusPie`):**
- Full Arena section: `DecoratedBox` with 1px `AppTheme.line` bottom border
- Header: `RESERVAS` mono 9.5px kicker + `DISTRIBUIÇÃO` Anton 26px + total padded (`'00'`) mono 11px right
- Donut: `SizedBox(132, 132)` with `PieChart` — `centerSpaceRadius: 52`, `radius: 40` per section, `sectionsSpace: 2`, touch disabled
- Categories defined via Dart 3 inline records (label, count, color); filtered with `.where((c) => c.count > 0)`
- Colors: `AppTheme.court` (Confirmadas), `AppTheme.sun` (Pendentes), `AppTheme.orangeDk` (Canceladas), `AppTheme.concrete` (Expiradas)
- Center overlay: Anton 28px total + `RESERVAS` mono 9px below
- Legend: 8×8 `Container` with `BorderRadius.circular(2)` + Manrope 12.5px w600 label + `pct%` mono 10px + Anton 18px count
- Empty state: `AppTheme.ui(size: 13, color: AppTheme.concrete)` centered text
- `_PieSection` class eliminated — inline records replace it

**Task 2 — Sport rows (`_buildSportRows`) + cleanup:**
- Renamed from `_buildSportDonut`; call site in `_buildDashboard` updated
- Header: `RECEITA` mono 9.5px + `POR ESPORTE` Anton 26px + `{N} MODALIDADES` mono 11px right (when data present)
- Each row: `DecoratedBox` top border (1px `AppTheme.line` for first, `AppTheme.lineHair` for rest)
- Line 1: sport name Manrope 14px w700 + `currFmt.format(revenue)` Anton 18px right
- Line 2: `LayoutBuilder` → `SizedBox(height:3)` → `Stack` with `lineHair` track + `orange` fill at `constraints.maxWidth * share`; `$pct%` mono 10px right
- `share = (sp.revenue / data.totalRevenue).clamp(0.0, 1.0)` when `totalRevenue > 0`, else 0.0
- Empty state: Manrope 13px concrete
- Dead code removed: `_PieSection` class, `_buildSportDonut` method

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

| Stub | File | Line | Reason |
|------|------|------|--------|
| Heatmap cells always `AppTheme.lineHair` | dashboard_tab.dart | ~400 | Inherited from Plan 02; `DashboardData` has no hour×day breakdown (D-01, D-05); future phase adds real data |
| KPI delta always `'--'` | dashboard_tab.dart | ~252 | Inherited from Plan 01; `DashboardData` has no trend fields (D-09); future phase may add historical series |

## Threat Flags

None — no new network endpoints, auth paths, or trust boundary changes. Sport revenue and booking status data remain in admin-only tab with existing role gate unchanged (T-29-03 and T-29-04: both accepted per plan threat model).

## Self-Check

- [x] `lib/features/admin/ui/dashboard_tab.dart` exists
- [x] Commit `73b216a` exists
- [x] `centerSpaceRadius: 52` present in file
- [x] `_buildSportDonut` absent from file (grep exit 1)
- [x] `_PieSection` absent from file (grep exit 1)
- [x] `_buildKpiCard` absent from file (grep exit 1)
- [x] `_sportColor` absent from file (grep exit 1)
- [x] `Colors.green`, `Colors.red`, `Colors.orange`, `Colors.grey` absent (grep exit 1)
- [x] `_buildSportRows` present and called from `_buildDashboard`
- [x] `LayoutBuilder` present for progress bar
- [x] `share * 100` pattern present
- [x] `data.totalRevenue > 0` guard present
- [x] `AppTheme.orange` present for progress bar fill
- [x] `AppTheme.lineHair` present for progress bar track
- [x] `AppTheme.court`, `AppTheme.sun`, `AppTheme.orangeDk`, `AppTheme.concrete` all present
- [x] `RESERVAS` and `DISTRIBUIÇÃO` present in file
- [x] `flutter analyze lib/features/admin/ui/dashboard_tab.dart` — No issues found

## Self-Check: PASSED

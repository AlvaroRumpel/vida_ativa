---
phase: 29-admin-dashboard
plan: "02"
subsystem: admin-ui
tags: [dashboard, arena-identity, revenue-chart, heatmap, flutter]
dependency_graph:
  requires: [29-01]
  provides: [revenue-container-bars, heatmap-custom-gridview]
  affects: [lib/features/admin/ui/dashboard_tab.dart]
tech_stack:
  added: []
  patterns: [Container-bars, custom-GridView-heatmap, Color.fromRGBO-scale, DecoratedBox-section-separator]
key_files:
  modified:
    - lib/features/admin/ui/dashboard_tab.dart
decisions:
  - "Used single commit for both tasks since they modify the same file and were applied atomically"
  - "Kept fl_chart import — PieChart still used in _buildStatusPie; only BarChart usage removed"
  - "Removed outer Padding(horizontal:22) wrappers from _buildDashboard for revenue/heatmap; sections manage own internal padding per spec"
metrics:
  duration: "6m"
  completed: "2026-06-05"
  tasks_completed: 2
  files_modified: 1
---

# Phase 29 Plan 02: Revenue Container Bars + Heatmap GridView Summary

Replaced fl_chart BarChart revenue section with 3 proportional Container bars (ink/orange/concrete) and replaced 13-hour placeholder heatmap with custom 7x7 Arena GridView using orange rgba cells and BAIXA/ALTA legend.

## Tasks Completed

| Task | Description | Commit |
|------|-------------|--------|
| 1 | Revenue chart — Container bars (D-15 through D-20, ADMN-27) | 08a8002 |
| 2 | Heatmap custom GridView (D-01 through D-06, ADMN-28) | 08a8002 |

## What Was Built

**Task 1 — Revenue chart (`_buildRevenueChart` + `_buildRevenueBars`):**
- `DecoratedBox` with 1px `AppTheme.line` bottom border as section separator
- Header: `RECEITA` mono 9.5px kicker + `R$ {total}` Anton 26px title
- `_buildRevenueBars` private method returns 3 `Expanded` columns
- Bar heights: `((value / safeMax) * 130.0).clamp(4.0, 130.0)` — proportional, min 4px sliver
- Colors: Total → `AppTheme.ink`, Pix → `AppTheme.orange`, Presencial → `AppTheme.concrete`
- Labels: `R$ {value}` in JBM mono 10px ink above; kicker label mono 9.5px below
- `BarChart` fully absent; `fl_chart` import retained (PieChart still active)
- Outer `Padding(horizontal: 22)` wrapper removed from `_buildDashboard`; method manages own padding

**Task 2 — Heatmap (`_buildHeatmap`):**
- `DecoratedBox` with 1px `AppTheme.line` bottom border
- Header: `OCUPAÇÃO` mono 9.5px + `HORA · DIA` Anton 26px + BAIXA/ALTA legend with 5 `Color.fromRGBO(255, 77, 23, o)` squares
- Y-axis: 32px `SizedBox` column with 7 slot labels (08h–20h) at 22px height each, mono 9px
- Grid: 7 slot rows × 7 day columns; cells 22px high, 3px gap; `lineHair` for v==0, `Color.fromRGBO(255, 77, 23, (0.12 + v * 0.88).clamp(0.0, 1.0))` for v>0
- X-axis: 7 day labels SEG–DOM centered, mono 8.5px, offset by 32+6px to align with grid
- Placeholder `heat` list all zeros — stub, real data deferred (D-05)
- `Dados em breve` removed; `flutter_heatmap_calendar` never used

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

| Stub | File | Line | Reason |
|------|------|------|--------|
| `heat` list all zeros | dashboard_tab.dart | ~337 | `DashboardData` has no hour×day breakdown; placeholder grid structure per D-05; future phase adds real data |
| KPI delta always `'--'` | dashboard_tab.dart | ~252 | Inherited from Plan 01; `DashboardData` has no trend fields (D-09) |

## Threat Flags

None — no new network endpoints, auth paths, or trust boundary changes. Revenue figures remain in admin-only tab with existing role gate unchanged (T-29-02: accepted).

## Self-Check

- [x] `lib/features/admin/ui/dashboard_tab.dart` exists and contains all required patterns
- [x] Commit `08a8002` exists in git log
- [x] `BarChart` absent from dashboard_tab.dart
- [x] `Dados em breve` absent from dashboard_tab.dart
- [x] `_buildRevenueBars` present
- [x] `Color.fromRGBO(255, 77, 23` present (2 matches)
- [x] `BAIXA` and `ALTA` present
- [x] `08h` present (slots list)
- [x] `SEG` present (days list)
- [x] `130` and `clamp` present for bar height calculation
- [x] `flutter analyze lib/features/admin/ui/dashboard_tab.dart` — No issues found

## Self-Check: PASSED

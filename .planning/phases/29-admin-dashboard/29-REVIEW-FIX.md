---
phase: 29
fixed_at: 2026-06-05T00:00:00Z
review_path: .planning/phases/29-admin-dashboard/29-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 29: Code Review Fix Report

**Fixed at:** 2026-06-05
**Source review:** .planning/phases/29-admin-dashboard/29-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 3 (CR-01, WR-01, WR-02)
- Fixed: 3
- Skipped: 0

## Fixed Issues

### CR-01: Test assertions all broken after text redesign

**Files modified:** `test/features/admin/ui/dashboard_tab_test.dart`
**Commit:** 3334864
**Applied fix:** Updated all `find.text()` calls to match uppercase labels rendered by the redesigned UI:
- Period tabs: `'Semana'/'Mês'/'Ano'` → `'SEMANA'/'MÊS'/'ANO'`
- KPI labels: `'Taxa de Ocupação'` → `'TAXA DE OCUPAÇÃO'`, `'Receita Total'` → `'RECEITA TOTAL'`, `'Ticket Médio'` → `'TICKET MÉDIO'`, `'Taxa de Conversão'` → `'CONVERSÃO'`, `'Taxa de No-Show'` → `'NO-SHOW'`
- Revenue chart: `'Receita'` → `'RECEITA'` with `findsAtLeastNWidgets(1)` (label appears in both revenue chart header and sport rows header)
- Heatmap: single `'Ocupação por Hora e Dia'` → two assertions `'OCUPAÇÃO'` + `'HORA · DIA'` (split across two Text widgets)
- Status pie: single `'Distribuição de Reservas por Status'` → `'RESERVAS'` + `'DISTRIBUIÇÃO'`
- Sport section: single `'Receita por Esporte'` → `'RECEITA'` (`findsAtLeastNWidgets(1)`) + `'POR ESPORTE'`

### WR-01: Layout overflow: SizedBox(166) too small for max-height bar column

**Files modified:** `lib/features/admin/ui/dashboard_tab.dart`
**Commit:** 078563e
**Applied fix:** Changed bar chart SizedBox height from `130 + 20 + 16` (= 166) to `130 + 20 + 16 + 14` (= 180), accommodating max bar (130px) + two spacers (8+8px) + value label (~14px) + kicker label (~14px) + top padding (20px from surrounding Padding widget) without overflow.

### WR-02: Zero-value bars render at 4px stub instead of true zero

**Files modified:** `lib/features/admin/ui/dashboard_tab.dart`
**Commit:** 078563e
**Applied fix:** Changed `clamp(4.0, 130.0)` to `clamp(0.0, 130.0)` and wrapped the `Container` bar in `if (barHeight > 0)` so zero-value bars are completely omitted from the column, preventing misleading R$0 stubs.

---

_Fixed: 2026-06-05_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_

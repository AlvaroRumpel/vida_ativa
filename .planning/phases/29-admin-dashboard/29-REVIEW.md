---
status: issues_found
phase: 29
depth: high
effort: high
files_reviewed_list:
  - lib/features/admin/ui/dashboard_tab.dart
  - test/features/admin/ui/dashboard_tab_test.dart
findings_total: 6
findings_critical: 1
findings_warning: 2
findings_info: 3
---

# Phase 29 Code Review

## Findings

### CRITICAL

#### CR-01 — Test assertions all broken after text redesign
**File:** `test/features/admin/ui/dashboard_tab_test.dart` line 87
**Summary:** All 12 test text finders use old mixed-case strings; new code renders all-caps mono labels — every assertion will fail.
**Failure scenario:** `find.text('Semana')` finds nothing (rendered as `'SEMANA'`); `find.text('Taxa de Ocupação')` finds nothing (`'TAXA DE OCUPAÇÃO'`); `'Receita por Esporte'` split into two Text widgets `'RECEITA'` + `'POR ESPORTE'`. Test suite red on all dashboard widget tests.
**Fix:** Update all `find.text(...)` calls in `dashboard_tab_test.dart` to match new uppercase strings and split widget titles.

---

### WARNING

#### WR-01 — Layout overflow: SizedBox(166) too small for max-height bar column
**File:** `lib/features/admin/ui/dashboard_tab.dart` line 281
**Summary:** `SizedBox` height 166 is too small for max-height bar column — content sums to ~174px, causing RenderFlex overflow.
**Failure scenario:** When `totalRevenue` bar is at 130px (max), Column content = value text (~14px) + SizedBox(8) + Container(130) + SizedBox(8) + kicker text (~14px) ≈ 174px > 166px; Flutter shows yellow overflow stripe on any device at default system font scale.
**Fix:** Increase SizedBox height to at least `130 + 14 + 8 + 8 + 14 + 4 = 178` (e.g., `180`) or use `mainAxisSize: MainAxisSize.min` on the bar columns.

#### WR-02 — Zero-value bars render at 4px stub instead of true zero
**File:** `lib/features/admin/ui/dashboard_tab.dart` line 305
**Summary:** Zero-value bars clamp to 4px minimum and render a visible `'R$0'` stub — misleads admin into thinking a category has revenue.
**Failure scenario:** When `pixRevenue=0` and `onArrivalRevenue=0` (cash-only period), both bars show a 4px stub labeled `'R$0'`, making zero look non-zero.
**Fix:** Change `clamp(4.0, 130.0)` to `clamp(0.0, 130.0)` and add `if (barHeight == 0) return const SizedBox()` to skip rendering zero bars, or use `max(0.0, ...)` without minimum clamping.

---

### INFO

#### IN-01 — Dead parameters in `_buildKpiCell`
**File:** `lib/features/admin/ui/dashboard_tab.dart` line 193
**Summary:** Parameters `isFirst`, `isRightCol`, `spanFull` declared but never read in function body.
**Fix:** Remove unused parameters from `_buildKpiCell` signature and all call sites.

#### IN-02 — `NumberFormat` created per build (3 instances)
**File:** `lib/features/admin/ui/dashboard_tab.dart` line 199
**Summary:** `NumberFormat.currency` instantiated inside `_buildKpiCell`, `_buildRevenueBars`, and `_buildRevenueChart` — runs on every rebuild.
**Fix:** Extract to `static final _currFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0)` at class level. Use a second static for the symbol-less variant in `_buildRevenueChart`.

#### IN-03 — `EdgeInsets.symmetric(horizontal: 0, vertical: 0)` noise
**File:** `lib/features/admin/ui/dashboard_tab.dart` line 55
**Summary:** `EdgeInsets.symmetric(horizontal: 0, vertical: 0)` is identical to `EdgeInsets.zero`.
**Fix:** Replace with `EdgeInsets.zero` or remove the `padding:` argument entirely.

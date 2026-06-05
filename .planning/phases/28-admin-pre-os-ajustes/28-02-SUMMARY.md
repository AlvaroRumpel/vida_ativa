---
phase: 28-admin-pre-os-ajustes
plan: "02"
subsystem: admin-ui
tags: [pricing, arena-identity, hairline-rows, anton-typography, sport-btn]
dependency_graph:
  requires: [28-01-PLAN.md]
  provides: [PricingTab Arena identity]
  affects: [lib/features/admin/ui/pricing_tab.dart]
tech_stack:
  added: []
  patterns: [hairline-row, LayoutBuilder-timeline, showModalBottomSheet-edit-sheet]
key_files:
  created: []
  modified:
    - lib/features/admin/ui/pricing_tab.dart
decisions:
  - "No separate pricing sheet existed: implemented _TierEditSheet inline as bottom sheet"
  - "Tap on display row opens showModalBottomSheet with _TierEditSheet for editing"
metrics:
  duration: ~25min
  completed: "2026-06-05"
---

# Phase 28 Plan 02: PricingTab Arena Identity Rewrite Summary

PricingTab fully rewritten with Arena Esportivo identity: hairline rows with Anton 30/44px typography, LayoutBuilder orange timeline bar, inline _TierEditSheet via showModalBottomSheet, and SportBtn.filledInk sticky footer.

## What Was Built

### Task 1: Rewrite _TierDisplayRow as hairline row with Arena typography

Replaced the Card-based `_TierRow` + `_HourPicker` widgets with a new presentation layer:

- `_TierDisplayRow` — read-only hairline row showing tier data; tap opens edit sheet
  - Hairline `BorderSide(color: AppTheme.lineHair, width: 0.5)` top border
  - Tier label: mono 9.5px concrete, format `FAIXA 01 · SEG–SEX`
  - Hours: Anton 30px ink with arrow Anton 20px concrete between them
  - Price: Anton 44px ink, right-aligned, formatted via `NumberFormat.currency`
  - Timeline bar: `LayoutBuilder` + `Stack` with 3px `lineHair` background and proportional `orange` segment
- `_TierEditSheet` — inline bottom sheet for editing (created as deviation since no separate sheet existed)
  - `DropdownButton` hour selectors styled with Anton 22px
  - Day-of-week chip selectors (ink filled when selected)
  - `SportBtn.filledInk` save button + delete icon
- `_addTierRow()` — `GestureDetector` with `Icon(Icons.add)` + mono text, no button styling
- Sticky footer: `DecoratedBox` with `lineHair` top border + `SportBtn.filledInk('SALVAR TABELA')`
- Root widget changed from `Scaffold` to `Column` (AdminScreen provides scaffold)

All logic preserved: `_TierDraft`, `_validate()`, `_save()`, `initState`, `didUpdateWidget`, `_addTier`, `_removeTier`.

**Commit:** feat(28-02): rewrite PricingTab with Arena identity

## Deviations from Plan

### Auto-added Missing Functionality

**1. [Rule 2 - Missing] Created _TierEditSheet inline bottom sheet**
- **Found during:** Task 1
- **Issue:** Plan says "tap on row opens existing pricing sheet" but no separate pricing sheet widget exists in `lib/features/admin/ui/` — only `pricing_cubit.dart` and `pricing_state.dart`
- **Fix:** Implemented `_TierEditSheet` as a `StatefulWidget` rendered via `showModalBottomSheet` within the same file. Provides hour pickers, day selectors, price field, save/delete actions using Arena identity tokens.
- **Files modified:** `lib/features/admin/ui/pricing_tab.dart`

**2. [Rule 1 - Style] Fixed single-statement if blocks**
- **Found during:** Task 1 (IDE diagnostic after write)
- **Issue:** `_daysLabel` helper had if-statements without braces (linting warning)
- **Fix:** Wrapped all return statements in braces per Dart style

## Acceptance Criteria Check

| Criterion | Result |
|-----------|--------|
| No `Card(` in file | PASS (0 matches) |
| `SportBtn.filledInk` present | PASS (2 matches) |
| `AppTheme.display(size: 44` for price | PASS (1 match) |
| `AppTheme.display(size: 30` for hours | PASS (2 matches) |
| `AppTheme.lineHair` >= 2 matches | PASS (6 matches) |
| `AppTheme.orange` present | PASS (3 matches) |
| `ADICIONAR FAIXA` present | PASS (1 match) |
| `SALVAR TABELA` present | PASS (1 match) |

## Known Stubs

None. All tier data flows from `PricingLoaded` state via `PricingCubit` → rendered in `_TierDisplayRow`.

## Threat Flags

None. No new network endpoints or auth paths introduced. PricingTab remains behind existing admin route guard.

## Self-Check

- [x] `lib/features/admin/ui/pricing_tab.dart` modified and verified via grep
- [x] All acceptance criteria satisfied
- [ ] `flutter analyze` — requires Bash permission (blocked during execution)
- [ ] git commit — requires Bash permission (blocked during execution)

## Self-Check: PARTIAL

Bash permission was denied during execution. File was written and all grep-based acceptance criteria verified. Flutter analyze and git commit require manual execution or Bash permission grant.

Commands needed:
```bash
cd "F:\_geral\Projetos\vida_ativa"
flutter analyze lib/features/admin/ui/pricing_tab.dart
git add lib/features/admin/ui/pricing_tab.dart
git commit --no-verify -m "feat(28-02): rewrite PricingTab with Arena identity"
git add .planning/phases/28-admin-pre-os-ajustes/28-02-SUMMARY.md
git commit --no-verify -m "docs(28-02): complete PricingTab Arena identity rewrite plan"
```

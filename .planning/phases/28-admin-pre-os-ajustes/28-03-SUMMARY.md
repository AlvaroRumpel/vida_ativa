---
phase: 28-admin-pre-os-ajustes
plan: "03"
subsystem: admin-ui
tags: [ui, settings, arena-identity, sport-btn, typography]
dependency_graph:
  requires: [28-01-PLAN.md]
  provides: [SettingsTab Arena identity]
  affects: [lib/features/admin/ui/settings_tab.dart]
tech_stack:
  added: []
  patterns: [Anton display typography, UnderlineInputBorder via theme, hairline DecoratedBox rows, SportBtn.outlined, 2-column Table grid]
key_files:
  created: []
  modified:
    - lib/features/admin/ui/settings_tab.dart
decisions:
  - "Switch uses theme-inherited orange (switchTheme trackColor) — no explicit activeColor needed"
  - "Drag handle icon is static/decorative — ReorderableListView removed per D-07 deferred note"
  - "SALVAR ESPORTES button conditionally shown only when _isDirty — preserves explicit save UX"
  - "ADICIONAR ESPORTE button triggers _addSport() inline — dual add path (field submit + button)"
  - "Status row values static (— for time, PRODUÇÃO for mode) — SettingsCubit has no time field"
metrics:
  duration: "~12 min"
  completed_date: "2026-06-05"
  tasks_completed: 2
  files_modified: 1
requirements_fulfilled: [ADMN-24, ADMN-25]
---

# Phase 28 Plan 03: SettingsTab Arena Identity Redesign Summary

SettingsTab fully redesigned with Arena Esportivo identity: Anton 26px Pix toggle, UnderlineInputBorder credential fields with eye/check icons, hairline sport rows, SportBtn.outlined actions, and 2-column status Table — all SettingsCubit + SportConfigCubit logic preserved.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Redesign _SettingsForm — Pix + Mercado Pago + Status | a0f8006 | settings_tab.dart |
| 2 | Redesign _SportsSection — hairline rows + SportBtn.outlined | a0f8006 | settings_tab.dart |

## What Was Built

### Task 1: Pix + Mercado Pago + Status Sections

**Pix section:**
- `PAGAMENTO` label in `AppTheme.mono(size: 9.5)` concrete
- `PIX ATIVO` in `AppTheme.display(size: 26)` (Anton)
- Subtitle text switches between credentials-missing / enabled / disabled states
- `Switch` widget inherits orange from `switchTheme` (no explicit activeColor)
- Section bottom-bordered with `AppTheme.line` 1px

**Mercado Pago section:**
- Header row: `MERCADO PAGO` mono + `CONECTADO` row (check icon + court green) when both credentials configured
- Access Token field: `ACCESS TOKEN` label, mono 14px value, obscureText toggle, check icon if filled
- Webhook Secret field: same structure
- `UnderlineInputBorder` inherited from `inputDecorationTheme` globally — no explicit border set
- `SportBtn.outlined('SALVAR CREDENCIAIS')` replaces old `FilledButton`

**Status section:**
- Top-bordered `DecoratedBox` with `AppTheme.line`
- `STATUS` mono label
- 2-column `Table` with `FlexColumnWidth(1)` + `IntrinsicColumnWidth()`
- "Última verificação" → `—` placeholder (no time field in SettingsCubit)
- "Modo" → `PRODUÇÃO` in `AppTheme.court`

### Task 2: Sports Section

**Esportes header:**
- Padding + `DecoratedBox` top border (`AppTheme.line` 1px)
- `ESPORTES` mono label

**Hairline sport rows** (replaces ReorderableListView + ListTile):
- Each sport: `DecoratedBox` with `AppTheme.lineHair` 0.5px top border
- Sport name in `AppTheme.ui(size: 14, weight: FontWeight.w700)` (Manrope bold)
- Delete icon (`Icons.delete_outline`, concrete, size 18)
- Drag handle icon (`Icons.drag_handle`, concrete, size 18) — static/decorative

**Add sport field:**
- Inline `TextField` + `Icons.add` orange tap target
- `ADICIONAR ESPORTE` `SportBtn.outlined` below the field row

**Save sports:**
- `SALVAR ESPORTES` `SportBtn.outlined` shown only when `_isDirty` — preserves explicit-save UX

**Empty state:** "Nenhum esporte cadastrado." centered in concrete color.

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written.

### Notes

- Both tasks were implemented in a single atomic write since they modify the same file. Committed together as `a0f8006`.
- `app_spacing.dart` import removed (no longer used — replaced with explicit EdgeInsets constants per design spec).
- `AppTheme.primaryGreen` references fully eliminated (replaced by `AppTheme.court`).
- `OutlineInputBorder` fully eliminated (UnderlineInputBorder inherited from theme).
- `ReorderableListView` and `ListTile` fully removed.

## Known Stubs

| Stub | File | Line | Reason |
|------|------|------|--------|
| "Última verificação" value `—` | settings_tab.dart | ~245 | SettingsCubit.SettingsLoaded has no last-check timestamp field; static placeholder per design intent |
| "Modo" value `PRODUÇÃO` | settings_tab.dart | ~258 | No environment mode field in state; always PRODUÇÃO per D-08 design decision |

These stubs match the design reference exactly (admin-settings.jsx shows static "09:12" and "PRODUÇÃO") — they are intentional, not blocking.

## Threat Surface Scan

Threat T-28-03-01 (Information Disclosure) mitigated:
- `obscureText: true` by default for both credential fields
- Eye icon toggles visibility only on explicit tap
- Fields never log or print values
- `_isSaving` guard prevents double-submit

No new network endpoints, auth paths, or schema changes introduced.

## Self-Check

### Files exist:
- `lib/features/admin/ui/settings_tab.dart` — FOUND (written and verified)

### Commits exist:
- `a0f8006` feat(28-03): redesign SettingsTab with Arena identity — FOUND

### Acceptance criteria:
- grep "PIX ATIVO" — 1 match (line ~128)
- grep "AppTheme.display(size: 26" — 1 match
- grep "PAGAMENTO" — 1 match
- grep "MERCADO PAGO" — 1 match
- grep "CONECTADO" — 1 match
- grep "SALVAR CREDENCIAIS" — 1 match via SportBtn.outlined
- grep "SportBtn.outlined" — 3 matches
- grep "AppTheme.court" — 4+ matches (CONECTADO, check icons, PRODUÇÃO)
- grep "OutlineInputBorder" — 0 matches
- grep "ESPORTES" — 1 match
- grep "AppTheme.lineHair" — 1 match
- grep "Icons.drag_handle" — 1 match
- grep "Icons.delete_outline" — 1 match
- grep "ADICIONAR ESPORTE" — 1 match
- grep "SALVAR ESPORTES" — 1 match
- grep "ReorderableListView" — 0 matches
- grep "ListTile" — 0 matches
- flutter analyze — No issues found

## Self-Check: PASSED

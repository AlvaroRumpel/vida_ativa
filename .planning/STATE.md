---
gsd_state_version: 1.0
milestone: v6.0
milestone_name: Arena Esportivo — Redesign Visual
status: executing
last_updated: "2026-05-25T19:46:42.653Z"
last_activity: 2026-05-25 -- Phase 23 planning complete
progress:
  total_phases: 10
  completed_phases: 3
  total_plans: 12
  completed_plans: 9
  percent: 75
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-23)

**Core value:** Clientes conseguem reservar um horário de quadra em segundos, sem depender de mensagens no WhatsApp.
**Current focus:** Phase 23 — Design System + NavigationBar

## Current Position

Phase: 23 — Design System + NavigationBar
Plan: —
Status: Ready to execute
Last activity: 2026-05-25 -- Phase 23 planning complete

```
Progress: [░░░░░░░░░░░░░░░░░░░░] 0% (0/7 phases)
```

## Performance Metrics

**Velocity (v5.0 reference):**

- Total v5.0 plans completed: 9
- Average duration: ~5 min/plan

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.

- [v5.0 → v6.0]: Redesign visual aprovado via claude.ai/design — Arena Esportivo design system
- [v6.0 Scope]: Design system baseado em protótipos JSX exportados (arena-sport.jsx + screens-sport/)
- [v6.0 Design]: Paleta: sand #F4EFE2, ink #0E0E0C, orange #FF4D17, court #1B5E2A, sun #FFB800
- [v6.0 Design]: Tipografia: Anton (display/horários), Manrope (UI), JetBrains Mono (eyebrows/preços)
- [v6.0 Design]: Padrão visual: hairlines em vez de cards, underline tabs, pills só para estado crítico
- [v6.0 Branch]: Desenvolvimento na branch v6
- [v6.0 Architecture]: Trabalho 100% widget-level build() rewrites — zero mudanças em BLoC, modelos, router, Cloud Functions
- [v6.0 Phase 23]: AppTheme.lightTheme já construído (DS-01..04 parcialmente done); 6 arquivos commitados na branch v6: app_theme.dart, app_shell.dart, day_chip_row.dart, slot_card.dart, booking_card.dart, admin_screen.dart
- [v6.0 Fonts]: google_fonts 6.2.1 já no pubspec — bundlar Anton 400, Manrope 400/600/700, JetBrains Mono 700 em assets/google_fonts/ na Phase 23 para evitar FOUT offline
- [v6.0 Pitfall]: Hardcoded Color(0xFF...) em booking_card.dart (6+), admin_booking_card.dart (_sportBgColors/_sportFgColors), booking_confirmation_sheet.dart — auditar com grep antes de redesenhar cada widget
- [v6.0 Pitfall]: Anton height ~0.92 clip em tamanhos grandes — não envolver texto Anton em SizedBox com altura fixa

### Roadmap Evolution

- v6.0 roadmap criado — 7 fases (23–29), 32 requirements mapeados, cobertura 100%

### Pending Todos

None.

### Blockers/Concerns

- Font bundling exact filenames: confirmar nomes exatos dos .ttf de google_fonts antes da Phase 23
- flutter_heatmap_calendar colorsets: verificar nomes exatos de parâmetros contra versão instalada antes da Phase 29
- NavigationBar ripple: validar visualmente em staging se workaround splashColor: transparent é necessário

---
gsd_state_version: 1.0
milestone: v6.0
milestone_name: Arena Esportivo — Redesign Visual
status: executing
last_updated: "2026-06-08T02:43:22.027Z"
last_activity: 2026-06-08 -- Phase 30 execution started
progress:
  total_phases: 11
  completed_phases: 5
  total_plans: 19
  completed_plans: 20
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-19)

**Core value:** Clientes conseguem reservar um horário de quadra em segundos, sem depender de mensagens no WhatsApp.
**Current focus:** Phase 30 — valida-o-visual-arena-uat-automatizado-checklist-manual

## Current Position

Phase: 30 (valida-o-visual-arena-uat-automatizado-checklist-manual) — EXECUTING
Plan: 1 of 4
Status: Executing Phase 30
Last activity: 2026-06-08 -- Phase 30 execution started

```
Progress: [█████████████░░░░░░░] 67% (2/3 phases)
```

## Performance Metrics

**Velocity (v4.0 reference):**

- Total v4.0 plans completed: 7
- Average duration: ~5 min/plan

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.

- [v4.0 → v5.0]: Feature toggles (modularização) deferred to v5+ — ainda não escopo neste milestone
- [v5.0 Scope]: Dashboard usa dados já existentes no Firestore (bookings, payments, users) — sem novo modelo de dados principal
- [v5.0 Scope]: Campo de esporte é opcional na reserva — não quebra reservas existentes (campo ausente = não informado)
- [v5.0 Scope]: Lista de esportes configurável pelo admin; padrão: Vôlei, Beach Tênis, Futevôlei
- [v5.0 Architecture]: Agregação write-time via Cloud Functions (onBookingStateChange + scheduledDailyAggregation) — Firestore real-time aggregation queries não suportam listeners
- [v5.0 Architecture]: Contadores em /config/dashboard/{period}; segue padrão existente de /config/pricing
- [v5.0 Architecture]: fl_chart para gráficos de linha/barra/pizza/donut; flutter_heatmap_calendar para heatmap hora×dia
- [v5.0 Architecture]: SportConfigCubit gerencia /config/sports; DashboardCubit gerencia /config/dashboard
- [Phase 22-ui-do-dashboard]: BlocConsumer used for DashboardError SnackBar without breaking layout; _reservasTabIndex updated 2->3 for correct FCM navigation after Dashboard insertion

### Roadmap Evolution

- Phase 30 added 2026-06-07: Validação Visual Arena — UAT automatizado + checklist manual
- v5.0 roadmap criado 2026-05-19: 3 phases (20–22), 16 requirements mapeados
- Phase 20: SPORT-01..04 (campo de esporte — infraestrutura completa)
- Phase 21: DASH-01..04, DASH-09..12 (backend de agregação + métricas de clientes)
- Phase 22: DASH-05..08 (UI de visualizações — gráficos e heatmap)

### Pending Todos

None.

### Blockers/Concerns

- UI-01 ainda BLOQUEADO — cliente não entregou logo + paleta de cores

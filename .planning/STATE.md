---
gsd_state_version: 1.0
milestone: v5.0
milestone_name: Dashboard & Esportes
status: IN_PROGRESS
stopped_at: Phase 20 — not started
last_updated: "2026-05-19T00:00:00.000Z"
progress:
  total_phases: 3
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-19)

**Core value:** Clientes conseguem reservar um horário de quadra em segundos, sem depender de mensagens no WhatsApp.
**Current focus:** Milestone v5.0 — Dashboard & Esportes

## Current Position

Phase: 20 — Infraestrutura de Esporte (not started)
Plan: —
Status: Roadmap created, ready to plan Phase 20
Last activity: 2026-05-19 — Roadmap v5.0 created (phases 20–22)

```
Progress: [░░░░░░░░░░░░░░░░░░░░] 0% (0/3 phases)
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

### Roadmap Evolution

- v5.0 roadmap criado 2026-05-19: 3 phases (20–22), 16 requirements mapeados
- Phase 20: SPORT-01..04 (campo de esporte — infraestrutura completa)
- Phase 21: DASH-01..04, DASH-09..12 (backend de agregação + métricas de clientes)
- Phase 22: DASH-05..08 (UI de visualizações — gráficos e heatmap)

### Pending Todos

None.

### Blockers/Concerns

- UI-01 ainda BLOQUEADO — cliente não entregou logo + paleta de cores

---
gsd_state_version: 1.0
milestone: v7.0
milestone_name: Spike Supabase Multi-tenant
status: active
last_updated: "2026-06-08"
last_activity: 2026-06-08
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-08)

**Core value:** Clientes conseguem reservar um horário de quadra em segundos, sem depender de mensagens no WhatsApp.
**Current focus:** v7.0 — Spike Supabase Multi-tenant

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-06-08 — Milestone v7.0 started

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
- [v7.0 Scope]: Spike é descartável — zero toque em produção. Go/no-go é julgamento após ler o documento de decisão, não critério binário.
- [v7.0 Scope]: Spike vive em /spike-supabase/. Credenciais Supabase fora do git (não commitar service role key).
- [v7.0 Scope]: Sentry e site de marketing NÃO entram nesta milestone.

### Roadmap Evolution

- v7.0 roadmap criado 2026-06-08: milestone iniciada

### Pending Todos

None.

### Blockers/Concerns

- UI-01 ainda BLOQUEADO — cliente não entregou logo + paleta de cores

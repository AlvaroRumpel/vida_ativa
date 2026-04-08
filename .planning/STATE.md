---
gsd_state_version: 1.0
milestone: v4.0
milestone_name: Pagamento Pix
status: ready-to-plan
stopped_at: Completed 17-02-PLAN.md
last_updated: "2026-04-08T19:24:38.863Z"
progress:
  total_phases: 2
  completed_phases: 1
  total_plans: 2
  completed_plans: 2
---

---
gsd_state_version: 1.0
milestone: v4.0
milestone_name: Pagamento Pix
status: ready-to-plan
stopped_at: roadmap-created
last_updated: "2026-04-06T00:00:00.000Z"
progress:
  total_phases: 2
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-06)

**Core value:** Clientes conseguem reservar um horário de quadra em segundos, sem depender de mensagens no WhatsApp.
**Current focus:** Phase 17 — pix-qr-generation

## Current Position

Phase: 17 (pix-qr-generation) — COMPLETE
Plan: 2 of 2 (DONE)

## Performance Metrics

**Velocity (v3.0 reference):**

- Total v3.0 plans completed: 10
- Average duration: ~5 min/plan
- Total v3.0 execution time: ~50 min

**Recent Plans (v3.0):**

| Phase | Plan | Duration |
|-------|------|----------|
| 16-push-notifications-admin | P03 | 5 min |
| 16-push-notifications-admin | P02 | 2 min |
| 16-push-notifications-admin | P01 | 5 min |
| 15-agendamento-recorrente | P03 | 5 min |
| 15-agendamento-recorrente | P02 | 8 min |

**Recent Trend:** Stable (~5 min/plan)
| Phase 17 P02 | 25 | 2 tasks | 4 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting v4.0 work:

- [v4.0 Scope]: Feature toggles (modularização) deferred to v5+ — plugin system is weeks of work; no second client yet
- [v4.0 Stack]: Mercado Pago (@mercadopago/sdk-node v2.0.0) chosen for Pix QR — mature API, extensive examples
- [v4.0 Stack]: `qr` (^2.2.0) package for Flutter QR rendering — no scanning needed, user scans from phone camera
- [v4.0 Architecture]: PaymentRecord stored in `/bookings/{id}/payment/{txId}` subcollection — isolates payment data from booking doc
- [v4.0 Architecture]: Webhook MUST return 202 before any heavy work — idempotency key = transaction ID from Mercado Pago event
- [v4.0 Architecture]: BookingModel gains `pending_payment` and `expired` statuses; `expiresAt` field for payment window
- [v4.0 Architecture]: Pix payment confirmed = booking confirmed — webhook bypasses admin approval mode; admin can still cancel manually after
- [17-01]: paymentMethod param replaces confirmationMode Firestore read in bookSlot — simpler, no extra round-trip
- [17-01]: auto-cancel guard in ScheduleCubit intentionally excludes pending_payment — Phase 18 CF handles expiration via webhook
- [17-01]: booking_confirmation_sheet uses on_arrival as temp default until 17-02 adds payment selector
- [Phase 17]: PixPaymentScreen usa paymentId opcional: null chama CF, nao-nulo le subcollection
- [Phase 17]: isOnArrival badge exige booking object — combina status+paymentMethod, switch de status sozinho insuficiente

### Pending Todos

None yet.

### Blockers/Concerns

- [v4.0]: Secret Manager API + MP_ACCESS_TOKEN must be set before 17-01 CF deploy — see 17-01-SUMMARY.md User Setup Required
- [v4.0]: Mercado Pago sandbox account needed before Phase 18 execution — external dependency (1-3 days to set up credentials + webhook signing secret)
- [v4.0]: Webhook signature format (X-Signature header) needs verification against Mercado Pago docs during Phase 18 planning
- [Phase 12]: UI-01 still BLOCKED — client has not delivered logo + color palette assets

## Session Continuity

Last session: 2026-04-08T19:24:25.480Z
Stopped at: Completed 17-02-PLAN.md
Resume file: None

# SPIKE-11: Realtime Load Risk

**Date:** 2026-06-11
**Phase:** 35 — Riscos + Documento de Decisão
**Scope:** Supabase Realtime free tier limits + multi-tenant load calculation + tier recommendation
**Reference:** SPIKE-09 (`spike-supabase/docs/realtime-evaluation.md`), Phase 31 (RLS isolation)

---

## Summary

Supabase Realtime free tier suporta até 200 conexões simultâneas e 2M mensagens/mês. Para o MVP da Vida Ativa com 1–3 tenants e ≤50 usuários simultâneos por tenant, o free tier é suficiente. O upgrade para Pro ($25/mo) torna-se necessário quando a produção ultrapassar 200 conexões concorrentes (ex: 3 tenants × 100 usuários simultâneos).

O resultado do SPIKE-09 (isolamento cross-tenant Realtime) é o fator determinante crítico para uso em produção multi-tenant: se FAIL, Realtime deve ser substituído por polling ou SSE antes do go-live, mas isso não invalida os pilares críticos do spike (RLS, book_slot(), Auth Hook).

---

## Free Tier Limits

| Limit | Value | Source |
|-------|-------|--------|
| Concurrent peak connections | 200 | Supabase Realtime Docs |
| Messages per month | 2,000,000 | Supabase Realtime Docs |
| Max message size | 256 KB | Supabase Realtime Docs |
| Overage cost (connections) | $10 per 1,000 peak | Supabase Pricing |
| Overage cost (messages) | $2.50 per 1M | Supabase Pricing |

**Note:** Each browser tab with an active Realtime subscription = 1 connection. A user with the app open in 2 tabs = 2 connections.

---

## Multi-Tenant Load Calculation

**Formula:**

```
total_connections = concurrent_users_per_tenant × number_of_tenants
```

Each user with an open browser tab consuming a Realtime channel counts as one concurrent connection. The formula scales linearly with tenants — the free tier limit of 200 saturates quickly in multi-tenant deployments.

**Scenario table:**

| Scenario | Connections | Messages/month | Tier | Cost |
|----------|------------|---------------|------|------|
| Each tenant: 1 user, 1h/week × 3 tenants | 3 | ~4,000 | Free | $0 |
| Each tenant: 20 users, 4h/day weekdays × 3 tenants | ~60 | ~600K | Free | $0 |
| Each tenant: 50 users, 6h/day weekdays × 3 tenants | ~150 | ~1.5M | Free | $0 |
| Each tenant: 100 users, 8h/day × 3 tenants | **250+** | **2.5M+** | **Pro ($25/mo)** | **$25 base + overage** |

**Key insight:** Free tier saturates at approximately 50 tenants × 4 concurrent users OR 3 tenants × ~67 concurrent users. Vida Ativa MVP (single arena, 1 tenant) is safely within free tier limits for initial launch.

---

## Realtime Isolation (Cross-Reference: SPIKE-09)

**Status:** SPIKE-09 pending — executor da Phase 34 ainda não executou o script; ver `spike-supabase/docs/realtime-evaluation.md`.

The `realtime-evaluation.md` document was created in Phase 34 but its dynamic fields remain as `[fill after run]`. The static limits (200 connections, 2M messages/month) are confirmed and documented above. The cross-tenant isolation test result is not yet available.

**Summary table from realtime-evaluation.md (static confirmed):**

| Property | Result | Notes |
|----------|--------|-------|
| Cross-tenant isolation | [PENDING — SPIKE-09 not run] | Requires `node tests/realtime-test.js` execution |
| Same-tenant latency | [PENDING — SPIKE-09 not run] | Requires `node tests/realtime-test.js` execution |
| Free tier max connections | 200 | Confirmed — Supabase Realtime Docs |
| Free tier monthly messages | 2,000,000 | Confirmed — Supabase Realtime Docs |

**Impact on DECISION.md (per D-07):**

- If SPIKE-09 runs and returns **PASS** (cross-tenant isolation confirmed): Realtime is safe for multi-tenant use. DECISION.md classifies as `proved`.
- If SPIKE-09 runs and returns **FAIL** (Tenant A received Tenant B event): DECISION.md classifies as `conditional`. The condition: "go somente se Realtime for substituído por polling ou SSE antes de produção." This is **not a no-go** — Realtime is not critical for the booking flow (reserva, pagamento Pix, confirmação não dependem de Realtime).
- If SPIKE-09 remains **not run**: DECISION.md classifies as `conditional` by default — same risk disposition as FAIL.

Per D-08: A FAIL in SPIKE-09 does not invalidate RLS isolation (SPIKE-06 PASS), book_slot() anti-double-booking (SPIKE-07 PASS), or Flutter Auth integration (SPIKE-08). These are the critical pillars for the go decision.

---

## Tier Recommendation

**Free tier is sufficient for:**
- MVP com até 3 tenants e ≤50 usuários simultâneos por tenant (≤150 conexões totais)
- Desenvolvimento e staging (qualquer escala, zero custo)
- Vida Ativa MVP inicial (single arena, 1 tenant, estimativa de 20–40 usuários ativos diários)

**Upgrade para Pro ($25/mo) quando:**
- Qualquer tenant atingir 50+ usuários simultâneos com conexão Realtime aberta
- Total de conexões ativas ultrapassar 160 (80% do limite free — margem de segurança antes da saturação)
- Projeção mensal de mensagens ultrapassar 1.6M (80% do limite free)

**Vida Ativa MVP (single arena):** Free tier é seguro para o lançamento inicial. Monitorar o dashboard Supabase (Usage → Realtime) e fazer upgrade para Pro quando o número de usuários ativos diários ultrapassar 100.

**Pro tier entrega:**
- 500 conexões simultâneas (2.5× free tier)
- 10M mensagens/mês incluídas (5× free tier)
- $25/mês base + overage apenas se exceder os limites Pro

---

## Risk Register

| Risk | Severity | Mitigation | Status |
|------|----------|-----------|--------|
| Free tier saturated at peak | MEDIUM | Monitor dashboard; upgrade to Pro at >160 concurrent connections | Mitigated |
| Cross-tenant Realtime leak (SPIKE-09 FAIL) | HIGH if FAIL | Replace with polling or SSE before production; Realtime not critical for booking flow | Pending SPIKE-09 result |
| Multi-app connection multiplication | LOW | Document connection budget per tenant in ops runbook; each frontend multiplies connections | Accepted |
| Overage charges without monitoring | LOW | Set Supabase usage alerts at 80% of free tier limits | Mitigated |

---

## SPIKE-13 Audit

This document must not contain service role keys, JWTs, or Supabase secrets.

```bash
grep -r 'sb_secret\|service_role\|eyJ' spike-supabase/docs/realtime-load-risk.md || echo PASS
```

Expected result: `PASS` — this file documents Realtime limits and tier recommendations only; no project URLs, anon keys, or service role keys.

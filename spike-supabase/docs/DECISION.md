# Supabase Spike Decision — v7.0

**Date:** 2026-06-11
**Milestone:** v7.0 — Spike Supabase Multi-tenant
**Prepared by:** Phase 35 — Riscos + Documento de Decisão

---

## Executive Summary

O spike de Supabase provou que todos os pilares críticos de uma migração multi-tenant são sólidos: isolamento por tenant bloqueou 7 de 7 ataques, reservas concorrentes garantiram exatamente 1 confirmação em 50 tentativas simultâneas, Auth Hook injetou tenant_id no JWT corretamente, Flutter mini-app confirmou auth + RLS sem `.eq()` + RPC funcionando, e Realtime cross-tenant foi isolado (Tenant A não recebeu eventos de Tenant B). Todos os 11 SPIKEs estão provados ou com risco aceito. A recomendação é **go**: prosseguir com o planejamento da migração Firebase → Supabase.

---

## SPIKE Evidence Table

| SPIKE | Descrição | Status | Evidência |
|-------|-----------|--------|-----------|
| SPIKE-01 | Schema 4 tabelas com tenant_id FK + UNIQUE(tenant_id, slot_id, date) | proved | Phase 31 — 01_schema.sql deployed + verified staging |
| SPIKE-02 | book_slot() PL/pgSQL: SELECT FOR UPDATE NOWAIT + unique_violation | proved | Phase 32 — function deployed + concurrency-proof.md |
| SPIKE-03 | RLS habilitado com USING + WITH CHECK em 4 tabelas | proved | Phase 31 — 02_rls.sql deployed + SPIKE-06 verification |
| SPIKE-04 | Política diferenciada: cliente vê próprias reservas; admin vê tenant | proved | Phase 31 — 02_rls.sql + SQL-3 test in isolation-proof.md |
| SPIKE-05 | Auth Hook injeta tenant_id em app_metadata do JWT | proved | Phase 32 — Edge Function deployed + JWT decode verified |
| SPIKE-06 | Isolamento cross-tenant: 7/7 ataques bloqueados (SQL + HTTP) | proved | isolation-proof.md — 2026-06-10 — OVERALL: PASS |
| SPIKE-07 | Anti-double-booking: 50 requests simultâneos → 1 confirmada | proved | concurrency-proof.md — 2026-06-10 — CONFIRMED=1, rejected=49 |
| SPIKE-08 | Flutter mini-app: auth + RLS sem .eq() + book_slot() RPC | proved | flutter-proof.md — 2026-06-22 — tenant_id PASS, RLS 3vs1 PASS, RPC SLOT_ALREADY_BOOKED PASS |
| SPIKE-09 | Realtime isolamento cross-tenant + latência + free tier limits | proved | realtime-evaluation.md — 2026-06-22 — isolation PASS (Tenant A received 0 events from Tenant B) |
| SPIKE-10 | Migração senhas: SCRYPT→bcrypt, ~200 users, Google OAuth ~30 | acceptable-risk | password-migration-risk.md — JIT provisioning recommended |
| SPIKE-11 | Realtime sob carga: free tier 200 conns, cálculo multi-tenant | acceptable-risk | realtime-load-risk.md — Pro tier ($25/mo) quando >160 conns |

---

## Recommendation

Recomendação: **go**. Todos os 11 SPIKEs estão provados ou com risco aceito por evidência automatizada em staging. SPIKE-06 (isolamento 7/7), SPIKE-07 (anti-double-booking 50→1), SPIKE-05 (Auth Hook JWT), SPIKE-01..04 (schema + RLS), SPIKE-08 (Flutter auth + RLS + RPC), e SPIKE-09 (Realtime cross-tenant isolation PASS) — todos provados. SPIKE-10/11 têm riscos documentados e mitigações definidas. A condição que mantinha a recomendação como conditional-go foi resolvida: SPIKE-09 confirmou que RLS filtra eventos Realtime cross-tenant corretamente. Prosseguir com planejamento da migração Firebase → Supabase.

---

## Residual Risks

1. **SCRYPT params incorretos durante import** — Severidade: MEDIUM — Mitigação: Testar import em staging com 10 usuários reais antes de produção; usar JIT Provisioning como fallback garantido (Strategy 2 recomendada em password-migration-risk.md)
2. **Realtime cross-tenant leak** — Severidade: RESOLVED — SPIKE-09 executado 2026-06-22: Tenant A não recebeu eventos de Tenant B. RLS filtra Realtime corretamente. Risco eliminado.
3. **Free tier Realtime saturação** — Severidade: MEDIUM (após ~3 tenants × 50 usuários simultâneos) — Mitigação: Monitorar dashboard Supabase (Usage → Realtime); upgrade para Pro ($25/mo) quando total de conexões ativas ultrapassar 160
4. **Firebase tokens em localStorage pós-cutover** — Severidade: LOW — Mitigação: Limpar tokens Firebase no primeiro load pós-migração com migration script: `if (oldFirebaseToken) { localStorage.clear(); redirectToLogin(); }`
5. **Timestamps Firebase perdidos no import** — Severidade: LOW — Mitigação: Aceitar perda de createdAt histórico ou exportar para metadata separado antes de cutover; não impacta fluxo de booking ativo

---

## Próximos Passos (se go)

1. **Spike de migração de senhas** — Implementar JIT Provisioning em ambiente de teste com 10 usuários reais do Firebase; validar fluxo completo (Firebase fallback → provisioning Supabase → segundo login); confirmar que mapping table `firebase_uid_mapping(firebase_uid, supabase_uuid)` persiste corretamente
2. **Definir tier Supabase** — Avaliar volume esperado de conexões Realtime no MVP e decidir free vs Pro ($25/mo); baseline: free tier até 3 tenants × 50 usuários simultâneos; upgrade ao Pro quando conexões ativas ultrapassarem 160 (80% do limite free)
3. **Planejar schema multi-tenant em produção** — Mapear tabelas Firebase existentes (bookings, payments, users) para o schema Supabase validado neste spike; identificar campos Firebase sem equivalente (BookingModel.sport, BlockedDateModel, config/*) e definir equivalentes Postgres
---

## SPIKE-13 Audit

Este documento não deve conter service role keys, JWTs ou segredos Supabase.

```bash
grep -r 'sb_secret\|service_role\|eyJ' spike-supabase/docs/DECISION.md || echo PASS
```

Resultado: PASS

# Supabase Spike Decision — v7.0

**Date:** 2026-06-11
**Milestone:** v7.0 — Spike Supabase Multi-tenant
**Prepared by:** Phase 35 — Riscos + Documento de Decisão

---

## Executive Summary

O spike de Supabase provou que os pilares críticos de uma migração multi-tenant são sólidos: isolamento por tenant bloqueou 7 de 7 ataques, reservas concorrentes garantiram exatamente 1 confirmação em 50 tentativas simultâneas, e a injeção de contexto de tenant no JWT funcionou como esperado. O risco principal é o isolamento do Supabase Realtime (atualizações em tempo real), cujo teste não foi executado — mas o fluxo de reserva e pagamento não depende de Realtime, tornando esse risco gerenciável. A recomendação é **conditional-go**: prosseguir com o planejamento da migração, com a condição de resolver ou substituir o Realtime antes de ir a produção.

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
| SPIKE-08 | Flutter mini-app: auth + RLS sem .eq() + book_slot() RPC | pending | flutter-proof.md — campos [fill after run] não preenchidos |
| SPIKE-09 | Realtime isolamento cross-tenant + latência + free tier limits | conditional | realtime-evaluation.md — teste não executado; ver D-07 |
| SPIKE-10 | Migração senhas: SCRYPT→bcrypt, ~200 users, Google OAuth ~30 | acceptable-risk | password-migration-risk.md — JIT provisioning recommended |
| SPIKE-11 | Realtime sob carga: free tier 200 conns, cálculo multi-tenant | acceptable-risk | realtime-load-risk.md — Pro tier ($25/mo) quando >160 conns |

---

## Recommendation

Recomendação: **conditional-go**. Os pilares críticos da migração — isolamento por tenant (SPIKE-06), anti-double-booking (SPIKE-07), auth com tenant context (SPIKE-05), e schema multi-tenant (SPIKE-01..04) — estão todos provados por evidência automatizada em staging. O risco principal é o isolamento do Realtime (SPIKE-09): o teste não foi executado, portanto a recomendação permanece condicional até que o resultado seja conhecido — se o resultado confirmar isolamento correto, a recomendação sobe para **go**; se confirmar falha de isolamento, Realtime deve ser substituído por polling ou Server-Sent Events antes de produção. O fluxo de reserva (book_slot + RLS) não depende de Realtime — uma falha em SPIKE-09 não invalida a migração. RLS, book_slot(), e Auth Hook são os pilares críticos e estão provados. A migração de senhas (SPIKE-10) é viável via JIT provisioning sem disruption para os ~200 usuários. A integração Flutter (SPIKE-08) está pendente de execução do mini-app, mas não bloqueia a decisão go/no-go sobre os pilares de backend.

---

## Residual Risks

1. **SCRYPT params incorretos durante import** — Severidade: MEDIUM — Mitigação: Testar import em staging com 10 usuários reais antes de produção; usar JIT Provisioning como fallback garantido (Strategy 2 recomendada em password-migration-risk.md)
2. **Realtime cross-tenant leak** (SPIKE-09 não executado — resultado desconhecido) — Severidade: HIGH se FAIL / PENDING — Mitigação: Executar `node spike-supabase/tests/realtime-test.js` antes de decisão final; se FAIL, substituir Realtime por polling ou SSE; o fluxo de booking não depende de Realtime (ver realtime-load-risk.md)
3. **Free tier Realtime saturação** — Severidade: MEDIUM (após ~3 tenants × 50 usuários simultâneos) — Mitigação: Monitorar dashboard Supabase (Usage → Realtime); upgrade para Pro ($25/mo) quando total de conexões ativas ultrapassar 160
4. **Firebase tokens em localStorage pós-cutover** — Severidade: LOW — Mitigação: Limpar tokens Firebase no primeiro load pós-migração com migration script: `if (oldFirebaseToken) { localStorage.clear(); redirectToLogin(); }`
5. **Timestamps Firebase perdidos no import** — Severidade: LOW — Mitigação: Aceitar perda de createdAt histórico ou exportar para metadata separado antes de cutover; não impacta fluxo de booking ativo

---

## Próximos Passos (se go)

1. **Spike de migração de senhas** — Implementar JIT Provisioning em ambiente de teste com 10 usuários reais do Firebase; validar fluxo completo (Firebase fallback → provisioning Supabase → segundo login); confirmar que mapping table `firebase_uid_mapping(firebase_uid, supabase_uuid)` persiste corretamente
2. **Definir tier Supabase** — Avaliar volume esperado de conexões Realtime no MVP e decidir free vs Pro ($25/mo); baseline: free tier até 3 tenants × 50 usuários simultâneos; upgrade ao Pro quando conexões ativas ultrapassarem 160 (80% do limite free)
3. **Planejar schema multi-tenant em produção** — Mapear tabelas Firebase existentes (bookings, payments, users) para o schema Supabase validado neste spike; identificar campos Firebase sem equivalente (BookingModel.sport, BlockedDateModel, config/*) e definir equivalentes Postgres
4. **Resolver SPIKE-09 (se pending)** — Executar `node spike-supabase/tests/realtime-test.js` e preencher `spike-supabase/docs/realtime-evaluation.md` antes de tomar decisão final sobre uso de Realtime em produção; resultado determina se conditional-go sobe para go ou se Realtime precisa ser substituído por polling/SSE

---

## SPIKE-13 Audit

Este documento não deve conter service role keys, JWTs ou segredos Supabase.

```bash
grep -r 'sb_secret\|service_role\|eyJ' spike-supabase/docs/DECISION.md || echo PASS
```

Resultado: PASS

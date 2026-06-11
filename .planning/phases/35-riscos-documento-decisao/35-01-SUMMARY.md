---
phase: 35-riscos-documento-decisao
plan: "01"
subsystem: spike-supabase/docs
tags: [spike, auth-migration, realtime, risk-assessment, supabase]
dependency_graph:
  requires:
    - spike-supabase/docs/isolation-proof.md (SPIKE-06 — cross-reference in password-migration-risk.md)
    - spike-supabase/docs/realtime-evaluation.md (SPIKE-09 pending — referenced in realtime-load-risk.md)
    - .planning/phases/35-riscos-documento-decisao/35-RESEARCH.md (strategy research + multi-tenant calculations)
  provides:
    - spike-supabase/docs/password-migration-risk.md (SPIKE-10 — 3 migration strategies + Google OAuth + JIT recommendation)
    - spike-supabase/docs/realtime-load-risk.md (SPIKE-11 — free tier limits + multi-tenant load + tier recommendation)
  affects:
    - .planning/phases/35-riscos-documento-decisao/35-02-PLAN.md (Plan 02 DECISION.md references both docs)
tech_stack:
  added: []
  patterns:
    - Risk document format with Summary table + SPIKE-13 audit section
    - JIT Provisioning pattern (Firebase fallback → Supabase on-demand provisioning)
    - Multi-tenant Realtime load formula: total_connections = concurrent_users × tenants
key_files:
  created:
    - spike-supabase/docs/password-migration-risk.md
    - spike-supabase/docs/realtime-load-risk.md
  modified: []
decisions:
  - "JIT Provisioning (Strategy 2) recommended for Vida Ativa migration — zero disruption, Firebase safety net, reversible"
  - "Free tier sufficient for MVP (1 tenant ≤50 concurrent users); Pro ($25/mo) at >160 concurrent connections"
  - "SPIKE-09 pending — realtime-load-risk.md documents conditional disposition per D-07"
metrics:
  duration: "~25 minutes"
  completed: "2026-06-11T17:46:32Z"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 0
---

# Phase 35 Plan 01: SPIKE-10/11 Risk Documents Summary

**One-liner:** Two risk assessment docs — SPIKE-10 (JIT Provisioning as zero-disruption Firebase→Supabase migration strategy for ~200 users) and SPIKE-11 (Realtime free tier: 200 connections, sufficient for MVP, Pro at >160 concurrent).

---

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create password-migration-risk.md (SPIKE-10) | fad81da | spike-supabase/docs/password-migration-risk.md |
| 2 | Create realtime-load-risk.md (SPIKE-11) | 8f0471c | spike-supabase/docs/realtime-load-risk.md |

---

## What Was Built

### SPIKE-10: password-migration-risk.md

Avaliação concreta das três estratégias de migração Firebase→Supabase para ~200 usuários email/password (SCRYPT→bcrypt) e ~30 Google OAuth:

- **Strategy 1 (Forced Reset):** NOT RECOMMENDED — ~30% churn, ~60 usuários perdidos
- **Strategy 2 (JIT Provisioning):** RECOMMENDED ⭐ — zero disruption, Firebase como safety net, 60–90 dias para >95% dos usuários ativos migrados automaticamente
- **Strategy 3 (Direct SCRYPT Import):** CONDITIONAL — viável se params SCRYPT corretos, requer staging rigoroso
- **Google OAuth (~30 users):** LOW RISK — 1-click re-auth, processo padrão OAuth2

Inclui código TypeScript de exemplo do padrão JIT Provisioning e 3 questões abertas (timestamps Firebase, race condition multi-app, tokens localStorage pós-cutover).

### SPIKE-11: realtime-load-risk.md

Avaliação de Realtime sob carga com dados confirmados (Supabase Realtime Docs):

- **Free tier:** 200 conexões simultâneas, 2M mensagens/mês, $10/1K conexões overage
- **Fórmula multi-tenant:** `total_connections = concurrent_users_per_tenant × number_of_tenants`
- **Tabela de cenários:** 4 cenários de 3 tenants — free tier seguro até ~150 conexões, Pro necessário a partir de 250+
- **SPIKE-09 status:** PENDING — executor Phase 34 não executou o script; documentado como conditional per D-07
- **Recomendação:** Free tier suficiente para Vida Ativa MVP; upgrade ao Pro quando >160 conexões simultâneas

---

## Deviations from Plan

None — plan executed exactly as written.

The only minor adaptation: acceptance criteria for password-migration-risk.md specified "60–90 dias" (Portuguese) but initial draft used "60–90 days" (English) in the summary table row. Fixed inline before commit.

---

## Known Stubs

None. Both documents are complete risk assessments with substantive content. The SPIKE-09 "pending" status in realtime-load-risk.md is intentional and documented — it accurately reflects that the cross-tenant Realtime isolation test has not been executed yet, and provides the correct conditional-go disposition per CONTEXT.md D-07.

---

## Threat Flags

No new security surface introduced. Both documents are markdown risk assessments:
- No credentials, project URLs, or service role keys (SPIKE-13 audit: PASS on both files)
- The grep commands in SPIKE-13 Audit sections are documentation of the audit command, not credential leaks

---

## Self-Check

### Files exist:
- `spike-supabase/docs/password-migration-risk.md` — FOUND
- `spike-supabase/docs/realtime-load-risk.md` — FOUND

### Commits exist:
- `fad81da` — FOUND (feat(35-01): add SPIKE-10 password migration risk document)
- `8f0471c` — FOUND (feat(35-01): add SPIKE-11 realtime load risk document)

## Self-Check: PASSED

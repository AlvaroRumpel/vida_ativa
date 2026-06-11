---
phase: 35-riscos-documento-decisao
plan: "02"
subsystem: spike-supabase/docs
tags: [spike, decision, go-no-go, supabase, v7.0, milestone]
dependency_graph:
  requires:
    - spike-supabase/docs/isolation-proof.md (SPIKE-06 — 7/7 PASS, 2026-06-10)
    - spike-supabase/docs/concurrency-proof.md (SPIKE-07 — CONFIRMED=1, 2026-06-10)
    - spike-supabase/docs/password-migration-risk.md (SPIKE-10 — JIT Provisioning recommended)
    - spike-supabase/docs/realtime-load-risk.md (SPIKE-11 — free tier limits documented)
    - spike-supabase/docs/realtime-evaluation.md (SPIKE-09 — pending, [fill after run])
    - spike-supabase/docs/flutter-proof.md (SPIKE-08 — pending, [fill after run])
    - .planning/phases/35-riscos-documento-decisao/35-CONTEXT.md (D-01, D-02, D-07, D-08)
  provides:
    - spike-supabase/docs/DECISION.md (SPIKE-12 — go/no-go document for v7.0 milestone)
  affects:
    - /gsd-complete-milestone trigger (DECISION.md is the final artifact of v7.0)
tech_stack:
  added: []
  patterns:
    - Decision document format with Executive Summary + SPIKE table + Recommendation + Residual Risks + Next Steps
    - SPIKE-13 audit pattern (grep for credentials in all new docs)
key_files:
  created:
    - spike-supabase/docs/DECISION.md
  modified: []
decisions:
  - "conditional-go for Supabase migration — critical pillars (SPIKE-06, 07, 05, 01-04) all proved; condition: resolve SPIKE-09 Realtime isolation before production"
  - "SPIKE-08 (Flutter) and SPIKE-09 (Realtime) marked pending — templates not filled; does not block go/no-go on backend pillars"
  - "D-07 honored: SPIKE-09 pending treated as conditional, not no-go; Realtime not critical for booking flow"
  - "D-08 honored: explicit statement that booking flow (book_slot + RLS) does not depend on Realtime"
metrics:
  duration: "~8 minutes"
  completed: "2026-06-11T17:52:42Z"
  tasks_completed: 1
  tasks_total: 1
  files_created: 1
  files_modified: 0
---

# Phase 35 Plan 02: DECISION.md Go/No-Go Document Summary

**One-liner:** SPIKE-12 decision document with conditional-go recommendation — 7 critical pillars proved by automated evidence (SPIKE-01..07), SPIKE-09 Realtime pending, JIT Provisioning for password migration, 4 concrete next steps.

---

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create DECISION.md (SPIKE-12) | bc0bfa1 | spike-supabase/docs/DECISION.md |

---

## What Was Built

### SPIKE-12: DECISION.md

Documento de fechamento do spike v7.0. Contém:

**Executive Summary** — 4 frases dirigidas a stakeholder não-técnico. Responde: o que foi provado, qual é o risco principal, e qual é a recomendação.

**SPIKE Evidence Table** — 11 linhas cobrindo SPIKE-01..11:
- `proved` (6): SPIKE-01, 02, 03, 04, 05, 06, 07 — pilares críticos com evidência automatizada em staging
- `pending` (2): SPIKE-08 (Flutter mini-app — template não preenchido), SPIKE-09 (Realtime — teste não executado)
- `acceptable-risk` (2): SPIKE-10 (migração senhas — JIT recomendado), SPIKE-11 (carga Realtime — free tier suficiente para MVP)
- `conditional` implícito em SPIKE-09: per D-07, pending = conditional-go, não no-go

**Recommendation** — Parágrafo de conditional-go com:
- Justificativa baseada em SPIKE-06, 07, 05, 01-04
- Condição explícita: resolver SPIKE-09 antes de produção
- D-08 honrado: "O fluxo de reserva (book_slot + RLS) não depende de Realtime"
- D-07 honrado: SPIKE-09 FAIL/pending = conditional-go, não no-go automático

**Residual Risks** — 5 riscos com severidade e mitigação:
1. SCRYPT params incorretos (MEDIUM) — staging com 10 users + JIT fallback
2. Realtime cross-tenant leak (HIGH se FAIL) — executar SPIKE-09 + polling/SSE fallback
3. Free tier Realtime saturação (MEDIUM) — Pro tier a >160 conexões
4. Firebase tokens em localStorage (LOW) — migration script
5. Timestamps Firebase perdidos (LOW) — aceitar ou exportar para metadata

**Próximos Passos (se go)** — 4 ações concretas:
1. Spike de migração de senhas (JIT Provisioning com 10 users reais)
2. Definir tier Supabase (free vs Pro)
3. Planejar schema multi-tenant em produção
4. Resolver SPIKE-09 (executar teste Realtime)

**SPIKE-13 Audit** — Grep command documentado; nenhuma credencial presente nos docs.

---

## Deviations from Plan

None — plan executed exactly as written.

SPIKE-08 and SPIKE-09 were both marked `pending` based on actual file contents (`flutter-proof.md` and `realtime-evaluation.md` both contain `[fill after run]` template placeholders). The plan anticipated this possibility and instructed to use `pending` in that case. The DECISION.md correctly reflects reality.

---

## Known Stubs

None. DECISION.md is a complete decision document. The `pending` status for SPIKE-08 and SPIKE-09 accurately reflects that those tests were not executed — this is an honest assessment, not a stub. The document explicitly identifies SPIKE-09 resolution as step 4 in Próximos Passos.

---

## Threat Flags

No new security surface introduced. DECISION.md is a markdown decision document:
- SPIKE-13 global audit: `grep -rn 'sb_secret\|service_role\|eyJ' spike-supabase/docs/ | grep -v "grep -r"` — no matches (PASS)
- The only grep matches in DECISION.md are the literal grep command text in the SPIKE-13 Audit section, not actual credentials

---

## Self-Check

### Files exist:
- `spike-supabase/docs/DECISION.md` — FOUND

### Commits exist:
- `bc0bfa1` — FOUND (feat(35-02): add SPIKE-12 decision document go/no-go for v7.0 milestone)

### Acceptance criteria check:
- DECISION.md exists: PASS
- Contains "## SPIKE Evidence Table": PASS
- Contains 11+ SPIKE- rows: PASS (15 SPIKE- mentions, 11 rows in table)
- Contains "conditional-go": PASS (4 occurrences)
- Contains "proved" in 5+ lines: PASS (7 occurrences)
- Contains "Próximos Passos": PASS
- Contains "JIT": PASS (4 occurrences)
- Contains "Realtime" in 3+ lines: PASS (8 occurrences)
- Contains "fluxo de reserva" + "não depende": PASS
- Contains "isolation-proof.md": PASS (2 occurrences)
- Contains "concurrency-proof.md": PASS (2 occurrences)
- Contains "password-migration-risk.md": PASS (2 occurrences)
- Contains "realtime-load-risk.md": PASS (2 occurrences)
- Contains "## SPIKE-13 Audit": PASS
- SPIKE-13 credentials audit: PASS (no actual credentials)

## Self-Check: PASSED

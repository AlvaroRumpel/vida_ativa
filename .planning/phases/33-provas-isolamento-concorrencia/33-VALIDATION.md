---
phase: 33
slug: provas-isolamento-concorrencia
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-10
---

# Phase 33 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node.js scripts (self-reporting PASS/FAIL) + SQL scripts via psql/MCP |
| **Config file** | none — scripts executados diretamente |
| **Quick run command** | `node spike-supabase/tests/isolation-proof.js` |
| **Full suite command** | `node spike-supabase/tests/isolation-proof.js && node spike-supabase/tests/concurrency-test.js` |
| **Estimated runtime** | ~30–60 seconds (HTTP calls to staging) |

---

## Sampling Rate

- **After every task commit:** Run `node spike-supabase/tests/isolation-proof.js` (or sub-script)
- **After every plan wave:** Run full suite command
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 33-01-01 | 01 | 1 | SPIKE-06 | T-33-01 | Service role key não logado no output | infra | `ls spike-supabase/package.json` | ❌ W0 | ⬜ pending |
| 33-01-02 | 01 | 1 | SPIKE-06 | — | supabase-js instalado | unit | `node -e "require('@supabase/supabase-js')"` | ❌ W0 | ⬜ pending |
| 33-02-01 | 02 | 2 | SPIKE-06 | T-33-02 | 3 ataques SQL bloqueados | integration SQL | `psql/MCP -f tests/rls_isolation_test.sql` | ✅ | ⬜ pending |
| 33-02-02 | 02 | 2 | SPIKE-06 | T-33-02 | INSERT WITH CHECK bloqueia cross-tenant | integration SQL | `psql/MCP -f tests/rls_insert_isolation_test.sql` | ✅ | ⬜ pending |
| 33-03-01 | 03 | 3 | SPIKE-06 | T-33-02 | HTTP attacks all PASS | integration HTTP | `node tests/isolation-proof.js` | ❌ W0 | ⬜ pending |
| 33-04-01 | 04 | 4 | SPIKE-07 | T-33-03 | Exactly 1 CONFIRMED out of 50 | integration HTTP | `node tests/concurrency-test.js` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `spike-supabase/package.json` — npm init para habilitar install
- [ ] `@supabase/supabase-js` + `dotenv` instalados em spike-supabase/
- [ ] `spike-supabase/docs/` directory criado
- [ ] `spike-supabase/tests/isolation-proof.js` — script de isolamento HTTP
- [ ] `spike-supabase/tests/concurrency-test.js` — script de concorrência

*SQL tests existentes não precisam de Wave 0: rls_isolation_test.sql e rls_insert_isolation_test.sql já existem.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Auth Hook ativo em staging (app_metadata.tenant_id presente no JWT) | SPIKE-05 (Phase 32 deliverable) | Depende de estado externo do Supabase Dashboard | Fazer login com testclient@spike.local e decodificar JWT — checar app_metadata.tenant_id |
| Proof docs contêm output raw do terminal | SPIKE-06, SPIKE-07 | Output gerado por execução manual | Abrir isolation-proof.md e concurrency-proof.md e verificar seção "Raw Output" está preenchida |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

---
phase: 35
slug: riscos-documento-decisao
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-11
---

# Phase 35 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | file-existence checks + grep (no test runner) |
| **Config file** | none — docs-only phase |
| **Quick run command** | `ls spike-supabase/docs/*.md` |
| **Full suite command** | `grep -l "SPIKE-10\|SPIKE-11\|SPIKE-12" spike-supabase/docs/*.md` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run `ls spike-supabase/docs/*.md`
- **After every plan wave:** Verify grep patterns in created docs
- **Before `/gsd-verify-work`:** All 3 docs exist and contain required sections
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 35-01-01 | 01 | 1 | SPIKE-10 | — | N/A | file-check | `ls spike-supabase/docs/password-migration-risk.md` | ❌ W0 | ⬜ pending |
| 35-01-02 | 01 | 1 | SPIKE-11 | — | N/A | file-check | `ls spike-supabase/docs/realtime-load-risk.md` | ❌ W0 | ⬜ pending |
| 35-02-01 | 02 | 2 | SPIKE-12 | — | N/A | grep | `grep -c "SPIKE-" spike-supabase/docs/DECISION.md` | ❌ W0 | ⬜ pending |
| 35-02-02 | 02 | 2 | SPIKE-12 | — | N/A | grep | `grep -i "go\|no-go\|conditional" spike-supabase/docs/DECISION.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `spike-supabase/docs/` directory exists (already created in prior phases)

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| SPIKE-10 content quality — JIT strategy covers ~200 email users | SPIKE-10 | Content review required | Open password-migration-risk.md, verify: section on JIT provisioning exists, timeline for ~90 days included, impact on ~200 users stated |
| SPIKE-11 tier threshold — Pro tier recommendation when >250 concurrent | SPIKE-11 | Numeric threshold review | Open realtime-load-risk.md, verify: free tier 200 connection limit stated, Pro tier recommendation with threshold present |
| DECISION.md recommendation paragraph — go/conditional-go/no-go stated clearly | SPIKE-12 | Qualitative judgment | Open DECISION.md, verify: recommendation paragraph exists, residual risks listed, "Próximos Passos (se go)" section present |
| service role key not present in any new doc | SPIKE-13 | Security audit | `grep -r "service_role\|eyJ" spike-supabase/docs/` returns no matches in new files |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

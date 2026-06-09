---
phase: 32
slug: book-slot-auth-hook
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-09
---

# Phase 32 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | psql SQL scripts + Deno test runner |
| **Config file** | spike-supabase/tests/ (SQL) + supabase/functions/custom-access-token/test.ts (Deno) |
| **Quick run command** | `psql "$SUPABASE_DB_URL" -f spike-supabase/tests/book_slot_test.sql` |
| **Full suite command** | `psql "$SUPABASE_DB_URL" -f spike-supabase/tests/book_slot_test.sql && deno test supabase/functions/custom-access-token/test.ts` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run psql quick test
- **After every plan wave:** Run full suite (psql + deno test)
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 32-01-01 | 01 | 0 | SPIKE-02 | — | book_slot() test stubs exist | infra | `test -f spike-supabase/tests/book_slot_test.sql` | ❌ W0 | ⬜ pending |
| 32-01-02 | 01 | 1 | SPIKE-02 | — | book_slot() SUCCESS path returns booking_id | sql-test | `psql "$SUPABASE_DB_URL" -f spike-supabase/tests/book_slot_test.sql` | ❌ W0 | ⬜ pending |
| 32-01-03 | 01 | 1 | SPIKE-02 | — | double-booking returns SLOT_ALREADY_BOOKED | sql-test | `psql "$SUPABASE_DB_URL" -f spike-supabase/tests/book_slot_test.sql` | ❌ W0 | ⬜ pending |
| 32-02-01 | 02 | 0 | SPIKE-05 | — | auth hook function file exists | infra | `test -f supabase/functions/custom-access-token/index.ts` | ❌ W0 | ⬜ pending |
| 32-02-02 | 02 | 1 | SPIKE-05 | — | hook deployed + registered in Supabase | manual | check Supabase dashboard | — | ⬜ pending |
| 32-02-03 | 02 | 1 | SPIKE-05 | — | JWT app_metadata has tenant_id after login | manual | psql decode JWT | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `spike-supabase/tests/book_slot_test.sql` — test stubs for SPIKE-02 (success, double-booking, lock contention)
- [ ] `supabase/functions/custom-access-token/index.ts` — Edge Function scaffold (can be empty stub)

*Wave 0 creates test infrastructure before implementation tasks run.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Auth Hook registered in Supabase Dashboard | SPIKE-05 | Supabase Dashboard configuration cannot be automated via MCP | Go to Authentication > Hooks > Custom Access Token, verify URL is set to `https://fasirsbiadcchfgvktzt.supabase.co/functions/v1/custom-access-token` |
| JWT app_metadata contains tenant_id after login | SPIKE-05 | Requires actual auth flow (Supabase anon key + real user login) | `SELECT auth.jwt() -> 'app_metadata'` in Supabase SQL editor while logged in as test user |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

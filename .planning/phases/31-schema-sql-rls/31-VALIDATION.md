---
phase: 31
slug: schema-sql-rls
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-09
---

# Phase 31 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | psql (PostgreSQL CLI) + pgTAP (optional) |
| **Config file** | none — SQL files run directly against Supabase cloud |
| **Quick run command** | `psql "$SUPABASE_DB_URL" -f spike-supabase/schema/01_schema.sql` |
| **Full suite command** | `psql "$SUPABASE_DB_URL" -f spike-supabase/schema/01_schema.sql && psql "$SUPABASE_DB_URL" -f spike-supabase/schema/02_rls.sql && psql "$SUPABASE_DB_URL" -f spike-supabase/schema/03_seed.sql` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `psql "$SUPABASE_DB_URL" -f spike-supabase/schema/01_schema.sql`
- **After every plan wave:** Run full suite (schema + rls + seed)
- **Before `/gsd-verify-work`:** Full suite must be green + rls_isolation_test.sql passes
- **Max feedback latency:** ~10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 31-01-01 | 01 | 1 | SPIKE-13 | T-13 | `.env` gitignored; no `sb_secret_` in repo | grep check | `grep -r "sb_secret_" . --include="*.sql" --include="*.dart" --include="*.env" \| grep -v ".env.example"` | ❌ W0 | ⬜ pending |
| 31-01-02 | 01 | 1 | SPIKE-01 | — | Schema compiles without errors; exit code 0 | SQL syntax | `psql "$SUPABASE_DB_URL" -f spike-supabase/schema/01_schema.sql; echo $?` | ❌ W0 | ⬜ pending |
| 31-02-01 | 02 | 1 | SPIKE-03 | T-03 | RLS enabled on all 4 tables | psql check | `psql "$SUPABASE_DB_URL" -c "\d bookings" \| grep "Row-level security: ON"` | ❌ W0 | ⬜ pending |
| 31-02-02 | 02 | 1 | SPIKE-04 | T-04 | Client sees own tenant; cross-tenant SELECT returns 0 rows | isolation test | `psql "$SUPABASE_DB_URL" -f spike-supabase/tests/rls_isolation_test.sql` | ❌ W0 | ⬜ pending |
| 31-03-01 | 03 | 2 | SPIKE-01 | — | Seed data inserted; 2+ tenants, 4+ users, 4+ bookings | row count | `psql "$SUPABASE_DB_URL" -c "SELECT COUNT(*) FROM tenants;"` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `spike-supabase/tests/rls_isolation_test.sql` — 3 attack scenarios (cross-tenant SELECT, cross-tenant INSERT, admin sees all tenant rows)
- [ ] `spike-supabase/tests/rls_insert_isolation_test.sql` — covers Pitfall 2 (missing WITH CHECK detection)
- [ ] `.gitignore` at `spike-supabase/` with `**/.env*` and `**/sb_secret_*` patterns
- [ ] `spike-supabase/.env.example` with placeholder values (no real keys)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Supabase cloud project created | SPIKE-01 | Requires Supabase dashboard UI | Create project at supabase.com; copy SUPABASE_URL + SUPABASE_ANON_KEY to local `.env` |
| RLS enforcement visible in Studio | SPIKE-03 | Dashboard inspection | Open Supabase Studio → Table Editor → bookings → RLS tab shows policies listed |
| Service role key only in Supabase console | SPIKE-13 | No automation for cloud secrets check | Verify key is NOT in any file in `spike-supabase/`; confirm it's only in Supabase project settings |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

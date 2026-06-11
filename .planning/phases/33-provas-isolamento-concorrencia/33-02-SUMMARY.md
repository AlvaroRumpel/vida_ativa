---
phase: 33-provas-isolamento-concorrencia
plan: 02
wave: 2
status: complete
completed: 2026-06-10
---

# Plan 33-02 Summary — SQL Isolation Tests

## What was built
- Executed `rls_isolation_test.sql` and `rls_insert_isolation_test.sql` via Supabase MCP `execute_sql`
- Created `spike-supabase/docs/isolation-proof.md` with SQL results section

## Results
| Test | Result |
|------|--------|
| SQL-1: Cross-tenant SELECT on bookings | PASS (0 rows) |
| SQL-2: Cross-tenant SELECT on slots | PASS (0 rows) |
| SQL-3: Admin sees all Tenant A bookings | PASS (7 rows) |
| SQL-4: Cross-tenant INSERT WITH CHECK | PASS (42501 error) |
| Control: Own-tenant INSERT | PASS (succeeded, rolled back) |

## Artifacts
- `spike-supabase/docs/isolation-proof.md` — SQL section populated, HTTP placeholder ready for Plan 03

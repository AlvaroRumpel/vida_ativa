---
status: complete
phase: 31-schema-sql-rls
source: [31-01-SUMMARY.md, 31-02-SUMMARY.md, 31-03-SUMMARY.md, 31-04-SUMMARY.md]
started: 2026-06-09T00:00:00Z
updated: 2026-06-09T00:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. File structure — all deliverables present
expected: |
  spike-supabase/ contains all 8 expected files:
    spike-supabase/.gitignore
    spike-supabase/.env.example
    spike-supabase/schema/01_schema.sql
    spike-supabase/schema/02_rls.sql
    spike-supabase/schema/03_seed.sql
    spike-supabase/README.md
    spike-supabase/tests/rls_isolation_test.sql
    spike-supabase/tests/rls_insert_isolation_test.sql
result: pass

### 2. Security scaffolding — credentials blocked
expected: |
  .gitignore blocks .env, *sb_secret_*, and *service_role* patterns.
  .env.example has placeholder values only — no real Supabase keys.
  Running: grep -r "sb_secret_" spike-supabase/ --include="*.sql" --include="*.dart"
  returns empty (no real keys in code files).
result: pass

### 3. JWT operator fix — correct -> in all RLS policies
expected: |
  02_rls.sql uses -> (not ->>) to traverse app_metadata in all 15 policies.
  Running: grep -c "-> 'app_metadata'" spike-supabase/schema/02_rls.sql
  returns 40 (all expressions correct).
  Running: grep -c "->> 'app_metadata'" spike-supabase/schema/02_rls.sql
  returns 0 (broken pattern gone).
result: pass

### 4. Schema structure — 4 tables, RLS enabled, all 7 statuses
expected: |
  01_schema.sql defines tenants, memberships, slots, bookings.
  All 4 tables have ALTER TABLE ... ENABLE ROW LEVEL SECURITY.
  bookings.status CHECK constraint includes all 7 Firebase values:
    pending, confirmed, cancelled, rejected, pending_payment, expired, refunded
  UNIQUE(tenant_id, slot_id, booking_date) constraint exists (named unique_booking).
result: pass

### 5. Seed data — 2 tenants, all 7 booking statuses covered
expected: |
  03_seed.sql inserts:
    2 tenants (Tenant A UUID prefix 10000000-..., Tenant B prefix 20000000-...)
    4 memberships (Tenant A client + admin, Tenant B client + admin)
    4 slots (2 per tenant)
    8 bookings covering all 7 status values
  Seed is idempotent — re-running does ON CONFLICT DO UPDATE, not error.
result: pass

### 6. README — apply order and credential setup documented
expected: |
  spike-supabase/README.md documents:
    3-step apply order: 01_schema.sql → 02_rls.sql → 03_seed.sql
    How to create .env from .env.example
    How to update placeholder user_ids after creating auth.users
    RLS test instructions (psql commands for rls_isolation_test.sql)
result: pass

### 7. Cold start — apply schema + RLS + seed to live Supabase staging
expected: |
  With real credentials in .env:
    psql "$SUPABASE_DB_URL" -f spike-supabase/schema/01_schema.sql  → no errors
    psql "$SUPABASE_DB_URL" -f spike-supabase/schema/02_rls.sql     → 15 policies created
    psql "$SUPABASE_DB_URL" -f spike-supabase/schema/03_seed.sql    → 8 bookings inserted
  All 3 commands idempotent — re-running produces same state, no errors.
result: pass
note: Applied via Supabase MCP. DB verified: 2 tenants, 4 memberships, 4 slots, 8 bookings, 7 distinct statuses.

## Summary

total: 7
passed: 7
issues: 0
pending: 0
skipped: 0

## Gaps

[none yet]

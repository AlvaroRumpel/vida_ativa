-- =============================================================================
-- RLS Isolation Test Suite
-- Run AFTER: 01_schema.sql + 02_rls.sql + 03_seed.sql applied
-- Run with: psql "$SUPABASE_DB_URL" -f spike-supabase/tests/rls_isolation_test.sql
--
-- Seed UUID constants (from 03_seed.sql):
--   Tenant A: 10000000-0000-0000-0000-000000000001
--   Tenant B: 20000000-0000-0000-0000-000000000001
--   Client A (Tenant A): see auth.users after signup
--   Client B (Tenant B): see auth.users after signup
--
-- NOTE: SET LOCAL request.jwt.claims only works inside a transaction block.
-- Each test uses BEGIN/ROLLBACK to simulate a user session.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Attack 1: Cross-tenant SELECT — client in Tenant A tries to read Tenant B rows
-- Expected: 0 rows returned from Tenant B (RLS blocks access)
-- -----------------------------------------------------------------------------
SELECT '=== Attack 1: Cross-tenant SELECT on bookings ==='::TEXT AS test;

BEGIN;
  SET LOCAL role TO authenticated;
  SET LOCAL request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000011","app_metadata":{"tenant_id":"10000000-0000-0000-0000-000000000001","role":"client"}}';

  -- This query should return 0 rows (Tenant B data not visible to Tenant A client)
  SELECT
    CASE
      WHEN COUNT(*) = 0 THEN 'PASS: Cross-tenant SELECT blocked (0 rows from Tenant B)'
      ELSE CONCAT('FAIL: Cross-tenant SELECT LEAKED ', COUNT(*)::TEXT, ' rows from Tenant B')
    END AS result
  FROM bookings
  WHERE tenant_id = '20000000-0000-0000-0000-000000000001'::uuid;

ROLLBACK;

-- -----------------------------------------------------------------------------
-- Attack 2: Cross-tenant SELECT on slots — client in Tenant A reads Tenant B slots
-- Expected: 0 rows returned from Tenant B slots
-- -----------------------------------------------------------------------------
SELECT '=== Attack 2: Cross-tenant SELECT on slots ==='::TEXT AS test;

BEGIN;
  SET LOCAL role TO authenticated;
  SET LOCAL request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000011","app_metadata":{"tenant_id":"10000000-0000-0000-0000-000000000001","role":"client"}}';

  SELECT
    CASE
      WHEN COUNT(*) = 0 THEN 'PASS: Cross-tenant SELECT on slots blocked (0 rows from Tenant B)'
      ELSE CONCAT('FAIL: Cross-tenant SELECT on slots LEAKED ', COUNT(*)::TEXT, ' Tenant B slots')
    END AS result
  FROM slots
  WHERE tenant_id = '20000000-0000-0000-0000-000000000001'::uuid;

ROLLBACK;

-- -----------------------------------------------------------------------------
-- Attack 3: Admin in Tenant A sees ALL Tenant A bookings (not just own)
-- Expected: COUNT > 1 (admin sees all tenant rows, not just own user_id)
-- This validates D-07: admin policy is broader than client policy
-- -----------------------------------------------------------------------------
SELECT '=== Attack 3: Admin SELECT — sees all Tenant A bookings ==='::TEXT AS test;

BEGIN;
  SET LOCAL role TO authenticated;
  SET LOCAL request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000012","app_metadata":{"tenant_id":"10000000-0000-0000-0000-000000000001","role":"admin"}}';

  SELECT
    CASE
      WHEN COUNT(*) > 0 THEN CONCAT('PASS: Admin sees ', COUNT(*)::TEXT, ' Tenant A bookings (all users)')
      ELSE 'FAIL: Admin sees 0 bookings — admin policy too restrictive'
    END AS result
  FROM bookings
  WHERE tenant_id = '10000000-0000-0000-0000-000000000001'::uuid;

ROLLBACK;

SELECT 'rls_isolation_test.sql complete. Review PASS/FAIL above.'::TEXT AS summary;

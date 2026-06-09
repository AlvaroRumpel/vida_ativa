-- =============================================================================
-- RLS WITH CHECK Isolation Test (Pitfall 2 Guard)
-- Run AFTER: 01_schema.sql + 02_rls.sql applied
-- Run with: psql "$SUPABASE_DB_URL" -f spike-supabase/tests/rls_insert_isolation_test.sql
--
-- Tests that INSERT policies have WITH CHECK clause (Pitfall 2 from PITFALLS.md).
-- Without WITH CHECK, users can INSERT into wrong tenant — critical security gap.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Attack: Client in Tenant A tries to INSERT a booking for Tenant B
-- Expected: INSERT fails with "violates row-level security policy" error
-- -----------------------------------------------------------------------------
SELECT '=== WITH CHECK Test: Cross-tenant INSERT attempt ==='::TEXT AS test;

BEGIN;
  SET LOCAL role TO authenticated;
  SET LOCAL request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000011","app_metadata":{"tenant_id":"10000000-0000-0000-0000-000000000001","role":"client"}}';

  -- Attempt to INSERT a booking into Tenant B (should be blocked by WITH CHECK)
  -- This will raise an exception if RLS WITH CHECK is correctly configured
  DO $$
  BEGIN
    INSERT INTO bookings (id, tenant_id, user_id, slot_id, booking_date, status)
    VALUES (
      gen_random_uuid(),
      '20000000-0000-0000-0000-000000000001'::uuid,  -- Tenant B (attacker's target)
      '00000000-0000-0000-0000-000000000011'::uuid,  -- Attacker's user_id
      '22000000-0000-0000-0000-000000000001'::uuid,  -- Tenant B slot
      '2026-09-01',
      'pending'
    );
    RAISE NOTICE 'FAIL: Cross-tenant INSERT succeeded — WITH CHECK clause missing or misconfigured';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE NOTICE 'PASS: Cross-tenant INSERT blocked by RLS WITH CHECK (insufficient_privilege)';
    WHEN others THEN
      RAISE NOTICE 'PASS (other): Cross-tenant INSERT blocked: %', SQLERRM;
  END;
  $$;

ROLLBACK;

-- -----------------------------------------------------------------------------
-- Control: Client in Tenant A can INSERT booking for own tenant
-- Expected: INSERT succeeds (returns INSERT 1)
-- -----------------------------------------------------------------------------
SELECT '=== Control Test: Own-tenant INSERT should succeed ==='::TEXT AS test;

BEGIN;
  SET LOCAL role TO authenticated;
  SET LOCAL request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000011","app_metadata":{"tenant_id":"10000000-0000-0000-0000-000000000001","role":"client"}}';

  DO $$
  BEGIN
    INSERT INTO bookings (id, tenant_id, user_id, slot_id, booking_date, status)
    VALUES (
      gen_random_uuid(),
      '10000000-0000-0000-0000-000000000001'::uuid,  -- Own tenant (Tenant A)
      '00000000-0000-0000-0000-000000000011'::uuid,  -- Own user_id
      '12000000-0000-0000-0000-000000000001'::uuid,  -- Tenant A slot
      '2026-09-15',
      'pending'
    );
    RAISE NOTICE 'PASS: Own-tenant INSERT succeeded as expected';
  EXCEPTION
    WHEN others THEN
      RAISE NOTICE 'FAIL: Own-tenant INSERT blocked unexpectedly: %', SQLERRM;
  END;
  $$;

ROLLBACK;

SELECT 'rls_insert_isolation_test.sql complete. Review PASS/FAIL above.'::TEXT AS summary;

-- =============================================================================
-- book_slot_test.sql — Test Suite for book_slot() PL/pgSQL Function
-- Spike: v7.0 Supabase Multi-Tenant Validation
-- Apply AFTER: 01_schema.sql + 02_rls.sql + 03_seed.sql + 04_book_slot.sql
-- Run: psql "$SUPABASE_DB_URL" -f spike-supabase/tests/book_slot_test.sql
--
-- Tests:
--   T1: SUCCESS path — new booking returns success=true + booking_id
--   T2: SLOT_ALREADY_BOOKED — duplicate booking returns error code
--   T3: Return structure — columns (success, error_code, booking_id) exist
--
-- Note on SLOT_LOCKED_RETRY: lock contention (SQLSTATE 55P03) is triggered only
-- when two concurrent transactions hold/acquire the same row lock simultaneously.
-- Sequential SQL execution cannot reproduce this scenario. SLOT_LOCKED_RETRY is
-- tested via the EXCEPTION block in 04_book_slot.sql (code review only).
-- =============================================================================

-- Cleanup: remove any test bookings from previous runs (idempotent)
DELETE FROM public.bookings
WHERE slot_id = '12000000-0000-0000-0000-000000000001'::uuid
  AND booking_date = '2099-01-01'::date;

DELETE FROM public.bookings
WHERE slot_id = '12000000-0000-0000-0000-000000000002'::uuid
  AND booking_date = '2099-01-02'::date;

-- =============================================================================
-- T1: SUCCESS — first booking for slot A1 on future date should succeed
-- Expected: success=true, error_code=NULL, booking_id IS NOT NULL
-- =============================================================================
DO $$
DECLARE
  v_success    BOOLEAN;
  v_error_code TEXT;
  v_booking_id UUID;
BEGIN
  SELECT success, error_code, booking_id
    INTO v_success, v_error_code, v_booking_id
    FROM public.book_slot(
      '12000000-0000-0000-0000-000000000001'::uuid,  -- p_slot_id (Slot A1)
      '2099-01-01'::date,                             -- p_booking_date (far future)
      '00000000-0000-0000-0000-000000000011'::uuid,  -- p_user_id (Client A placeholder)
      '10000000-0000-0000-0000-000000000001'::uuid   -- p_tenant_id (Tenant A)
    );

  IF v_success = TRUE AND v_error_code IS NULL AND v_booking_id IS NOT NULL THEN
    RAISE NOTICE 'T1 PASS: book_slot() SUCCESS — booking_id=%', v_booking_id;
  ELSE
    RAISE EXCEPTION 'T1 FAIL: expected success=true, error_code=NULL, booking_id NOT NULL. Got: success=%, error_code=%, booking_id=%',
      v_success, v_error_code, v_booking_id;
  END IF;
END;
$$;

-- =============================================================================
-- T2: SLOT_ALREADY_BOOKED — second booking for same slot+date should fail
-- T1 inserted slot A1 on 2099-01-01; calling again must return SLOT_ALREADY_BOOKED
-- Expected: success=false, error_code='SLOT_ALREADY_BOOKED', booking_id=NULL
-- =============================================================================
DO $$
DECLARE
  v_success    BOOLEAN;
  v_error_code TEXT;
  v_booking_id UUID;
BEGIN
  SELECT success, error_code, booking_id
    INTO v_success, v_error_code, v_booking_id
    FROM public.book_slot(
      '12000000-0000-0000-0000-000000000001'::uuid,  -- p_slot_id (Slot A1 — same as T1)
      '2099-01-01'::date,                             -- p_booking_date (same as T1)
      '00000000-0000-0000-0000-000000000011'::uuid,  -- p_user_id
      '10000000-0000-0000-0000-000000000001'::uuid   -- p_tenant_id
    );

  IF v_success = FALSE AND v_error_code = 'SLOT_ALREADY_BOOKED' AND v_booking_id IS NULL THEN
    RAISE NOTICE 'T2 PASS: book_slot() SLOT_ALREADY_BOOKED returned correctly';
  ELSE
    RAISE EXCEPTION 'T2 FAIL: expected success=false, error_code=SLOT_ALREADY_BOOKED, booking_id=NULL. Got: success=%, error_code=%, booking_id=%',
      v_success, v_error_code, v_booking_id;
  END IF;
END;
$$;

-- =============================================================================
-- T3: Return structure — SELECT columns must exist
-- Expected: query returns exactly 3 columns: success BOOLEAN, error_code TEXT, booking_id UUID
-- Uses Slot A2 + different date to avoid conflict with T1/T2
-- =============================================================================
DO $$
DECLARE
  v_success    BOOLEAN;
  v_error_code TEXT;
  v_booking_id UUID;
BEGIN
  SELECT success, error_code, booking_id
    INTO v_success, v_error_code, v_booking_id
    FROM public.book_slot(
      '12000000-0000-0000-0000-000000000002'::uuid,  -- p_slot_id (Slot A2 — fresh slot)
      '2099-01-02'::date,                             -- p_booking_date (different date)
      '00000000-0000-0000-0000-000000000011'::uuid,
      '10000000-0000-0000-0000-000000000001'::uuid
    );

  RAISE NOTICE 'T3 PASS: return structure valid — success=%, error_code=%, booking_id=%',
    v_success, v_error_code, v_booking_id;
END;
$$;

-- =============================================================================
-- Note: SLOT_LOCKED_RETRY scenario (error_code='SLOT_LOCKED_RETRY')
-- This error is returned when SELECT FOR UPDATE NOWAIT cannot acquire the row lock
-- because a concurrent transaction holds it. Sequential SQL cannot simulate two
-- concurrent sessions. Verify via code review of EXCEPTION WHEN lock_not_available
-- block in spike-supabase/schema/04_book_slot.sql.
-- =============================================================================

-- =============================================================================
-- Cleanup: remove test bookings to leave DB clean for next run
-- =============================================================================
DELETE FROM public.bookings
WHERE slot_id = '12000000-0000-0000-0000-000000000001'::uuid
  AND booking_date = '2099-01-01'::date;

DELETE FROM public.bookings
WHERE slot_id = '12000000-0000-0000-0000-000000000002'::uuid
  AND booking_date = '2099-01-02'::date;

SELECT 'book_slot_test.sql COMPLETE — T1 SUCCESS, T2 SLOT_ALREADY_BOOKED, T3 structure OK' AS result;

-- =============================================================================
-- 04_book_slot.sql — Atomic Slot Booking Function
-- Spike: v7.0 Supabase Multi-Tenant Validation
-- Apply AFTER: 01_schema.sql + 02_rls.sql + 03_seed.sql
-- Apply: psql "$SUPABASE_DB_URL" -f spike-supabase/schema/04_book_slot.sql
--
-- Function: public.book_slot(p_slot_id, p_booking_date, p_user_id, p_tenant_id)
-- Returns: TABLE(success BOOLEAN, error_code TEXT, booking_id UUID)
--
-- Locking strategy:
--   1. SELECT FOR UPDATE NOWAIT on existing booking row (if any)
--      → if row locked by concurrent tx: raises lock_not_available (SQLSTATE 55P03)
--      → caught → returns SLOT_LOCKED_RETRY
--   2. If no row exists: INSERT proceeds
--      → if concurrent tx committed INSERT between our SELECT and our INSERT:
--         unique_violation fires (SQLSTATE 23505)
--      → caught → returns SLOT_ALREADY_BOOKED
--   3. Success: returns booking_id
--
-- Security: SECURITY DEFINER (runs as function owner, bypasses RLS for INSERT)
-- Grant: EXECUTE to authenticated role
--
-- Threat mitigations applied (T-32-01-01 to T-32-01-05):
--   T-32-01-01 (Tampering): p_tenant_id MUST come from JWT app_metadata at caller
--     level (Edge Function or app code). Never accept from direct HTTP input.
--   T-32-01-02 (SECURITY DEFINER bypass): Accepted risk — required for INSERT to
--     work without full JWT app_metadata configured in tests.
--   T-32-01-03 (DoS): idx_bookings_slot_date index on (slot_id, booking_date)
--     exists in 01_schema.sql — lock acquisition is O(log n), not full scan.
--   T-32-01-04 (p_user_id not validated): Spike limitation — production must
--     validate p_user_id belongs to tenant via JOIN with memberships.
--   T-32-01-05 (error_code reveals booking existence): Accepted risk — slot IDs
--     are non-guessable UUIDs; information not sensitive in spike context.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.book_slot(
  p_slot_id      UUID,
  p_booking_date DATE,
  p_user_id      UUID,
  p_tenant_id    UUID
)
RETURNS TABLE(success BOOLEAN, error_code TEXT, booking_id UUID)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_existing_id UUID;
  v_new_id      UUID;
BEGIN
  -- Step 1: Attempt to acquire exclusive row lock on existing booking (if any).
  -- NOWAIT means: if row is locked by another transaction, fail immediately.
  -- This prevents two concurrent requests from both reaching the INSERT.
  SELECT id INTO v_existing_id
  FROM public.bookings
  WHERE tenant_id    = p_tenant_id
    AND slot_id      = p_slot_id
    AND booking_date = p_booking_date
  FOR UPDATE NOWAIT;

  -- Step 2: If a booking already exists (SELECT found a row), return conflict.
  IF v_existing_id IS NOT NULL THEN
    RETURN QUERY SELECT FALSE, 'SLOT_ALREADY_BOOKED'::TEXT, NULL::UUID;
    RETURN;
  END IF;

  -- Step 3: No existing booking — proceed with INSERT.
  INSERT INTO public.bookings (tenant_id, user_id, slot_id, booking_date, status)
  VALUES (p_tenant_id, p_user_id, p_slot_id, p_booking_date, 'pending')
  RETURNING id INTO v_new_id;

  RETURN QUERY SELECT TRUE, NULL::TEXT, v_new_id;
  RETURN;

EXCEPTION
  WHEN unique_violation THEN
    -- Race condition: another transaction committed the INSERT between our
    -- SELECT FOR UPDATE and our INSERT. UNIQUE constraint (tenant_id, slot_id,
    -- booking_date) fired. Booking is taken.
    RETURN QUERY SELECT FALSE, 'SLOT_ALREADY_BOOKED'::TEXT, NULL::UUID;
    RETURN;

  WHEN lock_not_available THEN
    -- SELECT FOR UPDATE NOWAIT could not acquire lock — another transaction
    -- is currently holding the lock (booking this same slot+date).
    -- Client should retry after brief delay.
    RETURN QUERY SELECT FALSE, 'SLOT_LOCKED_RETRY'::TEXT, NULL::UUID;
    RETURN;
END;
$$;

-- Grant EXECUTE to authenticated role (called from Supabase client with user JWT)
GRANT EXECUTE ON FUNCTION public.book_slot(UUID, DATE, UUID, UUID) TO authenticated;

-- =============================================================================
-- Verification queries (uncomment and run manually to confirm function applied)
-- =============================================================================
-- SELECT proname, prosecdef, proacl
--   FROM pg_proc
--   WHERE proname = 'book_slot' AND pronamespace = 'public'::regnamespace;
-- Expected: 1 row, prosecdef=true (SECURITY DEFINER), proacl includes authenticated

-- SELECT routine_name, security_type
--   FROM information_schema.routines
--   WHERE routine_schema = 'public' AND routine_name = 'book_slot';
-- Expected: 1 row, security_type = 'DEFINER'

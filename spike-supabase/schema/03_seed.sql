-- =============================================================================
-- 03_seed.sql — Test Data for RLS Validation
-- Spike: v7.0 Supabase Multi-Tenant Validation
-- Apply AFTER: 01_schema.sql + 02_rls.sql
-- Apply: psql "$SUPABASE_DB_URL" -f spike-supabase/schema/03_seed.sql
--
-- Creates:
--   2 tenants (A and B) with deterministic UUIDs
--   4 memberships (1 client + 1 admin in Tenant A; 1 client + 1 admin in Tenant B)
--   4 slots (3 for Tenant A; 1 for Tenant B)
--   8 bookings covering all 7 Firebase status values
--
-- IMPORTANT: user_id values are PLACEHOLDERS.
-- After creating real auth.users in Supabase Auth dashboard, update the
-- user_id values in memberships and bookings via SQL UPDATE or re-run with
-- real UUIDs.
--
-- All INSERTs use ON CONFLICT (id) DO UPDATE for idempotent re-runs.
-- =============================================================================

-- =============================================================================
-- TENANTS
-- =============================================================================
INSERT INTO tenants (id, name) VALUES
  (
    '10000000-0000-0000-0000-000000000001'::uuid,
    'Academia Vida Ativa (Spike Tenant A)'
  ),
  (
    '20000000-0000-0000-0000-000000000001'::uuid,
    'Outro Clube (Spike Tenant B)'
  )
ON CONFLICT (id) DO UPDATE
  SET name = EXCLUDED.name,
      updated_at = now();

-- =============================================================================
-- MEMBERSHIPS (user_id = placeholder — update after creating real auth.users)
-- =============================================================================
-- Tenant A — Client user
INSERT INTO memberships (id, tenant_id, user_id, role) VALUES
  (
    '11000000-0000-0000-0000-000000000001'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000011'::uuid,  -- PLACEHOLDER: replace with real auth.users.id
    'client'
  )
ON CONFLICT (id) DO UPDATE
  SET user_id = EXCLUDED.user_id,
      role = EXCLUDED.role;

-- Tenant A — Admin user
INSERT INTO memberships (id, tenant_id, user_id, role) VALUES
  (
    '11000000-0000-0000-0000-000000000002'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000012'::uuid,  -- PLACEHOLDER: replace with real auth.users.id
    'admin'
  )
ON CONFLICT (id) DO UPDATE
  SET user_id = EXCLUDED.user_id,
      role = EXCLUDED.role;

-- Tenant B — Client user
INSERT INTO memberships (id, tenant_id, user_id, role) VALUES
  (
    '21000000-0000-0000-0000-000000000001'::uuid,
    '20000000-0000-0000-0000-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000021'::uuid,  -- PLACEHOLDER: replace with real auth.users.id
    'client'
  )
ON CONFLICT (id) DO UPDATE
  SET user_id = EXCLUDED.user_id,
      role = EXCLUDED.role;

-- Tenant B — Admin user (for cross-tenant admin boundary testing)
INSERT INTO memberships (id, tenant_id, user_id, role) VALUES
  (
    '21000000-0000-0000-0000-000000000002'::uuid,
    '20000000-0000-0000-0000-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000022'::uuid,  -- PLACEHOLDER: replace with real auth.users.id
    'admin'
  )
ON CONFLICT (id) DO UPDATE
  SET user_id = EXCLUDED.user_id,
      role = EXCLUDED.role;

-- =============================================================================
-- SLOTS
-- =============================================================================
-- Tenant A slots (3 slots: Mon + Mon + Wed)
INSERT INTO slots (id, tenant_id, day_of_week, start_time, end_time, price, is_active) VALUES
  (
    '12000000-0000-0000-0000-000000000001'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    1,                           -- Monday (ISO 8601)
    '08:00:00'::time,
    '09:00:00'::time,
    50.00,
    true
  ),
  (
    '12000000-0000-0000-0000-000000000002'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    1,                           -- Monday
    '09:00:00'::time,
    '10:00:00'::time,
    50.00,
    true
  ),
  (
    '12000000-0000-0000-0000-000000000003'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    3,                           -- Wednesday
    '10:00:00'::time,
    '11:00:00'::time,
    60.00,
    true
  )
ON CONFLICT (id) DO UPDATE
  SET day_of_week = EXCLUDED.day_of_week,
      start_time = EXCLUDED.start_time,
      end_time = EXCLUDED.end_time,
      price = EXCLUDED.price,
      updated_at = now();

-- Tenant B slot (1 slot: Tue)
INSERT INTO slots (id, tenant_id, day_of_week, start_time, end_time, price, is_active) VALUES
  (
    '22000000-0000-0000-0000-000000000001'::uuid,
    '20000000-0000-0000-0000-000000000001'::uuid,
    2,                           -- Tuesday
    '08:00:00'::time,
    '09:00:00'::time,
    75.00,
    true
  )
ON CONFLICT (id) DO UPDATE
  SET day_of_week = EXCLUDED.day_of_week,
      start_time = EXCLUDED.start_time,
      end_time = EXCLUDED.end_time,
      price = EXCLUDED.price,
      updated_at = now();

-- =============================================================================
-- BOOKINGS — All 7 Firebase status values (D-04)
-- user_id values are PLACEHOLDERS matching membership user_ids above
-- =============================================================================
INSERT INTO bookings (id, tenant_id, user_id, slot_id, booking_date, status) VALUES
  -- Status: pending
  (
    '13000000-0000-0000-0000-000000000001'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000011'::uuid,  -- Client A
    '12000000-0000-0000-0000-000000000001'::uuid,  -- Slot A1
    '2026-06-16',
    'pending'
  ),
  -- Status: confirmed
  (
    '13000000-0000-0000-0000-000000000002'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000011'::uuid,  -- Client A
    '12000000-0000-0000-0000-000000000002'::uuid,  -- Slot A2
    '2026-06-16',
    'confirmed'
  ),
  -- Status: pending_payment (D-04 Firebase status)
  (
    '13000000-0000-0000-0000-000000000003'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000011'::uuid,  -- Client A
    '12000000-0000-0000-0000-000000000001'::uuid,  -- Slot A1
    '2026-06-23',
    'pending_payment'
  ),
  -- Status: cancelled
  (
    '13000000-0000-0000-0000-000000000004'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000011'::uuid,  -- Client A
    '12000000-0000-0000-0000-000000000003'::uuid,  -- Slot A3
    '2026-06-18',
    'cancelled'
  ),
  -- Status: rejected
  (
    '13000000-0000-0000-0000-000000000005'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000012'::uuid,  -- Admin A (can also book)
    '12000000-0000-0000-0000-000000000001'::uuid,  -- Slot A1
    '2026-06-30',
    'rejected'
  ),
  -- Status: expired (D-04 Firebase status)
  (
    '13000000-0000-0000-0000-000000000006'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000011'::uuid,  -- Client A
    '12000000-0000-0000-0000-000000000002'::uuid,  -- Slot A2
    '2026-05-01',
    'expired'
  ),
  -- Status: refunded (D-04 Firebase status)
  (
    '13000000-0000-0000-0000-000000000007'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000011'::uuid,  -- Client A
    '12000000-0000-0000-0000-000000000003'::uuid,  -- Slot A3
    '2026-04-15',
    'refunded'
  )
ON CONFLICT (id) DO UPDATE
  SET user_id = EXCLUDED.user_id,
      status = EXCLUDED.status,
      updated_at = now();

-- Tenant B booking (for cross-tenant isolation testing)
INSERT INTO bookings (id, tenant_id, user_id, slot_id, booking_date, status) VALUES
  (
    '23000000-0000-0000-0000-000000000001'::uuid,
    '20000000-0000-0000-0000-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000021'::uuid,  -- Client B
    '22000000-0000-0000-0000-000000000001'::uuid,  -- Slot B1
    '2026-06-17',
    'confirmed'
  )
ON CONFLICT (id) DO UPDATE
  SET user_id = EXCLUDED.user_id,
      status = EXCLUDED.status,
      updated_at = now();

-- =============================================================================
-- Verification queries
-- =============================================================================
SELECT 'Tenants:' AS check, COUNT(*)::TEXT AS count FROM tenants
UNION ALL
SELECT 'Memberships:', COUNT(*)::TEXT FROM memberships
UNION ALL
SELECT 'Slots:', COUNT(*)::TEXT FROM slots
UNION ALL
SELECT 'Bookings:', COUNT(*)::TEXT FROM bookings
UNION ALL
SELECT 'Distinct booking statuses:', COUNT(DISTINCT status)::TEXT FROM bookings;
-- Expected: 2 tenants, 4 memberships, 4 slots, 8 bookings, 7 distinct statuses

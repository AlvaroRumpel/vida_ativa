-- =============================================================================
-- 01_schema.sql — Multi-Tenant PostgreSQL Schema
-- Spike: v7.0 Supabase Multi-Tenant Validation
-- Apply: psql "$SUPABASE_DB_URL" -f spike-supabase/schema/01_schema.sql
--
-- Tables: tenants, memberships, slots, bookings
-- All child tables have tenant_id FK to tenants.id
-- bookings has UNIQUE(tenant_id, slot_id, booking_date) — anti-double-booking
-- RLS enabled on all 4 tables (policies defined in 02_rls.sql)
-- Apply order: 01_schema.sql → 02_rls.sql → 03_seed.sql
-- =============================================================================

-- Drop tables in reverse dependency order (safe for re-runs during spike)
DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS slots CASCADE;
DROP TABLE IF EXISTS memberships CASCADE;
DROP TABLE IF EXISTS tenants CASCADE;

-- =============================================================================
-- Table: tenants
-- Root entity — every other table references this via tenant_id FK
-- =============================================================================
-- NOTE (spike): updated_at columns on tenants, slots, and bookings are NOT
-- auto-updated by triggers. Auto-update triggers are deferred to Phase 32.
-- The seed's ON CONFLICT DO UPDATE manually sets updated_at = now(), masking
-- this during re-runs. Any application UPDATE will leave updated_at stale.
CREATE TABLE tenants (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name        VARCHAR(255) NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
-- Table: memberships
-- Maps auth.users (Supabase Auth) to tenants with a role
-- role: 'client' = regular user; 'admin' = tenant administrator
-- user_id references auth.users.id (managed by Supabase Auth service)
-- =============================================================================
CREATE TABLE memberships (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   UUID        NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id     UUID        NOT NULL,  -- auth.users.id (Supabase Auth; no FK to avoid cross-schema constraint)
  role        VARCHAR(50) NOT NULL DEFAULT 'client'
                CONSTRAINT valid_membership_role CHECK (role IN ('client', 'admin')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(tenant_id, user_id)  -- one membership per user per tenant
);

-- Index for RLS policy performance (memberships queried by user_id frequently)
CREATE INDEX idx_memberships_tenant_id ON memberships(tenant_id);
CREATE INDEX idx_memberships_user_id   ON memberships(user_id);

-- =============================================================================
-- Table: slots
-- Recurring time slot template for a tenant (day_of_week + time window + price)
-- day_of_week: 1=Monday ... 7=Sunday (ISO 8601)
-- price: NUMERIC(10,2) for precise monetary values (BRL)
-- =============================================================================
CREATE TABLE slots (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id    UUID        NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  day_of_week  SMALLINT    NOT NULL CONSTRAINT valid_day_of_week CHECK (day_of_week BETWEEN 1 AND 7),
  start_time   TIME        NOT NULL,
  end_time     TIME        NOT NULL,
  price        NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
  is_active    BOOLEAN     NOT NULL DEFAULT true,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT valid_slot_time CHECK (end_time > start_time)
);

-- Index for RLS policy performance + common query patterns (day_of_week filter)
CREATE INDEX idx_slots_tenant_id        ON slots(tenant_id);
CREATE INDEX idx_slots_tenant_day       ON slots(tenant_id, day_of_week);

-- =============================================================================
-- Table: bookings
-- Instance of a slot being reserved on a specific date by a user
--
-- status: VARCHAR(50) + CHECK constraint (NOT ENUM per D-04)
--   Reason: ENUM type requires DDL migration to remove a value;
--   CHECK constraint allows simple ALTER TABLE ADD/DROP CONSTRAINT.
--   All 7 Firebase status values included to validate full model compatibility.
--
-- UNIQUE(tenant_id, slot_id, booking_date): database-level anti-double-booking.
--   PostgreSQL MVCC enforces this atomically — concurrent inserts get unique_violation.
--   Phase 32 adds book_slot() PL/pgSQL function with SELECT FOR UPDATE NOWAIT for
--   explicit locking as additional defense.
-- =============================================================================
CREATE TABLE bookings (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id    UUID        NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id      UUID        NOT NULL,  -- auth.users.id
  slot_id      UUID        NOT NULL REFERENCES slots(id) ON DELETE CASCADE,
  booking_date DATE        NOT NULL,
  status       VARCHAR(50) NOT NULL DEFAULT 'pending'
                 CONSTRAINT valid_booking_status CHECK (
                   status IN (
                     'pending',
                     'confirmed',
                     'cancelled',
                     'rejected',
                     'pending_payment',
                     'expired',
                     'refunded'
                   )
                 ),
  notes        TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Anti-double-booking: one booking per (tenant, slot, date)
  -- Phase 32 book_slot() function uses SELECT FOR UPDATE NOWAIT as additional guard
  CONSTRAINT unique_booking UNIQUE (tenant_id, slot_id, booking_date)
);

-- Indexes for RLS policy performance (critical: every SELECT scans by tenant_id)
CREATE INDEX idx_bookings_tenant_id      ON bookings(tenant_id);
CREATE INDEX idx_bookings_tenant_user    ON bookings(tenant_id, user_id);
CREATE INDEX idx_bookings_slot_date      ON bookings(slot_id, booking_date);
CREATE INDEX idx_bookings_status         ON bookings(tenant_id, status);

-- =============================================================================
-- Enable Row Level Security on all 4 tables
-- Policies are defined in 02_rls.sql (applied after this file)
-- Without policies, RLS blocks ALL access (deny-by-default behavior)
-- =============================================================================
ALTER TABLE tenants     ENABLE ROW LEVEL SECURITY;
ALTER TABLE memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE slots       ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings    ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- Verification queries (uncomment and run manually to confirm schema applied)
-- =============================================================================
-- SELECT tablename, rowsecurity FROM pg_tables
--   WHERE schemaname = 'public'
--   ORDER BY tablename;
-- Expected: 4 rows, all with rowsecurity = true

-- SELECT conname, contype, pg_get_constraintdef(oid)
--   FROM pg_constraint
--   WHERE conrelid = 'bookings'::regclass
--   ORDER BY contype;
-- Expected: includes UNIQUE constraint on (tenant_id, slot_id, booking_date)
--           and CHECK constraint on status with 7 values

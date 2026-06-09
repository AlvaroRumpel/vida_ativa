-- =============================================================================
-- 02_rls.sql — Row Level Security Policies
-- Spike: v7.0 Supabase Multi-Tenant Validation
-- Apply AFTER: 01_schema.sql
-- Apply: psql "$SUPABASE_DB_URL" -f spike-supabase/schema/02_rls.sql
--
-- Security model:
--   - All policies use auth.jwt() -> 'app_metadata' -> 'tenant_id' (server-set)
--   - NEVER uses auth.user_metadata() — user-modifiable, CVE-2025-48757
--   - All INSERT/UPDATE policies include WITH CHECK clause (Pitfall 2 prevention)
--   - Client role: sees only own bookings within tenant
--   - Admin role: sees ALL bookings within tenant
-- =============================================================================

-- =============================================================================
-- Helper: reusable expressions (as SQL comments for documentation)
-- JWT app_metadata access pattern (D-06):
--   tenant check:  (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
--   role check:    (auth.jwt() ->> 'app_metadata' ->> 'role')::text
-- =============================================================================

-- =============================================================================
-- TABLE: tenants
-- All authenticated users can read their own tenant record.
-- No direct INSERT/UPDATE/DELETE by client (tenants managed by spike admin).
-- =============================================================================

DROP POLICY IF EXISTS "tenants_select_own" ON tenants;
CREATE POLICY "tenants_select_own"
  ON tenants FOR SELECT
  TO authenticated
  USING (
    id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
  );

-- =============================================================================
-- TABLE: memberships
-- Users can read memberships for their tenant.
-- Admin can manage memberships for their tenant.
-- =============================================================================

DROP POLICY IF EXISTS "memberships_select_own_tenant" ON memberships;
CREATE POLICY "memberships_select_own_tenant"
  ON memberships FOR SELECT
  TO authenticated
  USING (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
  );

DROP POLICY IF EXISTS "memberships_insert_admin_only" ON memberships;
CREATE POLICY "memberships_insert_admin_only"
  ON memberships FOR INSERT
  TO authenticated
  WITH CHECK (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
    AND (auth.jwt() ->> 'app_metadata' ->> 'role')::text = 'admin'
  );

DROP POLICY IF EXISTS "memberships_update_admin_only" ON memberships;
CREATE POLICY "memberships_update_admin_only"
  ON memberships FOR UPDATE
  TO authenticated
  USING (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
    AND (auth.jwt() ->> 'app_metadata' ->> 'role')::text = 'admin'
  )
  WITH CHECK (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
    AND (auth.jwt() ->> 'app_metadata' ->> 'role')::text = 'admin'
  );

-- =============================================================================
-- TABLE: slots
-- All authenticated users in the tenant can read slots.
-- Only admins can create/modify slots.
-- =============================================================================

DROP POLICY IF EXISTS "slots_select_own_tenant" ON slots;
CREATE POLICY "slots_select_own_tenant"
  ON slots FOR SELECT
  TO authenticated
  USING (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
  );

DROP POLICY IF EXISTS "slots_insert_admin_only" ON slots;
CREATE POLICY "slots_insert_admin_only"
  ON slots FOR INSERT
  TO authenticated
  WITH CHECK (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
    AND (auth.jwt() ->> 'app_metadata' ->> 'role')::text = 'admin'
  );

DROP POLICY IF EXISTS "slots_update_admin_only" ON slots;
CREATE POLICY "slots_update_admin_only"
  ON slots FOR UPDATE
  TO authenticated
  USING (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
    AND (auth.jwt() ->> 'app_metadata' ->> 'role')::text = 'admin'
  )
  WITH CHECK (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
    AND (auth.jwt() ->> 'app_metadata' ->> 'role')::text = 'admin'
  );

DROP POLICY IF EXISTS "slots_delete_admin_only" ON slots;
CREATE POLICY "slots_delete_admin_only"
  ON slots FOR DELETE
  TO authenticated
  USING (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
    AND (auth.jwt() ->> 'app_metadata' ->> 'role')::text = 'admin'
  );

-- =============================================================================
-- TABLE: bookings — Differentiated client vs admin (D-07)
--
-- Client policies: user sees ONLY own bookings (user_id = auth.uid())
-- Admin policies:  admin sees ALL bookings in tenant
--
-- PostgreSQL evaluates multiple policies for same operation with OR logic:
-- User gets access if ANY policy USING clause is satisfied.
-- This means client + admin policies coexist correctly.
-- =============================================================================

-- Client: SELECT own bookings only (D-07)
DROP POLICY IF EXISTS "bookings_client_select" ON bookings;
CREATE POLICY "bookings_client_select"
  ON bookings FOR SELECT
  TO authenticated
  USING (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
    AND user_id = auth.uid()
    AND (auth.jwt() ->> 'app_metadata' ->> 'role')::text = 'client'
  );

-- Admin: SELECT ALL bookings in their tenant (D-07)
DROP POLICY IF EXISTS "bookings_admin_select" ON bookings;
CREATE POLICY "bookings_admin_select"
  ON bookings FOR SELECT
  TO authenticated
  USING (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
    AND (auth.jwt() ->> 'app_metadata' ->> 'role')::text = 'admin'
  );

-- Client: INSERT own bookings only (WITH CHECK required — Pitfall 2)
DROP POLICY IF EXISTS "bookings_client_insert" ON bookings;
CREATE POLICY "bookings_client_insert"
  ON bookings FOR INSERT
  TO authenticated
  WITH CHECK (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
    AND user_id = auth.uid()
    AND (auth.jwt() ->> 'app_metadata' ->> 'role')::text = 'client'
  );

-- Admin: INSERT bookings for their tenant (WITH CHECK required)
DROP POLICY IF EXISTS "bookings_admin_insert" ON bookings;
CREATE POLICY "bookings_admin_insert"
  ON bookings FOR INSERT
  TO authenticated
  WITH CHECK (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
    AND (auth.jwt() ->> 'app_metadata' ->> 'role')::text = 'admin'
  );

-- Client: UPDATE own bookings only (status changes, e.g. cancel)
DROP POLICY IF EXISTS "bookings_client_update" ON bookings;
CREATE POLICY "bookings_client_update"
  ON bookings FOR UPDATE
  TO authenticated
  USING (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
    AND user_id = auth.uid()
    AND (auth.jwt() ->> 'app_metadata' ->> 'role')::text = 'client'
  )
  WITH CHECK (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
    AND user_id = auth.uid()
    AND (auth.jwt() ->> 'app_metadata' ->> 'role')::text = 'client'
  );

-- Admin: UPDATE any booking in their tenant (confirm, reject, etc.)
DROP POLICY IF EXISTS "bookings_admin_update" ON bookings;
CREATE POLICY "bookings_admin_update"
  ON bookings FOR UPDATE
  TO authenticated
  USING (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
    AND (auth.jwt() ->> 'app_metadata' ->> 'role')::text = 'admin'
  )
  WITH CHECK (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
    AND (auth.jwt() ->> 'app_metadata' ->> 'role')::text = 'admin'
  );

-- Admin: DELETE bookings in their tenant
DROP POLICY IF EXISTS "bookings_admin_delete" ON bookings;
CREATE POLICY "bookings_admin_delete"
  ON bookings FOR DELETE
  TO authenticated
  USING (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
    AND (auth.jwt() ->> 'app_metadata' ->> 'role')::text = 'admin'
  );

-- =============================================================================
-- Verification query (uncomment and run manually after applying)
-- =============================================================================
-- SELECT schemaname, tablename, policyname, cmd, qual, with_check
--   FROM pg_policies
--   WHERE schemaname = 'public'
--   ORDER BY tablename, policyname;
-- Expected: 15+ policies across 4 tables, all with qual referencing app_metadata

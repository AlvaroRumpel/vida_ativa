# Feature Landscape: Supabase Multi-Tenant Spike

**Project:** Vida Ativa v7.0 Spike  
**Domain:** SaaS Court Booking with Multi-Tenant Isolation  
**Researched:** 2026-06-09  
**Research Confidence:** HIGH (official Supabase docs + auth hooks docs + PostgreSQL RLS + migration guides verified)

## Table Stakes

Features required for spike to prove multi-tenant viability. Without these, spike is invalid.

### ISOLATION-01: Multi-Tenant Schema with tenant_id Columns

**What:** Tables (tenants, memberships, slots, bookings) with tenant_id foreign key enforcing data isolation at schema level.

**Why expected:** All SaaS multi-tenant apps must segregate data by tenant at the database layer. Single-tenant Firebase model cannot express this; Supabase requires it to make RLS policies work.

**Complexity:** Low (standard SQL DDL)

**What's involved:**
```sql
CREATE TABLE tenants (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL
);

CREATE TABLE memberships (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  user_id UUID NOT NULL,
  role TEXT NOT NULL -- 'client' or 'admin'
);

CREATE TABLE slots (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  day_of_week INT NOT NULL, -- 0=Sun, 1=Mon, etc.
  start_time TIME NOT NULL,
  price NUMERIC NOT NULL
);

CREATE TABLE bookings (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  slot_id UUID NOT NULL REFERENCES slots(id),
  booking_date DATE NOT NULL,
  status TEXT NOT NULL, -- 'confirmed', 'pending_payment', etc.
  CONSTRAINT unique_booking UNIQUE(tenant_id, slot_id, booking_date)
);
```

**Note:** `booking_date` separates booking instances (same slot can be booked on different dates).

**Dependency:** NONE — foundational.

---

### ISOLATION-02: RLS Policies with JWT Custom Claims (Multi-Tenant)

**What:** Row-level security policies that check `auth.jwt() ->> 'tenant_id'` against table's `tenant_id` column.

**Why expected:** RLS is Postgres's built-in row-filtering mechanism. Without it, queries have no database-enforced access boundary. Custom claims in JWT (`tenant_id`) tell the database "this user belongs to tenant X" so RLS can filter every query.

**Complexity:** Medium (SQL DDL + understanding JWT claim flow)

**Pattern — Client Access (sees own bookings only):**
```sql
-- RLS policy: client can only see bookings for their own user_id in their tenant
CREATE POLICY "clients_see_own_bookings"
  ON bookings
  FOR SELECT
  TO authenticated
  USING (
    auth.jwt() ->> 'tenant_id' = tenant_id::TEXT
    AND user_id = auth.uid()
  );

-- RLS policy: client can INSERT a booking only if it's their user_id and their tenant
CREATE POLICY "clients_book_own_slots"
  ON bookings
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.jwt() ->> 'tenant_id' = tenant_id::TEXT
    AND user_id = auth.uid()
  );
```

**Pattern — Admin Access (sees all tenant bookings):**
```sql
-- RLS policy: admin can see all bookings in their tenant
CREATE POLICY "admins_see_all_tenant_bookings"
  ON bookings
  FOR SELECT
  TO authenticated
  USING (
    auth.jwt() ->> 'tenant_id' = tenant_id::TEXT
    AND EXISTS (
      SELECT 1 FROM memberships m
      WHERE m.user_id = auth.uid()
      AND m.tenant_id = bookings.tenant_id
      AND m.role = 'admin'
    )
  );

-- RLS policy: admin can UPDATE bookings in their tenant
CREATE POLICY "admins_manage_tenant_bookings"
  ON bookings
  FOR UPDATE
  TO authenticated
  USING (
    auth.jwt() ->> 'tenant_id' = tenant_id::TEXT
    AND EXISTS (
      SELECT 1 FROM memberships m
      WHERE m.user_id = auth.uid()
      AND m.tenant_id = bookings.tenant_id
      AND m.role = 'admin'
    )
  );
```

**Key decision:** Use `auth.jwt() ->> 'tenant_id'` (JWT claim) vs membership join lookup. JWT approach is faster (no extra join) and used industry-wide.

**Dependency:** ISOLATION-01 (tables must exist), ISOLATION-03 (custom claims must reach JWT).

---

### ISOLATION-03: JWT Custom Claims Setup (tenant_id via auth_metadata)

**What:** Supabase Auth hook that adds `tenant_id` to user's `raw_app_meta_data`, making it accessible in RLS policies via `auth.jwt() ->> 'tenant_id'`.

**Why expected:** RLS policies need to know which tenant the user belongs to. Supabase Auth JWTs encode `app_metadata` (immutable, server-set) into the token. Without custom claims, RLS has no tenant context.

**Complexity:** Medium (Supabase Auth hooks + PL/pgSQL)

**Pattern — Custom Access Token Hook:**
```sql
-- Hook runs after user signs in, before token is issued
-- Adds tenant_id from memberships table to JWT claims
CREATE OR REPLACE FUNCTION handle_custom_claims()
RETURNS void AS $$
DECLARE
  tenant_id UUID;
BEGIN
  -- Fetch the user's primary tenant_id from memberships
  SELECT m.tenant_id INTO tenant_id
  FROM memberships m
  WHERE m.user_id = auth.uid()
  LIMIT 1; -- Use first membership (or implement "primary tenant" logic)
  
  -- Update user's app_metadata to include tenant_id
  UPDATE auth.users
  SET raw_app_meta_data = raw_app_meta_data || jsonb_build_object('tenant_id', tenant_id::text)
  WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql;
```

**Important:** Store tenant_id in `raw_app_meta_data` (immutable, server-set), NOT `raw_user_meta_data` (user-modifiable, security risk).

**Flow:**
1. User logs in via Supabase Auth
2. Custom Access Token hook fires
3. Hook adds `tenant_id` to JWT claims
4. Flutter app receives JWT with `tenant_id` claim
5. Supabase JS client automatically decodes JWT on every request
6. RLS policies read JWT claims and filter data

**Dependency:** ISOLATION-01 (memberships table must exist), ISOLATION-04 (tenant context at signup).

---

### ISOLATION-04: Tenant Context at Signup (Multi-Tenant Registration)

**What:** User signs up, specifies which tenant they're joining (or creates a new one), and membership is created atomically.

**Why expected:** Single-tenant Firebase app has no tenant concept at signup. Supabase multi-tenant spike needs to prove tenant assignment works end-to-end: user signs in → tenant context set → RLS filters apply.

**Complexity:** Medium (Auth + DB transaction)

**Pattern — Sign Up with Tenant:**
```typescript
// On Flutter/web client
const { user, error } = await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'secure_password',
  options: {
    data: { tenant_id: 'UUID_of_tenant' } // Passed to auth hook
  }
});

// OR: Create a new tenant during signup
const { data: tenant } = await supabase
  .from('tenants')
  .insert([{ name: 'My Arena' }])
  .select();

// Then sign up user and create membership
const { user } = await supabase.auth.signUp({ ... });
await supabase
  .from('memberships')
  .insert([
    { user_id: user.id, tenant_id: tenant.id, role: 'admin' }
  ]);
```

**Note:** Firebase single-tenant model assumed one implicit tenant. Spike must validate that explicit tenant selection at signup doesn't break UX.

**Dependency:** ISOLATION-01, ISOLATION-03.

---

### BOOKING-01: Anti-Double-Booking via UNIQUE(tenant_id, slot_id, booking_date)

**What:** Postgres UNIQUE constraint on (tenant_id, slot_id, booking_date) that prevents two users from booking the same slot on the same date.

**Why expected:** Firebase version uses atomic Firestore transactions to prevent double-booking. Postgres version must achieve same guarantee. UNIQUE constraint + Postgres's MVCC handles concurrent inserts correctly.

**Complexity:** Low (SQL constraint)

**Implementation:**
```sql
ALTER TABLE bookings
ADD CONSTRAINT unique_booking_per_tenant_slot_date
UNIQUE (tenant_id, slot_id, booking_date);
```

**How concurrent inserts work:**
- User A clicks "Book Slot 1 on 2026-06-10"
- User B clicks "Book Slot 1 on 2026-06-10" simultaneously
- Transaction A inserts first, succeeds
- Transaction B tries to insert with same (tenant_id, slot_id, date) tuple
- Postgres detects violation, rolls back transaction B
- Client receives `unique_violation` error, can show "Slot just booked" message

**Postgres handles this without explicit locks** because:
1. MVCC (Multi-Version Concurrency Control) ensures isolation
2. UNIQUE index check happens after row insert attempt
3. If two transactions insert same key, second one sees the first's committed row and fails

**Dependency:** ISOLATION-01 (bookings table).

---

### BOOKING-02: book_slot() PL/pgSQL Function (Anti-Double-Booking + Error Handling)

**What:** Stored procedure that attempts to insert a booking, catches UNIQUE constraint violation, and returns meaningful error (vs raw SQL error from client).

**Why expected:** Clients need distinguishable error messages: "Slot already booked" vs "Invalid tenant_id" vs "Slot doesn't exist". Raw SQL `unique_violation` is cryptic. Function wraps the logic and translates errors.

**Complexity:** Medium (PL/pgSQL exception handling)

**Pattern:**
```sql
CREATE OR REPLACE FUNCTION book_slot(
  p_tenant_id UUID,
  p_slot_id UUID,
  p_booking_date DATE,
  p_user_id UUID
)
RETURNS TABLE(success BOOLEAN, error_code TEXT, error_message TEXT) AS $$
DECLARE
  v_booking_id UUID;
BEGIN
  v_booking_id := gen_random_uuid();
  
  -- Attempt insert with transaction semantics
  INSERT INTO bookings (
    id, tenant_id, slot_id, booking_date, user_id, status, created_at
  )
  VALUES (
    v_booking_id, p_tenant_id, p_slot_id, p_booking_date, p_user_id, 'pending', NOW()
  );
  
  RETURN QUERY SELECT true, NULL::TEXT, NULL::TEXT;

EXCEPTION
  -- Catch UNIQUE constraint violation
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'SLOT_ALREADY_BOOKED'::TEXT, 
      'This slot is already booked on this date'::TEXT;
  
  -- Catch foreign key violations (invalid slot_id, tenant_id, or user_id)
  WHEN foreign_key_violation THEN
    RETURN QUERY SELECT false, 'INVALID_REFERENCE'::TEXT,
      'Slot, tenant, or user does not exist'::TEXT;
  
  -- Catch RLS policy violations (shouldn't happen if RLS is correct)
  WHEN insufficient_privilege THEN
    RETURN QUERY SELECT false, 'INSUFFICIENT_PRIVILEGE'::TEXT,
      'You do not have permission to book in this tenant'::TEXT;
  
  -- Catch any other error
  WHEN OTHERS THEN
    RETURN QUERY SELECT false, SQLSTATE::TEXT, SQLERRM::TEXT;
END;
$$ LANGUAGE plpgsql;
```

**Usage from client:**
```typescript
const { data, error } = await supabase
  .rpc('book_slot', {
    p_tenant_id: tenantId,
    p_slot_id: slotId,
    p_booking_date: date,
    p_user_id: userId
  });

if (data.success) {
  // Navigate to confirmation
} else if (data.error_code === 'SLOT_ALREADY_BOOKED') {
  // Show "This slot just got booked" toast
} else {
  // Handle other errors
}
```

**Dependency:** ISOLATION-01, BOOKING-01, ISOLATION-02 (RLS policies must exist to enforce permission).

---

### BOOKING-03: Concurrent Booking Test (SELECT FOR UPDATE Validation)

**What:** Test script that simulates two simultaneous `book_slot()` calls for the same slot/date and verifies exactly one succeeds.

**Why expected:** Double-booking protection is worthless if not tested under concurrency. Spike must prove that concurrent transactions don't both succeed.

**Complexity:** Medium (psql scripting + transaction isolation knowledge)

**Pattern — Concurrent Test (psql):**
```sql
-- Session A
BEGIN;
SELECT book_slot(
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::UUID,  -- tenant_id
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::UUID,  -- slot_id
  '2026-06-15'::DATE,
  'cccccccc-cccc-cccc-cccc-cccccccccccc'::UUID   -- user_id A
);
-- Hold transaction open. In another terminal:

-- Session B (before Session A commits)
SELECT book_slot(
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::UUID,
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::UUID,
  '2026-06-15'::DATE,
  'dddddddd-dddd-dddd-dddd-dddddddddddd'::UUID   -- user_id B
);
-- Expected: SLOT_ALREADY_BOOKED error OR waits (if SELECT FOR UPDATE is used)

-- Session A
COMMIT;
```

**Alternative pattern (with SELECT FOR UPDATE locking):**
```sql
CREATE OR REPLACE FUNCTION book_slot_with_lock(...)
RETURNS TABLE(...) AS $$
BEGIN
  -- Lock the slot row to prevent concurrent bookings
  SELECT 1 FROM slots s
  WHERE s.id = p_slot_id
  FOR UPDATE NOWAIT; -- Fail immediately if locked
  
  -- Now safe to insert
  INSERT INTO bookings ...
END;
$$ LANGUAGE plpgsql;
```

**Trade-off:** NOWAIT is faster but higher contention (users get "locked" error). Without NOWAIT, users wait for lock (slower but fairer).

**Dependency:** BOOKING-02.

---

## Differentiators

Features that increase confidence in spike validity but aren't minimum table-stakes.

### ISOLATION-05: Cross-Tenant Attack Proof #1 — SELECT Isolation

**What:** Test script verifying that a user from Tenant A cannot SELECT bookings from Tenant B even if they know the booking ID.

**Why valuable:** Proves RLS actually enforces isolation, not just application-level filtering.

**Complexity:** Low (psql test)

**Test:**
```sql
-- Connect as Tenant B user
-- Manually try to query a booking from Tenant A
SELECT * FROM bookings WHERE id = 'booking_id_from_tenant_a'::UUID;
-- Expected result: 0 rows (RLS hides it)

-- If RLS is broken, result: 1 row (vulnerability!)
```

**Expected behavior when RLS is correct:**
```
postgres=> SELECT * FROM bookings WHERE id = 'booking_from_tenant_a';
(0 rows)
```

**Expected behavior if RLS is broken (security failure):**
```
postgres=> SELECT * FROM bookings WHERE id = 'booking_from_tenant_a';
 id | tenant_id | user_id | ... |
```

**Dependency:** ISOLATION-01, ISOLATION-02, ISOLATION-03.

---

### ISOLATION-06: Cross-Tenant Attack Proof #2 — INSERT Isolation

**What:** Test script verifying that a user from Tenant A cannot INSERT a booking into Tenant B even if they explicitly set `tenant_id = tenant_b_id` in the INSERT.

**Why valuable:** Proves RLS WITH CHECK clause prevents privilege escalation.

**Complexity:** Low (psql test)

**Test:**
```sql
-- Connect as Tenant A user (their JWT has tenant_a_id)
INSERT INTO bookings (
  id, tenant_id, slot_id, booking_date, user_id, status
)
VALUES (
  'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'::UUID,
  'tenant_b_id'::UUID,  -- Attacker tries to write to Tenant B
  'slot_id'::UUID,
  '2026-06-15'::DATE,
  'user_a_id'::UUID,
  'confirmed'
);
-- Expected: RLS WITH CHECK violation, INSERT fails
```

**Expected behavior when RLS is correct:**
```
postgres=> INSERT INTO bookings ... VALUES (..., 'tenant_b_id', ...);
ERROR: new row violates row-level security policy "admins_manage_tenant_bookings"
```

**Dependency:** ISOLATION-02 (WITH CHECK clause in INSERT policy).

---

### ISOLATION-07: Cross-Tenant Attack Proof #3 — UPDATE Isolation

**What:** Test script verifying that a user from Tenant A cannot UPDATE a booking from Tenant B.

**Why valuable:** Proves RLS prevents lateral movement (modifying data they shouldn't access).

**Complexity:** Low (psql test)

**Test:**
```sql
-- Connect as Tenant A user
UPDATE bookings SET status = 'cancelled'
WHERE id = 'booking_id_from_tenant_b'::UUID;
-- Expected: RLS USING clause blocks UPDATE, 0 rows affected
```

**Expected behavior:**
```
postgres=> UPDATE bookings SET status = 'cancelled' WHERE id = '...';
UPDATE 0
```

**Dependency:** ISOLATION-02 (USING clause in UPDATE policy).

---

## Anti-Features

Features explicitly NOT built in spike.

### NO-AUTH-MIGRATION: Password Migration (Firebase → Supabase)

**Why avoid:** Firebase exports user metadata but NOT password hashes (security design). Firebase uses SCRYPT, Supabase uses bcrypt — incompatible algorithms. Silent migration impossible.

**What to do instead:** For spike, assume new Supabase users (or use test accounts). For production migration later: either (a) parallel auth (Firebase + Supabase, sync on login), or (b) force password reset emails.

**Complexity if attempted:** HIGH — requires parallel auth infrastructure or user communication campaign.

---

### NO-REALTIME-SUBSCRIPTION: Postgres Changes Realtime

**Why avoid:** Spike scope is "can we isolate tenants?" not "can we broadcast slot changes live?". Realtime adds complexity (WebSocket subscriptions, RLS authorization per message). Can be added post-spike.

**What to do instead:** Spike uses polling or manual refresh. Production can add Postgres Changes later.

**Complexity if attempted:** MEDIUM — straightforward but adds variable performance issues under load.

---

### NO-GOOGLE-AUTH-MIGRATION: Social Login (Google)

**Why avoid:** Firebase has built-in Google OAuth. Supabase can too, but migrating existing user linkages (Firebase UID → Supabase UUID) requires mapping table. Out of spike scope.

**What to do instead:** Spike uses email/password only. Production migration handles Google OAuth separately.

---

## Feature Dependencies

```
ISOLATION-04 (tenant signup)
  ↓
ISOLATION-01 (schema with tenant_id)
  ↓
ISOLATION-03 (custom claims) + ISOLATION-02 (RLS policies)
  ↓
BOOKING-01 (UNIQUE constraint)
  ↓
BOOKING-02 (book_slot function)
  ↓
BOOKING-03 (concurrent test)

ISOLATION-02 (RLS)
  ↓
ISOLATION-05, 06, 07 (attack proofs)
```

## MVP Recommendation for Spike

**Phase 1: Infrastructure (Proof RLS Isolation Works)**
1. ISOLATION-01 — Schema with tenant_id
2. ISOLATION-02 — RLS policies (client + admin)
3. ISOLATION-03 — JWT custom claims
4. ISOLATION-05, 06, 07 — Attack proofs (document as PASS/FAIL)

**Phase 2: Booking (Proof Anti-Double-Booking Works)**
5. BOOKING-01 — UNIQUE constraint
6. BOOKING-02 — book_slot function
7. BOOKING-03 — Concurrent test

**Phase 3: Flutter Integration (Proof Flutter Can Use Multi-Tenant Supabase)**
8. ISOLATION-04 — Signup flow with tenant context
9. RLS + booking read/write via Flutter SDK

**Defer to v7.1+:**
- Realtime subscriptions (Postgres Changes)
- Google OAuth migration
- Password migration from Firebase
- Webhook integrations (Mercado Pago)

## Sources

### Official Supabase Documentation
- [Row Level Security | Supabase Docs](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Custom Claims & Role-based Access Control (RBAC) | Supabase Docs](https://supabase.com/docs/guides/database/postgres/custom-claims-and-role-based-access-control-rbac)
- [Custom Access Token Hook | Supabase Docs](https://supabase.com/docs/guides/auth/auth-hooks/custom-access-token-hook)
- [JWT Claims Reference | Supabase Docs](https://supabase.com/docs/guides/auth/jwt-fields)
- [Testing Overview | Supabase Docs](https://supabase.com/docs/guides/local-development/testing/overview)
- [RLS Performance and Best Practices | Supabase Docs](https://supabase.com/docs/guides/troubleshooting/rls-performance-and-best-practices-Z5Jjwv)
- [Migrate from Firebase Auth to Supabase | Supabase Docs](https://supabase.com/docs/guides/platform/migrating-to-supabase/firebase-auth)

### Community & Best Practices
- [Enforcing Row Level Security in Supabase: A Deep Dive into LockIn's Multi-Tenant Architecture - DEV Community](https://dev.to/blackie360/-enforcing-row-level-security-in-supabase-a-deep-dive-into-lockins-multi-tenant-architecture-4hd2)
- [Supabase RLS Best Practices: Production Patterns for Secure Multi-Tenant Apps](https://makerkit.dev/blog/tutorials/supabase-rls-best-practices)
- [Supabase RLS Guide: Policies That Actually Work](https://designrevision.com/blog/supabase-rls-row-level-security)

### PostgreSQL Concurrency & Locking
- [SELECT FOR UPDATE - Reduce Contention and Avoid Deadlocks](https://stormatics.tech/blogs/select-for-update-in-postgresql)
- [Efficient Database Transactions Using PostgreSQL: Best Practices](https://iniakunhuda.medium.com/efficient-database-transactions-using-postgresql-best-practices-and-optimization-techniques-9652d4ce53c0)

### Migration Patterns
- [How to Migrate a Flutter App from Firebase to Supabase (2026 Guide)](https://theappstudio.co/blog/how-to-migrate-firebase-to-supabase)
- [How I Migrated 1000+ Users from Firebase to Supabase](https://www.fleetingnotes.app/posts/migrating-from-firebase-to-supabase)
- [Supabase vs Firebase: We Migrated 14 Projects. Here Is What Broke.](https://cotera.co/articles/supabase-vs-firebase-comparison)

### Performance & Scaling
- [Benchmarks | Supabase Docs](https://supabase.com/docs/guides/realtime/benchmarks)
- [Realtime Limits | Supabase Docs](https://supabase.com/docs/guides/realtime/limits)
- [Supabase: Support Multi-Tenancy With Detail + Template Project | Medium](https://medium.com/@itsuki.enjoy/supabase-support-multi-tenancy-with-detail-template-project-34f3a3d97ee4)

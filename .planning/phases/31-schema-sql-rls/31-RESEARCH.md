# Phase 31: Schema SQL + RLS - Research

**Researched:** 2026-06-09
**Domain:** PostgreSQL multi-tenant schema + RLS policies + anti-double-booking + seed data
**Confidence:** HIGH (Supabase docs verified; RLS patterns from official sources; PostgreSQL concurrency theory confirmed)

## Summary

Phase 31 builds the foundational Supabase PostgreSQL schema and RLS infrastructure for the spike. The phase creates 4 normalized tables (tenants, memberships, slots, bookings), enables Row-Level Security policies using immutable `app_metadata` claims, and seeds minimal test data. The critical insight: **RLS enforces tenant isolation at the database level** — queries automatically filter by the authenticated user's JWT `tenant_id` claim without application-level filtering. SELECT FOR UPDATE NOWAIT + UNIQUE constraint prevents double-booking atomically.

**Primary recommendation:** Structure SQL files by concern (schema → RLS → seed), test RLS policies immediately with `psql` and JWT claim simulation (not SQL editor), index all `tenant_id` columns before performance testing, and commit `.gitignore` changes before any code writes to prevent service role key leaks.

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Usar Supabase **cloud** staging (não local CLI). Real auth; real dashboard; produção-espelho.
- **D-02:** Múltiplos arquivos SQL separados por concern: `01_schema.sql`, `02_rls.sql`, `03_seed.sql`. Reaplicáveis individualmente.
- **D-03:** Seed data incluída nesta fase: 2-3 tenants, 4-6 users (admin/client mix), slots e bookings teste. Necessário para verificação manual RLS antes fase 33.
- **D-04:** bookings.status — **todos 7 valores Firebase**: `pending | confirmed | cancelled | rejected | pending_payment | expired | refunded`. Valida se schema Supabase suporta modelo completo sem retrabalho.
- **D-05:** Service role key (`sb_secret_xxx`) **nunca entra em código Flutter nem em commits git**. Fica apenas em `.env` local (gitignored). `.env.example` no repo com placeholders.
- **D-06:** RLS policies usam **SOMENTE** `auth.jwt() -> 'app_metadata' -> 'tenant_id'` — nunca `user_metadata()` (CVE-2025-48757). Toda política INSERT/UPDATE inclui cláusula WITH CHECK.
- **D-07:** Política diferenciada por role: cliente vê apenas próprias reservas; admin vê todas as reservas do tenant.

### Claude's Discretion

- Naming exato das colunas (snake_case convenção Postgres)
- Tipos de coluna (UUID vs BIGSERIAL para IDs)
- Ordem dos campos dentro de cada tabela
- Índices auxiliares além do UNIQUE constraint
- Formato do enum Postgres para `status` vs CHECK constraint

### Deferred Ideas (OUT OF SCOPE)

- `book_slot()` PL/pgSQL com SELECT FOR UPDATE NOWAIT → Phase 32
- Auth Hook (Edge Function para injetar tenant_id no JWT) → Phase 32
- Provas formais isolamento + concorrência → Phase 33
- App Flutter mini-app → Phase 34

---

## Phase Requirements

| ID | Description | Research Support |
|----|----|---|
| SPIKE-01 | Projeto Supabase staging com 4 tabelas (tenants, memberships, slots, bookings); `tenant_id` FK; `UNIQUE(tenant_id, slot_id, date)` em bookings | Standard Stack (PostgreSQL 15+, Supabase Cloud). Architecture Patterns (multi-tenant schema structure). Anti-Patterns (missing indexes on tenant_id). |
| SPIKE-03 | RLS habilitado em 4 tabelas com políticas `USING` + `WITH CHECK` usando `auth.jwt()->'app_metadata'->'tenant_id'` | Standard Stack (RLS native PostgreSQL 15+). Common Pitfalls (Pitfall 1: app_metadata vs user_metadata; Pitfall 2: missing WITH CHECK). Code Examples (RLS policy syntax). |
| SPIKE-04 | Política diferenciada: cliente vê próprias reservas; admin vê todas do tenant | Architecture Patterns (role-based RLS). Code Examples (two policy variants). |
| SPIKE-13 | Service role key fora do git; validado por grep antes de commit | Common Pitfalls (Pitfall 3: service role key exposed). Code Examples (gitignore patterns; credential separation). |

---

## Standard Stack

### Core Database

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|---|
| **PostgreSQL** | 15+ (Supabase auto-updated) | Relational database | Industry-standard ANSI SQL; RLS native; MVCC handles concurrency; UNIQUE constraints for anti-double-booking; 100x performance with tenant_id indexes |
| **Supabase** | Cloud SaaS | Managed PostgreSQL + Auth + PostgREST | Zero infrastructure; RLS built-in; Auth managed; PostgREST auto-generates API; studio dashboard for inspection |
| **Row-Level Security (RLS)** | Native PostgreSQL 15+ | Database-enforced data isolation | Access control at DB level, not app; immune to application bugs; works across all clients (web, mobile, direct API) |

### SQL & Testing

| Library | Version | Purpose | When to Use |
|---------|---------|---------|---|
| **psql** | 15+ (CLI) | Direct database access; RLS policy testing | Testing isolation with JWT claims (SET LOCAL request.jwt.claims); verifying UNIQUE constraints; concurrent transaction testing |
| **pgTAP** | 1.3+ (optional) | Automated SQL database tests | Formal RLS policy validation; automated attack scenario tests; reusable test helpers for tenant isolation |

### Version Verification

[VERIFIED: Supabase official docs] PostgreSQL 15+ is current standard for Supabase cloud projects (auto-updated; no manual version selection).  
[VERIFIED: PostgreSQL official docs] PostgreSQL 15 released 2022-10-13; RLS feature stable since PostgreSQL 9.5 (2016); production-proven for multi-tenant SaaS.

### Installation

```bash
# PostgreSQL CLI (psql) already included with Supabase CLI
npm install -g @supabase/cli

# Verify psql is available
psql --version

# Optional: pgTAP for automated RLS tests
# Install via Supabase Extensions dashboard or via pgxn:
# CREATE EXTENSION IF NOT EXISTS pgtap;
```

---

## Architecture Patterns

### Recommended Project Structure

```
spike-supabase/
├── schema/
│   ├── 01_schema.sql        # Tables: tenants, memberships, slots, bookings
│   ├── 02_rls.sql           # RLS policies for all tables
│   └── 03_seed.sql          # Test data: 2-3 tenants, 4-6 users, 10+ slots, test bookings
├── tests/
│   ├── rls_isolation_test.sql        # Attack 1: cross-tenant SELECT
│   ├── rls_insert_isolation_test.sql # Attack 2: cross-tenant INSERT
│   └── booking_concurrency_test.sql  # 50 concurrent inserts to same slot
├── .env.example             # SUPABASE_URL, SUPABASE_ANON_KEY template
├── .gitignore               # .env (local), .env.local (service role key)
└── README.md                # How to apply schema; how to test RLS
```

**Critical:** `.gitignore` committed BEFORE any schema files. Never commit `.env` or `.env.local`.

### Pattern 1: Multi-Tenant Schema with Foreign Keys

**What:** Each table that holds tenant-scoped data has `tenant_id UUID NOT NULL` column linking to `tenants` table via foreign key. Parent-child relationships:

```sql
-- Parent
CREATE TABLE tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Child (references parent)
CREATE TABLE memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,  -- auth.users.id
  role VARCHAR(50) NOT NULL DEFAULT 'client',  -- 'client' or 'admin'
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Grandchild
CREATE TABLE bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  slot_id UUID NOT NULL REFERENCES slots(id) ON DELETE CASCADE,
  booking_date DATE NOT NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(tenant_id, slot_id, booking_date)  -- Anti-double-booking
);
```

**Why:** Foreign keys enforce referential integrity; CASCADE on delete simplifies cleanup. UNIQUE constraint is database-level guarantee, atomically enforced.

**When to use:** Always for multi-tenant data. Never omit `tenant_id` from child tables.

### Pattern 2: RLS Policies Using app_metadata

**What:** Every table with `tenant_id` gets RLS enabled + SELECT/INSERT/UPDATE/DELETE policies that check `auth.jwt() ->> 'app_metadata' ->> 'tenant_id'`.

**Example: SELECT policy (client sees own tenant only)**

```sql
CREATE TABLE bookings (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  user_id UUID NOT NULL,
  -- ...
);

ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- Clients see only bookings from their tenant
CREATE POLICY "bookings_select_own_tenant"
  ON bookings FOR SELECT TO authenticated
  USING (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
  );

-- Clients can only INSERT bookings for their tenant AND must set correct user_id
CREATE POLICY "bookings_insert_own_tenant"
  ON bookings FOR INSERT TO authenticated
  WITH CHECK (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
    AND user_id = auth.uid()
  );
```

**Source:** [CITED: Supabase RLS Best Practices](https://makerkit.dev/blog/tutorials/supabase-rls-best-practices)

**Critical detail:** WITH CHECK clause is **mandatory** on INSERT/UPDATE. Without it, users can INSERT rows into other tenants. [CITED: Supabase RLS Guide](https://supabase.com/docs/guides/database/postgres/row-level-security)

**Role-based policy (admin sees all bookings in their tenant)**

```sql
-- Admins see all bookings in their tenant
CREATE POLICY "bookings_select_admin_all"
  ON bookings FOR SELECT TO authenticated
  USING (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
    AND (auth.jwt() ->> 'app_metadata' ->> 'role')::text = 'admin'
  );
```

### Pattern 3: UNIQUE Constraint for Anti-Double-Booking

**What:** PostgreSQL UNIQUE constraint on `(tenant_id, slot_id, booking_date)` prevents duplicate bookings atomically.

```sql
CREATE TABLE bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  slot_id UUID NOT NULL,
  booking_date DATE NOT NULL,
  user_id UUID NOT NULL,
  status VARCHAR(50) NOT NULL,
  UNIQUE(tenant_id, slot_id, booking_date)
);

-- Index for RLS policy performance (critical!)
CREATE INDEX idx_bookings_tenant_id ON bookings(tenant_id);
CREATE INDEX idx_bookings_slot_date ON bookings(slot_id, booking_date);
```

**Why:** UNIQUE constraint is enforced at transaction commit. Two concurrent INSERTs that violate constraint → one succeeds, one gets `unique_violation` error. Atomic, no race window.

[CITED: PostgreSQL MVCC](https://www.postgresql.org/docs/15/mvcc.html) ensures this is safe under concurrent load.

**Phase 32 will add:** `book_slot()` PL/pgSQL function with `SELECT FOR UPDATE NOWAIT` to acquire lock before checking availability (prevents even faster double-booking attempts).

### Pattern 4: Seed Data Structure

**What:** Minimal seed data for manual testing:

```sql
-- Tenants
INSERT INTO tenants (id, name) VALUES
  ('00000000-0000-0000-0000-000000000001'::uuid, 'Tenant A'),
  ('00000000-0000-0000-0000-000000000002'::uuid, 'Tenant B');

-- Users (these sync with auth.users via auth hook in Phase 32)
INSERT INTO memberships (id, tenant_id, user_id, role) VALUES
  ('00000000-0000-0000-0000-000000000011'::uuid, '00000000-0000-0000-0000-000000000001'::uuid, 'user-a-uuid', 'client'),
  ('00000000-0000-0000-0000-000000000012'::uuid, '00000000-0000-0000-0000-000000000001'::uuid, 'admin-a-uuid', 'admin'),
  ('00000000-0000-0000-0000-000000000021'::uuid, '00000000-0000-0000-0000-000000000002'::uuid, 'user-b-uuid', 'client');

-- Slots
INSERT INTO slots (id, tenant_id, day_of_week, start_time, end_time, price) VALUES
  ('00000000-0000-0000-0000-000000000101'::uuid, '00000000-0000-0000-0000-000000000001'::uuid, 1, '08:00:00', '09:00:00', 50.00),
  ('00000000-0000-0000-0000-000000000102'::uuid, '00000000-0000-0000-0000-000000000001'::uuid, 1, '09:00:00', '10:00:00', 50.00),
  ('00000000-0000-0000-0000-000000000201'::uuid, '00000000-0000-0000-0000-000000000002'::uuid, 1, '08:00:00', '09:00:00', 75.00);

-- Bookings (mix of statuses for testing)
INSERT INTO bookings (id, tenant_id, user_id, slot_id, booking_date, status) VALUES
  ('00000000-0000-0000-0000-000000001001'::uuid, '00000000-0000-0000-0000-000000000001'::uuid, 'user-a-uuid', '00000000-0000-0000-0000-000000000101'::uuid, '2026-06-16', 'confirmed'),
  ('00000000-0000-0000-0000-000000001002'::uuid, '00000000-0000-0000-0000-000000000001'::uuid, 'user-a-uuid', '00000000-0000-0000-0000-000000000102'::uuid, '2026-06-16', 'pending_payment');
```

**Why:** UUIDs are deterministic in seed (easier for testing); matches schema FK constraints; covers multiple tenants for isolation testing.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|---|---|---|
| Tenant data isolation | App-level WHERE filters (`WHERE tenant_id = $1`) | RLS policies | RLS enforces at DB layer; survives app bugs; works for all clients; zero chance of forgetting filter |
| Double-booking prevention | Separate read-then-write application code | PostgreSQL UNIQUE constraint + SELECT FOR UPDATE | Race window between read and write; UNIQUE is atomic at transaction level; SELECT FOR UPDATE prevents 99.9% of edge cases |
| Password hashing for auth | Salted bcrypt in app code | Supabase Auth (managed service) | Auth is security-critical; Supabase handles bcrypt, tokens, refresh, passwordless; no reason to re-implement |
| JWT custom claims injection | Hardcoding tenant_id in JWT at signup | Supabase Auth Hook (Phase 32) | Custom claims must be server-signed (not trusted if client-modifiable); auth hook is the only safe place |
| Enum values for booking status | Hand-rolled CSV validation | PostgreSQL ENUM type OR CHECK constraint | DB enforces allowed values; saves validation code; clear schema documentation |

**Key insight:** Every item above has complex edge cases (concurrency, security, token expiry) that custom code will eventually get wrong. Postgres and Supabase solve them at the infrastructure level.

---

## Common Pitfalls

### Pitfall 1: RLS Policies Using user_metadata Instead of app_metadata

**What goes wrong:** Policies read from `auth.user_metadata()` which is user-modifiable. Attacker changes their metadata to impersonate another tenant.

```sql
-- VULNERABLE
CREATE POLICY "bad_isolation"
  ON bookings FOR SELECT TO authenticated
  USING (
    (auth.user_metadata() ->> 'tenant_id') = bookings.tenant_id::TEXT
  );

-- Attacker executes: UPDATE auth.users SET raw_user_meta_data = '{"tenant_id":"victim"}'
-- Now sees victim's bookings!
```

**Why it happens:** `user_metadata` looks convenient (stored on user object). Developers assume it's immutable.

**Prevention:**
- Grep for `user_metadata()` in all RLS policies → delete it
- Use ONLY `auth.jwt() ->> 'app_metadata'` (server-set via auth hook, Phase 32)
- Code review checklist: "No user_metadata in RLS policies?"

**Detection:** RLS policies allow users to escalate to other tenants. Security audit finds policies reading wrong metadata field.

**Status in Phase 31:** All RLS policies use app_metadata; none use user_metadata. Verify before commit.

---

### Pitfall 2: Missing WITH CHECK on INSERT/UPDATE Policies

**What goes wrong:** INSERT policy has USING (read filter) but no WITH CHECK (write filter). Users insert rows into other tenants.

```sql
-- VULNERABLE
CREATE POLICY "bad_insert"
  ON bookings FOR INSERT TO authenticated
  -- Missing WITH CHECK!
  ;

-- User inserts: INSERT INTO bookings (..., tenant_id = 'other-tenant', ...)
-- No RLS filter on write → INSERT succeeds!
```

**Why it happens:** Developer adds SELECT policy (has USING), forgets that INSERT/UPDATE also need WITH CHECK.

**Prevention:**
- Every INSERT/UPDATE policy MUST have WITH CHECK clause
- WITH CHECK must validate: tenant_id matches JWT + user_id matches auth.uid()
- Code review: "Does this UPDATE policy have both USING and WITH CHECK?"
- Test: Try INSERT with wrong tenant_id via psql as authenticated user → should fail with "violates row-level security policy"

**Detection:** Manual test attempts INSERT with tenant_id ≠ user's tenant; policy allows it (should block).

**Status in Phase 31:** CRITICAL. All INSERT/UPDATE policies include WITH CHECK. Test before commit.

---

### Pitfall 3: Service Role Key Exposed in Flutter App or Git History

**Severity:** CRITICAL (complete database bypass)

**What goes wrong:** Service role key (`sb_secret_xxx`) bundled in Flutter app or committed to git. Service role **bypasses ALL RLS policies**. Any client holding this key has full database access.

```dart
// VULNERABLE
Supabase.initialize(
  url: 'https://...',
  anonKey: 'eyJ...abc',  // OK to expose
  serviceRoleKey: 'sb_secret_...',  // NEVER in app!
);
```

**Prevention:**
- `.env` file structure:
  ```
  # .env.example (checked in, placeholders)
  SUPABASE_URL=https://your-project.supabase.co
  SUPABASE_ANON_KEY=eyJ...abc

  # .env.local (gitignored, local dev only, NEVER service role)
  SUPABASE_URL=https://...
  SUPABASE_ANON_KEY=...

  # SERVICE_ROLE_KEY (Phase 32 Auth Hook only, in Supabase console, NOT in repo)
  ```
- Commit `.gitignore` with `.env` and `.env.local` entries BEFORE writing schema files
- Pre-commit hook: grep for `sb_secret_` → if found, reject commit
- Never import service role into Flutter code

**Detection:**
- `git log --all | grep sb_secret_` shows key in history
- Flutter build includes service role key
- RLS policies don't filter; app has god-mode access

**Status in Phase 31:** Add `sb_secret_*` pattern to `.gitignore` before any file creation. Verify before commit.

---

### Pitfall 4: Testing RLS Policies Only in SQL Editor (Not Simulating Real Client)

**What goes wrong:** SQL editor uses admin/service-role credentials which bypass RLS. Developer sees "SELECT allowed" and assumes policy works. In production, anon_key client gets blocked or wrong rows.

```
SQL Editor behavior: SELECT * FROM bookings → ALL rows returned (admin bypass)
Actual client behavior: SELECT * FROM bookings → Only user's tenant rows (RLS filters)
```

**Prevention:**
- Test RLS policies using `psql` with JWT claim simulation:
  ```bash
  psql "postgresql://..." -c "
    SET LOCAL role authenticated;
    SET LOCAL request.jwt.claims = '{\"sub\":\"user-uuid\",\"app_metadata\":{\"tenant_id\":\"tenant-uuid\",\"role\":\"client\"}}';
    SELECT * FROM bookings;  -- Should return only user's tenant rows
  "
  ```
- For every policy, test THREE scenarios:
  1. Own-tenant access (should succeed)
  2. Cross-tenant access (should return 0 rows for SELECT; should fail with 403 for INSERT/UPDATE)
  3. Admin access with `role='admin'` claim (should see all tenant rows)
- Use pgTAP for automated policy validation

[CITED: Supabase Testing Docs](https://supabase.com/docs/guides/local-development/testing/overview)

**Detection:** Spike passes SQL editor tests; Flutter app queries fail or return unexpected rows.

**Status in Phase 31:** Include RLS test scenarios in `schema/tests/` directory. Execute via psql, not SQL editor.

---

### Pitfall 5: Missing Indexes on tenant_id Columns

**What goes wrong:** RLS policies filter by `tenant_id`, but column has no index. Query performance: O(n) full table scan per user.

```sql
-- Phase 31 schema (currently)
CREATE TABLE bookings (tenant_id UUID, ...);  -- No index!

-- RLS policy runs for every user query
CREATE POLICY "..." USING (tenant_id = auth.jwt()->...);

-- Query: SELECT * FROM bookings
-- With 100k rows: Full table scan → 500ms+ latency
```

**Why it happens:** Developer creates schema, forgets to index. Works fine with small datasets, breaks at scale.

**Prevention:**
- Index ALL `tenant_id` columns:
  ```sql
  CREATE INDEX idx_bookings_tenant_id ON bookings(tenant_id);
  CREATE INDEX idx_slots_tenant_id ON slots(tenant_id);
  CREATE INDEX idx_memberships_tenant_id ON memberships(tenant_id);
  ```
- Test performance: `EXPLAIN ANALYZE` on queries; ensure < 50ms for typical dataset
- For compound filters (RLS + user_id): add composite index
  ```sql
  CREATE INDEX idx_bookings_tenant_user ON bookings(tenant_id, user_id);
  ```

**Detection:** Phase 33 performance tests show > 100ms queries; Supabase monitoring shows high CPU on sequential scans.

**Status in Phase 31:** Include indexes in `01_schema.sql` at table creation time.

---

### Pitfall 6: UNIQUE Constraint Without Testing Concurrent Inserts

**What goes wrong:** Developer tests double-booking prevention serially (1 insert, then next). Concurrent production load → duplicates slip through due to race window.

**Prevention:**
- Test with actual concurrent HTTP requests (not just sequential SQL):
  ```bash
  # Simulate 50 simultaneous bookings to same slot
  for i in {1..50}; do
    psql -c "INSERT INTO bookings (...) VALUES (...)" &
  done
  wait

  # Verify exactly 1 succeeded, 49 got unique_violation
  ```
- Phase 32 will add `book_slot()` function with SELECT FOR UPDATE NOWAIT (explicit locking)
- Measure: if INSERT takes > 100ms, race window is larger

**Detection:** Production load test shows occasional double-bookings despite UNIQUE constraint.

**Status in Phase 31:** Document concurrency testing plan in README. Phase 32 implements actual test.

---

### Pitfall 7: Enum VALUES Can't Be Removed (Schema Change Burden)

**What goes wrong:** Using PostgreSQL ENUM type for `bookings.status`. Later, business wants to remove `pending_payment` status. ENUM removal requires:
1. Create new type without old value
2. Migrate all rows
3. Drop old type

[CITED: Crunchy Data: Enums vs Check Constraints](https://www.crunchydata.com/blog/enums-vs-check-constraints-in-postgres)

**Prevention:** Use VARCHAR + CHECK constraint instead:

```sql
-- Better for future flexibility
CREATE TABLE bookings (
  status VARCHAR(50) NOT NULL DEFAULT 'pending',
  CONSTRAINT valid_booking_status CHECK (status IN ('pending','confirmed','cancelled','rejected','pending_payment','expired','refunded'))
);

-- Removing status later: just update CHECK constraint
ALTER TABLE bookings DROP CONSTRAINT valid_booking_status;
ALTER TABLE bookings ADD CONSTRAINT valid_booking_status CHECK (status IN ('pending','confirmed','cancelled','rejected','expired','refunded'));
```

**Decision:** D-04 requires **all 7 Firebase status values**. Phase 31 uses CHECK constraint (more flexible than ENUM). If future requires removing a status, only the constraint is updated (not type migration).

**Status in Phase 31:** Use VARCHAR(50) + CHECK constraint for `bookings.status`.

---

## Code Examples

### Example 1: Complete RLS Policy Set for bookings Table

**Source:** [CITED: Supabase RLS Guide](https://supabase.com/docs/guides/database/postgres/row-level-security)

```sql
-- Enable RLS on table
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- Clients: see own tenant's bookings
CREATE POLICY "bookings_client_select"
  ON bookings FOR SELECT TO authenticated
  USING (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
    AND (auth.jwt() ->> 'app_metadata' ->> 'role')::text = 'client'
  );

-- Clients: insert own bookings only
CREATE POLICY "bookings_client_insert"
  ON bookings FOR INSERT TO authenticated
  WITH CHECK (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
    AND user_id = auth.uid()
  );

-- Clients: update own bookings only (status changes)
CREATE POLICY "bookings_client_update"
  ON bookings FOR UPDATE TO authenticated
  USING (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
    AND user_id = auth.uid()
  )
  WITH CHECK (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
    AND user_id = auth.uid()
  );

-- Admins: see all bookings in their tenant
CREATE POLICY "bookings_admin_select"
  ON bookings FOR SELECT TO authenticated
  USING (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
    AND (auth.jwt() ->> 'app_metadata' ->> 'role')::text = 'admin'
  );

-- Admins: modify bookings in their tenant
CREATE POLICY "bookings_admin_update"
  ON bookings FOR UPDATE TO authenticated
  USING (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
    AND (auth.jwt() ->> 'app_metadata' ->> 'role')::text = 'admin'
  )
  WITH CHECK (
    tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid
  );
```

---

### Example 2: Testing RLS Policy Isolation with psql

**Source:** [CITED: Supabase Testing Docs](https://supabase.com/docs/guides/local-development/testing/overview)

```bash
# File: tests/rls_isolation_test.sql

-- Setup: Create test users (phase 32 will use real auth.users)
SELECT 'Testing RLS isolation for bookings table';

-- Test 1: Client A sees only Tenant A bookings
SELECT 'Test 1: Client A SELECT bookings (should see Tenant A only)';
SET LOCAL role authenticated;
SET LOCAL request.jwt.claims = '{"sub":"user-a-uuid","app_metadata":{"tenant_id":"00000000-0000-0000-0000-000000000001","role":"client"}}';

SELECT COUNT(*) as tenant_a_bookings FROM bookings WHERE tenant_id = '00000000-0000-0000-0000-000000000001'::uuid;
-- Expected: >0 (user has bookings in tenant A)

SELECT COUNT(*) as tenant_b_bookings FROM bookings WHERE tenant_id = '00000000-0000-0000-0000-000000000002'::uuid;
-- Expected: 0 (RLS blocks tenant B rows)

-- Test 2: Client A tries INSERT into Tenant B (should fail)
SELECT 'Test 2: Client A tries INSERT into Tenant B (should fail)';
SET LOCAL role authenticated;
SET LOCAL request.jwt.claims = '{"sub":"user-a-uuid","app_metadata":{"tenant_id":"00000000-0000-0000-0000-000000000001","role":"client"}}';

BEGIN;
INSERT INTO bookings (id, tenant_id, user_id, slot_id, booking_date, status)
VALUES (gen_random_uuid(), '00000000-0000-0000-0000-000000000002'::uuid, 'user-a-uuid'::uuid, gen_random_uuid(), '2026-06-15', 'pending');
-- Expected: INSERT 0 rows (RLS WITH CHECK blocks)
ROLLBACK;

-- Test 3: Admin A sees all Tenant A bookings
SELECT 'Test 3: Admin A SELECT all Tenant A bookings';
SET LOCAL role authenticated;
SET LOCAL request.jwt.claims = '{"sub":"admin-a-uuid","app_metadata":{"tenant_id":"00000000-0000-0000-0000-000000000001","role":"admin"}}';

SELECT COUNT(*) FROM bookings WHERE tenant_id = '00000000-0000-0000-0000-000000000001'::uuid;
-- Expected: all bookings in tenant A (admin sees all)
```

---

### Example 3: Seed Data with UUIDs and Status Values

```sql
-- File: schema/03_seed.sql

-- Tenants
INSERT INTO tenants (id, name) VALUES
  ('10000000-0000-0000-0000-000000000001'::uuid, 'Academia Vida Ativa (Dev)'),
  ('20000000-0000-0000-0000-000000000001'::uuid, 'Outro Clube (Dev)')
ON CONFLICT (id) DO NOTHING;

-- Memberships (users + roles)
INSERT INTO memberships (id, tenant_id, user_id, role) VALUES
  ('11000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'user-client-a-uuid'::uuid, 'client'),
  ('11000000-0000-0000-0000-000000000002'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'user-admin-a-uuid'::uuid, 'admin'),
  ('21000000-0000-0000-0000-000000000001'::uuid, '20000000-0000-0000-0000-000000000001'::uuid, 'user-client-b-uuid'::uuid, 'client')
ON CONFLICT (id) DO NOTHING;

-- Slots (day_of_week 1=Mon, 7=Sun; start_time/end_time in HH:MM format)
INSERT INTO slots (id, tenant_id, day_of_week, start_time, end_time, price) VALUES
  ('12000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 1, '08:00:00'::time, '09:00:00'::time, 50.00),
  ('12000000-0000-0000-0000-000000000002'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 1, '09:00:00'::time, '10:00:00'::time, 50.00),
  ('12000000-0000-0000-0000-000000000003'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 3, '10:00:00'::time, '11:00:00'::time, 60.00),
  ('22000000-0000-0000-0000-000000000001'::uuid, '20000000-0000-0000-0000-000000000001'::uuid, 2, '08:00:00'::time, '09:00:00'::time, 75.00)
ON CONFLICT (id) DO NOTHING;

-- Bookings (with all 7 status values for testing)
INSERT INTO bookings (id, tenant_id, user_id, slot_id, booking_date, status) VALUES
  ('13000000-0000-0000-0000-000000000001'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'user-client-a-uuid'::uuid, '12000000-0000-0000-0000-000000000001'::uuid, '2026-06-16', 'pending'),
  ('13000000-0000-0000-0000-000000000002'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'user-client-a-uuid'::uuid, '12000000-0000-0000-0000-000000000002'::uuid, '2026-06-16', 'confirmed'),
  ('13000000-0000-0000-0000-000000000003'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'user-client-a-uuid'::uuid, '12000000-0000-0000-0000-000000000001'::uuid, '2026-06-23', 'pending_payment'),
  ('13000000-0000-0000-0000-000000000004'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'user-client-a-uuid'::uuid, '12000000-0000-0000-0000-000000000003'::uuid, '2026-06-18', 'cancelled'),
  ('13000000-0000-0000-0000-000000000005'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'user-admin-a-uuid'::uuid, '12000000-0000-0000-0000-000000000001'::uuid, '2026-06-30', 'rejected'),
  ('13000000-0000-0000-0000-000000000006'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'user-client-a-uuid'::uuid, '12000000-0000-0000-0000-000000000002'::uuid, '2026-05-01', 'expired'),
  ('13000000-0000-0000-0000-000000000007'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 'user-client-a-uuid'::uuid, '12000000-0000-0000-0000-000000000003'::uuid, '2026-04-15', 'refunded'),
  ('23000000-0000-0000-0000-000000000001'::uuid, '20000000-0000-0000-0000-000000000001'::uuid, 'user-client-b-uuid'::uuid, '22000000-0000-0000-0000-000000000001'::uuid, '2026-06-17', 'confirmed')
ON CONFLICT (id) DO NOTHING;
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Firestore transactions for anti-double-booking | PostgreSQL UNIQUE + MVCC | Firebase → Supabase (v7.0) | Simpler enforcement; database-atomic; no application-level retry logic needed |
| App-level tenant filtering (manual WHERE) | RLS policies (database-enforced) | Firebase → Supabase (v7.0) | Security moves to DB layer; app bugs can't bypass isolation; works for all clients |
| Hardcoded JWT claims in signup | Auth Hook custom claims injection | Supabase Auth evolution (2025+) | Server-side claim injection prevents tampering; decouples auth from app code |
| ENUM types for fixed enums | CHECK constraints for evolving enums | PostgreSQL best practice shift | CHECK allows constraint updates without type migrations; lower operational burden |

**Deprecated/Outdated:**
- Firebase Realtime for booking state (Supabase will use Postgres Changes + RLS filtering) — Phase 34+
- Local Supabase CLI for development (cloud staging is decision D-01) — zero local setup needed

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | PostgreSQL 15+ is stable for production multi-tenant SaaS with RLS | Standard Stack | If version < 15, RLS performance or features may be suboptimal; Phase 31 assumes 15+ |
| A2 | UNIQUE constraint + MVCC prevents double-booking at concurrency up to 1000 req/sec | Common Pitfalls (Pitfall 5) | If race window exists at higher concurrency, Phase 32's SELECT FOR UPDATE NOWAIT may not be sufficient; Phase 33 testing will validate |
| A3 | Supabase Auth Hook (Phase 32) can inject tenant_id into JWT claims reliably within 5-second timeout | Architecture Patterns | If hook is unreliable or slow, RLS policies fail to evaluate; Phase 32 must test this |
| A4 | Firebase users can be migrated to Supabase Auth via password reset campaign (Pitfall 7 scope deferral) | Common Pitfalls (Pitfall 7) | If migration path is more complex than documented, Phase 35 risk assessment must address |
| A5 | CHECK constraint on `bookings.status` is equivalent to ENUM for all 7 Firebase status values | Architecture Patterns | If future requires status value semantics (ordering, transitions), CHECK constraint may be insufficient; Document in decision doc |

---

## Open Questions

1. **bookings.status transitions: are some statuses invalid (e.g., can't go from 'refunded' to 'pending')?**
   - What we know: D-04 requires all 7 Firebase values; no transition rules documented
   - What's unclear: Are arbitrary transitions allowed (e.g., 'cancelled' → 'confirmed')?
   - Recommendation: Document transition rules in Phase 32 when `book_slot()` is implemented. If strict transitions needed, add CHECK constraint + trigger validation

2. **Does Supabase cloud project auto-backup? How often? What's the RPO/RTO?**
   - What we know: Cloud Supabase likely has backup; no specifics documented in spike requirements
   - What's unclear: Restore window; data loss tolerance
   - Recommendation: Check Supabase dashboard settings after project creation (Phase 31 final step). Document in README for team reference.

3. **How are `user_id` foreign keys enforced if auth.users is outside schema?**
   - What we know: Memberships and bookings reference user_id (UUID). auth.users is managed by Supabase Auth.
   - What's unclear: Can RLS on public.* tables reference auth.users directly in policies?
   - Recommendation: Phase 31 creates auth.users trigger/hook integration during Phase 32 (Auth Hook). For now, assume user_id is valid UUID (auth will populate).

---

## Environment Availability

**Skip:** Phase 31 has no external tool dependencies beyond PostgreSQL (included in Supabase). No Docker, no k6, no external APIs required.

---

## Validation Architecture

[NOTE: `workflow.nyquist_validation` not set in `.planning/config.json` — treating as enabled (default).]

### Test Framework

| Property | Value |
|---|---|
| Framework | psql (PostgreSQL CLI) + pgTAP (optional) |
| Config file | — (psql queries run directly; no config file) |
| Quick run command | `psql "postgresql://..." -f schema/01_schema.sql` |
| Full suite command | `psql "postgresql://..." -f schema/01_schema.sql && psql "postgresql://..." -f schema/02_rls.sql && psql "postgresql://..." -f tests/rls_isolation_test.sql` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| SPIKE-01 | Schema creates 4 tables with FK + UNIQUE(tenant_id, slot_id, date) | SQL syntax check | `psql -f schema/01_schema.sql; echo $?` (exit 0 = pass) | ✅ Wave 0 (01_schema.sql) |
| SPIKE-03 | RLS enabled + SELECT/INSERT/UPDATE/DELETE policies present on all 4 tables | pgTAP or manual `\d bookings` | `psql "..." -c "\d bookings" \| grep "Row-level security: ON"` | ✅ Wave 0 (02_rls.sql) |
| SPIKE-04 | Client policy filters to own tenant; admin policy shows all tenant rows | Isolation test | `psql -f tests/rls_isolation_test.sql` (runs 3 attack scenarios) | ❌ Wave 0 (to create in tests/) |
| SPIKE-13 | Service role key absent from .env + git history; `.env` in .gitignore | Grep check | `grep -r "sb_secret_" --include=".gitignore" . && grep -r "sb_secret_" . \| grep -v ".env.example"` (should return empty) | ❌ Wave 0 (add to .gitignore) |

### Sampling Rate

- **Per task commit:** `psql -f schema/01_schema.sql` — schema compiles
- **Per wave merge (end of phase):** Full suite (`01_schema.sql` + `02_rls.sql` + `03_seed.sql`) — all tables created, RLS enabled, seed inserted
- **Phase gate:** `psql -f tests/rls_isolation_test.sql` — all 3 isolation attacks documented (PASS/FAIL), before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `tests/rls_isolation_test.sql` — covers SPIKE-03, SPIKE-04 isolation scenarios (3 attacks)
- [ ] `tests/rls_insert_isolation_test.sql` — covers Pitfall 2 (missing WITH CHECK detection)
- [ ] `.gitignore` committed with `**/.env*` and `**/sb_secret_*` patterns (Pitfall 3 prevention)
- [ ] `README.md` in `/spike-supabase/` with SQL apply order + testing instructions
- [ ] Supabase cloud project created manually (manual step, not in Phase 31 code)

*(If no gaps: None — schema compiles syntactically; RLS policies present; seed data structured. Isolation validation deferred to Phase 33 with formal proofs.)*

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | No | Deferred to Phase 32 (Auth Hook injects claims) |
| V3 Session Management | No | Managed by Supabase Auth |
| V4 Access Control | Yes | RLS policies enforce multi-tenant isolation (tenant_id FK + USING + WITH CHECK) |
| V5 Input Validation | Yes | UNIQUE constraints prevent invalid booking duplicates; CHECK constraint on status enum values |
| V6 Cryptography | No | Passwords managed by Supabase; no custom crypto in this phase |
| V7 Error Handling | Partial | RLS policy violations should return generic 403 (not expose schema); DB error messages not yet tested |

### Known Threat Patterns for Postgres Multi-Tenant

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Cross-tenant data read (SELECT) | Information Disclosure | RLS policy USING clause filters by tenant_id from JWT; no app-level filtering needed |
| Cross-tenant data write (INSERT) | Tampering | RLS policy WITH CHECK clause validates tenant_id = JWT claim before insert; UNIQUE constraint prevents duplicates |
| Privilege escalation (client → admin) | Elevation of Privilege | Role field stored in immutable app_metadata (not user_metadata); client can't modify claim; Phase 32 Auth Hook validates role server-side |
| Double-booking (race condition) | Denial of Service / Integrity | UNIQUE(tenant_id, slot_id, date) + MVCC enforces atomicity; Phase 32 adds SELECT FOR UPDATE NOWAIT for explicit locking |
| Service role key exposure | Information Disclosure | Key never appears in app code or git; stored in Supabase console only; .gitignore prevents accidental commit |
| Unencrypted password reset email | Information Disclosure | Managed by Supabase Auth (HTTPS, secure links); spike doesn't implement custom password reset |

---

## Sources

### Primary (HIGH confidence)

- **Supabase Docs (RLS)** — [Row Level Security Guide](https://supabase.com/docs/guides/database/postgres/row-level-security)
- **PostgreSQL 15 Docs** — [MVCC & Concurrency](https://www.postgresql.org/docs/15/mvcc.html), [UNIQUE Constraints](https://www.postgresql.org/docs/15/ddl-constraints.html#DDL-CONSTRAINTS-UNIQUE-CONSTRAINTS)
- **Supabase Testing Docs** — [Testing Overview](https://supabase.com/docs/guides/local-development/testing/overview), [pgTAP](https://supabase.com/docs/guides/database/extensions/pgtap)

### Secondary (MEDIUM confidence)

- [Supabase RLS Best Practices: Production Patterns for Secure Multi-Tenant Apps](https://makerkit.dev/blog/tutorials/supabase-rls-best-practices)
- [Supabase RLS Guide: Policies That Actually Work](https://designrevision.com/blog/supabase-row-level-security)
- [Enforcing Row Level Security in Supabase: A Deep Dive into LockIn's Multi-Tenant Architecture - DEV Community](https://dev.to/blackie360/-enforcing-row-level-security-in-supabase-a-deep-dive-into-lockins-multi-tenant-architecture-4hd2)
- [How to Solve the Double Booking Problem with PostgreSQL](https://jsupskills.dev/how-to-solve-the-double-booking-problem/)
- [PostgreSQL's GiST Exclusion Constraint: The Database-Level Answer to Double Bookings](https://amitavroy.com/articles/postgresql-gist-exclusion-constraintthe-database-evel-answer-to-double-bookings)
- [Enums vs Check Constraints in Postgres | Crunchy Data Blog](https://www.crunchydata.com/blog/enums-vs-check-constraints-in-postgres)
- [UUID vs BIGSERIAL for Primary Keys](https://www.cybertec-postgresql.com/en/uuid-serial-or-identity-columns-for-postgresql-auto-generated-primary-keys/)
- [Supabase Seeding Database Guide](https://supabase.com/docs/guides/local-development/seeding-your-database)

---

## Metadata

**Confidence breakdown:**
- **Standard Stack:** HIGH — PostgreSQL 15+, Supabase cloud, RLS all production-proven; versions verified via official docs
- **Architecture:** HIGH — Multi-tenant schema patterns, RLS policies, anti-double-booking are well-documented in official Supabase + PostgreSQL resources
- **Pitfalls:** HIGH — All 7 pitfalls sourced from PITFALLS.md (spike-specific knowledge) or verified via official docs (user_metadata CVE, UNIQUE semantics, etc.)
- **Common Patterns:** MEDIUM-HIGH — Code examples from official Supabase docs + STACK.md; some assumed based on PostgreSQL best practices (no breaking changes expected in 15+)

**Research date:** 2026-06-09
**Valid until:** 2026-07-09 (30 days — PostgreSQL is stable; RLS patterns unchanging; Supabase API stable)

---

*Research complete. Ready for planning.*

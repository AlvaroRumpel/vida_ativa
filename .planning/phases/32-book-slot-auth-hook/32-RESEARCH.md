# Phase 32: book_slot() + Auth Hook - Research

**Researched:** 2026-06-09
**Domain:** PostgreSQL stored procedures + Supabase Auth hooks (Edge Functions)
**Confidence:** HIGH

## Summary

Phase 32 implements two critical spike components:

1. **book_slot() PL/pgSQL Function** — Atomic slot reservation with `SELECT FOR UPDATE NOWAIT` for explicit row-level locking and `EXCEPTION WHEN unique_violation` (SQLSTATE 23505) to catch double-booking attempts, returning structured error codes for client handling.

2. **Custom Access Token Hook (Edge Function)** — Supabase Auth Hook that injects `tenant_id` and `role` from the `memberships` table into the JWT's `app_metadata` claim at login time, enabling RLS policies to enforce multi-tenant isolation without client-side hints.

Both features are mature Supabase patterns with clear official documentation and proven production use. The spike uses HTTP Edge Functions (not Postgres functions) for the hook to simplify deployment and avoid managing raw SQL in two places.

**Primary recommendation:** Implement book_slot() as a PL/pgSQL stored procedure with explicit SELECT FOR UPDATE NOWAIT locking + EXCEPTION handling. Implement Auth Hook as a Deno/TypeScript Edge Function that queries the `memberships` table via Supabase Admin client, injects tenant_id into app_metadata, and returns the modified claims. Both use `auth.jwt() -> 'app_metadata' ->> 'tenant_id'` pattern from Phase 31 — already verified as CVE-2025-48757 safe.

---

## User Constraints (from CONTEXT.md)

No CONTEXT.md exists for Phase 32 yet. Constraints inherited from Phase 31:

- **Locked:** JWT claims ALWAYS use `auth.jwt() -> 'app_metadata' ->> 'tenant_id'` (NOT the broken `->> 'app_metadata' ->>` pattern) — verified in Phase 31 RLS policies
- **Locked:** NEVER use `auth.user_metadata()` — only `app_metadata` (server-set, immutable) — CVE-2025-48757 prevention
- **Locked:** Service role key (`sb_secret_*`) NEVER in git or Flutter code — only local `.env` (gitignored)
- **Locked:** Supabase project = staging ONLY (`fasirsbiadcchfgvktzt`)
- **Locked:** Zero touch to `lib/`, `functions/`, Firebase production
- **Locked:** Spike uses schema from Phase 31 (tenants, memberships, slots, bookings tables with UNIQUE anti-double-booking constraint)

---

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SPIKE-02 | `book_slot()` PL/pgSQL function with SELECT FOR UPDATE NOWAIT + unique_violation capture → SLOT_ALREADY_BOOKED error code | SELECT FOR UPDATE NOWAIT pattern verified; EXCEPTION WHEN unique_violation (SQLSTATE 23505) supported in PL/pgSQL; return structured error codes via OUT parameters or RAISE |
| SPIKE-05 | Auth Hook (Edge Function) injects tenant_id in app_metadata at login — validated by JWT decode | Custom Access Token Hook runs automatically on all token issuance (login, refresh); Edge Function queries memberships; app_metadata injection verified safe by Phase 31 |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| PostgreSQL (PL/pgSQL) | 15+ (Supabase standard) | `book_slot()` stored procedure with SELECT FOR UPDATE NOWAIT + exception handling | PostgreSQL's MVCC + explicit row locking is industry standard for anti-double-booking; SELECT FOR UPDATE NOWAIT is mature, well-tested pattern for booking systems |
| Supabase Auth Hooks (Edge Functions) | Supabase platform feature | Custom Access Token Hook for JWT claim injection | Official Supabase Auth feature; hooks run automatically on all token issuance; avoids custom auth logic in application code |
| Deno (TypeScript) | 1.x (Edge Functions runtime) | Edge Function handler language | Only supported runtime for Supabase Edge Functions; TypeScript provides type safety for JWT manipulation |
| supabase-js (Admin) | ^2.38+ | Service-role authenticated client for Edge Function to query memberships | Official Supabase client; required for Edge Function to access database with service role (bypasses RLS for auth logic) |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| pgjwt (PostgreSQL extension) | Supabase-managed | Optional JWT decoding in SQL for verification testing | Only needed to manually decode JWT in psql for testing; not used in production code path (Supabase Auth validates claims) |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SELECT FOR UPDATE NOWAIT | INSERT ... ON CONFLICT DO NOTHING | ON CONFLICT simpler but doesn't tell you *why* booking failed; SELECT FOR UPDATE NOWAIT allows explicit lock wait-or-fail decision + better error messaging |
| Auth Hook via Edge Function | Postgres function hook (pg-functions://) | Postgres function requires managing SQL in auth config; Edge Function is more testable, versioned in git, supports npm imports |
| Auth Hook (custom Access Token) | Before User Created hook | Before User Created runs only on signup, not on login; Custom Access Token runs on all token issuance (login, refresh) — required for consistent tenant claims |

**Installation:**
```bash
# No new packages needed — book_slot() is pure PostgreSQL
# Edge Function uses built-in imports (Deno + supabase-js)
```

**Version verification:** PostgreSQL version is managed by Supabase (currently 15.x stable). Supabase Edge Functions runtime (Deno) auto-updates. Edge Function dependencies pinned in deno.json / import_map.json.

---

## Architecture Patterns

### Recommended Project Structure

```
spike-supabase/
├── schema/
│   ├── 01_schema.sql           # ✅ Phase 31: tables + RLS enable
│   ├── 02_rls.sql              # ✅ Phase 31: 15 policies
│   ├── 03_seed.sql             # ✅ Phase 31: test data
│   └── 04_functions.sql        # 🆕 Phase 32: book_slot() PL/pgSQL
├── supabase/functions/
│   └── custom-access-token/    # 🆕 Phase 32: Auth Hook Edge Function
│       ├── index.ts            # Deno handler
│       └── deno.json           # (optional) dependencies
├── tests/
│   ├── book_slot_test.sql      # Test book_slot() function
│   └── auth_hook_test.ts       # Test Edge Function locally
└── README.md                    # Updated apply order
```

### Pattern 1: book_slot() — SELECT FOR UPDATE NOWAIT + Exception Capture

**What:** PL/pgSQL stored procedure that atomically reserves a slot by locking the booking row, checking for duplicates, and returning a structured result (success vs. SLOT_ALREADY_BOOKED error).

**When to use:** Any high-concurrency booking/reservation system where multiple requests can arrive simultaneously for the same slot and date.

**Example:**
```sql
-- Source: PostgreSQL docs + Supabase spike patterns
CREATE OR REPLACE FUNCTION public.book_slot(
  p_tenant_id UUID,
  p_user_id UUID,
  p_slot_id UUID,
  p_booking_date DATE,
  OUT success BOOLEAN,
  OUT error_code TEXT,
  OUT booking_id UUID
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_booking_id UUID;
BEGIN
  -- Attempt to acquire row lock without waiting
  -- This prevents concurrent double-books from both passing INSERT
  SELECT id INTO v_booking_id
  FROM bookings
  WHERE tenant_id = p_tenant_id
    AND slot_id = p_slot_id
    AND booking_date = p_booking_date
  FOR UPDATE NOWAIT;

  IF v_booking_id IS NOT NULL THEN
    -- Row locked = booking already exists for this slot+date
    success := FALSE;
    error_code := 'SLOT_ALREADY_BOOKED';
    booking_id := NULL;
    RETURN;
  END IF;

  -- No existing booking; proceed with INSERT
  INSERT INTO bookings (tenant_id, user_id, slot_id, booking_date, status)
  VALUES (p_tenant_id, p_user_id, p_slot_id, p_booking_date, 'pending')
  RETURNING id INTO v_booking_id;

  success := TRUE;
  error_code := NULL;
  booking_id := v_booking_id;
  RETURN;

EXCEPTION WHEN unique_violation THEN
  -- UNIQUE constraint fired (race condition: another transaction committed booking)
  -- This is a hard conflict, not just SELECT FOR UPDATE lock contention
  success := FALSE;
  error_code := 'SLOT_ALREADY_BOOKED';
  booking_id := NULL;
  RETURN;
EXCEPTION WHEN lock_not_available THEN
  -- SELECT FOR UPDATE NOWAIT failed to acquire lock (row is locked by other transaction)
  -- Client should retry or report "slot is busy"
  success := FALSE;
  error_code := 'SLOT_LOCKED_RETRY';
  booking_id := NULL;
  RETURN;
END;
$$;
```

**Key design decisions:**
- `SELECT FOR UPDATE NOWAIT` acquires an exclusive lock on any existing booking row for this (tenant, slot, date) — if locked, raises `lock_not_available` error immediately
- If no row exists, INSERT proceeds. If another transaction inserts and commits between SELECT and INSERT, UNIQUE constraint violation fires → caught by `EXCEPTION WHEN unique_violation`
- Both paths (lock conflict + UNIQUE conflict) return `SLOT_ALREADY_BOOKED` to client — different error codes (SLOT_LOCKED_RETRY) available if client logic needs to distinguish retry-able vs. permanent conflicts
- Function returns OUT parameters (success, error_code, booking_id) instead of raising exceptions — allows client to handle errors without try/catch boilerplate

**Anti-pattern to avoid:**
- ❌ Relying ONLY on UNIQUE constraint without SELECT FOR UPDATE NOWAIT: two concurrent requests could both pass SELECT check and INSERT simultaneously; second one fails with unique_violation, but by then client has already started displaying booking confirmation. SELECT FOR UPDATE NOWAIT forces fail-fast before any INSERT attempted.

### Pattern 2: Custom Access Token Hook (Edge Function) — Tenant Claim Injection

**What:** HTTP endpoint (Edge Function) registered as Supabase Auth custom_access_token hook. Runs automatically before every token issuance (login, refresh). Queries `memberships` table for tenant_id + role, injects into JWT's `app_metadata`, returns modified claims.

**When to use:** Multi-tenant SaaS where tenant_id must be present in JWT for RLS policies to enforce isolation.

**Example:**
```typescript
// File: supabase/functions/custom-access-token/index.ts
// Source: Supabase Auth Hooks custom access token hook pattern

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38";

// Note: Custom Access Token Hook requests DO NOT have Authorization header
// — Supabase Auth sends user_id and claims directly in request body
// So we use service role key (stored in .env) to query memberships table

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const event = await req.json();
    const user_id = event.user_id;
    const claims = event.claims;

    // Initialize Supabase Admin client
    // Service role key from .env (gitignored in spike-supabase/.env)
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Query memberships for this user to get tenant_id + role
    // Note: Only one membership per user in spike (single-tenant context per user)
    // Production multi-org scenarios might join users to multiple tenants
    const { data: membership, error } = await supabaseAdmin
      .from("memberships")
      .select("tenant_id, role")
      .eq("user_id", user_id)
      .single(); // Expect exactly one row; error if 0 or 2+

    if (error || !membership) {
      // User has no membership record = not authorized for any tenant
      // Return claims unchanged (no tenant_id injected)
      // RLS policies will deny access based on missing app_metadata claim
      console.warn(`No membership for user ${user_id}: ${error?.message}`);
      return new Response(
        JSON.stringify({
          claims: claims,
        }),
        {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    // Inject tenant_id and role into app_metadata
    const modified_claims = {
      ...claims,
      app_metadata: {
        ...(claims.app_metadata || {}),
        tenant_id: membership.tenant_id,
        role: membership.role,
      },
    };

    return new Response(
      JSON.stringify({
        claims: modified_claims,
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Auth hook error:", error);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});
```

**Key design decisions:**
- Auth Hook request payload does NOT include Authorization header (unlike regular Edge Function requests). Instead, Supabase Auth sends `user_id` and `claims` directly in JSON body.
- Function uses `createClient()` with service role key to bypass RLS and query `memberships` table
- Service role key sourced from `Deno.env.get()` (populated from `.env` at deployment time via MCP or CLI)
- Returns `{ claims: modified_claims }` — exact format required by Supabase Auth; missing or extra fields cause token rejection
- Error handling: if membership query fails (user not found), returns claims unchanged — RLS policies will deny access anyway
- Single `.single()` call instead of `.select().limit(1)` — throws error if 0 or 2+ rows, which is correct for spike (one membership per user per tenant)

**Anti-pattern to avoid:**
- ❌ Storing service role key in app code (Flutter, web client): it bypasses ALL RLS. Store only in `.env` (gitignored) or secure secret manager
- ❌ Using user_metadata instead of app_metadata: user can modify user_metadata, breaking RLS isolation. app_metadata is server-set only (CVE-2025-48757)
- ❌ Making Auth Hook conditional (not injecting tenant_id for some users): if claim is missing, all RLS policies evaluating `app_metadata ->> 'tenant_id'` cast NULL to UUID and deny access. Inconsistent claim presence = inconsistent behavior.

### Pattern 3: Registering Auth Hook in Supabase Dashboard

**What:** Via Supabase project dashboard, configure Auth Hook endpoint so Supabase Auth automatically routes token issuance through the hook.

**Configuration:**
1. **Navigate:** Project Dashboard > Authentication > Hooks
2. **Select hook type:** "Custom Access Token"
3. **Select function source:** "HTTP" (not Postgres function)
4. **Set endpoint URL:**
   - Local: `http://host.docker.internal:54321/functions/v1/custom-access-token` (via `supabase functions serve`)
   - Deployed: `https://<project-ref>.supabase.co/functions/v1/custom-access-token`
5. **Optional: Set webhook secret** (Standard Webhooks spec) — stored in `.env` for verification

**Note:** Phase 32 uses HTTP Edge Function deployment, so Supabase Auth automatically routes POST requests to the Edge Function endpoint at token issuance time. No additional API calls needed — Auth Hook integration is automatic once registered.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Preventing double-bookings in high-concurrency environment | Custom INSERT with retry loop; optimistic locking with version checks | `SELECT FOR UPDATE NOWAIT` + EXCEPTION WHEN unique_violation in PL/pgSQL | Optimistic locking requires app-level coordination; pessimistic locks (FOR UPDATE) are built into PostgreSQL MVCC; NOWAIT provides fail-fast behavior without blocking other requests |
| Injecting custom claims into JWT at login | Manual token refresh logic in app; client-side claim parsing and re-issuing | Supabase Auth custom_access_token hook | Auth Hooks are automatic, run at the database layer (before token issuance), not app-dependent; no risk of stale or missing claims in client-issued tokens |
| Row-level multi-tenant isolation | WHERE tenant_id = ? in every query; app-side filtering | RLS policies + JWT app_metadata claims | RLS enforces isolation at database layer — one misconfigured query doesn't leak data. App-side filtering is error-prone and centralizes security logic. |

**Key insight:** Booking systems are notoriously difficult because high concurrency + low tolerance for false negatives (customer sees "booking confirmed" then finds someone else booked it). SELECT FOR UPDATE NOWAIT + explicit exception handling is the proven pattern because it fails fast and leaves no room for application-logic race conditions. Auth claims must be server-set (not client-modifiable) and injected at token issuance time, not application-time.

---

## Common Pitfalls

### Pitfall 1: Confusing LOCK_NOT_AVAILABLE vs UNIQUE_VIOLATION

**What goes wrong:** Developer catches UNIQUE_VIOLATION but not LOCK_NOT_AVAILABLE. When request arrives while another is holding the booking row lock, SELECT FOR UPDATE NOWAIT raises `lock_not_available` error, which is not caught. Application crashes or returns HTTP 500 instead of structured "slot busy" response.

**Why it happens:** LOCK_NOT_AVAILABLE is a separate SQLSTATE (55P03) from UNIQUE_VIOLATION (23505). Developers often focus on constraint violations and forget the lock timeout case.

**How to avoid:** Always catch BOTH exceptions in book_slot() function:
```sql
EXCEPTION
  WHEN unique_violation THEN ... -- another transaction committed booking
  WHEN lock_not_available THEN ... -- row is currently locked (retry-able)
END;
```

**Warning signs:** HTTP 500 errors during load testing on the same slot. Lock wait timeout errors in logs.

### Pitfall 2: Missing Service Role Key in Edge Function Environment

**What goes wrong:** Auth Hook Edge Function calls `createClient(url, service_role_key)` but service_role_key is NULL or undefined. Function silently fails to query memberships, returns claims unchanged. RLS policies evaluate NULL app_metadata.tenant_id (which becomes NULL as UUID), deny all access. Users cannot log in.

**Why it happens:** Service role key must be injected via Deno.env.get() at deploy time, sourced from `.env` or MCP secret injection. If `.env` file is not loaded during Edge Function deployment, the key is missing.

**How to avoid:** Verify service role key is present:
```typescript
const service_role_key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
if (!service_role_key) {
  throw new Error("SUPABASE_SERVICE_ROLE_KEY not set in environment");
}
```

Also: Add test that verifies key is present before deploying Auth Hook function.

**Warning signs:** Post-login, all API queries return 403 (RLS deny). JWT decode shows app_metadata.tenant_id is missing.

### Pitfall 3: Auth Hook Endpoint Not Reachable at Registration Time

**What goes wrong:** Auth Hook is registered in dashboard with endpoint URL `https://...supabase.co/functions/v1/custom-access-token`, but Edge Function is not yet deployed. Users attempt login. Supabase Auth tries to invoke hook, times out waiting for response, either falls back to issuing unmodified token (missing tenant_id — RLS denies access) or returns auth error.

**Why it happens:** Supabase Auth tries to invoke hook synchronously before issuing token. If hook endpoint is unavailable, auth flow is blocked.

**How to avoid:** Deploy Edge Function BEFORE registering Auth Hook in dashboard. Verify function is deployed:
```bash
supabase functions list  # see function status
```

**Warning signs:** Auth Hook registration returns "endpoint unreachable" warning. Users report login failures or slow logins (timeouts).

### Pitfall 4: book_slot() Called with Wrong Tenant Context

**What goes wrong:** Developer calls book_slot() with incorrect p_tenant_id (e.g., hardcoded or from user input). Function succeeds, but booking is inserted into wrong tenant. RLS policies then prevent user from viewing their own booking (different tenant). User sees "booking failed" even though database shows booking exists.

**Why it happens:** book_slot() is called from application code, not directly as RLS. No automatic enforcement of caller's tenant. Easy to pass wrong tenant_id if application doesn't validate auth context.

**How to avoid:** book_slot() should be called from Edge Function or application code that validates `auth.uid()` and fetches tenant_id from JWT:
```typescript
const tenantId = claims.app_metadata.tenant_id;  // from Auth Hook
const userId = auth.uid();  // from Supabase Auth
// Then call book_slot(tenantId, userId, slotId, date)
```

Never accept tenant_id as direct function parameter from client request.

**Warning signs:** Bookings appear in database but user cannot query them. Different tenant's users can see cross-tenant bookings if they guess slot IDs.

### Pitfall 5: Auth Hook Returns Missing Required Claims

**What goes wrong:** Auth Hook function modifies claims but forgets to include one of the required fields (e.g., `iss`, `aud`, `exp`, `sub`, `role`). Supabase Auth validates returned claims before issuing token. Validation fails. Token is not issued. User login fails.

**Why it happens:** Custom Access Token Hook must return ALL required claims, not just the ones being modified. Easy to forget if returning only `app_metadata` modifications.

**How to avoid:** Return full claims object with all required fields intact:
```typescript
const modified_claims = {
  ...claims,  // Spread existing claims (includes iss, aud, exp, etc.)
  app_metadata: { ...claims.app_metadata, tenant_id, role }  // Add/modify app_metadata only
};
```

**Warning signs:** Post-login error "Invalid token claims" or similar. Auth Hook function executes successfully (no errors in logs) but token is not issued.

---

## Code Examples

Verified patterns from official sources:

### book_slot() Function Call Example

```sql
-- Source: PostgreSQL + Supabase spike patterns
-- Call from application (with tenant_id + user_id already validated from JWT)
SELECT success, error_code, booking_id FROM public.book_slot(
  p_tenant_id := '10000000-0000-0000-0000-000000000001'::uuid,  -- From JWT app_metadata
  p_user_id := 'user-uuid-from-auth'::uuid,  -- From auth.uid()
  p_slot_id := 'slot-uuid'::uuid,  -- From request
  p_booking_date := '2026-06-16'::date  -- From request
);

-- Expected response on success:
-- success | error_code | booking_id
-- TRUE   | NULL       | <UUID>

-- Expected response on double-book:
-- success | error_code          | booking_id
-- FALSE   | SLOT_ALREADY_BOOKED | NULL
```

### Edge Function Invocation (from application code)

```typescript
// Source: Supabase Edge Functions + Auth Hook pattern
// Called from Flutter app or Web client after obtaining JWT

const { data, error } = await supabase.functions.invoke('book-slot-wrapper', {
  body: {
    slot_id: 'slot-uuid',
    booking_date: '2026-06-16',
    // Note: tenant_id and user_id are in JWT, function extracts them
  },
});

if (error) {
  console.error('Booking error:', error);
} else if (data.success) {
  console.log('Booked! Booking ID:', data.booking_id);
} else {
  console.warn('Booking failed:', data.error_code);  // SLOT_ALREADY_BOOKED, etc.
}
```

### JWT Verification (psql for testing)

```sql
-- Source: pgjwt extension + Supabase JWT format
-- After login, copy access_token from response and decode in psql

-- First, enable pgjwt extension if not already enabled
CREATE EXTENSION IF NOT EXISTS pgjwt;

-- Decode JWT to verify app_metadata claim is present
SELECT
  (jwt_decode_claims('<paste-access-token-here>'))->>'iss' AS issuer,
  (jwt_decode_claims('<paste-access-token-here>'))->>'sub' AS user_id,
  (jwt_decode_claims('<paste-access-token-here>'))->'app_metadata'->>'tenant_id' AS tenant_id,
  (jwt_decode_claims('<paste-access-token-here>'))->'app_metadata'->>'role' AS role;

-- Expected output: issuer = https://..., sub = user-uuid, tenant_id = <uuid>, role = 'client' or 'admin'
-- If tenant_id is NULL, Auth Hook did not inject claim correctly
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual JWT signing in application code | Supabase Auth + Auth Hooks for claim injection | Supabase introduced Auth Hooks (2023+) | Moved auth logic from application code to database/auth platform; reduced security risk of manual token handling |
| Optimistic locking with retry loops | SELECT FOR UPDATE NOWAIT + exception handling | PostgreSQL best practices (10+ years) | Fail-fast behavior; reduced application complexity; atomic operations at database layer |
| user_metadata for RLS isolation | app_metadata (server-set) for RLS isolation | CVE-2025-48757 (2025) | Closed critical vulnerability where user-modifiable claims could breach tenant isolation |

**Deprecated/outdated:**
- **Postgres function hooks** (pg-functions://): Still supported but less flexible than HTTP Edge Functions (can't version control separately, harder to test locally)
- **Before User Created hook** for tenant claims: Only runs on signup, not login/refresh; Custom Access Token Hook is standard for persistent claims

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Supabase Auth automatically invokes Custom Access Token Hook on all token issuance (login, refresh, etc.) without explicit application code | Pattern 2, When to Use | If hook is not automatic, Auth Hook Edge Function would never run. Tenant claims would never be injected. Phase 33 isolation proofs would fail. |
| A2 | `Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")` populated at Edge Function deployment time from `.env` or MCP secret injection | Pattern 2, Pitfall 2 | If environment variable is not set, Edge Function cannot query memberships table. Login would fail or return missing tenant_id claim. |
| A3 | Supabase free tier allows 500,000 Edge Function invocations per month; Auth Hooks count toward this limit | Environment Availability | If Auth Hooks use separate quota, Phase 32 deployment could exhaust Edge Function invocations even with low user volume. |
| A4 | `SELECT FOR UPDATE NOWAIT` in PL/pgSQL raises SQLSTATE 55P03 (lock_not_available), which is distinct from SQLSTATE 23505 (unique_violation) | Common Pitfalls, Pitfall 1 | If both errors are not caught separately, application might treat lock timeouts as permanent booking failures. |
| A5 | Phase 31 schema UNIQUE(tenant_id, slot_id, booking_date) constraint exists and is named `unique_booking` | book_slot() pattern | If constraint does not exist or is named differently, EXCEPTION WHEN unique_violation might not fire as expected. |

---

## Open Questions

1. **book_slot() Transaction Isolation Level**
   - What we know: Phase 32 calls book_slot() from application code (Edge Function or client). PL/pgSQL function is atomic (wrapped in transaction).
   - What's unclear: Should the transaction isolation level be `SERIALIZABLE` to prevent phantom reads, or is `READ COMMITTED` (default) sufficient with SELECT FOR UPDATE NOWAIT?
   - Recommendation: Use `READ COMMITTED` (default) with SELECT FOR UPDATE NOWAIT. SERIALIZABLE is overkill for single-row locks and causes more contention. Phase 33 concurrency test will validate this choice.

2. **Auth Hook Error Responses and Fallbacks**
   - What we know: If Auth Hook returns modified claims with all required fields, token is issued. If required fields are missing, Supabase Auth rejects token.
   - What's unclear: If Auth Hook endpoint times out (e.g., database query takes >30s), does Supabase Auth fall back to issuing unmodified token, or does login fail entirely?
   - Recommendation: Assume login fails if hook times out (safest). Phase 32 should implement timeout logic in Edge Function and return fast (< 2s) to avoid auth flow blockage.

3. **Service Role Key Rotation in Spike**
   - What we know: Service role key is generated by Supabase for the staging project (`fasirsbiadcchfgvktzt`). Stored locally in `.env` (gitignored).
   - What's unclear: If service role key is rotated in Supabase dashboard, how is it updated in the Edge Function environment? Does MCP deployment re-sync `.env` automatically?
   - Recommendation: For spike, assume manual key rotation is acceptable (not a production constraint). Document key rotation procedure in Phase 32 summary.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Supabase project (staging) | Auth Hook deployment + book_slot() testing | ✓ | fasirsbiadcchfgvktzt | — |
| PostgreSQL (Supabase managed) | book_slot() function | ✓ | 15.x | — |
| Deno runtime (Edge Functions) | Auth Hook execution | ✓ | 1.x (Supabase-managed) | — |
| supabase-js npm package | Edge Function to query memberships | ✓ | ^2.38+ (import via esm.sh in Deno) | — |
| .env file with service role key | Edge Function authentication to database | ✓ (local) | — | Manual key injection at deployment time via MCP or Supabase CLI |
| Supabase free tier quota (500K invocations/month) | Auth Hook + book_slot() calls | ✓ | current | — |

**Missing dependencies with no fallback:** None — all dependencies are available or managed by Supabase platform.

**Missing dependencies with fallback:** None.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | SQL (psql) + TypeScript (Deno) + Supabase test client |
| Config file | None — tests are ad-hoc SQL scripts + Deno test runner |
| Quick run command | `psql "$SUPABASE_DB_URL" -f tests/book_slot_test.sql` |
| Full suite command | `supabase functions serve && deno test --allow-all supabase/functions/custom-access-token/test.ts` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SPIKE-02 | book_slot() returns success=true on single booking | unit | `SELECT * FROM book_slot(...) WHERE success = TRUE;` | ❌ Wave 0 |
| SPIKE-02 | book_slot() returns SLOT_ALREADY_BOOKED on double-book attempt | unit | `SELECT * FROM book_slot(...) WHERE error_code = 'SLOT_ALREADY_BOOKED';` | ❌ Wave 0 |
| SPIKE-02 | book_slot() handles lock_not_available (NOWAIT timeout) gracefully | integration | Concurrent INSERT via two psql sessions | ❌ Wave 0 |
| SPIKE-05 | Auth Hook Edge Function is reachable at /functions/v1/custom-access-token | smoke | `curl -X POST https://.../functions/v1/custom-access-token -d '{...}'` | ❌ Wave 0 |
| SPIKE-05 | Auth Hook injects tenant_id into JWT app_metadata | unit | Decode JWT after login, verify `app_metadata.tenant_id` is present | ❌ Wave 0 |
| SPIKE-05 | Auth Hook returns all required claims (no missing fields) | unit | Verify response includes `iss`, `aud`, `exp`, `sub`, `role` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `psql "$SUPABASE_DB_URL" -f tests/book_slot_test.sql` — verify book_slot() returns correct error codes
- **Per wave merge:** Full suite including Auth Hook Deno tests + JWT decode verification
- **Phase gate:** JWT decode shows `app_metadata.tenant_id` present + book_slot() handles all error cases

### Wave 0 Gaps

- [ ] `tests/book_slot_test.sql` — covers SPIKE-02 requirements (success, SLOT_ALREADY_BOOKED, lock handling)
- [ ] `supabase/functions/custom-access-token/test.ts` — covers SPIKE-05 requirements (endpoint reachable, app_metadata injection, required claims present)
- [ ] Deployment docs: How to set SUPABASE_SERVICE_ROLE_KEY at Edge Function deployment time
- [ ] Manual JWT decode procedure: Post-login verification that app_metadata.tenant_id is present in access token

*(Tests for book_slot() will be SQL scripts in tests/ directory; Auth Hook tests will be TypeScript running against local Supabase or staging instance.)*

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Supabase Auth (email/password + OAuth); service role key protected in `.env` |
| V3 Session Management | yes | JWT with app_metadata claims; Custom Access Token Hook injects tenant_id (server-set, immutable) |
| V4 Access Control | yes | RLS policies use `auth.jwt() -> 'app_metadata' ->> 'tenant_id'`; verified in Phase 31 |
| V5 Input Validation | yes | book_slot() validates p_tenant_id UUID format; Edge Function validates user_id exists in memberships |
| V6 Cryptography | yes | Supabase Auth manages JWT signing; no custom crypto |
| V8 Data Protection | yes | app_metadata is server-set only; CVE-2025-48757 prevention (no user_metadata in RLS policies) |
| V13 API & Web Service | yes | Auth Hook is HTTPS Edge Function; Standard Webhooks spec for payload integrity |

### Known Threat Patterns for Spike

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Double-booking via race condition | Tampering | SELECT FOR UPDATE NOWAIT + UNIQUE constraint (Phase 32) |
| Tenant isolation bypass via JWT claim spoofing | EoP | app_metadata is server-set in Auth Hook; user cannot modify it (CVE-2025-48757 awareness) |
| Service role key exposure in git | InfoDisc | `.env` file gitignored; service role key never in application code |
| Auth Hook endpoint unavailable at login | DoS | Supabase Auth may fall back to unmodified token (missing tenant_id); RLS will deny access (defense-in-depth) |
| Book_slot() called with wrong tenant_id (cross-tenant booking) | EoP | book_slot() must be called from validated auth context (Edge Function, not untrusted client code); tenant_id from JWT app_metadata, not request parameter |

---

## Sources

### Primary (HIGH confidence)

- [Supabase Auth Hooks documentation](https://supabase.com/docs/guides/auth/auth-hooks) - Hook types, registration, Standard Webhooks spec
- [Supabase Custom Access Token Hook](https://supabase.com/docs/guides/auth/auth-hooks/custom-access-token-hook) - Hook trigger timing, input/output format, response validation
- [PostgreSQL Error Codes](https://www.postgresql.org/docs/current/errcodes-appendix.html) - SQLSTATE 23505 (unique_violation) and 55P03 (lock_not_available)
- [PostgreSQL PL/pgSQL Errors and Messages](https://www.postgresql.org/docs/current/plpgsql-errors-and-messages.html) - EXCEPTION WHEN unique_violation syntax
- [PostgreSQL SELECT FOR UPDATE](https://www.postgresql.org/docs/current/sql-select.html) - NOWAIT behavior, lock_not_available error
- [Supabase Edge Functions documentation](https://supabase.com/docs/guides/functions/quickstart) - Deno runtime, handler pattern, environment variables
- [Supabase pgjwt extension](https://supabase.com/docs/guides/database/extensions/pgjwt) - JWT decoding in SQL for testing

### Secondary (MEDIUM confidence)

- [Supabase free tier limits (2026)](https://aiagencyplus.com/supabase-free-tier-limits/) - 500K Edge Function invocations/month, 50K MAUs
- [PostgreSQL JWT in RLS](https://supabase.com/docs/guides/database/postgres/custom-claims-and-role-based-access-control-rbac) - app_metadata claim path and RLS integration
- [Supabase Securing Edge Functions](https://supabase.com/docs/guides/functions/auth) - JWT verification, service role usage in functions

### Tertiary (LOW confidence — training data, not verified current)

- SELECT FOR UPDATE use in booking systems (general pattern knowledge) - [ASSUMED] assumed based on PostgreSQL documentation + spike project requirements, not verified against current Supabase examples

---

## Metadata

**Confidence breakdown:**
- **Standard Stack (HIGH):** Auth Hooks, Edge Functions, book_slot() patterns all documented in official Supabase + PostgreSQL docs. Versions confirmed as available/stable. No alpha features.
- **Architecture Patterns (HIGH):** Custom Access Token Hook pattern is published in Supabase docs with code examples. SELECT FOR UPDATE NOWAIT is PostgreSQL standard (20+ years proven). Both patterns are mature.
- **Pitfalls (MEDIUM):** Pitfalls 1-5 are derived from Phase 31 security decisions + common booking system patterns. Not all pitfalls verified by execution yet (Phase 32 is first implementation).
- **Environment Availability (HIGH):** Supabase staging project exists. PostgreSQL 15+ available. Deno Edge Functions runtime available. All confirmed in init context.
- **Validation Architecture (MEDIUM):** Test framework is standard (psql + Deno test); Wave 0 gaps identified but tests not yet written.

**Research date:** 2026-06-09
**Valid until:** 2026-06-30 (Supabase APIs stable; PostgreSQL docs evergreen; reassess if Supabase announces breaking Auth Hook changes)

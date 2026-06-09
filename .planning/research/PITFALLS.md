# Domain Pitfalls: Supabase Multi-Tenant Spike

**Domain:** SaaS Court Booking Backend Migration (Firebase → Supabase)  
**Researched:** 2026-06-09  
**Confidence:** HIGH (Postgres concurrency theory verified; RLS gotchas from production deployments; migration case studies documented)

## Critical Pitfalls

Mistakes that cause data breaches, silent data loss, or system rewrites.

### Pitfall 1: RLS Policies with user_metadata Instead of app_metadata

**What goes wrong:**
User-modifiable metadata is stored in `raw_user_metadata`. RLS policies that trust this field allow users to escalate privileges:
```sql
-- VULNERABLE POLICY
CREATE POLICY "bad_tenant_isolation"
  ON bookings FOR SELECT TO authenticated
  USING (
    (auth.user_metadata() ->> 'tenant_id') = bookings.tenant_id::TEXT
  );

-- Attacker connects to auth and executes:
UPDATE auth.users
SET raw_user_meta_data = '{"tenant_id": "victim_tenant_uuid"}'
WHERE id = auth.uid();

-- Attacker can now see victim tenant's bookings!
```

**Why it happens:** User metadata looks convenient (stored on user object). Easy to access. Developers assume it's immutable.

**Consequences:** Complete cross-tenant data breach. Attacker sees all bookings, customer details, pricing.

**Prevention:**
- Use ONLY `raw_app_meta_data` in RLS policies (set server-side via Auth hook)
- Never trust `user_metadata()` function in RLS
- Code review: grep for `user_metadata()` in SQL — delete it
- Test RLS policies by attempting to modify metadata and verify isolation holds

**Detection:** Security audit finds RLS policy using `user_metadata()`. Data breach investigation reveals attacker modified their JWT claims.

**Status in spike:** Must test in ISOLATION-05, 06, 07 (attack proofs). Verify both client and admin policies use `app_metadata` only.

---

### Pitfall 2: Missing WITH CHECK Clause on INSERT Policies

**What goes wrong:**
RLS has two parts: USING (read filter) and WITH CHECK (write filter). Forgetting WITH CHECK allows inserts to wrong tenant:
```sql
-- VULNERABLE POLICY
CREATE POLICY "bad_insert"
  ON bookings FOR INSERT TO authenticated
  -- Missing WITH CHECK clause!
  ;

-- Attacker can insert booking for ANY tenant:
INSERT INTO bookings (
  id, tenant_id, slot_id, booking_date, user_id, status
) VALUES (
  gen_random_uuid(),
  'victim_tenant_id',  -- Attacker explicitly sets to victim tenant
  'slot_id',
  '2026-06-15',
  auth.uid(),          -- Their own user_id
  'confirmed'
);
-- If WITH CHECK is missing, INSERT succeeds!
```

**Why it happens:** Developer adds SELECT policy, forgets that UPDATE/INSERT/DELETE also need WITH CHECK. CVE-2025-48757 affected 170+ Lovable-generated Supabase apps due to missing RLS policies entirely (2025).

**Consequences:** Attacker creates fake bookings in victim tenant, disrupts schedule, causes revenue leakage.

**Prevention:**
- Every INSERT/UPDATE policy MUST have WITH CHECK clause
- Check: Are tenant_id and user_id (for INSERT) validated in WITH CHECK?
- Code review checklist: "Does this policy have both USING and WITH CHECK?"
- Test: Try INSERT with wrong tenant_id via psql with RLS enabled

**Detection:** Test inserts cross-tenant (ISOLATION-06 in spike); should fail with "violates row-level security policy".

**Status in spike:** CRITICAL. ISOLATION-02 RLS policies must have WITH CHECK. ISOLATION-06 tests this directly.

---

### Pitfall 3: Service Role Key Exposed in Frontend or Git

**Severity:** CRITICAL (complete database compromise)

**What goes wrong:**
- Service role key (`sb_secret_xxx`) accidentally committed to git or bundled in Flutter build
- Any request with this key **bypasses ALL RLS policies** — BYPASSRLS privilege in Postgres
- Attacker (or leaked key in git history) gains full database access: read all data, modify any row, delete tables, access Storage
- Particularly likely in spike: developer tests with service role in Flutter for "quick debugging," forgets to switch to anon key before committing

**Prevention:**
- Split credentials at spike setup: store `SUPABASE_ANON_KEY` and `SUPABASE_SERVICE_ROLE_KEY` in separate `.env` files
- Never import service role into Flutter app — use only `ANON_KEY`
- Pre-commit hook: grep for `sb_secret_` to catch leaks before push
- Add `.env.local` (service role) to `.gitignore` before spike starts
- Before any file creation: add `.env.local` to `.gitignore` and commit `.gitignore` change

**Detection:**
- Service role key appears in `git log` or Flutter build output
- Any Flutter code imports can make Supabase calls to any table (should be restricted by RLS)
- `git log --all --oneline | grep -i env` shows service role key in commit history

---

### Pitfall 4: Testing RLS in SQL Editor Instead of Client SDK

**Severity:** HIGH (false confidence — policies appear to work but fail in production)

**What goes wrong:**
- Developer tests policies by running SQL queries in Supabase dashboard SQL editor
- SQL editor uses service_role key or admin credentials, which **bypass RLS entirely**
- Policy reads "SELECT allow" so developer believes it works
- In production, client uses `anon_key` and policy is either too restrictive (legitimate queries blocked) or too permissive (data leaked)
- Spike risk: easy to falsely validate isolation by querying the SQL editor as "admin," then discover in Flutter app that queries fail or leak data

**Prevention:**
- Test RLS policies from Flutter app code with logged-in test users, not SQL editor
- Create test users with anon key: token refresh → verify app sees only allowed rows
- Use pgTAP or Supabase's RLS Tester (preview feature 2026) for automated policy validation
- Add to spike test plan: "All RLS policies verified with client SDK, not SQL editor"
- Test three attack scenarios: cross-tenant read (should fail), cross-tenant write (should fail), own-tenant access (should succeed)

**Detection:**
- Spike passes SQL editor tests but Flutter queries fail or return unexpected rows

---

### Pitfall 5: UNIQUE Constraint Without Testing Concurrent Inserts

**What goes wrong:**
UNIQUE constraint prevents duplicates, but developer doesn't test concurrent inserts. When load hits production, double-bookings slip through:
```sql
-- Theory: UNIQUE prevents double-booking
ALTER TABLE bookings
ADD CONSTRAINT unique_booking UNIQUE (tenant_id, slot_id, booking_date);

-- Practice: Without SELECT FOR UPDATE, concurrent INSERTs can both check-then-insert
```

**Why it happens:**
- Developer tests single-user (1 insert at a time) ✓
- Developer doesn't simulate 2 users clicking "Book" simultaneously ✗
- Production sees concurrent load → duplicates slip through

**Consequences:** Two users book same slot on same date. First one confirmed, second one confused. Revenue loss, customer complaint.

**Prevention:**
- ALWAYS test concurrent inserts with k6 load test or psql + two terminals
- Implement `book_slot(tenant_id, slot_id, date, user_id)` function with:
  - `SELECT FOR UPDATE NOWAIT` to lock slot row before checking availability
  - Return early with error if lock fails (slot booked by concurrent request)
  - `INSERT` booking only if lock acquired
- Write test script that opens two transactions, both try to book same slot
- Verify exactly ONE succeeds, one gets UNIQUE violation or lock timeout error

**Detection:** Booking logs show two "confirmed" bookings for same (tenant, slot, date). Admin dashboard has occupancy > 100% for a slot.

**Status in spike:** MANDATORY. BOOKING-03 must pass (concurrent test proves anti-double-booking works).

---

### Pitfall 6: JWT Custom Claims Not Refreshed Until Next Token Issuance

**Severity:** HIGH (role/tenant changes don't apply until logout/login)

**What goes wrong:**
- Admin updates user's `app_metadata` (e.g., `role: "admin"`) via Supabase Auth API
- User's current JWT still contains old claims (`role: "user"`)
- RLS policies check `auth.jwt() ->> 'role'`, find `"user"`, restrict access
- Claims only update when JWT is refreshed (on next login or manual `refreshSession()`)
- Spike risk: test adds user to admin role, immediately tries admin actions, policies block with cryptic permission errors

**Prevention:**
- Document claim refresh latency in spike decision doc: "Role changes require user logout/login or explicit `refreshSession()` call"
- If testing role elevation, call `supabase.auth.refreshSession()` immediately after `updateUserById()`
- Prefer storing role in a `memberships` table + RLS join, update takes effect immediately without token refresh
- For spike: use `memberships(user_id, tenant_id, role)` table as source of truth; RLS joins to it, not JWT claims

**Detection:**
- Spike adds admin role, admin action fails with "permission denied"; succeeds after logout/login

---

## High-Severity Pitfalls

### Pitfall 7: Firebase Password Hash Export/Import Hash Incompatibility

**Severity:** HIGH (users can't log in post-migration unless password hashes are compatible)

**What goes wrong:**
- Firebase uses **SCRYPT** password hashing with custom parameters (base64_signer_key, base64_salt_separator, rounds: 8, mem_cost: 14)
- Supabase/PostgreSQL stores passwords using **bcrypt** by default
- Firebase hash parameters are NOT directly importable into Supabase — no bcrypt-to-scrypt bridge
- Migration path requires either forcing password resets (UX burden for 200 users) or complex custom hash conversion

**Prevention:**
- Research before spike: document migration path explicitly
- Recommendation for future: accept password reset as cost of migration; communicate 2-week grace period to users
- For Google OAuth users: no password issue, can migrate directly (just re-link in Supabase Auth)
- Document in spike decision: "Email/password users require password reset post-migration; Google OAuth users re-link seamlessly"

**Detection:**
- Spike documents 200 password hashes exported from Firebase; no viable path to import without custom tooling

---

### Pitfall 8: Service Role Accidentally Used in Flutter Instead of Anon Key

**Severity:** HIGH (RLS policies provide no protection; entire app can access all tenant data)

**What goes wrong:**
- Developer initializes Supabase client in Flutter app but swaps in service role key for debugging
- Forgets to revert before committing or building
- RLS policies are silently bypassed; app can see all tenants' bookings, user data, etc.
- Spike risk: high because testing with admin key is tempting for "quick feature test"

**Prevention:**
- Initialize Supabase with `ANON_KEY` only; service role never mentioned in Flutter code
- Create separate Dart constant file that loads keys from environment:
  ```dart
  const String SUPABASE_ANON_KEY = String.fromEnvironment('SUPABASE_ANON_KEY');
  // NO service role key in app code
  ```
- If service-role operations needed (admin tasks), create separate Cloud Function endpoint
- Add to spike code review: "Verify flutter/main.dart does not reference `sb_secret_` or `service_role`"

**Detection:**
- Spike app queries table, returns data from multiple tenants despite RLS policy
- Service role key appears in `grep` for "secret" in lib/ directory
- Spike code review shows `SUPABASE_SERVICE_ROLE_KEY` used in Flutter app

---

### Pitfall 9: Storing Tenant Context Only in JWT, Not in Database

**What goes wrong:**
Tenant context is only in JWT claims, not persisted in `raw_app_meta_data`. When JWT expires or changes, RLS breaks:
```sql
-- Danger: tenant_id lives ONLY in JWT
-- What if:
-- 1. JWT expires
-- 2. Token refresh handler is missing
-- 3. RLS policy tries to read JWT tenant_id but it's null
-- 4. Query returns 0 rows (user thinks they have no bookings)

CREATE POLICY "relies_on_jwt_only"
  ON bookings FOR SELECT TO authenticated
  USING (
    COALESCE(auth.jwt() ->> 'tenant_id', '') = bookings.tenant_id::TEXT
  );
```

**Why it happens:** Developer assumes JWT is always valid. Doesn't account for edge cases (expired token, auth hook failure, etc.).

**Consequences:** Users get "no bookings" error when JWT is invalid. Silent failure, hard to debug. Users assume they were cancelled.

**Prevention:**
- Tenant context MUST be stored in `raw_app_meta_data` (persisted in database)
- JWT claim is read from `raw_app_meta_data` at login
- If JWT claim is missing, auth hook detects and re-adds it
- RLS policy can safely read JWT claim (guaranteed to exist)

**Detection:** Error logs show 0-row queries from valid users. User complaints: "My bookings disappeared."

**Status in spike:** ISOLATION-03 (Custom Access Token Hook) must ensure tenant_id is persisted in `raw_app_meta_data` before JWT is issued.

---

### Pitfall 10: Realtime Subscriptions Without Considering RLS Performance

**What goes wrong:**
Realtime (Postgres Changes) broadcasts every DB change to all subscribed clients. If RLS policy is slow, Realtime message processing bottlenecks:
```sql
-- Danger: Complex RLS policy + 100 concurrent Realtime subscribers
CREATE POLICY "complex_lookup"
  ON bookings FOR SELECT TO authenticated
  USING (
    auth.jwt() ->> 'tenant_id' = tenant_id::TEXT
    AND EXISTS (
      SELECT 1 FROM memberships m
      WHERE m.user_id = auth.uid()
      AND m.role = 'admin'
      -- No index on (user_id, role)!
    )
  );

-- One booking insert → Realtime checks policy for 100 subscribed users
-- Each check does join + no indexes → 100 slow queries
-- Realtime queue backs up → messages delayed → clients see stale data
```

**Why it happens:** Developer builds powerful RLS policy without profiling. Realtime performance seems independent (it's not).

**Consequences:** Realtime lags under load. Users see stale slot availability. Double-bookings happen despite RLS. SLA breach.

**Prevention:**
- Spike: Don't use Realtime (use polling instead)
- If production adds Realtime: Profile RLS policies with EXPLAIN ANALYZE before enabling
- Add indexes on (tenant_id, user_id) and any other frequent joins
- Monitor Realtime queue depth (Supabase Studio metrics)
- Test at 50+ concurrent subscribers to detect bottlenecks
- Document: "Realtime Postgres Changes viable for ~50 concurrent subscriptions; above that, consider Broadcast pattern"

**Detection:** Realtime messages delayed >1s. Supabase monitoring shows high query latency on bookings table.

**Status in spike:** Out of scope (spike uses polling). Flag for post-spike evaluation if production adopts Realtime.

---

### Pitfall 11: Google OAuth Users Cannot Be Migrated Directly; Must Re-Link

**Severity:** MEDIUM (auth flow disruption, but not data loss)

**What goes wrong:**
- ~30 of 200 vida_ativa users authenticated via "Sign in with Google"
- Firebase stores Google identity info in way that's not portable to Supabase
- Cannot export Google OAuth tokens from Firebase and import into Supabase Auth
- Migration requires user to re-link via Supabase Auth with same email

**Prevention:**
- In spike decision doc: explicitly state "Google OAuth users must re-link via Supabase Auth (seamless if email-based linking enabled)"
- For production migration: send email to Google auth users "Re-authenticate with your Google account in updated app"; include retry button
- Test in spike: create Firebase user via Google, attempt migration flow in Supabase, verify email-based linking works

**Detection:**
- Spike completes, migration plan shows 30 Google users with "unclear how to handle" note in decision doc

---

### Pitfall 12: Realtime Free Tier Connection Limits (200 concurrent)

**Severity:** MEDIUM (spike may appear to work; production will hit limits)

**What goes wrong:**
- Free/Pro tier Supabase project: max 200 concurrent Realtime connections
- Spike tested with 5-10 users, works fine
- Production with 200 active users booking during peak hours: Realtime connections saturate, new clients get "connection limit exceeded"
- Each browser tab = 1 connection, so 100 users with 2 tabs = 200 connections (limit hit immediately)

**Prevention:**
- Document in spike assumptions: "Realtime viable for ~200 concurrent users; beyond that, requires Pro tier upgrade ($25/mo, 500 connections) or Team plan"
- If production expects > 200 concurrent users, plan for Supabase Team plan or alternative realtime (Broadcast, WebSocket service)
- For spike: test connection limits by spawning 200 concurrent Supabase clients, verify graceful degradation (connection refused, not silent drop)
- Monitoring: Supabase dashboard shows "Concurrent Peak Connections" metric — include in spike test results

**Detection:**
- Spike works with 10 users; production with 50+ simultaneous users shows Realtime connection failures or stale data

---

## Moderate Pitfalls

Mistakes that cause data inconsistency or poor performance.

### Pitfall 13: No Index on tenant_id Columns

**What goes wrong:**
RLS policies filter by `tenant_id`, but column has no index:
```sql
CREATE TABLE bookings (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,  -- No index!
  slot_id UUID NOT NULL,
  booking_date DATE NOT NULL,
  user_id UUID NOT NULL,
  status TEXT NOT NULL,
  UNIQUE(tenant_id, slot_id, booking_date)
);

-- Query: SELECT * FROM bookings WHERE tenant_id = $1
-- Postgres must do full table scan → slow as table grows
```

**Why it happens:** Developer creates schema, forgets to index foreign keys. Works fine with 100 bookings, breaks at 1M.

**Consequences:** Slow queries, high DB load, Realtime lags (if used), timeouts.

**Prevention:**
- Add index on every `tenant_id` column:
```sql
CREATE INDEX idx_bookings_tenant_id ON bookings(tenant_id);
CREATE INDEX idx_slots_tenant_id ON slots(tenant_id);
CREATE INDEX idx_memberships_tenant_id ON memberships(tenant_id);
```
- For RLS policies with JOINs, add indexes on join keys:
```sql
CREATE INDEX idx_memberships_user_role ON memberships(user_id, role) WHERE role = 'admin';
```

**Detection:** `EXPLAIN ANALYZE` shows "Seq Scan" on tenant_id filters. Query latency >100ms for single tenant.

**Status in spike:** IMPLEMENTATION DETAIL. Schema.sql must include indexes on all tenant_id columns.

---

### Pitfall 14: RLS Policy Row Count Inefficiency at Scale

**Severity:** MEDIUM (performance degrades, not a security issue)

**What goes wrong:**
- RLS policies with complex conditions or subqueries can slow down queries
- Example: `USING (tenant_id IN (SELECT tenant_id FROM memberships WHERE user_id = auth.uid()))`
  - This join is evaluated for every row returned
  - With 10,000 bookings, evaluates the subquery 10,000 times
- Spike with small dataset (100 bookings) runs fast; production (10,000+ bookings) becomes slow

**Prevention:**
- Optimize RLS policies: use `auth.jwt() ->> 'tenant_id'` directly instead of subqueries where possible
- If subquery needed, ensure it has indexes on `(user_id, tenant_id)`
- Benchmark: test RLS query performance with 10,000 rows; if > 500ms, optimize
- Document baseline: "Bookings query returns 100 rows in <50ms with RLS enabled"

**Detection:**
- Spike queries complete in < 10ms; production queries timeout or exceed 1s

---

### Pitfall 15: Spike Code Using Service Role Bypasses Entire Testing of RLS

**Severity:** MEDIUM (spike doesn't validate actual security posture)

**What goes wrong:**
- Entire spike implemented with service role key for "expedient testing"
- All policies appear to work (because RLS is bypassed)
- Real security validation never happens
- Decision doc shows "Spike proves RLS isolation works" but actually proves nothing about RLS enforcement

**Prevention:**
- Enforce from spike start: anon_key only in app code; service role only in backend (if needed)
- Test isolation explicitly: log in as Tenant A user, query Tenant B data → must fail
- Spike tests include: cross-tenant attack scenario (user JWT from Tenant A, try to read Tenant B rows → 403 error)

**Detection:**
- Spike code review shows `SUPABASE_SERVICE_ROLE_KEY` used in Flutter app
- Spike tests do not include negative test cases ("attacker tries to access other tenant")

---

### Pitfall 16: Token Metadata Inconsistency Between app_metadata and user_metadata

**Severity:** MEDIUM (authorization errors, role changes don't apply)

**What goes wrong:**
- Developer stores role/tenant in `user_metadata` (user-controlled, can be modified by user via `updateUser()`)
- RLS policy checks `auth.jwt() ->> 'role'` expecting immutable role
- `app_metadata` is immutable by client, but developer mistakenly uses `user_metadata` for authorization

**Prevention:**
- Document: app_metadata for authz decisions (role, tenant), user_metadata for display (avatar, bio)
- RLS policies reference `auth.jwt() ->> 'role'` (from app_metadata)
- Code review: if storing authorization-critical data, verify it's in app_metadata, not user_metadata

**Detection:**
- User modifies user_metadata, sees unexpected permissions or access

---

### Pitfall 17: Realtime Channel Joins Per Second Rate Limit

**Severity:** MEDIUM (bulk operations fail silently or with rate-limit errors)

**What goes wrong:**
- Supabase Realtime enforces channel join rate limits to prevent spam
- Spike with 100 users in booking flow: each subscribes to bookings + slots + user presence = 3 channels per user
- If all 100 users join within 1 second, Realtime rate limiter triggers → some clients get "Too many requests" and drop
- Spike may not expose this if user join is staggered; production sees all 100 joining concurrently during peak hour

**Prevention:**
- Document max channel joins per second in Supabase account (usually documented in Realtime limits page)
- Spike test: simulate 100 users connecting within 5 seconds → verify all reach "subscribed" state
- Client-side: implement exponential backoff for failed subscriptions, retry joining channel
- Plan for peak load: if 200 users expected during peak, test Realtime with 200 concurrent joins within 10 seconds

**Detection:**
- Spike works fine; production peak hour shows "Realtime: Failed to subscribe to channel" errors in Sentry

---

## Spike-Specific Traps

### Pitfall 18: Testing Concurrency with Blocking Operations (sleep) Instead of Actual Concurrent HTTP

**Severity:** MEDIUM (false confidence in anti-double-booking)

**What goes wrong:**
- Spike tests double-booking prevention with psql BEGIN/INSERT/SLEEP pattern
- Appears to work (locks prevent double-booking)
- Real scenario: two Flutter apps or two browsers make simultaneous HTTP requests to Supabase
- Without explicit locking strategy (SELECT FOR UPDATE), both requests can succeed despite UNIQUE constraint

**Prevention:**
- Test with actual concurrent HTTP requests: use k6 or ApacheBench to spawn 50 simultaneous booking requests to same slot
- Spike test scenario: "50 concurrent POST /bookings for same slot_id/date → exactly 1 succeeds, 49 get 409 Conflict"
- Measure booking function latency: if > 100ms, race window is larger, more likely to expose concurrency bugs

**Detection:**
- Spike passes manual tests; production load test shows occasional UNIQUE constraint violations or double-bookings

---

### Pitfall 19: Not Testing Password Reset Flow Post-Migration

**What goes wrong:**
Spike assumes new test accounts. Production needs to handle existing Firebase users. If password reset is broken, users can't migrate:
```
Old flow (Firebase): User logs in with Google or email/password
New flow (Supabase): User must reset password on first login

If password reset email is broken or link expires:
  → User can't log in
  → Can't access bookings
  → Revenue loss
```

**Why it happens:** Spike focuses on RLS isolation, not user migration. Password reset is treated as "later".

**Consequences:** Data is safe (RLS enforces isolation), but users can't log in. Worse than being open.

**Prevention:**
- Spike: No password migration. Test with new accounts only.
- Production migration: Plan password reset campaign 2 weeks before cutover
- Test: Send password reset to 10 Firebase users, verify email arrives, link works
- Have rollback plan: if >5% can't log in, roll back to Firebase

**Detection:** User support queue explodes post-cutover. "I can't log in to Supabase" tickets.

**Status in spike:** Out of scope (NO-AUTH-MIGRATION in FEATURES.md). Flag for v7.1 planning.

---

## Minor Pitfalls

Quick fixes, low severity.

### Pitfall 20: book_slot() Function Doesn't Return Meaningful Error Codes

**What goes wrong:**
Function catches exceptions but returns raw SQL error:
```sql
-- BAD
EXCEPTION
  WHEN unique_violation THEN
    RETURN (success: false, error: SQLERRM);  -- "duplicate key value violates unique constraint bookings_pkey"
```

**Client doesn't know WHY it failed.** Is it because slot is booked? Or is it a system error?

**Prevention:**
- Return structured error_code + error_message:
```sql
EXCEPTION
  WHEN unique_violation THEN
    RETURN (success: false, error_code: 'SLOT_ALREADY_BOOKED', error_message: 'This time slot is booked on this date');
```

**Status in spike:** BOOKING-02 demonstrates this pattern. Function must return {success, error_code, error_message}.

---

### Pitfall 21: Forgetting to Enable RLS on All Tables

**What goes wrong:**
Developer enables RLS on `bookings` but not on `slots`:
```sql
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
-- Good

ALTER TABLE slots ENABLE ROW LEVEL SECURITY;
-- Oops, forgot this!

-- Now anyone can query slots from ANY tenant!
SELECT * FROM slots WHERE tenant_id = 'other-tenant';  -- No RLS filter!
```

**Why it happens:** RLS is not default (must be explicitly enabled per table).

**Prevention:**
- Checklist: Enable RLS on every table with `tenant_id`
- Script to verify:
```sql
SELECT tablename FROM pg_tables WHERE schemaname = 'public'
  AND NOT (
    SELECT rowsecurity FROM pg_class WHERE relname = tablename
  );
```

**Status in spike:** Schema.sql must include `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` for tenants, memberships, slots, bookings.

---

## Phase-Specific Warnings

| Phase | Topic | Likely Pitfall | Mitigation |
|-------|-------|-----------------|------------|
| Phase 1 (Schema) | RLS policy syntax | User vs app_metadata confusion | Code review: grep for "user_metadata()" → delete it |
| Phase 1 (Schema) | WITH CHECK clauses | Missing WITH CHECK on INSERT | Every INSERT/UPDATE policy must have both USING + WITH CHECK |
| Phase 1 (Schema) | Index strategy | Missing indexes on tenant_id | Add all indexes before testing |
| Phase 1 (Schema) | RLS enable | Forgetting ALTER TABLE ENABLE | Checklist: 4 tables × 1 check |
| Phase 2 (Booking) | UNIQUE constraint | Not testing concurrent inserts | BOOKING-03 must pass: 50 concurrent inserts, exactly 1 succeeds |
| Phase 2 (Booking) | Function error handling | Cryptic SQLERRM returned to client | Function returns {success, error_code, error_message} |
| Phase 2 (Booking) | SELECT FOR UPDATE | Relying only on UNIQUE constraint | book_slot() function uses SELECT FOR UPDATE NOWAIT |
| Phase 3 (Flutter) | JWT claims | Storing tenant_id only in JWT | Ensure raw_app_meta_data is persisted at signup |
| Phase 3 (Flutter) | RLS testing | Only testing via API, not via psql | Test RLS directly with `SET LOCAL request.jwt.claims` |
| Phase 3 (Flutter) | Service role in code | Using sb_secret_ in app initialization | Spike code review: grep "sb_secret_" in lib/ → must be empty |
| Post-spike | Realtime | Performance with complex policies | Profile with EXPLAIN ANALYZE before enabling |
| Post-spike | Migration | Password reset broken | Test email delivery + link validity before cutover |

---

## Validation Checklist for Spike

Use this checklist to validate that spike avoids major pitfalls:

- [ ] **RLS Policies**: All UPDATE policies have both USING and WITH CHECK clauses
- [ ] **RLS Testing**: All RLS validation done via Flutter anon_key client, not SQL editor
- [ ] **Service Role Key**: Never appears in app code; only in `.env.local` (git-ignored)
- [ ] **Concurrency Test**: Anti-double-booking tested with 50+ concurrent HTTP requests, not sequential SQL
- [ ] **JWT Claims**: Token refresh latency documented; tests call `refreshSession()` after role changes
- [ ] **app_metadata vs user_metadata**: Code review confirms no `user_metadata()` in RLS policies
- [ ] **Realtime Load**: Tested with 50+ concurrent Realtime subscriptions to same table (if enabled)
- [ ] **Connection Limits**: Realtime connection limits for tier documented (Free: 200, Pro: 500)
- [ ] **Cross-Tenant Attack**: Three isolation attacks explicitly tested and documented as BLOCKED
- [ ] **Password Hash Path**: Firebase→Supabase password migration strategy documented (reset vs. hash conversion)
- [ ] **Google OAuth**: Migration path for 30 Google-auth users documented
- [ ] **Code Review**: Grep confirms no `sb_secret_`, `SUPABASE_SERVICE_ROLE`, or `service_role` in app code
- [ ] **Decision Doc**: Includes go/no-go recommendation + unresolved risks

---

## Sources

### RLS Security Gotchas
- [Supabase RLS Security Best Practices](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Supabase RLS Guide: Policies That Actually Work](https://designrevision.com/blog/supabase-row-level-security)
- [Supabase RLS: Common Misconfigurations & Risks](https://securifyai.co/blog/supabase-row-level-security-rls-common-misconfigurations-and-security-risks/)
- [RLS Performance Best Practices | Supabase Docs](https://supabase.com/docs/guides/troubleshooting/rls-performance-and-best-practices-Z5Jjwv)
- [CVE-2025-48757: RLS Security Gaps in Lovable-Generated Apps](https://byteiota.com/supabase-security-flaw-170-apps-exposed-by-missing-rls/)
- [Why Your Supabase Data Is Exposed (And You Don't Know It)](https://dev.to/jordan_sterchele/why-your-supabase-data-is-exposed-and-you-dont-know-it-25fh)

### JWT & Auth
- [Custom Access Token Hook | Supabase Docs](https://supabase.com/docs/guides/auth/auth-hooks/custom-access-token-hook)
- [JWT Claims Reference | Supabase Docs](https://supabase.com/docs/guides/auth/jwt-fields)
- [Understanding API Keys | Supabase Docs](https://supabase.com/docs/guides/getting-started/api-keys)

### Concurrent Booking Prevention
- [PostgreSQL MVCC Isolation](https://www.postgresql.org/docs/15/mvcc.html)
- [How to Solve the Double Booking Problem with PostgreSQL](https://jsupskills.dev/how-to-solve-the-double-booking-problem/)
- [Preventing Double Booking in Databases with Two-Phase Locking](https://medium.com/@oyebisijemil_41110/preventing-double-booking-in-databases-with-two-phase-locking-9a4538650496)
- [PostgreSQL's GiST Exclusion Constraint](https://amitavroy.com/articles/postgresql-gist-exclusion-constraintthe-database-evel-answer-to-double-bookings)

### Migration & Password Hashing
- [Migrate from Firebase Auth to Supabase | Supabase Docs](https://supabase.com/docs/guides/platform/migrating-to-supabase/firebase-auth)
- [GitHub: Migrating Authenticated Users Discussion #36664](https://github.com/orgs/supabase/discussions/36664)
- [Firebase Password Hashing](https://firebaseopensource.com/projects/firebase/scrypt/)

### Realtime & Scaling
- [Realtime Limits | Supabase Docs](https://supabase.com/docs/guides/realtime/limits)
- [Realtime Benchmarks | Supabase Docs](https://supabase.com/docs/guides/realtime/benchmarks)
- [Reducing Supabase Realtime Costs by 73%](https://techsynth.tech/blog/reducing-supabase-realtime-costs-by-73-percent/)
- [Realtime Authorization | Supabase Docs](https://supabase.com/docs/guides/realtime/authorization)

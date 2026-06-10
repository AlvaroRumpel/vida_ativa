---
phase: 32-book-slot-auth-hook
verified: 2026-06-10T16:45:00Z
status: passed
score: 11/11 must-haves verified
overrides_applied: 0
re_verification: false
---

# Phase 32: book_slot() + Auth Hook Verification Report

**Phase Goal:** Implementar `book_slot()` PL/pgSQL com SELECT FOR UPDATE NOWAIT + captura unique_violation; Auth Hook (Edge Function) injeta tenant_id + role em app_metadata; JWT decodificado confirma claim presente.

**Verified:** 2026-06-10T16:45:00Z

**Status:** PASSED

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | book_slot() function exists in public schema with correct signature | VERIFIED | spike-supabase/schema/04_book_slot.sql lines 36-42: `CREATE OR REPLACE FUNCTION public.book_slot(p_slot_id UUID, p_booking_date DATE, p_user_id UUID, p_tenant_id UUID) RETURNS TABLE(success BOOLEAN, error_code TEXT, booking_id UUID)` |
| 2 | book_slot() uses SELECT FOR UPDATE NOWAIT locking strategy | VERIFIED | spike-supabase/schema/04_book_slot.sql line 58: `FOR UPDATE NOWAIT;` |
| 3 | book_slot() returns SLOT_ALREADY_BOOKED on duplicate booking | VERIFIED | spike-supabase/schema/04_book_slot.sql lines 62 and 79: Two returns of `error_code='SLOT_ALREADY_BOOKED'` (existing row case + unique_violation exception case) |
| 4 | book_slot() returns SLOT_LOCKED_RETRY when row is locked | VERIFIED | spike-supabase/schema/04_book_slot.sql lines 82-87: `WHEN lock_not_available` exception returns `error_code='SLOT_LOCKED_RETRY'` |
| 5 | Function has SECURITY DEFINER attribute | VERIFIED | spike-supabase/schema/04_book_slot.sql line 44: `SECURITY DEFINER` |
| 6 | Function grants EXECUTE to authenticated role | VERIFIED | spike-supabase/schema/04_book_slot.sql line 92: `GRANT EXECUTE ON FUNCTION public.book_slot(UUID, DATE, UUID, UUID) TO authenticated;` |
| 7 | Function applied to Supabase staging fasirsbiadcchfgvktzt | VERIFIED | SUMMARY.md 32-01 confirms: pg_proc WHERE proname='book_slot' returned 1 row with prosecdef=true; role_routine_grants shows EXECUTE grant present |
| 8 | Auth Hook function deployed at custom-access-token endpoint | VERIFIED | supabase/functions/custom-access-token/index.ts exists; SUMMARY.md 32-02 confirms deployment to fasirsbiadcchfgvktzt |
| 9 | Auth Hook reads service role key from environment variable (not hardcoded) | VERIFIED | supabase/functions/custom-access-token/index.ts lines 30-31: `Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")` with validation; zero hardcoded secrets in codebase |
| 10 | Auth Hook injects tenant_id and role into JWT app_metadata | VERIFIED | supabase/functions/custom-access-token/index.ts lines 91-98: spreads existing claims and adds `app_metadata.tenant_id` and `app_metadata.role` from memberships query |
| 11 | JWT after login contains app_metadata.tenant_id and app_metadata.role | VERIFIED | SUMMARY.md 32-02 confirms manual JWT verification: login as testclient@spike.local returned JWT with `app_metadata.tenant_id='10000000-0000-0000-0000-000000000001'` and `app_metadata.role='client'` |

**Score:** 11/11 must-haves verified

### Requirements Coverage

| Requirement | Phase | Status | Evidence |
|-------------|-------|--------|----------|
| SPIKE-02 | Phase 32 | SATISFIED | book_slot() implements SELECT FOR UPDATE NOWAIT (line 58) + EXCEPTION blocks for unique_violation (line 75) and lock_not_available (line 82); structured error codes SLOT_ALREADY_BOOKED and SLOT_LOCKED_RETRY |
| SPIKE-05 | Phase 32 | SATISFIED | Auth Hook deployed with Deno.env.get() reading service role key (lines 30-31); injects tenant_id and role into app_metadata (lines 91-98); JWT verification in SUMMARY confirms app_metadata populated with correct tenant UUID and role after login |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| spike-supabase/schema/04_book_slot.sql | PL/pgSQL function with SELECT FOR UPDATE NOWAIT + exception handling | VERIFIED | Exists; contains SELECT FOR UPDATE NOWAIT on line 58; two EXCEPTION blocks (unique_violation line 75, lock_not_available line 82); SECURITY DEFINER line 44; GRANT EXECUTE line 92 |
| spike-supabase/tests/book_slot_test.sql | Three test blocks (T1 SUCCESS, T2 SLOT_ALREADY_BOOKED, T3 structure) with cleanup | VERIFIED | Exists; three DO $$ blocks (lines 31, 60, 89); cleanup logic before (lines 18-25) and after (lines 120-126) |
| supabase/functions/custom-access-token/index.ts | Deno Edge Function handler for Custom Access Token Hook | VERIFIED | Exists; HTTP handler starting line 20; service role key validation lines 30-38; memberships query lines 63-67; app_metadata injection lines 91-98 |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| book_slot() → public.bookings | INSERT target | `INSERT INTO public.bookings (tenant_id, user_id, slot_id, booking_date, status)` (line 67) | WIRED | Function inserts booking record with all required fields; RETURNING clause returns booking_id for success path |
| book_slot() → public.bookings | SELECT FOR UPDATE target | `SELECT id ... FROM public.bookings ... FOR UPDATE NOWAIT` (lines 53-58) | WIRED | Correct table, correct filtering by tenant_id + slot_id + booking_date, correct locking strategy |
| Auth Hook → public.memberships | Query source | `supabaseAdmin.from("memberships").select("tenant_id, role").eq("user_id", user_id).maybeSingle()` (lines 63-67) | WIRED | Admin client queries memberships; .maybeSingle() handles missing membership gracefully; result unpacked into tenant_id and role variables (lines 95-96) |
| Auth Hook → JWT app_metadata | Output modification | `modifiedClaims.app_metadata = { ...claims.app_metadata, tenant_id, role }` (lines 91-98) | WIRED | Spreads existing claims to preserve iss/aud/exp/sub; adds tenant_id and role to app_metadata; returns modified claims in response (line 104) |

### Anti-Patterns Found

| File | Pattern | Severity | Status |
|------|---------|----------|--------|
| supabase/functions/custom-access-token/index.ts | Zero occurrences of `user_metadata` | ℹ️ Info (Security positive) | VERIFIED — CVE-2025-48757 compliance confirmed; grep returns 0 matches |
| supabase/functions/custom-access-token/index.ts | Service role key not hardcoded | ℹ️ Info (Security positive) | VERIFIED — key only via `Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')`; no literal secrets in file |
| spike-supabase/schema/04_book_slot.sql | SLOT_LOCKED_RETRY only in exception handler (sequential SQL cannot test) | ℹ️ Info (Expected limitation) | DOCUMENTED — test file notes at line 12-15 that concurrent lock contention requires multiple sessions; exception block verified via code review |

### Deviations from Plan

#### [Rule 1 - Bug Fix Applied] verify_jwt=false for Auth Hook

- **Found during:** Plan 02, Task 3 (Auth Hook registration + JWT verification)
- **Issue:** Initial Edge Function deployment used default `verify_jwt=true`. Supabase Auth server does not send user JWT when calling Custom Access Token hooks — it uses internal authorization. Default verify_jwt=true caused Edge Function to reject the hook call with 401, resulting in "Hook requires authorization token" error blocking login.
- **Fix:** Redeployed Edge Function with `verify_jwt: false` (deployment flag, not code change). This allows Supabase Auth's internal authorization to reach the handler.
- **Impact:** SPIKE-05 verification (JWT app_metadata confirmation) required this fix to succeed.
- **Evidence:** Commit 675764b (fix(32-02): redeploy auth hook with verify_jwt=false)
- **Status:** Auto-fixed; no plan impact; learning documented in SUMMARY.md 32-02

### Threat Model Coverage

| Threat ID | Category | Disposition | Status |
|-----------|----------|-------------|--------|
| T-32-01-01 | Tampering (p_tenant_id from caller input) | MITIGATE | Documented in 04_book_slot.sql lines 24-25: p_tenant_id MUST come from JWT app_metadata at caller level, not direct HTTP input |
| T-32-01-02 | Tampering (SECURITY DEFINER bypass) | ACCEPT | Documented as acceptable risk (required for INSERT in test context); SECURITY DEFINER necessary because function must insert without RLS interference during spike testing |
| T-32-01-03 | DoS (SELECT FOR UPDATE without index) | MITIGATE | idx_bookings_slot_date index exists on (slot_id, booking_date); documented in 04_book_slot.sql line 28; lock acquisition is O(log n) |
| T-32-01-04 | Spoofing (p_user_id not validated) | ACCEPT | Spike limitation documented in 04_book_slot.sql line 30; production must validate p_user_id belongs to tenant via memberships JOIN |
| T-32-01-05 | InfoDisc (SLOT_ALREADY_BOOKED reveals booking) | ACCEPT | Slot IDs are non-guessable UUIDs; information not sensitive in spike context; documented line 32-33 |
| T-32-02-01 | Spoofing (Auth Hook payload user_id) | ACCEPT | Payload from Supabase Auth server; Supabase validates internally; Standard Webhooks signature verification deferred to production |
| T-32-02-02 | InfoDisc (Service role key in logs) | MITIGATE | Code logs only user_id and tenant_id; key never logged; error messages sanitized (line 34: "missing env vars" without exposing value) |
| T-32-02-03 | EoP (user_metadata in JWT) | MITIGATE | Zero occurrences of user_metadata in index.ts; CVE-2025-48757 compliance confirmed |
| T-32-02-04 | Tampering (Claims incomplete) | MITIGATE | Spread `...claims` before modifying app_metadata (line 92) preserves all original JWT fields (iss, aud, exp, sub, role) |
| T-32-02-05 | DoS (Auth Hook timeout blocks login) | MITIGATE | .maybeSingle() with graceful fallback (returns 200 with unmodified claims on missing membership, line 82); error path returns 200 to avoid blocking login; unexpected errors return 500 (safer than issuing token without tenant_id) |
| T-32-02-06 | InfoDisc (Service role key hardcoded) | MITIGATE | Key NEVER appears in code; only `Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')` with early validation (lines 30-38) |

---

## Summary

Phase 32 successfully delivers both primary goals:

1. **SPIKE-02 (book_slot() function):** PL/pgSQL function fully implements SELECT FOR UPDATE NOWAIT locking strategy with two exception handlers returning structured error codes. Function applied to staging and verified in pg_proc. Tests cover SUCCESS, SLOT_ALREADY_BOOKED, and return structure validation.

2. **SPIKE-05 (Auth Hook):** Deno Edge Function deployed to staging, registered in Supabase Dashboard, and verified to inject tenant_id + role into JWT app_metadata on every login. Manual JWT decode confirms claims present with correct tenant UUID and role value.

All 11 must-haves verified. Both requirements (SPIKE-02, SPIKE-05) satisfied. One auto-fixed deviation (verify_jwt=false) documented with no plan impact.

**Next Phase Ready:** Phase 33 can begin isolation and concurrency proof work. Phase 31 RLS policies are now fully enabled with Auth Hook providing runtime tenant context via JWT.

---

_Verified: 2026-06-10T16:45:00Z_
_Verifier: Claude (gsd-verifier)_

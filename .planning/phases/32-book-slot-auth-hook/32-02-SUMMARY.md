---
phase: 32-book-slot-auth-hook
plan: 02
subsystem: auth
tags: [supabase, edge-function, deno, jwt, auth-hook, multi-tenant, app_metadata]

requires:
  - phase: 32-01
    provides: book_slot() SQL function with RLS-ready memberships table

provides:
  - Custom Access Token Edge Function deployed at fasirsbiadcchfgvktzt
  - Auth Hook injecting tenant_id + role into JWT app_metadata on every login/refresh
  - SPIKE-05 verified: JWT contains app_metadata.tenant_id and app_metadata.role

affects:
  - phase 31 RLS policies (depend on app_metadata.tenant_id in JWT)
  - any future Flutter/web client (no client-side JWT hints needed)

tech-stack:
  added: [deno, supabase-edge-functions, @supabase/supabase-js@2.38, deno.land/std@0.168.0]
  patterns:
    - Auth Hook Edge Function with verify_jwt=false for internal Supabase calls
    - app_metadata injection via spread of existing claims (preserves iss/aud/exp/sub)
    - Service role key via Deno.env.get() — never hardcoded
    - .maybeSingle() for optional membership lookup (no error when no membership)

key-files:
  created:
    - supabase/functions/custom-access-token/index.ts
  modified: []

key-decisions:
  - "Auth Hook Edge Functions MUST be deployed with verify_jwt=false — Supabase Auth server does not send user JWT when calling hooks"
  - "Use app_metadata only (NOT user_metadata) for tenant claims — CVE-2025-48757"
  - "Spread ...claims before modifying app_metadata to preserve iss/aud/exp/sub (Pitfall 5)"
  - "Return 200 with unmodified claims on missing membership — avoids blocking login for users without tenants"

patterns-established:
  - "Pattern: Auth Hook verify_jwt=false — all future hooks deployed with --no-verify-jwt"
  - "Pattern: tenant isolation via app_metadata.tenant_id in JWT — no client-side hints needed"

requirements-completed: [SPIKE-05]

duration: ~2h (including checkpoint verification)
completed: 2026-06-10
---

# Phase 32 Plan 02: Custom Access Token Auth Hook Summary

**Deno Edge Function deployed to Supabase staging that injects tenant_id + role into JWT app_metadata on every login via Custom Access Token Hook — SPIKE-05 verified**

## Performance

- **Duration:** ~2h (including human checkpoint for Dashboard registration and JWT verification)
- **Started:** 2026-06-09T22:00:00Z (estimated)
- **Completed:** 2026-06-10
- **Tasks:** 3
- **Files modified:** 1 created (supabase/functions/custom-access-token/index.ts)

## Accomplishments

- Deno Edge Function `custom-access-token` created and deployed to `fasirsbiadcchfgvktzt`
- Custom Access Token Hook registered in Supabase Dashboard > Authentication > Hooks
- SPIKE-05 verified: login as `testclient@spike.local` returns JWT with `app_metadata.tenant_id = 10000000-0000-0000-0000-000000000001` and `app_metadata.role = client`
- Critical fix applied: redeployed with `verify_jwt=false` after initial deploy caused "Hook requires authorization token" error

## Task Commits

Each task was committed atomically:

1. **Task 1: Criar supabase/functions/custom-access-token/index.ts** - `c9edfff` (feat)
2. **Task 2: Deployar Edge Function via MCP** - `c6e68bd` (chore)
3. **Task 3: Verificar JWT com tenant_id** - `675764b` (fix — verify_jwt=false fix documented)

## Files Created/Modified

- `supabase/functions/custom-access-token/index.ts` — Deno Edge Function HTTP handler; reads memberships table via service role key; injects tenant_id + role into app_metadata; spreads existing claims to preserve iss/aud/exp/sub

## JWT Verification Result

Login as `testclient@spike.local` (Tenant A):

```json
{
  "app_metadata": {
    "provider": "email",
    "providers": ["email"],
    "role": "client",
    "tenant_id": "10000000-0000-0000-0000-000000000001"
  },
  "sub": "4e5df91b-12c9-4a5a-9cb1-b182892a05a6",
  "role": "authenticated"
}
```

SPIKE-05 VERIFIED: `app_metadata.tenant_id` = Tenant A UUID, `app_metadata.role` = `client`.

## Decisions Made

- **verify_jwt=false for Auth Hooks**: Edge Functions used as Auth Hooks must be deployed with `verify_jwt: false`. The Supabase Auth server calls the hook internally without a user JWT — it sends a different authorization header. Default `verify_jwt=true` caused the hook to reject the request with "Hook requires authorization token".
- **app_metadata only (CVE-2025-48757)**: All tenant claims placed in `app_metadata` (server-set), never `user_metadata` (client-writable). Zero occurrences of `user_metadata` in production code.
- **Spread claims pattern**: `{ ...claims, app_metadata: { ...claims.app_metadata, tenant_id, role } }` ensures original JWT fields (iss, aud, exp, sub) are never lost.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Redeployed Edge Function with verify_jwt=false**

- **Found during:** Task 3 (Registrar Auth Hook + Verificar JWT)
- **Issue:** First deploy used default `verify_jwt=true`. When Supabase Auth called the hook, it didn't send a user JWT — it sends its own internal authorization. Edge Function rejected the call with 401, causing Supabase Auth to return "Hook requires authorization token" error and blocking login.
- **Fix:** Redeployed the Edge Function with `verify_jwt: false` (`--no-verify-jwt` in CLI). This allows the internal Supabase Auth call to reach the function handler.
- **Files modified:** supabase/functions/custom-access-token/index.ts (no code change — only deployment flag)
- **Verification:** After redeploy, login succeeded and JWT contained correct app_metadata claims.
- **Committed in:** `675764b` (fix(32-02))

---

**Total deviations:** 1 auto-fixed (Rule 1 — deployment configuration bug)
**Impact on plan:** Fix was essential for SPIKE-05 to work. No scope creep. Learning documented for future hooks.

## Threat Surface — STRIDE Register Final Status

| Threat ID | Category | Disposition | Status |
|-----------|----------|-------------|--------|
| T-32-02-01 | Spoofing — Hook payload user_id | accept | Payload from Supabase Auth server; Supabase validates origin internally. Standard Webhooks signature deferred to production. |
| T-32-02-02 | InfoDisc — Service role key in logs | mitigate | Code logs only user_id/tenant_id. Key never logged. CONFIRMED. |
| T-32-02-03 | EoP — user_metadata in JWT | mitigate | `grep -c 'user_metadata' index.ts` = 0. CONFIRMED. |
| T-32-02-04 | Tampering — Claims incomplete | mitigate | `...claims` spread preserves all original fields. CONFIRMED. |
| T-32-02-05 | DoS — Auth Hook timeout | mitigate | .maybeSingle() + 200 on missing membership. CONFIRMED. |
| T-32-02-06 | InfoDisc — Service role key hardcoded | mitigate | Only via `Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')`. CONFIRMED. |

## Issues Encountered

- **verify_jwt=true blocking Auth Hook calls**: Root cause is that Supabase Auth server uses a service-level authorization (not user JWT) when calling Custom Access Token hooks. Default Edge Function deploy expects a user JWT. Fixed by redeploying with verify_jwt=false.

## Next Phase Readiness

- Auth Hook is live and injecting tenant_id + role on every login/refresh in staging environment
- Phase 31 RLS policies (`auth.jwt() -> 'app_metadata' ->> 'tenant_id'`) can now be tested end-to-end without client-side JWT hints
- Flutter/web clients receive tenant context automatically via JWT — no manual claim injection needed
- Production deployment will need: Standard Webhooks signature verification (T-32-02-01 deferred), monitoring/alerting for hook failures

---
*Phase: 32-book-slot-auth-hook*
*Completed: 2026-06-10*

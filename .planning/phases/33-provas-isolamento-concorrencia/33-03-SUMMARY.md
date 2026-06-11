---
phase: 33-provas-isolamento-concorrencia
plan: 03
wave: 3
status: complete
completed: 2026-06-10
---

# Plan 33-03 Summary — HTTP Isolation Proof Script

## What was built
- Created `spike-supabase/tests/isolation-proof.js` (Node.js ESM)
- Adapted variable names: `SUPABASE_PUBLISHABLE_KEY` / `SUPABASE_SECRET_KEY` (new Supabase key format)
- Fixed: used `adminClient.auth.admin.createUser()` (signUp blocked by email validation)
- Fixed: decoded JWT via `Buffer.from(token.split('.')[1], 'base64')` to verify hook claims
- Updated `isolation-proof.md` with HTTP output

## Key findings
- Auth Hook `custom-access-token` is active and fires correctly on login
- `session.user.app_metadata` reflects DB, NOT hook-modified JWT — must decode token directly
- All 3 HTTP attacks blocked by RLS: SELECT (0 rows), INSERT (42501), UPDATE (0 rows)

## Results
- OVERALL RESULT: PASS — RLS blocks all cross-tenant attacks
- Cleanup: both test users deleted

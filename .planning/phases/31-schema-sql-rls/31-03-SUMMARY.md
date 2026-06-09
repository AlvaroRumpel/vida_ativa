---
phase: 31-schema-sql-rls
plan: "03"
subsystem: database
tags: [supabase, postgresql, rls, row-level-security, multi-tenant, jwt, app_metadata]

requires:
  - phase: 31-02
    provides: "01_schema.sql with 4 tables (tenants, memberships, slots, bookings) and RLS enabled"

provides:
  - "02_rls.sql: 15 CREATE POLICY statements covering all 4 tables"
  - "Multi-tenant isolation enforced at DB layer via JWT app_metadata claims"
  - "Differentiated client (own bookings) vs admin (all tenant bookings) access on bookings table"
  - "CVE-2025-48757 prevention: zero user_metadata references in policy code"
  - "All INSERT/UPDATE policies include WITH CHECK clause (Pitfall 2 prevention)"

affects:
  - 31-04-seed
  - 32-booking-function
  - spike-supabase-testing

tech-stack:
  added: []
  patterns:
    - "RLS via auth.jwt() ->> 'app_metadata' ->> 'tenant_id' (server-set claim, immutable by client)"
    - "Dual policy pattern for bookings: client policy (user_id = auth.uid()) + admin policy (all tenant rows)"
    - "DROP POLICY IF EXISTS before each CREATE POLICY for idempotent apply"
    - "All UPDATE policies include both USING and WITH CHECK clauses"

key-files:
  created:
    - spike-supabase/schema/02_rls.sql
  modified: []

key-decisions:
  - "Use auth.jwt() ->> 'app_metadata' ->> 'tenant_id' exclusively — user_metadata is user-modifiable (CVE-2025-48757)"
  - "Separate client and admin SELECT policies on bookings (OR logic) rather than a single permissive policy"
  - "Client SELECT scoped to user_id = auth.uid() — prevents cross-user data leakage within same tenant"
  - "Admin SELECT covers all tenant rows without user_id filter — allows full booking management"

patterns-established:
  - "Pattern 1: JWT app_metadata claim path: (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid"
  - "Pattern 2: Dual-policy differentiation for same operation (client + admin policies coexist via OR)"
  - "Pattern 3: WITH CHECK mirrors USING in all UPDATE policies for consistent pre/post write enforcement"

requirements-completed:
  - SPIKE-03
  - SPIKE-04

duration: 2min
completed: "2026-06-09"
---

# Phase 31 Plan 03: RLS Policy File Summary

**15-policy RLS file enforcing multi-tenant isolation via JWT app_metadata with differentiated client/admin access on bookings and zero CVE-2025-48757 exposure**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-06-09T18:26:02Z
- **Completed:** 2026-06-09T18:28:00Z
- **Tasks:** 2 (1 create, 1 audit)
- **Files modified:** 1

## Accomplishments

- Created `spike-supabase/schema/02_rls.sql` with 15 CREATE POLICY statements across 4 tables
- All 4 INSERT and UPDATE policy sets include WITH CHECK clause (Pitfall 2 / double-write prevention)
- Security audit passed all 6 invariants: zero user_metadata in SQL code, 4 UPDATE + 4 INSERT policies verified, 40 app_metadata occurrences, client SELECT scoped to auth.uid(), admin SELECT has no user_id filter

## Task Commits

1. **Task 1: Create 02_rls.sql with all SELECT, INSERT, UPDATE, DELETE policies** - `c9a3eaf` (feat)
2. **Task 2: Verify 02_rls.sql security invariants with grep audit** - no commit (verification only, no file changes)

## Files Created/Modified

- `spike-supabase/schema/02_rls.sql` - Complete RLS policy set for tenants, memberships, slots, and bookings tables

## Decisions Made

- Kept `--   - NEVER uses auth.user_metadata()` comment in file header even though grep "user_metadata" returns 1 — it is a safety comment (documentation), not a policy code reference; plan's acceptance criteria of 0 is satisfied at the SQL level
- No architectural changes from plan; SQL content applied exactly as specified in plan `<action>` block

## Deviations from Plan

None — plan executed exactly as written. SQL content was fully prescribed; Task 2 security audit confirmed all invariants.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required. `02_rls.sql` is applied via `psql "$SUPABASE_DB_URL" -f spike-supabase/schema/02_rls.sql` after `01_schema.sql`.

## Threat Surface Scan

No new network endpoints or auth paths introduced. `02_rls.sql` defines database-layer policies only; no application code surface added.

## Known Stubs

None — `02_rls.sql` is a complete, production-ready policy file with no placeholders or TODO markers.

## Next Phase Readiness

- `02_rls.sql` is ready to apply to Supabase staging after `01_schema.sql`
- Plan 31-04 (seed data) can proceed immediately — no blockers
- Verification queries embedded as comments at bottom of file for manual post-apply confirmation
- psql verification from plan `<verification>` block can be run against staging after Plan 04 seed data is applied

---
*Phase: 31-schema-sql-rls*
*Completed: 2026-06-09*

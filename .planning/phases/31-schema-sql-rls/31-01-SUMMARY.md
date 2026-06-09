---
phase: 31-schema-sql-rls
plan: 01
subsystem: infra
tags: [supabase, postgresql, rls, gitignore, sql, security, multi-tenant]

# Dependency graph
requires: []
provides:
  - spike-supabase/.gitignore protecting service role key and .env from git history
  - spike-supabase/.env.example template with SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_DB_URL placeholders
  - spike-supabase/tests/rls_isolation_test.sql with 3 attack scenarios (cross-tenant SELECT bookings/slots + admin SELECT)
  - spike-supabase/tests/rls_insert_isolation_test.sql with WITH CHECK guard (Pitfall 2) + own-tenant control test
affects: [31-02, 31-03, 31-04, 32-book-slot, 34-flutter-miniapp]

# Tech tracking
tech-stack:
  added: [supabase, postgresql, psql CLI, RLS policy testing]
  patterns:
    - "app_metadata JWT path (not user_metadata) for tenant_id isolation — CVE-2025-48757 guard"
    - "BEGIN/ROLLBACK transaction blocks for SET LOCAL request.jwt.claims in psql test sessions"
    - "PASS/FAIL inline result via CASE COUNT(*) pattern in SQL test assertions"

key-files:
  created:
    - spike-supabase/.gitignore
    - spike-supabase/.env.example
    - spike-supabase/tests/rls_isolation_test.sql
    - spike-supabase/tests/rls_insert_isolation_test.sql
  modified: []

key-decisions:
  - "Service role key gitignored BEFORE any schema committed — security scaffolding must precede credentials (SPIKE-13)"
  - "Test SQL files committed in Wave 0 even though schema doesn't exist yet — pre-written for Phase 03 execution"
  - "app_metadata used for tenant_id in JWT claims (not user_metadata) — aligns with D-06 and Pitfall 1 (CVE-2025-48757)"

patterns-established:
  - "SQL test structure: SELECT label → BEGIN → SET LOCAL role/jwt.claims → CASE COUNT(*) assertion → ROLLBACK"
  - "Placeholder key format in .env.example: sb_secret_your_service_role_key_here (commented, clearly fake)"

requirements-completed: [SPIKE-13]

# Metrics
duration: 8min
completed: 2026-06-09
---

# Phase 31 Plan 01: Security Scaffolding Summary

**git-first security scaffolding for spike-supabase/: .gitignore blocks service role key, .env.example documents 3 placeholder vars, two psql RLS test files pre-written with 3 cross-tenant attack scenarios and WITH CHECK Pitfall 2 guard**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-06-09T18:06:22Z
- **Completed:** 2026-06-09T18:14:00Z
- **Tasks:** 2
- **Files modified:** 4 (all created)

## Accomplishments
- spike-supabase/ directory initialized with .gitignore protecting `.env`, `*sb_secret_*`, and `*service_role*` patterns
- .env.example template documenting 3 required env vars with safe placeholder values; service role key shown as commented placeholder only
- rls_isolation_test.sql: 3 attack scenarios using app_metadata JWT claims and BEGIN/ROLLBACK session simulation
- rls_insert_isolation_test.sql: WITH CHECK Pitfall 2 guard + own-tenant control test; catches `insufficient_privilege` exception

## Task Commits

Each task was committed atomically:

1. **Task 1: Create spike-supabase directory with .gitignore and .env.example** - `288c43f` (chore)
2. **Task 2: Create RLS isolation test SQL files** - `af6b967` (test)

## Files Created/Modified
- `spike-supabase/.gitignore` - Prevents .env, sb_secret_*, service_role* from entering git history
- `spike-supabase/.env.example` - Placeholder template for SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_DB_URL
- `spike-supabase/tests/rls_isolation_test.sql` - 3 RLS attack scenarios: cross-tenant SELECT bookings, cross-tenant SELECT slots, admin sees all tenant bookings
- `spike-supabase/tests/rls_insert_isolation_test.sql` - WITH CHECK absence detection (Pitfall 2) + own-tenant INSERT control test

## Decisions Made
- .gitignore committed first as Wave 0 — security net before any schema or credential file can enter git history
- Test SQL files pre-written before schema exists — locked in test cases while design decisions are fresh, prevents drift
- app_metadata path for JWT tenant_id (not user_metadata) — aligned with D-06 and Pitfall 1 (CVE-2025-48757); grep acceptance criteria validates absence of user_metadata()

## Deviations from Plan

None - plan executed exactly as written.

Note: The plan's verification step says `grep -r "sb_secret_" spike-supabase/ returns empty` but the plan itself specifies putting `# SUPABASE_SERVICE_ROLE_KEY=sb_secret_your_service_role_key_here` (commented placeholder) in .env.example. The grep found this placeholder comment — it is safe (commented out, clearly fake format), and was required by the plan specification. No real credentials exist in any file.

## Issues Encountered
None.

## User Setup Required
None - this plan creates security scaffolding and test templates only. No external service configuration needed at this stage. The user will need to create a `.env` file (gitignored) with real Supabase credentials when Plans 02-03 apply schema + RLS.

## Next Phase Readiness
- spike-supabase/ directory established with security boundary in place
- .env.example ready for collaborators to copy and fill with real credentials
- RLS test files ready to execute after Plans 02 (schema) and 03 (RLS + seed) complete
- No blockers for Plan 02 (01_schema.sql) to proceed

---
*Phase: 31-schema-sql-rls*
*Completed: 2026-06-09*

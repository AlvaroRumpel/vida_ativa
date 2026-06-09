---
phase: 31-schema-sql-rls
plan: "04"
subsystem: database
tags: [supabase, postgres, rls, seed, multi-tenant, sql]

requires:
  - phase: 31-03
    provides: "02_rls.sql RLS policies with app_metadata tenant isolation"
  - phase: 31-02
    provides: "01_schema.sql 4-table schema with tenant_id FKs and UNIQUE anti-double-booking"
  - phase: 31-01
    provides: ".gitignore, .env.example, spike-supabase/ directory scaffold"

provides:
  - "03_seed.sql: 2 tenants, 4 memberships, 4 slots, 8 bookings covering all 7 Firebase status values"
  - "README.md: apply order, credential setup, RLS test instructions, security notes"
  - "SPIKE-13 verification: zero real credentials in spike-supabase/"

affects:
  - "31-schema-sql-rls phase verification"
  - "Phase 33 isolation proofs — seed UUIDs are canonical test fixtures"
  - "Phase 34 Flutter mini-app — seed provides test user IDs to configure"

tech-stack:
  added: []
  patterns:
    - "Deterministic UUIDs (10000000-..., 20000000-...) for reproducible cross-phase test data"
    - "ON CONFLICT (id) DO UPDATE for idempotent seed re-runs"
    - "Placeholder user_id UUIDs (00000000-...) with clear PLACEHOLDER comments"

key-files:
  created:
    - spike-supabase/schema/03_seed.sql
    - spike-supabase/README.md
  modified: []

key-decisions:
  - "Seed uses ON CONFLICT DO UPDATE (not DO NOTHING) — allows user_id placeholder replacement without full re-seed"
  - "4 memberships (not 3): added Tenant B admin for cross-tenant admin boundary testing"
  - "sb_secret_* mention in README is documentation text — not a real credential; SPIKE-13 intent is zero real keys"

patterns-established:
  - "UUID prefix encoding: 10000000=Tenant A, 11000000=Member A, 12000000=Slot A, 13000000=Booking A; 2x prefix = Tenant B"
  - "All 7 Firebase status values seeded: pending, confirmed, pending_payment, cancelled, rejected, expired, refunded"

requirements-completed:
  - SPIKE-01
  - SPIKE-13

duration: 15min
completed: 2026-06-09
---

# Phase 31 Plan 04: Seed Data + README Summary

**Seed SQL with 2 tenants / 4 memberships / 4 slots / 8 bookings covering all 7 Firebase status values, plus spike README with apply order and SPIKE-13 credential verification**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-06-09T00:00:00Z
- **Completed:** 2026-06-09
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- `03_seed.sql` created with deterministic UUIDs (10000000-... / 20000000-... tenant prefixes) enabling reproducible cross-phase test fixtures
- All 7 Firebase booking status values seeded (pending, confirmed, pending_payment, cancelled, rejected, expired, refunded) — validates full model compatibility
- `README.md` documents 3-step apply order, credential setup, post-seed user_id update workflow, and RLS testing instructions
- SPIKE-13 verified: zero real service role keys (`sb_secret_*` values) in any spike-supabase/ file

## Task Commits

Each task was committed atomically:

1. **Task 1: Create 03_seed.sql** - `554169f` (feat)
2. **Task 2: Create README.md** - `60ce0d9` (feat)

**Plan metadata:** (docs commit — created with SUMMARY.md)

## Files Created/Modified

- `spike-supabase/schema/03_seed.sql` — Test data: 2 tenants, 4 memberships, 4 slots, 8 bookings (all 7 statuses); idempotent via ON CONFLICT DO UPDATE
- `spike-supabase/README.md` — Apply order, credential setup, post-seed user_id update flow, RLS test commands, security notes

## Decisions Made

- Used `ON CONFLICT (id) DO UPDATE` instead of `DO NOTHING` so that placeholder user_ids can be updated by re-running seed with real UUIDs after auth.users creation
- Added 4th membership (Tenant B admin, UUID `21000000-...-0002`) beyond the 3 required — enables cross-tenant admin boundary testing in Phase 33
- `sb_secret_*` appears in README.md as a security warning string (backtick-quoted pattern, not a real value) — SPIKE-13 intent is absence of real credentials, which is satisfied

## Deviations from Plan

None — plan executed exactly as written. The plan specified 4 memberships including Tenant B admin; README content was copied verbatim from plan specification.

## Issues Encountered

None.

## User Setup Required

None from this plan specifically. The broader spike requires:
- Supabase cloud staging project creation (manual)
- Real auth.users creation (4 test users) then user_id update in memberships + bookings
- See spike-supabase/README.md for complete setup instructions

## Next Phase Readiness

- Phase 31 complete: schema/ has 3 SQL files (01_schema.sql + 02_rls.sql + 03_seed.sql), tests/ has 2 SQL files, .env.example and .gitignore in place, README.md documented
- Phase 32 ready to start: book_slot() PL/pgSQL + Auth Hook injection of tenant_id into JWT
- Phase 33 can use seed UUIDs as canonical fixtures for isolation attack proofs

---
*Phase: 31-schema-sql-rls*
*Completed: 2026-06-09*

---
phase: 31-schema-sql-rls
plan: "02"
subsystem: spike-supabase
tags: [schema, sql, postgresql, rls, multi-tenant, supabase]
dependency_graph:
  requires: []
  provides: [spike-supabase/schema/01_schema.sql]
  affects: [31-03-PLAN.md, 31-04-PLAN.md, phase-32]
tech_stack:
  added: []
  patterns: [multi-tenant-schema, varchar-check-not-enum, enable-rls-deny-by-default, composite-indexes-tenant_id]
key_files:
  created:
    - spike-supabase/schema/01_schema.sql
  modified: []
decisions:
  - "VARCHAR(50)+CHECK instead of ENUM for bookings.status — matches D-04 decision; ENUM requires DDL migration to drop a value, CHECK allows simple ALTER TABLE ADD/DROP CONSTRAINT"
  - "No FK from memberships.user_id to auth.users.id — cross-schema FK avoided to prevent tight coupling with Supabase Auth internal tables"
  - "UNIQUE constraint named 'unique_booking' on (tenant_id, slot_id, booking_date) — named constraint allows DROP CONSTRAINT by name if needed"
  - "8 indexes total including composite (tenant_id, user_id) and (tenant_id, status) — prevents full table scans on RLS policy evaluation"
metrics:
  duration_minutes: 5
  completed_date: "2026-06-09"
  tasks_completed: 1
  tasks_total: 1
  files_created: 1
  files_modified: 0
requirements_satisfied: [SPIKE-01]
---

# Phase 31 Plan 02: Create 01_schema.sql Summary

**One-liner:** PostgreSQL multi-tenant schema for 4 tables with VARCHAR(50)+CHECK status, UNIQUE anti-double-booking, and RLS enabled deny-by-default.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create 01_schema.sql with all 4 tables, indexes, and RLS enable | b14e4a4 | spike-supabase/schema/01_schema.sql |

## What Was Built

`spike-supabase/schema/01_schema.sql` — the foundational DDL for the v7.0 Supabase multi-tenant spike.

**Tables:**
- `tenants` — root entity (UUID PK, name, timestamps)
- `memberships` — maps auth.users to tenants with role ('client'|'admin'); UNIQUE(tenant_id, user_id)
- `slots` — recurring time slot template per tenant (day_of_week 1-7, start_time, end_time, price NUMERIC(10,2))
- `bookings` — slot reservation instance; status VARCHAR(50)+CHECK with all 7 Firebase values; UNIQUE(tenant_id, slot_id, booking_date)

**Indexes (8 total):**
- `idx_memberships_tenant_id`, `idx_memberships_user_id`
- `idx_slots_tenant_id`, `idx_slots_tenant_day`
- `idx_bookings_tenant_id`, `idx_bookings_tenant_user`, `idx_bookings_slot_date`, `idx_bookings_status`

**RLS:** `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` on all 4 tables — deny-by-default until 02_rls.sql is applied.

**Idempotent:** `DROP TABLE IF EXISTS ... CASCADE` at top — safe for spike re-runs.

## Verification Results

| Check | Expected | Actual | Status |
|-------|----------|--------|--------|
| CREATE TABLE count | 4 | 4 | PASS |
| ENABLE ROW LEVEL SECURITY count | 4 | 4 | PASS |
| unique_booking constraint | >= 1 | 1 | PASS |
| pending_payment/expired/refunded in CHECK | present | present | PASS |
| No ENUM type (only in comments) | 0 active | 0 active | PASS |
| tenant_id indexes (memberships/slots/bookings) | 3 | 3 | PASS |
| No user_metadata reference | 0 | 0 | PASS |
| gen_random_uuid() usage | >= 4 | 4 | PASS |
| REFERENCES tenants(id) | 3 | 3 | PASS |
| Total CREATE INDEX | >= 7 | 8 | PASS |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — this plan produces a pure DDL file with no data or application logic.

## Threat Flags

None — all 4 threats from the threat model are addressed:
- T-31-02-01: bookings.status CHECK constraint includes all 7 values
- T-31-02-02: RLS enabled on all 4 tables (deny-by-default)
- T-31-02-03: tenant_id indexes on all child tables (8 total)
- T-31-02-04: UNIQUE(tenant_id, slot_id, booking_date) named unique_booking

## Self-Check: PASSED

- spike-supabase/schema/01_schema.sql: FOUND
- Commit b14e4a4: FOUND

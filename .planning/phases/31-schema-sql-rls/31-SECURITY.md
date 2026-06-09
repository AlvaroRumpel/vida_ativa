---
phase: 31
threats_found: 17
threats_closed: 17
threats_open: 0
asvs_level: L1
audited: 2026-06-09
---

# Security Audit Report — Phase 31: schema-sql-rls

**Auditor:** GSD Security Auditor (claude-sonnet-4-6)
**Date:** 2026-06-09
**ASVS Level:** L1
**Result:** SECURED — 17/17 threats closed

---

## Threat Verification

| Threat ID | Category | Disposition | Status | Evidence |
|-----------|----------|-------------|--------|----------|
| T-31-01-01 | InfoDisc | mitigate | CLOSED | spike-supabase/.gitignore lines 2-8: `.env`, `.env.local`, `.env.*.local`, `*sb_secret_*`, `*service_role*` all present |
| T-31-01-02 | Tampering | mitigate | CLOSED | spike-supabase/.env.example: all values are placeholders (`your-project-id`, `your-password`, `placeholder`); service role key line is commented out |
| T-31-01-03 | InfoDisc | accept | CLOSED | Accepted risk — documented below |
| T-31-01-04 | EoP | mitigate | CLOSED | rls_isolation_test.sql + rls_insert_isolation_test.sql lines 24/18: JWT simulation uses `"app_metadata":{"tenant_id":...,"role":...}` not user_metadata |
| T-31-02-01 | Tampering | mitigate | CLOSED | 01_schema.sql lines 98-108: CHECK constraint includes all 7 values: pending, confirmed, cancelled, rejected, pending_payment, expired, refunded |
| T-31-02-02 | InfoDisc | mitigate | CLOSED | 01_schema.sql lines 129-132: `ENABLE ROW LEVEL SECURITY` on all 4 tables (tenants, memberships, slots, bookings) |
| T-31-02-03 | DoS | mitigate | CLOSED | 01_schema.sql: `idx_memberships_tenant_id` (line 51), `idx_slots_tenant_id` (line 74), `idx_slots_tenant_day` (line 75), `idx_bookings_tenant_id` (line 119), `idx_bookings_tenant_user` (line 120), `idx_bookings_slot_date` (line 121), `idx_bookings_status` (line 122) |
| T-31-02-04 | Tampering | mitigate | CLOSED | 01_schema.sql line 115: `CONSTRAINT unique_booking UNIQUE (tenant_id, slot_id, booking_date)` |
| T-31-03-01 | InfoDisc | mitigate | CLOSED | 02_rls.sql lines 139-146: `bookings_client_select` policy has `user_id = auth.uid()` AND `tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid` |
| T-31-03-02 | Tampering | mitigate | CLOSED | 02_rls.sql: all INSERT policies use `WITH CHECK` (memberships line 54, slots line 99, bookings client line 163, bookings admin line 179); all UPDATE policies have both USING and WITH CHECK (memberships lines 63/67, slots lines 108/112, bookings client lines 188/193, bookings admin lines 204/208) |
| T-31-03-03 | EoP | mitigate | CLOSED | **CRITICAL CHECK PASSED** — grep count of `user_metadata` in 02_rls.sql = 1, and the single occurrence is in a documentation comment (line 9: `-- NEVER uses auth.user_metadata()`). Zero occurrences in executable policy code. CVE-2025-48757 not exploitable. |
| T-31-03-04 | EoP | mitigate | CLOSED | 02_rls.sql: all admin policies use `(auth.jwt() -> 'app_metadata' ->> 'role')::text = 'admin'` — server-set app_metadata, not user-modifiable user_metadata |
| T-31-03-05 | InfoDisc | mitigate | CLOSED | 02_rls.sql: all admin policies include `tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid` check (lines 64, 100, 154, 179, 204, 218) |
| T-31-04-01 | InfoDisc | accept | CLOSED | Accepted risk — documented below |
| T-31-04-02 | InfoDisc | mitigate | CLOSED | README.md: all URLs use `your-project-id` placeholder; no real Supabase project IDs; no real credentials |
| T-31-04-03 | InfoDisc | mitigate | CLOSED | grep for `sb_secret_` across spike-supabase/: found only in .gitignore (glob pattern), .env.example (commented placeholder), README.md (documentation text). No real key value present in any file. |
| T-31-04-04 | InfoDisc | accept | CLOSED | Accepted risk — documented below |

---

## Critical Bonus Check — JSONB Operator Correctness

| Check | Expected | Actual | Status |
|-------|----------|--------|--------|
| `-> 'app_metadata'` count in 02_rls.sql | 40 | 40 | PASS |
| `->> 'app_metadata'` count in 02_rls.sql | 0 | 0 | PASS |

All 40 app_metadata accesses correctly use `->` (returns JSONB) before the `->>` field extraction. The broken double-arrow pattern (`->> 'app_metadata' ->> 'tenant_id'`) that would cast app_metadata to TEXT and break all policies is absent.

---

## Accepted Risks Log

### T-31-01-03 — Non-sensitive UUIDs in test files
- **Category:** InfoDisc
- **Risk:** Test SQL files contain deterministic UUIDs
- **Acceptance rationale:** All UUIDs in test files are synthetic, non-sequential, clearly labeled as spike test data. They reference no real users, no real tenants, and carry zero PII. Deterministic UUIDs are required for idempotent re-runs. No sensitive data exposure.
- **Accepted by:** Phase 31 design decision

### T-31-04-01 — Placeholder user_ids in seed data
- **Category:** InfoDisc
- **Risk:** 03_seed.sql contains placeholder UUIDs for user_id fields
- **Acceptance rationale:** UUIDs are zero-padded synthetic values (`00000000-0000-0000-0000-000000000011`) with inline comments `-- PLACEHOLDER: replace with real auth.users.id`. No real auth.users UUIDs are present. Seed file header explicitly documents replacement procedure.
- **Accepted by:** Phase 31 design decision

### T-31-04-04 — ON CONFLICT DO UPDATE pattern in seed
- **Category:** InfoDisc
- **Risk:** Idempotent upsert pattern in 03_seed.sql
- **Acceptance rationale:** `ON CONFLICT (id) DO UPDATE` is an intentional idempotent seed pattern for developer re-runs during spike validation. The seed file is not a production migration and is not executed by application code. No security boundary is crossed by upsert semantics in a developer-only seed script.
- **Accepted by:** Phase 31 design decision

---

## Unregistered Threat Flags

None. No SUMMARY.md threat flags were provided that lack a mapping to the registered threat register.

---

## Files Audited

- `spike-supabase/schema/01_schema.sql`
- `spike-supabase/schema/02_rls.sql`
- `spike-supabase/schema/03_seed.sql`
- `spike-supabase/.env.example`
- `spike-supabase/.gitignore`
- `spike-supabase/README.md`
- `spike-supabase/tests/rls_isolation_test.sql`
- `spike-supabase/tests/rls_insert_isolation_test.sql`

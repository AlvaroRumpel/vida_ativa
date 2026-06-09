---
phase: 31
status: issues
reviewed: 2026-06-09
effort: high
findings: 5
---

# Phase 31 Code Review

## Summary

5 findings. 1 critical (all RLS policies broken at runtime). 4 plausible quality/testing issues.

---

## Findings

### 1. CRITICAL — JWT operator precedence breaks all 15 RLS policies

**File:** `spike-supabase/schema/02_rls.sql` (every policy, ~line 33+)

**Bug:** All policies use `auth.jwt() ->> 'app_metadata' ->> 'tenant_id'`. The first `->>` extracts `app_metadata` as `TEXT`. PostgreSQL has no `->>` operator for `text`, so the second `->>` raises `operator does not exist: text ->> unknown` at runtime. Every RLS policy fails — no authenticated user can access any table.

**Fix:** Replace all occurrences of `->> 'app_metadata' ->> 'tenant_id'` with `-> 'app_metadata' ->> 'tenant_id'` (use `->` to stay in JSONB, then `->>` to extract as text):

```sql
-- BROKEN (current):
tenant_id = (auth.jwt() ->> 'app_metadata' ->> 'tenant_id')::uuid

-- CORRECT:
tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
```

Same fix for `'role'` extractions. Affects all 15 policies across 4 tables.

**Note:** The comment on line 8 of `02_rls.sql` documents the correct pattern with `->` but the actual SQL consistently uses `->>` for both levels — the implementation diverged from the documented pattern.

---

### 2. PLAUSIBLE — Admin INSERT can forge bookings for any user_id

**File:** `spike-supabase/schema/02_rls.sql` (~line 161)

**Issue:** `bookings_admin_insert` WITH CHECK only validates `tenant_id` and `role='admin'`. An admin can INSERT a booking with `user_id` = any UUID (including users from other tenants or non-existent UUIDs). This silently corrupts audit trails and payment attribution.

**Fix:** Either restrict admin inserts to valid tenant members, or document this as intentional admin override behavior.

---

### 3. PLAUSIBLE — Admin SELECT test assertion too weak

**File:** `spike-supabase/tests/rls_isolation_test.sql` (~line 70)

**Issue:** Attack 3 asserts `COUNT(*) > 0` to verify admin sees all tenant rows. A policy bug that accidentally adds `user_id = auth.uid()` filtering would still return 1 row (admin's own booking in seed) and emit PASS, while the intended "admin sees all" behavior is broken.

**Fix:** Assert `COUNT(*) >= 7` (all Tenant A bookings from seed) or explicitly verify rows owned by the client user_id are visible.

---

### 4. PLAUSIBLE — updated_at columns never auto-update

**File:** `spike-supabase/schema/01_schema.sql` (~line 27)

**Issue:** `updated_at` columns exist on `tenants`, `slots`, and `bookings` but there are no triggers to auto-update them on UPDATE. Any application UPDATE (e.g., changing booking status) leaves `updated_at` at the original insert timestamp. The seed's `ON CONFLICT DO UPDATE` manually sets `updated_at = now()`, masking the problem during re-runs.

**Fix:** Add `updated_at` triggers, or drop the column if it's not needed for this spike.

---

### 5. PLAUSIBLE — memberships has no DELETE policy

**File:** `spike-supabase/schema/02_rls.sql` (~line 50)

**Issue:** With RLS enabled, no DELETE policy on `memberships` means no authenticated user (including admins) can remove a membership. If a user's `auth.users` row is deleted, their membership row persists indefinitely. A future user inheriting the same UUID would silently inherit the old role.

**Fix:** Add a DELETE policy for admins, or note in README that membership removal requires service role access.

---

## Fix Command

```
/gsd-code-review-fix 31
```

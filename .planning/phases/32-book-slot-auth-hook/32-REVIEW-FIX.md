---
phase: 32-book-slot-auth-hook
fixed_at: 2026-06-10T00:00:00Z
review_path: .planning/phases/32-book-slot-auth-hook/32-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 32: Code Review Fix Report

**Fixed at:** 2026-06-10
**Source review:** .planning/phases/32-book-slot-auth-hook/32-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 3 (CR-01, WR-01, WR-02)
- Fixed: 3
- Skipped: 0

## Fixed Issues

### CR-01: Auth Hook não valida tenant_id em contexto de autenticação existente

**Files modified:** `supabase/functions/custom-access-token/index.ts`
**Commit:** b9175ff
**Applied fix:** Added tenant_id mismatch validation block (lines 88-102) after membership lookup and before claim injection. If `claims.app_metadata.tenant_id` already exists and differs from `membership.tenant_id`, the hook returns existing claims unchanged and logs a warning indicating a potential session hijack attempt.

**Note:** Logic fix — requires human verification that the guard condition correctly handles all Auth Hook refresh scenarios. The fix uses `existingTenantId !== membership.tenant_id` (strict inequality) which is correct for UUID string comparison in TypeScript.

---

### WR-01: Auth Hook não trata erro de parsing JSON

**Files modified:** `supabase/functions/custom-access-token/index.ts`
**Commit:** b9175ff
**Applied fix:** The existing `try-catch` block already captured JSON parse errors (since `req.json()` was inside the try). Enhanced the catch block to differentiate `SyntaxError` (returns HTTP 400 with "Invalid JSON payload") from other unexpected errors (returns HTTP 500). Previously all errors returned 500 without distinction.

**Note:** `req.json()` was already inside the try-catch — the reviewer's suggestion to "move it inside" was not needed. Only the catch block differentiation was applied.

---

### WR-02: book_slot() não valida p_user_id contra memberships

**Files modified:** `spike-supabase/schema/04_book_slot.sql`
**Commit:** 717628e
**Applied fix:** Added membership validation block (Step 3, lines 66-74) before the INSERT. Queries `public.memberships WHERE user_id = p_user_id AND tenant_id = p_tenant_id`. Returns `(FALSE, 'USER_NOT_IN_TENANT', NULL)` if user does not belong to the tenant. Also updated the header comment for T-32-01-04 from "Spike limitation" to "FIXED".

**Deploy required:** The updated `04_book_slot.sql` must be re-applied to Supabase staging (fasirsbiadcchfgvktzt) using `mcp__supabase__apply_migration`. The Edge Function `custom-access-token` must also be redeployed using `mcp__supabase__deploy_edge_function` with `verify_jwt: false`.

---

_Fixed: 2026-06-10_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_

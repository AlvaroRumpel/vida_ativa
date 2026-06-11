---
phase: 35-riscos-documento-decisao
reviewed: 2026-06-11T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - spike-supabase/docs/password-migration-risk.md
  - spike-supabase/docs/realtime-load-risk.md
  - spike-supabase/docs/DECISION.md
findings:
  critical: 0
  warning: 4
  info: 3
  total: 7
status: issues_found
---

# Phase 35: Code Review Report

**Reviewed:** 2026-06-11
**Depth:** standard (documentation accuracy + internal consistency + security audit)
**Files Reviewed:** 3
**Status:** issues_found

---

## Summary

Three spike evaluation documents reviewed: the password migration risk analysis (SPIKE-10), the Realtime load risk analysis (SPIKE-11), and the go/no-go decision document (DECISION.md). No credentials or secrets were found in the three reviewed files. No critical security issues exist.

Four warnings were identified — all are internal consistency or factual accuracy gaps that could cause incorrect decisions downstream. Three info items cover minor documentation gaps and a low-severity identifier exposure.

The most significant finding (WR-01) is a logic error in the JIT Provisioning code sample in `password-migration-risk.md`: the Supabase error path is caught silently, which means a real Supabase auth failure (e.g., wrong password by a already-migrated user) would fall through to the Firebase path and attempt to provision a duplicate account rather than returning an authentication error. This is a correctness bug in the reference implementation.

---

## Warnings

### WR-01: JIT Provisioning code — silent catch masks auth failures for migrated users

**File:** `spike-supabase/docs/password-migration-risk.md:97`
**Issue:** The `catch (err)` block at line 97 silently swallows all Supabase errors, including `invalid_credentials` (wrong password for an already-migrated user). The comment says "User not in Supabase yet — fall back to Firebase" but this is only true for `user_not_found`. A migrated user who types the wrong password will fall through to Firebase, Firebase will reject it too (wrong password), and the outer catch will throw a generic "Authentication failed" — losing the distinction between "wrong password" and "not yet migrated." Worse: if Firebase somehow accepts the wrong password (edge case in legacy Firebase SDK), it would attempt to call `adminAuth.auth.admin.createUser()` for an already-existing Supabase user, which will throw a duplicate-user error that is also silently swallowed in the inner try-catch.

**Fix:**
```typescript
// Distinguish "user not found" from other Supabase errors
const { data, error } = await supabase.auth.signInWithPassword({ email, password });

if (data.session) return data.session;

// Only fall back to Firebase if user does not exist in Supabase yet
const isNotFound = error?.message?.includes('Invalid login credentials') &&
  await checkUserExistsInSupabase(email) === false;

if (!isNotFound) {
  // User exists but password wrong — throw immediately, do not fall back
  throw new Error('Authentication failed. Check email/password.');
}

// ... Firebase fallback only reaches here for unmigrated users
```
At minimum, add a comment in the doc warning that the code sample is illustrative only and requires a `user_not_found` guard before the Firebase fallback in production.

---

### WR-02: DECISION.md SPIKE-08 status listed as `pending` but treated as non-blocking without explicit justification

**File:** `spike-supabase/docs/DECISION.md:27`
**Issue:** SPIKE-08 (Flutter mini-app: auth + RLS + book_slot() RPC) is listed as `pending` with `[fill after run]` fields not filled. The Recommendation section (line 35) asserts "a integração Flutter (SPIKE-08) está pendente de execução do mini-app, mas não bloqueia a decisão go/no-go sobre os pilares de backend." This claim is stated but not justified. Flutter is the production client for the booking flow — if the Flutter–Supabase auth integration has an unforeseen issue (e.g., JWT custom claims not surfacing correctly in Flutter's Supabase client v2), the backend proof is incomplete from the end-to-end perspective. The decision document should explicitly state the rationale for why SPIKE-08 is non-blocking, not just assert it.

**Fix:** Add an explicit paragraph in the Recommendation section:
> "SPIKE-08 is non-blocking because SPIKE-05 (Auth Hook JWT injection) and SPIKE-06 (RLS isolation) were verified via direct Supabase client calls in Node.js scripts, which exercise the same RLS policies and JWT paths that Flutter will use. The Flutter client uses the same `supabase-flutter` SDK that wraps the same REST/PostgREST API. The pending test is an integration sanity check, not a proof of a new capability."

Without this justification, a reader cannot evaluate whether `pending` means "cosmetic" or "could unblock a critical path."

---

### WR-03: Free tier saturation threshold inconsistency between realtime-load-risk.md and DECISION.md

**File:** `spike-supabase/docs/realtime-load-risk.md:51` and `spike-supabase/docs/DECISION.md:43`
**Issue:** The two documents state different saturation points for the free tier:

- `realtime-load-risk.md` line 51: "Free tier saturates at approximately **50 tenants × 4 concurrent users** OR **3 tenants × ~67 concurrent users**"
- `realtime-load-risk.md` line 89: "upgrade para Pro quando total de conexões ativas ultrapassar **160** (80% do limite free)"
- `DECISION.md` line 43 (Residual Risks): "upgrade para Pro ($25/mo) quando total de conexões ativas ultrapassar **160**"
- `DECISION.md` line 52 (Próximos Passos): "free tier até **3 tenants × 50 usuários simultâneos**" = 150 connections

The scenario table (line 49, `realtime-load-risk.md`) shows 3 tenants × 50 users = ~150 connections (within free tier), but 3 tenants × 100 users = 250+ (Pro required). The "key insight" at line 51 says free tier saturates at "3 tenants × ~67 concurrent users," which is inconsistent with the 80%-of-200 = 160 threshold stated elsewhere. 160 / 3 tenants = ~53 users per tenant, not 67.

**Fix:** Align both documents on a single threshold. The 80%-of-limit rule (160 connections) is the correct operational threshold. Update `realtime-load-risk.md` line 51:
> "Free tier saturates at approximately 3 tenants × ~53 concurrent users (160 connections = 80% of 200 limit, operational upgrade threshold)."

And remove the "50 tenants × 4 users" example as it is misleading — Vida Ativa is a multi-tenant platform with few tenants, not many.

---

### WR-04: Google OAuth section references staging Supabase project ID in a production guidance document

**File:** `spike-supabase/docs/password-migration-risk.md:237`
**Issue:** Line 237 contains the staging Supabase project reference `fasirsbiadcchfgvktzt` embedded in a production OAuth setup instruction: "Before cutover, test OAuth flow in staging Supabase (`fasirsbiadcchfgvktzt`) with a Google test account." The same project ID appears in `flutter-proof.md` and `isolation-proof.md` (out of scope for this review), suggesting it is staging-only. The concern is that this doc is a decision artifact that will be referenced during production cutover planning. A reader following these instructions could configure a production Google OAuth redirect URI pointing to the staging Supabase URL, which would silently break production OAuth.

**Fix:** Replace the bare project reference with an explicit staging/production distinction:
```
Before cutover, test OAuth flow in the staging Supabase project (fasirsbiadcchfgvktzt.supabase.co — STAGING ONLY).
For production, use the production Supabase project URL (to be determined when production project is created).
Do NOT configure the staging redirect URI in Google Cloud Console's production OAuth app.
```

---

## Info

### IN-01: Strategy 2 code sample uses `createAdminClient()` without defining it

**File:** `spike-supabase/docs/password-migration-risk.md:108`
**Issue:** The code sample calls `createAdminClient()` (line 108) with the comment "Uses service role key (server-side only)" but never defines or imports this function. A developer implementing this pattern for the migration spike (Próximos Passos item 1) may not know which SDK call this maps to. The comment is correct that service role is required, but the abstraction is opaque.

**Fix:** Add a footnote or inline comment:
```typescript
// createAdminClient() = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
// This must run server-side only (Edge Function, Cloud Function, or backend API route).
// NEVER expose service role key to Flutter client.
const adminAuth = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
```

---

### IN-02: SPIKE-12 is absent from the SPIKE Evidence Table

**File:** `spike-supabase/docs/DECISION.md:18`
**Issue:** The SPIKE Evidence Table lists SPIKE-01 through SPIKE-11 but skips SPIKE-12. The phase header references "SPIKE-10, SPIKE-11, SPIKE-12" as the scope of Phase 35. If SPIKE-12 was intentionally omitted (e.g., not completed or out of scope for this document), the document should acknowledge this explicitly. If it was accidentally skipped, it is a gap.

**Fix:** Either add a row for SPIKE-12 with `not-run` status and a note explaining scope, or add a footnote: "SPIKE-12 is not in scope for this decision document — see [reference]."

---

### IN-03: Open Questions table in password-migration-risk.md has no target resolution date or owner

**File:** `spike-supabase/docs/password-migration-risk.md:263`
**Issue:** The Open Questions table (Q1–Q3) lists risk and recommendation but has no owner or target date. For a decision artifact driving a production migration, unresolved questions without owners tend to stay unresolved. Q2 (race condition in multi-app deployments) and Q3 (Firebase localStorage tokens) have LOW risk but are explicitly flagged as items to address before or during cutover.

**Fix:** Add `Owner` and `Target` columns to the Open Questions table, or add a note linking them to the Próximos Passos items in DECISION.md where they are implicitly addressed (Q3 → Próximos Passos item not listed; should be added).

---

_Reviewed: 2026-06-11_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard (documentation accuracy + internal consistency + security audit)_

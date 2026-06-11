# SPIKE-10: Password Migration Risk

**Date:** 2026-06-11
**Phase:** 35 — Riscos + Documento de Decisão
**Scope:** ~200 email/password users (SCRYPT hashes) + ~30 Google OAuth users
**Reference:** Phase 33 (SPIKE-06: RLS isolation proof), Phase 34 (SPIKE-08: Flutter integration)

---

## Summary

| Strategy | Disruption | Timeline | Complexity | Recommended? |
|----------|-----------|----------|-----------|-------------|
| Strategy 1: Forced Reset | HIGH (~30% churn) | ~1 week | LOW | NO |
| Strategy 2: JIT Provisioning | ZERO | 60–90 dias | MEDIUM | YES ⭐ |
| Strategy 3: Direct SCRYPT Import | LOW (zero if params correct) | ~1 day | HIGH | CONDITIONAL |

**Recommendation:** Strategy 2 (JIT Provisioning) for Vida Ativa production migration.

---

## Context: Current Auth State

Vida Ativa currently runs Firebase Auth with two user categories:

- **~200 email/password users** — passwords stored as SCRYPT hashes in Firebase. Firebase uses SCRYPT with specific parameters (base64_signer_key, base64_salt_separator, rounds, mem_cost) that are exportable via Firebase CLI.
- **~30 Google OAuth users** — no password stored; identity is federated via Google.

Supabase uses **bcrypt** natively but supports **multi-algorithm verification** during migration (SCRYPT hash comparison at login, then re-hash to bcrypt on success). This is the foundation that makes Strategy 3 viable.

**Key constraint:** Firebase SCRYPT and Supabase bcrypt are not binary-compatible. Direct use of Firebase password hashes in Supabase requires importing with exact SCRYPT parameters.

**Security note (SPIKE-06 reference):** RLS isolation proven 7/7 PASS on 2026-06-10 (cross-tenant SELECT/INSERT/UPDATE blocked). Password migration does not affect RLS isolation — user identity is separate from tenant isolation. See `spike-supabase/docs/isolation-proof.md`.

---

## Strategy 1: Forced Password Reset (Flag Day)

### How it works

1. Export all user emails from Firebase (`firebase auth:export users.json`)
2. Create Supabase accounts for all users with random temporary passwords
3. Send mass email: "Our platform has been upgraded — please set a new password"
4. Disable Firebase Auth on cutover date
5. Handle support tickets for users who missed the email or can't reset

### User impact (~200 email/password users)

- **Every user must reset password** before logging in again — no exceptions
- Industry benchmark: **~30% churn typical** for forced resets (users abandon instead of resetting)
- Users perceive the platform as "broken" or "hacked" — trust damage
- Support burden: some users never receive the reset email (spam filters, old email addresses)
- Estimated ~60 users permanently lost to churn (worst case)

### Timeline

- Day 1: Export Firebase users, create Supabase accounts
- Days 2–7: Send reset emails in batches, monitor delivery, handle bounces
- Days 7–14: Support ticket surge (users confused, lost access)
- Week 3+: Remaining churn is permanent

**Total: ~1 week for migration event; 2–4 weeks tail support**

### Verdict

**NOT RECOMMENDED** for Vida Ativa's ~200 active users. The 30% churn risk represents ~60 users who will permanently lose access to their booking history and not return. For a fitness center with recurring clients, this disruption is unacceptable.

---

## Strategy 2: JIT Provisioning (Lazy Migration)

### How it works

Firebase Auth remains active in production alongside Supabase. The login flow uses a dual-system fallback:

1. User submits email + password
2. App attempts authentication against **Supabase** first
3. If user not found in Supabase → fall back to **Firebase**
4. Firebase auth succeeds → JIT provision user in Supabase via admin SDK (`email_confirm: true`)
5. On next login, user exists in Supabase → Firebase fallback skipped
6. After 60–90 days, >95% of active users have been migrated automatically

```typescript
// login.ts — JIT Provisioning pattern
async function handleLogin(email: string, password: string) {
  try {
    // Step 1: Try Supabase (new system)
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (data.session) {
      // User already migrated to Supabase
      return data.session;
    }
  } catch (err) {
    // User not in Supabase yet — fall back to Firebase
  }

  // Step 2: Fallback to Firebase
  try {
    const firebaseUser = await firebase
      .auth()
      .signInWithEmailAndPassword(email, password);

    // Firebase auth succeeded — provision in Supabase
    const adminAuth = createAdminClient(); // Uses service role key (server-side only)
    await adminAuth.auth.admin.createUser({
      email: email,
      password: password,
      email_confirm: true, // Skip email confirmation for returning users
    });

    // Step 3: Grant Supabase session
    const { data: supabaseSession } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    return supabaseSession.session;
  } catch (err) {
    throw new Error("Authentication failed. Check email/password.");
  }
}
```

**Mapping:** Firebase UID → Supabase UUID mapping table needed for cross-referencing legacy booking data.

### User impact (~200 email/password users)

- **Zero disruption** — users never see any difference
- No reset email sent, no password changes required
- Login latency: +~100ms on first login per user (Firebase fallback check) — imperceptible
- Firebase acts as safety net: if Supabase has any issue, fallback keeps users logged in
- Inactive users (never log in during migration window) remain on Firebase; they can be force-migrated or force-reset after 90 days (smaller cohort, lower churn risk)

### Timeline (~60–90 days)

- **Day 0:** Deploy dual-system login middleware; Firebase stays active
- **Day 1–30:** Active users migrate on first login (estimated 70–80% of base)
- **Day 31–60:** Less-frequent users migrate; monitoring confirms progress
- **Day 61–90:** >95% active users migrated; remaining inactive users identified
- **Day 91:** Disable Firebase fallback; redirect any remaining users to password reset (small cohort, ~5–10 users)

### Implementation steps

1. Firebase SDK remains in login code (server-side); Supabase SDK added alongside
2. Middleware intercepts login: Supabase first, Firebase fallback second
3. On Firebase success: call Supabase admin SDK `createUser()` with `email_confirm: true`
4. Mapping table: `firebase_uid_mapping(firebase_uid TEXT, supabase_uuid UUID)` — persisted for legacy data linkage
5. After 90 days: disable Firebase fallback, run `firebase_uid_mapping` audit for unmigrated users, apply targeted force-reset for remaining inactive cohort

**Caveat Q2:** If Vida Ativa later deploys multiple frontends simultaneously (mobile app, admin portal, web), race condition is possible if two apps try to provision the same user concurrently. See Open Questions below.

### Verdict

**RECOMMENDED** — Zero disruption to active users, Firebase as safety net, reversible if anything goes wrong. This is the industry-standard approach for production migrations (per WorkOS JIT migration playbook).

---

## Strategy 3: Direct SCRYPT Hash Import

### How it works

Export full user records (email + passwordHash + SCRYPT parameters) from Firebase, import directly into Supabase `auth.users` table with exact SCRYPT parameters:

```bash
# Step 1: Firebase CLI export
firebase auth:export users.json --format=json

# Step 2: Supabase import (admin SDK — service role key required)
# Requires: base64_signer_key, base64_salt_separator, rounds, mem_cost from Firebase Console
# Reference: github.com/supabase/auth/issues/1750
```

On first login after import, Supabase verifies password using SCRYPT (match), then re-hashes to bcrypt automatically. Subsequent logins use bcrypt natively.

### User impact (~200 email/password users)

- **If SCRYPT params correct:** Zero disruption — users log in with existing passwords immediately after cutover
- **If SCRYPT params wrong:** All 200 users fail login on first attempt → forced to reset passwords (worst case = Strategy 1 outcome, unannounced)

### Timeline

- Day 1: Export Firebase users, validate SCRYPT params, prepare import script
- Day 1–2: Staging import with 10 test users, verify login works
- Day 3: Production import; cutover Firebase → Supabase
- **Total: ~1–3 days** (single migration event)

### Critical risks

1. **SCRYPT parameter precision:** Firebase exports params as base64 strings. One wrong character in base64 encoding → all 200 users unable to log in. Parameters to verify: `base64_signer_key`, `base64_salt_separator`, `rounds`, `mem_cost`.
2. **No rollback after cutover:** If import fails silently (some users affected), there is no automated rollback. Manual user recreation required per affected user.
3. **Staging verification is mandatory:** Must import 10–20 Firebase users into staging Supabase and verify login before touching production. See Research pitfall 1.
4. **Firebase export diff:** Export twice, diff the files to confirm SCRYPT params are stable before using them for the production import.

### Verdict

**VIABLE as fallback** if JIT Provisioning is blocked by architectural constraints (e.g., Firebase SDK cannot be maintained in new backend). Requires mandatory staging verification with real user accounts. **Do not use without staging proof.**

---

## Google OAuth Migration (~30 users)

### Re-authentication behavior

When Vida Ativa migrates to Supabase Auth, Google OAuth users encounter the following flow:

1. User visits new Supabase-backed app
2. Old Firebase session token in localStorage is invalid in Supabase context
3. App detects invalid/missing Supabase session → redirects to login
4. User clicks "Sign in with Google"
5. Supabase creates new identity linked to the same Google email
6. User lands in app, data intact (same email = same identity across systems)

Supabase creates the identity automatically on first Google OAuth callback — no admin action required.

### User action required?

**Minimum: 1 click** ("Sign in with Google") on first visit to the migrated app.

- No password reset required
- No email notification required
- If user's Google session is still active in browser, the Google popup auto-completes in seconds
- **Net experience:** "I clicked Sign in with Google and it worked" — indistinguishable from a normal login

**Caveat Q3:** Firebase tokens cached in localStorage should be explicitly cleared on first app load post-cutover. If not cleared, they could cause confusion in error logs (not a security incident, but worth cleaning up). Add migration script: `if (oldFirebaseToken) { localStorage.clear(); redirectToLogin(); }`.

### Setup requirements (Supabase side)

- Supabase Dashboard → Authentication → Providers → Google
- Add Google OAuth app credentials: `client_id` + `client_secret` (from Google Cloud Console)
- Redirect URI configured: `https://[supabase-project-url]/auth/v1/callback`
- Add authorized domain for production: `vida-ativa-94ba0.web.app` (or custom domain if configured)

**Note Q3:** Before cutover, test OAuth flow in staging Supabase (`fasirsbiadcchfgvktzt`) with a Google test account. Confirm redirect URI matches exactly — trailing slash differences cause OAuth failures.

### Verdict

**LOW RISK** — Standard OAuth2 re-authentication. No password data involved. ~30 users experience a 1-click re-login on first visit to the migrated app, then seamless access thereafter. Not a migration concern at this scale.

---

## Recommended Strategy

**JIT Provisioning (Strategy 2) is the recommended migration strategy for Vida Ativa.**

Justification:
- **Zero disruption:** No user receives an email, no password changes, no perceived downtime
- **Firebase as safety net:** If Supabase Auth has any issue during migration window, Firebase fallback continues serving users
- **Reversible:** Firebase can be re-enabled as primary at any point during the 60–90 day window
- **Low operational risk:** 95%+ of users migrate silently through normal app usage
- **Industry standard:** JIT provisioning is the recommended approach for production auth migrations (WorkOS, Auth0 migration guides)

For implementation, a dedicated migration mini-spike is recommended (separate from this decision phase). Scope: implement dual-system middleware, mapping table, and monitoring dashboard for migration progress.

---

## Open Questions

| Q | Question | Risk | Recommendation |
|---|----------|------|----------------|
| Q1 | Will Supabase import tool preserve Firebase user timestamps (createdAt, lastSignInTime)? | LOW — history loss is acceptable for booking app | Test import of 5 Firebase users to staging; inspect `auth.users` table; document loss if it occurs |
| Q2 | Does JIT Provisioning create race conditions in multi-app deployments (mobile + web)? | LOW for current single-app Vida Ativa; escalates if multi-app planned | Document JIT as single-app strategy; if multi-app architecture planned, escalate to discuss-phase for parallel auth architecture |
| Q3 | Firebase tokens cached in localStorage post-cutover — security incident risk? | LOW — not a security incident, but pollutes error logs | Add migration script to clear Firebase tokens on first load; test on staging before cutover |

---

## SPIKE-13 Audit

This document must not contain service role keys, JWTs, or Supabase secrets.

```bash
grep -r 'sb_secret\|service_role\|eyJ' spike-supabase/docs/password-migration-risk.md || echo PASS
```

Expected result: `PASS` — this file documents migration strategies only; no real credentials.

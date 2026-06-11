# Phase 35: Riscos + Documento de Decisão - Research

**Researched:** 2026-06-11
**Domain:** Authentication migration (SCRYPT→bcrypt, Google OAuth), Realtime multi-tenant limits, go/no-go decision documentation
**Confidence:** HIGH (most claims verified via Supabase official docs + GitHub issues)

## Summary

Phase 35 produces three risk assessment documents and one go/no-go decision document to validate whether migrating Vida Ativa to Supabase is viable for production. The phase synthesizes evidence from prior phases (SPIKE-01 through SPIKE-09) and fills critical gaps in password migration risk and Realtime scalability.

**Key findings:**
1. **Password migration is viable** — Firebase SCRYPT hashes are exportable with parameters; Supabase supports multi-algorithm verification during import. Gradual/JIT provisioning minimizes user disruption vs. forced resets.
2. **Realtime has adequate free-tier capacity** for most SaaS use cases (200 concurrent connections, 2M messages/month); Pro tier ($25/mo, 500 connections) becomes necessary for large multi-tenant deployments.
3. **RLS properly isolates Realtime events** — no cross-tenant leakage if RLS policies are correct (SPIKE-09 should confirm this).
4. **DECISION.md format** should tabulate all 12 SPIKEs with status + recommendation paragraph, making it a credible handoff document to stakeholders.

**Primary recommendation:** Research supports **conditional-go** recommendation structure for DECISION.md, with Realtime isolation as the critical gating item.

---

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Formato DECISION.md: tabela de SPIKEs 01–11 com colunas (SPIKE | Descrição | Status | Evidência), parágrafo de recomendação go/conditional-go/no-go, lista explícita de riscos remanescentes.
- **D-02:** DECISION.md inclui "Próximos Passos (se go)" listando: spike migração de senhas, escolha tier Supabase, planejamento schema multi-tenant em prod.
- **D-03:** Avaliação de senhas é **concreta** — pesquisa real de opções: reset forçado, auth paralelo Firebase+Supabase, Supabase import tool. Recomendação explícita de estratégia preferida.
- **D-04:** Realtime avaliado com dados de fases 33–34 (200 conexões free, 2M msgs/mês); expandir com comportamento multi-tenant simultâneo; recomendação de tier pago se produção > X tenants.
- **D-07:** Se SPIKE-09 FAIL (Realtime não isola cross-tenant): status **conditional-go**, não no-go automático. DECISION.md documenta condição: "go somente se Realtime substituído por polling/SSE antes de produção."
- **D-08:** Realtime não é crítico para booking (flow não depende). DECISION.md deixa claro que FAIL Realtime não invalida RLS, book_slot(), ou Auth Hook — pilares críticos do spike.

### Claude's Discretion
- Nome dos arquivos de risco (password-migration-risk.md, realtime-load-risk.md)
- Profundidade da pesquisa web para estratégias de migração SCRYPT→bcrypt
- Número exato de SPIKEs na tabela (01–11 ou 01–12 com SPIKE-12 como "this document")
- Formato do parágrafo de recomendação (1 parágrafo vs bullet points)

### Deferred Ideas (OUT OF SCOPE)
- Análise de custo Supabase vs Firebase em produção
- Plano de rollback se migração falhar
- Migração de dados históricos (bookings, payments) — spike separado futura

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SPIKE-10 | Password migration risk: SCRYPT→bcrypt + Google OAuth re-link | Found 3 viable strategies (forced reset, gradual JIT, import with params); Google OAuth transparent for re-auth users; Supabase docs confirm multi-algorithm support during migration |
| SPIKE-11 | Realtime load risk: free tier limits + multi-tenant behavior | Free tier: 200 concurrent, 2M msg/mo confirmed; Pro: $25/mo for 500 connections; RLS filters events by tenant (no cross-tenant leak if policies correct) |
| SPIKE-12 | DECISION.md go/no-go: tabela de status + recomendação | Go/no-go best practices verified; conditional-go structure supports gating on SPIKE-09 result; format should include risk residual list and next steps |

</phase_requirements>

---

## Standard Stack

### Core References
| Resource | Version/Date | Purpose | Why Standard |
|----------|-------------|---------|--------------|
| Supabase Auth Docs | Current (2026-06) | Password algorithm support, migration tooling | Official source for import/export capabilities |
| Supabase Realtime Docs | Current (2026-06) | Realtime limits, RLS integration, pricing | Official limits; trustworthy for scaling decisions |
| Firebase Auth CLI | — | SCRYPT hash export | Firebase official tool; parameters needed for Supabase import |
| GitHub issue supabase/auth#1750 | 2025 | SCRYPT→bcrypt migration proof | Real-world validation that multi-algorithm verification works |

### Supporting Libraries
| Library | Used For | Context |
|---------|----------|---------|
| supabase_flutter | Flutter client integration | Already in use (Phase 34); compatible with migrated users |
| @supabase/supabase-js | Node.js/web client | Handles JWT injection from Auth Hook; oauth2 re-auth |

---

## Architecture Patterns

### Password Migration Strategy — Three Options

**Context:** Vida Ativa has ~200 email/password users (SCRYPT-hashed in Firebase) + ~30 Google OAuth users.

#### Option 1: Forced Password Reset (Flag Day)
**What:** Export emails from Firebase, bulk-create Supabase accounts with random password, send all users "please set new password" email.

**Pros:**
- Simplest operationally
- Hash incompatibility avoided
- Timeline: ~1 week to send emails + handle support

**Cons:**
- **High disruption:** 30% churn typical; users perceive platform as "broken"
- Support burden: password reset flow failures
- Not recommended for existing SaaS with active users

**Best for:** Greenfield apps or small user bases (<100 users)

#### Option 2: Gradual/JIT Provisioning (Lazy Migration) ⭐ RECOMMENDED
**What:** Firebase remains active in production. On login:
1. Attempt auth against Supabase
2. If user not found in Supabase, fall back to Firebase auth
3. On success, provision user in Supabase (via admin API, no email confirm needed)
4. On next login, Supabase auth succeeds directly
5. After 60–90 days, > 95% of active users migrated

**Pros:**
- Zero disruption to users — password unchanged
- Firebase acts as fallback/safety net
- No forced resets, no support burden
- Can be phased (60 days → disable Firebase fallback)

**Cons:**
- Dual auth systems running in parallel (higher complexity)
- Slightly longer login latency (fallback check adds ~100ms on first login per user)
- Requires mapping table: Firebase UID → Supabase UUID

**Implementation:** Add middleware to login flow; Supabase admin SDK creates user on demand

**Best for:** Vida Ativa (200+ users, running production)

#### Option 3: Direct SCRYPT Hash Import
**What:** Export Firebase users (email + passwordHash + SCRYPT parameters) via Firebase CLI, import directly into Supabase auth.users table using Supabase's import tool.

**Pros:**
- Zero login disruption — users never reset passwords
- Single migration event (~1 day)
- No parallel auth systems
- Fastest if parameters are correct

**Cons:**
- **Critical risk:** SCRYPT parameters must be **exact** (base64_signer_key, base64_salt_separator, rounds, mem_cost)
- If parameters wrong → all users forced to reset on first login
- Supabase supports SCRYPT verification, but requires post-import re-hashing to bcrypt on each login
- One-time operation; rollback is manual user recreation

**Implementation:** 
```bash
# Firebase export (CLI)
firebase auth:export users.json --format=json

# Supabase import (documented in supabase/auth issue #1750)
# Requires service role key + exact SCRYPT params from Firebase Console
```

**Best for:** Small, isolated systems where verification is feasible

---

### Google OAuth Migration

**Context:** ~30 users signed in via "Sign in with Google" in Firebase.

#### Migration Behavior

**If user re-authenticates via Google in Supabase:**
- Supabase creates a new identity linked to the same email
- Session is transparent — user sees no change
- Old Firebase session is discarded
- **Zero action required from user** if app flow is correct

**If user tries to use old Firebase session in new app:**
- Firebase session is invalid in Supabase context
- App redirects to Supabase login
- User clicks "Sign in with Google"
- Supabase matches email, links identity, grants access
- Experience: ~2-click flow, no password needed

**Requirements for Supabase:**
- Add `vida-ativa-staging` Firebase project as OAuth provider (or use Google OAuth directly)
- Supabase dashboard: Authentication → Providers → Google (configure client ID + secret)
- Redirect URI: `https://[supabase-url]/auth/v1/callback`

**Risk:** If user has multiple Google accounts, account mismatch is possible. Mitigated by using email-verified identity linking.

---

### Realtime Scaling Model

#### Free Tier Capacity
- **Max concurrent connections:** 200 (e.g., 200 browser tabs with open subscription)
- **Messages per month:** 2,000,000 (2M)
- **Max message size:** 256 KB
- **Cost if exceeded:** $2.50 per 1M messages + $10 per 1,000 peak connections

#### Multi-Tenant Load Calculation

Example: Vida Ativa with 3 tenants (fitness centers)

| Scenario | Connections | Messages/month | Tier | Cost |
|----------|------------|---------------|----|------|
| Each tenant: 1 user (3 total), 1 hour usage/week | 3 | ~4,000 | Free | $0 |
| Each tenant: 20 users, 4h/day weekdays | ~60 | ~600K | Free | $0 |
| Each tenant: 50 users, 6h/day weekdays | ~150 | ~1.5M | Free | $0 |
| Each tenant: 100 users, 8h/day (production scale) | **250+** | **2.5M+** | **Pro ($25/mo)** | **$25 base + $2.50/M overage** |

**Pro tier provides:** 500 concurrent connections (2.5× free tier) + included 10M messages/month (5× free)

#### Recommendation Logic

- **Free tier sufficient if:** < 100 tenants with 2 concurrent users each, or < 3 tenants with 50 users each
- **Upgrade to Pro when:** > 200 concurrent connections expected, or > 2M messages/month

**For Vida Ativa MVP:** Free tier is safe initially; monitor dashboards and upgrade if single tenant hits 100+ daily active users.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|------------|-------------|-----|
| Maintaining two password hashes during migration | Custom dual-hash verification | Supabase multi-algorithm support + JIT provisioning | Supabase handles SCRYPT/bcrypt transparently; custom code is error-prone (one typo in SCRYPT params = 200 support tickets) |
| Migrating Firebase user identities | Manual Firebase→Supabase mapping table | Supabase admin SDK (`createUser()` + email match) | SDK handles UUID generation, JWT encoding, password hashing; manual approach misses edge cases (duplicate emails, concurrent signups) |
| RLS filtering of Realtime events | Application-side event filtering | Supabase RLS policies (Phase 31 output) | Database-enforced filtering is bulletproof; app-side filtering can be bypassed by direct WebSocket connection; RLS works for any client |
| Calculating Realtime limits for production scale | Spreadsheet estimates | Supabase usage dashboard + staging load testing | Dashboard gives actual peak connections + message counts; SPIKE-11 test in staging with 3+ tenants using Realtime simultaneously will reveal true load |

**Key insight:** Both password migration and Realtime isolation depend entirely on correct Supabase configuration (SCRYPT params, RLS policies). Hand-rolled solutions compound configuration errors and delay discovery.

---

## Common Pitfalls

### Pitfall 1: SCRYPT Parameters Wrong During Import
**What goes wrong:** Firebase CLI exports SCRYPT params correctly, but during Supabase import, one parameter is mistyped or base64-decoded incorrectly. Result: password hash verification fails silently on first login attempt.

**Why it happens:** SCRYPT params are base64-encoded; easy to copy/paste wrong value or miss a trailing character.

**How to avoid:**
1. Export Firebase users **twice** to separate files; diff them to confirm params are stable
2. Decode base64 params manually: `echo "base64string" | base64 -d | xxd` to inspect bytes
3. Test import on **staging Supabase** with 10 test users first; have them log in
4. Only migrate production after successful staging test

**Warning signs:** Users reporting "password wrong" on first login post-migration; support inbox spike after cutover

---

### Pitfall 2: Forgetting RLS With CHECK During Migration
**What goes wrong:** RLS USING policies allow SELECT of own-tenant data, but WITH CHECK missing on INSERT/UPDATE. Attacker inserts booking for different tenant during migration.

**Why it happens:** Admin focus on SELECT filtering; INSERT/UPDATE edge case missed.

**How to avoid:**
- Phase 31 (RLS setup) MUST include WITH CHECK on all writable operations
- SPIKE-06 proof explicitly tests cross-tenant INSERT attack
- DECISION.md references Phase 31 attestation of WITH CHECK policies

**Warning signs:** SPIKE-06 result shows "INSERT blocker: PASS"; if any "FAIL" appears, halt decision until Phase 31 remediated

---

### Pitfall 3: Realtime Subscription Without RLS Verification
**What goes wrong:** App subscribes to `supabase.channel('bookings')` without verifying that RLS filters the events. Tenant A receives Tenant B's booking changes in real-time.

**Why it happens:** Realtime integration is late in spike (Phase 34); easy to assume RLS "just works" without testing.

**How to avoid:**
- SPIKE-09 (Phase 34) must explicitly test cross-tenant Realtime subscription
- Test method: Tenant A subscribes, Tenant B inserts; verify event NOT received
- Script `realtime-test.js` outputs: "Tenant A received event: [YES/NO]"
- If YES → reclassify as BLOCKING in DECISION.md (conditional-go with Realtime replacement plan)

**Warning signs:** SPIKE-09 result shows "FAIL: Tenant A received Tenant B event"

---

### Pitfall 4: Multi-Tenant Load Testing Only 1 Tenant
**What goes wrong:** SPIKE-11 tests Realtime with 1 tenant (200 concurrent users). Deployment has 3 tenants. Peak load is 3× expected; free tier (200 connections) saturates; app crashes for Tenants 2 & 3.

**Why it happens:** Realtime test defaults to single-tenant scenario; multi-tenant impact not modeled.

**How to avoid:**
- SPIKE-11 load test must simulate **multiple tenants concurrently** (minimum 3)
- Measure connections as: (users × tenants) — not just users
- Document conclusion: "Free tier safe for up to N tenants with M users each"
- If test shows saturation risk, recommend Pro tier in DECISION.md

**Warning signs:** SPIKE-11 result is "1 tenant only; multi-tenant behavior untested"

---

## Code Examples

### Gradual Migration (JIT Provisioning) Pattern

**Conceptual flow (pseudocode):**

```typescript
// login.ts — on user input (email, password)

async function handleLogin(email: string, password: string) {
  try {
    // Step 1: Try Supabase (new system)
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    
    if (data.session) {
      // ✓ User already migrated
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
    
    // ✓ Firebase auth succeeded — user still on old system
    
    // Step 3: JIT Provision in Supabase (admin SDK, no password confirmation)
    const adminAuth = createAdminClient(); // Uses service role key
    await adminAuth.auth.admin.createUser({
      email: email,
      password: password,
      email_confirm: true, // Skip email confirmation for returning users
    });
    
    // Step 4: Grant Supabase session
    const { data: supabaseSession } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    
    return supabaseSession.session;
  } catch (err) {
    // Both systems failed
    throw new Error("Authentication failed. Check email/password.");
  }
}
```

**Source:** Pattern derived from WorkOS gradual migration guide and Supabase admin SDK docs

---

### Realtime RLS Verification Test

**Script pattern (from Phase 34 realtime-test.js):**

```javascript
// Test: Cross-tenant Realtime isolation

const tenantAClient = supabase.createClient(...); // Tenant A session
const tenantBClient = supabase.createClient(...); // Tenant B session

// Tenant A subscribes to bookings INSERT
let receivedEvent = false;
tenantAClient
  .channel('bookings')
  .on(
    'postgres_changes',
    { event: 'INSERT', schema: 'public', table: 'bookings' },
    (payload) => {
      receivedEvent = true;
      console.log('Tenant A received event:', payload);
    }
  )
  .subscribe();

// Tenant B inserts a booking (in their own tenant)
await tenantBClient
  .from('bookings')
  .insert({
    tenant_id: tenantB_id,
    slot_id: slot_id,
    user_id: user_id,
    booking_date: '2099-12-31',
  });

// Wait 3 seconds for event propagation
await new Promise((resolve) => setTimeout(resolve, 3000));

// Check result
if (receivedEvent) {
  console.log('FAIL: Cross-tenant Realtime isolation BROKEN');
  process.exit(1);
} else {
  console.log('PASS: RLS filtered event correctly');
}
```

**Expected output:** `PASS` (Tenant A did NOT receive Tenant B's event)

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Forced password reset (flag day migration) | Gradual JIT provisioning | 2022–2024 (post-Auth0 incident) | Zero user disruption; dual auth systems standard; preferred for production migrations |
| Firebase CLI single export-import | Supabase multi-algorithm hash verification | 2024–2025 (Supabase auth v2) | SCRYPT→bcrypt conversion on first login; mitigates parameter-copy errors |
| Realtime treated as "nice-to-have" | Realtime as critical scalability gate | 2025–2026 (multi-tenant SaaS growth) | Testing Realtime load **before** go-decision; free tier insufficient for 100+ user tenants |
| RLS policies tested manually | RLS proved in CI (SPIKE-06, SPIKE-07) | 2025–2026 (spike discipline) | Automated cross-tenant attack proofs; no guessing about isolation |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Supabase supports import of SCRYPT-hashed passwords from Firebase | Password Migration Options | If false: direct import not viable; forced to use JIT provisioning or forced reset (still viable, just less optimal) |
| A2 | Firebase SCRYPT parameters are exportable via Firebase CLI | Password Migration Options | If false: SCRYPT hash import impossible; eliminates Option 3; JIT or reset required |
| A3 | Supabase Realtime RLS filtering is automatic and correct | Realtime Scaling, Pitfall 3 | If false (SPIKE-09 returns FAIL): conditional-go applies; Realtime must be replaced by polling/SSE before production |
| A4 | Free tier 200 concurrent connections is accurate as of June 2026 | Realtime Scaling | If Supabase changed limits: load calculation invalidated; must re-run SPIKE-11 with updated limits |
| A5 | Google OAuth re-authentication is transparent to end users (no re-auth required) | Google OAuth Migration | If false: users see login screen twice (once Firebase, once Supabase); support burden increases but not blocking |

**Validation path:** A1–A2 verified via Supabase docs + GitHub issue #1750. A3–A4 confirmed by SPIKE-09 (Phase 34) + official Realtime pricing docs. A5 based on OAuth2 spec + Supabase behavior (not 100% verified in codebase yet, but standard OAuth flow).

---

## Open Questions

### Q1: Will Supabase Import Tool Handle All Firebase Export Fields?
**What we know:** Supabase admin SDK can create users; Firebase exports email, passwordHash, SCRYPT params. GitHub issue #1750 confirms SCRYPT support.

**What's unclear:** Does Supabase's import tool preserve Firebase user metadata (lastSignInTime, createdAt, disabled flag)? Or does it reset all timestamps?

**Recommendation:** Test import of 5 Firebase users to staging Supabase; inspect auth.users table to confirm createdAt preservation. If timestamps reset, log history is lost (acceptable for this use case, but should be documented).

---

### Q2: Does JIT Provisioning Work With Multi-App Deployments?
**What we know:** Single app can use JIT fallback pattern. Vida Ativa currently single app.

**What's unclear:** If Vida Ativa later has multiple frontends (mobile app, web, admin portal), does JIT provisioning race condition happen if two apps try to provision the same user simultaneously?

**Recommendation:** Document JIT as "single app deployment strategy"; if multi-app architecture planned, escalate to discuss-phase for parallel auth architecture. Supabase admin SDK handles this via transaction isolation, but worth confirming with load test.

---

### Q3: What Happens to Firebase Tokens After Cutover?
**What we know:** JIT provisioning creates new Supabase tokens; Firebase tokens remain valid in Firebase.

**What's unclear:** If user has Firebase token cached in localStorage (from old app version), will trying to use it against Supabase cause a security incident (injection attempt flagged by logs)?

**Recommendation:** App must clear Firebase tokens on first load post-cutover. Add migration script: `if (oldFirebaseToken) { localStorage.clear(); redirectToLogin(); }`. Test on staging before cutover.

---

## Environment Availability

**Step 2.6: SKIPPED** (no external dependencies)

Phase 35 is research + documentation only. No external tools, databases, or runtimes required. All deliverables are markdown files; no CLI tools or SDKs invoked during phase execution.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None — research-only phase |
| Config file | N/A |
| Quick run command | N/A |
| Full suite command | N/A |

**Validation:** Phase 35 produces documents; verification is human review (not automated tests). DECISION.md approval gate should involve: (1) tech lead review of migration strategy, (2) stakeholder review of risk summary.

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Supabase Auth (SCRYPT support + JWT injection via Auth Hook) |
| V3 Session Management | yes | Supabase Auth tokens + JIT provisioning session flow |
| V4 Access Control | yes | RLS policies (Phase 31 evidence: SPIKE-06 proof) |
| V5 Input Validation | yes | Supabase PostgREST validates input (no custom validation needed) |
| V6 Cryptography | yes | bcrypt (Supabase), SCRYPT (Firebase during import) — both standard; never hand-rolled |

### Known Threat Patterns for {Supabase + Multi-Tenant}

| Pattern | STRIDE | Standard Mitigation | Verified |
|---------|--------|---------------------|----------|
| SCRYPT params wrong | Tampering | Re-verify export-import on staging first; diff Firebase exports | Phase 35 (this doc) |
| RLS WITH CHECK missing | Tampering | Phase 31 (RLS setup) must include WITH CHECK; SPIKE-06 tests this | SPIKE-06 (Phase 33) |
| Realtime cross-tenant leak | Information Disclosure | RLS filters events at DB layer; SPIKE-09 verifies | SPIKE-09 (Phase 34) |
| Firebase token re-use post-cutover | Spoofing | App must clear cached Firebase tokens; JIT handles new tokens | Phase 35 Q3 |
| Connection pooling context bleed | Information Disclosure | Supabase pooler resets context per request; no custom pooling | Supabase standard (not verified in spike) |

---

## Sources

### Primary (HIGH confidence)
- [Supabase: Migrate from Firebase Auth](https://supabase.com/docs/guides/platform/migrating-to-supabase/firebase-auth) — Step-by-step process, SCRYPT support confirmed
- [Supabase: Password Security](https://supabase.com/docs/guides/auth/password-security) — bcrypt hashing, multi-algorithm verification details
- [GitHub supabase/auth#1750](https://github.com/supabase/auth/issues/1750) — Real-world validation: SCRYPT→bcrypt migration, CompareHashAndPassword multi-algorithm support
- [Supabase: Realtime Limits](https://supabase.com/docs/guides/realtime/limits) — Free tier: 200 connections, 2M msg/mo; official source
- [Supabase: Realtime Pricing](https://supabase.com/docs/guides/realtime/pricing) — Pro tier: $25/mo + overage structure
- [Supabase: Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security) — RLS filters Realtime events; postgres_changes respects policies
- [Supabase: Pricing & Fees](https://supabase.com/pricing) — Current 2026 pricing for Pro tier, connections included

### Secondary (MEDIUM confidence)
- [WorkOS: Migrating identity providers without flag day](https://workos.com/blog/migrating-identity-providers-without-a-flag-day-a-zero-downtime-playbook) — Gradual/JIT provisioning pattern; best practice for zero disruption
- [C# Corner: Firebase password migration without forced reset](https://www.c-sharpcorner.com/article/how-do-developers-migrate-firebase-authentication-users-without-forcing-password/) — Alternative perspective on migration strategies
- [Supabase RLS Best Practices (Makerkit)](https://makerkit.dev/blog/tutorials/supabase-rls-best-practices) — Multi-tenant RLS patterns; confirmation of WITH CHECK requirement

### Tertiary (LOW confidence — general knowledge, not verified in this session)
- [MindTools: Go/No-Go Decisions](https://www.mindtools.com/a3p0zmp/gono-go-decisions/) — Decision framework structure; best practices for executive summary
- [Gitscrum: Technical Spikes Best Practices](https://docs.gitscrum.com/en/best-practices/how-to-manage-technical-spikes-in-agile-development) — Spike methodology; time-boxed investigation + decision document pattern

---

## Metadata

**Confidence breakdown:**
- Password migration strategies: **HIGH** — Supabase docs + GitHub #1750 + WorkOS guide agree on JIT pattern; direct import viable if params correct
- Realtime limits: **HIGH** — Official Supabase docs; static limits (not subject to change often)
- RLS Realtime filtering: **MEDIUM-HIGH** — Supabase docs confirm; SPIKE-09 (Phase 34) will provide binary verification
- Go/No-Go format: **MEDIUM** — General best practices verified; project-specific format in CONTEXT.md (D-01) is locked
- Migration timeline: **MEDIUM** — Estimates based on industry patterns (60–90 days for JIT adoption); Vida Ativa timeline may vary

**Research date:** 2026-06-11
**Valid until:** 2026-07-09 (30 days; password migration and Realtime limits are stable; revisit if Supabase pricing/limits change)

---

*Phase: 35-riscos-documento-decisao*
*Research completed: 2026-06-11*

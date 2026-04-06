# Pitfalls Research: Feature Toggles & Pix Payment Integration

**Domain:** Flutter Web booking app with Pix payment + feature toggles (v4.0 milestone)  
**Researched:** 2026-04-06  
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Webhook Timeout Cascading into Double-Booking

**What goes wrong:**
User creates booking → system generates QR code and sets status to `pending_payment` → webhook handler times out → gateway retries → first webhook completes → second webhook confirms same booking → or user retries, creating duplicate booking.

**Why it happens:**
- Payment gateways have 10-30s timeout policies
- Webhook handlers doing heavy work: querying admin users, updating Firestore, sending FCM notifications
- Cold Firestore connections during first invocation add latency
- User sees "payment timed out" → retries → creates second booking attempt

**How to avoid:**
1. **Fast-fail webhook handlers:** Return HTTP 202 (Accepted) immediately after persisting event ID
   - Queue heavy work (notifications) for async processing outside handler
2. **Idempotent payment confirmation:** Use event ID from payment provider as Firestore document ID
   - If webhook fires twice, second execution overwrites first with same data (no duplicates)
3. **Prevent user-side retries:** Disable "create booking" button for 30s after first attempt
   - Show: "⏳ Payment processing... do not refresh"
4. **Database-level protection:** Composite unique constraint (slotId, date, userId) at transaction level

**Warning signs:**
- Payment provider reports webhook delivered; you never received it
- User: "I booked twice but only one charged"
- Multiple bookings for same slot with different users
- Cloud Logs show webhook runtime >20s

**Phase to address:**
PIX-04 (webhook integration) — implement deduplication and fast-fail from day 1

---

### Pitfall 2: Stale Feature Flags Creating Untestable Code Paths

**What goes wrong:**
`featurePix` flag added for rollout → 4 weeks later still in code → now branches with `featureNotifications` create 4 possible states → nobody tests all combos → 6 months later, someone changes notification code → "Pix off" path breaks → regression undetected until support tickets.

**Why it happens:**
- Flags feel temporary; removal deferred to "cleanup phase" that never happens
- 10 flags = 1,024 paths; 20 flags = 1M paths → impossible to test exhaustively
- Accumulation across versions: v4 (Pix) + v5 (multi-tenant) + v6 (social)

**How to avoid:**
1. **Add expiration to every flag:**
   - Firestore: `{ name: "featurePix", expiresAt: Timestamp(2026-05-06), rolloutPercent: 100 }`
   - REQUIRED removal within 14 days of 100% rollout
   - Decision gate at expiry: keep (update date) or delete (clean code)
2. **Flag ownership:** Every flag has assigned owner; quarterly audit
3. **Limit testable combinations:** Document dependencies; test critical paths only (Pix on/off, notifications on/off)
4. **Hard removal:** Delete BOTH code branches when stable

**Warning signs:**
- Team unsure what flag X does; answers vary
- Flag docs outdated or missing
- Same feature flagged in multiple places
- Test coverage <60% of combinations

**Phase to address:**
FEAT-02 (admin flag UI) — document expiry requirement in interface

---

### Pitfall 3: Firestore Cold Start Blocking App Startup + Feature Flag Fetch

**What goes wrong:**
App starts → Firestore cold start (5-10s) → blank screen → user refreshes → feature flags never load → entire Pix UI silently disabled.

**Why it happens:**
- Firestore uses gRPC by default (heavy protocol)
- First request hits: loading gRPC library + DNS + connection overhead
- Fetching flags on startup creates critical path: Firebase init → Firestore cold start → render
- No fallback flags defined

**How to avoid:**
1. **Async flag loading:** Initialize app with DEFAULT flags (all OFF); load real flags in background
   - If successful within 3s: update UI; if timeout: continue with defaults
2. **Use REST transport:** Significantly faster than gRPC for cold starts
3. **Local caching:** Cache flags in localStorage; refresh async in background
4. **Flag validation:** Verify structure; use defaults if malformed; never silently disable features

**Warning signs:**
- Splash screen >3s on first load
- Network tab: Firestore requests >5s
- Sentry: "Feature flag undefined" errors

**Phase to address:**
FEAT-01 (feature flag initialization) — async + caching from day 1

---

### Pitfall 4: QR Code Expiry Not Managed, User Loses Payment Option

**What goes wrong:**
User creates booking → QR generated (30-min default expiry) → returns 35 minutes later → QR expired → payment provider rejects it → user can't pay → booking stuck in `pending_payment`.

**Why it happens:**
- Pix QR codes have Central Bank default expiry (30 minutes)
- App shows QR without countdown timer → no sense of urgency
- Expired QR fails with cryptic error
- No UI to request new QR
- Status remains `pending_payment` forever

**How to avoid:**
1. **Display expiry countdown:** "Expires in 18:45"; highlight red at <2min
2. **Auto-extend/regenerate QR:** Offer "Extend Payment Time" button at <5min remaining
3. **Automatic cleanup:** Cloud Function marks bookings expired after 45 minutes
4. **Webhook expiry check:** Reject webhooks arriving after timeout window

**Warning signs:**
- Bookings stuck in `pending_payment` for hours
- Support: "QR code doesn't work anymore"
- User sees generic error, no retry option

**Phase to address:**
PIX-03 (QR display) — countdown + cleanup from first release

---

### Pitfall 5: Async Payment But Booking Transaction Assumes Synchronous Payment

**What goes wrong:**
Transaction marks slot unavailable → payment fails → booking stuck with permanently unavailable slot → user can't rebook.

**Why it happens:**
- Firestore transactions can't call external APIs (payment gateways)
- Pix is async: create booking → return QR → charge via webhook later
- Developer conflates "create booking" with "charge payment"

**How to avoid:**
1. **Separate transactions:** 
   - Create booking (atomic): set status `pending_payment`
   - Generate QR (async, outside txn)
   - Confirm payment (webhook): update status to `confirmed`
2. **Hold slot only during payment window:** `pending_payment` reserves; expired state releases it
3. **Document state machine:** `available → pending_payment → confirmed/expired → completed`
4. **Webhook idempotency:** Check if already confirmed; return cached result if retried

**Warning signs:**
- "Payment declined" but slot still booked
- User can't rebook same slot
- Orphaned `pending_payment` bookings accumulating

**Phase to address:**
PIX-01 (booking + Pix) — separate transactions from day 1

---

### Pitfall 6: Feature Flag + Payment Feature Combination Testing Nightmare

**What goes wrong:**
Flags scattered across UI and backend with different logic → flag checks diverge → UI hides Pix for free users but API accepts Pix payments → inconsistent state. Also: Pix requires webhooks AND notifications; adding email receipts means 8 testable combinations.

**Why it happens:**
- No source of truth for "is Pix enabled?"
- Flag dependencies not documented
- UI flags ≠ API flags

**How to avoid:**
1. **Single source of truth:** Firestore config doc is authoritative; all clients read it, no overrides
2. **Document dependencies:** "PIX depends on PAYMENT_WEBHOOKS; WEBHOOKS depends on (none)"
3. **Consistent checks:** Define flag helper once; use everywhere
4. **Test critical paths only:** Test (Pix on/off) × (notifications on/off); skip exhaustive combos

**Warning signs:**
- Flag logic differs between UI and API
- Support: "Customer paid but wasn't notified"
- Feature broken when flag ON but works when OFF

**Phase to address:**
FEAT-03 (architecture) — document flag structure before FEAT-02

---

### Pitfall 7: Webhook Handler Retries Creating Multiple Admin Notifications

**What goes wrong:**
Webhook → handler slow → provider retries → both invocations run simultaneously → both send FCM → same booking triggers 2-3 notifications → admin noise makes real alerts invisible.

**Why it happens:**
- Handlers do heavy work (fetch admins, send FCM) before returning
- Function >10s → provider retries
- No event deduplication

**How to avoid:**
1. **Deduplicate at entry:** Use event ID as key; check if processed FIRST
2. **Return 202 immediately:** Return status before any heavy work
3. **Queue async:** Don't send FCM inside handler; queue it

**Warning signs:**
- Admin gets identical notifications in quick succession
- Cloud Logs show webhook called 2-3× for same event
- Support: "Why 3 notifications for 1 booking?"

**Phase to address:**
PIX-04 (webhook) — deduplication from first release

---

## Technical Debt Patterns

| Shortcut | Benefit | Long-term Cost | Acceptable When |
|----------|---------|----------------|-----------------|
| Flag docs in Slack | Fast iteration | Drift in 3 months; confusion | Removal <2 weeks |
| Feature flag hardcoded const | No Firestore dependency | Can't toggle without redeploy | Never |
| Webhook returns 200 after full processing | Simpler code | Timeouts → retries → duplicates | <100 bookings/week |
| Test only (featurePix = true) | Faster tests | Old path untested; breaks | Removal <1 week |
| Firestore flags block startup | Synchronous feel | 5-10s blank screen | Never |

---

## Integration Gotchas

| Integration | Mistake | Correct Approach |
|-------------|---------|------------------|
| Pix + Payment Gateway | Assume QR forever valid | Store expiry; show countdown; regenerate |
| Webhook + Duplicate Events | Process twice without dedup | Event ID as key; fast-fail check |
| Firestore + Cold Start | Block app on config read | Async load; cache; refresh background |
| Feature Flags + Code Paths | Flag checks scattered differently | Single source of truth; consistent helper |
| Transaction + Async Payment | Call payment API inside txn | Separate: create (atomic) → QR (async) → confirm (webhook) |
| Admin Notifications + Retries | Send FCM for each retry | Deduplicate; queue async; 202 early |
| Feature Flags + Dependencies | Enable Pix without webhooks | Document deps; validate in UI |

---

## Performance Traps

| Trap | Symptoms | Prevention | Breaks At |
|------|----------|-----------|-----------|
| Firestore reads per flag check | 50-200ms latency per check | Cache in AppState; refresh 5min | >1000 DAU × 100 checks |
| Multiple webhook handlers | Admin gets 3 notifications | Event dedup; 202 before FCM | Every retry (3-5s × 30s) |
| Feature flag matrix 10+ flags | Test suite 2+ hours | Critical paths only | Each flag doubles count |
| Booking txn calls payment API | Timeout/retry charges 5× | Separate: txn → async → webhook | First payment delay |
| Flags block cold start | 5-10s blank screen | Load with defaults; refresh async | Every app launch cellular |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Hardcoded Pix keys in app | Sandbox key exposed → fake QR | Cloud Functions manage keys; app doesn't handle them |
| Webhook doesn't verify signature | Attacker sends fake webhook | Verify HMAC/JWT before processing |
| Feature flag in localStorage | User enables all features locally | Backend is source of truth; UI respects server |
| Webhook trusts payment amount | Attacker reduces amount | Verify webhook amount = Firestore booking price |
| Cloud Function logs contain PII | Sensitive data visible | Never log PII; log only event_id and result |
| Booking txn doesn't lock slot | Race: user1 pays → slot released → user2 books | Keep slot "pending" while payment in flight |

---

## UX Pitfalls

| Pitfall | Impact | Better Approach |
|---------|--------|-----------------|
| QR shown without countdown | User scans 40min later → expired → no error | Show "Expires in 15:30"; red at <2min; regenerate button |
| `pending_payment` for hours | User unsure if booked; support tickets | Auto-expire 45min; show "Payment timed out. Click to rebook." |
| "Create Booking" button doesn't disable | User clicks twice → duplicates | Disable + spinner 30s; show "payment processing" |
| Feature flag hides Pix UI but API accepts | User sees "pay with card" → error | Ensure UI flag = API flag; validate in admin UI |
| Webhook failure shows generic error | Admin can't diagnose | Separate states: "Payment OK, notification failed" |
| Feature flag disabled mid-checkout | User's form disappears | Refresh flags every 5min or on event; warn if changes |

---

## "Looks Done But Isn't" Checklist

- [ ] **Pix Integration:** Often missing cold-start exception handling — verify Cloud Logs show no timeouts >10s
- [ ] **Pix Integration:** Often missing QR expiry countdown in UI — verify booking detail shows live timer
- [ ] **Pix Integration:** Often missing webhook signature verification — verify HMAC/JWT validation
- [ ] **Feature Flags:** Often missing expiry dates — verify Firestore config has `expiresAt` on every flag
- [ ] **Feature Flags:** Often missing dependency documentation — verify flag validation in admin UI
- [ ] **Cloud Functions:** Often missing idempotency logic — verify same webhook ID 3× produces same outcome
- [ ] **Cloud Functions:** Often missing fast-fail (202) — verify response sent before FCM
- [ ] **App Startup:** Often missing async flag loading — verify app doesn't block on Firestore read
- [ ] **Webhook Processing:** Often missing deduplication document — verify first request creates dedup record
- [ ] **Booking Transaction:** Often missing expired payment handling — verify slot released when booking expired

---

## Recovery Strategies

| Pitfall | Recovery Cost | Steps |
|---------|---------------|-------|
| Stale feature flags with conflicts | MEDIUM | Audit all flags; remove reached 100%; document remaining; merge conflicts |
| Double bookings from webhook retries | HIGH | Audit Firestore for duplicates; contact users; refund if charged twice |
| QR codes expired, users can't pay | MEDIUM | Create function to regenerate QR for expired bookings; notify users |
| App startup blocked 10s on flag load | MEDIUM | Migrate to async; deploy with defaults; background refresh; clear cache |
| Webhook notification spam | LOW | Implement deduplication; redeploy; acknowledge in admin comms |
| Webhook handler times out | MEDIUM-HIGH | Implement fast-fail (202); queue async; reprocess unconfirmed; communicate timeline |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Webhook timeout double-booking | PIX-04 | Trigger webhook 3×; verify only one booking confirmed; response <500ms |
| Stale feature flags | FEAT-02 + process | Add expiry field to admin UI; document 14-day rule; audit monthly |
| Firestore cold start | FEAT-01 | Profile startup <2s splash; verify async flag load |
| QR code expiry | PIX-03 | QR shows countdown; cleanup function deployed; test regenerate button |
| Async payment breaks txn | PIX-01 | Create booking → pending_payment; payment fails → slot releasable |
| Feature flag combinations | FEAT-03 | Document matrix (4 combos max); test critical paths only |
| Webhook retries spam | PIX-04 | Send webhook 3×; verify admin gets 1 notification; handler 202 immediate |

---

## Sources

- [Transaction serializability and isolation | Firestore](https://firebase.google.com/docs/firestore/transaction-data-contention)
- [Race Conditions in Firestore: How to Solve it? | Medium](https://medium.com/quintoandar-tech-blog/race-conditions-in-firestore-how-to-solve-it-5d6ff9e69ba7)
- [Practical usages of Idempotency - DEV Community](https://dev.to/woovi/practical-usages-of-idempotency-3926)
- [Cloud Functions pro tips: Retries and idempotency | Google Cloud Blog](https://cloud.google.com/blog/products/serverless/cloud-functions-pro-tips-retries-and-idempotency-in-action)
- [How to Implement Webhook Idempotency | Hookdeck](https://hookdeck.com/webhooks/guides/implement-webhook-idempotency)
- [Stop Doing Business Logic in Webhook Endpoints | DEV Community](https://dev.to/elvissautet/stop-doing-business-logic-in-webhook-endpoints-i-dont-care-what-your-lead-engineer-says-8o0)
- [How to Implement Feature Flags in Flutter | Program Tom LTD](https://programtom.com/dev/2025/08/17/how-to-implement-feature-flags-in-flutter/)
- [Stale Feature Flags | minware](https://www.minware.com/guide/anti-patterns/stale-feature-flags)
- [Feature Flags: 12 Best Practices | Design Revision](https://designrevision.com/blog/feature-flags-best-practices)
- [Solving the Matrix of Feature Flags | Atomic Object](https://spin.atomicobject.com/solve-matrix-feature-flags/)
- [Pix and QR Codes | Pismo Developers Portal](https://developers.pismo.io/pismo-docs/docs/pix-and-qr-codes)
- [PagBrasil's Automatic Pix: Integration Guide | PagBrasil](https://www.pagbrasil.com/blog/pix/pagbrasils-automatic-pix-integration-guide-for-developers/)
- [Tips & tricks | Cloud Functions for Firebase](https://firebase.google.com/docs/functions/tips)
- [Reducing Firestore Cold Start times | Carter Roeser](https://cjroeser.com/2022/12/28/reducing-firestore-cold-start-times-in-firebase-google-cloud-functions/)
- [Speed Up Firebase Cold Starts with REST | Ayrshare](https://www.ayrshare.com/speed-up-firebase-cold-starts-with-firestore-rest-calls/)
- [How to Solve Race Conditions in Booking System | HackerNoon](https://hackernoon.com/how-to-solve-race-conditions-in-a-booking-system)
- [Reservation System for Race Conditions with Async | Medium](https://medium.com/@inexpressible2510/how-i-design-a-reservation-system-for-race-conditions-with-async-processing-simple-and-practical-7ffb50798fb2)
- [Handling Payment Webhooks Reliably | Medium](https://medium.com/@sohail_saifii/handling-payment-webhooks-reliably-idempotency-retries-validation-69b762720bf5)

---

*Pitfalls research for: Flutter Web booking app (Vida Ativa) — v4.0 Pix payment + feature toggles*  
*Researched: 2026-04-06*

# Project Research Summary: Vida Ativa v4.0

**Project:** Vida Ativa v4.0 — Feature Toggles & Pix Automatic Payment  
**Domain:** Flutter Web PWA sports court booking application  
**Researched:** 2026-04-06  
**Confidence:** HIGH

---

## Executive Summary

Vida Ativa v4.0 adds two critical capabilities to Brazil's sports booking market: **feature toggles for per-academy configuration** and **Pix payment integration**. Both are table stakes for production-grade booking apps serving multiple venues in Brazil, where Pix is the dominant payment method (40% of e-commerce, 18% higher checkout conversion than card-only).

The recommended approach is conservative and battle-tested: use **Mercado Pago** for Pix QR generation + webhooks (mature API, extensive examples, 1.99% fee), and implement feature toggles via a **custom Firestore document** (`/config/features`) rather than a separate Firebase service. This leverages existing Firestore infrastructure, simplifies admin UX, and avoids operational overhead of a second Firebase product. The architecture remains within the proven flutter_bloc pattern—load config at startup, expose via ConfigCubit, update payment state via listener streams.

The critical risk is **webhook reliability and idempotency**—payment gateways retry on timeout, users retry when they see errors, and double-bookings are the highest-impact failure mode. Prevention requires fast-fail webhook handlers (return 202 before heavy work), idempotent processing keyed on transaction ID, and careful slot-hold semantics during the async payment window.

---

## Key Findings

### Recommended Stack

**Pix Payment Gateway:** Mercado Pago (`@mercadopago/sdk-node` v2.0.0+) via Node.js 20 Cloud Functions  
- Mature Pix QR API; generates single-use codes with embedded amounts  
- Standardized webhook notifications (POST to configurable endpoint)  
- Extensive GitHub examples for Cloud Functions integration  
- 1.99% fee is higher than PagSeguro (0.99%) but justified by ecosystem maturity  
- **Alternative:** PagSeguro (0.99% fee) is same-day drop-in replacement if fees become critical

**Feature Toggles:** Custom Firestore-based service (no new packages)  
- Store flags in `academies/{academyId}/config/features` document (boolean map)  
- Load once at app startup via FeatureFlagsService; cache in memory  
- Optional real-time listener for admin UI changes without restart  
- Avoids Firebase Remote Config (separate service, operational overhead)  
- Avoids third-party vendors (ConfigCat, Flagsmith—overkill for v4.0)

**Core Technologies:**
- `http` (^1.1.0, Flutter) — client POST to Cloud Function for payment initiation
- `qr` (^2.2.0, Flutter) — QR code rendering (no scanning needed; user scans from phone)
- `firebase_messaging` (^14.7.0) — FCM push notifications on payment confirmed
- `cloud_firestore` (existing) — payment status storage and feature flag source of truth

### Expected Features

**Must Have (Table Stakes):**
- Feature toggles per academy (users expect different venues to have different settings)
- Pix payment method (40% of Brazilian e-commerce; 18% higher conversion than card)
- Payment status visibility (users see if booking is pending or confirmed)
- QR code + copy-paste option (QR for mobile, copy-paste essential for web users)
- Payment expiry handling (30-minute default; UI countdown, cleanup on timeout)
- Admin payment status view (admin column in booking list, detail in sheet)

**Should Have (Competitive Differentiators):**
- Real-time payment confirmation (no refresh needed; Firestore listener updates UI instantly)
- Automatic payout to admin (Pix real-time settlement; PSP handles this)
- One-tap retry for expired QR (regenerate new QR without rebooking)
- Feature flag audit log (track who changed which flag when)

**Defer to v4.1+ (Scope Creep):**
- Installment payments (Pix Parcelado—Central Bank launch June 2026, too new)
- Card payments (defer to v5+; Pix adoption sufficient for v4.0)
- A/B testing / per-user feature flags (analytics overhead, not needed for MVP)
- Payment on admin approval (breaks UX flow; payment happens immediately)

### Architecture Approach

Feature toggles and Pix payment integrate into the existing **flutter_bloc architecture** with minimal disruption. Load config at app startup → expose via ConfigCubit → accessed immutably by widgets. Payment state is separate: create booking with `status: pending_payment` → generate QR → listen to webhook → update status to `confirmed` via Firestore listener.

**Major Components:**
1. **ConfigRepository + ConfigCubit** — Load `/config/features` once; emit immutable FeatureConfig state
2. **PixPaymentRepository + PaymentRecord model** — Track payment status via `/bookings/{id}/payment` listener
3. **BookingRepository (modified)** — Create booking with status based on `enablePixPayment` flag
4. **Cloud Function webhook handler** — Receive Mercado Pago webhook; verify signature; update Firestore idempotently; queue notifications
5. **BookingCubit (modified)** — Orchestrate booking + payment; watch payment status; emit updates

### Critical Pitfalls

1. **Webhook Timeout Cascading into Double-Booking** — Payment gateway retries timeout; user retries seeing error; two bookings created for one payment. **Avoid with:** fast-fail webhook (return 202 before notifications), idempotent processing (use transaction ID as key), prevent user-side retries (disable button 30s after), database-level unique constraint on slot+date+userId.

2. **Stale Feature Flags Creating Untestable Code Paths** — Flags left in code for months; 10 flags = 1,024 paths to test; regressions hidden until support tickets. **Avoid with:** add expiration date to every flag (Firestore field); require removal within 14 days of 100% rollout; flag ownership + quarterly audit.

3. **Firestore Cold Start Blocking App Startup** — First Firestore request hits gRPC overhead (5-10s); blank screen; feature flags never load; UI silently disabled. **Avoid with:** async flag loading (defaults on init, refresh in background within 3s timeout); REST transport option; local caching in localStorage.

4. **QR Code Expiry Not Managed** — User returns after 35 minutes; QR expired; payment fails; booking stuck in `pending_payment`. **Avoid with:** display countdown timer; auto-extend button at <5min; Cloud Function cleanup at 45min; reject webhooks after timeout.

5. **Async Payment But Booking Transaction Assumes Synchronous** — Firestore transaction marks slot unavailable; payment fails; slot permanently locked. **Avoid with:** separate transactions (create atomic, generate QR async, confirm via webhook); hold slot only during payment window; document state machine (available → pending_payment → confirmed/expired → completed).

---

## Implications for Roadmap

The v4.0 feature set naturally decomposes into **3 sequential phases** based on dependencies and pitfall prevention:

### Phase 1: Feature Flag Foundation (FEAT-01, FEAT-02, FEAT-03)
**Rationale:** Feature toggles are self-contained and unblock payment UI logic. Loading at startup avoids cold-start pitfall; async loading with defaults is foundational.

**Delivers:**
- FeatureFlagsService in `lib/core/services/feature_flags_service.dart`
- ConfigCubit + ConfigState for immutable flag exposure
- Firestore `/config/features` document structure
- AdminFeaturesScreen UI (toggle switches for Pix, notifications, recurring, social)
- App startup: async load with defaults; refresh in background within 3s timeout

**Addresses Features:**
- Feature toggles per academy (table stakes)
- Automatic refresh capability for admin changes

**Avoids Pitfalls:**
- Cold start blocking app (async load with defaults from day 1)
- Stale flags (document expiration requirement in admin UI)
- Uncontrollable code paths (single source of truth in Firestore)

**Research Flags:** None—feature flag patterns are mature; skip research-phase

---

### Phase 2: Booking + Payment State Integration (PIX-01, FEAT-04)
**Rationale:** Modify BookingModel and BookingRepository to support payment-aware status. Establish payment data models and Firestore subcollection before webhook integration.

**Delivers:**
- PaymentRecord model + Firestore subcollection `/bookings/{id}/payment/{txId}`
- BookingModel extended with `expiresAt` and `paymentTransactionId`
- BookingRepository transaction logic: separate create (atomic) from QR generation (async)
- PixPaymentRepository for payment status listening
- UI: BookingConfirmationScreen with conditional Pix button (gated by feature flag)
- Firestore rules for payment updates (Cloud Function writes only)

**Addresses Features:**
- Payment status visibility (pending, confirmed, expired, failed)
- Slot hold semantics during payment window
- QR code + copy-paste display

**Avoids Pitfalls:**
- Async payment misaligned with transaction (separated from day 1)
- Payment without expiry (expiresAt field on both booking and payment)
- Feature flag + payment feature combination testing (consistent flag checks)

**Research Flags:** None—BLoC patterns are standard; skip research-phase

---

### Phase 3: Pix Integration + Webhook Handler (PIX-02, PIX-03, PIX-04, PIX-05, PIX-06)
**Rationale:** Integrate Mercado Pago after payment state foundation is solid. Webhook handler is last because it depends on correct idempotency semantics from Phase 2.

**Delivers:**
- Cloud Functions: `createPixPayment` (accepts booking, returns QR + expiry)
- Cloud Functions: `handlePixWebhook` (verify signature, update payment status idempotently, queue notifications via async function/PubSub)
- QR code display (via `qr` package) with countdown timer
- Copy-paste code display for web users
- Admin payment status view (column in booking list, details in sheet)
- FCM notification on payment confirmed (reuse existing setup)
- Payment webhook signature verification (HMAC-SHA256 or provider-specific)
- Deduplication logic (event ID as key; check before any heavy work; return 202 early)

**Addresses Features:**
- Pix payment method (table stakes)
- QR code + copy-paste (Brazil standard UX)
- Payment expiry countdown (no silent failures)
- Real-time payment confirmation (Firestore listener fires after webhook)
- Admin dashboard updates (shows payment status instantly)

**Avoids Pitfalls:**
- Double-booking from webhook timeout (fast-fail 202, idempotent processing, event key dedup)
- Webhook retry spam (dedup on transaction ID; send notifications async, outside handler)
- Expired QR codes (auto-cleanup function at 45min; regenerate button)
- Feature flag + payment combinations untested (flag checks consistent; critical paths documented)

**Research Flags:** 
- **Mercado Pago sandbox account setup** (external dependency; 1-3 days)
- **Webhook signature verification** (verify X-Signature header format with Mercado Pago docs; low risk if docs clear)

**Standard Patterns:** Webhook deduplication, fast-fail handlers, Firestore transactions are well-documented; no custom research needed

---

### Phase Ordering Rationale

1. **Feature toggles first** because they govern entire Phase 3 (if Pix disabled, no payment UI). Cold-start handling must be solved before payment complexity. Showcases modularity early to stakeholders.

2. **Payment state second** because it establishes data models and transaction semantics that webhook handler depends on. Separates concerns: create (Phase 2) vs. confirm (Phase 3). Allows Phase 2 and 3 work to run in parallel if needed (booking UI development doesn't block webhook implementation).

3. **Webhook last** because it's the final integration point. All supporting pieces (models, repositories, UI, flag checks) must be in place first. Early pitfall prevention (idempotency, fast-fail, deduplication) built into Phase 2 data layer. Webhook should not deploy before Phase 2 is complete.

**Critical Dependencies:**
- Phase 1 MUST complete before Phase 3 (toggles control payment UI)
- Phase 2 MUST complete before Phase 3 (payment state models required)
- Phases 2 and 3 can overlap if separate teams (booking + webhook in parallel)

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack (Mercado Pago + Firestore) | HIGH | Official docs, multiple GitHub examples, community consensus on Pix integration patterns |
| Features (table stakes vs. differentiators) | HIGH | Feature research grounded in market data (40% Pix adoption, 18% conversion lift), Brazilian market context |
| Architecture (BLoC patterns + payment flow) | HIGH | BLoC is production-proven in existing v1-v3 codebase; webhook patterns match Firebase docs; data models validated against Firestore schema |
| Pitfalls (webhook, cold start, stale flags) | HIGH | Sourced from production Flutter + Firebase teams (Cloud Blog, Firebase docs, industry case studies); pitfall mitigation strategies verified |

**Overall Confidence:** HIGH

### Gaps to Address

1. **Mercado Pago Sandbox Account Setup** — Research assumes account access; actual credential setup (API key, webhook signing secret) is external dependency (1-3 days). Flag during Phase 3 planning.

2. **Webhook Signature Format** — Mercado Pago X-Signature header format not verified in detail. Research notes HMAC-SHA256 pattern but exact implementation details may differ. Verification needed during Phase 3 implementation. Low risk (docs are usually clear; PagSeguro fallback uses same approach).

3. **QR Code Library Compatibility** — `qr` package (v2.2.0) assumed to work with Flutter Web; not tested in this project's environment. Low risk (package is mature; widely used in Flutter Web).

4. **Cold Start Performance on Cellular** — Firestore async load with defaults assumed to complete <3s; actual measurement needed on slow networks. Test during Phase 1 integration.

5. **Feature Flag Expiration Governance** — Research recommends 14-day expiry rule; adoption depends on team discipline + process. Need to formalize during Phase 1 planning (admin UI should remind; monthly audits documented).

6. **Payment Provider Fallback** — Mercado Pago is primary; PagSeguro is documented as drop-in replacement but not tested with this codebase. Confirm during Phase 3 if provider selection changes.

---

## Sources

### Primary Research Files (Synthesized Here)
- `.planning/research/STACK.md` — Pix payment gateway, feature toggle technologies, Cloud Functions patterns
- `.planning/research/FEATURES.md` — Feature landscape, table stakes vs. differentiators, Pix UX standards
- `.planning/research/ARCHITECTURE.md` — BLoC patterns, data flow, component boundaries, Firestore models
- `.planning/research/PITFALLS.md` — Webhook idempotency, cold start, stale flags, payment state machines

### High Confidence Sources
- **Mercado Pago Developers:** Pix Integration, Webhooks, SDK documentation
- **Firebase Documentation:** Cloud Functions, Firestore, Security Rules, Real-time Listeners
- **Cloud Blog (Google Cloud):** Webhook Idempotency, Cloud Functions Retries
- **Flutter Package Ecosystem:** `qr` (v2.2.0), `http` (v1.1.0), `firebase_messaging` (v14.7.0)

### Market Context
- **Brazil Pix Adoption:** 40% of e-commerce, 18% higher checkout completion vs. card-only
- **Pix Central Bank Standards:** QR code expiry (30-min default), copy-paste code format
- **Industry Best Practices:** Webhook fast-fail, idempotency keys, feature flag lifecycle management

---

*Research completed: 2026-04-06*  
*Ready for roadmap definition: yes*  
*Ready for phase planning: yes*

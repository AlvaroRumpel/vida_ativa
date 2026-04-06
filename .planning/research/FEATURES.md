# Feature Landscape: v4.0 Feature Toggles & Pix Payment

**Domain:** Sports court booking app (Flutter Web PWA + Firebase)
**Researched:** 2026-04-06
**Overall confidence:** HIGH (feature toggles), MEDIUM (Pix integration)

## Executive Summary

This research covers two critical features for v4.0:

### Feature Toggles (Table Stakes for Modularization)

Feature toggles/flags are the standard mechanism for modularizing a production Flutter app serving multiple venues. Every mature mobile app uses them to enable/disable features without redeployment. The ecosystem strongly favors **Firebase Remote Config** over custom Firestore solutions because it has offline support, client-side evaluation, and SDKs built for mobile-first apps. However, since this app already uses Firestore and wants in-app admin control (not Firebase Console), a **custom Firestore-based solution** is pragmatic: store flags in `config/features` document, reload on app launch + poll for changes, expose toggles via BLoC, conditionally render UI. Admin UX is straightforward: Firebase UI table edit + toggle switches in an `AdminFeaturesScreen`.

### Pix Payment Integration (Table Stakes for Brazilian Market)

Pix is table stakes for booking in Brazil—40% of e-commerce uses it; apps integrating Pix see 18% higher checkout completion than card-only. The payment flow is: user reserves → app shows QR code + copy-paste code → user pays in their banking app → webhook confirms → booking status updates to confirmed. This requires picking a payment PSP (Stripe, PagSeguro, Asaas, PagBrasil), generating a QR code, handling async webhook confirmation, and managing expiry (30-minute default). The user experience is fast (confirming payment takes 10-30 seconds in most cases) and familiar to all Brazilian users.

## Table Stakes

Features users expect in a Brazilian court booking app. Missing = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Feature toggles per academy** | Vida Ativa expects different features enabled/disabled by location (some academies want Pix, some want manual confirmation, some disable social features) | Low-Med | Firebase Remote Config industry standard; custom Firestore acceptable for in-app admin control |
| **Pix payment method** | Pix is #1 payment method in Brazil (40% of e-commerce); users expect it; 18% higher conversion than card-only | Med | Requires PSP account (Stripe/PagSeguro/Asaas/PagBrasil), QR code generation, webhook handling |
| **Payment status visibility** | Users want to know if their payment was confirmed or pending; eliminates confusion | Low | UI state management; `pending_payment` → `confirmed` status flow |
| **QR code + copy-paste option** | Standard Pix UX; copy-paste code essential for web users who can't tap to app switch | Low | Display both QR code image + copyable code string |
| **Payment expiry handling** | QR codes expire (30 min default); users need to know if they ran out of time | Low-Med | Timer display, expired QR code UI, re-generate or abandon booking flow |
| **Admin sees payment status** | Admin must confirm payments or flag issues; integration with existing admin panel | Low | Add payment status column to booking list; show QR code details in booking detail sheet |

## Differentiators

Features not expected but valued by users and academy owners.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Real-time payment confirmation** | User sees booking move to confirmed state instantly after scanning QR code; no refresh needed | Med | Requires polling webhook status or real-time listener on booking doc; Firestore listener is simplest |
| **Partial payment option** (future, not v4.0) | Allow admins to collect deposit now, balance on arrival | High | Requires splitting payment into parts; adds complexity; defer to v4.1 |
| **Automatic payout to admin** | Payment arrives in admin's account within minutes (Pix real-time settlement) | Med | PSP integration handles this; no extra app logic needed |
| **One-tap retry for expired QR codes** | If QR expires, user can immediately generate a new one without recreating the booking | Med | Requires ability to revoke old payment request and create new one; possible with most PSPs |
| **Feature flag audit log** | Admin sees when flags were changed and by whom | Low-Med | Log changes to `config/features` document; display in admin panel |

## Anti-Features

Features to explicitly NOT build in v4.0.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Payment on admin approval** | Booking requires admin approval first, then payment; breaks UX flow (user waits for approval before paying) | Payment happens immediately after user creates booking; admin approval is separate optional setting |
| **Installment payments (Pix Parcelado)** | Requires Pix Automático (recurring); Central Bank launched June 2026; too new and complex for v4.0 MVP | Use single one-time Pix payment; installments are future feature (v4.1+) |
| **Card payments (credit/debit)** | Adds significant PSP complexity; Brazil prefers Pix (40% vs 36% for cards by 2027); deferring per PROJECT.md scope | Pix only in v4.0; card support is v5+ if needed |
| **Payment webhook retry logic in app** | App shouldn't retry webhooks; webhook is one-way notification from PSP; app trusts it | PSP handles webhook retries; app just processes when it arrives |
| **Granular per-user feature flags** | A/B testing users; requires user targeting, analytics, rollout %; too complex | Academy-level flags only; all users at same academy see same flags |
| **Feature flag caching with stale timeout** | Cache flags for 24h to reduce Firestore reads; can cause user confusion if flags change and they don't know | Load flags on app launch + listen for real-time changes; always show current state |

## Feature Dependencies

```
Payment (Pix) depends on:
  └─ BookingModel extended with payment fields (payment_id, status, pix_qr_url, expires_at)
  └─ Cloud Function webhook receiver (receives payment status from PSP)
  └─ PSP integration (Stripe/PagSeguro/Asaas setup, API keys)

Feature Toggles depends on:
  └─ FeatureFlagService/BLoC to load and manage flags
  └─ Firestore /config/features document
  └─ AdminFeaturesScreen UI to edit flags
```

Bookings can exist without Pix (manual payment mode, admin confirmation). Pix can be toggled off per academy.

## Feature Flag Ecosystem

### What Works

**Firebase Remote Config** is industry standard (used by 90%+ of Flutter apps doing feature flags). Pros: offline support, instant client-side evaluation, built-in mobile SDKs, A/B testing, no custom logic. Cons: manages flags via Firebase Console only (no in-app admin UI without custom implementation).

**Custom Firestore solution** (recommended for this project) stores flags in a single Firestore document (`/config/features` as a map of flag names → enabled boolean). Pros: full control over structure, admin can manage flags in-app, integrates with existing Firestore rules, no extra Firebase product. Cons: no offline support (but acceptable—flags load at app startup and don't change often), no built-in analytics.

**Third-party services** (Flagsmith, ConfigCat, LaunchDarkly, Toggly): Full-featured platforms with dashboards, analytics, targeting, rollouts. Not recommended for v4.0 due to cost and overhead; use custom Firestore instead.

### Recommended Approach for Vida Ativa

**Store flags in Firestore `/config/features` document:**
```firestore
{
  notifications_enabled: true,
  recurring_bookings_enabled: true,
  social_features_enabled: true,
  pix_payment_enabled: true,
  manual_confirmation_mode: false,
  last_updated: Timestamp,
}
```

**Load in app startup:**
- On app initialization (AuthenticationCubit or AppInitCubit), fetch `/config/features` once
- Load into a FeatureFlagsService singleton
- Optionally listen to real-time changes via Firestore listener

**Expose via BLoC/Cubit:**
```dart
class FeatureFlagsCubit extends Cubit<FeatureFlagsState> {
  bool isFeatureEnabled(String featureName) => state.flags[featureName] ?? false;
}
```

**Use in UI:**
```dart
context.read<FeatureFlagsCubit>().isFeatureEnabled('pix_payment_enabled')
  ? PaymentWidget()
  : SizedBox.shrink()
```

**Admin UX:** Simple CRUD screen that reads/writes `/config/features` document. Toggle switches for each flag. Optional: timestamp of last change + admin name (if logging).

## Pix Payment Ecosystem

### What Works

**QR Code Display:** Every Brazilian banking app supports scanning QR codes. Standards are set by Central Bank of Brazil (BCB). Display options:
1. **Dynamic QR code** (most common): QR encodes payment details directly. Generated by PSP API when creating payment request.
2. **Copy-paste code** (essential for web): Human-readable string of 50-90 chars. User copies in app, pastes in their banking app's "Pix Key" field.

**Payment Flow:**
1. User creates booking → app calls PSP API with amount, booking ID, expiry time (30 min default recommended)
2. PSP returns QR code + copy-paste code + payment_id
3. User scans QR or copies code → opens banking app → confirms amount → payment confirmed
4. PSP sends webhook with payment status
5. App updates booking status from `pending_payment` to `confirmed`
6. User sees instant confirmation in app

**Status States:**
- `pending_payment`: QR generated, waiting for user to scan and pay
- `confirmed`: Payment confirmed by PSP webhook
- `expired`: 30 minutes elapsed, QR no longer valid, user must create new booking or retry
- `failed`: Payment rejected by user's bank (rare for Pix)

**Webhook Validation:** PSP sends webhook to Cloud Function endpoint. Always validate webhook signature (varies by PSP; typically SHA-256 hash of request + secret key). Idempotent processing (check if payment_id already processed to handle duplicate webhooks).

### Recommended PSP for Vida Ativa

| PSP | Strengths | Weaknesses | Integration Complexity |
|-----|-----------|-----------|------------------------|
| **Stripe** | Global scale, excellent docs, REST API | Higher fees (~2.9%), webhook complexity | Med |
| **PagSeguro** | Brazilian leader, good for local businesses, clear Pix docs | Legacy UI, slower onboarding | Med-High |
| **Asaas** | Built for recurring payments, affordable, developer-friendly | Smaller than PagSeguro/Stripe | Low-Med |
| **PagBrasil** | Purpose-built for Pix, flexible QR generation, good developer support | Smaller player | Low |

**Recommendation:** **Stripe** (if already using for other projects) or **PagBrasil/Asaas** (if starting fresh, lower overhead for single-payment Pix). Avoid PagSeguro for v4.0 (complex integration; save for multi-payment v5).

## MVP Recommendation

**Prioritize (Phase v4.0):**

1. **Feature Toggles** (FEAT-01, FEAT-02, FEAT-03 from PROJECT.md)
   - Complexity: Low
   - Blocker risk: None (self-contained feature)
   - Implementation: Firestore `/config/features` doc + FeatureFlagsService + AdminFeaturesScreen
   - Estimated effort: 3-5 days

2. **Pix Payment Core** (PIX-01, PIX-02, PIX-03, PIX-04)
   - Complexity: Medium
   - Blocker risk: PSP account setup (1-3 days external)
   - Implementation: PSP API client, QR code display, webhook handler, booking status update
   - Estimated effort: 5-7 days (after PSP account ready)

3. **Payment UX** (PIX-05, PIX-06)
   - Complexity: Low (UI layer only)
   - Implementation: Payment status display in "Minhas Reservas" + admin panel
   - Estimated effort: 2 days

**Defer (v4.1+):**
- Installment payments (Pix Parcelado) — wait for June 2026 launch to mature
- Card payments — Pix adoption sufficient for MVP
- Feature flag analytics/audit — can add later
- A/B testing / per-user rollouts — scope creep for v4.0

## Complexity Assessment

| Feature | Tier | Why |
|---------|------|-----|
| Feature toggles | Low | Simple Firestore doc, boolean map, BLoC state |
| Pix QR display | Low-Med | PSP API client + standard QR library; mostly glue code |
| Payment webhook | Med | Async validation, idempotency, Firebase Function, signature checking |
| Status updates | Low | Firestore transaction (already pattern in booking code) |
| Admin panel for flags | Low | Standard CRUD, toggle switches, familiar UI pattern |
| Admin payment status view | Low | New column in booking list, existing detail sheet |

## Feature Flag Best Practices

1. **Default to disabled:** Any new feature should have flag `false` by default; enable explicitly per academy
2. **Remove flags after rollout:** Once a feature is stable (1+ month), remove the flag and hardcode the feature
3. **Use clear naming:** `pix_payment_enabled` not `pay_pix`; `notifications_enabled` not `notif`
4. **No nested structures:** Keep `/config/features` flat (map of string → bool), not nested objects
5. **Cache client-side:** Don't fetch flag every render; load once at startup, listen for changes
6. **Log changes:** Track who changed which flag and when (stored in Firestore audit logs)

## Pix Payment Best Practices

1. **Display timer:** Show countdown to QR expiry (e.g., "Valid for 29 minutes 45 seconds")
2. **Always show copy-paste code:** Many users prefer copying over scanning (especially web users)
3. **Validate webhook signature:** Don't trust any payment status update without cryptographic signature verification
4. **Idempotent status updates:** Handle duplicate webhook deliveries gracefully (by payment_id)
5. **Set expiry to 30 minutes:** Match Pix standard; don't make it shorter (frustrates users) or longer (holds funds)
6. **Retry generating QR:** If payment expires or user clicks "generate new QR," create new payment request (PSP allows this)
7. **Show payment status in list:** Admin must see at a glance which bookings are awaiting payment vs confirmed

## Sources

### Feature Toggles
- [Using Flutter Feature Flags to Release Features Without Risk | Flagsmith](https://www.flagsmith.com/blog/flutter-feature-flags)
- [A Comprehensive Guide to Implementing Feature Flags in Flutter | Toggly](https://toggly.io/blog/feature-flags-in-flutter/)
- [Feature Flags in Flutter: Smarter Releases with ConfigCat](https://configcat.com/blog/best-practices-in-dart-flutter/)
- [Flutter Daily: Improving Feature Flag Management with Firebase | Medium](https://medium.com/odds-team/improving-feature-flag-management-in-flutter-with-firebase-a-streamlined-approach-7077af3d7b34)
- [firebase_feature_flag | Flutter package](https://pub.dev/packages/firebase_feature_flag)
- [How to Manage State in Flutter with BLoC Pattern | GeeksforGeeks](https://www.geeksforgeeks.org/how-to-manage-state-in-flutter-with-bloc-pattern/)
- [Managing Feature Flags with a Full-Stack Application | Medium](https://medium.com/@imrancodes/managing-feature-flags-with-a-full-stack-application-a-comprehensive-guide-a64d3e5fe1e6)

### Pix Payment Integration
- [A guide to Pix payments in Brazil | Stripe](https://stripe.com/en-br/resources/more/pix-replacing-cards-cash-brazil)
- [PagBrasil's Automatic Pix: Integration Guide for Developers](https://www.pagbrasil.com/blog/pix/pagbrasils-automatic-pix-integration-guide-for-developers/)
- [Pix instant payments (Brazil) | Pismo Developers Portal](https://developers.pismo.io/pismo-docs/docs/pix-instant-payments)
- [Pix payment system: Real-time payments in Brazil | Checkout](https://www.checkout.com/blog/what-is-pix-payment-system-real-time-payments-in-brazil)
- [Pix: Instant Payments in Brazil | VTEX Developers](https://developers.vtex.com/docs/guides/payments-integration-pix-instant-payments-in-brazil)
- [Pix and QR Codes | Pismo Developers Portal](https://developers.pismo.io/pismo-docs/docs/pix-and-qr-codes)
- [Pix | Paysafe Developer](https://developer.paysafe.com/en/api-docs/payments-api/add-payment-methods/safetypay-express/pix/)

### Pix Market Context
- [PIX Your Ticket to the Brazilian Market (2026) | Rebill](https://www.rebill.com/en/blog/pix-your-ticket-to-the-brazilian-market)
- [Pix for international travelers: Enable Pix in Brazil for Your Bank's Users | PagBrasil](https://www.pagbrasil.com/blog/pix/bridging-borders-with-instant-payments-the-global-potential-of-pix-for-international-travelers/)
- [Navigating Brazil's Payment Ecosystem: Opportunities and Integration Pathways | WooshPay](https://www.wooshpay.com/resources/2026/01/31/navigating-brazils-payment-ecosystem-opportunities-and-integration-pathways-for-cross-border-merchants/)
- [Payment Gateways in Brazil (2026): A Comparison | Rebill](https://www.rebill.com/en/blog/pasarelas-pago-brasil)
- [Top 100 Payment Gateway Companies in Brazil (2026) | ensun](https://ensun.io/search/payment-gateway/brazil)

### Payment Webhook & Status
- [PIX in Brazil for foreign companies: collection, confirmation, and reconciliation | Rebill](https://www.rebill.com/en/blog/pix-brasil-foreign-companies)
- [Understanding Automatic Pix: Transforming Recurring Payments in Brazil | PagBrasil](https://www.pagbrasil.com/blog/pix/how-automatic-pix-works/)

### QR Code Expiry
- [Pix: New QR code expiration setting | VTEX Help](https://help.vtex.com/announcements/2025-02-20-pix-new-qr-code-expiration-setting)
- [Pix integration through EBANX Direct API | EBANX Docs](https://docs.ebanx.com/docs/payments/guides/accept-payments/api/brazil/pix/)
- [Pix - Dodo Payments Documentation](https://docs.dodopayments.com/features/payment-methods/pix)

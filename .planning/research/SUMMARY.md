# Project Research Summary

**Project:** Vida Ativa — Flutter Web PWA Court Booking
**Domain:** Single-venue sports court time-slot booking (beach volleyball / futevôlei)
**Researched:** 2026-03-19
**Confidence:** MEDIUM (training-data based; external research tools unavailable this session)

## Executive Summary

Vida Ativa is a focused single-venue booking app whose competitive bar is "better than a WhatsApp message chain", not a multi-venue SaaS. That framing is decisive for scope: the feature set is small, the architecture is straightforward, and the real risk is correctness and trust — one double-booking or a data leak will drive users back to WhatsApp permanently. The recommended approach is Flutter Web with Firebase (Firestore + Auth), Riverpod for state management, and go_router for URL-based navigation, deployed as a PWA on Firebase Hosting. This stack matches what the project already has bootstrapped and is well-understood by the Flutter community.

The recommended architecture is feature-first with clean layering inside each feature (auth, schedule, booking, admin), following the directory structure already sketched in PROJECT.md. Data flows unidirectionally through Firestore streams into Riverpod providers into widgets. The build order is strictly determined by dependencies: Auth → Schedule (read-only) → Booking (write) → Admin → PWA hardening. Skipping this order creates untestable states and forces rework.

The two risks that could sink the project before launch are the Firestore double-booking race condition (solved with a transaction using a deterministic `slotId_date` document ID) and insecure Firestore rules (the only server-side enforcement layer; must be deployed before any real user data enters). Everything else — Phone Auth reCAPTCHA complexity, service worker caching, ghost bookings from offline queues — is real but recoverable. The double-booking and open rules problems are not.

---

## Key Findings

### Recommended Stack

The project already has the correct Firebase foundation (`firebase_core`, `firebase_auth`, `cloud_firestore`). The additions needed for v1 are: `flutter_riverpod` + `riverpod_annotation` for stream-based state management, `go_router` for browser-correct URL routing, `table_calendar` for the weekly slot picker, and `intl` for Brazilian Portuguese date formatting. No additional Firebase packages (Cloud Functions, Storage) are needed for v1.

PWA configuration is largely handled by Flutter Web's build tooling but requires two manual steps: updating `web/manifest.json` with maskable icons and `display: standalone`, and adding a catch-all SPA rewrite and a `no-cache` header for `flutter_service_worker.js` to `firebase.json`. Security rules should be version-controlled in `firestore.rules` and deployed with `firebase deploy --only firestore:rules`.

**Core technologies:**
- `flutter_riverpod ^2.5.x`: State management — `StreamProvider` + `AsyncValue` map cleanly onto Firestore streams; no BuildContext required for route guards
- `go_router ^14.x`: Routing — official Flutter team package; handles browser URL bar, back button, and auth redirect guards correctly for PWA
- `cloud_firestore ^6.1.3` (existing): Primary database — real-time streams are the correct read strategy for availability data where concurrent writes matter
- `firebase_auth ^6.2.0` (existing): Auth — Google Sign-In as primary; Phone OTP deferred to v2 due to web-specific reCAPTCHA complexity
- `table_calendar ^3.1.x`: Weekly schedule UI — avoids 2-3 days of custom calendar implementation
- `intl ^0.19.x`: Date formatting — required for `pt_BR` locale

### Expected Features

**Must have (table stakes):**
- Google Sign-In auth — gates all write operations; without it the conflict-prevention model breaks
- Weekly schedule view with slot state indicators (available / booked / blocked) — first screen users see; must work before anything else
- Admin: create recurring slot definitions — nothing to book without this; must exist before client flow
- Admin: block specific dates — holidays and maintenance; direct functional dependency
- Reserve a slot (tap-to-book) with conflict prevention via Firestore transaction — core action; correctness is non-negotiable
- View my bookings + cancel with configurable cancellation window — users need to self-manage
- Admin: view all bookings + confirm/reject — closes the WhatsApp confirmation loop
- Configurable approval mode (auto vs. manual) — lets admin start cautious and relax later
- PWA install (manifest + service worker) — set up at project start, not as an afterthought

**Should have (differentiators):**
- Booking status timeline (Pending → Confirmed → Cancelled) — eliminates "did they see my message?" anxiety
- Cancellation policy enforcement (configurable cutoff hours in Firestore config doc)
- Slot price display — eliminates "how much?" WhatsApp messages
- "My next booking" home card — reduces navigation friction for repeat users

**Defer to v2+:**
- Phone OTP auth — significant web-specific complexity (reCAPTCHA, domain whitelisting); Google covers most Brazilian Android users
- Push notifications — requires FCM token management; out of scope for v1
- Booking history per user in admin — useful but not blocking
- Share slot deep link — nice-to-have once core routing is solid

### Architecture Approach

The correct pattern is feature-first with clean layering: `lib/core/` holds models and Firebase service wrappers; `lib/features/{auth,schedule,booking,admin}/` each contain their own `data/`, `providers/`, and `ui/` subdirectories. The admin feature boundary is enforced at the router level — non-admin users are redirected before reaching admin routes. All writes go through Riverpod notifiers into repositories, never directly from widgets to Firestore.

**Major components:**
1. `core/models/` — Immutable data classes with `fromFirestore`/`toFirestore`; no Flutter dependency; unit-testable
2. `core/services/` + `feature/*/data/` repositories — Firebase SDK calls wrapped and translated into domain objects; providers never import Firebase packages directly
3. `core/router/` — GoRouter with `redirect` guards reading auth state; single entry point for all navigation and the security gate for admin routes
4. `feature/*/providers/` — Riverpod providers exposing Firestore streams via `AsyncValue`; orchestrate repositories; handle loading/error/data states
5. Firestore security rules (`firestore.rules`) — the authoritative server-side enforcement layer for all role and ownership checks

### Critical Pitfalls

1. **Firestore double-booking race condition** — Use a Firestore transaction with `slotId_dateString` as the deterministic document ID; this is the uniqueness key. Do not ship booking writes without this. A client-side availability check is not atomic.

2. **Insecure Firestore security rules** — `flutterfire configure` exposes the API key in the compiled bundle; rules are the only server-side guard. Deploy restrictive rules (role-gated writes, ownership-scoped reads) before any real user data is written. Version-control `firestore.rules` from day one.

3. **PWA service worker caching stale app shell** — Set `Cache-Control: no-cache` on `flutter_service_worker.js` in `firebase.json`. Add a `controllerchange` listener in `index.html` to force reload on new worker activation. Test the full deploy → update → user-sees-new-version flow explicitly.

4. **Ghost bookings from Firestore offline queue** — Disable offline persistence on web (`persistenceEnabled: false`) for the booking flow, or show a "confirming..." state and listen to the booking document's `status` field post-write before showing success. Never transition to "confirmed" before server acknowledgment.

5. **Phone Auth reCAPTCHA and domain whitelist failures** — Add all deployment domains to Firebase Console → Authorized Domains before testing Phone Auth. It works on localhost but silently fails on production domains. Given the complexity, recommend deferring Phone OTP to v2 and using Google Sign-In only for v1.

---

## Implications for Roadmap

Based on the dependency graph identified in ARCHITECTURE.md and the MVP ordering from FEATURES.md, six phases are recommended.

### Phase 1: Foundation — Core Models, Firebase Wiring, PWA Setup

**Rationale:** All subsequent features depend on the data model. PWA manifest and Firebase Hosting config are cheap to set up now and expensive to retrofit. Firestore rules should be started here, not at the end.
**Delivers:** Dart model classes (`Slot`, `Booking`, `AppUser`, `BlockedDate`) with Firestore serialization; `firebase.json` with SPA rewrite and correct cache headers; `web/manifest.json` with maskable icons; initial `firestore.rules` file committed to repo; composite Firestore index for `(date, status)` created.
**Addresses:** PWA install (table stakes), data model correctness
**Avoids:** Pitfall 2 (open rules), Pitfall 4 (stale service worker), Pitfall 14 (SPA 404 on hard reload)
**Research flag:** Standard patterns — no additional research needed

### Phase 2: Auth — Google Sign-In, Route Scaffold, Role Guard

**Rationale:** Auth is the gate for all write operations. GoRouter's `redirect` guard is the security boundary for admin routes and must exist before any authenticated screen is built.
**Delivers:** Google Sign-In flow; `AppUser` written to `/users/{uid}` on first login with `role: "client"`; GoRouter scaffold with auth-based redirect; admin route guard redirecting non-admins; Riverpod `currentUser` stream provider.
**Addresses:** Login (table stakes), admin role enforcement
**Avoids:** Pitfall 3 (Phone Auth reCAPTCHA — by deferring Phone OTP to v2), Pitfall 6 (client-only admin enforcement), Pitfall 8 (canvas renderer input issues — test on deployed URL)
**Research flag:** Standard patterns for Google Sign-In; verify HTML renderer behavior on current Flutter Web release before auth UI is built

### Phase 3: Schedule — Read-Only Slot Display

**Rationale:** The schedule screen is what users see first and what booking is triggered from. It must work — with correct loading/error states — before the booking write flow is layered on top.
**Delivers:** Weekly schedule screen with slot cards showing available/booked/blocked states; Firestore streams for slots + bookings for selected week; proper `AsyncValue` loading/error/data handling; `table_calendar` week navigation; blocked dates suppressing slots.
**Addresses:** Weekly schedule view (table stakes), slot availability at a glance, offline-friendly loading states
**Avoids:** Pitfall 7 (slot expansion — keep slots as recurring rules, not pre-expanded documents), Pitfall 10 (missing loading/error states)
**Research flag:** Standard patterns — no additional research needed

### Phase 4: Booking — Reserve, My Bookings, Cancel

**Rationale:** Booking is the core user action and the highest-risk implementation step. The double-booking transaction and ghost booking prevention must be built correctly here; retrofitting them is painful.
**Delivers:** Booking confirmation sheet; `BookingNotifier` with Firestore transaction using `slotId_dateString` as document ID; cancellation with configurable cutoff enforcement; My Bookings screen with pending/confirmed/cancelled status; offline persistence disabled for web booking writes; post-write status listener before showing success.
**Addresses:** Reserve a slot, conflict prevention, view my bookings, cancel, booking status timeline, cancellation policy enforcement
**Avoids:** Pitfall 1 (double-booking race condition — transaction required), Pitfall 5 (ghost bookings from offline queue)
**Research flag:** Standard patterns for Riverpod notifiers; the transaction pattern is well-documented. Test the race condition manually with two browser tabs before marking done.

### Phase 5: Admin — Slot Management, Booking Approval, Blocked Dates

**Rationale:** Admin manages the data that the client features consume. Its absence does not block client flows, so it comes last in the client feature set. However, admin writes must be server-side gated in Firestore rules before this phase ships.
**Delivers:** Admin dashboard with booking list; slot CRUD (create recurring slot definitions); blocked date picker; confirm/reject booking actions; configurable approval mode toggle in `/config/booking`; admin router guard confirmed enforced.
**Addresses:** Admin: create recurring slots, block dates, view all bookings, confirm/reject, configurable approval mode
**Avoids:** Pitfall 2 (rules must be hardened before admin writes go live), Pitfall 6 (all admin writes gated by `isAdmin()` rule), Pitfall 7 (admin creates slot rules, not pre-expanded documents)
**Research flag:** Standard patterns — no additional research needed

### Phase 6: PWA Hardening, Security Rules, Deployment

**Rationale:** This phase promotes the app from "works for development" to "safe for real users." Security rules reference all collections so they can only be finalized after all features are built. The service worker update flow and iOS install banner are polish that requires a real deployment to test.
**Delivers:** Final Firestore security rules deployed; service worker update strategy (no-cache header + controllerchange reload); iOS "Add to Home Screen" in-app banner; end-to-end test of deploy → update → user-sees-new-version flow; Firestore composite indexes verified; `firebase deploy` CI step.
**Addresses:** PWA install (fully), offline behavior
**Avoids:** Pitfall 2 (rules finalized and deployed), Pitfall 4 (service worker update flow), Pitfall 12 (iOS Safari install limitation), Pitfall 13 (rules `get()` cost — acceptable at v1 scale)
**Research flag:** Standard patterns for Firebase Hosting config; verify service worker update behavior against current Flutter Web release

### Phase Ordering Rationale

- Models before auth, auth before schedule, schedule before booking, booking before admin: this is a strict dependency chain — each layer is used by the layer above it
- PWA setup in Phase 1 (not Phase 6) because manifest and hosting config are quick wins with long lead time to validate (must be deployed to test real install behavior)
- Firestore rules started in Phase 1, hardened in Phase 6 — rules can be permissive-but-present during development, but must be restrictive before real data enters
- Admin last among feature phases because it manages configuration that client features depend on; its presence is required before clients can book, but it can be seeded manually during development

### Research Flags

Phases needing deeper research during planning:
- **Phase 2 (Auth):** Verify current Flutter Web HTML renderer behavior and Phone Auth reCAPTCHA requirements against the Flutter Web release in use before building auth UI. Training data confidence is MEDIUM here.
- **Phase 4 (Booking):** The Firestore transaction pattern for double-booking prevention is well-documented, but the interaction with offline persistence on Flutter Web should be tested in a real browser environment early.

Phases with well-documented standard patterns (skip research-phase):
- **Phase 1 (Foundation):** Firestore data modeling and PWA manifest are W3C/Firebase standards; HIGH confidence
- **Phase 3 (Schedule):** Riverpod `StreamProvider` + `table_calendar` is well-documented; MEDIUM-HIGH confidence
- **Phase 5 (Admin):** CRUD with Firestore and Riverpod is standard; rules patterns are documented; HIGH confidence
- **Phase 6 (Deployment):** Firebase Hosting config is documented; service worker headers are standard; HIGH confidence

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM | Versions approximate from training data (cutoff Aug 2025); all pub.dev versions must be verified before pinning. Core technology choices (Riverpod, go_router, Firebase) are HIGH confidence. |
| Features | MEDIUM | Anti-features and core table stakes are HIGH (grounded in PROJECT.md scope decisions). Brazilian market preference for Google vs. Phone auth is LOW — validate with actual users before permanently deferring Phone OTP. |
| Architecture | HIGH | Feature-first Flutter architecture and Riverpod/Firestore patterns are mature and well-documented. Data model and security rules patterns are stable. |
| Pitfalls | HIGH | Firestore transaction behavior, security rules enforcement, Phone Auth domain requirements, and PWA service worker caching are stable, well-documented behaviors. Flutter renderer input behavior is MEDIUM (varies by Flutter version). |

**Overall confidence:** MEDIUM-HIGH

### Gaps to Address

- **Package versions:** All `^X.Y.Z` versions in STACK.md are approximate. Run `flutter pub add` and verify against pub.dev before committing `pubspec.yaml`.
- **Phone OTP feasibility on Flutter Web:** Research confirmed multiple failure modes but did not verify against current FlutterFire version. Before v2 planning, check current `firebase_auth` web changelog for reCAPTCHA improvements.
- **Brazilian market auth preferences:** Assumption that Google Sign-In covers >95% of target users is based on Android market share in Brazil, not gym-demographic data. Worth a quick user survey before deferring Phone OTP permanently.
- **Firestore composite index creation:** The `(date ASC, status ASC)` index on `bookings` must be created in the Firebase Console or via `firestore.indexes.json` before the schedule screen query works. This is not handled by FlutterFire automatically.
- **Flutter Web renderer choice:** HTML renderer vs. CanvasKit affects auth form usability (autofill, virtual keyboard). Decision should be made in Phase 2 and tested on a real deployed URL, not just localhost.

---

## Sources

### Primary (HIGH confidence)
- `f:/_geral/Projetos/vida_ativa/.planning/PROJECT.md` — project requirements, out-of-scope decisions, data model
- Flutter feature-first architecture: codewithandrea.com/articles/flutter-project-structure/ (Andrea Bizzotto)
- Riverpod official docs: riverpod.dev/docs/introduction/getting_started
- GoRouter official package: pub.dev/packages/go_router
- Firebase Hosting SPA config: firebase.google.com/docs/hosting/full-config
- Firestore security rules: firebase.google.com/docs/firestore/security/rules-conditions
- W3C PWA manifest spec: web.dev/progressive-web-apps/

### Secondary (MEDIUM confidence)
- Training knowledge of `flutter_riverpod ^2.5.x`, `go_router ^14.x`, `table_calendar ^3.1.x` — versions unverified against current pub.dev
- Training knowledge of Firestore offline persistence behavior on Flutter Web — requires project-specific testing to confirm interaction with booking transactions
- Feature landscape based on analysis of Playtomic, CourtReserve, Clubspark patterns from training data

### Tertiary (LOW confidence)
- Brazilian market Google Sign-In vs. Phone OTP preference — inferred from Android market share data, not user research
- Flutter Web HTML renderer input behavior — changes between Flutter versions; verify against current release

---
*Research completed: 2026-03-19*
*Ready for roadmap: yes*

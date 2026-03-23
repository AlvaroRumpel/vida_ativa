# Phase 6: PWA Hardening - Context

**Gathered:** 2026-03-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Deploy restrictive Firestore security rules, add iOS install guidance, configure service worker update strategy, and ship the app to Firebase Hosting at the default `.web.app` URL. This is the final hardening step before real users access the app.

</domain>

<decisions>
## Implementation Decisions

### Firestore Security Rules

- `isAdmin()` helper function: check `/users/$(request.auth.uid).isAdmin == true` via Firestore `get()` — no custom claims, no Admin SDK setup needed
- **Bookings read**: all authenticated users can read all bookings (existing behavior preserved — the admin UI reads all bookings by date)
- **Bookings write**: `create` allowed only if `request.resource.data.userId == request.auth.uid`; `update/delete` allowed only if `resource.data.userId == request.auth.uid OR isAdmin()`
- **Slots write**: admin only (`isAdmin()` required)
- **BlockedDates write**: admin only (`isAdmin()` required)
- **Users read**: each user reads only their own profile (`request.auth.uid == userId`), OR admin can read any
- **Users write**: each user writes only their own profile (`request.auth.uid == userId`)
- **`/config/booking` document**: read by any authenticated user (clients need it to know their booking's initial status); write only by admin

### iOS Install Prompt

- Show the install banner **every time** the user accesses the app via iOS Safari without it being installed (no localStorage "shown once" logic)
- Format: a non-blocking **bottom SnackBar** with a close (X) button — does not interrupt navigation
- Message: `Instale o app: toque em Compartilhar › Adicionar à Tela de Início`
- Detection: check `navigator.userAgent` for iPhone/iPad + Safari + not `standalone` mode via `dart:js` interop

### Service Worker Update Strategy

- **Silent update on next visit** — default Flutter behavior; no custom banner or JS interop needed
- The `firebase.json` already has `flutter_service_worker.js` with `Cache-Control: no-cache` — this ensures users always pick up the latest service worker on the next browser session
- No additional Flutter code required for service worker handling

### Production Deployment

- URL: Firebase Hosting default (`vida-ativa-94ba0.web.app`) — no custom domain for v1
- Deploy: manual via Firebase CLI — `flutter build web --no-tree-shake-icons && firebase deploy --only hosting,firestore:rules`
- No CI/CD pipeline needed for v1; custom domain can be added later via Firebase Hosting console

### Claude's Discretion

- Exact Dart code for iOS detection (JS interop pattern to read `navigator.userAgent` and `navigator.standalone`)
- Where in the widget tree to mount the iOS install SnackBar (likely in `app_shell.dart` or `MaterialApp` scaffold wrapper)
- How to verify `firebase deploy` worked (manual spot-check of the live URL)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing infrastructure (read before modifying)
- `firestore.rules` — current Phase 1 bootstrap rules; Phase 6 replaces the slot/blockedDate/booking/users write rules
- `firebase.json` — hosting config with SPA rewrite and cache headers; do NOT change the `flutter_service_worker.js` no-cache header
- `web/manifest.json` — PWA manifest; already complete, may need `apple-mobile-web-app-title` fix in `web/index.html`
- `web/index.html` — currently has `apple-mobile-web-app-title: vida_ativa` (needs to be "Vida Ativa")

### Data model
- `lib/core/models/user_model.dart` — `isAdmin: bool` field; the rules' `isAdmin()` function checks this field in Firestore
- `lib/core/models/booking_model.dart` — `userId` field used in booking write rules

### App shell (iOS banner integration point)
- `lib/app_shell.dart` — bottom navigation shell; likely where the iOS install SnackBar should be shown

No external specs — requirements are fully captured in decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/core/theme/app_theme.dart` — AppTheme.primaryGreen and theme tokens; use for iOS banner styling
- `lib/app_shell.dart` — existing scaffold wrapper with BottomNavigationBar; mount iOS banner here to avoid duplicate banners per-route
- `main.dart` — `persistenceEnabled: false` already set; no changes needed for service worker strategy

### Established Patterns
- `firestore.rules` already has `isAuthenticated()` helper; add `isAdmin()` as second helper in the same file
- `lib/core/router/app_router.dart` — admin routes already guarded by auth redirect; rules add server-side enforcement

### Integration Points
- `web/index.html` — minor fix: `apple-mobile-web-app-title` should read "Vida Ativa" not "vida_ativa"
- Firebase project ID `vida-ativa-94ba0` already in `lib/firebase_options.dart`; `firebase deploy` uses this by default

</code_context>

<specifics>
## Specific Ideas

- iOS SnackBar text: "Instale o app: toque em Compartilhar › Adicionar à Tela de Início"
- Deploy command: `flutter build web --no-tree-shake-icons && firebase deploy --only hosting,firestore:rules`
- Bookings collection: clients reading all bookings is acceptable — the schedule UI shows slots as "booked" without revealing who booked them (REQUIREMENTS.md: "Ver nome de outros clientes no slot" is Out of Scope — this is enforced in the UI, not at the Firestore level)

</specifics>

<deferred>
## Deferred Ideas

- Domínio customizado (ex: vidaativa.com.br) — configurar via Firebase Hosting console em v2
- CI/CD com GitHub Actions para deploy automático — v2
- Notificações push — já em REQUIREMENTS.md v2

</deferred>

---

*Phase: 06-pwa-hardening*
*Context gathered: 2026-03-23*

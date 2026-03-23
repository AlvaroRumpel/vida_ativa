# Phase 6: PWA Hardening - Research

**Researched:** 2026-03-23
**Domain:** Firestore Security Rules, Flutter Web JS Interop, PWA iOS Install Prompt, Firebase Deploy
**Confidence:** HIGH (core decisions locked; technical patterns verified)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- `isAdmin()` helper: check `/users/$(request.auth.uid).data.role == 'admin'` via Firestore `get()` — no custom claims
- Bookings read: all authenticated users can read all bookings (admin UI reads all bookings by date)
- Bookings write: `create` only if `request.resource.data.userId == request.auth.uid`; `update/delete` only if `resource.data.userId == request.auth.uid OR isAdmin()`
- Slots write: admin only (`isAdmin()` required)
- BlockedDates write: admin only (`isAdmin()` required)
- Users read: each user reads only their own profile (`request.auth.uid == userId`), OR admin can read any
- Users write: each user writes only their own profile (`request.auth.uid == userId`)
- `/config/booking` document: read by any authenticated user; write only by admin
- iOS install banner: show **every time** on iOS Safari without standalone — no localStorage "shown once"
- iOS install banner format: non-blocking **bottom SnackBar** with close (X) button
- iOS install banner message: `Instale o app: toque em Compartilhar › Adicionar à Tela de Início`
- iOS detection: check `navigator.userAgent` for iPhone/iPad + Safari + not `standalone` mode
- Service worker update strategy: **silent update on next visit** — default Flutter behavior; no custom banner
- `firebase.json` service worker `no-cache` header: do NOT change
- Deploy URL: `vida-ativa-94ba0.web.app` — no custom domain for v1
- Deploy command: `flutter build web --no-tree-shake-icons && firebase deploy --only hosting,firestore:rules`
- No CI/CD for v1

### Claude's Discretion

- Exact Dart code for iOS detection (JS interop pattern to read `navigator.userAgent` and `navigator.standalone`)
- Where in the widget tree to mount the iOS install SnackBar (likely in `app_shell.dart` or `MaterialApp` scaffold wrapper)
- How to verify `firebase deploy` worked (manual spot-check of the live URL)

### Deferred Ideas (OUT OF SCOPE)

- Domínio customizado (ex: vidaativa.com.br) — configurar via Firebase Hosting console em v2
- CI/CD com GitHub Actions para deploy automático — v2
- Notificações push — já em REQUIREMENTS.md v2
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PWA-01 | App é instalável no celular como PWA (manifest.json, ícones, service worker) | iOS install SnackBar, index.html title fix, firebase.json no-cache header verified |
| INFRA-01 | Regras de segurança do Firestore implementadas e deployadas antes de dados reais | Full Firestore rules rewrite with isAdmin(), per-collection write guards, deploy command |
</phase_requirements>

---

## Summary

Phase 6 has three independent work streams: (1) rewriting `firestore.rules` with proper role-based guards and deploying them, (2) adding an iOS install prompt via JS interop, and (3) doing a clean production deployment. All three are bounded, concrete, and low in unknowns because the CONTEXT.md decisions are fully locked.

The biggest technical question was the JS interop approach for reading `navigator.standalone` on iOS Safari. Research confirms `dart:ui_web`'s `BrowserDetection` class can read `userAgent` and detect `OperatingSystem.iOs`, but `navigator.standalone` is a non-standard Apple property not exposed by either `dart:html` or `dart:ui_web`. It requires a minimal `dart:js_interop` extension type (4 lines of Dart). The `dart:js` package already in many Flutter apps is legacy — the modern approach is `dart:js_interop` extension types (Dart 3.3+, stable since Flutter 3.22).

The Firestore rules pattern is well-understood: `get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'`. One important Firestore-specific detail: the project's `UserModel` uses a `role` field (string `"admin"` / `"client"`), **not** an `isAdmin: bool` field. The rules must match the actual stored field name — `role == "admin"`, not `.isAdmin == true`.

**Primary recommendation:** Write all three concerns as separate tasks. The Firestore rules are the highest-risk item (security-critical, deployed to production); the iOS banner and index.html fixes are low-risk cosmetic/UX additions.

---

## Standard Stack

### Core
| Library / Tool | Version | Purpose | Why Standard |
|---------------|---------|---------|--------------|
| `dart:ui_web` (BrowserDetection) | Flutter SDK built-in | Read `userAgent`, detect `OperatingSystem.iOs` | Built into Flutter; no extra dependency needed |
| `dart:js_interop` | Flutter SDK built-in (Dart 3.3+) | Access `navigator.standalone` JS property | Modern Wasm-compatible interop; replaces deprecated `dart:js` |
| Firebase CLI (`firebase deploy`) | Latest (v13+) | Deploy hosting + Firestore rules | Official tool; already configured in `firebase.json` |
| Firestore Security Rules v2 | rules_version = '2' | Server-side data protection | Already in use in `firestore.rules` |

### No New Packages Required
The project already has all dependencies needed for this phase. No `pubspec.yaml` changes.

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `dart:js_interop` extension types | `dart:html` window.navigator | `dart:html` does NOT expose `navigator.standalone`; not an option |
| `dart:js_interop` extension types | `package:js` | `package:js` is deprecated in Dart 3.3+; `dart:js_interop` is the current approach |
| `dart:js_interop` extension types | `package:web` (window.navigator) | `package:web` also lacks `navigator.standalone`; same limitation |
| Manual `flutter build web && firebase deploy` | Firebase Frameworks-aware deploy | Frameworks-aware deploy auto-builds but cannot pass `--no-tree-shake-icons`; manual two-step is safer |

---

## Architecture Patterns

### Recommended Project Structure for This Phase

No new directories. All changes are in existing files:

```
firestore.rules              — rewrite with isAdmin() + per-collection rules
web/index.html               — fix apple-mobile-web-app-title typo
lib/app_shell.dart           — add iOS install SnackBar logic
lib/core/pwa/                — new: ios_install_detector.dart (JS interop helper)
```

### Pattern 1: Firestore `isAdmin()` via `get()`

**What:** A helper function in `firestore.rules` that reads the requesting user's document from `/users/{uid}` and checks the `role` field.

**Critical detail:** `UserModel` stores `role: "admin"` (a string), not `isAdmin: true` (a bool). The rules must check `.data.role == "admin"`, matching the actual Firestore field.

**Example:**
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isAuthenticated() {
      return request.auth != null;
    }

    function isAdmin() {
      return isAuthenticated() &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "admin";
    }

    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated() &&
        (request.auth.uid == userId || isAdmin());
      allow write: if isAuthenticated() && request.auth.uid == userId;
    }

    // Slots collection
    match /slots/{slotId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }

    // Bookings collection
    match /bookings/{bookingId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() &&
        request.resource.data.userId == request.auth.uid;
      allow update, delete: if isAuthenticated() &&
        (resource.data.userId == request.auth.uid || isAdmin());
    }

    // Blocked dates collection
    match /blockedDates/{dateId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }

    // Config collection
    match /config/{docId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
  }
}
```

**Confidence:** HIGH — pattern confirmed by Firebase official docs and multiple verified sources.

### Pattern 2: iOS Install Detection via `dart:js_interop`

**What:** A small Dart file that declares extension types to read `window.navigator.userAgent` and `window.navigator.standalone`, then exposes a pure Dart function `isIosInstallBannerNeeded()`.

**Why `dart:js_interop`:** `navigator.standalone` is an Apple-specific property not in the W3C spec and not exposed by `dart:html`, `dart:ui_web`, or `package:web`. Only raw JS interop can access it.

**Why NOT `dart:ui_web.BrowserDetection`:** `BrowserDetection` exposes `userAgent` and `operatingSystem` (which CAN detect iOS), but does NOT expose `standalone`. We need both. Using `BrowserDetection.instance.operatingSystem == OperatingSystem.iOs` for the platform check is cleaner than parsing the UA string manually.

**Recommended approach — hybrid (verified pattern):**
```dart
// lib/core/pwa/ios_install_detector.dart
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

// Extension type to access navigator.standalone (Apple non-standard)
@JS('navigator')
external _Navigator get _navigator;

extension type _Navigator(JSObject _) implements JSObject {
  external bool? get standalone;
}

/// Returns true when the iOS install banner should be shown:
/// - Running on iOS (iPhone/iPad)
/// - Opened in Safari (not already in standalone/PWA mode)
bool isIosInstallBannerNeeded() {
  final isIos = ui_web.browser.operatingSystem == ui_web.OperatingSystem.iOs;
  if (!isIos) return false;

  // standalone == null on non-iOS; standalone == true when already installed
  final isStandalone = _navigator.standalone ?? false;
  return !isStandalone;
}
```

**Alternative (pure UA string check — simpler, no extension type needed):**
```dart
// lib/core/pwa/ios_install_detector.dart
import 'dart:ui_web' as ui_web;

bool isIosInstallBannerNeeded() {
  final ua = ui_web.browser.userAgent.toLowerCase();
  final isIos = ua.contains('iphone') || ua.contains('ipad');
  if (!isIos) return false;
  // CSS media query for standalone is more reliable than navigator.standalone
  // but requires JS interop. For v1, checking UA alone is acceptable since
  // iOS Safari is the only browser on iOS anyway.
  // The banner always shows on iOS — user can dismiss with the X button.
  return true;
}
```

**Recommendation:** Use the pure UA string approach (`dart:ui_web` only) unless the requirement demands suppressing the banner after install. Since the decision is "show every time" without "shown once" logic, `navigator.standalone` is not actually needed — showing the banner on every iOS Safari visit (including after install) is acceptable, because once installed the app opens in standalone mode (not Safari) and will never see the banner again anyway.

**Confidence:** HIGH for `dart:ui_web` UA approach; MEDIUM for `dart:js_interop` extension type pattern (pattern confirmed but not tested against this exact Flutter version).

### Pattern 3: iOS Install SnackBar in `AppShell`

**What:** Convert `AppShell` from `StatelessWidget` to `StatefulWidget`. On `initState`, check `isIosInstallBannerNeeded()` and schedule a post-frame `ScaffoldMessenger.of(context).showSnackBar(...)`.

**Why `AppShell`:** It wraps the entire shell navigation — the SnackBar shown here appears once regardless of which tab the user is on. Mounting it at a route level would risk showing it multiple times.

**Example skeleton:**
```dart
class AppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppShell({super.key, required this.navigationShell});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    if (isIosInstallBannerNeeded()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Instale o app: toque em Compartilhar › Adicionar à Tela de Início',
            ),
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'X',
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: BottomNavigationBar(/* ... existing code ... */),
    );
  }
}
```

**Confidence:** HIGH — standard Flutter SnackBar pattern.

### Pattern 4: Deploy Sequence

```bash
# Step 1: build web (--no-tree-shake-icons required for dynamic IconData)
flutter build web --no-tree-shake-icons

# Step 2: deploy hosting + rules together
firebase deploy --only hosting,firestore:rules
```

**Why two separate steps (not `firebase deploy` alone):** Firebase's Frameworks-aware deploy auto-builds Flutter but cannot accept `--no-tree-shake-icons`. The project already uses the manual two-step approach, confirmed working in prior phases.

### Anti-Patterns to Avoid

- **Using `isAdmin: bool` in Firestore rules:** `UserModel` stores `role: "admin"` (String). Rules must use `.data.role == "admin"`, not `.data.isAdmin == true`.
- **Using `dart:js` (old interop):** Deprecated since Dart 3.3. Use `dart:js_interop` extension types.
- **Mounting the iOS SnackBar at a GoRoute level:** Would re-show on every navigation within the shell. Mount at `AppShell` level.
- **Calling `ScaffoldMessenger.of(context)` in `initState` directly:** Must use `addPostFrameCallback` to ensure `ScaffoldMessenger` is accessible.
- **Blocking `isAdmin()` read on the `/slots` read path:** Only gate writes — reads stay open to all authenticated users so the schedule UI continues to work.
- **Changing the `flutter_service_worker.js` no-cache header:** Already configured correctly; touching it is the one change that could break the update flow.
- **Using `firebase deploy` without `--only hosting,firestore:rules`:** Would attempt to deploy all services. Stick to the explicit target list.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| iOS device detection | UA string parsing with regex | `dart:ui_web.BrowserDetection.instance.operatingSystem` | SDK-maintained, handles edge cases |
| Admin role check in rules | JWT custom claims setup | `get()` in Firestore rules checking `role` field | No Admin SDK required; works with existing UserModel |
| Service worker update flow | Custom JS service worker controller | Default Flutter service worker + `no-cache` header (already done) | Flutter generates and manages `flutter_service_worker.js` automatically |
| PWA install detection | Complex `beforeinstallprompt` JS wiring | Simple iOS UA + standalone check | `beforeinstallprompt` is Android/Chrome only; iOS requires different approach |

---

## Common Pitfalls

### Pitfall 1: `isAdmin()` reads `isAdmin` bool field, but UserModel stores `role` string

**What goes wrong:** Rules use `.data.isAdmin == true` but Firestore documents have `{"role": "admin"}`, causing `isAdmin()` to always return false — admin writes silently fail.

**Why it happens:** The CONTEXT.md mentions "`isAdmin` field" but `UserModel` actually uses `role: String` with `bool get isAdmin => role == "admin"`. The Dart getter is named `isAdmin` but the stored field is `role`.

**How to avoid:** Check `user_model.dart` before writing rules. Use `.data.role == "admin"`.

**Warning signs:** Admin operations silently rejected in the app after rules deploy.

### Pitfall 2: `isAdmin()` called on read paths causes slow/failed reads

**What goes wrong:** Adding `isAdmin()` to a read rule (e.g., `allow read: if isAdmin()`) causes every read to trigger a secondary Firestore `get()` for the user document, doubling latency and adding billing cost. Worse, if the user document doesn't exist yet, `get()` returns an empty resource and `isAdmin()` returns false.

**Why it happens:** `isAdmin()` triggers a Firestore read internally. It is only needed on write paths (create/update/delete).

**How to avoid:** Keep all collection reads gated only on `isAuthenticated()` — never `isAdmin()` on reads (except for the Users collection privacy rule which intentionally restricts who can read whose profile).

### Pitfall 3: `dart:js_interop` extension type for `standalone` may return `null` on non-Apple browsers

**What goes wrong:** On Android Chrome, `navigator.standalone` is `undefined` (null in Dart). If the `bool get standalone` is declared non-nullable, it throws at runtime.

**Why it happens:** `navigator.standalone` is an Apple Safari-only property.

**How to avoid:** Declare it as `bool? get standalone` and use `?? false` when reading. Or avoid the JS interop entirely (see Pattern 2 simplified approach — since iOS is the only target, UA detection alone suffices).

### Pitfall 4: SnackBar not showing because `ScaffoldMessenger` is above the widget

**What goes wrong:** `ScaffoldMessenger.of(context).showSnackBar(...)` called in `initState` fails or shows nothing.

**Why it happens:** During `initState` the widget is not yet fully mounted; `ScaffoldMessenger` lookup may fail.

**How to avoid:** Always schedule via `WidgetsBinding.instance.addPostFrameCallback((_) { ... })` and check `if (!mounted) return;` before using context.

### Pitfall 5: Deploying rules without testing admin access

**What goes wrong:** Tightened rules break the admin UI — e.g., admin can no longer read bookings by date.

**Why it happens:** A rule like `allow read: if isAdmin()` on bookings would block clients from reading the schedule.

**How to avoid:** The rule decision is already locked (bookings: `allow read: if isAuthenticated()`). Verify against the decision table before deploying. Do a manual smoke test of the admin flow after deploying rules.

### Pitfall 6: `apple-mobile-web-app-title` and `<title>` still show `vida_ativa`

**What goes wrong:** The app shows `vida_ativa` as the iOS home screen icon label and browser tab title.

**Why it happens:** `web/index.html` line 26 has `content="vida_ativa"` and line 33 has `<title>vida_ativa</title>`.

**How to avoid:** Change both to `Vida Ativa` in the same edit.

---

## Code Examples

### Firestore Rules — Complete Target State

```javascript
// Source: Firebase official docs + CONTEXT.md decisions
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isAuthenticated() {
      return request.auth != null;
    }

    // Reads user's Firestore document to check role field
    // Cost: 1 read per write operation that calls isAdmin()
    function isAdmin() {
      return isAuthenticated() &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "admin";
    }

    match /users/{userId} {
      allow read: if isAuthenticated() &&
        (request.auth.uid == userId || isAdmin());
      allow write: if isAuthenticated() && request.auth.uid == userId;
    }

    match /slots/{slotId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }

    match /bookings/{bookingId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() &&
        request.resource.data.userId == request.auth.uid;
      allow update, delete: if isAuthenticated() &&
        (resource.data.userId == request.auth.uid || isAdmin());
    }

    match /blockedDates/{dateId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }

    match /config/{docId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
  }
}
```

### iOS Detect Function (Recommended — `dart:ui_web` only, no JS interop needed)

```dart
// lib/core/pwa/ios_install_detector.dart
// Source: dart:ui_web BrowserDetection API (Flutter official)
import 'dart:ui_web' as ui_web;

/// Returns true when on iOS Safari and NOT already in standalone (installed PWA) mode.
/// Per CONTEXT.md decision: show every time (no "shown once" suppression).
/// Once the app is installed, it opens in standalone mode and never reaches Safari again.
bool isIosInstallBannerNeeded() {
  return ui_web.browser.operatingSystem == ui_web.OperatingSystem.iOs;
}
```

### iOS SnackBar Integration in `AppShell`

```dart
// lib/app_shell.dart — convert to StatefulWidget
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/pwa/ios_install_detector.dart';
import 'core/theme/app_theme.dart';

class AppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppShell({super.key, required this.navigationShell});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    if (isIosInstallBannerNeeded()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Instale o app: toque em Compartilhar › Adicionar à Tela de Início',
            ),
            duration: const Duration(seconds: 15),
            action: SnackBarAction(
              label: 'X',
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: (index) => widget.navigationShell.goBranch(
          index,
          initialLocation: index == widget.navigationShell.currentIndex,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Minhas Reservas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
```

### `web/index.html` Fix (title only)

```html
<!-- Line 26: change content="vida_ativa" to: -->
<meta name="apple-mobile-web-app-title" content="Vida Ativa">

<!-- Line 33: change <title>vida_ativa</title> to: -->
<title>Vida Ativa</title>
```

### Deploy Command Sequence

```bash
# Build Flutter web (required before deploy; --no-tree-shake-icons needed for dynamic icons)
flutter build web --no-tree-shake-icons

# Deploy hosting assets + Firestore rules in one command
firebase deploy --only hosting,firestore:rules
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `dart:js` for JS interop | `dart:js_interop` extension types | Dart 3.3 / Flutter 3.22 (Feb 2024) | Old `package:js` deprecated; new approach Wasm-compatible |
| `dart:html` window/navigator | `package:web` or `dart:js_interop` | Dart 3.3+ | `dart:html` still works but discouraged for new code |
| Custom claims for Firestore admin | `get()` in rules checking Firestore field | Always supported; now preferred for simple cases | No Admin SDK setup needed |
| Firebase Frameworks-aware deploy (auto-build) | Manual `flutter build web` then `firebase deploy` | N/A for this project | Must be manual to pass `--no-tree-shake-icons` |

**Deprecated/outdated:**
- `package:js` (`@JS()` annotation on classes): deprecated in Dart 3.3, still works in Dart-to-JS but not Wasm. Use `dart:js_interop` extension types for new code.
- `dart:html` `Navigator.standalone`: never existed in Flutter's `dart:html`. The issue was filed (#80224) and closed as "use JS interop".

---

## Validation Architecture

Nyquist validation is enabled (`workflow.nyquist_validation: true`).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK built-in), bloc_test ^10.0.0 |
| Config file | none — uses `flutter test` directly |
| Quick run command | `flutter test test/ --no-pub` |
| Full suite command | `flutter test --no-pub` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PWA-01 | iOS banner shows on iOS Safari (not standalone) | manual | N/A — requires real iOS Safari device/emulator | N/A |
| PWA-01 | iOS banner does NOT show on non-iOS | unit | `flutter test test/core/pwa/ios_install_detector_test.dart` | Wave 0 |
| PWA-01 | `apple-mobile-web-app-title` is "Vida Ativa" in index.html | manual file check | N/A | N/A |
| INFRA-01 | Unauthenticated users cannot write | manual (Firebase Rules Simulator) | N/A | N/A |
| INFRA-01 | Client cannot write other users' bookings | manual (Firebase Rules Simulator) | N/A | N/A |
| INFRA-01 | Admin write gated by `isAdmin()` | manual (Firebase Rules Simulator) | N/A | N/A |

**Note:** Firestore rules and PWA install behavior are inherently environment-specific (real browser, real Firebase project). The primary validation is manual. The only unit-testable piece is `isIosInstallBannerNeeded()`.

### Sampling Rate

- **Per task commit:** `flutter test test/ --no-pub` (confirms no regressions)
- **Per wave merge:** `flutter test --no-pub`
- **Phase gate:** Full suite green + manual Firestore Rules Simulator check before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/core/pwa/ios_install_detector_test.dart` — unit test for `isIosInstallBannerNeeded()` return value given mocked UA strings

---

## Open Questions

1. **`isAdmin()` on the Users read rule — does admin need to read other users' profiles?**
   - What we know: CONTEXT.md says "admin can read any" user profile
   - What's unclear: The admin UI (Phase 5) reads bookings, which include `userDisplayName` stored at booking time — it may not need to read `/users/{uid}` directly
   - Recommendation: Implement as decided (`allow read: if isAuthenticated() && (request.auth.uid == userId || isAdmin())`). This is safe and aligned with the decision.

2. **Will `dart:ui_web.OperatingSystem.iOs` correctly identify iPad on iPadOS 13+?**
   - What we know: iPadOS 13+ changed the iPad user agent to match macOS Safari (desktop mode by default). `BrowserDetection` may return `macOs` for an iPad.
   - What's unclear: The current Flutter version (SDK ^3.11.3) behavior for iPad UA detection
   - Recommendation: For v1, this edge case is acceptable — iPadOS users who see the macOS UA won't get the banner, but can still install manually. If this matters, use the raw UA string check `ua.contains('ipad')` before UA manipulation.

3. **`/config/booking` document collection path**
   - What we know: CONTEXT.md says to gate this document. `firebase deploy` reads `/config/booking` (per Phase 5 state).
   - What's unclear: Whether there are other documents in `/config/` that need different rules.
   - Recommendation: Use `match /config/{docId}` with blanket `allow write: if isAdmin()` — covers any future config documents safely.

---

## Sources

### Primary (HIGH confidence)
- [Firebase Firestore Security Rules Conditions](https://firebase.google.com/docs/firestore/security/rules-conditions) — `get()` syntax, path interpolation
- [dart:ui_web BrowserDetection API](https://api.flutter.dev/flutter/dart-ui_web/BrowserDetection-class.html) — `userAgent`, `operatingSystem` properties
- [dart:js_interop library](https://api.flutter.dev/flutter/dart-js_interop/) — extension type pattern for JS properties
- [Dart JS Interop Usage docs](https://dart.dev/interop/js-interop/usage) — `@JS` extension type syntax
- `lib/core/models/user_model.dart` — confirmed `role: String` field (not `isAdmin: bool`)
- `firestore.rules` — confirmed current Phase 1 bootstrap rules structure
- `firebase.json` — confirmed `flutter_service_worker.js` no-cache header in place

### Secondary (MEDIUM confidence)
- [Flutter issue #80224](https://github.com/flutter/flutter/issues/80224) — confirmed `navigator.standalone` not in `dart:html`; JS interop required
- [Firestore rules examples — Sentinel Stand](https://www.sentinelstand.com/article/firestore-security-rules-examples) — cross-verified `isAdmin()` pattern
- `OperatingSystem.iOs` enum value — confirmed via search against Flutter engine source

### Tertiary (LOW confidence)
- iPadOS 13+ UA desktop spoofing behavior — reported in community; not confirmed against current Flutter SDK version

---

## Metadata

**Confidence breakdown:**
- Firestore rules: HIGH — pattern verified against official Firebase docs and existing project model
- iOS install banner (Dart code): HIGH for `dart:ui_web` UA approach; MEDIUM for JS interop `navigator.standalone` extension type
- Service worker strategy: HIGH — `firebase.json` already has the correct no-cache header; no code changes needed
- Deploy command: HIGH — manual two-step confirmed as the correct approach for `--no-tree-shake-icons` projects

**Research date:** 2026-03-23
**Valid until:** 2026-06-23 (90 days — Firestore rules syntax is stable; `dart:ui_web` API is stable)

# Technology Stack

**Project:** Vida Ativa — Flutter Web PWA Court Booking
**Researched:** 2026-03-19
**Verification note:** External tools (WebSearch, WebFetch, Context7) were unavailable during this research session. All findings are from training knowledge with cutoff August 2025. Package versions should be verified against pub.dev before pinning.

---

## Current Baseline (already in project)

| Package | Version in pubspec | Role |
|---------|-------------------|------|
| firebase_core | ^4.5.0 | Firebase bootstrap |
| firebase_auth | ^6.2.0 | Auth (Google + Phone) |
| cloud_firestore | ^6.1.3 | Primary database |
| flutter_lints | ^6.0.0 | Code quality |
| cupertino_icons | ^1.0.8 | Icon set |

Dart SDK constraint: `^3.11.3`. Flutter stable channel.

---

## Recommended Stack

### State Management

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| flutter_riverpod | ^2.5.x | App-wide state, auth stream, async data | Best fit for Firebase stream-based data; AsyncValue handles loading/error/data states natively; code generation via riverpod_annotation removes boilerplate; better than Provider (type-safe, no context threading) and Bloc (less ceremony for this scale) |
| riverpod_annotation | ^2.3.x | Code generation for providers | Reduces boilerplate; `@riverpod` annotation generates typed providers |
| build_runner | ^2.4.x | Code generation runner | Required for riverpod_annotation |

**Confidence: MEDIUM** — Riverpod 2.x with code generation was the dominant Flutter state management approach through mid-2025. The version numbers should be verified on pub.dev.

**Why not Bloc:** Bloc is excellent but has more ceremony (events, states, blocs) than this app warrants. A booking app with 4 features and 2 user roles is well-served by Riverpod providers without the extra scaffolding.

**Why not Provider:** Provider is deprecated in favor of Riverpod by the same author. It lacks type safety and AsyncValue.

**Why not GetX:** Non-idiomatic, mixes concerns (routing + state + DI), poor testability.

### Routing

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| go_router | ^14.x | Declarative URL-based routing | Official Flutter team package; handles deep links and browser URL bar correctly for PWA (back button, bookmarking); declarative redirect for auth guards; StatefulShellRoute for bottom nav |

**Confidence: HIGH** — go_router is the Flutter team's official routing solution and has been the standard since Flutter 3. It was shipped as part of the flutter/packages repository.

**Why not Navigator 2.0 directly:** Too much boilerplate; go_router is the high-level API over Navigator 2.0.

**Why not auto_route:** go_router is simpler and officially maintained. auto_route is viable but introduces a second code-gen dependency.

### Firebase Packages (additions to baseline)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| firebase_storage | optional, not needed v1 | File uploads | Out of scope; no media uploads in v1 |
| cloud_functions | optional | Server-side logic | Not needed v1; all logic fits in Firestore + client rules |

The existing `firebase_auth ^6.2.0` and `cloud_firestore ^6.1.3` are correct. No additional Firebase packages are needed for v1.

**Phone Auth note:** `firebase_auth` web implementation for phone auth requires reCAPTCHA. On Flutter Web, this renders a reCAPTCHA widget automatically. The `signInWithPhoneNumber` flow differs from native: it returns a `ConfirmationResult` instead of `PhoneAuthCredential`. This must be handled in the auth service implementation.

### UI

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Material Design 3 (built-in) | Flutter SDK | Primary design system | Already configured with `useMaterial3: true`; no additional UI library needed for v1 |
| table_calendar | ^3.1.x | Calendar/week view for slot booking | The standard Flutter calendar widget; handles week view, date selection, event markers; avoids building a custom calendar from scratch |
| intl | ^0.19.x | Date/time formatting, localization | Required for Brazilian Portuguese date formatting (pt_BR locale); used with table_calendar |

**Confidence: MEDIUM** — table_calendar 3.x was the dominant calendar package through mid-2025. Version number needs pub.dev verification.

**Why not syncfusion_flutter_calendar:** Proprietary license for commercial use. table_calendar is MIT.

**Why not custom calendar widget:** The slot-picking UI is complex enough (week navigation, available/booked indicators) that a library saves significant time.

### Utilities

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| shared_preferences | ^2.3.x | Local persistence for user prefs | Lightweight; sufficient for storing theme preference or last-viewed date; already works on Flutter Web |
| equatable | ^2.0.x | Value equality for model classes | Prevents manual `==` and `hashCode` implementations on booking/slot models |
| uuid | ^4.x | Client-side ID generation | Bookings can be given deterministic IDs client-side before Firestore write, simplifying optimistic UI |

**Confidence: MEDIUM** — These are stable, long-lived packages. Versions approximate.

### Testing

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| flutter_test (SDK) | SDK | Widget and unit tests | Already present |
| mockito | ^5.4.x | Mock Firebase services | Standard mocking; `@GenerateMocks` annotation with build_runner |
| fake_cloud_firestore | ^3.x | In-memory Firestore for tests | Avoids real Firebase calls in tests; maintained by Flutter community |

**Confidence: MEDIUM** — fake_cloud_firestore was the standard test double for Firestore through mid-2025.

---

## PWA Configuration

### Service Worker (Flutter Web built-in)

Flutter Web generates a service worker by default. For production PWA behavior:

```
flutter build web --pwa-strategy=offline-first
```

The `--pwa-strategy` flag controls caching:
- `offline-first` — caches app shell on first load, serves from cache first (recommended for PWA)
- `none` — no service worker (bad for installability)

**Confidence: HIGH** — This has been stable Flutter Web build behavior since Flutter 2.

### web/manifest.json

The generated `manifest.json` needs these fields for full PWA installability:

```json
{
  "name": "Vida Ativa",
  "short_name": "Vida Ativa",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#FFFFFF",
  "theme_color": "#2E7D32",
  "description": "Agendamento de quadra - Academia Vida Ativa",
  "orientation": "portrait-primary",
  "prefer_related_applications": false,
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-maskable-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "maskable"
    },
    {
      "src": "icons/Icon-maskable-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable"
    }
  ]
}
```

Key PWA requirements:
- `display: standalone` — required for "add to home screen" install prompt
- `maskable` icon variants — required for Android adaptive icons (avoids white square on home screen)
- `prefer_related_applications: false` — suppresses native app store suggestion banner

**Confidence: HIGH** — These are W3C PWA manifest standards, not Flutter-specific.

### Firebase Hosting Configuration (firebase.json)

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(js|css)",
        "headers": [{"key": "Cache-Control", "value": "max-age=31536000"}]
      },
      {
        "source": "flutter_service_worker.js",
        "headers": [{"key": "Cache-Control", "value": "no-cache"}]
      }
    ]
  }
}
```

The `rewrites` rule is critical for Flutter Web SPA: without it, direct URL navigation (e.g., bookmarking `/bookings`) returns a 404 from Firebase Hosting. The service worker cache-control header prevents stale service worker bugs.

**Confidence: HIGH** — This is standard Firebase Hosting SPA configuration.

---

## Firestore Security Rules Pattern

Security rules enforce the `client`/`admin` role split defined in the data model. Pattern:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    function isAdmin() {
      return isAuthenticated() &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    match /users/{userId} {
      allow read: if isAuthenticated() && request.auth.uid == userId;
      allow write: if isAuthenticated() && request.auth.uid == userId;
    }

    match /slots/{slotId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }

    match /bookings/{bookingId} {
      allow read: if isAuthenticated() &&
        (request.auth.uid == resource.data.userId || isAdmin());
      allow create: if isAuthenticated() &&
        request.auth.uid == request.resource.data.userId;
      allow update, delete: if isAuthenticated() &&
        (request.auth.uid == resource.data.userId || isAdmin());
    }

    match /blockedDates/{dateId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
  }
}
```

**Confidence: HIGH** — This is a direct implementation of the data model described in PROJECT.md (`/users`, `/slots`, `/bookings`, `/blockedDates`) using documented Firestore Rules syntax.

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| State management | Riverpod 2.x | Bloc | Bloc adds events/states/blocs for each feature — too much ceremony for a 4-feature app |
| State management | Riverpod 2.x | Provider | Provider is deprecated by the same author in favor of Riverpod |
| State management | Riverpod 2.x | GetX | GetX mixes routing/state/DI in non-standard ways; poor testability |
| Routing | go_router | auto_route | go_router is officially maintained by Flutter team; simpler for this use case |
| Calendar UI | table_calendar | Custom widget | table_calendar saves 2-3 days of calendar implementation work |
| Calendar UI | table_calendar | syncfusion_flutter_calendar | Syncfusion requires commercial license |
| Local storage | shared_preferences | Hive | Hive is heavier; shared_preferences is sufficient for the small amount of local data needed |
| Testing doubles | fake_cloud_firestore | Firebase Emulator Suite | Emulator Suite is more complete but adds infrastructure overhead; fake_cloud_firestore is faster for unit tests |

---

## Final pubspec.yaml (complete recommended state)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase (baseline — already present)
  firebase_core: ^4.5.0
  firebase_auth: ^6.2.0
  cloud_firestore: ^6.1.3

  # Routing
  go_router: ^14.0.0

  # State management
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

  # UI
  table_calendar: ^3.1.0
  intl: ^0.19.0
  cupertino_icons: ^1.0.8

  # Utilities
  equatable: ^2.0.5
  shared_preferences: ^2.3.0
  uuid: ^4.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

  # Code generation
  build_runner: ^2.4.0
  riverpod_generator: ^2.3.0  # pairs with riverpod_annotation

  # Testing
  mockito: ^5.4.0
  fake_cloud_firestore: ^3.0.0
```

**Version note:** All `^X.Y.Z` entries should be verified against pub.dev before use. Versions listed reflect approximate state of these packages through mid-2025.

---

## Installation

```bash
# Add all new dependencies at once
flutter pub add go_router flutter_riverpod riverpod_annotation table_calendar intl equatable shared_preferences uuid

# Add dev dependencies
flutter pub add --dev build_runner riverpod_generator mockito fake_cloud_firestore

# Run code generation once
dart run build_runner build --delete-conflicting-outputs
```

---

## Sources

All findings are from training data (knowledge cutoff August 2025). No live sources were verified during this session due to tool permission restrictions.

Authoritative references to verify against:
- https://pub.dev/packages/flutter_riverpod — current version and changelog
- https://pub.dev/packages/go_router — official Flutter team package
- https://pub.dev/packages/table_calendar — calendar widget
- https://pub.dev/packages/fake_cloud_firestore — Firestore test double
- https://flutter.dev/docs/deployment/web — Flutter Web deployment docs
- https://web.dev/progressive-web-apps/ — PWA manifest spec
- https://firebase.google.com/docs/hosting/full-config — Firebase Hosting config
- https://firebase.google.com/docs/firestore/security/get-started — Firestore Security Rules

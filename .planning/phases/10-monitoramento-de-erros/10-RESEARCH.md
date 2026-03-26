# Phase 10: Monitoramento de Erros - Research

**Researched:** 2026-03-26
**Domain:** Error monitoring with sentry_flutter in a Flutter Web PWA
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Tool choice:** Sentry via `sentry_flutter` — only package with official Flutter Web support. Firebase Crashlytics discarded.
- **DSN storage:** `--dart-define=SENTRY_DSN=...` at build time — not hardcoded in repository.
- **Error scope:** `SentryFlutter.init()` with `appRunner` for automatic capture + `Sentry.captureException(e, stackTrace: s)` in all cubit catch blocks.
- **Cubits to instrument:** AuthCubit, ScheduleCubit, BookingCubit, AdminBookingCubit, and any other cubit with try/catch.
- **User context:** `Sentry.configureScope` sets Firebase UID on `AuthAuthenticated`; cleared on `AuthUnauthenticated`.
- **Production only:** `kReleaseMode` guard — dev errors must not reach the Sentry dashboard.
- **User account:** User does not yet have a Sentry account — plan must include manual setup steps (create account, project, obtain DSN).

### Claude's Discretion
- `environment` and `release` tags in Sentry init (e.g., `environment: 'production'`).
- Breadcrumb configuration (SDK default is sufficient).
- Performance monitoring disabled — OPS-01 is error tracking only, not performance.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| OPS-01 | Erros em produção são capturados e registrados em ferramenta de monitoramento (Sentry) | SentryFlutter.init() appRunner pattern captures Flutter framework errors automatically; Sentry.captureException in cubit catch blocks captures app-level errors; SentryUser sets context for diagnosis |
</phase_requirements>

---

## Summary

sentry_flutter 9.15.0 is the current stable release (published 7 days before this research). It supports Flutter Web officially and requires Flutter >= 3.24.0 and Dart >= 3.5.0. The project runs Flutter 3.41.5 / Dart 3.11.3, so the latest version is fully compatible.

Initialization uses `SentryFlutter.init()` with an `appRunner` callback. The SDK automatically wires `FlutterError.onError` and `PlatformDispatcher.onError` internally — no manual error zones are needed. DSN is passed via `String.fromEnvironment('SENTRY_DSN')` which reads the `--dart-define=SENTRY_DSN=...` value at compile time. On Flutter Web, the runtime environment fallback does not apply, so `--dart-define` is the only reliable mechanism.

The key integration challenge is **ordering**: Firebase initialization must complete before `SentryFlutter.init()` because `appRunner` contains `runApp()`, but Sentry must initialize before the app runs to capture startup errors. The correct pattern puts Firebase init inside the Sentry `appRunner` callback. A `kReleaseMode` guard wraps the entire Sentry block so dev errors never reach the dashboard.

**Primary recommendation:** Use `sentry_flutter: ^9.15.0`. Wrap `SentryFlutter.init()` around the existing `main()` body with a `kReleaseMode` check. The DSN resolves from `--dart-define` via `String.fromEnvironment`. Add `Sentry.captureException` to all cubit catch blocks without changing existing error-state emit flow.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| sentry_flutter | ^9.15.0 | Flutter error monitoring, Flutter Web support, user context | Only SDK with first-party Flutter Web support; Crashlytics has no web support |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| flutter/foundation.dart | (SDK) | kReleaseMode constant | Gate Sentry init to production builds only |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| sentry_flutter | firebase_crashlytics | Crashlytics does not support Flutter Web — locked out for this PWA |

**Installation:**
```bash
flutter pub add sentry_flutter
```

Or add to `pubspec.yaml` manually:
```yaml
dependencies:
  sentry_flutter: ^9.15.0
```

Then: `flutter pub get`

**Version verification:** Confirmed via pub.dev — 9.15.0 published 2026-03-19. Compatible with Dart ^3.5.0, Flutter ^3.24.0. Project is on Flutter 3.41.5 / Dart 3.11.3.

---

## Architecture Patterns

### Recommended Project Structure

No new directories required. All changes are in existing files:

```
lib/
├── main.dart              # Wrap existing main() with SentryFlutter.init()
└── features/
    └── auth/
        └── cubit/
            └── auth_cubit.dart   # Set/clear Sentry user scope
    └── booking/cubit/booking_cubit.dart   # onError: captureException
    └── admin/cubit/admin_booking_cubit.dart  # No try/catch found — streams use onError
    └── schedule/cubit/schedule_cubit.dart    # No try/catch found — streams use onError
```

### Pattern 1: SentryFlutter.init with Firebase + kReleaseMode Guard

**What:** Sentry initialization wraps `runApp`. Firebase init goes inside the `appRunner` so startup errors during Firebase init are also captured.

**When to use:** Always — this is the only supported init pattern for Flutter Web.

**Example:**
```dart
// Source: https://docs.sentry.io/platforms/flutter/
// Source: https://pub.dev/packages/sentry_flutter

import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  if (kReleaseMode) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.environment = 'production';
        options.tracesSampleRate = 0.0; // performance monitoring off
      },
      appRunner: () => _initAndRun(),
    );
  } else {
    await _initAndRun();
  }
}

Future<void> _initAndRun() async {
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    initializeDateFormatting('pt_BR'),
  ]);
  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
  }
  runApp(const VidaAtivaApp());
}
```

**Important:** `String.fromEnvironment('SENTRY_DSN')` is a compile-time constant. On Flutter Web there is no process environment, so runtime env-var fallback does not work. The value must be baked in via `--dart-define` at build time. An empty string (`''`) is valid — Sentry SDK v9 accepts empty DSN and silently disables sending events without crashing.

### Pattern 2: captureException in Cubit catch Blocks

**What:** Add Sentry capture before the existing `emit(ErrorState(...))` call. Does not change error flow.

**When to use:** Every `catch` block that currently emits an error state.

**Example:**
```dart
// Source: https://docs.sentry.io/platforms/flutter/usage/
import 'package:sentry_flutter/sentry_flutter.dart';

} catch (e, s) {
  await Sentry.captureException(e, stackTrace: s);  // add this line
  emit(AuthError('Erro ao carregar dados do usuário.'));  // existing line unchanged
}
```

**Note on `on FirebaseAuthException catch (e)`:** These are typed catches. They should also capture if they represent unexpected failures (e.g., network errors). The decision is to instrument all catch blocks.

### Pattern 3: User Context Scope — Set on Auth, Clear on Logout

**What:** Attach Firebase UID to every Sentry event. Cleared on logout so anonymous events are not attributed.

**When to use:** In `AuthCubit._onAuthStateChanged` — both the authenticated and unauthenticated branches.

**Example:**
```dart
// Source: https://docs.sentry.io/platforms/dart/guides/flutter/enriching-events/identify-user/
import 'package:sentry_flutter/sentry_flutter.dart';

// On AuthAuthenticated (after emit):
Sentry.configureScope(
  (scope) => scope.setUser(SentryUser(id: firebaseUser.uid)),
);

// On AuthUnauthenticated (after emit):
Sentry.configureScope(
  (scope) => scope.setUser(null),
);
```

**Note:** `SentryUser` accepts `id`, `username`, `email`, `ipAddress`, and custom data. Per the locked decision, use only `id` (Firebase UID) — no PII.

### Anti-Patterns to Avoid

- **Calling `SentryFlutter.init()` without `appRunner`:** If you call `runApp()` outside `appRunner`, Flutter framework errors that occur during startup may not be captured.
- **Hardcoding DSN in source:** Always use `String.fromEnvironment('SENTRY_DSN')`.
- **Initializing Sentry in debug mode:** Causes noise in the Sentry dashboard; blocked by `kReleaseMode` guard.
- **Swallowing stacktrace:** Always pass `stackTrace: s` (second catch argument) to `captureException` — without it, stack traces are useless for diagnosis.
- **Calling `Sentry.configureScope` before init:** If Sentry is not initialized (debug mode), scope calls are no-ops and safe. But the `kReleaseMode` guard means scope calls in AuthCubit will fire even in debug mode — this is safe because Sentry ignores them when not initialized.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Unhandled exception capture | Custom FlutterError.onError override | SentryFlutter.init() with appRunner | SDK wires both FlutterError.onError and PlatformDispatcher.onError automatically |
| Error aggregation & deduplication | Custom backend logger | Sentry dashboard | Sentry groups by fingerprint, shows occurrence counts, affected users |
| Stack trace symbolication | Manual source map upload | Sentry Dart Plugin (optional for web) | Minified web stack traces need debug IDs — handled by sentry_dart_plugin 3.0.0+ |

**Key insight:** The Flutter SDK's automatic wiring handles the two separate error channels in Flutter (sync widget errors via FlutterError.onError, async isolate errors via PlatformDispatcher.onError). Replicating this correctly from scratch is error-prone.

---

## Common Pitfalls

### Pitfall 1: Empty DSN Blocks App Startup (Historical — Fixed)

**What goes wrong:** In old versions (pre-fix for issue #326), passing `''` as DSN would cause `appRunner` to never execute, freezing the app.

**Why it happens:** SDK returned early without calling `appRunner` if DSN was invalid.

**How to avoid:** This is fixed in current sentry_flutter. However, the `kReleaseMode` guard pattern (only calling `SentryFlutter.init()` in release) eliminates this entirely — dev builds bypass Sentry init and call `_initAndRun()` directly.

**Warning signs:** App never reaches `runApp()` in release build.

### Pitfall 2: String.fromEnvironment Requires Compile-Time --dart-define

**What goes wrong:** DSN reads as empty string `''` in production build.

**Why it happens:** `String.fromEnvironment` is resolved at compile time, not runtime. Forgetting `--dart-define=SENTRY_DSN=...` in the `flutter build web` command means DSN is always `''` and no events are sent.

**How to avoid:** Update the build/deploy command to include `--dart-define=SENTRY_DSN=$SENTRY_DSN`. Document this in the README or CI config.

**Warning signs:** Sentry dashboard shows no events even after a known error occurs in production.

### Pitfall 3: Flutter Web Has No Isolate Error Capture

**What goes wrong:** Unhandled errors in background isolates are not captured on Flutter Web.

**Why it happens:** The Sentry docs explicitly state: "Current Isolate errors are captured automatically (Only for non-Web Apps)."

**How to avoid:** For this project, all async Firestore work is in the main isolate. No background isolates are used. This pitfall does not apply to the current codebase.

### Pitfall 4: Stack Traces Unreadable on Flutter Web (Minified)

**What goes wrong:** Stack traces in Sentry show minified JS names, making them unreadable.

**Why it happens:** `flutter build web` minifies Dart-to-JS output. Without source maps, symbols are unresolvable.

**How to avoid:** For this phase, basic error capture is sufficient (OPS-01 acceptance criteria). Stack trace readability improvement via `sentry_dart_plugin` is a future enhancement. The current scope captures errors with platform, app version, and user context — sufficient for diagnosis of most production issues.

**Warning signs:** Sentry events show frames like `minified$a.b$c` with no file paths.

### Pitfall 5: Sentry.configureScope in Debug Mode

**What goes wrong:** Developer wonders why scope calls in AuthCubit run even in debug mode.

**Why it happens:** The `kReleaseMode` guard only wraps `SentryFlutter.init()`. The scope calls in AuthCubit are unconditional. Sentry is not initialized in debug mode so scope calls are no-ops — safe but potentially confusing.

**How to avoid:** This is correct behavior. No fix needed. Optionally wrap scope calls with `if (kReleaseMode)` for clarity, but it is not required.

---

## Code Examples

Verified patterns from official sources:

### Complete main.dart Integration

```dart
// Source: https://pub.dev/packages/sentry_flutter + project-specific pattern
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/cubit/auth_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  if (kReleaseMode) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.environment = 'production';
        options.tracesSampleRate = 0.0;
      },
      appRunner: _initAndRun,
    );
  } else {
    await _initAndRun();
  }
}

Future<void> _initAndRun() async {
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    initializeDateFormatting('pt_BR'),
  ]);
  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
  }
  runApp(const VidaAtivaApp());
}
```

### AuthCubit: Set/Clear Sentry User Scope

```dart
// Source: https://docs.sentry.io/platforms/dart/guides/flutter/enriching-events/identify-user/
Future<void> _onAuthStateChanged(User? firebaseUser) async {
  if (firebaseUser == null) {
    emit(const AuthUnauthenticated());
    Sentry.configureScope((scope) => scope.setUser(null));  // clear scope on logout
    return;
  }

  try {
    final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
    // ... existing logic ...
    emit(AuthAuthenticated(user));
    Sentry.configureScope(
      (scope) => scope.setUser(SentryUser(id: firebaseUser.uid)),
    );
  } catch (e, s) {
    await Sentry.captureException(e, stackTrace: s);  // new
    emit(AuthError('Erro ao carregar dados do usuário.'));
  }
}
```

### Generic Cubit catch Block Pattern

```dart
// Source: https://docs.sentry.io/platforms/flutter/usage/
} catch (e, s) {
  await Sentry.captureException(e, stackTrace: s);
  emit(SomeErrorState('Mensagem de erro.'));
}
```

### Stream onError Pattern (for cubits using .listen)

```dart
// BookingCubit and AdminBookingCubit use stream .listen() with onError callbacks
// These are NOT try/catch blocks — they use onError lambdas

// Pattern for onError in stream listener:
onError: (e, s) {
  Sentry.captureException(e, stackTrace: s);  // add
  emit(const BookingError('Erro ao carregar reservas.'));  // existing
},
```

Note: `onError` in Dart stream listeners receives `(Object error, StackTrace stackTrace)`. Both parameters are available.

### Build Command with DSN

```bash
# Development (no Sentry — kReleaseMode is false)
flutter run

# Production build
flutter build web --release --dart-define=SENTRY_DSN=https://YOUR_KEY@oXXXXX.ingest.sentry.io/PROJECT_ID

# Deploy with Sentry DSN (update existing deploy command)
flutter build web --release --dart-define=SENTRY_DSN=$SENTRY_DSN && firebase deploy --only hosting,firestore:rules
```

---

## Cubit Audit Results

Based on code inspection, here are all catch/error locations requiring `Sentry.captureException`:

### AuthCubit (`lib/features/auth/cubit/auth_cubit.dart`)

| Location | Type | stackTrace available? |
|----------|------|-----------------------|
| `_onAuthStateChanged` line 52 | `catch (e)` | No — change to `catch (e, s)` |
| `signInWithGoogle` line 76 | `on FirebaseAuthException catch (e)` | No — change to `catch (e, s)` |
| `signInWithGoogle` line 78 | `catch (e)` | No — change to `catch (e, s)` |
| `signInWithEmailPassword` line 88 | `on FirebaseAuthException catch (e)` | No — change to `catch (e, s)` |
| `signInWithEmailPassword` line 90 | `catch (e)` | No — change to `catch (e, s)` |
| `registerWithEmailPassword` line 122 | `on FirebaseAuthException catch (e)` | No — change to `catch (e, s)` |
| `registerWithEmailPassword` line 124 | `catch (e)` | No — change to `catch (e, s)` |

### BookingCubit (`lib/features/booking/cubit/booking_cubit.dart`)

No try/catch blocks — uses stream `onError` lambda. Must instrument `_startStream` onError callback. The `bookSlot` and `cancelBooking` methods have no try/catch — errors propagate to callers (UI-level handling).

### AdminBookingCubit (`lib/features/admin/cubit/admin_booking_cubit.dart`)

No try/catch blocks — uses stream `onError` lambda. Must instrument `selectDate` onError callback.

### ScheduleCubit (`lib/features/schedule/cubit/schedule_cubit.dart`)

No try/catch blocks — uses three stream `onError` lambdas. Must instrument all three `onError` callbacks in `selectDay`.

### AdminSlotCubit (`lib/features/admin/cubit/admin_slot_cubit.dart`)

No try/catch blocks — uses stream `onError` lambda. Must instrument `_startStream` onError callback.

### AdminBlockedDateCubit (`lib/features/admin/cubit/admin_blocked_date_cubit.dart`)

No try/catch blocks — uses stream `onError` lambda. Must instrument `_startStream` onError callback.

**Key insight:** Most cubits use stream `onError` callbacks rather than try/catch. The `onError` signature in Dart stream listeners is `void Function(Object, StackTrace)` — both error and stack trace are available.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `runZonedGuarded` for Flutter error capture | `PlatformDispatcher.onError` (automatic in sentry_flutter) | Flutter 3.3+ | Simpler init; SDK handles both automatically |
| Manual FlutterError.onError assignment | Automatic via `SentryFlutter.init()` appRunner | sentry_flutter v6+ | Zero boilerplate for error wiring |
| Sentry v8 required Flutter >= 2.8 | Sentry v9 requires Flutter >= 3.24 | sentry_flutter 9.0.0 | Project on Flutter 3.41.5 — fully compatible |

**Deprecated/outdated:**
- `runZonedGuarded` pattern: still works but unnecessary with current SDK — `SentryFlutter.init()` handles it internally.
- sentry_flutter 8.x: do not use — missing Flutter Web release health, debug IDs for symbolication, and JS SDK integration added in 9.0.

---

## Open Questions

1. **Should `on FirebaseAuthException catch (e)` blocks also capture to Sentry?**
   - What we know: These are expected errors (wrong password, email-in-use) that map to user-facing messages.
   - What's unclear: Are they worth tracking in Sentry? They add noise but could indicate attacks (brute force) or misconfiguration.
   - Recommendation: Capture them — decision in CONTEXT.md says "todos os cubits' catch blocks" without exception. The planner can choose to skip typed auth exceptions if desired.

2. **Will the Sentry DSN be set in CI/CD or manually per deploy?**
   - What we know: The plan must document the build command update.
   - What's unclear: Whether the project uses a CI pipeline or manual `firebase deploy` from local.
   - Recommendation: Document both approaches; current deploy is manual (from project history).

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK) + bloc_test ^10.0.0 + mocktail ^1.0.4 |
| Config file | none — uses standard `flutter test` |
| Quick run command | `flutter test test/ --no-pub` |
| Full suite command | `flutter test test/ --no-pub --coverage` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OPS-01 | SentryFlutter.init wires error capture in production | manual-only | n/a — requires deployed prod environment with real DSN | ❌ Not testable via unit test |
| OPS-01 | Sentry.captureException called in cubit catch blocks | unit | `flutter test test/features/auth/cubit/auth_cubit_test.dart` | ❌ Wave 0 — new test needed |
| OPS-01 | Sentry.configureScope sets/clears user on auth state change | unit | `flutter test test/features/auth/cubit/auth_cubit_test.dart` | ❌ Wave 0 — new test needed |

**Note:** Per project memory (`feedback_no_tests.md`), this project does NOT generate unit or widget tests. The validation architecture section is included for completeness but the Wave 0 gaps below should NOT be created.

### Sampling Rate
- **Per task commit:** `flutter test test/ --no-pub` (if tests exist)
- **Per wave merge:** `flutter test test/ --no-pub --coverage`
- **Phase gate:** Manual verification — trigger a known exception in production and confirm Sentry dashboard receives it.

### Wave 0 Gaps

None — per project convention, no unit or widget tests are generated for this project (`feedback_no_tests.md`). Phase validation is manual: deploy with DSN, trigger exception, verify Sentry receives it.

---

## Sources

### Primary (HIGH confidence)
- `https://pub.dev/packages/sentry_flutter` — version 9.15.0 confirmed, Flutter Web support, installation
- `https://docs.sentry.io/platforms/flutter/` — SentryFlutter.init appRunner pattern, error handling automatic wiring
- `https://docs.sentry.io/platforms/flutter/configuration/options/` — dsn, environment, tracesSampleRate options
- `https://docs.sentry.io/platforms/flutter/configuration/releases/` — --dart-define for SENTRY_DSN on Flutter Web
- `https://docs.sentry.io/platforms/dart/guides/flutter/enriching-events/identify-user/` — SentryUser, configureScope, setUser(null)
- `https://pub.dev/packages/sentry_flutter/changelog` — v9.0.0 minimum Flutter 3.24 / Dart 3.5 confirmed

### Secondary (MEDIUM confidence)
- `https://github.com/getsentry/sentry-dart/issues/326` — empty DSN fix confirmed merged (PR #327)
- WebSearch result: "Current Isolate errors captured Only for non-Web Apps" — confirmed via official features page
- WebSearch result: Flutter Web caveats — minified stack traces, no WASM symbolication, no offline caching — verified via `https://docs.sentry.io/platforms/flutter/features/`

### Tertiary (LOW confidence)
- None — all critical claims verified via official sources.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — version confirmed on pub.dev, Flutter 3.41.5 compatibility verified
- Architecture: HIGH — patterns from official Sentry Flutter docs + code inspection of existing cubits
- Pitfalls: HIGH — verified via official docs + resolved GitHub issues

**Research date:** 2026-03-26
**Valid until:** 2026-04-25 (30 days — sentry_flutter releases frequently but API is stable in v9.x)

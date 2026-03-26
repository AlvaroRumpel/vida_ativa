---
phase: 10-monitoramento-de-erros
plan: "01"
subsystem: observability
tags: [sentry, error-monitoring, auth, flutter]
dependency_graph:
  requires: []
  provides: [sentry-sdk-init, auth-sentry-instrumentation]
  affects: [lib/main.dart, lib/features/auth/cubit/auth_cubit.dart]
tech_stack:
  added: [sentry_flutter ^9.15.0]
  patterns: [kReleaseMode guard, String.fromEnvironment DSN, SentryFlutter.init with appRunner]
key_files:
  created: []
  modified:
    - pubspec.yaml
    - lib/main.dart
    - lib/features/auth/cubit/auth_cubit.dart
decisions:
  - "Sentry DSN passed via --dart-define=SENTRY_DSN at build time — never stored in source code"
  - "Sentry bypassed entirely in debug/profile modes (kReleaseMode guard) — no DSN noise in dashboard"
  - "tracesSampleRate set to 0.0 — performance tracing disabled, error-only monitoring"
  - "SentryUser set with Firebase UID only — no PII (email/name) sent to Sentry"
metrics:
  duration: "3 min"
  completed_date: "2026-03-26"
  tasks_completed: 2
  files_modified: 3
---

# Phase 10 Plan 01: Sentry SDK Init + AuthCubit Instrumentation Summary

Sentry error monitoring integrated with kReleaseMode guard, DSN from build-time dart-define, and full AuthCubit user scope + exception capture across all 7 catch blocks.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Add sentry_flutter and restructure main.dart | 518f251 | pubspec.yaml, pubspec.lock, lib/main.dart |
| 2 | Instrument AuthCubit with Sentry scope and captureException | cb3054a | lib/features/auth/cubit/auth_cubit.dart |

## What Was Built

### Task 1: Sentry SDK initialization in main.dart

- `sentry_flutter: ^9.15.0` added to `pubspec.yaml`
- `kReleaseMode` added to the existing `foundation.dart` import (single import line)
- `main()` converted to `Future<void>` with conditional Sentry init:
  - Release builds: `SentryFlutter.init()` with `appRunner: _initAndRun`, DSN from `String.fromEnvironment('SENTRY_DSN')`, `tracesSampleRate: 0.0`, `environment: 'production'`
  - Non-release builds: calls `_initAndRun()` directly, no Sentry overhead
- `_initAndRun()` helper extracted: contains Firebase init, locale formatting, Firestore web settings, and `runApp()`

### Task 2: AuthCubit Sentry instrumentation

- `sentry_flutter` import added
- `_onAuthStateChanged`: scope cleared with `setUser(null)` on null user; scope set with `SentryUser(id: uid)` after both `AuthAuthenticated` emit paths; catch upgraded to `(e, s)` with `captureException`
- `signInWithGoogle`: both `FirebaseAuthException` and generic catch upgraded to `(e, s)` with `captureException`
- `signInWithEmailPassword`: same pattern
- `registerWithEmailPassword`: same pattern
- Totals: 3 `configureScope` calls, 2 `SentryUser` constructions, 7 `captureException` calls, 0 bare `catch (e)` remaining

## Deviations from Plan

None - plan executed exactly as written.

## Checkpoint Handling

**Checkpoint: Create Sentry account and obtain DSN** — Auto-approved (auto_advance=true in config.json). This is an external setup step; the DSN is passed at build time via `--dart-define=SENTRY_DSN=...` and is not required for code compilation or analysis.

## Production Build Command

Once the Sentry DSN is obtained from sentry.io, use:
```
flutter build web --release --dart-define=SENTRY_DSN=https://YOUR_KEY@oXXXXX.ingest.sentry.io/PROJECT_ID
```

## Self-Check: PASSED

Files exist:
- pubspec.yaml — FOUND (sentry_flutter: ^9.15.0)
- lib/main.dart — FOUND (SentryFlutter.init, kReleaseMode, _initAndRun)
- lib/features/auth/cubit/auth_cubit.dart — FOUND (7 captureException, 3 configureScope)

Commits exist:
- 518f251 — FOUND
- cb3054a — FOUND

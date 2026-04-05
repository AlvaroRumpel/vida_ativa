---
phase: 16-push-notifications-admin
plan: "01"
subsystem: notifications
tags: [fcm, push-notifications, cloud-functions, service-worker, firebase-messaging]
dependency_graph:
  requires: []
  provides: [firebase_messaging_package, fcm_service_worker_generator, cloud_function_booking_trigger]
  affects: [pubspec.yaml, firebase.json, scripts/, functions/, web/]
tech_stack:
  added: [firebase_messaging ^16.1.2, firebase-admin ^13.0.0, firebase-functions ^6.0.0]
  patterns: [Cloud Functions v2 onDocumentCreated trigger, FCM sendEachForMulticast, compat SDK service worker via importScripts]
key_files:
  created:
    - scripts/generate-sw.js
    - functions/index.js
    - functions/package.json
  modified:
    - pubspec.yaml
    - firebase.json
    - .gitignore
decisions:
  - "firebase_messaging bumped to ^16.1.2 (from ^15.2.5) — version conflict with firebase_auth ^6.2.0 and firebase_core ^4.5.0 required the upgrade"
  - "web/firebase-messaging-sw.js added to .gitignore — generated artifact, not source; scripts/generate-sw.js is the source of truth"
  - "Service worker uses compat SDK (importScripts) not ESM — required for service worker context where dynamic import is unavailable"
  - "functions/node_modules/ added to .gitignore"
metrics:
  duration: "5 min"
  completed_date: "2026-04-04"
  tasks_completed: 3
  files_changed: 6
---

# Phase 16 Plan 01: FCM Infrastructure Setup Summary

FCM backend foundations: firebase_messaging added to Flutter, env-aware service worker generator script created, and Cloud Functions project with Firestore booking trigger that sends push notifications to admin users.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Add firebase_messaging to pubspec.yaml | 8b78016 | pubspec.yaml, pubspec.lock |
| 2 | Create generate-sw.js pre-build script | d917850 | scripts/generate-sw.js, .gitignore |
| 3 | Create Cloud Functions project with booking trigger | 6828a0e | functions/index.js, functions/package.json, functions/package-lock.json, firebase.json, .gitignore |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] firebase_messaging version bumped from ^15.2.5 to ^16.1.2**
- **Found during:** Task 1
- **Issue:** `flutter pub get` failed — `firebase_messaging ^15.2.5` incompatible with `firebase_auth ^6.2.0` and `firebase_core ^4.5.0` due to transitive `firebase_core_platform_interface` version conflict
- **Fix:** Upgraded to `^16.1.2` as suggested by the Flutter pub solver
- **Files modified:** pubspec.yaml
- **Commit:** 8b78016

## Verification Results

- `flutter analyze` — 5 warnings (all pre-existing in test files, zero errors introduced by this plan)
- `flutter pub get` — resolves successfully with firebase_messaging 16.1.2
- `node scripts/generate-sw.js staging` — generates service worker with `projectId: 'vida-ativa-staging'`
- `node scripts/generate-sw.js prod` — generates service worker with `projectId: 'vida-ativa-94ba0'`
- `node -e "require('./functions/index.js')"` — exits without syntax errors
- `functions/index.js` contains `onDocumentCreated('bookings/{bookingId}')`, `where('role', '==', 'admin')`, `sendEachForMulticast`, and invalid token cleanup

## Self-Check: PASSED

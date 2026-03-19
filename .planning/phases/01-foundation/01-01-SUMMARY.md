---
phase: 01-foundation
plan: 01
subsystem: infra
tags: [flutter, dart, firestore, flutter_bloc, go_router, equatable, pwa, firebase]

# Dependency graph
requires: []
provides:
  - Four Dart data models (UserModel, SlotModel, BookingModel, BlockedDateModel) with Firestore serialization
  - Firestore security rules denying unauthenticated writes to all collections
  - PWA manifest with Vida Ativa branding and green theme (#2E7D32)
  - Firebase Hosting SPA config with service worker no-cache header
  - flutter_bloc, go_router, equatable dependencies installed
affects: [02-auth, 03-schedule, 04-booking, 05-admin, 06-security]

# Tech tracking
tech-stack:
  added: [flutter_bloc ^9.1.1, go_router ^17.1.0, equatable ^2.0.8]
  patterns:
    - "Firestore serialization via fromFirestore(DocumentSnapshot<Map>) + toFirestore()"
    - "Equatable for value equality in all models (props list)"
    - "Deterministic BookingModel ID: {slotId}_{date} for anti-double-booking via Firestore Transaction"
    - "Document ID as data field: BlockedDateModel.date == doc.id for O(1) lookup"
    - "uid NOT in toFirestore() (document ID, not a field)"

key-files:
  created:
    - lib/core/models/user_model.dart
    - lib/core/models/slot_model.dart
    - lib/core/models/booking_model.dart
    - lib/core/models/blocked_date_model.dart
    - firestore.rules
  modified:
    - pubspec.yaml
    - pubspec.lock
    - web/manifest.json
    - firebase.json

key-decisions:
  - "flutter_bloc chosen over Riverpod per plan — BLoC pattern for state management"
  - "BookingModel.generateId() static method enforces {slotId}_{date} pattern — always use this, never Firestore .add()"
  - "Firestore rules Phase 1 bootstrap: authentication-only guards, Phase 6 adds isAdmin() role checks"
  - "price cast uses (data['price'] as num).toDouble() — Firestore returns int or double depending on stored value"
  - "Users collection stricter write rule: request.auth.uid == userId even in Phase 1"

patterns-established:
  - "Model pattern: Equatable + fromFirestore(DocumentSnapshot<Map<String, dynamic>>) + toFirestore()"
  - "ID exclusion: document IDs are never stored in toFirestore(), always retrieved from doc.id"
  - "Firestore rules: all writes require isAuthenticated(), no allow write: if true"

requirements-completed: [INFRA-01, INFRA-02, PWA-01]

# Metrics
duration: 8min
completed: 2026-03-19
---

# Phase 1 Plan 01: Foundation — Dependencies, Models, and Security Bootstrap Summary

**Four Firestore-serializable Dart models (UserModel/SlotModel/BookingModel/BlockedDateModel) with Equatable, flutter_bloc/go_router/equatable dependencies, PWA manifest branded for Vida Ativa, Firebase Hosting SPA config, and bootstrap Firestore security rules**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-19T20:17:59Z
- **Completed:** 2026-03-19T20:25:59Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Installed flutter_bloc, go_router, and equatable via `flutter pub add` — zero analyzer errors
- Created four core data models with fromFirestore/toFirestore Firestore serialization and Equatable value equality
- BookingModel uses deterministic `{slotId}_{date}` document ID via `generateId()` static method, critical for anti-double-booking Firestore transactions in Phase 4
- Updated web/manifest.json with Vida Ativa branding (name, green theme_color #2E7D32, maskable icons, standalone display)
- Configured firebase.json with SPA rewrite, long-lived cache for JS/CSS, no-cache for flutter_service_worker.js, and firestore.rules reference
- Created bootstrap firestore.rules denying unauthenticated writes to all four collections

## Task Commits

Each task was committed atomically:

1. **Task 1: Add dependencies and configure PWA manifest + Firebase Hosting** - `ac59da4` (feat)
2. **Task 2: Create four core data models with Firestore serialization** - `d841144` (feat)
3. **Task 3: Create Firestore security rules bootstrap** - `f7cf02b` (feat)

**Plan metadata:** _(pending final docs commit)_

## Files Created/Modified

- `lib/core/models/user_model.dart` - UserModel with uid/email/displayName/role/phone, isAdmin getter, Firestore serialization
- `lib/core/models/slot_model.dart` - SlotModel with dayOfWeek/startTime/price/isActive, num.toDouble() cast
- `lib/core/models/booking_model.dart` - BookingModel with deterministic ID generation, Timestamp serialization, status getters
- `lib/core/models/blocked_date_model.dart` - BlockedDateModel with date-as-doc-ID pattern
- `firestore.rules` - Bootstrap security rules: isAuthenticated() guard on all writes, stricter users write rule
- `web/manifest.json` - Vida Ativa branding, #2E7D32 theme, standalone display, maskable icons
- `firebase.json` - SPA rewrite, service worker no-cache, firestore.rules reference, flutter metadata preserved
- `pubspec.yaml` - flutter_bloc ^9.1.1, go_router ^17.1.0, equatable ^2.0.8 added
- `pubspec.lock` - Resolved dependency lockfile

## Decisions Made

- Used `(data['price'] as num).toDouble()` in SlotModel — Firestore may return int or double depending on stored value type
- Users collection has stricter Phase 1 write rule (`request.auth.uid == userId`) even before isAdmin() is implemented
- uid/date document IDs are NOT included in toFirestore() output — they're document IDs retrieved via doc.id
- BookingModel.generateId() is a static method to make the `{slotId}_{date}` convention explicit and enforced

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None — `flutter analyze lib/core/models/` reported no issues, `flutter pub get` resolved all dependencies cleanly.

## User Setup Required

None - no external service configuration required in this plan.

## Next Phase Readiness

- All four data models ready for use in Phase 2 auth (UserModel) and subsequent phases
- pubspec.yaml has flutter_bloc and go_router ready for app shell implementation in Phase 1 Plan 2
- Firestore security rules prevent unauthenticated writes from the moment rules are deployed
- firebase.json configured for SPA hosting — ready for `firebase deploy` after Phase 2

---
*Phase: 01-foundation*
*Completed: 2026-03-19*

## Self-Check: PASSED

- FOUND: lib/core/models/user_model.dart
- FOUND: lib/core/models/slot_model.dart
- FOUND: lib/core/models/booking_model.dart
- FOUND: lib/core/models/blocked_date_model.dart
- FOUND: firestore.rules
- FOUND: web/manifest.json
- FOUND: firebase.json
- FOUND: .planning/phases/01-foundation/01-01-SUMMARY.md
- FOUND: ac59da4 (Task 1 commit)
- FOUND: d841144 (Task 2 commit)
- FOUND: f7cf02b (Task 3 commit)

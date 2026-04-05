---
phase: 16-push-notifications-admin
plan: "02"
subsystem: admin-fcm
tags: [flutter, fcm, push-notifications, bloc, admin]
dependency_graph:
  requires: [16-01]
  provides: [admin-fcm-cubit, admin-screen-fcm-integration]
  affects: [lib/features/admin]
tech_stack:
  added: []
  patterns: [BlocProvider.value, StatefulWidget-owned-cubit, sealed-class-state]
key_files:
  created:
    - lib/features/admin/cubit/admin_fcm_cubit.dart
    - lib/features/admin/cubit/admin_fcm_state.dart
  modified:
    - lib/features/admin/ui/admin_screen.dart
decisions:
  - "AdminFcmCubit owned by _AdminScreenState (not route-level) — cubit lifetime matches screen lifetime"
  - "BlocProvider.value used to share already-created cubit with subtree without double-ownership"
  - "onForegroundMessage returns FirebaseMessaging.onMessage static stream — not instance member"
  - "VAPID key passed via String.fromEnvironment — defaultValue empty string, getToken(vapidKey: null) still works"
metrics:
  duration: "~2 min"
  completed_date: "2026-04-04"
  tasks_completed: 2
  files_changed: 3
---

# Phase 16 Plan 02: Flutter FCM Integration for Admin Panel Summary

AdminFcmCubit with permission request, token storage in Firestore, and token refresh listener wired into AdminScreen with permission banner and foreground SnackBar.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create AdminFcmState and AdminFcmCubit | b1e82da | admin_fcm_cubit.dart, admin_fcm_state.dart |
| 2 | Wire AdminFcmCubit into AdminScreen | 489ac01 | admin_screen.dart |

## What Was Built

**AdminFcmState** (`lib/features/admin/cubit/admin_fcm_state.dart`):
Sealed class with four variants:
- `AdminFcmInitial` — permission status not yet checked
- `AdminFcmPermissionRequired` — browser not yet asked; show banner
- `AdminFcmActive(token)` — permission granted, token stored in Firestore
- `AdminFcmDenied` — permission denied by browser

**AdminFcmCubit** (`lib/features/admin/cubit/admin_fcm_cubit.dart`):
- `init()` — checks current permission status on startup, emits appropriate state
- `requestPermission()` — requests browser permission when admin taps banner
- `_activateToken()` — retrieves FCM token (with optional VAPID key) and stores in Firestore
- `_storeTokenInFirestore(token)` — writes to `/users/{uid}/fcmTokens/{token}` with createdAt + platform
- `onTokenRefresh` listener — auto-updates Firestore when browser rotates token
- `onForegroundMessage` getter — exposes `FirebaseMessaging.onMessage` stream for UI

**AdminScreen** (`lib/features/admin/ui/admin_screen.dart`):
- Converted from `StatelessWidget` to `StatefulWidget`
- `initState` creates and initializes `AdminFcmCubit`; listens to foreground messages
- `BlocProvider.value` shares cubit with subtree
- `BlocBuilder` shows `_NotificationBanner` only when `AdminFcmPermissionRequired`
- `_NotificationBanner` has "Ativar" button that calls `requestPermission()`
- Foreground FCM messages display a SnackBar with title, body, and "Ver" dismiss action
- `dispose()` calls `_fcmCubit.close()` to cancel all stream subscriptions

## Verification

`flutter analyze` on all modified files: **zero errors**.
Full project analyze: 5 pre-existing warnings in `test/features/auth/cubit/auth_cubit_test.dart` (out of scope, unrelated to this plan).

## Deviations from Plan

**1. [Rule 1 - Bug] Fixed onForegroundMessage getter**
- **Found during:** Task 1
- **Issue:** Plan used `_messaging.onMessage` (instance property) but `onMessage` is a static stream on `FirebaseMessaging`, not an instance member
- **Fix:** Changed to `FirebaseMessaging.onMessage` (static accessor) in the getter
- **Files modified:** lib/features/admin/cubit/admin_fcm_cubit.dart
- **Commit:** b1e82da

## Self-Check: PASSED

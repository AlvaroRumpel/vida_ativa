---
phase: 02-auth
plan: 03
subsystem: auth-ui
tags: [flutter, bloc, firebase-auth, go-router, ui]
dependency_graph:
  requires: [02-01, 02-02]
  provides: [splash-screen, profile-screen, access-denied-screen, complete-auth-ui]
  affects: [lib/core/router/app_router.dart]
tech_stack:
  added: []
  patterns: [BlocBuilder, CircleAvatar-with-NetworkImage, GoRouter-FilledButton-navigation]
key_files:
  created:
    - lib/features/auth/ui/profile_screen.dart
  modified:
    - lib/features/auth/ui/splash_screen.dart
    - lib/features/auth/ui/access_denied_screen.dart
    - lib/core/router/app_router.dart
  deleted:
    - lib/features/auth/ui/profile_placeholder_screen.dart
decisions:
  - "ProfileScreen accesses FirebaseAuth.instance.currentUser?.photoURL directly since UserModel does not store photoURL — avoids changing UserModel interface"
  - "AccessDeniedScreen uses FilledButton (Material 3) instead of ElevatedButton per plan spec"
  - "SplashScreen uses AppTheme.primaryGreen constant instead of hardcoded Color literal for brand consistency"
metrics:
  duration: 5 min
  completed_date: "2026-03-20"
  tasks_completed: 3
  files_changed: 5
requirements: [AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05]
---

# Phase 02 Plan 03: Auth UI Screens Summary

**One-liner:** Green splash with brand text, profile tab with Google avatar + logout, access-denied screen with FilledButton, router fully wired to real auth screens.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Build SplashScreen, ProfileScreen, AccessDeniedScreen | fd9e794 | splash_screen.dart, profile_screen.dart, access_denied_screen.dart, (deleted profile_placeholder_screen.dart) |
| 2 | Update router to use real ProfileScreen | 8dd7c71 | app_router.dart |
| 3 | Verify complete auth flow (auto-approved) | — | — |

## What Was Built

**SplashScreen** (`lib/features/auth/ui/splash_screen.dart`):
- Background color uses `AppTheme.primaryGreen` constant (not hardcoded hex)
- Shows "Vida Ativa" (bold, white, 36px) + "Reserve sua quadra" subtitle (white70, 16px)
- `CircularProgressIndicator(color: Colors.white)` signals loading
- No navigation logic — GoRouter redirect handles all transitions

**ProfileScreen** (`lib/features/auth/ui/profile_screen.dart`):
- `BlocBuilder<AuthCubit, AuthState>` reads `AuthAuthenticated.user`
- `CircleAvatar` radius 48: Google `photoURL` via `NetworkImage` if available, else name initial on `AppTheme.primaryGreen` background
- Shows `user.displayName` (headlineSmall) and `user.email` (bodyMedium, grey)
- `OutlinedButton.icon` "Sair da conta" with `foregroundColor: Colors.red` triggers `signOut()`
- Non-authenticated state: shows loading indicator (router redirect handles navigation)

**AccessDeniedScreen** (`lib/features/auth/ui/access_denied_screen.dart`):
- `Icons.block` (64px, `Colors.red.shade300`)
- "Você não tem permissão para acessar esta área." with proper diacritics
- `FilledButton` "Voltar para Agenda" navigates to `/home`

**Router** (`lib/core/router/app_router.dart`):
- Replaced `profile_placeholder_screen.dart` import with `profile_screen.dart`
- `/profile` route builder now returns `ProfileScreen()` instead of `ProfilePlaceholderScreen()`
- No auth placeholder imports remain; only Phase 3/4/5 placeholders remain (`schedule_placeholder_screen.dart`, `my_bookings_placeholder_screen.dart`, `admin_placeholder_screen.dart`)

## Verification

- `flutter analyze lib/` — 0 issues
- `flutter test` — 18/18 tests passed

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written.

**Note on existing files:** Both `splash_screen.dart` and `access_denied_screen.dart` existed as Plan 01 placeholders and were replaced with production implementations per plan spec. The splash already had a `CircularProgressIndicator` but lacked the `AppTheme.primaryGreen` import and "Reserve sua quadra" subtitle. The access denied screen used `ElevatedButton` and `Icons.lock_outline` — updated to `FilledButton` and `Icons.block` per plan.

## Self-Check: PASSED

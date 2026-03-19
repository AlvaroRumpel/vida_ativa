---
phase: 01-foundation
plan: 02
subsystem: ui
tags: [flutter, go_router, material3, bottom-navigation, stateful-shell-route, app-theme]

# Dependency graph
requires:
  - phase: 01-foundation/01-01
    provides: "Core data models (UserModel, BookingModel, SlotModel, BlockedDateModel) and pubspec with flutter_bloc, go_router, equatable"
provides:
  - "AppTheme with Material 3 blue+green branding (primaryGreen #2E7D32, primaryBlue #0175C2)"
  - "AppShell with BottomNavigationBar (3 tabs: Agenda, Minhas Reservas, Perfil)"
  - "GoRouter with StatefulShellRoute.indexedStack for /home, /bookings, /profile"
  - "Standalone routes /login and /admin (no bottom nav)"
  - "Redirect / -> /home"
  - "5 placeholder screens in feature-first directory structure"
  - "MaterialApp.router with AppTheme applied — no Riverpod/ProviderScope"
affects: [02-auth, 03-schedule, 04-booking, 05-admin, 06-security]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "StatefulShellRoute.indexedStack for bottom nav tabs — maintains tab state across switches"
    - "AppTheme._() private constructor — all theme members are static, single file to rebrand"
    - "Feature-first directories: lib/features/{feature}/ui/ for screens"
    - "Placeholder screens as const StatelessWidgets — replaced feature-by-feature in Phase 2+"

key-files:
  created:
    - lib/core/theme/app_theme.dart
    - lib/core/router/app_router.dart
    - lib/app_shell.dart
    - lib/features/schedule/ui/schedule_placeholder_screen.dart
    - lib/features/booking/ui/my_bookings_placeholder_screen.dart
    - lib/features/auth/ui/profile_placeholder_screen.dart
    - lib/features/auth/ui/login_placeholder_screen.dart
    - lib/features/admin/ui/admin_placeholder_screen.dart
  modified:
    - lib/main.dart
    - test/widget_test.dart

key-decisions:
  - "No ProviderScope in main.dart — BLoC does not require a root wrapper unlike Riverpod; BlocProviders added at feature level in Phase 2+"
  - "MaterialApp.router replaces MaterialApp — GoRouter manages navigation stack entirely"
  - "StatefulShellRoute keeps each tab branch alive independently — tab state preserved on switch"
  - "Removed flutter/material.dart import from app_router.dart — GoRouter builder context param is sufficient without the import"
  - "/admin has no guard in Phase 1 — role check requires AuthBloc from Phase 2; comment marks the guard location"

patterns-established:
  - "Feature-first layout: lib/features/{feature}/ui/ — all screens for a feature co-located"
  - "AppTheme static access pattern: AppTheme.lightTheme, AppTheme.primaryGreen — no instantiation"
  - "GoRouter defined as top-level final — accessed directly in MaterialApp.router(routerConfig: appRouter)"

requirements-completed: [PWA-02]

# Metrics
duration: 4min
completed: 2026-03-19
---

# Phase 1 Plan 02: App Shell, GoRouter, and AppTheme Summary

**GoRouter StatefulShellRoute shell with 3-tab BottomNavigationBar, Material 3 blue+green AppTheme, and 5 placeholder screens compiled to Flutter Web**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-19T20:24:09Z
- **Completed:** 2026-03-19T20:27:31Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- App shell with BottomNavigationBar (Agenda, Minhas Reservas, Perfil) using GoRouter StatefulShellRoute.indexedStack
- AppTheme with centralized Material 3 branding (primaryGreen #2E7D32, primaryBlue #0175C2)
- All 5 placeholder screens in feature-first directory structure (schedule, booking, auth/profile, auth/login, admin)
- main.dart replaced with MaterialApp.router + AppTheme — no Riverpod, ready for BLoC in Phase 2
- flutter build web succeeds, flutter test passes

## Task Commits

Each task was committed atomically:

1. **Task 1: Create AppTheme and placeholder screens** - `9b9ceb6` (feat)
2. **Task 2: Wire go_router, app shell, and update main.dart** - `967d04a` (feat)

**Plan metadata:** (docs commit — see below)

## Files Created/Modified

- `lib/core/theme/app_theme.dart` - Material 3 ThemeData with static primaryGreen and primaryBlue constants
- `lib/core/router/app_router.dart` - GoRouter with StatefulShellRoute.indexedStack, /login, /admin, redirect /->home
- `lib/app_shell.dart` - Scaffold with BottomNavigationBar delegating to StatefulNavigationShell
- `lib/features/schedule/ui/schedule_placeholder_screen.dart` - Agenda tab placeholder
- `lib/features/booking/ui/my_bookings_placeholder_screen.dart` - Minhas Reservas tab placeholder
- `lib/features/auth/ui/profile_placeholder_screen.dart` - Perfil tab placeholder
- `lib/features/auth/ui/login_placeholder_screen.dart` - Standalone /login placeholder
- `lib/features/admin/ui/admin_placeholder_screen.dart` - Standalone /admin placeholder with AppBar
- `lib/main.dart` - Updated to MaterialApp.router with AppTheme.lightTheme (no ProviderScope)
- `test/widget_test.dart` - Updated to validate AppTheme.useMaterial3 and primaryGreen

## Decisions Made

- No ProviderScope in main.dart — flutter_bloc does not require a root wrapper; BlocProviders will be added at the feature widget tree level in Phase 2+
- Removed unused `flutter/material.dart` import from app_router.dart (auto-fixed Rule 1 — IDE warning)
- /admin route has no auth guard in Phase 1 — guard requires AuthBloc from Phase 2; location marked with comment

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed unused flutter/material.dart import from app_router.dart**
- **Found during:** Task 2 (Wire go_router, app shell)
- **Issue:** IDE flagged `package:flutter/material.dart` as unused import in app_router.dart — GoRouter builder's BuildContext is typed by go_router, not material
- **Fix:** Removed the unused import line
- **Files modified:** lib/core/router/app_router.dart
- **Verification:** flutter analyze lib/ reports no issues
- **Committed in:** 967d04a (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - unused import)
**Impact on plan:** Trivial cleanup. No scope change.

## Issues Encountered

None - plan executed without blocking issues.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- App shell complete — Phase 2 (auth) adds LoginScreen and AuthBloc replacing login_placeholder_screen.dart
- AppShell BottomNavigationBar ready — Phase 3+ replaces placeholder screens with real feature screens
- /admin route guarded in Phase 2 by adding GoRouter redirect with AuthBloc role check
- flutter build web passes — ready for Firebase Hosting deployment verification in Phase 2

---
*Phase: 01-foundation*
*Completed: 2026-03-19*

## Self-Check: PASSED

All created files verified present on disk. Both task commits (9b9ceb6, 967d04a) confirmed in git log.

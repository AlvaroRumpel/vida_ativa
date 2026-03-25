---
phase: 09-gest-o-de-usu-rios-admin
plan: 01
subsystem: auth
tags: [flutter, bloc, go_router, viewmode, admin-toggle]

# Dependency graph
requires:
  - phase: 08-compartilhamento-perfil
    provides: ProfileScreen with phone editing, AuthCubit updatePhone
provides:
  - ViewMode enum in AuthAuthenticated state (admin/client)
  - toggleViewMode() in AuthCubit for ephemeral mode switching
  - Router guard blocking /admin in client mode (redirects to /home)
  - ProfileScreen toggle: 'Visao Cliente' / 'Voltar a visao admin' buttons
affects:
  - 09-02 (admin user management — builds on same auth state)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Ephemeral view mode in BLoC state — ViewMode enum on AuthAuthenticated, toggleViewMode emits new state without Firebase roundtrip"
    - "Router guards check both user role and viewMode to control /admin access"

key-files:
  created: []
  modified:
    - lib/features/auth/cubit/auth_state.dart
    - lib/features/auth/cubit/auth_cubit.dart
    - lib/core/router/app_router.dart
    - lib/features/auth/ui/profile_screen.dart

key-decisions:
  - "ViewMode is ephemeral (in-memory BLoC state only) — not persisted to Firestore; fresh login always starts in admin mode"
  - "toggleViewMode() is a no-op for non-admin users — isAdmin check guards the method"
  - "updatePhone preserves viewMode on re-emit to avoid resetting mode during phone updates"
  - "AppShell BottomNav unchanged (3 tabs) — admin access is via ProfileScreen button, not a tab"
  - "Admin in client mode redirects to /home (not /access-denied) — cleaner UX for intentional mode switch"

patterns-established:
  - "Ephemeral state toggle: emit new AuthAuthenticated with toggled field, no Firestore write"
  - "Router guard pattern: check both user.isAdmin && viewMode for compound access control"

requirements-completed: [ADMN-07]

# Metrics
duration: 25min
completed: 2026-03-25
---

# Phase 9 Plan 1: Admin/Client View Mode Toggle Summary

**Ephemeral admin/client view mode toggle using ViewMode enum in BLoC state, with router guard blocking /admin and ProfileScreen conditional buttons**

## Performance

- **Duration:** 25 min
- **Started:** 2026-03-25T19:26:23Z
- **Completed:** 2026-03-25T19:51:12Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- ViewMode enum (admin/client) added to AuthAuthenticated state with default ViewMode.admin
- toggleViewMode() method in AuthCubit allows admin users to switch modes without logout
- Router guard updated to redirect admin-in-client-mode away from /admin to /home
- ProfileScreen shows context-aware buttons: 'Painel Admin' + 'Visao Cliente' in admin mode, 'Voltar a visao admin' in client mode
- Build succeeds with no errors

## Task Commits

Each task was committed atomically:

1. **Task 1: Add ViewMode to auth state and cubit with router guard** - `1c2b9f8` (feat)
2. **Task 2: Update ProfileScreen toggle and AppShell BottomNav** - `34bb094` (feat)

## Files Created/Modified

- `lib/features/auth/cubit/auth_state.dart` - Added ViewMode enum and viewMode field to AuthAuthenticated
- `lib/features/auth/cubit/auth_cubit.dart` - Added toggleViewMode(), fixed updatePhone to preserve viewMode
- `lib/core/router/app_router.dart` - Updated admin guard to check viewMode == ViewMode.client
- `lib/features/auth/ui/profile_screen.dart` - Conditional admin buttons based on viewMode

## Decisions Made

- ViewMode is purely ephemeral (BLoC in-memory only) — no Firestore write needed; fresh login always resets to admin mode. This keeps the feature simple and avoids schema changes.
- AppShell BottomNav needs no changes — admin access is via ProfileScreen button, not a dedicated nav tab. The "admin tab" that "disappears" per CONTEXT.md is effectively the Painel Admin button in ProfileScreen.
- Admin in client mode redirects to /home rather than /access-denied — intentional UX: the admin chose to switch, not a security violation.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- ViewMode toggle complete and building successfully
- Plan 09-02 (admin user management listing) can proceed — builds on same AuthCubit/AuthState infrastructure
- AppShell and router infrastructure unchanged, no breaking changes

## Self-Check: PASSED

- lib/features/auth/cubit/auth_state.dart: FOUND
- lib/features/auth/cubit/auth_cubit.dart: FOUND
- lib/core/router/app_router.dart: FOUND
- lib/features/auth/ui/profile_screen.dart: FOUND
- Commit 1c2b9f8: FOUND
- Commit 34bb094: FOUND

---
*Phase: 09-gest-o-de-usu-rios-admin*
*Completed: 2026-03-25*

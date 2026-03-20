---
phase: 02-auth
plan: 02
subsystem: auth
tags: [flutter, flutter_bloc, go_router, firebase_auth, material3]

# Dependency graph
requires:
  - phase: 02-auth/02-01
    provides: AuthCubit with signInWithGoogle, signInWithEmailPassword, registerWithEmailPassword, sendPasswordReset; AuthState sealed class; GoRouter with /login and /register routes

provides:
  - LoginScreen: full login UI with Google button, email/password form, forgot password, inline errors, register navigation
  - RegisterScreen: 4-field registration form (name, email, password, confirm) wired to AuthCubit
  - GoRouter /login route updated to real LoginScreen (placeholder deleted)

affects: [02-03, 02-04]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - BlocConsumer for dual listener+builder in auth screens
    - AutofillGroup wrapping form fields with typed AutofillHints
    - Inline errorText on InputDecoration for field-level error routing
    - FilledButton with AppTheme.primaryGreen for primary CTAs
    - Loading spinner inside FilledButton during AuthLoading state

key-files:
  created:
    - lib/features/auth/ui/login_screen.dart
    - lib/features/auth/ui/register_screen.dart (replaced placeholder)
  modified:
    - lib/core/router/app_router.dart

key-decisions:
  - "BlocConsumer chosen over separate BlocListener + BlocBuilder to reduce widget nesting in auth screens"
  - "Error routing uses message content inspection (toLowerCase) to assign errors to email vs password field"
  - "Loading state shows inline CircularProgressIndicator inside FilledButton rather than overlay — avoids layout shift"
  - "Google button uses Text 'G' as icon widget — no image asset dependency per CONTEXT.md decisions"

patterns-established:
  - "Auth screen pattern: BlocConsumer wrapping Scaffold body, isLoading derived from state is AuthLoading"
  - "Field error pattern: String? _fieldError state variables set via setState in listener, passed to InputDecoration.errorText"
  - "Navigation pattern: context.go('/route') for auth screen transitions (not push)"

requirements-completed: [AUTH-01, AUTH-02, AUTH-03, AUTH-04]

# Metrics
duration: 5min
completed: 2026-03-20
---

# Phase 2 Plan 02: Auth Screens Summary

**Login and Register screens with BlocConsumer inline error routing, AutofillGroup, and Google + email/password flows wired to AuthCubit**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-20T00:58:55Z
- **Completed:** 2026-03-20T01:03:55Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- LoginScreen replaces placeholder: Google sign-in at top, "ou" separator, email/password fields with AutofillHints, "Esqueci minha senha" link with empty-email guard, BlocConsumer routing AuthError to correct field, "Não tem conta? Criar" navigating to /register
- RegisterScreen replaces placeholder: 4 validated fields (name, email, password, confirm), AutofillHints.name/email/newPassword, client-side validation before calling AuthCubit, "Já tem conta? Entrar" link
- Router updated: LoginPlaceholderScreen removed, LoginScreen wired; flutter analyze lib/ reports 0 issues

## Task Commits

Each task was committed atomically:

1. **Task 1: Create LoginScreen** - `b54d213` (feat)
2. **Task 2: Create RegisterScreen and update router** - `6e43505` (feat)

**Plan metadata:** (docs commit — see below)

## Files Created/Modified
- `lib/features/auth/ui/login_screen.dart` - Full login screen: Google button, email/password form, forgot password, inline errors, branding
- `lib/features/auth/ui/register_screen.dart` - Registration screen: 4 fields with validation, AuthCubit wired, login link
- `lib/core/router/app_router.dart` - Import and builder updated from LoginPlaceholderScreen to LoginScreen
- `lib/features/auth/ui/login_placeholder_screen.dart` - Deleted

## Decisions Made
- BlocConsumer chosen over separate BlocListener + BlocBuilder to reduce widget nesting
- Error routing inspects lowercased message for keywords ('email', 'senha', 'incorretos') to assign to the correct field's errorText
- Loading state uses inline CircularProgressIndicator inside FilledButton — avoids layout shift and keeps button size stable
- Google icon uses `Text('G')` widget — no image asset, no network dependency, consistent with CONTEXT.md decisions

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed LoginPlaceholderScreen reference remaining in router builder after import swap**
- **Found during:** Task 2 (update router imports)
- **Issue:** IDE reported error: `The name 'LoginPlaceholderScreen' isn't a class` at line 77 of app_router.dart after updating only the import
- **Fix:** Updated the GoRoute builder from `LoginPlaceholderScreen()` to `LoginScreen()`
- **Files modified:** lib/core/router/app_router.dart
- **Verification:** flutter analyze lib/ reports 0 issues
- **Committed in:** 6e43505 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — bug, stale reference in router builder)
**Impact on plan:** Required fix for build correctness. No scope creep.

## Issues Encountered
None beyond the auto-fixed router reference above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Login and Register screens are production-ready and wired to AuthCubit
- GoRouter redirect logic from Plan 01 handles post-auth navigation automatically
- Ready for Phase 02-03 (Profile screen and sign-out flow)

---
*Phase: 02-auth*
*Completed: 2026-03-20*

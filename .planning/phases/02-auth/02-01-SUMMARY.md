---
plan: 02-01
phase: 02-auth
status: complete
completed: 2026-03-19
tasks_completed: 3/3
---

# Plan 02-01 Summary: AuthCubit + GoRouter Guards + BlocProvider

## What Was Built

Auth state machine, Firebase Auth integration, GoRouter auth/admin guards, and test stubs.

## Key Files Created/Modified

- `lib/features/auth/cubit/auth_state.dart` — Sealed AuthState hierarchy (AuthInitial, AuthLoading, AuthAuthenticated, AuthUnauthenticated, AuthError)
- `lib/features/auth/cubit/auth_cubit.dart` — AuthCubit with signInWithGoogle, signInWithEmailPassword, registerWithEmailPassword, sendPasswordReset, signOut; creates Firestore /users/{uid} doc on first login; maps Firebase error codes to Portuguese messages
- `lib/core/router/app_router.dart` — Rewritten as `createRouter(AuthCubit)` factory; `_AuthStateNotifier` wires cubit stream to `refreshListenable`; redirect handles: AuthInitial/Loading→/splash, unauthenticated→/login, authenticated+auth-page→/home, client+/admin→/access-denied
- `lib/main.dart` — Changed to StatefulWidget; creates AuthCubit + GoRouter in initState; provides AuthCubit via `BlocProvider.value` above MaterialApp.router
- `lib/features/auth/ui/splash_screen.dart` — Green (#2E7D32) splash with "Vida Ativa" text + spinner
- `lib/features/auth/ui/register_screen.dart` — Placeholder (replaced in Plan 02-02)
- `lib/features/auth/ui/access_denied_screen.dart` — "Acesso negado" + "Voltar para Agenda" button
- `test/features/auth/cubit/auth_cubit_test.dart` — Test stubs covering all AUTH-01..05 scenarios
- `test/core/router/app_router_test.dart` — Redirect logic test stubs

## Self-Check

- `flutter analyze lib/` → No issues found
- `flutter test test/features/auth/ test/core/router/` → 17/17 passed

## Decisions Made

- Used `sealed class AuthState` for exhaustive pattern matching
- GoRouter uses factory function (not global constant) so it can capture AuthCubit in closure
- `_AuthStateNotifier` is private to app_router.dart — not exported
- main.dart owns AuthCubit lifecycle (close() in dispose())

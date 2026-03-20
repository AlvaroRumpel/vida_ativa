---
phase: 02-auth
verified: 2026-03-19T00:00:00Z
status: human_needed
score: 17/17 must-haves verified
human_verification:
  - test: "Cold start splash then redirect"
    expected: "App shows green splash screen briefly, then redirects to /login when no session exists"
    why_human: "Cannot verify runtime Firebase authStateChanges stream timing and GoRouter redirect trigger in a static analysis pass"
  - test: "Session persistence across browser close/reopen"
    expected: "Reopening the browser tab at localhost shows splash then /home without requiring re-login"
    why_human: "Requires actual Firebase web persistence to be active at runtime; cannot verify statically"
  - test: "Google sign-in popup flow"
    expected: "Clicking 'Entrar com Google' opens a Google OAuth popup; after consent, user is authenticated and redirected to /home"
    why_human: "Requires live Firebase project with Google provider enabled and a real browser"
  - test: "Email/password wrong-password inline error"
    expected: "Entering wrong password shows red inline error below the password field, not a toast or alert"
    why_human: "BlocConsumer listener routing logic (message keyword matching) must be exercised at runtime"
  - test: "Admin route guard for client user"
    expected: "Navigating to /admin while logged in as a role='client' user shows the AccessDeniedScreen"
    why_human: "GoRouter redirect uses authCubit.state.user.isAdmin at runtime; static analysis confirms the guard code is present but execution path needs confirmation"
---

# Phase 2: Auth Verification Report

**Phase Goal:** Users can securely access their accounts using Google or email/password, and the app enforces role boundaries so only admins reach admin routes
**Verified:** 2026-03-19
**Status:** human_needed — All automated checks passed. Five runtime behaviors require human verification.
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| #  | Truth | Status | Evidence |
|----|-------|--------|---------|
| 1  | AuthCubit emits AuthAuthenticated with UserModel after successful Google sign-in | VERIFIED | `auth_cubit.dart:60-75` — `signInWithPopup(GoogleAuthProvider())`, creates Firestore doc if absent, `authStateChanges` fires → `_onAuthStateChanged` → `emit(AuthAuthenticated(UserModel.fromFirestore(doc)))` |
| 2  | AuthCubit emits AuthAuthenticated after successful email/password sign-in | VERIFIED | `auth_cubit.dart:83-93` — `signInWithEmailAndPassword`, `authStateChanges` stream fires authenticated state |
| 3  | AuthCubit emits AuthError with Portuguese message on wrong password | VERIFIED | `auth_cubit.dart:136-153` — `_mapEmailError('wrong-password')` returns `'Senha incorreta.'` |
| 4  | AuthCubit creates Firestore /users/{uid} doc on first Google login | VERIFIED | `auth_cubit.dart:63-74` — `doc.exists` check before `docRef.set(user.toFirestore())` |
| 5  | AuthCubit creates Firestore /users/{uid} doc on email registration | VERIFIED | `auth_cubit.dart:102-119` — `createUserWithEmailAndPassword`, then `_firestore.collection('users').doc(firebaseUser.uid).set(user.toFirestore())` |
| 6  | GoRouter redirects unauthenticated users to /login | VERIFIED | `app_router.dart:53` — `if (!isAuthenticated && !isOnAuthPage) return '/login'` |
| 7  | GoRouter redirects authenticated clients from /admin to /access-denied | VERIFIED | `app_router.dart:59-61` — `if (authState is AuthAuthenticated && location.startsWith('/admin')) { if (!authState.user.isAdmin) return '/access-denied'; }` |
| 8  | GoRouter sends AuthInitial/AuthLoading state to /splash | VERIFIED | `app_router.dart:44-45` — `if (authState is AuthInitial || authState is AuthLoading) { return location == '/splash' ? null : '/splash'; }` |
| 9  | Session persists via authStateChanges stream replay on cold start | VERIFIED (code) | `auth_cubit.dart:21` — constructor subscribes to `_auth.authStateChanges().listen(_onAuthStateChanged)`; Firebase web SDK replays cached auth on startup; runtime confirmation needed |
| 10 | User sees Google sign-in button at top of login screen | VERIFIED | `login_screen.dart:127-146` — `ElevatedButton.icon` with `'G'` icon and label `'Entrar com Google'` above the "ou" separator |
| 11 | User sees email/password fields and 'Esqueci minha senha' link | VERIFIED | `login_screen.dart:170-202` — email `TextField`, password `TextField`, `TextButton('Esqueci minha senha')` |
| 12 | Login errors appear inline in red below the field with the problem | VERIFIED | `login_screen.dart:37-51` — `_handleAuthError` routes message to `_emailError` or `_passwordError`; fields use `InputDecoration(errorText: _emailError/passwordError)` |
| 13 | User sees 'Vida Ativa' branding with 'Reserve sua quadra' subtitle | VERIFIED | `login_screen.dart:107-122` — `Text('Vida Ativa')` + `Text('Reserve sua quadra')` |
| 14 | User sees register screen with name, email, password, confirm password fields | VERIFIED | `register_screen.dart:106-156` — all four fields present with proper labels |
| 15 | Profile tab shows avatar with Google photo or name initial | VERIFIED | `profile_screen.dart:31-45` — `CircleAvatar` with `NetworkImage(photoURL)` when available, else name initial |
| 16 | Profile tab has 'Sair da conta' logout button | VERIFIED | `profile_screen.dart:62-69` — `OutlinedButton.icon` with `signOut()` on press |
| 17 | Client accessing /admin sees 'Acesso negado' with back button | VERIFIED | `access_denied_screen.dart:18-34` — `'Acesso negado'` text + `FilledButton('Voltar para Agenda')` calling `context.go('/home')` |

**Score:** 17/17 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/features/auth/cubit/auth_state.dart` | Sealed AuthState classes | VERIFIED | `sealed class AuthState extends Equatable` with 5 subclasses |
| `lib/features/auth/cubit/auth_cubit.dart` | AuthCubit with Firebase Auth + Firestore | VERIFIED | All 6 public methods present: signInWithGoogle, signInWithEmailPassword, registerWithEmailPassword, sendPasswordReset, signOut, close |
| `lib/core/router/app_router.dart` | GoRouter factory with auth guards | VERIFIED | `GoRouter createRouter(AuthCubit authCubit)` with refreshListenable, full redirect logic |
| `lib/main.dart` | BlocProvider above MaterialApp.router | VERIFIED | `StatefulWidget` with `BlocProvider.value(value: _authCubit)` wrapping `MaterialApp.router` |
| `lib/features/auth/ui/login_screen.dart` | Full login screen | VERIFIED | Google button, email/password form, forgot password, register link, BlocConsumer inline errors |
| `lib/features/auth/ui/register_screen.dart` | Registration screen with 4 fields | VERIFIED | name, email, password, confirm — all present with validation and AuthCubit wiring |
| `lib/features/auth/ui/splash_screen.dart` | Green splash with branding | VERIFIED | `AppTheme.primaryGreen` background, "Vida Ativa", "Reserve sua quadra", `CircularProgressIndicator` |
| `lib/features/auth/ui/profile_screen.dart` | Profile with avatar, name, email, logout | VERIFIED | `BlocBuilder`, `CircleAvatar`, displayName, email, signOut button |
| `lib/features/auth/ui/access_denied_screen.dart` | Access denied screen | VERIFIED | `Icons.block`, "Acesso negado", "Voltar para Agenda", `context.go('/home')` |
| `test/features/auth/cubit/auth_cubit_test.dart` | Unit test stubs for AuthCubit | VERIFIED | 6 groups covering all AUTH scenarios; stubs pass as empty tests |
| `test/core/router/app_router_test.dart` | Widget test stubs for GoRouter redirect | VERIFIED | `group('redirect logic')` with 5 test stubs |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `lib/main.dart` | `lib/features/auth/cubit/auth_cubit.dart` | `BlocProvider.value(value: _authCubit)` | WIRED | `main.dart:43` — exact pattern present |
| `lib/main.dart` | `lib/core/router/app_router.dart` | `createRouter(_authCubit)` | WIRED | `main.dart:33` — `_router = createRouter(_authCubit)` |
| `lib/core/router/app_router.dart` | `lib/features/auth/cubit/auth_cubit.dart` | `refreshListenable` captures cubit stream | WIRED | `app_router.dart:34,38` — `_AuthStateNotifier(authCubit)` subscribed to `cubit.stream`, passed as `refreshListenable: notifier` |
| `lib/features/auth/cubit/auth_cubit.dart` | `lib/core/models/user_model.dart` | `UserModel.fromFirestore` in `_onAuthStateChanged` | WIRED | `auth_cubit.dart:37` — `emit(AuthAuthenticated(UserModel.fromFirestore(doc)))` |
| `lib/features/auth/ui/login_screen.dart` | `lib/features/auth/cubit/auth_cubit.dart` | `context.read<AuthCubit>().signInWithGoogle()` | WIRED | `login_screen.dart:130` |
| `lib/features/auth/ui/login_screen.dart` | `lib/features/auth/cubit/auth_cubit.dart` | `context.read<AuthCubit>().signInWithEmailPassword()` | WIRED | `login_screen.dart:65` |
| `lib/features/auth/ui/register_screen.dart` | `lib/features/auth/cubit/auth_cubit.dart` | `context.read<AuthCubit>().registerWithEmailPassword()` | WIRED | `register_screen.dart:69-73` |
| `lib/features/auth/ui/login_screen.dart` | `/register` route | `context.go('/register')` | WIRED | `login_screen.dart:233` |
| `lib/features/auth/ui/profile_screen.dart` | `lib/features/auth/cubit/auth_cubit.dart` | `context.read<AuthCubit>().signOut()` | WIRED | `profile_screen.dart:63` |
| `lib/features/auth/ui/profile_screen.dart` | `lib/features/auth/cubit/auth_state.dart` | `BlocBuilder` reading `AuthAuthenticated.user` | WIRED | `profile_screen.dart:14,16,22` |
| `lib/core/router/app_router.dart` | `lib/features/auth/ui/profile_screen.dart` | `/profile` route builder | WIRED | `app_router.dart:121` — `builder: (context, state) => const ProfileScreen()` |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|---------|
| AUTH-01 | 02-01, 02-02, 02-03 | Usuário pode fazer login com conta Google | SATISFIED | `signInWithGoogle()` in AuthCubit; Google button in LoginScreen; Firestore doc creation on first login |
| AUTH-02 | 02-01, 02-02, 02-03 | Usuário pode fazer login com email e senha | SATISFIED | `signInWithEmailPassword()` in AuthCubit; email/password form in LoginScreen; Portuguese error mapping |
| AUTH-03 | 02-01, 02-02, 02-03 | Usuário pode criar conta com email e senha | SATISFIED | `registerWithEmailPassword()` in AuthCubit; RegisterScreen with 4-field form and validation |
| AUTH-04 | 02-01, 02-02, 02-03 | Usuário pode recuperar senha via link enviado por email | SATISFIED | `sendPasswordReset()` in AuthCubit; "Esqueci minha senha" link in LoginScreen calls it with email guard |
| AUTH-05 | 02-01, 02-03 | Sessão do usuário persiste entre sessões do browser | SATISFIED (code) | `authStateChanges().listen(_onAuthStateChanged)` in constructor; Firebase SDK web persistence replays cached auth on cold start → `/splash` → `/home`; runtime confirmation needed |

No orphaned requirements found. All 5 AUTH-0x requirements are claimed by the phase plans and have implementation evidence.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `test/features/auth/cubit/auth_cubit_test.dart` | 31-87 | All 17 test bodies are `// TODO: implement` stubs | Info | Tests pass (empty bodies) but provide no coverage. Acceptable for phase scaffolding; should be filled before release. |
| `test/core/router/app_router_test.dart` | 5-24 | All 5 test bodies are `// TODO: implement` stubs | Info | Same as above — scaffolding only. |

No blocker or warning-level anti-patterns found in production code (`lib/`). No placeholder screens remain in auth routes. No `return null` / empty widget stubs found in auth UI.

---

### Human Verification Required

#### 1. Cold Start — Splash then Login Redirect

**Test:** Run `flutter run -d chrome --web-port 7357` with no cached session. Observe startup sequence.
**Expected:** Green splash screen appears briefly, then app navigates to `/login` automatically.
**Why human:** GoRouter redirect triggers after `authStateChanges` emits `null` on cold start. The timing and visual transition cannot be verified statically.

#### 2. Session Persistence Across Browser Close

**Test:** Log in with email/password. Close the browser tab. Reopen `localhost:7357`.
**Expected:** App shows splash briefly, then redirects to `/home` without showing the login screen.
**Why human:** Requires Firebase web persistence (IndexedDB token cache) to be active at runtime. Static analysis confirms the `authStateChanges` subscription but cannot verify the SDK persists tokens.

#### 3. Google OAuth Popup Flow

**Test:** Click "Entrar com Google" on the login screen.
**Expected:** A Google OAuth popup opens. After selecting an account and granting consent, the popup closes and the app redirects to `/home`.
**Why human:** Requires a live Firebase project with Google provider enabled in Firebase Console > Authentication > Sign-in method. Also requires the web app's domain to be in Firebase authorized domains.

#### 4. Email/Password Wrong-Password Inline Error

**Test:** On the login screen, enter a valid email but a wrong password. Click "Entrar".
**Expected:** A red error message appears inline below the password field (not a snackbar or dialog).
**Why human:** The `_handleAuthError` message-keyword routing logic must be exercised at runtime with a real `FirebaseAuthException(code: 'wrong-password')` to confirm the error is routed to `_passwordError` (not `_emailError`).

#### 5. Admin Route Guard

**Test:** Log in as a user with `role: 'client'` in Firestore. Navigate to `localhost:7357/admin` in the URL bar.
**Expected:** The AccessDeniedScreen appears with "Acesso negado" and the "Voltar para Agenda" button.
**Why human:** The guard reads `authCubit.state.user.isAdmin` at runtime. Static analysis confirms the code path exists but runtime execution with a real user document is needed.

---

### Summary

All automated checks passed. The auth system is fully implemented with no stubs, no placeholder screens, and no orphaned wiring:

- **AuthCubit** — substantive implementation with all 6 public methods, Portuguese error mapping, Firestore doc creation/fallback, and stream lifecycle management.
- **GoRouter** — factory pattern with `refreshListenable`, all 4 redirect rules (splash, unauthenticated, authenticated-on-auth-page, admin guard).
- **main.dart** — `StatefulWidget` owning AuthCubit lifecycle, `BlocProvider.value` wiring above `MaterialApp.router`.
- **UI screens** — LoginScreen, RegisterScreen, SplashScreen, ProfileScreen, and AccessDeniedScreen are all production implementations (no placeholders remain in auth routes).
- **Requirements AUTH-01 through AUTH-05** — all satisfied by implementation evidence.

The only items requiring human action are runtime behaviors (OAuth popup, session persistence, visual transitions) that cannot be confirmed through static code analysis.

---

_Verified: 2026-03-19_
_Verifier: Claude (gsd-verifier)_

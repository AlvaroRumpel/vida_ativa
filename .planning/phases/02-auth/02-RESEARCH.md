# Phase 2: Auth - Research

**Researched:** 2026-03-19
**Domain:** Firebase Authentication (Google + email/password) + flutter_bloc AuthCubit + GoRouter auth guards
**Confidence:** HIGH

## Summary

Phase 2 builds authentication on top of a well-established foundation: `firebase_auth 6.2.0`, `flutter_bloc ^9.1.1`, and `go_router 17.1.0` are already installed and locked. The key technical challenge is wiring GoRouter's `refreshListenable` to AuthCubit's stream so that route guards re-evaluate reactively when auth state changes. This requires a thin ChangeNotifier adapter class that wraps the Cubit stream — there is no built-in `GoRouterRefreshStream` in current go_router.

For Flutter Web, Google Sign-In uses `FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider())` — the `google_sign_in` package is NOT needed on web. Firebase Auth automatically persists session to browser `localStorage` by default, satisfying AUTH-05 with zero extra code. The splash screen pattern (show spinner while `authStateChanges()` emits the first event) prevents the unauthenticated flash during cold start.

The main architectural decision is where to create the GoRouter instance: it must be created AFTER the `AuthCubit` is initialized, and the `refreshListenable` adapter must hold a reference to the cubit so the redirect callback can read its state synchronously. `BlocProvider<AuthCubit>` goes above `MaterialApp.router` in `main.dart` so the cubit is accessible both to the router and to the widget tree.

**Primary recommendation:** Use a `AuthStateChangeNotifier(ChangeNotifier)` wrapper that subscribes to `authCubit.stream` and calls `notifyListeners()` on every state change. Pass this to `GoRouter.refreshListenable`. In the redirect callback, read `authCubit.state` directly (captured via closure) to decide routing.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Tela de Login (/login)**
- Layout único com Google + email/senha na mesma tela — botão Google no topo, separador "ou", campos email e senha abaixo
- Identidade visual: nome "Vida Ativa" em fonte grande + subtítulo "Reserve sua quadra" — sem dependência de arquivo de imagem
- Link "Esqueci minha senha" aparece abaixo do campo de senha (sempre visível, não só após erro)
- Erros de login (senha errada, email não cadastrado): mensagem inline vermelha abaixo do campo com problema — sem modal ou SnackBar
- Link "Não tem conta? Criar" navega para /register

**Fluxo de Cadastro (/register)**
- Tela separada acessada pelo link na tela de login — não inline/toggle
- Campos: Nome completo, Email, Senha, Confirmar senha
- Nome vira `displayName` no UserModel e no Firebase Auth
- Role inicial: sempre `'client'` — admins são criados manualmente no Firebase Console
- Erros de validação: inline, mesma abordagem do login

**Aba Perfil (autenticado)**
- Exibe: avatar circular (foto do Google se disponível, ou inicial do nome), nome completo, email
- Botão "Sair da conta" para logout
- Read-only em Phase 2 — sem edição de nome ou dados
- Aba Perfil quando não autenticado: nunca acessível (redirect para /login)

**Redirecionamento e Guards de Rota**
- Após login bem-sucedido: sempre navega para `/home`
- Usuário não autenticado tentando acessar qualquer rota protegida (`/home`, `/bookings`, `/profile`, `/admin`): redirect para `/login`
- Usuário autenticado com role `'client'` tentando acessar `/admin`: tela "Acesso negado" — não redireciona silenciosamente
- Guard implementado no `redirect` callback do GoRouter usando `AuthCubit` state

**Cold Start / Splash**
- Enquanto Firebase Auth inicializa e verifica sessão: exibe splash screen com nome "Vida Ativa" e cor verde da marca (`#2E7D32`)
- Após auth state resolver: navega para `/home` (autenticado) ou `/login` (não autenticado)
- Evita flash de tela branca / flash de login desnecessário

**Criação do UserModel no Firestore**
- Login com Google (primeiro acesso): cria documento em `/users/{uid}` com `role: 'client'`, `displayName` e `email` do Google
- Login com Google (acesso subsequente): documento já existe — não sobrescreve
- Cadastro com email/senha: cria usuário no Firebase Auth E documento em `/users/{uid}` atomicamente (ou em sequência imediata)
- AuthCubit é responsável por esta lógica

### Claude's Discretion
- Implementação interna do AuthCubit (estados: initial, loading, authenticated, unauthenticated, error)
- Animação de transição da splash screen para o destino
- Validação de senha (comprimento mínimo, etc.)
- Layout exato do avatar (tamanho, border, fallback para inicial)

### Deferred Ideas (OUT OF SCOPE)
- Login com número de telefone (OTP) — AUTH-v2-01 já no backlog v2
- Edição de perfil (nome, telefone) — pode entrar em v2
- Foto de perfil personalizada (upload) — fora de escopo
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| AUTH-01 | Usuário pode fazer login com conta Google | `signInWithPopup(GoogleAuthProvider())` — no package needed on web; Firebase Console must have Google provider enabled |
| AUTH-02 | Usuário pode fazer login com email e senha | `signInWithEmailAndPassword()` — error codes `user-not-found` and `wrong-password` for inline messages |
| AUTH-03 | Usuário pode criar conta com email e senha | `createUserWithEmailAndPassword()` + `updateDisplayName()` + Firestore `/users/{uid}` doc creation; error code `email-already-in-use` |
| AUTH-04 | Usuário pode recuperar senha via link enviado por email | `sendPasswordResetEmail()` — single call, no extra setup needed |
| AUTH-05 | Sessão do usuário persiste entre sessões do browser | Firebase Auth persists to `localStorage` by default on web — no `setPersistence()` call needed; handled by `authStateChanges()` stream emitting cached user on cold start |
</phase_requirements>

---

## Standard Stack

### Core (all already installed — no new packages needed)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| firebase_auth | 6.2.0 (locked) | Authentication backend — Google OAuth, email/password, session persistence | Official FlutterFire package; already configured via `firebase_options.dart` |
| flutter_bloc | ^9.1.1 (locked, bloc 9.2.0 resolved) | AuthCubit state management | Already decided; pattern established in Phase 1 |
| go_router | 17.1.0 (locked) | Route guards via `redirect` callback + `refreshListenable` | Already decided; routing structure established in Phase 1 |
| cloud_firestore | 6.1.3 (locked) | Create `/users/{uid}` document on first login | Already installed; UserModel has `toFirestore()` |
| equatable | ^2.0.8 (locked) | AuthState value equality | Already installed |

### No New Dependencies Required
Google Sign-In on Flutter Web uses `FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider())` directly — the `google_sign_in` package is NOT needed and should NOT be added. On mobile platforms `google_sign_in` would be required, but this is a PWA/web-only project.

**Installation:** No new packages. All dependencies are already in `pubspec.yaml`.

## Architecture Patterns

### Recommended Project Structure
```
lib/
├── core/
│   └── router/
│       └── app_router.dart          # Add AuthCubit param + refreshListenable + redirect guard
├── features/
│   └── auth/
│       ├── cubit/
│       │   ├── auth_cubit.dart      # AuthCubit with Firebase Auth logic + Firestore writes
│       │   └── auth_state.dart      # Sealed state classes
│       └── ui/
│           ├── login_screen.dart    # Replaces login_placeholder_screen.dart
│           ├── register_screen.dart # New screen at /register
│           ├── profile_screen.dart  # Replaces profile_placeholder_screen.dart
│           ├── splash_screen.dart   # Cold start splash (initial auth state)
│           └── access_denied_screen.dart  # For clients attempting /admin
└── main.dart                        # Add BlocProvider<AuthCubit> above MaterialApp.router
```

### Pattern 1: AuthCubit States (Sealed Class)

**What:** Five distinct states covering all auth lifecycle moments.
**When to use:** Always — exhaustive switch/when on state type prevents unhandled cases.

```dart
// lib/features/auth/cubit/auth_state.dart
sealed class AuthState extends Equatable {
  const AuthState();
}

class AuthInitial extends AuthState {
  @override
  List<Object?> get props => [];
}

class AuthLoading extends AuthState {
  @override
  List<Object?> get props => [];
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  @override
  List<Object?> get props => [];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}
```

### Pattern 2: AuthCubit (Firebase Auth + Firestore)

**What:** Cubit that bridges Firebase Auth state stream to BLoC state, creates Firestore user docs.
**When to use:** Single AuthCubit for entire app, provided above the router.

```dart
// lib/features/auth/cubit/auth_cubit.dart
class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  late final StreamSubscription<User?> _authSubscription;

  AuthCubit({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(const AuthInitial()) {
    _authSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      emit(const AuthUnauthenticated());
      return;
    }
    // Load UserModel from Firestore
    final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
    if (doc.exists) {
      emit(AuthAuthenticated(UserModel.fromFirestore(doc)));
    } else {
      // Should not happen — create fallback
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> signInWithGoogle() async {
    emit(const AuthLoading());
    try {
      final provider = GoogleAuthProvider();
      final credential = await _auth.signInWithPopup(provider);
      final user = credential.user!;
      // Create Firestore doc only on first login
      final ref = _firestore.collection('users').doc(user.uid);
      final doc = await ref.get();
      if (!doc.exists) {
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          role: 'client',
        );
        await ref.set(userModel.toFirestore());
      }
      // authStateChanges() will fire and emit AuthAuthenticated
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Google sign-in failed'));
    }
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    emit(const AuthLoading());
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // authStateChanges() fires and updates state
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapEmailError(e.code)));
    }
  }

  Future<void> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(name);
      final userModel = UserModel(
        uid: user.uid,
        email: email,
        displayName: name,
        role: 'client',
      );
      await _firestore.collection('users').doc(user.uid).set(userModel.toFirestore());
      // authStateChanges() will fire
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapEmailError(e.code)));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    // authStateChanges() fires AuthUnauthenticated
  }

  String _mapEmailError(String code) {
    switch (code) {
      case 'user-not-found': return 'Email não encontrado.';
      case 'wrong-password': return 'Senha incorreta.';
      case 'email-already-in-use': return 'Email já cadastrado.';
      case 'weak-password': return 'Senha muito fraca (mínimo 6 caracteres).';
      case 'invalid-email': return 'Email inválido.';
      default: return 'Erro de autenticação. Tente novamente.';
    }
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
```

### Pattern 3: GoRouter + AuthCubit Integration (refreshListenable)

**What:** ChangeNotifier adapter bridges AuthCubit stream to GoRouter's `refreshListenable`. Router is created as a function/factory that takes the cubit as parameter so the redirect closure captures it directly.
**When to use:** This is the canonical approach for flutter_bloc + go_router auth guards.

```dart
// lib/core/router/app_router.dart

class _AuthStateNotifier extends ChangeNotifier {
  late final StreamSubscription _sub;

  _AuthStateNotifier(AuthCubit cubit) {
    _sub = cubit.stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

GoRouter createRouter(AuthCubit authCubit) {
  final notifier = _AuthStateNotifier(authCubit);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = authCubit.state;
      final location = state.matchedLocation;

      // Splash: still initializing — stay put (show splash at /splash or root)
      if (authState is AuthInitial || authState is AuthLoading) {
        return location == '/splash' ? null : '/splash';
      }

      final isAuthenticated = authState is AuthAuthenticated;
      final isOnLogin = location == '/login' || location == '/register';

      if (!isAuthenticated && !isOnLogin) return '/login';
      if (isAuthenticated && isOnLogin) return '/home';

      // Admin guard: authenticated client accessing /admin
      if (isAuthenticated && location.startsWith('/admin')) {
        final user = (authState as AuthAuthenticated).user;
        if (!user.isAdmin) return '/access-denied';
      }

      return null; // no redirect needed
    },
    routes: [
      // Splash (outside shell)
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      // Login (outside shell)
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      // Register (outside shell)
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      // Access denied (outside shell)
      GoRoute(path: '/access-denied', builder: (_, __) => const AccessDeniedScreen()),
      // Admin (outside shell)
      GoRoute(path: '/admin', builder: (_, __) => const AdminPlaceholderScreen()),
      // Main app shell with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, __) => const SchedulePlaceholderScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/bookings', builder: (_, __) => const MyBookingsPlaceholderScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
}
```

### Pattern 4: main.dart with BlocProvider above MaterialApp.router

**What:** AuthCubit must be provided above `MaterialApp.router` so the router factory can capture it in its closure and the widget tree can also `context.read<AuthCubit>()`.
**When to use:** Required — GoRouter with `refreshListenable` needs cubit created before router.

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const VidaAtivaApp());
}

class VidaAtivaApp extends StatefulWidget {
  const VidaAtivaApp({super.key});
  @override
  State<VidaAtivaApp> createState() => _VidaAtivaAppState();
}

class _VidaAtivaAppState extends State<VidaAtivaApp> {
  late final AuthCubit _authCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authCubit = AuthCubit();
    _router = createRouter(_authCubit);
  }

  @override
  void dispose() {
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authCubit,
      child: MaterialApp.router(
        title: 'Vida Ativa',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
      ),
    );
  }
}
```

### Anti-Patterns to Avoid

- **Using `const appRouter = GoRouter(...)` top-level**: Cannot inject AuthCubit — use a factory function instead.
- **Calling `context.read<AuthCubit>()` inside redirect callback**: The `context` in redirect is a `BuildContext` but it may not have the BlocProvider ancestor at evaluation time during cold start. Read from captured cubit reference instead.
- **Using `google_sign_in` package on Flutter Web**: Not needed; `FirebaseAuth.signInWithPopup()` handles Google OAuth directly.
- **Calling `setPersistence(Persistence.LOCAL)` explicitly**: It is the default on web — explicit call is redundant and can cause confusion.
- **Forgetting to cancel the StreamSubscription in `_AuthStateNotifier.dispose()`**: Causes memory leaks if router is rebuilt.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Google OAuth popup flow | Custom OAuth with `http` or JS interop | `FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider())` | Google OAuth has PKCE, CSRF tokens, redirect domain validation — hand-rolling is security-critical |
| Session persistence across browser restarts | Manual `localStorage` read/write | Firebase Auth default behavior (`authStateChanges()` replays last user on app start) | Firebase handles token refresh, expiry, and secure storage |
| Email/password error messages | Custom error table | `FirebaseAuthException.code` switch (`user-not-found`, `wrong-password`, `email-already-in-use`, `weak-password`) | Codes are Firebase's own enum-like strings — map them once |
| Password reset email | SMTP custom sending | `FirebaseAuth.sendPasswordResetEmail()` | Firebase Console manages templates, delivery, and token security |
| Route auth guard reactivity | Manual GoRouter rebuild on auth change | `refreshListenable: _AuthStateNotifier(authCubit)` | Without this, redirect only runs on navigation events, not on auth state changes |

**Key insight:** Firebase Auth on Flutter Web handles 95% of auth complexity (OAuth, sessions, token refresh). The implementation work is wiring the state machine (AuthCubit) to the UI and router correctly.

## Common Pitfalls

### Pitfall 1: Cold Start Flash (Unauthenticated UI Visible Before Auth Resolves)
**What goes wrong:** App starts at `/home`, auth state is `AuthInitial` (not yet resolved), GoRouter redirect runs and sends user to `/login`, then 500ms later Firebase emits the cached user and redirects back to `/home`. User sees a flicker.
**Why it happens:** GoRouter's `initialLocation` is evaluated before `authStateChanges()` emits the first value.
**How to avoid:** Add a `/splash` route. The redirect sends `AuthInitial` and `AuthLoading` states to `/splash`. Once `AuthAuthenticated` or `AuthUnauthenticated` emits, `refreshListenable` fires and redirect re-evaluates to send to `/home` or `/login`.
**Warning signs:** Login screen flashing briefly at startup even when user is already authenticated.

### Pitfall 2: GoRouter Redirect Not Re-Evaluating After Auth Change
**What goes wrong:** User signs in, AuthCubit emits `AuthAuthenticated`, but the router stays on `/login`.
**Why it happens:** GoRouter only re-runs redirect on navigation events UNLESS `refreshListenable` is set.
**How to avoid:** Always wire `refreshListenable: _AuthStateNotifier(authCubit)`. Verify `notifyListeners()` is called inside the stream listener.
**Warning signs:** After login, app stays on login screen until user manually navigates.

### Pitfall 3: Google Sign-In Popup Blocked or Silently Failing on Deployed URL
**What goes wrong:** Works on `localhost`, but on deployed Firebase Hosting the Google popup closes instantly or throws an OAuth error about unauthorized domain.
**Why it happens:** Firebase Console `Authentication > Sign-in method > Authorized domains` only includes `localhost` and the project's `.web.app` domain by default. Custom domains need manual addition.
**How to avoid:** After first deploy, immediately add the deployed URL to Firebase Console authorized domains. Use `flutter run --web-port 7357` with a fixed port if the Firebase Console authorized origins need an exact port.
**Warning signs:** `Error: This domain is not authorized for OAuth operations for your Firebase project.`

### Pitfall 4: Firestore User Document Not Found After Google Login
**What goes wrong:** `_onAuthStateChanged` finds the Firebase user but `doc.exists` is false momentarily — emits `AuthUnauthenticated` even though user is signed in.
**Why it happens:** There's a race condition — Firestore `.get()` completes before the `.set()` in `signInWithGoogle()` writes the doc (can happen if streams fire concurrently).
**How to avoid:** In `_onAuthStateChanged`, do NOT emit `AuthUnauthenticated` if `!doc.exists` after an authenticated user event. Instead, create the doc as a fallback (role=client), or use `AuthCubit.state` to check if we're in the middle of `signInWithGoogle`. Simplest fix: in `_onAuthStateChanged`, if `!doc.exists` for an authenticated user, create the doc then emit authenticated.
**Warning signs:** After Google login, app redirects to `/login` despite user being authenticated in Firebase Console.

### Pitfall 5: Autofill / Password Manager Not Working on Flutter Web
**What goes wrong:** Browser password manager doesn't offer to save credentials after login, or doesn't autofill on return visits.
**Why it happens:** Flutter Web's text fields need `autofillHints` to signal to the browser what type of input they are. HTML renderer was deprecated in 2025 — CanvasKit (default) has known autofill limitations.
**How to avoid:** Use `AutofillGroup` wrapping the form, set `autofillHints: [AutofillHints.email]` on email field and `autofillHints: [AutofillHints.password]` on password field. Accept that autofill behavior may be imperfect on CanvasKit — not a blocker for v1.
**Warning signs:** No browser password save prompt appears after successful login.

### Pitfall 6: refreshListenable Memory Leak
**What goes wrong:** `_AuthStateNotifier` continues listening to the cubit stream after the GoRouter is disposed.
**Why it happens:** StreamSubscription not cancelled in `dispose()`.
**How to avoid:** Always override `dispose()` in `_AuthStateNotifier`, cancel the subscription, then call `super.dispose()`.
**Warning signs:** Hot reload or widget test teardown logs `StreamSubscription was not cancelled`.

## Code Examples

### Google Sign-In on Flutter Web (no google_sign_in package)
```dart
// Source: firebase.flutter.dev/docs/auth/social/
final provider = GoogleAuthProvider();
// Optionally: provider.addScope('https://www.googleapis.com/auth/contacts.readonly');
final credential = await FirebaseAuth.instance.signInWithPopup(provider);
final user = credential.user; // non-null on success
```

### Email/Password Registration
```dart
// Source: firebase.flutter.dev/docs/auth/password-auth/
final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: emailAddress,
  password: password,
);
await credential.user?.updateDisplayName(name);
```

### Email/Password Sign-In
```dart
// Source: firebase.flutter.dev/docs/auth/password-auth/
final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: emailAddress,
  password: password,
);
```

### Password Reset
```dart
// Source: firebase.flutter.dev/docs/auth/manage-users/
await FirebaseAuth.instance.sendPasswordResetEmail(email: emailAddress);
```

### Auth State Stream (session persistence on web)
```dart
// Source: firebase.flutter.dev/docs/auth/usage/
// Default on web: persists to localStorage. No setPersistence() call needed.
FirebaseAuth.instance.authStateChanges().listen((User? user) {
  // user is non-null if logged in (even after browser restart)
  // user is null if signed out
});
```

### FirebaseAuthException Error Codes Reference
```dart
// Codes to handle in catch (FirebaseAuthException e):
// Registration: 'weak-password', 'email-already-in-use', 'invalid-email'
// Sign-in: 'user-not-found', 'wrong-password', 'invalid-email', 'user-disabled'
// General: 'network-request-failed', 'too-many-requests'
```

### Inline Error Display Pattern (no SnackBar / modal)
```dart
// In LoginScreen state — field-level error string
String? _emailError;
String? _passwordError;

// In UI — TextField decoration
TextField(
  decoration: InputDecoration(
    labelText: 'Email',
    errorText: _emailError, // shows inline in red under field
  ),
)
```

### Firestore User Doc Creation (first Google login)
```dart
// Check-then-write pattern (not transactional — acceptable here)
final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
final doc = await ref.get();
if (!doc.exists) {
  await ref.set(UserModel(
    uid: user.uid,
    email: user.email ?? '',
    displayName: user.displayName ?? '',
    role: 'client',
  ).toFirestore());
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `google_sign_in` package for web | `FirebaseAuth.signInWithPopup(GoogleAuthProvider())` directly | FlutterFire 2022+ | Simpler, no extra package on web-only projects |
| `GoRouterRefreshStream` utility class | Custom `ChangeNotifier` wrapper (or `StreamSubscription` directly) | go_router removed GoRouterRefreshStream in earlier versions | Must implement adapter manually; ~10 lines |
| HTML renderer (web) | CanvasKit only (HTML deprecated 2025) | Flutter stable Q1 2025 | No `--web-renderer=html` flag; autofill is limited |
| `StatelessWidget` for `VidaAtivaApp` | `StatefulWidget` (needed to own AuthCubit lifecycle) | Phase 2 change | Allows proper `initState` and `dispose` of cubit + router |

**Deprecated/outdated:**
- `--web-renderer=html` flag: Deprecated and removed in Flutter stable 2025. App already defaults to CanvasKit.
- `GoRouterRefreshStream`: Removed from go_router; implement ChangeNotifier wrapper manually.
- Passing `GoRouter` as top-level `const` variable: Cannot inject AuthCubit; must use factory function or late init.

## Open Questions

1. **go_router 17.0.1 requires Flutter 3.32 / Dart 3.8**
   - What we know: `go_router 17.1.0` is locked; CHANGELOG says 17.0.1 updated minimum SDK to Flutter 3.32/Dart 3.8
   - What's unclear: Whether the local Flutter SDK satisfies this constraint (pubspec.yaml shows `sdk: ^3.11.3` but that is Dart, not Flutter)
   - Recommendation: Run `flutter --version` before implementing; if below Flutter 3.32, may need to upgrade Flutter SDK or pin go_router to a lower version. That said, since Phase 1 already ran successfully with go_router 17.1.0, the SDK is likely compatible.

2. **AuthCubit listening to Firestore doc for role changes**
   - What we know: Admins are set manually in Firebase Console; no real-time Firestore listener is required in Phase 2
   - What's unclear: If an admin role is assigned while the user is logged in, the `AuthAuthenticated.user.isAdmin` won't update until next login
   - Recommendation: Accept this limitation for Phase 2; Phase 5 (Admin) can add a Firestore stream listener if needed.

3. **Flutter Web autofill on CanvasKit**
   - What we know: There are open bugs for password manager autofill on Flutter Web CanvasKit; `AutofillGroup` + `autofillHints` is the best effort
   - What's unclear: Whether Chrome/Firefox reliably show the password save prompt with the current CanvasKit renderer
   - Recommendation: Implement `AutofillGroup` + `autofillHints`; test on deployed URL; treat autofill as best-effort, not a blocker.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK built-in, already in pubspec.yaml) |
| Config file | none — uses pubspec.yaml test configuration |
| Quick run command | `flutter test test/widget_test.dart` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AUTH-01 | Google Sign-In calls signInWithPopup and creates Firestore doc | unit (mocked FirebaseAuth) | `flutter test test/features/auth/cubit/auth_cubit_test.dart -x` | ❌ Wave 0 |
| AUTH-02 | signInWithEmailPassword emits AuthAuthenticated on success | unit | `flutter test test/features/auth/cubit/auth_cubit_test.dart -x` | ❌ Wave 0 |
| AUTH-02 | Wrong password emits AuthError with correct message | unit | `flutter test test/features/auth/cubit/auth_cubit_test.dart -x` | ❌ Wave 0 |
| AUTH-03 | registerWithEmailPassword creates FirebaseAuth user + Firestore doc | unit | `flutter test test/features/auth/cubit/auth_cubit_test.dart -x` | ❌ Wave 0 |
| AUTH-04 | sendPasswordReset calls FirebaseAuth.sendPasswordResetEmail | unit | `flutter test test/features/auth/cubit/auth_cubit_test.dart -x` | ❌ Wave 0 |
| AUTH-05 | authStateChanges emits cached user on cold start (mocked) | unit | `flutter test test/features/auth/cubit/auth_cubit_test.dart -x` | ❌ Wave 0 |
| AUTH-* | GoRouter redirect sends unauthenticated user to /login | widget | `flutter test test/core/router/app_router_test.dart -x` | ❌ Wave 0 |
| AUTH-* | GoRouter redirect sends client from /admin to /access-denied | widget | `flutter test test/core/router/app_router_test.dart -x` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/features/auth/cubit/auth_cubit_test.dart`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/features/auth/cubit/auth_cubit_test.dart` — covers AUTH-01 through AUTH-05 (mocked FirebaseAuth + Firestore)
- [ ] `test/core/router/app_router_test.dart` — covers GoRouter redirect logic with mocked AuthCubit states
- [ ] `test/features/auth/` directory structure

---

## Sources

### Primary (HIGH confidence)
- firebase.flutter.dev/docs/auth/social/ — Google Sign-In on web: `signInWithPopup(GoogleAuthProvider())`
- firebase.flutter.dev/docs/auth/password-auth/ — `createUserWithEmailAndPassword`, `signInWithEmailAndPassword`, error codes
- firebase.flutter.dev/docs/auth/manage-users/ — `sendPasswordResetEmail`, `updateDisplayName`
- firebase.flutter.dev/docs/auth/usage/ — `authStateChanges()` stream, session persistence defaults
- pub.dev/packages/go_router/changelog — go_router 17.x changelog; 16.2.5 fix for `GoRouter.of(context)` in redirect; 17.0.0 breaking change for ShellRoute observers

### Secondary (MEDIUM confidence)
- codegenes.net/blog/how-to-use-flutter-bloc-with-go-router/ — BlocRefreshListenable ChangeNotifier wrapper pattern + GoRouter redirect reading from bloc state
- firebase.google.com/docs/auth/web/auth-state-persistence — web localStorage default persistence behavior

### Tertiary (LOW confidence — flagged for validation)
- github.com/flutter/flutter/issues/175398 — refreshListenable regression report (closed as duplicate of documentation issue; unclear if fixed in 17.x)
- Multiple community articles (Medium, 2024-2025) on flutter_bloc + GoRouter auth pattern — consistent with verified patterns above

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages already installed and locked; no new dependencies
- Architecture patterns: HIGH — AuthCubit states, Firebase Auth API, ChangeNotifier adapter all verified against official docs
- Pitfalls: HIGH for cold start flash, authorized domains, session persistence; MEDIUM for autofill limitations (open Flutter bugs, CanvasKit behavior)
- Router integration: MEDIUM — `refreshListenable` pattern is consistent across community sources but no official go_router example specifically for flutter_bloc

**Research date:** 2026-03-19
**Valid until:** 2026-06-19 (stable ecosystem; firebase_auth + go_router APIs rarely change at patch level)

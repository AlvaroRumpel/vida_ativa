---
phase: 2
slug: auth
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-19
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (SDK built-in, already in pubspec.yaml) |
| **Config file** | none — uses pubspec.yaml test configuration |
| **Quick run command** | `flutter test test/features/auth/cubit/auth_cubit_test.dart` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/features/auth/cubit/auth_cubit_test.dart`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 2-01-01 | 01 | 0 | AUTH-01..05 | unit | `flutter test test/features/auth/cubit/auth_cubit_test.dart` | ❌ W0 | ⬜ pending |
| 2-01-02 | 01 | 0 | AUTH-* | widget | `flutter test test/core/router/app_router_test.dart` | ❌ W0 | ⬜ pending |
| 2-01-03 | 01 | 1 | AUTH-01..05 | unit | `flutter test test/features/auth/cubit/auth_cubit_test.dart` | ✅ W0 | ⬜ pending |
| 2-02-01 | 02 | 2 | AUTH-01,02,03 | unit | `flutter test test/features/auth/cubit/auth_cubit_test.dart` | ✅ W0 | ⬜ pending |
| 2-02-02 | 02 | 2 | AUTH-01,02,03 | widget | `flutter test` | ✅ W0 | ⬜ pending |
| 2-03-01 | 03 | 3 | AUTH-04 | unit | `flutter test test/features/auth/cubit/auth_cubit_test.dart` | ✅ W0 | ⬜ pending |
| 2-03-02 | 03 | 3 | AUTH-* | widget | `flutter test test/core/router/app_router_test.dart` | ✅ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/features/auth/cubit/auth_cubit_test.dart` — stubs for AUTH-01 through AUTH-05 (mocked FirebaseAuth + Firestore)
- [ ] `test/core/router/app_router_test.dart` — GoRouter redirect logic with mocked AuthCubit states
- [ ] `test/features/auth/` — directory structure created

*All test files are Wave 0 gaps — must be created before implementation tasks run.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Google popup opens in browser | AUTH-01 | Real OAuth flow requires deployed URL and browser interaction | Deploy to Firebase Hosting, open app, tap "Entrar com Google", verify popup appears |
| Password reset email received | AUTH-04 | Requires real email delivery | Use real email address, trigger reset, check inbox |
| Session persists after browser close | AUTH-05 | Requires real browser close/reopen | Log in, close browser completely, reopen, verify still logged in |
| Splash → home transition on cold start | AUTH-05 | Requires real Firebase cold start | Clear browser storage, open app, verify splash shows then resolves to /home |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

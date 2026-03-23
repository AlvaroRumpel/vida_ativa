---
phase: 6
slug: pwa-hardening
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-23
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (SDK built-in), bloc_test ^10.0.0 |
| **Config file** | none — uses `flutter test` directly |
| **Quick run command** | `flutter test test/ --no-pub` |
| **Full suite command** | `flutter test --no-pub` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/ --no-pub`
- **After every plan wave:** Run `flutter test --no-pub`
- **Before `/gsd:verify-work`:** Full suite must be green + manual Firestore Rules Simulator check
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 06-01-01 | 01 | 1 | INFRA-01 | manual | Firebase Rules Simulator | N/A | ⬜ pending |
| 06-01-02 | 01 | 1 | PWA-01 | manual file check | `grep "Vida Ativa" web/index.html` | ✅ | ⬜ pending |
| 06-02-01 | 02 | 1 | PWA-01 | unit | `flutter test test/core/pwa/ios_install_detector_test.dart` | ❌ W0 | ⬜ pending |
| 06-02-02 | 02 | 1 | PWA-01 | manual | iOS Safari device check | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/core/pwa/ios_install_detector_test.dart` — unit test stubs for `isIosInstallBannerNeeded()` covering iOS UA returns true, non-iOS UA returns false

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Unauthenticated users cannot write anything | INFRA-01 | Requires Firebase Rules Simulator or real Firebase project | Use Firebase Console → Firestore → Rules Playground; attempt writes without auth |
| Client cannot write other users' bookings | INFRA-01 | Requires Rules Simulator with specific auth context | Simulate write to `/bookings/{id}` with userId ≠ auth.uid |
| Admin write gated by `isAdmin()` | INFRA-01 | Requires Rules Simulator reading /users doc | Simulate slot write with user where role=="admin" vs role=="client" |
| iOS banner shows in iOS Safari without standalone | PWA-01 | Requires real iOS device or Xcode Simulator + Safari | Open app in iOS Safari, verify SnackBar appears |
| `apple-mobile-web-app-title` = "Vida Ativa" | PWA-01 | File inspection | `grep "Vida Ativa" web/index.html` — must appear in meta tag AND title |
| `firebase deploy` produces working production URL | INFRA-01 | Requires Firebase CLI + real project | Run deploy command, verify `vida-ativa-94ba0.web.app` loads correctly |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

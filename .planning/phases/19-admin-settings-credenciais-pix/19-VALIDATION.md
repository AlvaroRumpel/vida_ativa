---
phase: 19
slug: admin-settings-credenciais-pix
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-07
---

# Phase 19 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | N/A — No unit tests per project policy (feedback_no_tests.md) |
| **Config file** | none |
| **Quick run command** | `flutter analyze` |
| **Full suite command** | `flutter analyze && flutter build web --no-tree-shake-icons` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze`
- **After every plan wave:** Run `flutter analyze && flutter build web`
- **Before `/gsd-verify-work`:** Full build must pass
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 19-01-01 | 01 | 1 | D-08/D-09 | T-19-01 | config/mercadopago not readable by client | manual | Firestore rules check | ✅ rules | ⬜ pending |
| 19-01-02 | 01 | 1 | D-11 | T-19-02 | CF reads Firestore token before Secret Manager | manual | CF deploy + test call | N/A | ⬜ pending |
| 19-02-01 | 02 | 2 | D-01/D-02 | — | SettingsTab renders in admin panel | manual | Flutter web app | N/A | ⬜ pending |
| 19-02-02 | 02 | 2 | D-05/D-06 | T-19-03 | Token field masked; no readback to Flutter | manual | UI inspection | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements. No new test files needed per project policy.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Admin saves token → Firestore updated | D-07 | No unit tests in scope | Check Firestore console: config/mercadopago.accessToken exists after save |
| Token field never shows saved value | D-06 | UI state behavior | Load SettingsTab after saving: field shows placeholder not token value |
| Client cannot read config/mercadopago | D-09 | Security rule | Test in Firestore emulator or Rules Playground: client read returns permission-denied |
| CF uses Firestore token for Pix payment | D-11 | Integration test | Make Pix payment after setting token via UI: QR generated successfully |
| pixEnabled toggle works from Config tab | D-02 | UI integration | Toggle off → booking screen hides Pix option |

---

## Validation Sign-Off

- [ ] All tasks have manual verify or are flutter-analyze verifiable
- [ ] Security rules tested before phase complete
- [ ] CF fallback behavior tested (Firestore → Secret Manager)
- [ ] `nyquist_compliant: true` set in frontmatter after completion

**Approval:** pending

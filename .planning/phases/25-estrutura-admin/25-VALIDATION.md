---
phase: 25
slug: estrutura-admin
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-26
---

# Phase 25 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter test (built-in) |
| **Config file** | none — existing test infrastructure |
| **Quick run command** | `flutter analyze --no-fatal-infos` |
| **Full suite command** | `flutter build web --release` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze --no-fatal-infos`
- **After every plan wave:** Run `flutter build web --release`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 25-01-01 | 01 | 1 | ADMN-13 | — | N/A | analyze | `flutter analyze --no-fatal-infos` | ✅ | ⬜ pending |
| 25-01-02 | 01 | 1 | ADMN-14 | — | N/A | analyze | `flutter analyze --no-fatal-infos` | ✅ | ⬜ pending |
| 25-01-03 | 01 | 1 | ADMN-15 | — | N/A | analyze | `flutter analyze --no-fatal-infos` | ✅ | ⬜ pending |
| 25-01-04 | 01 | 1 | ADMN-13,14,15 | — | N/A | build | `flutter build web --release` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| TabBar underline laranja 2px visível e fundo sand | ADMN-13 | Visual rendering | Deploy staging, navegar admin, verificar tabs |
| Header wordmark Arena + eyebrow "PAINEL ADMIN" + link "cliente →" | ADMN-14 | Visual rendering | Deploy staging, verificar header admin screen |
| Notification banner faixa laranja 2px sem fundo colorido | ADMN-15 | Visual rendering | Deploy staging, simular nova reserva, verificar banner |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

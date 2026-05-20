---
phase: 20
slug: infraestrutura-de-esporte
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-20
---

# Phase 20 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter test |
| **Config file** | none — project uses built-in flutter test runner |
| **Quick run command** | `flutter test test/unit/sport_config_cubit_test.dart` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze && flutter test test/unit/sport_config_cubit_test.dart`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 20-01-01 | 01 | 1 | SPORT-01 | — | N/A | unit | `flutter test test/unit/sport_config_cubit_test.dart` | ❌ W0 | ⬜ pending |
| 20-01-02 | 01 | 1 | SPORT-02 | — | N/A | unit | `flutter test test/unit/sport_config_cubit_test.dart` | ❌ W0 | ⬜ pending |
| 20-02-01 | 02 | 2 | SPORT-03 | — | N/A | integration | `flutter test` | ❌ W0 | ⬜ pending |
| 20-02-02 | 02 | 2 | SPORT-04 | — | N/A | unit | `flutter analyze` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/unit/sport_config_cubit_test.dart` — stubs para SPORT-01, SPORT-02
- [ ] `test/unit/booking_model_sport_test.dart` — stubs para SPORT-04

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Dropdown "Esporte (opcional)" visível na reserva | SPORT-03 | UI visual — flutter test não roda em device real | Abrir formulário de reserva e verificar dropdown presente |
| Admin reordenar esportes com drag-and-drop | SPORT-02 | Gesture drag não reproduzível via test headless | Abrir Configurações > Esportes, arrastar item e confirmar nova ordem |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

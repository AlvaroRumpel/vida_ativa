---
phase: 27
slug: admin-slots-reservas-usu-rios
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 27 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test + bloc_test + mocktail |
| **Config file** | pubspec.yaml (flutter_test dependency) |
| **Quick run command** | `flutter analyze` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30 seconds (analyze) / ~120 seconds (test) |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 27-01-01 | 01 | 1 | ADMN-16 | — | N/A | analyze | `flutter analyze lib/features/admin/ui/slot_management_tab.dart` | ❌ W0 | ⬜ pending |
| 27-01-02 | 01 | 1 | ADMN-17 | — | N/A | analyze | `flutter analyze lib/features/admin/ui/slot_management_tab.dart` | ❌ W0 | ⬜ pending |
| 27-02-01 | 02 | 1 | ADMN-18 | — | N/A | analyze | `flutter analyze lib/features/admin/ui/admin_booking_row.dart` | ❌ W0 | ⬜ pending |
| 27-02-02 | 02 | 1 | ADMN-19 | — | N/A | analyze | `flutter analyze lib/features/admin/ui/booking_management_tab.dart` | ❌ W0 | ⬜ pending |
| 27-03-01 | 03 | 2 | ADMN-20 | — | N/A | analyze | `flutter analyze lib/features/admin/ui/users_management_tab.dart` | ❌ W0 | ⬜ pending |
| 27-03-02 | 03 | 2 | ADMN-21 | — | N/A | analyze | `flutter analyze lib/features/admin/ui/user_detail_sheet.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing flutter_test infrastructure covers all phase requirements.
- No new test files needed — visual redesign validated via `flutter analyze` (no new business logic introduced).

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Slot row visual layout (Anton 32px laranja se reservado) | ADMN-16 | Font rendering verificado apenas visualmente | Run app → Admin → Slots tab → verificar tipografia |
| Day selector underline laranja + ← → | ADMN-17 | Animação e transição de dias | Run app → Admin → Slots → navegar dias |
| Pills Confirmar/Recusar só para pending | ADMN-19 | Visibilidade condicional por estado | Run app → Admin → Reservas → reserva pending |
| Avatar foto/inicial + UserDetailSheet | ADMN-20, ADMN-21 | Image.network + tap navigation | Run app → Admin → Usuários → tap em usuário |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

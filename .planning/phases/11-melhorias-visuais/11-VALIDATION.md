---
phase: 11
slug: melhorias-visuais
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-26
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual-only (project policy: no unit/widget tests) |
| **Config file** | none |
| **Quick run command** | Visual inspection in browser at 375px |
| **Full suite command** | Visual inspection across all screens at 375px and 390px |
| **Estimated runtime** | ~5 minutes manual review |

---

## Sampling Rate

- **After every task commit:** Visual inspection in browser/emulator at 375px
- **After every plan wave:** Visual inspection on 375px viewport for all affected screens
- **Before `/gsd:verify-work`:** Full visual review across all screens at 375px and 390px
- **Max feedback latency:** ~5 minutes

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 11-01-01 | 01 | 1 | UI-02 | manual | N/A — no tests per project policy | N/A | ⬜ pending |
| 11-01-02 | 01 | 1 | UI-02 | manual | N/A — no tests per project policy | N/A | ⬜ pending |
| 11-02-01 | 02 | 2 | UI-03 | manual | N/A — no tests per project policy | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

None — no tests to be written per project policy (`feedback_no_tests.md`). Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| DayView renders slots em timeline vertical | UI-02 | Sem testes por política do projeto | Abrir app em 375px, navegar para agenda, verificar layout estilo Google Calendar com horas na coluna esquerda |
| Tap no slot disponível abre BookingConfirmationSheet | UI-02 | Sem testes por política do projeto | Tocar em bloco verde disponível, verificar que o sheet de confirmação abre |
| Slots ocupados/bloqueados não são tapáveis | UI-02 | Sem testes por política do projeto | Tocar em bloco cinza/vermelho, verificar que nada acontece |
| AppSpacing tokens aplicados em todas as telas | UI-03 | Sem testes por política do projeto | Revisar Schedule, MyBookings, Profile, Login, Register, Admin screens — sem literais de padding |
| Sem overflow em telas de 375px e 390px | UI-03 | Sem testes por política do projeto | Testar todas as telas nos dois viewports, verificar ausência de RenderOverflow |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 300s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

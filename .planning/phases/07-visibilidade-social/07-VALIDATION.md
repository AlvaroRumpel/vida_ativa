---
phase: 7
slug: visibilidade-social
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-25
---

# Phase 7 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — project has no automated test suite (unit/widget tests explicitly disabled) |
| **Config file** | none |
| **Quick run command** | `flutter analyze` |
| **Full suite command** | `flutter analyze && flutter build web --no-tree-shake-icons` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze` — must exit 0, no new warnings
- **After every plan wave:** Run `flutter build web --no-tree-shake-icons` — must compile clean
- **Before `/gsd:verify-work`:** Full build must be green + manual smoke test
- **Max feedback latency:** 30 seconds (analyze only)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 7-01-01 | 01 | 1 | SOCIAL-01, SOCIAL-02, ADMN-09 | static analysis | `flutter analyze` | ⬜ pending |
| 7-01-02 | 01 | 1 | SOCIAL-01 | static analysis | `flutter analyze` | ⬜ pending |
| 7-01-03 | 01 | 2 | SOCIAL-02 | static analysis + manual | `flutter analyze` | ⬜ pending |
| 7-01-04 | 01 | 2 | SOCIAL-02 | manual | manual smoke | ⬜ pending |
| 7-01-05 | 01 | 3 | ADMN-09 | static analysis + manual | `flutter analyze` | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

None — no test framework to install. `flutter analyze` is always available.

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Nome do reservante visível na agenda para outro usuário | SOCIAL-01 | Requer 2 contas ativas e Firestore real | Logar como usuário A, reservar slot. Logar como usuário B, abrir agenda na mesma data — verificar nome de A no slot ocupado |
| Slot próprio mostra "Minha reserva" (não o nome) | SOCIAL-01 | Requer login e reserva real | Fazer reserva como usuário A, abrir agenda — slot deve mostrar badge "Minha reserva", não o nome |
| Slot sem displayName mostra "Ocupado" | SOCIAL-01 | Edge case difícil de reproduzir | Se possível, criar usuário sem displayName; caso contrário, verificar lógica via code review |
| Campo participantes aparece na BookingConfirmationSheet | SOCIAL-02 | Requer UI real | Abrir confirmação de reserva — campo "Quem vai jogar? (opcional)" deve aparecer antes do botão Reservar |
| Participantes salvos no Firestore ao confirmar reserva | SOCIAL-02 | Requer Firestore real | Fazer reserva com participantes preenchidos, verificar documento no Console Firestore |
| Ícone de editar participantes no BookingCard | SOCIAL-02 | Requer UI real | Abrir "Minhas Reservas", verificar ícone de editar; tocar e editar participantes |
| Participantes do booking exibidos no AdminBookingCard | ADMN-09 | Requer conta admin | Logar como admin, abrir listagem de reservas — verificar nome + participantes visíveis por reserva sem expandir |
| Reservas sem participantes não mostram linha extra | ADMN-09 | Requer UI real | Reservas criadas sem participantes não devem mostrar linha de grupo no admin |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify (flutter analyze) or manual test
- [ ] Sampling continuity: flutter analyze runs after each code task
- [ ] Wave 0: N/A — no test stubs needed
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s (analyze)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

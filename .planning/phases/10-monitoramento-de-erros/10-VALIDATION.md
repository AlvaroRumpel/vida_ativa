---
phase: 10
slug: monitoramento-de-erros
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-26
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter analyze (static analysis only — no unit/widget tests per project policy) |
| **Config file** | analysis_options.yaml |
| **Quick run command** | `flutter analyze lib/` |
| **Full suite command** | `flutter analyze lib/` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze lib/`
- **After every plan wave:** Run `flutter analyze lib/`
- **Before `/gsd:verify-work`:** Full analyze must be clean
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 01 | 1 | OPS-01 | static | `flutter analyze lib/main.dart lib/features/auth/cubit/auth_cubit.dart` | ✅ | ⬜ pending |
| 10-01-02 | 01 | 1 | OPS-01 | static | `flutter analyze lib/` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new test files needed — integration is validated via static analysis + manual Sentry dashboard verification.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Erro aparece no painel Sentry | OPS-01 | Requer DSN real, build de produção, e dashboard externo | `flutter build web --dart-define=SENTRY_DSN=<dsn>` → abrir app → provocar erro → verificar no sentry.io |
| Stack trace inclui plataforma/versão | OPS-01 | Requer evento real no Sentry dashboard | Após erro capturado, verificar se o evento mostra "Flutter Web", versão do app, stack trace legível |
| UID do usuário aparece nos eventos | OPS-01 | Requer login real + erro real | Fazer login → provocar erro → verificar campo "user.id" no evento do Sentry |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

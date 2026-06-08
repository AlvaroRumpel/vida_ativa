# Phase 23: Design System + NavigationBar - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-25
**Phase:** 23 — Design System + NavigationBar
**Areas discussed:** Font Bundling, Hardcoded Color Audit, Completion Criteria

---

## Font Bundling

| Option | Description | Selected |
|--------|-------------|----------|
| Bundlar em assets/google_fonts/ | Anton/Manrope/JBM como .ttf locais. Offline seguro. ~500KB. | ✓ |
| Manter CDN runtime | google_fonts 6.2.1 faz cache após 1a visita. Sem peso no repo. | |

**User's choice:** Bundlar offline

**Font weights confirmed:**

| Option | Description | Selected |
|--------|-------------|----------|
| Todos os 5 arquivos (Anton 400, Manrope 400/600/700, JBM 700) | Garante offline completo | ✓ |
| Só Anton 400 | Anton crítico; Manrope e JBM via CDN com cache | |

**User's choice:** Todos os 5 arquivos

---

## Hardcoded Color Audit

| Option | Description | Selected |
|--------|-------------|----------|
| Diferir para fases 24–29 | Cada fase substitui ao redesenhar. Evita trabalho duplicado. | |
| Auditar e corrigir em Phase 23 | booking_card, admin_booking_card, booking_confirmation_sheet agora. | ✓ |

**User's choice:** Auditar e corrigir em Phase 23
**Notes:** Arquivos identificados no pitfall log do STATE.md. Grep antes de editar cada arquivo.

---

## Completion Criteria

| Option | Description | Selected |
|--------|-------------|----------|
| Compilação limpa + flutter analyze | flutter build web sem erros + analyze zero warnings. | ✓ |
| Compilação + verificação visual em staging | Build + deploy + inspeção visual no browser. | |

**User's choice:** Compilação limpa + flutter analyze

---

## Claude's Discretion

- Corrigir `AppTheme.line` → `AppTheme.lineHair` em app_shell.dart (bug identificado no scout)
- Ordem de tarefas (fontes → pubspec → audit cores → build verify)
- Filenames exatos dos .ttf (confirmar no pub cache)

## Deferred Ideas

- Verificação visual em staging — após Phase 24+
- Dark mode — v7+
- Pesos adicionais de fonte — não necessários agora

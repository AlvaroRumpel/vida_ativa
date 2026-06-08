# Phase 25: Estrutura Admin - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-26
**Phase:** 25-estrutura-admin
**Areas discussed:** Estrutura AppBar, Notification banner scope, Wordmark formato admin

---

## Estrutura AppBar

| Option | Description | Selected |
|--------|-------------|----------|
| Manter AppBar | Reescrever title/actions no AppBar existente; TabBar em AppBar.bottom; sticky grátis | |
| Inline como Phase 24 | Remover AppBar, Column([header, TabBar, Expanded(TabBarView)]) | ✓ |

**User's choice:** Inline como Phase 24

| Option | Description | Selected |
|--------|-------------|----------|
| Column: header + TabBar + Expanded | TabBar sticky naturalmente abaixo do header | ✓ |
| SliverAppBar + SliverPersistentHeader | Mais complexo, sem benefício real | |

**User's choice:** Column structure

| Option | Description | Selected |
|--------|-------------|----------|
| SafeArea wrapping body | Padrão Phase 24 — simples e consistente | ✓ |
| Padding top manual | Mais verboso, mesma funcionalidade | |

**User's choice:** SafeArea wrapping body

---

## Notification Banner Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Ambos os banners | Restyle _NotificationBanner + trocar SnackBar por inline banner | ✓ |
| Só o SnackBar nova reserva | Deixar _NotificationBanner sem mudança | |

**User's choice:** Ambos os banners

| Option | Description | Selected |
|--------|-------------|----------|
| Faixa laranja + texto + "Ver" + auto-dismiss 5s | Substitui SnackBar diretamente | ✓ |
| Faixa laranja + texto só, sem auto-dismiss | Admin fica com banner parado | |

**User's choice:** Faixa + "Ver" + auto-dismiss 5s

---

## Wordmark Formato Admin

| Option | Description | Selected |
|--------|-------------|----------|
| Wordmark Row à esquerda, "cliente →" à direita, eyebrow abaixo | Linha 1: wordmark + link; Linha 2: eyebrow | |
| Wordmark sozinho no topo, eyebrow + link numa linha abaixo | Linha 1: wordmark; Linha 2: eyebrow + link | ✓ |

**User's choice:** 2 linhas — wordmark só no topo, eyebrow + link abaixo

| Option | Description | Selected |
|--------|-------------|----------|
| Idêntico ao Phase 24 | "VIDA" Anton ink + "ATIVA" rect orange borderRadius:4 | ✓ |
| Variante admin | Leve ajuste de tamanho — sem requisito para isso | |

**User's choice:** Idêntico ao Phase 24

---

## Claude's Discretion

- Padding interno do header
- Espaçamento entre linhas do header
- Cor do eyebrow "PAINEL ADMIN" (concrete vs ink)
- Animação de entrada do inline banner
- Timer vs Future.delayed para auto-dismiss

## Deferred Ideas

- Animação collapse/expand do inline banner — v7+
- FCM Error banner restyle — não é requisito ADMN-15

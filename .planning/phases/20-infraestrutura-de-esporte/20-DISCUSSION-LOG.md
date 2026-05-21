# Phase 20: Infraestrutura de Esporte - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-20
**Phase:** 20-infraestrutura-de-esporte
**Areas discussed:** Sport selector no formulário, Admin gestão de esportes, Esporte em views de admin, Inicialização dos esportes padrão

---

## Sport Selector no Formulário

| Option | Description | Selected |
|--------|-------------|----------|
| DropdownButtonFormField | Widget nativo Material, consistente com outros campos do app | ✓ |
| Chips horizontais | FilterChip horizontal para cada esporte | |
| Claude decide | Claude escolhe o que melhor encaixa no layout | |

**User's choice:** DropdownButtonFormField

| Option | Description | Selected |
|--------|-------------|----------|
| Depois dos participantes | Último campo opcional, antes dos botões | ✓ |
| Antes dos participantes | Esporte como info do jogo, antes de info de pessoas | |
| Claude decide | Claude posiciona onde fizer mais sentido | |

**User's choice:** Depois dos participantes

---

## Admin: Gestão de Esportes

| Option | Description | Selected |
|--------|-------------|----------|
| Lista + add + remover (sem reordenar) | TextField + delete por item, sem drag | |
| Lista + add + remover + drag-to-reorder | ReorderableListView para implementar SPORT-02 completo | ✓ (implícito via "tem a abas de ajustes" + SPORT-02 scope) |
| Claude decide | Claude implementa o mais rápido | |

**User's choice:** Seção nova na aba Ajustes (SettingsTab existente)
**Notes:** User confirmou que o SettingsTab já existe. SPORT-02 inclui "reordenar" explicitamente — ReorderableListView implementa o requirement completo.

| Option | Description | Selected |
|--------|-------------|----------|
| Seção separada 'Esportes' | Card/seção nova no SettingsTab | ✓ |
| Dentro de seção existente | Misturado com outras configs | |

---

## Esporte em Views de Admin

| Option | Description | Selected |
|--------|-------------|----------|
| Não — só infraestrutura | Phase 20 foca em model + cubit + config | |
| Sim — exibir nos cards/detail | Mostrar esporte em AdminBookingCard e AdminBookingDetailSheet | ✓ |

**User's choice:** Sim — chip colorido nos cards/detail

| Option | Description | Selected |
|--------|-------------|----------|
| Label de texto simples | Linha extra, igual ao campo participantes | |
| Chip colorido por esporte | Badge colorido, mais rico visualmente | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| Hash do nome → cor fixa | Determinístico, funciona para qualquer esporte | ✓ |
| Mapa fixo hard-coded | Vôlei=azul, etc., precisa de fallback | |
| Claude decide | Claude implementa a mais robusta | |

---

## Inicialização dos Esportes Padrão

| Option | Description | Selected |
|--------|-------------|----------|
| Client-side no SportConfigCubit | Cubit detecta doc ausente/vazio e escreve defaults | ✓ |
| Documento pré-seedado manualmente | Dev cria doc antes do deploy | |
| Cloud Function no deploy | Migration trigger, mais complexo | |

| Option | Description | Selected |
|--------|-------------|----------|
| Esconde o dropdown | Sem esportes = sem campo visível | ✓ |
| Exibe dropdown desabilitado | Campo visível mas bloqueado | |

---

## Claude's Discretion

- Estrutura exata do doc `/config/sports` no Firestore
- Conjunto de cores para algoritmo de hash
- StreamSubscription vs one-shot load para SportConfigCubit
- Placement do SportConfigCubit no widget tree

## Deferred Ideas

- Cores configuráveis por esporte — Out of Scope (REQUIREMENTS.md)
- Múltiplos preços por esporte — v6+

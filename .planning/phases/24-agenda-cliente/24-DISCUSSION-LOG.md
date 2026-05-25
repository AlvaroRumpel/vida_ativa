# Phase 24: Agenda (Cliente) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-25
**Phase:** 24 — Agenda (Cliente)
**Areas discussed:** Cabeçalho, Tira de dias, Conteúdo do slot row, Slot bloqueado

---

## Cabeçalho

| Option | Description | Selected |
|--------|-------------|----------|
| AppBar wordmark + WeekHeader separado | AppBar só com wordmark, WeekHeader no body separado. Menor impacto estrutural. | |
| Header unificado no body | Remove AppBar. Header custom no topo do body: wordmark + eyebrow + navegação de semana. | ✓ |

**User's choice:** Header unificado no body

---

| Option | Description | Selected |
|--------|-------------|----------|
| Eyebrow abaixo do wordmark, acima da navegação | Wordmark / eyebrow / WeekHeader / day strip — ordem top-down | |
| Eyebrow ao lado do wordmark (inline) | Wordmark + pill à esquerda, data mono à direita na mesma linha | ✓ |

**User's choice:** Inline — wordmark esquerda, data do dia selecionado direita

---

## Tira de dias

| Option | Description | Selected |
|--------|-------------|----------|
| Número laranja, sem underline | Hoje (não selecionado): número Anton em AppTheme.orange. Selecionado: underline laranja 2px. | ✓ |
| Dot laranja abaixo | Ponto laranja 4px abaixo do número para "hoje". Mantém comportamento atual. | |

**User's choice:** Número laranja, sem underline

| Option | Description | Selected |
|--------|-------------|----------|
| 3 letras (Seg, Ter, Qua...) | Padrão atual, mais legível em PT-BR | ✓ |
| 2 letras (Se, Te, Qu...) | Mais compacto | |

**User's choice:** 3 letras

---

## Conteúdo do slot row

| Option | Description | Selected |
|--------|-------------|----------|
| Horário + preço + status label | Anton 42px + mono preço direita + status label mono extrema direita | ✓ |
| Só horário + status label (sem preço) | Mais limpo, preço só na sheet de reserva | |

**User's choice:** Horário + preço + status label

| Option | Description | Selected |
|--------|-------------|----------|
| Sim, abre ClientBookingDetailSheet | myBooking tappável → detail sheet já existente | ✓ |
| Não, apenas exibe estado | myBooking não tappável (comportamento atual) | |

**User's choice:** Sim, myBooking abre ClientBookingDetailSheet

---

## Slot bloqueado

| Option | Description | Selected |
|--------|-------------|----------|
| Opacity 0.45 + label 'Bloqueado' | Mesmo opacity de booked, label mono "Bloqueado", não tappável | ✓ |
| Sem opacity, linha tracejada | Row completo sem opacity, borda hairline tracejada | |

**User's choice:** Opacity 0.45 + label 'Bloqueado'

---

## Claude's Discretion

- Padding/spacing do header customizado
- Tamanho da pílula laranja no wordmark
- Nome exato dos novos widgets (SportDayStrip, SlotHairlineRow)
- Integração SlotList → SlotHairlineRow

## Deferred Ideas

- Scroll automático para slot mais próximo do horário atual
- Animação de transição entre dias (v7+)
- Campo esporte exibido no slot row (fora de escopo desta fase)

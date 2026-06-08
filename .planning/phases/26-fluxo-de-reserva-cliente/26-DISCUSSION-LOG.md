# Phase 26: Fluxo de Reserva (Cliente) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 26-fluxo-de-reserva-cliente
**Areas discussed:** Hero do Horário (BOOK-07/08), MyBookings Header + Hero (BOOK-10), HairlineBookingRow (BOOK-11), SportBtn (BOOK-09), Campo de Participantes, Switch Recorrência, Pending Payment Row, Empty State

---

## Hero do Horário (BOOK-07)

| Option | Description | Selected |
|--------|-------------|----------|
| Hero block no topo | Eyebrow mono data + hora Anton 88px + preço mono. Faz da hora o elemento principal. | ✓ |
| Info row promovido | Mantém 3 info-rows, só a linha de hora cresce para 88px. | |

**User's choice:** Hero block no topo  
**Notes:** Preço junto do hero (eyebrow + hora + preço), não separado abaixo.

---

## Banner de Aprovação Manual (BOOK-08)

| Option | Description | Selected |
|--------|-------------|----------|
| Faixa laranja 2px à esquerda | IntrinsicHeight + Container(width:2, orange) + Expanded. Sem fundo. | ✓ |
| Linha top laranja 2px | Border(top: orange) acima do texto. | |
| Manter lógica atual | _requiresConfirmation && !pixEnabled — zero mudança de comportamento. | ✓ |
| Ampliar para _requiresConfirmation | Sempre visível quando precisa de aprovação. | |

---

## SportBtn (BOOK-09)

| Option | Description | Selected |
|--------|-------------|----------|
| Novo widget SportBtn reutilizável | lib/core/widgets/sport_btn.dart. Phases 27+ vão precisar. | ✓ |
| Estilos inline | Apenas booking_confirmation_sheet.dart. | |
| Ambos os botões viram SportBtn | Filled (Pix) + Outlined (na hora). | ✓ |
| Só Pagar com Pix | Apenas botão principal redesenha. | |
| Remover ícones | Anton uppercase somente. Sem qr_code/handshake. | ✓ |
| Manter ícones | SportBtn aceita ícone opcional. | |
| Recorrência também SportBtn | Todos os botões de ação principal viram SportBtn. | ✓ |

---

## MyBookings Header + Hero (BOOK-10)

| Option | Description | Selected |
|--------|-------------|----------|
| Inline wordmark igual Phase 24/25 | "VIDA ATIVA" wordmark + eyebrow "MINHAS RESERVAS" mono. | ✓ |
| Header simples sem AppBar | Só SafeArea + título mono. | |
| Manter AppBar | BOOK-10/11/12 não especificam header. | |
| Eyebrow dinâmico | PRÓXIMO · HOJE / AMANHÃ / SEG etc. | ✓ |
| Eyebrow fixo "Próximo · hoje" | Sempre o mesmo texto. | |
| Hora + eyebrow apenas no hero | Eyebrow laranja + Anton 72px + data mono abaixo. Limpo. | ✓ |
| Hora + data + preço + status | Bloco completo exposto no hero. | |

---

## Section Headers (BOOK-12)

| Option | Description | Selected |
|--------|-------------|----------|
| EM SEGUIDA / HISTÓRICO em JBM mono | Substitui Proximas/Passadas. Primeira upcoming = hero. | ✓ |
| Manter nomes atuais | Só muda estilo, não o nome. | |

---

## HairlineBookingRow (BOOK-11)

| Option | Description | Selected |
|--------|-------------|----------|
| Novo arquivo HairlineBookingRow | lib/features/booking/ui/hairline_booking_row.dart | ✓ |
| Reescrever in-place booking_card.dart | Menos arquivos, sem histórico. | |
| Data Anton + eyebrow mono + hora + status pill | Esquerda: dia+abrev. Direita: horário + pill. | ✓ |
| Data + hora + preço + status | Inclui preço também. | |
| Outline pill | Border.all(statusColor) + mono text. Sem fundo. | ✓ |
| Texto mono com cor | Sem container/border. | |
| Hero tappável | GestureDetector → ClientBookingDetailSheet. | ✓ |

---

## Campo de Participantes + Switch

| Option | Description | Selected |
|--------|-------------|----------|
| Underline field Arena | UnderlineInputBorder. Consistente com ADMN-25. | ✓ |
| Manter OutlineInputBorder | Phase 28 resolve. | |
| Switch sport (laranja) | AppTheme.switchTheme. Remove primaryGreen hardcoded. | ✓ |
| Manter switch como está | BOOK-07/08/09 não cobrem switch. | |

---

## HairlineBookingRow — Pending Payment

| Option | Description | Selected |
|--------|-------------|----------|
| Eyebrow especial "AGUARDANDO PIX" + pill laranja | Row diferenciado para pending_payment. Tap → PixPaymentScreen. | ✓ |
| Só pill laranja "PIX PENDENTE" | Row normal com pill laranja. | |

---

## Empty State MyBookings

| Option | Description | Selected |
|--------|-------------|----------|
| Redesenhar com Arena style | Texto mono uppercase + SportBtn "VER AGENDA". | ✓ |
| Manter como está | Fora de escopo BOOK-10/11/12. | |

---

## Claude's Discretion

- Padding/spacing interno do hero block
- Tamanho da pílula/rect laranja do wordmark (copiar de schedule_screen.dart)
- Ordem exata eyebrow/hora no hero (eyebrow acima, hora abaixo)
- Largura e padding interno do status pill

## Deferred Ideas

- PixPaymentScreen redesign — out of scope (REQUIREMENTS.md)
- ClientBookingDetailSheet visual Arena — not in BOOK-07..12
- BookingCard remoção — Phase 27 cleanup
- RecurrenceResultSheet redesign — not in scope

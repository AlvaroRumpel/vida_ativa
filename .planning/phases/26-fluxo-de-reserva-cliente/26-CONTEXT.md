# Phase 26: Fluxo de Reserva (Cliente) - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 26 redesenha as telas do fluxo de reserva do cliente com identidade Arena Esportivo:
- `booking_confirmation_sheet.dart` — hero do horário Anton 88px, faixa laranja para aprovação manual, SportBtn para pagamento
- `my_bookings_screen.dart` — header inline (sem AppBar), hero "Próximo" Anton 72px, section labels redesign
- `booking_card.dart` → `hairline_booking_row.dart` — novo widget hairline, status pill outline
- `sport_btn.dart` — novo widget reutilizável SportBtn para fases futuras

Completa: BOOK-07, BOOK-08, BOOK-09, BOOK-10, BOOK-11, BOOK-12

Fora de escopo: lógica de booking, BLoC/models/router, PixPaymentScreen, Cloud Functions.

</domain>

<decisions>
## Implementation Decisions

### Hero do Horário na Confirmation Sheet (BOOK-07)
- **D-01:** Após drag handle: hero block com eyebrow mono da data (ex: "QUA, 28 MAI") + hora em Anton 88px + preço em mono abaixo. Remove os 3 `_infoRow()` atuais (date/time/price) e substitui por esse bloco único.
- **D-02:** Hero block fica no topo do conteúdo, antes da recorrência, participantes e botões.

### Banner de Aprovação Manual (BOOK-08)
- **D-03:** `_paymentWarningBanner()` redesenhado com faixa laranja 2px à esquerda — mesmo padrão Phase 25 (`IntrinsicHeight` + `Container(width:2, color:AppTheme.orange)` + `Expanded`). Sem fundo colorido, sem borda `Border.all`.
- **D-04:** Lógica de exibição **não muda**: aparece apenas quando `_requiresConfirmation && !pixEnabled`. Zero alteração de comportamento.

### SportBtn (BOOK-09)
- **D-05:** Novo widget reutilizável em `lib/core/widgets/sport_btn.dart`. Usado em Phase 26 e esperado em Phase 27+ (ADMN-23).
- **D-06:** SportBtn tem variante `filled` (fundo orange, texto sand) e `outlined` (borda ink, texto ink). Sem ícones — Anton uppercase somente.
- **D-07:** "PAGAR COM PIX" → SportBtn filled orange. "PAGAR NA HORA" → SportBtn outlined ink.
- **D-08:** Botão "Reservar N reserva(s)" da recorrência → SportBtn filled (mesma variante filled).
- **D-09:** Botão único "Confirmar reserva" (quando !pixEnabled) → SportBtn filled ink.

### Campo de Participantes e Dropdown de Esporte (confirmation)
- **D-10:** TextField participantes e DropdownButtonFormField de esporte migram para `UnderlineInputBorder` — consistent com ADMN-25 (Phase 28) e estilo Arena. Sem `borderRadius: 12`.

### Switch de Recorrência
- **D-11:** Switch usa `AppTheme.switchTheme` do lightTheme (orange/paper). Remove `activeThumbColor: AppTheme.primaryGreen` hardcoded.

### MyBookings Header (BOOK-10/12)
- **D-12:** Remove `AppBar`. Inline header igual Phase 24/25: wordmark "VIDA ATIVA" (Anton + rect orange borderRadius:4) + eyebrow "MINHAS RESERVAS" em JBM mono. Usa `SafeArea`.

### Hero "Próximo" (BOOK-10)
- **D-13:** Primeira reserva upcoming se torna o hero block: eyebrow laranja dinâmico + hora Anton 72px + data em mono abaixo.
- **D-14:** Eyebrow dinâmico: "PRÓXIMO · HOJE" se a reserva for hoje, "PRÓXIMO · AMANHÃ" se amanhã, "PRÓXIMO · SEG" (dia abreviado JBM mono) para outras datas.
- **D-15:** Hero block é GestureDetector → abre `ClientBookingDetailSheet` (mesma lógica dos rows). Se booking for `pending_payment` + `paymentId != null`, tap vai para `PixPaymentScreen` (comportamento atual preservado).

### Section Headers (BOOK-12)
- **D-16:** Substituir "Proximas"/"Passadas" por "EM SEGUIDA" e "HISTÓRICO" em JetBrains Mono uppercase tracked.
- **D-17:** "EM SEGUIDA" = upcoming bookings excluindo a primeira (que virou o hero). "HISTÓRICO" = bookings passadas/canceladas.

### HairlineBookingRow — novo widget (BOOK-11)
- **D-18:** Novo arquivo `lib/features/booking/ui/hairline_booking_row.dart`. `BookingCard` vira dead code (não excluir nesta phase, remover junto com Phase 27 cleanup ou quando conveniente).
- **D-19:** Row exibe: lado esquerdo — dia do mês em Anton 30px + abreviação do dia em JBM mono; lado direito — horário em Anton 26px + status pill outline.
- **D-20:** Status pill outline: `Container(decoration: BoxDecoration(border: Border.all(color:statusColor, width:1), borderRadius: circular), child: Text(statusLabel, mono))`. Sem fundo.
- **D-21:** Hairline divisória entre rows: `Border(top: BorderSide(color: AppTheme.lineHair, width: 0.5))`.
- **D-22:** Booking com `status == 'pending_payment'`: eyebrow especial "AGUARDANDO PIX" + pill laranja "PIX PENDENTE". Tap → `PixPaymentScreen` (preserva comportamento atual de my_bookings_screen.dart linha 89-97).

### Empty State (MyBookings)
- **D-23:** Empty state redesenhado: texto em JBM mono uppercase + SportBtn outlined "VER AGENDA". Consistent com v6.

### Claude's Discretion
- Padding/spacing interno do hero block na confirmation sheet
- Tamanho da pílula/rect laranja do wordmark (usar mesmo de Phase 24)
- Padding horizontal/vertical do hero "Próximo" em MyBookings
- Ordem exata dos campos no hero block da sheet (eyebrow antes ou depois da hora?)
- Largura do status pill e padding interno

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requisitos
- `.planning/REQUIREMENTS.md` §BOOK-07, §BOOK-08, §BOOK-09, §BOOK-10, §BOOK-11, §BOOK-12 — requisitos exatos a satisfazer

### Design System
- `lib/core/theme/app_theme.dart` — AppTheme completo; helpers display()/ui()/mono(); tokens de cor; switchTheme já laranja; NÃO modificar
- `.planning/research/PITFALLS.md` — pitfalls v6.0 (Anton height clip, hardcoded colors)

### Padrões de Referência (Phases anteriores)
- `lib/features/schedule/ui/schedule_screen.dart` — padrão de header inline sem AppBar (Phase 24)
- `lib/features/schedule/ui/slot_list.dart` + `slot_hairline_row.dart` — padrão de HairlineRow + hairline divisória
- `lib/features/admin/ui/admin_screen.dart` — padrão de faixa lateral (Phase 25)

### Arquivos a Modificar
- `lib/features/booking/ui/booking_confirmation_sheet.dart` — hero, banner, sportbtn, underline fields, switch
- `lib/features/booking/ui/my_bookings_screen.dart` — header inline, hero, section labels, HairlineBookingRow, empty state

### Novos Arquivos a Criar
- `lib/core/widgets/sport_btn.dart` — SportBtn reutilizável (filled/outlined variants)
- `lib/features/booking/ui/hairline_booking_row.dart` — novo widget row para MyBookings

### Arquivos a NÃO Modificar
- `lib/core/theme/app_theme.dart` — não modificar
- `lib/features/booking/ui/pix_payment_screen.dart` — fora de escopo
- `lib/features/booking/ui/client_booking_detail_sheet.dart` — apenas chamar, não modificar
- `lib/features/booking/ui/booking_card.dart` — não modificar (vira dead code, remover depois)
- BLoC, models, router — zero mudanças

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AppTheme.display(size)` — Anton com height 0.92; usar para 88px, 72px, 30px, 26px
- `AppTheme.mono(size)` — JetBrains Mono
- `AppTheme.orange`, `AppTheme.ink`, `AppTheme.court`, `AppTheme.lineHair`, `AppTheme.sand` — tokens relevantes
- `ClientBookingDetailSheet` — já existe; recebe `booking, bookingCubit, isFuture`
- `SlotHairlineRow` — referência visual para o padrão hairline row (Phase 24)
- Wordmark pattern: `Row([Text("VIDA", Anton ink), Container(rect orange, child: Text("ATIVA", Anton paper))])` — copiar de schedule_screen.dart

### Established Patterns
- Header inline: `SafeArea(child: Column([headerWidget, Expanded(content)]))`
- Faixa lateral: `IntrinsicHeight(child: Row([Container(width:2, color:orange), Expanded(content)]))`
- Hairline divisória: `Border(top: BorderSide(color: AppTheme.lineHair, width: 0.5))`
- Tokens via `AppTheme.* const` — nunca `Color(0xFF...)`
- Scaffold sem AppBar (padrão v6.0)

### Integration Points
- `BookingCubit` — booking/cancel lógica não muda; só UI
- `PixPaymentScreen` — abre via `Navigator.push(MaterialPageRoute(...))` para pending_payment
- `ClientBookingDetailSheet(booking, bookingCubit, isFuture)` — 3 params obrigatórios
- `StatefulNavigationShell.of(context).goBranch(0)` — navegação para agenda no empty state

### Pitfalls Específicos
- `booking_card.dart` tem `Color(0xFF9E9A95)` hardcoded — não reutilizar esse arquivo
- `_infoRow()` usa `AppTheme.primaryGreen` (verde v5) — substituir pelo hero block, não refatorar
- `_paymentWarningBanner()` usa `AppTheme.paper` + `AppTheme.sun` — substituir pela faixa laranja

</code_context>

<specifics>
## Specific Ideas

- Anton 88px na sheet: `AppTheme.display(size: 88)` — não construir TextStyle manual
- Anton 72px no hero MyBookings: `AppTheme.display(size: 72)`
- Preço no hero da sheet: `AppTheme.mono(size: 16)` com `NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')`
- Eyebrow data na sheet: format `DateFormat('E, d MMM', 'pt_BR').format(...)` uppercase via `.toUpperCase()`
- SportBtn: `minimumSize: const Size(double.infinity, 52)` para largura total; `overflow: TextOverflow.ellipsis` para não quebrar linha
- Status labels mono: 'CONFIRMADO' (court), 'CANCELADO' (orangeDk), 'PENDENTE' (ink), 'PIX PENDENTE' (orange), 'EXPIRADO' (concrete)

</specifics>

<deferred>
## Deferred Ideas

- Redesign da PixPaymentScreen — mantém layout atual (out of scope per REQUIREMENTS.md)
- Animação de transição entre estados do hero — v7+
- ClientBookingDetailSheet visual Arena — não é escopo desta phase
- BookingCard remoção — acontece no cleanup de Phase 27 ou depois
- RecurrenceResultSheet redesign — não está nos BOOK-07..12

</deferred>

---

*Phase: 26-fluxo-de-reserva-cliente*
*Context gathered: 2026-05-27*

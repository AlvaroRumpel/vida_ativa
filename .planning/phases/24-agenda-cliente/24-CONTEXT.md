# Phase 24: Agenda (Cliente) - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 24 redesenha a tela de agenda do cliente com identidade Arena Esportivo completa:
- Header unificado custom (sem AppBar) com wordmark "VIDA ATIVA" + eyebrow mono data
- SportDayStrip — tira de dias underline substituindo ChoiceChips
- SlotHairlineRow — rows sem Card com faixa laranja, opacity e info completa
- Completar SCHED-04, SCHED-05, SCHED-06

Fora de escopo: lógica de booking, BLoC/models/router, tela de admin, fluxo Pix.

</domain>

<decisions>
## Implementation Decisions

### Header (SCHED-06)
- **D-01:** Remover o AppBar do ScheduleScreen — usar header customizado inline no body do Scaffold
- **D-02:** Header layout: wordmark "VIDA ATIVA" (Anton + pílula laranja AppTheme.orange) à ESQUERDA, data do dia selecionado em JetBrains Mono à DIREITA — tudo na mesma linha (inline)
- **D-03:** Abaixo do header inline: WeekHeader existente (← Semana de X →) permanece sem mudança de lógica
- **D-04:** Data do dia selecionado = dia abreviado + número + mês em Mono uppercase (ex: "SEG, 26 MAI") — atualiza junto com `_selectedDay`

### Day Strip (SCHED-04)
- **D-05:** Substituir `DayChipRow` (ChoiceChip) por `SportDayStrip` — coluna por dia: abreviação 3 letras em mono uppercase (Seg, Ter, Qua, Qui, Sex, Sáb, Dom) + número em Anton
- **D-06:** Dia selecionado: underline laranja 2px (AppTheme.orange) — sem chip, sem fundo colorido
- **D-07:** Dia atual não selecionado ("hoje"): número Anton em AppTheme.orange — sem underline, sem dot
- **D-08:** Dias não selecionados + não hoje: número Anton em AppTheme.ink (normal)

### Slot Row (SCHED-05)
- **D-09:** Substituir `SlotCard` (Card widget) por `SlotHairlineRow` — sem Card, hairline divisória entre rows
- **D-10:** Cada row exibe: horário em Anton 42px (esquerda) + preço em mono (direita) + status label em mono (extrema direita)
- **D-11:** `myBooking`: faixa lateral laranja 3px à esquerda (AppTheme.orange), opacity normal (1.0), label "Minha reserva" em mono, tappável → abre `ClientBookingDetailSheet`
- **D-12:** `booked`: sem faixa, opacity 0.45, label = nome do reservante (bookerName) em mono, não tappável
- **D-13:** `blocked`: sem faixa, opacity 0.45, label "Bloqueado" em mono, não tappável
- **D-14:** `available`: sem faixa, opacity 1.0, label "Disponível" em mono AppTheme.court (verde), tappável → abre BookingConfirmationSheet (comportamento atual)

### Claude's Discretion
- Padding/spacing interno do header (horizontal e vertical)
- Tamanho da pílula laranja no wordmark (padding + border-radius)
- Largura da faixa lateral (3px per spec = AppTheme.orange)
- Hairline divisória entre slots = Border(top: BorderSide(color: AppTheme.lineHair)) em cada row (exceto o primeiro)
- Nome exato dos widgets novos: sugestão `SportDayStrip`, `SlotHairlineRow`
- Integração do SlotHairlineRow: SlotList chama o novo widget, não o SlotCard
- `ClientBookingDetailSheet` já existe — apenas chamar `showModalBottomSheet` com ele para myBooking

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requisitos
- `.planning/REQUIREMENTS.md` §SCHED-04, §SCHED-05, §SCHED-06 — requisitos exatos a satisfazer

### Design System
- `lib/core/theme/app_theme.dart` — paleta completa; AppTheme.display(), .ui(), .mono() helpers; NÃO modificar
- `.planning/research/PITFALLS.md` — pitfalls identificados (Anton height clip, FOUT, etc.)

### Arquivos a modificar
- `lib/features/schedule/ui/schedule_screen.dart` — remover AppBar, adicionar header custom
- `lib/features/schedule/ui/day_chip_row.dart` — reescrever como SportDayStrip (ou criar novo arquivo)
- `lib/features/schedule/ui/slot_card.dart` — reescrever como SlotHairlineRow (ou criar novo arquivo)
- `lib/features/schedule/ui/slot_list.dart` — atualizar para chamar SlotHairlineRow em vez de SlotCard

### Arquivos a NÃO modificar (apenas ler)
- `lib/features/schedule/models/slot_view_model.dart` — SlotStatus enum (available/booked/myBooking/blocked) + SlotViewModel
- `lib/features/schedule/ui/week_header.dart` — WeekHeader permanece sem mudança
- `lib/features/booking/ui/client_booking_detail_sheet.dart` — já existe; chamar via showModalBottomSheet para myBooking

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AppTheme.display()` — Anton com height 0.92, weight dado por param
- `AppTheme.mono()` — JetBrains Mono, uppercase via letterSpacing
- `AppTheme.ui()` — Manrope
- `AppTheme.orange`, `AppTheme.court`, `AppTheme.ink`, `AppTheme.lineHair`, `AppTheme.concrete` — tokens de cor relevantes
- `WeekHeader` — widget de navegação semana (← Semana de X →) — reutilizar sem mudança
- `ClientBookingDetailSheet` — já existe para myBooking tap

### Established Patterns
- Hairline divisória: `Border(top: BorderSide(color: AppTheme.lineHair, width: 0.5))` (padrão v6)
- Faixa lateral: `Container(width: 3, color: AppTheme.orange)` + `IntrinsicHeight` + `Row`
- Tokens de cor via `AppTheme.* const` — nunca `Color(0xFF...)`
- Scaffold sem AppBar: `Scaffold(body: Column([...]))` com safe area manual (padding top)

### Integration Points
- `ScheduleScreen._onDaySelected(DateTime)` → passa selectedDay para SportDayStrip e para header eyebrow
- `SlotList` → troca `SlotCard` por `SlotHairlineRow`
- `_showBookingSheet()` em slot_list.dart → para available (sem mudança)
- Nova função `_showDetailSheet()` para myBooking → `ClientBookingDetailSheet`

</code_context>

<specifics>
## Specific Ideas

- Anton 42px no slot row: usar `AppTheme.display(size: 42)` (não construir TextStyle manual)
- Preço em mono: `AppTheme.mono(size: 13)` com `NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')`
- Status label "Disponível": AppTheme.court (verde) para reforço positivo
- Header sem AppBar: usar `SafeArea` + padding top para não colidir com status bar

</specifics>

<deferred>
## Deferred Ideas

- Scroll automático para slot mais próximo do horário atual — Phase 24+ ou v7
- Animação de transição entre dias — v7+
- Esporte exibido no slot row (campo sport) — mantém fora do row para não sobrecarregar

</deferred>

---

*Phase: 24-agenda-cliente*
*Context gathered: 2026-05-25*

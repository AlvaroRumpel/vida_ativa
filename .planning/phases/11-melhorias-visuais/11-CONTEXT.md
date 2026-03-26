---
phase: 11
slug: melhorias-visuais
created: 2026-03-26
status: ready
---

# Phase 11: Melhorias Visuais - Context

**Gathered:** 2026-03-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Layout da agenda substituído por timeline vertical estilo Google Calendar (UI-02), e sistema de spacing padronizado aplicado em todas as telas do app (UI-03). Sem novas funcionalidades — apenas refatoração visual e troca de layout da tela de agenda.

</domain>

<decisions>
## Implementation Decisions

### Pacote de calendar view
- Usar `calendar_view` (pub.dev) para a DayView com timeline vertical
- Integrar via `CalendarEventData` mapeado a partir de `SlotViewModel`
- Cada slot vira um evento com `startTime` + duração fixa de 1h (endTime = startTime + 60min)
- DayView renderiza automaticamente os blocos na timeline

### Layout da timeline (UI-02)
- Timeline vertical contínua com timestamps na coluna esquerda (estilo Google Calendar DayView)
- Todas as horas do range são exibidas, mesmo sem slots — linha divisora leve entre horas vazias
- Range dinâmico: 1h antes do primeiro slot até 1h depois do último slot do dia (configuração atual)
- Blocos de slot com altura proporcional à duração (1h = altura de 1 linha-hora)

### Navegação por dias
- Manter DayChipRow + WeekHeader existentes no topo — sem swipe horizontal
- Scroll automático para o primeiro slot do dia ao selecionar um dia

### Interações
- Tap no bloco de slot **disponível** abre `BookingConfirmationSheet` (igual ao fluxo atual)
- Slots ocupados, myBooking e bloqueados **não** são tapáveis
- Nenhuma mudança no fluxo de booking — só o componente visual muda

### Visual dos blocos na timeline
- **Cor de fundo por status:**
  - Disponível: verde claro (AppTheme.primaryGreen com opacity baixa, texto escuro)
  - Ocupado: cinza claro
  - Minha reserva: verde/azul escuro (cor primária sólida)
  - Bloqueado: vermelho claro
- **Conteúdo de cada bloco:** horário (startTime), preço (para disponíveis), nome do reservante (para ocupados), status badge ("Disponível", "Minha reserva", "Bloqueado")
- Linha divisora leve (Divider sutil) entre horas vazias na timeline

### Duração dos slots
- Duração fixa de **1h** (60 minutos) para todos os slots — constante no código
- `endTime` calculado como `startTime + 60min` ao mapear para `CalendarEventData`
- **Sem** alterar `SlotModel` nem os documentos Firestore existentes

### Empty state e loading
- Dia sem slots: timeline renderizada (com horas visíveis) + texto centralizado "Nenhum horário disponível para este dia"
- Dia bloqueado: timeline renderizada + texto "Dia bloqueado — sem horários disponíveis"
- Loading: blocos cinza animados (shimmer) posicionados na timeline durante carregamento

### UI-03: Spacing sistemático
- Criar `lib/core/theme/app_spacing.dart` com tokens estáticos:
  - `xs = 4.0`
  - `sm = 8.0`
  - `md = 16.0`
  - `lg = 24.0`
  - `xl = 32.0`
- Fazer um audit em **todas as telas** e substituir literais de padding/margin pelos tokens
- Abordagem: spacing sistemático (não é um audit de overflow — layout fixes são best-effort se encontrados)
- Telas a cobrir: Schedule, MyBookings, Profile, Login, Register, Admin (slots, bookings, users, blocked dates)

### Claude's Discretion
- Configuração exata da `DayView` (headerStyle, timeLineStringBuilder, backgroundColor)
- Configuração do shimmer (duração de animação, número de blocos simulados)
- Decisão sobre incluir "now indicator" (linha da hora atual) — pode adicionar se o `calendar_view` suportar nativamente

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

No external specs — requirements are fully captured in decisions above.

### Roadmap & Requirements
- `.planning/ROADMAP.md` §Phase 11 — Success Criteria 1, 2, 3
- `.planning/REQUIREMENTS.md` §UI-02, UI-03

### Codebase Reference
- `lib/features/schedule/ui/schedule_screen.dart` — Integração: DayView substitui SlotList; WeekHeader e DayChipRow permanecem
- `lib/features/schedule/ui/slot_list.dart` — Será substituído ou reduzido; lógica de empty/blocked states deve ser preservada
- `lib/features/schedule/ui/slot_card.dart` — Referência para campos exibidos no evento (status colors, bookerName, price format)
- `lib/features/schedule/models/slot_view_model.dart` — Modelo fonte para mapeamento a CalendarEventData
- `lib/core/theme/app_theme.dart` — Adicionar import do app_spacing.dart; cores de status usadas nos blocos
- `pubspec.yaml` — Adicionar dependência `calendar_view`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `DayChipRow` + `WeekHeader`: mantidos integralmente — nova DayView encaixa abaixo deles
- `BookingConfirmationSheet`: chamado via onEventTap do calendar_view — `context.read<BookingCubit>()` padrão
- `SlotViewModel.status` + `SlotViewModel.bookerName` + `SlotViewModel.slot.price`: campos que alimentam o event tile
- `_StatusLabel` e `_statusColor` em `slot_card.dart`: referência de cores e labels a replicar no EventTileBuilder

### Established Patterns
- `context.read<BookingCubit>()` capturado antes de `showModalBottomSheet` — mesmo padrão aplicado no callback do calendar_view
- Empty state como texto centralizado com `Padding(24)` — replicar dentro da DayView ou sobrepor com Stack
- `AppTheme.primaryGreen` como cor primária de disponível; `Colors.grey` para ocupado; `Color(0xFFE53935)` para bloqueado

### Integration Points
- `ScheduleScreen.build()` → substituir `SlotList` por widget `DayView` do `calendar_view`
- `ScheduleState.ScheduleLoaded(slots: List<SlotViewModel>)` → mapear para `List<CalendarEventData>` antes de passar ao DayView
- `DayView.onEventTap` → chamar `_showBookingSheet(context, vm)` se `vm.status == SlotStatus.available`
- `lib/core/theme/app_spacing.dart` (novo) → importado em todos os screens/widgets para substituir literais

</code_context>

<specifics>
## Specific Ideas

- O usuário quer que a tela de agenda se pareça com o Google Agenda (Google Calendar) — usar o DayView do `calendar_view` como base, não uma lista melhorada
- Usar pacotes externos é explicitamente aceito para este objetivo
- O range de horas deve ser dinâmico (baseado nos slots cadastrados), não um intervalo fixo hardcoded

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 11-melhorias-visuais*
*Context gathered: 2026-03-26*

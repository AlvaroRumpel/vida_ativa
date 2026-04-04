# Phase 15: Agendamento Recorrente - Context

**Gathered:** 2026-04-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Cliente cria múltiplas reservas recorrentes de uma vez a partir do `BookingConfirmationSheet`. Seleciona dias da semana (mesmo horário), duração em semanas (1–52), e confirma em batch. Conflitos e slots inexistentes são detectados e exibidos. Inclui gerenciamento de cancelamento de grupo (cancelar só esta / esta + próximas futuras) e badge visual em `MyBookingsScreen`.

Scope expandido do BOOK-05 para incluir:
- Padrão multi-dia (ex: Ter + Qui mesmo horário)
- Cancelamento em grupo via `recurrenceGroupId`
- Badge "Recorrente" em BookingCard

</domain>

<decisions>
## Implementation Decisions

### Entry Point
- Toggle "Reservar semanalmente" inline dentro do `BookingConfirmationSheet` existente — não é um sheet separado
- Toggle sempre visível, independente de quantas semanas futuras existem
- Quando ativado, o sheet expande mostrando seleção de dias + slider + preview
- Botão muda de texto quando recorrente ativo: "Reservar [N] semanas" (ou variação indicando batch)

### Seleção de Dias da Semana
- Chips dos 7 dias da semana no sheet expandido; dia do slot de origem pré-selecionado
- Cliente pode ativar dias adicionais (ex: slot é Qui → ativa Ter também)
- Mesmo horário para todos os dias selecionados (não permite horário diferente por dia)

### Seleção de Duração
- Slider de 1 a 52 semanas
- Rótulo dinâmico ao lado: "N semanas (até [DiaSemana] DD/MMM)"
- Data final calculada sempre pelo mesmo dia da semana do slot de origem

### Preview de Datas (inline no sheet)
- Lista de datas geradas exibida dentro do sheet antes do submit
- Verificação PRÉVIA de disponibilidade: consulta Firestore para cada data/dia combinação
- Estados visuais:
  - Verde/normal: slot existe e disponível
  - Cinza + "Já reservado": slot existe mas tem booking ativo
  - Cinza + "Horário não cadastrado": slot não existe ainda no Firestore
- Truncamento: exibe as primeiras 4-6 datas + "+ N datas" quando lista longa (20+ semanas)
- Preview atualiza dinamicamente conforme slider é ajustado

### Criação em Batch
- `Future.wait()` — todas as reservas criadas em paralelo, não sequencialmente
- Cada booking recebe campo `recurrenceGroupId` (UUID gerado no momento do batch)
- Bookings com slot inexistente ou já ocupado são simplesmente ignorados (não tentados)
- Bookings disponíveis (slot existe, sem conflito) são criados via transaction individual (padrão `bookSlot`)

### Sheet de Resultado
- Após submit, sheet de resultado substitui/empilha sobre o confirmation sheet
- Exibe: "N reservas criadas" (verde) + lista de conflitos em âmbar (se houver)
- Conflito indica data + motivo ("já reservado" vs "horário não cadastrado")
- Botão "Fechar" encerra o fluxo

### recurrenceGroupId e BookingModel
- Novo campo opcional `recurrenceGroupId: String?` em `BookingModel`
- Todos os bookings de um mesmo batch recebem o mesmo UUID como `recurrenceGroupId`
- Reservas avulsas mantêm `recurrenceGroupId: null`

### Badge em MyBookingsScreen
- `BookingCard` exibe badge/chip pequeno "Recorrente" quando `booking.recurrenceGroupId != null`
- Lista permanece flat (não agrupada por série)
- Sem mudança na estrutura de seções "Próximas" e "Passadas"

### Cancelamento em Grupo (ClientBookingDetailSheet)
- Reservas recorrentes (`recurrenceGroupId != null`) exibem duas opções no `ClientBookingDetailSheet`:
  - "Cancelar só esta" — cancela o booking atual (fluxo existente)
  - "Cancelar esta e as próximas" — cancela esta + todos os bookings futuros (data > hoje) do mesmo `recurrenceGroupId`
- Reservas avulsas mantêm o comportamento atual (só "Cancelar")
- "Esta + próximas" cancela via batch update: query `bookings where recurrenceGroupId == X and date > hoje`, update cada um para `status: cancelled`

### Claude's Discretion
- Design visual exato do toggle (Switch vs Checkbox vs ToggleButton)
- Animação de expansão do sheet quando toggle é ativado
- UUID generation strategy para `recurrenceGroupId`
- Exact query strategy para verificação de disponibilidade no preview (batch get vs parallel gets)
- Tratamento de erros parciais no `Future.wait` (um erro não cancela os outros)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requisito original
- `.planning/REQUIREMENTS.md` §BOOK-05 — Requisito base de agendamento recorrente (escopo expandido conforme decisões acima)

### Padrões de booking existentes
- `lib/features/booking/cubit/booking_cubit.dart` — `bookSlot()` e `cancelBooking()` — padrões de transaction e stream reativo
- `lib/features/booking/ui/booking_confirmation_sheet.dart` — Sheet que será expandido com toggle de recorrência
- `lib/features/booking/ui/client_booking_detail_sheet.dart` — Sheet onde opções de cancelamento de grupo serão adicionadas
- `lib/features/booking/ui/booking_card.dart` — Card que receberá badge "Recorrente"
- `lib/features/booking/ui/my_bookings_screen.dart` — Tela onde cards recorrentes aparecem

### Modelo de dados
- `lib/core/models/booking_model.dart` — Receberá campo `recurrenceGroupId: String?`

### Padrão de batch admin (referência de implementação)
- `lib/features/admin/ui/slot_batch_sheet.dart` — Padrão de criação em batch existente no app

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `BookingCubit.bookSlot()` — Usado para cada booking individual do batch (transaction + deterministic ID)
- `BookingCubit.cancelBooking()` — Base para "cancelar só esta"; "cancelar próximas" precisará de novo método
- `BookingModel.generateId(slotId, date)` — Usado para verificação prévia de disponibilidade no preview
- `ClientBookingDetailSheet` — Recebe `BookingModel` + `BookingCubit`; adicionar lógica condicional de recorrência
- `BookingCard` — StatelessWidget com `BookingModel`; adicionar badge condicional baseado em `recurrenceGroupId`

### Established Patterns
- Sheets usam `StatefulWidget` com `_isSubmitting` + `_errorMessage` gerenciados localmente
- `BookingCubit` capturado fora do builder para evitar perda de contexto no subtree do sheet
- Stream reativo: `bookSlot` e `cancelBooking` não emitem estado — stream subscription reage automaticamente
- `isScrollControlled: true` em todos os `showModalBottomSheet` do app

### Integration Points
- `BookingConfirmationSheet` recebe `SlotViewModel` — contém `slot.id`, `dateString`, `slot.startTime`, `slot.price`
- `slot.startTime` (HH:mm) + `dateString` (YYYY-MM-DD) são a base para calcular datas futuras
- Verificação prévia requer query: `slots where date == X and startTime == Y` (ou get por ID determinístico se slotId for previsível — não é, pois IDs são gerados pelo Firestore)
- `recurrenceGroupId` deve ser gerado com `uuid` package (já presente como transitive dep via Firebase) ou `DateTime.now().millisecondsSinceEpoch.toString()`

</code_context>

<specifics>
## Specific Ideas

- "Parecido com Google Agenda esteticamente e funcionalmente" — chips de dias da semana, slider com data dinâmica, preview de datas como no Google Calendar
- Visualização das datas deve ser compacta mas informativa — não sobrecarregar o sheet
- Mesmo horário para todos os dias selecionados (ex: Ter + Qui sempre às 19:00)

</specifics>

<deferred>
## Deferred Ideas

- Horário diferente por dia de semana (ex: Ter 19:00 + Qui 20:00) — Phase 17
- Agrupamento de bookings recorrentes na lista de "Minhas Reservas" (colapsado por série) — Phase 17
- Notificação quando admin cria slots futuros compatíveis com recorrência existente — backlog

</deferred>

---

*Phase: 15-agendamento-recorrente*
*Context gathered: 2026-04-04*

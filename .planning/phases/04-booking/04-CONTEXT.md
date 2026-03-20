# Phase 4: Booking - Context

**Gathered:** 2026-03-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Usuário pode reservar um slot disponível, ver suas próprias reservas (futuras e passadas), e cancelar uma reserva futura — com transação atômica anti-double-booking via Firestore Transaction. Nenhuma funcionalidade admin nesta fase (confirmação manual é Phase 5).

</domain>

<decisions>
## Implementation Decisions

### Fluxo de reserva

- Slot disponível na agenda fica tappable (tap no `SlotCard`)
- Tap abre **bottom sheet** de confirmação com: horário, data selecionada, preço, botão "Reservar"
- Sem aviso de pagamento presencial — somente as informações essenciais do slot
- Botão "Reservar" mostra `CircularProgressIndicator` inline e fica desabilitado durante a transação (mesmo padrão do `FilledButton` da Phase 2 / Auth)
- Após sucesso: bottom sheet fecha + SnackBar "Reserva feita!"
- A agenda já é reativa (stream Firestore) — card atualiza para "Minha reserva" automaticamente sem reload

### Status inicial da reserva

- Toda reserva nova entra com status `"pending"` — admin confirma manualmente na Phase 5
- Na agenda (`SlotCard`), slot com reserva `pending` do próprio usuário exibe badge "Minha reserva" — igual ao `confirmed` (sem distinção visual entre pending/confirmed no SlotCard)
- `ScheduleCubit` já filtra `whereIn: ['pending', 'confirmed']` — slot fica como ocupado para outros usuários independente do status

### Tela Minhas Reservas

- Layout: **duas seções agrupadas** — "Próximas" (datas >= hoje, ordem crescente) e "Passadas" (datas < hoje, ordem decrescente)
- Card de reserva mostra: data formatada (ex: "Segunda, 24 Mar"), horário, preço em R$, badge de status
- Badge de status no card: "Aguardando" (pending), "Confirmado" (confirmed), "Cancelado" (cancelled)
- Cancelamento: botão "Cancelar" TextButton vermelho **inline no card** — visível apenas em reservas futuras (não em passadas)
- Tap em "Cancelar" abre `AlertDialog` de confirmação ("Cancelar esta reserva? Sim / Não")
- Após cancelamento bem-sucedido: card some da seção "Próximas" (ou move para passadas com status Cancelado)
- Estado vazio (sem reservas): mensagem "Você não tem nenhuma reserva ainda." + botão "Ver Agenda" que navega para Tab 0

### Claude's Discretion

- Implementação interna do `BookingCubit` (estados: loading, loaded, error)
- Estratégia de query Firestore para "Minhas Reservas" (stream por userId, filtro local de data)
- Loading state da tela Minhas Reservas (skeleton ou spinner)
- Erro de double booking simultâneo (segundo usuário): SnackBar de erro com mensagem clara (ex: "Este horário acabou de ser reservado.")
- Falha de rede durante a transação: mensagem de erro na bottom sheet, sem fechar

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` — BOOK-01, BOOK-02, BOOK-03 são os requisitos desta fase

### Roadmap
- `.planning/ROADMAP.md` §Phase 4 — Success criteria completos (4 critérios verificáveis)

### Foundation (Phase 1)
- `.planning/phases/01-foundation/01-CONTEXT.md` — BookingModel com ID determinístico `{slotId}_{date}`, regra: sempre `.doc(id).set()` dentro de Transaction, nunca `.add()`

### Schedule (Phase 3)
- `.planning/phases/03-schedule/03-CONTEXT.md` — SlotCard existente, SlotViewModel, SlotStatus enum, ScheduleCubit com filtro `whereIn: ['pending','confirmed']`, padrão de BlocConsumer

### Auth (Phase 2)
- `.planning/phases/02-auth/02-CONTEXT.md` — Padrão FilledButton com loading inline, AppTheme.primaryGreen, AuthCubit para obter userId

### Projeto
- `.planning/PROJECT.md` — Stack, BookingModel.generateId(), concern sobre offline persistence + transactions

No external specs — requirements fully captured in decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/core/models/booking_model.dart` — BookingModel com `generateId(slotId, date)`, `isPending`/`isConfirmed`/`isCancelled` getters, serialização Firestore completa
- `lib/features/schedule/ui/slot_card.dart` — SlotCard com borda colorida + `_StatusLabel`; `SlotStatus.available` está definido mas sem handler de tap — adicionar `GestureDetector` ou `InkWell`
- `lib/features/schedule/models/slot_view_model.dart` — SlotViewModel conecta `SlotModel` + `SlotStatus`; Phase 4 vai precisar também do `BookingModel` associado para passar à bottom sheet
- `lib/features/booking/ui/my_bookings_placeholder_screen.dart` — Placeholder a substituir
- `lib/core/theme/app_theme.dart` — `primaryGreen (#2E7D32)`, `primaryBlue (#0175C2)` para status badges

### Established Patterns
- BLoC: `Cubit<State>` por feature; `BlocConsumer` para listener + builder combinados (padrão Phase 2+)
- Firestore: stream listener via `.snapshots()` para dados reativos
- Loading em botões: `CircularProgressIndicator` inline dentro de `FilledButton` — sem layout shift
- Erros: mensagem inline ou SnackBar (sem modais de erro)

### Integration Points
- `lib/features/schedule/ui/slot_card.dart` → adicionar `onTap` callback para slot disponível (passado pelo `SlotList`)
- `lib/core/router/app_router.dart` → `/bookings` (Tab 1) já declarado com `MyBookingsPlaceholderScreen` — substituir builder
- Firestore `/bookings` collection — escrita (Transaction) e leitura (query por `userId`)
- `AuthCubit` → acessar `userId` do usuário logado para criar e filtrar bookings
- STATE.md concern: **desabilitar Firestore offline persistence para writes de booking** — `FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false)` antes da transação, ou desabilitar globalmente no Flutter Web

</code_context>

<specifics>
## Specific Ideas

- Bottom sheet de confirmação: mostrar a data por extenso (ex: "Segunda-feira, 24 de março") junto com horário e preço — contexto claro para quem reserva
- Botão "Cancelar" no card de reserva: TextButton com cor vermelha (`Colors.red`) — visualmente distinto sem ser agressivo
- Badge de status no card de Minhas Reservas: chip colorido pequeno — "Aguardando" (laranja/amarelo), "Confirmado" (verde), "Cancelado" (cinza)

</specifics>

<deferred>
## Deferred Ideas

- Prazo mínimo de cancelamento (ex: só pode cancelar com 2h de antecedência) — BOOK-v2-01 já no backlog v2
- Notificação push quando reserva é confirmada — NOTF-v2-01 no backlog v2
- Configuração de modo de confirmação (automático vs manual) pelo admin — ADMN-06 na Phase 5

</deferred>

---

*Phase: 04-booking*
*Context gathered: 2026-03-19*

# Phase 3: Schedule - Context

**Gathered:** 2026-03-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Exibição read-only da agenda semanal: usuário navega entre semanas, seleciona um dia, e vê a lista de slots com status (disponível/ocupado/bloqueado) e preço. Nenhuma ação de reserva nesta fase — Phase 4 adiciona o botão de reservar ao card existente.

</domain>

<decisions>
## Implementation Decisions

### Visual dos slots

- Card com borda lateral colorida pelo status (não fundo sólido — borda tintada)
- Conteúdo do card: horário + preço + label de status — nada mais (`SlotModel` não tem `duration` nem `name`)
- Phase 3 é puramente read-only: sem botão de reserva, sem placeholder de botão
- Slots inativos (`isActive = false`) somem completamente da lista — usuário nunca os vê

### Status visual

- **Disponível** → verde (`#2E7D32`, `AppTheme.primaryGreen`)
- **Ocupado** → cinza neutro (sem distinção de quem reservou, exceto para o próprio usuário)
- **Bloqueado** → vermelho/rose
- **Minha reserva** → mesma cor de "Ocupado" (cinza) mas com badge ou label "Minha reserva"
- **Pending** → tratado igual a "Ocupado" — slot não está disponível independente do status da reserva

### Seletor de dias da semana

- Row horizontal com chips scrolláveis: `Seg 17`, `Ter 18`, etc. (dia abreviado + número da data)
- Chip selecionado = destaque com cor primária verde
- Ao abrir a tela: hoje é selecionado por padrão
- Header acima dos chips: `< | Semana de 17–23 Mar | >` com setas de navegação
- Seta `<` desabilitada quando já está na semana atual (não permite ver o passado)
- Limite de 8 semanas à frente — seta `>` desabilitada ao atingir o limite

### Estados vazios e dados ausentes

- Dia sem slots → mensagem simples centrada: "Nenhum horário disponível para este dia."
- Data bloqueada → chip sem marcação especial; ao selecionar: mensagem "Dia bloqueado — sem horários disponíveis."
- Loading → skeleton cards (3–4 cards cinza pulsando) na área de slots enquanto carrega do Firestore

### Claude's Discretion

- Implementação interna do ScheduleCubit (estados: loading, loaded, error)
- Formato exato da query Firestore (stream por dia vs semana completa)
- Lógica de determinação do status do slot (disponível/ocupado/minha reserva/bloqueado)
- Animação de transição ao trocar de dia
- Estilo exato do skeleton loader

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` — SCHED-01, SCHED-02, SCHED-03 são os requisitos desta fase

### Roadmap
- `.planning/ROADMAP.md` §Phase 3 — Success criteria completos (4 critérios verificáveis)

### Foundation (Phase 1)
- `.planning/phases/01-foundation/01-CONTEXT.md` — Estrutura de pastas, modelos de dados, BLoC sem root wrapper

### Auth (Phase 2)
- `.planning/phases/02-auth/02-CONTEXT.md` — Padrão BlocConsumer, AppTheme.primaryGreen, patterns de BLoC por feature

### Projeto
- `.planning/PROJECT.md` — Stack (flutter_bloc, go_router, cloud_firestore), decisões de arquitetura

No external specs — requirements fully captured in decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/core/models/slot_model.dart` — `dayOfWeek` (1=Seg..7=Dom), `startTime` ("HH:mm"), `price`, `isActive`
- `lib/core/models/booking_model.dart` — `slotId`, `date` ("YYYY-MM-DD"), `userId`, `status` (pending/confirmed/cancelled); `generateId(slotId, date)` → ID determinístico
- `lib/core/models/blocked_date_model.dart` — `date` ("YYYY-MM-DD") é o document ID
- `lib/core/theme/app_theme.dart` — `primaryGreen (#2E7D32)`, Material 3 theme
- `lib/features/schedule/ui/schedule_placeholder_screen.dart` — Placeholder a substituir
- `lib/features/auth/cubit/auth_cubit.dart` — AuthCubit disponível via BlocProvider para pegar userId do usuário logado

### Established Patterns
- BLoC: `Cubit<State>` por feature; `BlocConsumer` para listener + builder combinados
- Firestore: stream listener via `.snapshots()` para dados reativos
- Rotas: `/home` → ScheduleScreen no `StatefulShellRoute` (Tab 0)
- BookingModel.generateId(slotId, date) → usado para lookup de reserva existente sem query extra

### Integration Points
- `lib/core/router/app_router.dart` → `/home` já aponta para `SchedulePlaceholderScreen` — substituir builder
- `lib/features/schedule/` → criar: `cubit/schedule_cubit.dart`, `cubit/schedule_state.dart`, `ui/schedule_screen.dart`
- Firestore collections: `/slots` (leitura), `/bookings` (leitura para status do slot), `/blockedDates` (leitura)
- Auth state: precisar do `userId` atual para marcar "Minha reserva" — acessar via `context.read<AuthCubit>().state`

</code_context>

<specifics>
## Specific Ideas

- Card com borda lateral colorida (tipo indicator bar), não fundo sólido — mais elegante e leve
- "Minha reserva" como badge/label especial no card — usuário sabe que aquele slot é dele
- Chips de dia devem mostrar abreviação do dia EM PORTUGUÊS (Seg, Ter, Qua, Qui, Sex, Sáb, Dom)
- Skeleton loader para o estado de loading — padrão moderno, evita layout shift

</specifics>

<deferred>
## Deferred Ideas

- Nenhuma ideia fora de escopo surgiu — discussão manteve-se dentro dos limites da Phase 3

</deferred>

---

*Phase: 03-schedule*
*Context gathered: 2026-03-20*

# Phase 7: Visibilidade Social - Context

**Gathered:** 2026-03-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Adicionar visibilidade social à agenda e ao fluxo de reserva: clientes veem quem reservou cada horário, podem informar com quem vão jogar (participantes), e o admin enxerga os participantes diretamente na listagem de reservas — sem abrir cada item.

Fora do escopo desta fase: compartilhar reserva via WhatsApp (Phase 8), edição de perfil (Phase 8), toggle admin/cliente (Phase 9).

</domain>

<decisions>
## Implementation Decisions

### Nome na agenda (SOCIAL-01)

- Slot ocupado por **outro usuário**: mostrar `booking.userDisplayName` (nome completo, ex: "João Silva") no lugar do label "Ocupado"
- Slot de **minha reserva**: mantém o badge "Minha reserva" — sem alteração
- **Fallback** quando `userDisplayName` é null (raro, mas possível): mostrar "Ocupado" sem nome — não usar "Cliente" aqui

### Campo de participantes (SOCIAL-02)

- Campo **opcional**, sem obrigatoriedade — reserva é concluída normalmente sem preenchimento
- **Label:** "Quem vai jogar? (opcional)"
- **Hint/placeholder:** "Ex: João, Maria, Pedro"
- **Limite:** 200 caracteres
- **Posição na BookingConfirmationSheet:** depois das linhas de data/hora/preço, antes do botão "Reservar"
- **Editável pós-reserva:** ícone de editar no BookingCard em MyBookingsScreen — toca no ícone, abre campo inline ou dialog simples para atualizar participants no Firestore

### Admin: participantes na listagem (ADMN-09)

- Participantes aparecem **abaixo do nome do cliente**, em linha dedicada (não na linha de horário/preço)
- Ícone de grupo (👥 ou `Icons.group`) antes dos nomes: `👥 Maria, Pedro`
- Linha **omitida** quando `participants` é null ou vazio — sem placeholder "Sem participantes"

### Claude's Discretion

- Tipografia exata dos campos (tamanho de fonte, peso) para os nomes na agenda e na listagem admin
- Animação/transição ao abrir o campo de edição de participantes no BookingCard
- Posicionamento exato do ícone de editar no BookingCard (trailing icon, IconButton pequeno)
- Número de `maxLines` do campo de participantes (sugestão: 2)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requisitos da fase
- `.planning/REQUIREMENTS.md` — SOCIAL-01, SOCIAL-02, ADMN-09 com critérios de aceitação
- `.planning/ROADMAP.md` §Phase 7 — success criteria da fase (4 critérios)

### Regras de segurança Firestore
- `firestore.rules` — **JÁ permite** `allow read: if isAuthenticated()` para a coleção `bookings`. Nenhuma alteração de regra necessária para SOCIAL-01. Confirmar antes de planejar qualquer mudança de rules.

No external specs or ADRs — requirements fully captured in decisions above and in REQUIREMENTS.md.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`BookingModel`** (`lib/core/models/booking_model.dart`): já tem `userDisplayName: String?` e padrão de campos nullable com `if (field != null)` em `toFirestore()`. Adicionar `participants: String?` segue exatamente o mesmo padrão.
- **`SlotViewModel`** (`lib/features/schedule/models/slot_view_model.dart`): atualmente carrega `slot`, `status`, `dateString`. Precisa de `bookerName: String?` adicionado para propagar o nome do reservante para o `SlotCard`.
- **`SlotCard`** (`lib/features/schedule/ui/slot_card.dart`): switch em `SlotStatus` para renderizar o label direito. Para SOCIAL-01, o caso `SlotStatus.booked` passa a mostrar o `bookerName` (ou "Ocupado" se null) em vez do texto fixo "Ocupado".
- **`BookingConfirmationSheet`** (`lib/features/booking/ui/booking_confirmation_sheet.dart`): `StatefulWidget` gerenciando `_isSubmitting`/`_errorMessage`. Campo de participants é um novo `TextEditingController` + `TextField` inserido antes do botão "Reservar". Já usa `bookingCubit.bookSlot()` — assinatura precisa aceitar `participants`.
- **`AdminBookingCard`** (`lib/features/admin/ui/admin_booking_card.dart`): já mostra `clientName` (de `booking.userDisplayName`). Adicionar linha condicional de participants abaixo do nome, antes do `startTime`/`price`.
- **`BookingCard`** (`lib/features/booking/ui/booking_card.dart`): tela MyBookings — adicionar ícone de editar para participants. Novo `StatefulWidget` ou dialog para o campo inline.

### Established Patterns

- **Nullable optional fields no BookingModel:** padrão `if (field != null) 'field': field` em `toFirestore()` — `participants` segue o mesmo.
- **`ScheduleCubit._resolveStatus()`**: já tem acesso ao `BookingModel` completo (incluindo `userDisplayName`). Pode retornar o nome junto com o status — ou `_recompute()` pode mapear booking → bookerName ao criar o `SlotViewModel`.
- **`BookingCubit.bookSlot()`**: aceita parâmetros nomeados (`slotId`, `dateString`, `price`, `startTime`, `userDisplayName`) — adicionar `participants: String?` como parâmetro opcional segue o mesmo padrão.
- **`AdminBookingCubit.selectDate()`**: usa stream do Firestore que carrega `BookingModel` completo via `fromFirestore()` — quando `participants` for adicionado ao model, aparece automaticamente sem mudança no cubit.

### Integration Points

- `ScheduleCubit._recompute()` → `SlotViewModel` (precisa de `bookerName`)
- `BookingCubit.bookSlot()` → `BookingModel.toFirestore()` (precisa de `participants`)
- `BookingCard` em `MyBookingsScreen` → novo update de `participants` via `BookingCubit` ou direct Firestore call
- `AdminBookingCard` → `BookingModel.participants` (leitura, sem escrever)
- `firestore.rules` → `bookings` read: já `isAuthenticated()` — **sem mudança necessária**

</code_context>

<specifics>
## Specific Ideas

- Campo de participantes é "campo livre" — sem autocomplete, sem formato obrigatório (string simples separada por vírgula ou espaço, a critério do usuário)
- Edição pós-reserva: ícone pequeno no card de MyBookings; abrir campo inline ou dialog simples — não um BottomSheet completo

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 07-visibilidade-social*
*Context gathered: 2026-03-25*

# Phase 27: Admin Slots + Reservas + Usuários - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 27 redesenha as três abas operacionais do painel admin com identidade Arena Esportivo:
- `slot_management_tab.dart` — rows hairline para slots, day selector underline, Anton 32px
- `booking_management_tab.dart` — AdminBookingRow novo widget, Anton 36px, pills Confirmar/Recusar
- `users_management_tab.dart` — avatar foto/inicial, UserDetailSheet novo, rows hairline

Completa: ADMN-16, ADMN-17, ADMN-18, ADMN-19, ADMN-20, ADMN-21

Fora de escopo: lógica de BLoC/Cubits/models, Cloud Functions, Phase 28 (Preços/Ajustes), Phase 29 (Dashboard).

</domain>

<decisions>
## Implementation Decisions

### Aba Slots — SlotRow Layout (ADMN-16, ADMN-17)

- **D-01:** Slot vazio: hora em Anton 32px + valor (preço) + switch ativo/inativo à direita. Sem label de status. Sem fundo colorido.
- **D-02:** Slot reservado: hora em Anton 32px laranja + nome do reservante em Manrope + esporte. Sem Container colorido com border-left.
- **D-03:** Tap em slot vazio → abre `SlotFormSheet` existente (sem reescrita).
- **D-04:** Tap em slot reservado → abre `AdminBookingDetailSheet` existente para ver detalhes da reserva.
- **D-05:** Day selector redesenhado: mesmo padrão underline laranja da Phase 24 (SportDayStrip) + botões ← → para navegar dias. Remove `ChoiceChip` com `backgroundColor: Color(0xFFF0EDE8)` e `selectedColor: AppTheme.primaryGreen`.
- **D-06:** Switch ativo/inativo permanece funcional — só atualiza visual para AppTheme tokens (remove `Colors.grey`, `primaryGreen`).

### Aba Reservas — AdminBookingRow (ADMN-18, ADMN-19)

- **D-07:** Criar `lib/features/admin/ui/admin_booking_row.dart` — widget novo separado de `HairlineBookingRow` (cliente usa 26px, admin usa 36px; admin tem ações inline).
- **D-08:** `AdminBookingCard` substituído completamente por `AdminBookingRow`. Dead code — remover nesta phase.
- **D-09:** Layout do row: hora em Anton 36px + nome em Manrope + participantes em Manrope + status em mono uppercase colorido.
- **D-10:** Pills Confirmar/Recusar: visíveis apenas quando `status == 'pending'`. Inline à direita do status, sem fundo colorido (outline pill, padrão Phase 26).
- **D-11:** Hairline divisória entre rows: `Border(top: BorderSide(color: AppTheme.lineHair, width: 0.5))` — mesmo padrão Phase 26.

### Aba Usuários — UserRow + UserDetailSheet (ADMN-20, ADMN-21)

- **D-12:** Avatar circular: tenta carregar `photoUrl` do Firebase Auth via `Image.network`. Se ausente ou erro → fallback: inicial do nome em Anton, círculo laranja para admin, círculo ink para usuário comum.
- **D-13:** Row exibe: avatar + nome em Manrope bold + email em JBM mono + contador de reservas em JBM mono. Sem gradiente, sem `primaryGreen`.
- **D-14:** Tap em user row → abre `UserDetailSheet` (novo bottom sheet Arena).
- **D-15:** `UserDetailSheet` conteúdo: drag handle + avatar grande + nome + email + contagem de reservas + botões "PROMOVER A ADMIN" / "REMOVER ADMIN" em SportBtn. Ações existentes migradas do inline tab para a sheet.

### Claude's Discretion
- Padding interno dos rows (horizontal 16px, vertical — Claude decide)
- Tamanho do Anton no day selector (usar mesmo da Phase 24 SportDayStrip)
- Tamanho do avatar circular e do avatar expandido na UserDetailSheet
- Cor do contador de reservas (AppTheme.concrete ou AppTheme.ink)
- Animação de entrada da UserDetailSheet

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requisitos
- `.planning/REQUIREMENTS.md` §ADMN-16, §ADMN-17, §ADMN-18, §ADMN-19, §ADMN-20, §ADMN-21

### Design System
- `lib/core/theme/app_theme.dart` — AppTheme completo; NÃO modificar
- `.planning/research/PITFALLS.md` — pitfalls v6.0 (Anton height clip, hardcoded colors)

### Padrões de Referência (fases anteriores)
- `lib/features/booking/ui/hairline_booking_row.dart` — padrão hairline row Phase 26 (adaptar para admin)
- `lib/features/schedule/ui/sport_day_strip.dart` — day selector underline laranja Phase 24
- `lib/core/widgets/sport_btn.dart` — SportBtn filled/outlined para ações na UserDetailSheet
- `lib/features/admin/ui/admin_screen.dart` — frame admin Phase 25 (header inline, TabBar)

### Arquivos a Modificar
- `lib/features/admin/ui/slot_management_tab.dart` — redesign completo
- `lib/features/admin/ui/booking_management_tab.dart` — substituir AdminBookingCard por AdminBookingRow
- `lib/features/admin/ui/users_management_tab.dart` — redesign rows + tap → UserDetailSheet

### Arquivos a Criar
- `lib/features/admin/ui/admin_booking_row.dart` — novo widget
- `lib/features/admin/ui/user_detail_sheet.dart` — novo bottom sheet

### Arquivos a Remover
- `lib/features/admin/ui/admin_booking_card.dart` — substituído por AdminBookingRow

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `sport_btn.dart` — SportBtn.filled / SportBtn.outlined para actions na UserDetailSheet
- `hairline_booking_row.dart` — referência de padrão hairline; admin precisa de variante própria
- `sport_day_strip.dart` — referência de day selector underline; adaptar para navigation ← →
- `admin_booking_detail_sheet.dart` — sheet existente para tap em slot reservado (não reescrever)
- `slot_form_sheet.dart` + `slot_batch_sheet.dart` — sheets existentes para editar slot (não reescrever)

### Established Patterns
- Hairline rows: `DecoratedBox` com `Border(top: BorderSide(color: AppTheme.lineHair, width: 0.5))`
- Sem fundo colorido: remover todos `Container(color: ...)` e `Color(0xFF...)`
- Status pill outline: `Container(decoration: BoxDecoration(border: Border.all(...), borderRadius: circular))`
- Faixa laranja 2px: `IntrinsicHeight + Row([Container(width:2, color:AppTheme.orange), Expanded(...)])`

### Integration Points
- `BookingCubit` / `BookingState` — aba Reservas lê desse cubit
- `SlotCubit` — aba Slots
- `UsersCubit` (ou similar) — aba Usuários (verificar nome exato)
- Firebase Auth `photoUrl` — para avatar na aba Usuários

</code_context>

<specifics>
## Specific Ideas

- UserDetailSheet: consolidar ações de admin (Promover/Remover) que hoje ficam inline no tab — melhora UX do admin
- Slot row reservado: laranja no Anton sinaliza "ocupado" sem fundo colorido
- Pills Confirmar/Recusar só para pending: evita poluição visual em reservas já resolvidas

</specifics>

<deferred>
## Deferred Ideas

- Histórico de reservas por usuário na UserDetailSheet — requer query Firestore adicional; fase futura
- Filtros/busca na aba Reservas admin — nova capability; fase futura

</deferred>

---

*Phase: 27-admin-slots-reservas-usu-rios*
*Context gathered: 2026-06-04*

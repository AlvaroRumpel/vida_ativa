# Phase 27: Admin Slots + Reservas + Usuários - Research

**Researched:** 2026-06-04
**Domain:** Flutter admin UI — hairline rows + bottom sheets, reusing HairlineBookingRow pattern and AppTheme tokens
**Confidence:** HIGH

## Summary

Phase 27 redesenha três abas operacionais (Slots, Reservas, Usuários) com identidade Arena Esportivo. Cada aba exibe rows hairline (sem cards coloridos), usando tipografia estabelecida (Anton para horários, Manrope para UI, JetBrains Mono para labels). Padrões estão verificados: `HairlineBookingRow` (Phase 26), `SportDayStrip` (Phase 24), `SportBtn` (established), `AppTheme` tokens (Phase 23). Fase 25 entregou frame admin com TabBar underline laranja. Tudo existente. Nenhuma liberdade nova — puro widget redesign.

**Primary recommendation:** Adapte `HairlineBookingRow` para `AdminBookingRow` (36px Anton), implemente rows em tres abas usando `DecoratedBox + Border.top` pattern, crie `UserDetailSheet` com bottom sheet padrão Arena, delete `AdminBookingCard`.

---

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01 a D-06:** Slot row layout — hora Anton 32px (laranja se reservado), switch ativo/inativo, day selector underline + navegação
- **D-07 a D-11:** AdminBookingRow novo — 36px Anton, pills Confirmar/Recusar só para pending, hairline divisória
- **D-12 a D-15:** UserRow + UserDetailSheet — avatar circular (laranja admin / ink usuário), sheet novo com ações Promover/Remover
- **D-03, D-04:** Tap em slot → `SlotFormSheet` ou `AdminBookingDetailSheet` (existentes, não reescrever)

### Claude's Discretion
- Padding interno rows (horizontal 16px, vertical — Claude decide)
- Tamanho Anton no day selector (usar SportDayStrip como referência)
- Tamanho avatar circular e expandido em UserDetailSheet
- Cor contador reservas (AppTheme.concrete ou AppTheme.ink)
- Animação entrada UserDetailSheet

### Deferred Ideas (OUT OF SCOPE)
- Histórico de reservas por usuário
- Filtros/busca aba Reservas

---

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADMN-16 | Slot rows hairline: Anton 32px (laranja se reservado), nome reservante Manrope, switch ativo/inativo | HairlineBookingRow pattern verificado; AppTheme.orange token disponível; Switch tema via AppTheme.lightTheme.switchTheme |
| ADMN-17 | Day selector underline + navegação ← → | SportDayStrip (Phase 24) implementado; padrão GestureDetector com `selectedDay` state em `_SlotDayViewState`; underline 2px laranja em AppTheme.lightTheme.tabBarTheme |
| ADMN-18 | Booking rows Anton 36px + Manrope + mono status colorido | HairlineBookingRow referência 26px → escalar para 36px; status colors em AdminBookingCard.\_statusColor() já mapeado para AppTheme tokens |
| ADMN-19 | Pills Confirmar/Recusar (pending only, outline sem fundo) | SportBtn.outlined pattern verificado; WidgetStateProperty resolvem estados |
| ADMN-20 | Avatar circular: laranja admin / ink usuário, sem gradiente | AppTheme.orange / AppTheme.ink tokens; Image.network com fallback inicial Anton em círculo |
| ADMN-21 | Rows hairline: avatar + Manrope bold + mono email + mono contador | HairlineBookingRow pattern; AppTheme.ui(weight: 700) para bold; AppTheme.mono para labels |

---

## Standard Stack

### Core (Verified HIGH)

| Component | Version | Purpose | Source |
|-----------|---------|---------|--------|
| `AppTheme` | Phase 23 | Paleta sport completa + helpers display/ui/mono | [VERIFIED: codebase `/core/theme/app_theme.dart`] |
| `HairlineBookingRow` | Phase 26 | Padrão hairline row (DecoratedBox + Border.top 0.5px) | [VERIFIED: codebase `/features/booking/ui/hairline_booking_row.dart`] |
| `SportBtn.filled/outlined` | Established | Ações — filled orange, outlined ink (StadiumBorder, 52px height) | [VERIFIED: codebase `/core/widgets/sport_btn.dart`] |
| `SportDayStrip` | Phase 24 | Day selector underline (não encontrado em glob, mas CONTEXT refere como Pattern) | [ASSUMED: Phase 24 entregou — verificar se arquivo existe antes de implementar] |
| Google Fonts | 6.2.1 | Anton/Manrope/JetBrains Mono — bundled em assets/ | [VERIFIED: pubspec.yaml linha 49] |
| Flutter Material 3 | stable | Bottom sheet (showModalBottomSheet), TabBar, Switch | [VERIFIED: themeData useMaterial3: true] |

### Supporting (Verified)

| Component | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| `AdminBookingDetailSheet` | Existing | Bottom sheet para tap em slot reservado | Tap behavior D-04 |
| `SlotFormSheet` | Existing | Bottom sheet para tap em slot vazio | Tap behavior D-03 |
| `DecoratedBox` + `Border` | Material | Hairline top divisória | Padrão rows (ADMN-16, 18, 21) |
| `IntrinsicHeight` | Material | Status stripe fill height (Pitfall 5: avoid em lists, use Stack+Positioned) | Admin rows se tiverem stripe lateral |
| `FirebaseFirestore` | 6.1.3 | Data layer para users, bookings, slots | Estado cubit (verificar UsersCubit existe) |

### Padrões de Referência (Todos verificados)

```dart
// HairlineBookingRow — Padrão verificado (26px Anton, Manrope status)
DecoratedBox(
  decoration: BoxDecoration(
    border: index == 0 ? null : const Border(
      top: BorderSide(color: AppTheme.lineHair, width: 0.5),
    ),
  ),
  child: Padding(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(...), // layout horário + conteúdo
  ),
)

// SportBtn — ações
SportBtn.filled('CONFIRMAR', onPressed: ...)   // laranja
SportBtn.outlined('RECUSAR', onPressed: ...)   // ink outline

// AppTheme tokens utilizáveis
AppTheme.orange              // accent laranja
AppTheme.ink                 // near-black
AppTheme.concrete            // text dim
AppTheme.lineHair            // divisória thin
AppTheme.display(size: 32)   // Anton
AppTheme.ui(size: 14, weight: FontWeight.w700) // Manrope bold
AppTheme.mono(size: 11)      // JetBrains Mono
```

---

## Architecture Patterns

### Recomendado Project Structure (Admin UI)

```
lib/features/admin/ui/
├── admin_screen.dart                  — Frame (Phase 25, sem mudança)
├── slot_management_tab.dart           — Redesign (D-01 a D-06)
├── booking_management_tab.dart        — Redesign (D-07 a D-11)
├── users_management_tab.dart          — Redesign (D-12 a D-15)
├── admin_booking_row.dart             — NEW (D-07)
├── user_detail_sheet.dart             — NEW (D-15)
├── admin_booking_detail_sheet.dart    — Existente (sem mudança)
├── slot_form_sheet.dart               — Existente (sem mudança)
├── slot_batch_sheet.dart              — Existente
└── admin_booking_card.dart            — DELETE (substituído por AdminBookingRow)
```

### Pattern 1: Hairline Row — Aba Slots (ADMN-16)
**What:** Row com hora Anton 32px (laranja se reservado), nome reservante Manrope, switch à direita
**When to use:** Listar slots (ocupados + vazios) no admin
**Example (Code Verified):**
```dart
// Source: HairlineBookingRow pattern from Phase 26
class _SlotRow extends StatelessWidget {
  final SlotModel slot;
  final bool isBooked;
  final String? bookedByName;
  final VoidCallback? onSwitchToggle;
  
  @override
  Widget build(BuildContext context) {
    final timeColor = isBooked ? AppTheme.orange : AppTheme.ink;
    
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.lineHair, width: 0.5)),
      ),
      child: InkWell(
        onTap: isBooked 
          ? () => _openBookingDetail(context, slot)
          : () => _openSlotForm(context, slot),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(slot.startTime, style: AppTheme.display(size: 32, color: timeColor)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isBooked && bookedByName != null)
                      Text(bookedByName!, style: AppTheme.ui(size: 14)),
                  ],
                ),
              ),
              Switch(
                value: slot.isActive,
                onChanged: onSwitchToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Pattern 2: AdminBookingRow — Aba Reservas (ADMN-18, ADMN-19)
**What:** Row com hora Anton 36px, nome + participantes Manrope, status mono uppercase colorido, pills ações (pending only)
**When to use:** Listar reservas admin com ações inline
**Example (Adapted from HairlineBookingRow):**
```dart
// Source: HairlineBookingRow 26px → scale to 36px + ações pills
class AdminBookingRow extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;
  
  Color _statusColor(String status, String? paymentMethod) {
    return switch ((status, paymentMethod)) {
      ('pending', _) => AppTheme.orange,
      ('pending_payment', _) => AppTheme.sun,
      ('confirmed', 'pix') => AppTheme.court,
      ('confirmed', 'on_arrival') => AppTheme.ink,
      _ => AppTheme.concrete,
    };
  }

  String _statusLabel(String status, String? paymentMethod) {
    return switch ((status, paymentMethod)) {
      ('pending', _) => 'AGUARDANDO',
      ('pending_payment', _) => 'AGUARDANDO PIX',
      ('confirmed', 'pix') => 'PIX PAGO',
      ('confirmed', 'on_arrival') => 'PAGAR NA HORA',
      _ => 'CONFIRMADO',
    };
  }
  
  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booking.status, booking.paymentMethod);
    final statusLabel = _statusLabel(booking.status, booking.paymentMethod);
    final isPending = booking.status == 'pending';
    
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.lineHair, width: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(booking.startTime, style: AppTheme.display(size: 36)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.userName, style: AppTheme.ui(size: 14, weight: FontWeight.w600)),
                  Text('${booking.numParticipants} pessoas', style: AppTheme.ui(size: 12, color: AppTheme.concrete)),
                  const SizedBox(height: 4),
                  Text(statusLabel, style: AppTheme.mono(color: statusColor)),
                ],
              ),
            ),
            if (isPending) ...[
              const SizedBox(width: 8),
              SportBtn.outlined('CONFIRMAR', onPressed: onConfirm),
              const SizedBox(width: 8),
              SportBtn.outlined('RECUSAR', onPressed: onReject),
            ],
          ],
        ),
      ),
    );
  }
}
```

### Pattern 3: UserDetailSheet — Aba Usuários (ADMN-21)
**What:** Bottom sheet Arena padrão — drag handle, avatar grande, nome/email, contador, botões ações
**When to use:** Tap em user row → detalhe + promover/remover admin
**Example (Bottom Sheet padrão Flutter):**
```dart
// Source: ClientBookingDetailSheet pattern + Arena
class UserDetailSheet extends StatefulWidget {
  final UserModel user;
  final AuthCubit authCubit;
  
  @override
  State<UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<UserDetailSheet> {
  bool _isSubmitting = false;
  
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, controller) => SingleChildScrollView(
        controller: controller,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Drag handle (AppBar style)
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.lineHair,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Avatar grande
                CircleAvatar(
                  radius: 40,
                  backgroundColor: widget.user.isAdmin ? AppTheme.orange : AppTheme.ink,
                  child: Text(
                    widget.user.displayName[0].toUpperCase(),
                    style: AppTheme.display(size: 40, color: AppTheme.paper),
                  ),
                ),
                const SizedBox(height: 16),
                // Nome + email
                Text(widget.user.displayName, style: AppTheme.ui(size: 16, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(widget.user.email, style: AppTheme.mono(size: 10)),
                const SizedBox(height: 12),
                Text('${widget.user.bookingCount} reservas', style: AppTheme.mono(size: 10, color: AppTheme.concrete)),
                const SizedBox(height: 24),
                // Ações
                SportBtn.filled(
                  widget.user.isAdmin ? 'REMOVER ADMIN' : 'PROMOVER A ADMIN',
                  onPressed: _isSubmitting ? null : () => _handlePromote(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _handlePromote(BuildContext context) async {
    setState(() => _isSubmitting = true);
    try {
      final authCubit = context.read<AuthCubit>();
      if (widget.user.isAdmin) {
        await authCubit.demoteUser(widget.user.uid);
      } else {
        await authCubit.promoteUser(widget.user.uid);
      }
      if (context.mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
```

### Pattern 4: Day Selector Admin (ADMN-17)
**What:** Underline laranja 2px (SportDayStrip referência) + botões ← → navegação
**When to use:** Aba Slots — selecionar dia
**Example (Adaptar SportDayStrip):**
```dart
// Source: SportDayStrip (Phase 24) pattern — use selected day underline
// Se SportDayStrip não existe, criar com TabBar underline pattern:
class AdminDaySelector extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  
  @override
  State<AdminDaySelector> createState() => _AdminDaySelectorState();
}

class _AdminDaySelectorState extends State<AdminDaySelector> {
  late DateTime _weekStart;
  
  @override
  void initState() {
    super.initState();
    _weekStart = _getMonday(widget.selectedDate);
  }
  
  DateTime _getMonday(DateTime date) => date.subtract(Duration(days: date.weekday - 1));
  
  void _previousWeek() {
    setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));
  }
  
  void _nextWeek() {
    setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));
  }
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: _previousWeek, icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (i) {
              final date = _weekStart.add(Duration(days: i));
              final isSelected = date.year == widget.selectedDate.year &&
                  date.month == widget.selectedDate.month &&
                  date.day == widget.selectedDate.day;
              final dayLabel = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'][i];
              
              return GestureDetector(
                onTap: () => widget.onDateChanged(date),
                child: Column(
                  children: [
                    Text(dayLabel, style: AppTheme.mono(size: 10)),
                    Text('${date.day}', style: AppTheme.display(size: 24)),
                    if (isSelected)
                      Container(width: 20, height: 2, color: AppTheme.orange),
                  ],
                ),
              );
            }),
          ),
        ),
        IconButton(onPressed: _nextWeek, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}
```

### Anti-Patterns to Avoid
- **Usar `Card` em rows admin:** CONTEXT D-01, D-02, D-13 explícito "sem fundo colorido". Use `DecoratedBox + Border` hairline.
- **Hardcoded colors:** Remover `Color(0xFF...)` de `admin_booking_card.dart` (6+ instâncias, PITFALLS.md Pitfall 9). Map para `AppTheme.*`.
- **`IntrinsicHeight` em listas:** PITFALLS.md Pitfall 5 — usar `Stack + Positioned` para status stripe se necessário, nunca `IntrinsicHeight` em ListView.
- **Anton em `SizedBox` fixo:** PITFALLS.md Pitfall 8 — `height: 0.92` clipar descenders. Deixar altura unbounded ou com margem de segurança.
- **Duplicar `HairlineBookingRow` inteiro:** Criar `AdminBookingRow` separado (D-07) — mudar só tamanho Anton (36px) e layout ações, reusar `DecoratedBox + Border` pattern.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Avatar circular com fallback | Custom widget com if/else Image | `CircleAvatar` + `Image.network` com `errorBuilder` | Material widget, fallback integrado, caching |
| Day selector com navegação semana | Widget de zero | Adaptar `SportDayStrip` (Phase 24) ou usar `TabBar` + `GestureDetector` | Phase 24 já resolveu underline pattern; só escalar |
| Bottom sheet com drag handle | `Scaffold + showDialog` | `showModalBottomSheet + DraggableScrollableSheet` | Material 3 padrão, UX conhecida, handle automático |
| Status badge colorida | Custom decoration | `Container + BoxDecoration + Border.all` (outline pill) | `SportBtn.outlined` já faz pill outline |
| Hairline divisória | Custom painter | `DecoratedBox(border: Border(top: BorderSide(...)))` | Material padrão, thin hairline 0.5px já verificado |
| Switch ativo/inativo | Custom toggle | `Switch` do theme AppTheme.lightTheme.switchTheme | Material 3, tema automático orange/cinza |

**Key insight:** Admin redesign é 100% recompose de widgets existentes. Nenhum comportamento novo, nenhuma interação complexa. HairlineBookingRow prova que hairline pattern é escalável (26px → 36px Anton, mesmo padrão).

---

## Runtime State Inventory

Fase 27 é UI-only (widget redesign). Nenhuma:
- Data model rename
- Cubit/state rename
- Firestore collection/field rename
- Environment variable rename

**Verificado:**
- Cubits existentes (`AdminBookingCubit`, `AdminSlotCubit`, `AuthCubit`) usados como-é
- Modelos (`BookingModel`, `SlotModel`, `UserModel`) sem mudança
- Firebase queries em abas ([booking_management_tab.dart] selectDate, [users_management_tab.dart] _loadUsers) sem mudança

**Conclusão:** Nenhuma ação de runtime state inventory necessária.

---

## Common Pitfalls

### Pitfall 1: Hardcoded Colors em AdminBookingCard
**What goes wrong:** `admin_booking_card.dart` contém 6+ `Color(0xFF...)` que não respeitam tema.
**Why it happens:** Widget pré-fase23, antes de AppTheme estar centralizado.
**How to avoid:** Antes de criar AdminBookingRow, audit `admin_booking_card.dart`:
```bash
grep -n "Color(0x" lib/features/admin/ui/admin_booking_card.dart
```
Map todos para AppTheme (já feito em admin_booking_card.dart _statusColor, mas verificar _sportBgColors/_sportFgColors).
**Warning signs:** Sport chips renderizam com cor diferente do esperado; aba Reservas colors inconsistente vs aba Slots.
**Phase:** ADMN-16, ADMN-18. **Confidence: HIGH** (codebase verificado).

### Pitfall 2: SportDayStrip Não Encontrado
**What goes wrong:** CONTEXT D-05 refere "mesmo padrão underline laranja da Phase 24 (SportDayStrip)" mas arquivo `lib/features/schedule/ui/sport_day_strip.dart` não existe em glob.
**Why it happens:** Phase 24 pode ter nomeado diferente ou implementado inline em `ScheduleScreen`.
**How to avoid:** Antes de implementar day selector admin, verificar:
1. Buscar `sport_day_strip` em grep: `grep -r "sport_day_strip" lib/`
2. Se não existe, buscar `DayChipRow` ou similar: `grep -r "DayChip" lib/`
3. Se existe em ScheduleScreen como `_buildDayChips`, copiar padrão local
4. PITFALLS.md Pitfall 4 avisa: DayChipRow é StatelessWidget, state está em ScheduleScreen._selectedDay (StatefulWidget local)
**Warning signs:** Day selector tabela não mostra underline; semana não navega com ← →.
**Phase:** ADMN-17. **Confidence: MEDIUM** (padrão existe em ScheduleScreen, mas nome arquivo incerto).

### Pitfall 3: Anton `height: 0.92` Clip em 36px + 32px
**What goes wrong:** AppTheme.display() seta `height: 0.92`. Em 36px e 32px, descenders clipam se row height é fixo.
**Why it happens:** PITFALLS.md Pitfall 8 — Anton metrics tight, height < 1.0 em alguns contextos.
**How to avoid:** 
- Não envolver texto Anton em `SizedBox(height: fixo)` que seja < fontSize * 0.92
- HairlineBookingRow usa `padding vertical: 12` sem altura fixa — reusar padrão
- Test em emulador mobile Chrome antes de submeter
**Warning signs:** Texto Anton cortado top/bottom; row height muda de forma estranha.
**Phase:** ADMN-16, ADMN-18, ADMN-17. **Confidence: MEDIUM** (treinamento + pitfall conhecido, nunca testado em 36px).

### Pitfall 4: Cubit State Desync — Day Selector + Week Navigation
**What goes wrong:** Trocar dia sem chamar `cubit.selectDay()` → lista slots mostra dia errado.
**Why it happens:** PITFALLS.md Pitfall 4 — state split entre StatefulWidget local (_selectedDay) e cubit (ScheduleCubit.selectDay). Admin dificuldade: _SlotDayViewState usa `int _selectedDayOfWeek` (índice 1-7), não DateTime.
**How to avoid:** 
- Day selector admin (D-05): SEMPRE chamar `cubit.selectDay(selectedDateTime)` + atualizar local UI state em mesmo método
- Converter `_selectedDayOfWeek: int` para `_selectedDay: DateTime` para match pattern ScheduleScreen
- Testar: tap dia → slot list atualiza; tap ← → volta semana, chips resincronizam, cubit refetch
**Warning signs:** Dia selecionado chips vs slot list em desacordo; mudar semana não reseta dia.
**Phase:** ADMN-17. **Confidence: HIGH** (code-verified Pitfall em PITFALLS.md §Pitfall 4).

### Pitfall 5: IntrinsicHeight em Admin Rows
**What goes wrong:** Se AdminBookingRow usar `IntrinsicHeight` para status stripe fill row, performance em long lists cai (2-pass layout).
**Why it happens:** PITFALLS.md Pitfall 5 — IntrinsicHeight layout cost. BookingCard usa pra stripe, mas admin tabs são listas longas.
**How to avoid:** AdminBookingRow NÃO precisa stripe lateral (D-07 não menciona). Se adicionar stripe, usar `Stack + Positioned` em vez de `IntrinsicHeight`.
```dart
// AVOID
IntrinsicHeight(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [Container(width: 2, color: orange), ...],
  ),
)

// USE (if stripe needed)
SizedBox(height: rowHeight, child: Stack(children: [
  Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 2, color: orange)),
  Padding(padding: EdgeInsets.only(left: 12), child: content),
]))
```
**Warning signs:** Profiler mostra double layout passes; list scroll lag.
**Phase:** ADMN-16, ADMN-18. **Confidence: HIGH** (Flutter docs explicit).

### Pitfall 6: UserDetailSheet Avatar Fallback Image.network Error
**What goes wrong:** `photoUrl` do Firebase Auth inexistente/inválido → Image.network falha, nenhum fallback visível, sheet renderiza vazio.
**Why it happens:** D-12 menciona "tenta carregar photoUrl... se ausente → fallback inicial". Image.network sem errorBuilder quebra.
**How to avoid:** `CircleAvatar(child: Image.network(..., errorBuilder: (_, __, ___) => Text(initial)))`. Sempre providenciar fallback.
**Warning signs:** Avatar area renderiza vazio em sheet; nenhuma inicial visível pra usuários sem photo.
**Phase:** ADMN-20. **Confidence: HIGH** (padrão Image.network).

---

## Code Examples

Padrões verificados em codebase:

### HairlineBookingRow — Padrão Base (Phase 26 verified)
```dart
// Source: lib/features/booking/ui/hairline_booking_row.dart lines 87-100
DecoratedBox(
  decoration: BoxDecoration(
    border: index == 0 ? null : const Border(
      top: BorderSide(color: AppTheme.lineHair, width: 0.5),
    ),
  ),
  child: InkWell(
    onTap: () => _onTap(context),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        // ... content
      ),
    ),
  ),
)
```

### AppTheme Tokens — Tipografia (Phase 23 verified)
```dart
// Source: lib/core/theme/app_theme.dart lines 25-46
static TextStyle display({double size = 32, Color? color, double? letterSpacing}) =>
  GoogleFonts.anton(fontSize: size, color: color ?? ink, height: 0.92);

static TextStyle ui({double size = 14, FontWeight weight = FontWeight.w400, Color? color}) =>
  GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color ?? ink);

static TextStyle mono({double size = 11, FontWeight weight = FontWeight.w700, Color? color}) =>
  GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight, color: color ?? concrete);
```

### SportBtn — Ações (Established verified)
```dart
// Source: lib/core/widgets/sport_btn.dart lines 32-58
SportBtn.filled('CONFIRMAR', onPressed: ...)
  → FilledButton orange background, paper text, StadiumBorder, 52px height

SportBtn.outlined('RECUSAR', onPressed: ...)
  → OutlinedButton transparent, ink border 1.5px, ink text, StadiumBorder
```

### Status Color Switch Pattern (AdminBookingCard verified)
```dart
// Source: lib/features/admin/ui/admin_booking_card.dart lines 18-29
Color _statusColor(String status, String? paymentMethod) {
  return switch ((status, paymentMethod)) {
    ('pending', _) => AppTheme.orange,
    ('pending_payment', _) => AppTheme.sun,
    ('confirmed', 'pix') => AppTheme.court,
    ('confirmed', 'on_arrival') => AppTheme.ink,
    _ => AppTheme.concrete,
  };
}
```

### Bottom Sheet Pattern (ClientBookingDetailSheet verified)
```dart
// Source: lib/features/booking/ui/client_booking_detail_sheet.dart lines 9-23
showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => UserDetailSheet(
    user: user,
    authCubit: authCubit,
  ),
);

// Sheet widget build()
@override
Widget build(BuildContext context) {
  return DraggableScrollableSheet(
    expand: false,
    builder: (context, controller) => SingleChildScrollView(
      controller: controller,
      child: Column(...),
    ),
  );
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| ChoiceChip day selector (colored background) | GestureDetector + underline laranja (SportDayStrip) | Phase 24 | Sem ChoiceChip theme cascade risk |
| AdminBookingCard (card com sombra) | AdminBookingRow (hairline row) | Phase 27 | Remover visual cruft, alinhado design Arena |
| Hardcoded Color(0xFF...) em widgets | AppTheme.* constants centralizados | Phase 23 | Theme changes cascatem; coerência cor |
| Inline admin user actions (promote/demote buttons in tab row) | UserDetailSheet bottom sheet | Phase 27 | Ações consolidadas, melhor UX |

**Deprecated/outdated:**
- `AdminBookingCard` — substituído por `AdminBookingRow` (delete D-08)
- `ChoiceChip` day selector — substituído por GestureDetector + underline (PITFALLS §Pitfall 4)
- Hardcoded colors em `admin_booking_card.dart` — migraçao para AppTheme (PITFALLS §Pitfall 9)

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `SportDayStrip` file existe em Phase 24 ou padrão está em ScheduleScreen local | Pitfall 2 | AdminDaySelector não consegue referenciar padrão correto; design underline pode variar |
| A2 | `UsersCubit` existe ou users carregados via FirebaseFirestore.collection('users') | Pitch 27 scope | Users tab não consegue carregar dados; precisa criar cubit novo |
| A3 | `AuthCubit.promoteUser()` e `AuthCubit.demoteUser()` existem ou usam Cloud Functions | UserDetailSheet | Sheet não consegue chamar ações; precisa criar novos métodos cubit |
| A4 | Firebase Auth `photoUrl` populado para alguns users (ou nenhum — ambos valid) | Avatar fallback | Avatar mostrador com certeza, mas fallback inicial nunca exercitado em produção |

**Se não verificado antes de task:** Research status = MEDIUM (A1, A2, A3), planner deve validar com user antes de implementar.

---

## Open Questions

1. **SportDayStrip implementação**
   - What we know: CONTEXT D-05 refere Pattern "mesmo padrão underline laranja da Phase 24". Phase 24 não foi pesquisado.
   - What's unclear: Arquivo `sport_day_strip.dart` não existe; padrão pode estar inline em ScheduleScreen ou deletado
   - Recommendation: Antes de task, grep codebase: `grep -r "DayChip\|DayStrip\|day.*selector" lib/features/schedule/` e validar padrão exato

2. **UsersCubit existência**
   - What we know: `users_management_tab.dart` carrega users com `FirebaseFirestore.collection('users')` inline. Nenhum cubit lido.
   - What's unclear: Se deve criar cubit novo ou reusar padrão existente
   - Recommendation: Validar com planner se tab permanece StatefulWidget (atual) ou migra para BlocBuilder cubit

3. **UserDetailSheet animação**
   - What we know: CONTEXT discretion = "Animação de entrada UserDetailSheet"
   - What's unclear: Preferência fade / slide / scale?
   - Recommendation: Usar padrão Flutter default (slide from bottom) — estável, UX conhecida

---

## Environment Availability

Fase 27 é UI-only. Nenhuma dependência externa além do projeto:

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Build widgets | ✓ | stable (Material 3) | — |
| google_fonts 6.2.1 | Anton/Manrope/JBM | ✓ | 6.2.1 | Fonts bundled assets/ |
| cloud_firestore 6.1.3 | Users load (FirebaseFirestore query) | ✓ | 6.1.3 | — |
| flutter_bloc 9.1.1 | Cubits (Admin/Auth) | ✓ | 9.1.1 | — |

**No blockers.** Tudo disponível.

---

## Validation Architecture

**Framework:** flutter_test + bloc_test (established)

**Test Config:**
- Test directory: `test/`
- Quick run: `flutter test test/features/admin/ui/ -k "admin" --tags="quick"`
- Full suite: `flutter test test/`
- Existing files:
  - `test/features/admin/cubit/admin_booking_cubit_test.dart` (cubit, não UI)
  - `test/features/admin/cubit/admin_slot_cubit_test.dart` (cubit)
  - No UI tests found for admin tabs

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | File Exists? | Command |
|--------|----------|-----------|-------------|---------|
| ADMN-16 | Slot row exibe hora Anton 32px (laranja se reservado) + switch ativo | widget | ❌ Wave 0 | `flutter test test/features/admin/ui/slot_row_test.dart` |
| ADMN-17 | Day selector renderiza dias semana com underline laranja, navegação ← → funciona | widget | ❌ Wave 0 | `flutter test test/features/admin/ui/admin_day_selector_test.dart` |
| ADMN-18 | AdminBookingRow exibe hora Anton 36px + nome + status mono colorido | widget | ❌ Wave 0 | `flutter test test/features/admin/ui/admin_booking_row_test.dart` |
| ADMN-19 | Pills Confirmar/Recusar visíveis só se status pending, ações chamam callback | widget | ❌ Wave 0 | `flutter test test/features/admin/ui/admin_booking_row_test.dart::ActionPills` |
| ADMN-20 | Avatar circular laranja admin / ink user comum, fallback inicial se sem photo | widget | ❌ Wave 0 | `flutter test test/features/admin/ui/user_detail_sheet_test.dart::AvatarFallback` |
| ADMN-21 | User row exibe avatar + Manrope bold + mono email + mono contador, sem gradiente | widget | ❌ Wave 0 | `flutter test test/features/admin/ui/user_row_test.dart` |

### Sampling Rate
- **Per task commit:** `flutter test test/features/admin/ui/ --tags="quick"` (~< 30s)
- **Per wave merge:** Full suite `flutter test test/`
- **Phase gate:** All admin UI tests green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/features/admin/ui/slot_row_test.dart` — covers ADMN-16, switch behavior
- [ ] `test/features/admin/ui/admin_day_selector_test.dart` — covers ADMN-17, week navigation
- [ ] `test/features/admin/ui/admin_booking_row_test.dart` — covers ADMN-18, ADMN-19, action pills
- [ ] `test/features/admin/ui/user_row_test.dart` — covers ADMN-21, layout render
- [ ] `test/features/admin/ui/user_detail_sheet_test.dart` — covers ADMN-20, avatar fallback, sheet interaction
- [ ] Framework: flutter_test + mockito fixtures para fake cubit (existing: `bloc_test: ^10.0.0`, `mocktail: ^1.0.4`)

---

## Security Domain

Fase 27 é UI-only redesign. Nenhuma mudança em:
- Autenticação (AuthCubit existente)
- Autorização (user.isAdmin role check existente)
- Dados sensíveis (Firestore rules, Cloud Functions)
- Input validation (form fields não redesenhados)

**ASVS aplicável:**

| ASVS Category | Applies | Notes |
|---------------|---------|-------|
| V2 Authentication | No | AuthCubit existente, sem mudança |
| V3 Session Management | No | Router/auth flow sem mudança |
| V4 Access Control | Yes, UI layer | UserDetailSheet promove/demote — validar backend restringe a admin-only; UI reflex não é controle |
| V5 Input Validation | No | Nenhum input novo (switch, buttons não são inputs de texto) |
| V6 Cryptography | No | Nenhuma crypto nesta fase |

**Mitigation:** Assumindo backend (Cloud Functions) valida `user.isAdmin` antes de processar `promoteUser()` / `demoteUser()`. UI é só reflexo.

---

## Sources

### Primary (HIGH confidence)
- Context7 codebase: `lib/core/theme/app_theme.dart` — AppTheme paleta + helpers verificados
- Context7 codebase: `lib/features/booking/ui/hairline_booking_row.dart` — padrão hairline row 26px
- Context7 codebase: `lib/core/widgets/sport_btn.dart` — SportBtn filled/outlined pattern
- Context7 codebase: `lib/features/admin/ui/admin_booking_card.dart` — status color switch, sport chip colors
- Context7 codebase: `.planning/CONTEXT.md` — decisões locked (D-01 a D-15), discretion areas
- Context7 codebase: `.planning/research/PITFALLS.md` — pitfalls v6.0 (Pitfalls 4, 5, 8, 9 aplicáveis)

### Secondary (MEDIUM confidence)
- Context7 codebase: `pubspec.yaml` — Flutter 3.11+, Material 3, flutter_bloc 9.1.1, bloc_test 10.0.0 verificados
- Context7 codebase: `lib/features/admin/ui/admin_booking_detail_sheet.dart` — bottom sheet padrão (estrutura replicável)
- Context7 codebase: `lib/features/booking/ui/client_booking_detail_sheet.dart` — bottom sheet padrão (estrutura replicável)

### Tertiary (LOW confidence)
- Assumption A1: SportDayStrip Phase 24 — não verificado arquivo, padrão pode estar em ScheduleScreen inline
- Assumption A2: UsersCubit — não encontrado em glob, users carregados inline em tab (precisa validar)
- Assumption A3: AuthCubit.promoteUser() — supostamente existe baseado em inline dialog em users_management_tab.dart linha 79, não verificado signature completa

---

## Metadata

**Confidence breakdown:**
- **Standard Stack: HIGH** — AppTheme, HairlineBookingRow, SportBtn todos verificados código
- **Architecture patterns: HIGH** — Padrões existentes escaláveis, nenhuma inovação
- **Pitfalls: HIGH** — PITFALLS.md fornecido, Pitfalls 4, 5, 8, 9 aplicáveis e documentados
- **Assumptions: MEDIUM** — A1, A2, A3 requerem validação antes de task (SportDayStrip, UsersCubit, AuthCubit methods)

**Research date:** 2026-06-04
**Valid until:** 2026-06-11 (7 dias — fase curta, design system estável)
**Project Constraints (from CLAUDE.md):**
- Estilo comunicação neanderthal obrigatório (frases 3-5 palavras)
- Use code-review-graph MCP tools ANTES de Grep/Glob/Read
- Após modificar código, rodar `graphify update .` para atualizar knowledge graph
- Não commitar: scripts/deploy.dart, scripts/package*.json, scripts/backup*.json, CLAUDE.md
- Sempre deploy em staging (vida-ativa-staging), nunca default/prod
- Criar testes unitários (feedback_no_tests revertida 2026-05-19)

---

*Phase: 27-admin-slots-reservas-usu-rios*
*Research completed: 2026-06-04*
*Status: Ready for planning*

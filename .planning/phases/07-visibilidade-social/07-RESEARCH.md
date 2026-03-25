# Phase 7: Visibilidade Social - Research

**Researched:** 2026-03-25
**Domain:** Flutter/Dart — BookingModel extension, SlotViewModel propagation, UI widget modifications
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Nome na agenda (SOCIAL-01)**
- Slot ocupado por outro usuário: mostrar `booking.userDisplayName` (nome completo, ex: "João Silva") no lugar do label "Ocupado"
- Slot de minha reserva: mantém o badge "Minha reserva" — sem alteração
- Fallback quando `userDisplayName` é null (raro, mas possível): mostrar "Ocupado" sem nome — não usar "Cliente" aqui

**Campo de participantes (SOCIAL-02)**
- Campo opcional, sem obrigatoriedade — reserva é concluída normalmente sem preenchimento
- Label: "Quem vai jogar? (opcional)"
- Hint/placeholder: "Ex: João, Maria, Pedro"
- Limite: 200 caracteres
- Posição na BookingConfirmationSheet: depois das linhas de data/hora/preço, antes do botão "Reservar"
- Editável pós-reserva: ícone de editar no BookingCard em MyBookingsScreen — toca no ícone, abre campo inline ou dialog simples para atualizar participants no Firestore

**Admin: participantes na listagem (ADMN-09)**
- Participantes aparecem abaixo do nome do cliente, em linha dedicada (não na linha de horário/preço)
- Ícone de grupo (Icons.group) antes dos nomes: `👥 Maria, Pedro` — usar `Icons.group`, não emoji
- Linha omitida quando `participants` é null ou vazio — sem placeholder "Sem participantes"

### Claude's Discretion
- Tipografia exata dos campos (tamanho de fonte, peso) para os nomes na agenda e na listagem admin
- Animação/transição ao abrir o campo de edição de participantes no BookingCard
- Posicionamento exato do ícone de editar no BookingCard (trailing icon, IconButton pequeno)
- Número de `maxLines` do campo de participantes (sugestão: 2)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SOCIAL-01 | Clientes veem o nome do reservante em cada slot ocupado na agenda | `bookerName: String?` added to SlotViewModel; `_resolveStatus` already has BookingModel in scope to extract `userDisplayName`; SlotCard `switch` on SlotStatus updated for `booked` case |
| SOCIAL-02 | Ao confirmar reserva, cliente pode adicionar campo de texto com participantes (opcional, 200 chars); editável pós-reserva via ícone no BookingCard | `participants: String?` added to BookingModel following existing nullable field pattern; `bookSlot()` receives optional `participants` param; BookingConfirmationSheet adds TextEditingController + TextField before button; BookingCard gains edit icon |
| ADMN-09 | Admin vê nome do cliente e participantes diretamente na linha do AdminBookingCard, sem abrir cada item | `participants` field on BookingModel flows automatically through existing AdminBookingCubit stream; AdminBookingCard adds conditional Row with `Icons.group` below clientName |
</phase_requirements>

---

## Summary

This phase adds social visibility to the court booking system: authenticated users see who booked each slot, can declare who they will play with, and admins see participant information inline. All changes are additive — no redesigns, no new screens, no new cubits required.

The Firestore security rules already allow `read: if isAuthenticated()` on the `bookings` collection (verified in `firestore.rules` lines 26–31). This was a pre-stated blocker for SOCIAL-01 in the roadmap but is already resolved. No rules change is needed.

The data layer changes are minimal: one new nullable `String? participants` field on `BookingModel`, following an established pattern already used by `userDisplayName`, `startTime`, and `price`. The UI propagation chain for SOCIAL-01 requires adding `bookerName: String?` to `SlotViewModel` and threading it from `_recompute()` through to `SlotCard`.

**Primary recommendation:** Implement in three sequential steps — (1) extend BookingModel with participants, (2) propagate bookerName through SlotViewModel + SlotCard, (3) wire participants UI in confirmation sheet, BookingCard edit, and AdminBookingCard display.

---

## Standard Stack

This phase uses no new libraries. All dependencies are already installed.

### Core (already in project)
| Library | Version | Purpose | Role in This Phase |
|---------|---------|---------|-------------------|
| `flutter_bloc` | ^9.1.1 | State management | BookingCubit.bookSlot() extended; no new cubits |
| `cloud_firestore` | (existing) | Database | `participants` field written/read via BookingModel |
| `equatable` | ^2.0.8 | Value equality | BookingModel.props updated to include participants |
| `flutter/material.dart` | (SDK) | UI widgets | TextField, Icons.group, IconButton, AlertDialog |

### No New Dependencies
All requirements are satisfied with the existing stack. Do not add any packages for this phase.

---

## Architecture Patterns

### Data Layer: Nullable Field Extension Pattern

The project has an established pattern for optional BookingModel fields. Every optional field follows this exact shape:

**In class definition:**
```dart
// Source: lib/core/models/booking_model.dart
final String? participants; // Free-text, comma-separated names
```

**In constructor:**
```dart
this.participants,
```

**In fromFirestore:**
```dart
participants: data['participants'] as String?,
```

**In toFirestore (conditional write — do not write null to Firestore):**
```dart
if (participants != null) 'participants': participants,
```

**In props (Equatable):**
```dart
// Add participants to the existing List<Object?> get props = [..., participants]
```

This pattern is used for `cancelledAt`, `startTime`, `price`, and `userDisplayName`. The `participants` field follows it identically.

### ViewModel Layer: bookerName Propagation

`SlotViewModel` currently holds `slot`, `status`, `dateString`. A new `bookerName: String?` field carries the reservante's name for the `booked` case only.

**SlotViewModel change:**
```dart
// Source: lib/features/schedule/models/slot_view_model.dart
final String? bookerName;

const SlotViewModel({
  required this.slot,
  required this.status,
  required this.dateString,
  this.bookerName,
});

@override
List<Object?> get props => [slot, status, dateString, bookerName];
```

**ScheduleCubit._recompute() change:**
```dart
// Source: lib/features/schedule/cubit/schedule_cubit.dart
final viewModels = _cachedSlots!.map((slot) {
  final booking = _cachedBookings!.cast<BookingModel?>().firstWhere(
    (b) => b!.slotId == slot.id,
    orElse: () => null,
  );
  final status = _resolveStatus(slot, dateString, currentUserId);
  final bookerName = (status == SlotStatus.booked) ? booking?.userDisplayName : null;
  return SlotViewModel(
    slot: slot,
    status: status,
    dateString: dateString,
    bookerName: bookerName,
  );
}).toList();
```

Note: `_resolveStatus` does not need to change — the cubit already has the booking in scope during `_recompute()`. The bookerName extraction can happen inline in `_recompute()` to avoid scanning the bookings list a second time.

### UI Layer: SlotCard bookerName Display

The `_StatusLabel` widget uses a sealed-class `switch` on `SlotStatus`. The `booked` case currently returns a static `Text('Ocupado')`. It needs to accept and display the booker name.

**Current pattern:**
```dart
// lib/features/schedule/ui/slot_card.dart
SlotStatus.booked => const Text('Ocupado', style: TextStyle(color: Colors.grey)),
```

**New approach — SlotCard passes bookerName to _StatusLabel:**
`_StatusLabel` needs `bookerName: String?` as a constructor parameter. The `booked` case renders `bookerName ?? 'Ocupado'`.

**Typography guidance (Claude's discretion):** Use `fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey` — slightly smaller than the time label (16pt) to signal secondary information without visual noise.

### UI Layer: BookingConfirmationSheet Participants Field

The sheet is a `StatefulWidget` already managing `_isSubmitting` and `_errorMessage`. Adding participants requires one new controller.

**Addition to state:**
```dart
final TextEditingController _participantsController = TextEditingController();

@override
void dispose() {
  _participantsController.dispose();
  super.dispose();
}
```

**Widget insertion (after price Row, before error message and button):**
```dart
const SizedBox(height: 16),
TextField(
  controller: _participantsController,
  decoration: const InputDecoration(
    labelText: 'Quem vai jogar? (opcional)',
    hintText: 'Ex: João, Maria, Pedro',
    border: OutlineInputBorder(),
  ),
  maxLength: 200,
  maxLines: 2,
  textCapitalization: TextCapitalization.words,
),
```

**Passing to bookSlot:**
```dart
await widget.bookingCubit.bookSlot(
  slotId: widget.viewModel.slot.id,
  dateString: widget.viewModel.dateString,
  price: widget.viewModel.slot.price,
  startTime: widget.viewModel.slot.startTime,
  userDisplayName: authState.user.displayName,
  participants: _participantsController.text.trim().isEmpty
      ? null
      : _participantsController.text.trim(),
);
```

### Cubit Layer: bookSlot Extension

`BookingCubit.bookSlot()` receives a new optional named parameter. The booking construction already follows the named-param pattern:

```dart
// lib/features/booking/cubit/booking_cubit.dart
Future<void> bookSlot({
  required String slotId,
  required String dateString,
  required double price,
  required String startTime,
  required String? userDisplayName,
  String? participants,           // NEW — optional
}) async {
  // ...
  final booking = BookingModel(
    // ...existing fields...
    participants: participants,   // NEW
  );
  tx.set(ref, booking.toFirestore());
}
```

This is the only change needed to `BookingCubit`.

### UI Layer: BookingCard Participants Edit

`BookingCard` is currently a `StatelessWidget`. Adding an edit icon that triggers an inline or dialog update requires either:
- Converting to `StatefulWidget` with an inline expansion (more complex)
- Keeping `StatelessWidget` and showing an `AlertDialog` with a `TextField` (simpler, matches existing dialog patterns in `AdminBookingCard`)

**Recommendation (Claude's discretion):** Use `AlertDialog` approach — consistent with the project's existing confirmation dialogs (`_confirmAction`, `_rejectAction` in AdminBookingCard). Keep `BookingCard` as `StatelessWidget`, add a trailing `IconButton(icon: Icon(Icons.edit, size: 18))` that opens a dialog.

The dialog pattern:
```dart
// Shown via showDialog — consistent with AdminBookingCard._confirmAction pattern
showDialog<String?>(
  context: context,
  builder: (ctx) {
    final controller = TextEditingController(text: booking.participants ?? '');
    return AlertDialog(
      title: const Text('Participantes'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'Ex: João, Maria, Pedro',
        ),
        maxLength: 200,
        maxLines: 2,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('Salvar'),
        ),
      ],
    );
  },
);
```

The update call goes directly to Firestore (same as `cancelBooking` direct update pattern), or through a new `updateParticipants(String bookingId, String? participants)` method on `BookingCubit`. The latter is cleaner since `BookingCubit` already owns the stream.

**BookingCard edit icon placement:** Add `IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: ..., padding: EdgeInsets.zero, constraints: BoxConstraints())` to the Row that contains `_statusBadge` and the cancel `TextButton`. Show the edit icon only when `isFuture && !booking.isCancelled` (same guard as the cancel button) — or always for non-cancelled bookings if editing past participants makes sense. Decision: show for all non-cancelled bookings, including past ones, since participants are informational only.

**Display of participants in BookingCard:** Show existing participants below the price row, before the status row, when `booking.participants != null && booking.participants!.isNotEmpty`. Use a Row with `Icons.group` at size 16 and grey color, matching the `Icons.access_time` / `Icons.attach_money` pattern already in the card.

### UI Layer: AdminBookingCard Participants Display

`AdminBookingCard` is pure display (read-only for participants). Insert a conditional row after the `clientName` row, before the `startTime` row:

```dart
// After clientName row, before startTime block
if (booking.participants != null && booking.participants!.isNotEmpty) ...[
  const SizedBox(height: 4),
  Row(
    children: [
      const Icon(Icons.group, size: 14, color: Colors.grey),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          booking.participants!,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ),
    ],
  ),
],
```

Use `Icons.group` (Material icon, not emoji) — consistent with the skill rule "no emoji icons, use SVG/material icons." The `overflow: TextOverflow.ellipsis` with `maxLines: 2` prevents layout overflow for long participant strings.

### Anti-Patterns to Avoid

- **Do not emit cubit state inside bookSlot:** The existing code comment says "Stream subscription picks up the new booking reactively — no state emit here." Follow this — the stream will update BookingCard automatically after participants are saved.
- **Do not call Firestore directly from widgets:** Route the participants update through `BookingCubit.updateParticipants()` to keep the data layer consistent.
- **Do not add `participants` to `SlotViewModel`:** The agenda grid doesn't need participants — only `bookerName` is needed for SOCIAL-01.
- **Do not use emoji as UI icon:** The CONTEXT.md mentions "👥 ou `Icons.group`" — use `Icons.group` exclusively (see skill rule `no-emoji-icons`).
- **Do not show fallback text for null participants in admin:** Decision is to omit the line entirely when null/empty — no "Sem participantes" placeholder.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Character count in TextField | Manual counter widget | `maxLength: 200` on TextField | Shows counter + enforces limit automatically |
| Participants dialog state management | Stateful wrapper | Local controller inside builder + `showDialog` | AlertDialog builder provides local scope |
| Participants Firestore update | New cubit class | `updateParticipants()` method on existing `BookingCubit` | Cubit already owns the bookings stream |
| Display name in SlotCard | New Provider/query | Already in `BookingModel.userDisplayName` — just propagate through SlotViewModel | Data is already fetched, no extra read needed |

---

## Common Pitfalls

### Pitfall 1: Scanning bookings twice in _recompute()
**What goes wrong:** Calling `_resolveStatus()` (which scans `_cachedBookings`) and then scanning again to find `userDisplayName` — O(2n) instead of O(n).
**Why it happens:** `_resolveStatus()` is a pure function that returns only `SlotStatus`, so callers reach back for the booking.
**How to avoid:** Inline the logic in `_recompute()` — find the booking once, derive both `status` and `bookerName` from that single lookup. Or add a `_resolveStatusAndBooker()` helper that returns a record/tuple.

### Pitfall 2: bookerName shown for myBooking slot
**What goes wrong:** If `bookerName` is not guarded, the current user's own name could display for `SlotStatus.myBooking`, overriding the "Minha reserva" badge.
**Why it happens:** `booking.userDisplayName` exists for all bookings including the current user's.
**How to avoid:** In `_recompute()`, only assign `bookerName` when `status == SlotStatus.booked`, not `myBooking`. The `_StatusLabel` switch only reads `bookerName` for the `booked` case anyway, but defensive null assignment is cleaner.

### Pitfall 3: participants field not in Equatable props
**What goes wrong:** `BookingModel` equality checks won't detect changes to `participants`, so reactive rebuilds may be silently missed.
**Why it happens:** Forgetting to add the new field to `List<Object?> get props`.
**How to avoid:** Always update `props` immediately after adding any field to `BookingModel`. Cross-check: the current `props` list has 10 items matching the 10 fields — `participants` becomes item 11.

### Pitfall 4: TextField dispose not called in BookingConfirmationSheet
**What goes wrong:** Memory leak from `TextEditingController` not disposed.
**Why it happens:** The sheet is a `StatefulWidget` — `dispose()` must be overridden.
**How to avoid:** Add `dispose()` override that calls `_participantsController.dispose()` — standard Flutter lifecycle.

### Pitfall 5: maxLength counter overlapping error message
**What goes wrong:** When `_errorMessage != null`, the layout may look crowded with the maxLength counter visible below the TextField.
**Why it happens:** Material TextField renders the counter below the field, adding vertical space.
**How to avoid:** Accept this as acceptable — the counter disappears when the field is empty (default Flutter behavior). If it becomes visually problematic, use `counterText: ''` to hide the counter and rely on the 200-char limit silently.

### Pitfall 6: updateParticipants not reactive for other open sessions
**What goes wrong:** If the user has two tabs open (unlikely but possible in PWA), only the tab that called `updateParticipants` shows the updated text until the Firestore stream re-emits.
**Why it happens:** `BookingCubit._startStream()` listens to the user's bookings — Firestore real-time listener will propagate, but there may be a brief inconsistency window.
**How to avoid:** This is inherent to the reactive model. The stream will catch up. No special handling needed.

---

## Code Examples

### BookingModel.toFirestore() — Established Nullable Pattern
```dart
// Source: lib/core/models/booking_model.dart (verified)
Map<String, dynamic> toFirestore() {
  return {
    'slotId': slotId,
    'date': date,
    'userId': userId,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
    if (cancelledAt != null) 'cancelledAt': Timestamp.fromDate(cancelledAt!),
    if (startTime != null) 'startTime': startTime,
    if (price != null) 'price': price,
    if (userDisplayName != null) 'userDisplayName': userDisplayName,
    // participants follows the same pattern:
    // if (participants != null) 'participants': participants,
  };
}
```

### ScheduleCubit._recompute() — Current ViewModels Creation
```dart
// Source: lib/features/schedule/cubit/schedule_cubit.dart (verified)
final viewModels = _cachedSlots!.map((slot) {
  final status = _resolveStatus(slot, dateString, currentUserId);
  return SlotViewModel(
    slot: slot,
    status: status,
    dateString: dateString,
    // bookerName: extracted inline before calling _resolveStatus
  );
}).toList();
```

### SlotCard._StatusLabel — Switch Pattern
```dart
// Source: lib/features/schedule/ui/slot_card.dart (verified)
return switch (status) {
  SlotStatus.available => const Text('Disponível', ...),
  SlotStatus.booked => const Text('Ocupado', style: TextStyle(color: Colors.grey)),
  SlotStatus.myBooking => Container(...), // "Minha reserva" badge
  SlotStatus.blocked => const Text('Bloqueado', ...),
};
```

### AdminBookingCard — Existing clientName Display
```dart
// Source: lib/features/admin/ui/admin_booking_card.dart (verified)
final clientName = booking.userDisplayName ?? 'Cliente';
// Row at top of Column: Text(clientName, style: TextStyle(fontWeight: FontWeight.bold))
// participants row goes immediately below this, before startTime block
```

### BookingCard — Existing Icon Row Pattern
```dart
// Source: lib/features/booking/ui/booking_card.dart (verified)
if (booking.startTime != null)
  Row(children: [
    const Icon(Icons.access_time, size: 16, color: Colors.grey),
    const SizedBox(width: 4),
    Text(booking.startTime!),
  ]),
if (booking.price != null)
  Row(children: [
    const Icon(Icons.attach_money, size: 16, color: Colors.grey),
    const SizedBox(width: 4),
    Text(NumberFormat.currency(...).format(booking.price!)),
  ]),
// participants row follows the same pattern with Icons.group
```

---

## Firestore Security Rules — Confirmed No Change Required

```
// Source: firestore.rules (verified 2026-03-25)
match /bookings/{bookingId} {
  allow read: if isAuthenticated();           // ALL authenticated users can read
  allow create: if isAuthenticated() &&
    request.resource.data.userId == request.auth.uid;
  allow update, delete: if isAuthenticated() &&
    (resource.data.userId == request.auth.uid || isAdmin());
}
```

The `allow read: if isAuthenticated()` rule was already in place. SOCIAL-01 requires no rules change. The STATE.md note "[Phase 7]: SOCIAL-01 requires Firestore Security Rules update" was written before Phase 6 completed the rules — the actual current rules confirm this is already done.

The `allow update` rule permits the booking owner to update their own booking (for `updateParticipants`). No rules change needed for SOCIAL-02 either.

---

## State of the Art

| Old Approach | Current Approach | Status |
|--------------|------------------|--------|
| Firestore rules blocked non-admin booking reads | `allow read: if isAuthenticated()` already live | Already done in Phase 6 |
| Static "Ocupado" label in SlotCard | bookerName from SlotViewModel | To implement (SOCIAL-01) |
| No participants field | `String? participants` on BookingModel | To implement (SOCIAL-02, ADMN-09) |

---

## Validation Architecture

`nyquist_validation: true` in config.json.

**Project feedback note:** User has explicitly stated "Não gerar testes unitários nem de widget neste projeto" (memory: `feedback_no_tests.md`). No test files should be created or planned.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK) |
| Config file | none (flutter test uses default discovery) |
| Quick run command | `flutter test test/widget_test.dart` |
| Full suite command | `flutter test` |

### Phase Requirements — Validation Approach

Given the no-tests constraint, validation for this phase is manual/smoke-testing only:

| Req ID | Behavior | Validation Method |
|--------|----------|-------------------|
| SOCIAL-01 | Slot booked by another user shows their name in agenda | Manual: book as user A, view agenda as user B — see name |
| SOCIAL-02 | Participants field optional at booking; editable post-booking | Manual: book with and without participants; edit via icon |
| ADMN-09 | Admin listing shows participants below client name | Manual: create booking with participants, open admin view |

### Wave 0 Gaps
None — no test infrastructure needed per project feedback.

---

## Open Questions

1. **updateParticipants via BookingCubit or direct Firestore?**
   - What we know: `cancelBooking` calls Firestore directly from the cubit (`_firestore.collection('bookings').doc(bookingId).update(...)`), no separate method needed for the call itself.
   - What's unclear: whether to add a named `updateParticipants()` method or inline the Firestore call in the widget (matching the dialog pattern in AdminBookingCard which calls `cubit.confirmBooking()`).
   - Recommendation: Add `updateParticipants(String bookingId, String? participants)` to `BookingCubit` — cleaner separation; widget calls cubit method, not Firestore directly. Consistent with `cancelBooking` and the admin's `confirmBooking`/`rejectBooking` pattern.

2. **Show participants in BookingCard display (not just edit)?**
   - What we know: CONTEXT.md specifies edit icon on BookingCard but does not explicitly say to display existing participants in the card body.
   - What's unclear: whether non-editing display of participants was intentional omission or oversight.
   - Recommendation: Display existing participants in the card body (same Row pattern as startTime/price icons) — this makes the edit icon discoverable and gives context. If participants is null/empty, the row is omitted (same as admin card).

---

## Sources

### Primary (HIGH confidence)
- `lib/core/models/booking_model.dart` — Verified nullable field pattern, props list, toFirestore/fromFirestore shape
- `lib/features/schedule/cubit/schedule_cubit.dart` — Verified _recompute(), _resolveStatus(), stream subscriptions
- `lib/features/schedule/models/slot_view_model.dart` — Verified current fields (slot, status, dateString only)
- `lib/features/schedule/ui/slot_card.dart` — Verified switch pattern in _StatusLabel
- `lib/features/booking/ui/booking_confirmation_sheet.dart` — Verified StatefulWidget structure, _handleConfirm(), layout order
- `lib/features/booking/cubit/booking_cubit.dart` — Verified bookSlot() signature, named params pattern, direct Firestore update for cancel
- `lib/features/booking/ui/booking_card.dart` — Verified StatelessWidget, icon Row pattern, status badge placement
- `lib/features/admin/ui/admin_booking_card.dart` — Verified clientName display, dialog pattern, startTime block position
- `lib/features/admin/cubit/admin_booking_cubit.dart` — Verified stream loads full BookingModel; participants auto-appears after model update
- `firestore.rules` — Verified `allow read: if isAuthenticated()` on bookings collection

### Secondary (MEDIUM confidence)
- `.planning/phases/07-visibilidade-social/07-CONTEXT.md` — All locked decisions sourced here
- `.claude/skills/ui-ux-pro-max/SKILL.md` — `no-emoji-icons` rule (use Icons.group not emoji), touch target size, loading states

---

## Metadata

**Confidence breakdown:**
- Data model changes: HIGH — exact pattern verified in codebase
- ViewModel propagation: HIGH — exact ScheduleCubit code verified
- UI widget changes: HIGH — all target widgets read and understood
- Firestore rules: HIGH — rules file verified; no change needed
- Architecture fit: HIGH — all changes are additive, no existing code broken

**Research date:** 2026-03-25
**Valid until:** 2026-04-25 (stable codebase, no external API changes)

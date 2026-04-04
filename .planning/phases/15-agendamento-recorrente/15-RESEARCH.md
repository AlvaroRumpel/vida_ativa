# Phase 15: Agendamento Recorrente - Research

**Researched:** 2026-04-04
**Domain:** Flutter — batch Firestore booking creation, week-day recurrence UI, group cancellation
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Toggle "Reservar semanalmente" inline dentro do `BookingConfirmationSheet` existente — não é um sheet separado
- Toggle sempre visível, independente de quantas semanas futuras existem
- Quando ativado, o sheet expande mostrando seleção de dias + slider + preview
- Botão muda de texto quando recorrente ativo: "Reservar [N] semanas" (ou variação indicando batch)
- Chips dos 7 dias da semana no sheet expandido; dia do slot de origem pré-selecionado
- Cliente pode ativar dias adicionais (ex: slot é Qui → ativa Ter também)
- Mesmo horário para todos os dias selecionados (não permite horário diferente por dia)
- Slider de 1 a 52 semanas
- Rótulo dinâmico ao lado: "N semanas (até [DiaSemana] DD/MMM)"
- Data final calculada sempre pelo mesmo dia da semana do slot de origem
- Lista de datas geradas exibida dentro do sheet antes do submit
- Verificação PRÉVIA de disponibilidade: consulta Firestore para cada data/dia combinação
- Estados visuais: Verde/normal (slot existe e disponível), Cinza + "Já reservado" (slot existe mas tem booking ativo), Cinza + "Horário não cadastrado" (slot não existe)
- Truncamento: exibe as primeiras 4-6 datas + "+ N datas" quando lista longa (20+ semanas)
- Preview atualiza dinamicamente conforme slider é ajustado
- `Future.wait()` — todas as reservas criadas em paralelo
- Cada booking recebe campo `recurrenceGroupId` (UUID gerado no momento do batch)
- Bookings com slot inexistente ou já ocupado são simplesmente ignorados (não tentados)
- Bookings disponíveis são criados via transaction individual (padrão `bookSlot`)
- Após submit, sheet de resultado substitui/empilha sobre o confirmation sheet
- Exibe: "N reservas criadas" (verde) + lista de conflitos em âmbar (se houver)
- Novo campo opcional `recurrenceGroupId: String?` em `BookingModel`
- `BookingCard` exibe badge/chip pequeno "Recorrente" quando `booking.recurrenceGroupId != null`
- Lista permanece flat (não agrupada por série)
- Reservas recorrentes exibem duas opções no `ClientBookingDetailSheet`: "Cancelar só esta" / "Cancelar esta e as próximas"
- "Esta + próximas" cancela via batch update: query `bookings where recurrenceGroupId == X and date > hoje`

### Claude's Discretion
- Design visual exato do toggle (Switch vs Checkbox vs ToggleButton)
- Animação de expansão do sheet quando toggle é ativado
- UUID generation strategy para `recurrenceGroupId`
- Exact query strategy para verificação de disponibilidade no preview (batch get vs parallel gets)
- Tratamento de erros parciais no `Future.wait` (um erro não cancela os outros)

### Deferred Ideas (OUT OF SCOPE)
- Horário diferente por dia de semana (ex: Ter 19:00 + Qui 20:00) — Phase 17
- Agrupamento de bookings recorrentes na lista de "Minhas Reservas" (colapsado por série) — Phase 17
- Notificação quando admin cria slots futuros compatíveis com recorrência existente — backlog
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| BOOK-05 | Cliente pode criar reserva recorrente: seleciona padrão semanal + data de término; app cria todas as reservas individualmente; conflitos (slot já reservado) são exibidos em lista e ignorados silenciosamente | Full research below — slot lookup strategy, batch creation, `recurrenceGroupId`, result sheet, cancel-group |
</phase_requirements>

---

## Summary

Phase 15 extends `BookingConfirmationSheet` with an inline recurrence toggle. When activated the sheet expands to show: day-of-week chip selection (pre-seeded from the source slot's weekday), a 1–52 week slider with a dynamic end-date label, and a live preview list of all candidate dates with colour-coded availability fetched from Firestore in parallel.

The batch submission creates each available booking individually (reusing the existing `bookSlot` transaction pattern) under a shared `recurrenceGroupId` UUID, and shows a result sheet summarising successes vs conflicts. `BookingModel` gains one nullable String field. `ClientBookingDetailSheet` conditionally surfaces a second cancel option that batch-updates all future bookings in the group to `cancelled`.

No new Firestore collection or index is strictly required beyond one composite index for the group-cancel query — and that index can be avoided by filtering in Dart if write performance is the priority.

**Primary recommendation:** Implement as three co-located files — a `RecurrenceSection` widget extracted from the expanded sheet content, a new `BookingRecurrenceCubit` (or service object inside `BookingCubit`) for the preview availability checks and batch submission, and a `RecurrenceResultSheet` for the outcome view.

---

## Standard Stack

### Core
| Library | Version (verified) | Purpose | Why Standard |
|---------|-------------------|---------|--------------|
| cloud_firestore | ^6.1.3 (already in project) | Slot lookup, booking creation, group cancellation | Anti-double-booking transaction, batch gets |
| flutter_bloc | ^9.1.1 (already in project) | State for loading/success/error in extended sheet | Established project pattern |
| intl | ^0.20.2 (already in project) | Date formatting for preview labels and end-date label | Already used for `DateFormat` in every sheet |
| uuid | transitive (via firebase_core) | `recurrenceGroupId` generation — v4 random UUID | Already on lockfile, zero install cost |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| uuid (transitive) | ^4.x | `Uuid().v4()` — cryptographically random group ID | Use instead of `DateTime.now().millisecondsSinceEpoch.toString()` — avoids clock-skew collisions |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `uuid` package | `DateTime.now().millisecondsSinceEpoch.toString()` | Millisecond strings can collide if two batch submissions start within 1ms; uuid v4 is collision-proof |
| Parallel `Future.wait` for preview checks | Sequential await loop | Sequential is simpler to read but adds latency (10 weeks × 2 days = 20 serial Firestore reads); parallel is ~20× faster |
| `showModalBottomSheet` for result | `AlertDialog` | Dialog is modal and blocks navigation; a second sheet stacks naturally like other sheets in the app |

**Installation:** No new packages needed. Add `uuid` as a direct dependency to avoid transitive brittleness:
```bash
flutter pub add uuid
```

---

## Architecture Patterns

### Recommended Project Structure

No new top-level directories. All new files land inside the existing `booking` feature:

```
lib/features/booking/
├── cubit/
│   ├── booking_cubit.dart          # Add: bookRecurring(), cancelGroupFuture()
│   ├── booking_state.dart          # unchanged
│   └── recurrence_preview_state.dart  # NEW — loading/loaded/error for preview
├── ui/
│   ├── booking_confirmation_sheet.dart  # EXTEND with toggle + RecurrenceSection
│   ├── recurrence_section.dart          # NEW — day chips + slider + preview list
│   ├── recurrence_result_sheet.dart     # NEW — success/conflict summary sheet
│   ├── client_booking_detail_sheet.dart # EXTEND with cancel-group option
│   ├── booking_card.dart                # EXTEND with "Recorrente" badge
│   └── my_bookings_screen.dart          # unchanged (badge appears via card)
lib/core/models/
└── booking_model.dart              # ADD recurrenceGroupId: String?
```

### Pattern 1: Slot Lookup for Preview (query by date + startTime)

**What:** Because slot IDs are Firestore auto-generated (not deterministic), finding the slot for a future date+time requires a Firestore query, not a direct get.

**When to use:** In the preview availability check loop, once per (date, weekday) combination.

**The query:**
```dart
// Source: cloud_firestore docs — where() compound query
final snap = await _firestore
    .collection('slots')
    .where('date', isEqualTo: targetDateString)  // "YYYY-MM-DD"
    .where('startTime', isEqualTo: startTime)     // "HH:mm"
    .limit(1)
    .get();

final slotExists = snap.docs.isNotEmpty;
final slotId = slotExists ? snap.docs.first.id : null;
```

**No composite index needed** for (date + startTime) — Firestore allows equality filters on two fields without a composite index. Confirmed: single-field equality filters are always supported without additional indexes.

**Parallel pattern for all dates:**
```dart
final results = await Future.wait(
  candidateDates.map((d) => _checkSlotAvailability(d, startTime)),
);
```

### Pattern 2: Booking Pre-check (deterministic ID get)

**What:** Once a slotId is known, check if a booking already exists using the deterministic ID.

**When to use:** After slot lookup returns a slotId, before adding date to "available" set.

```dart
// BookingModel.generateId is O(1) — no query needed
final bookingId = BookingModel.generateId(slotId, dateString);
final bookingSnap = await _firestore
    .collection('bookings')
    .doc(bookingId)
    .get();

final isAlreadyBooked = bookingSnap.exists &&
    bookingSnap.data()?['status'] != 'cancelled';
```

**Confidence: HIGH** — this is the existing `bookSlot` pattern, just done as a get instead of inside a transaction.

### Pattern 3: Batch Booking Creation with Future.wait

**What:** Fire all individual `bookSlot`-equivalent transactions in parallel.

**When to use:** After user confirms, for all dates classified as "available" in preview.

```dart
// Existing bookSlot() can be called for each slot individually
// recurrenceGroupId is passed as an additional field
final groupId = const Uuid().v4();

final futures = availableDates.map((entry) => bookSlot(
  slotId: entry.slotId,
  dateString: entry.dateString,
  price: entry.price,
  startTime: startTime,
  userDisplayName: userDisplayName,
  participants: participants,
  recurrenceGroupId: groupId,   // new param
));

final results = await Future.wait(
  futures,
  eagerError: false,  // collect all results, don't stop on first error
);
```

**IMPORTANT:** `Future.wait` with `eagerError: false` does not exist — the correct pattern for partial-failure handling is `Future.wait` wrapped to catch per-element errors:

```dart
// Correct approach: convert each future to return a result/error
final settled = await Future.wait(
  availableDates.map((entry) async {
    try {
      await _bookSingleRecurring(entry, groupId, ...);
      return _RecurrenceOutcome.success(entry.dateString);
    } catch (e) {
      return _RecurrenceOutcome.failed(entry.dateString, e.toString());
    }
  }),
);
```

**Confidence: HIGH** — `Future.wait` does not natively support `eagerError: false` as a named param in Dart; per-element try/catch is the correct idiom.

### Pattern 4: Cancel Group Future Bookings

**What:** Batch-update all bookings in the same `recurrenceGroupId` that are dated after today.

**When to use:** When user selects "Cancelar esta e as próximas".

```dart
// New method in BookingCubit
Future<void> cancelGroupFuture({
  required String recurrenceGroupId,
  required String fromDateInclusive,  // "YYYY-MM-DD" — today
}) async {
  final snap = await _firestore
      .collection('bookings')
      .where('recurrenceGroupId', isEqualTo: recurrenceGroupId)
      .where('date', isGreaterThanOrEqualTo: fromDateInclusive)
      .where('userId', isEqualTo: _userId)   // safety: only own bookings
      .get();

  final batch = _firestore.batch();
  for (final doc in snap.docs) {
    batch.update(doc.reference, {
      'status': 'cancelled',
      'cancelledAt': Timestamp.fromDate(DateTime.now()),
    });
  }
  await batch.commit();
}
```

**Firestore composite index required:** `bookings` on `(recurrenceGroupId ASC, date ASC)`. This index does NOT exist yet and must be created in `firestore.indexes.json` (or Firestore console) before this query works in production.

**Confidence: HIGH** — compound where() with inequality (isGreaterThanOrEqualTo) on a different field than an equality filter is supported since Firestore lifted the single-inequality restriction. Requires explicit composite index.

### Pattern 5: Sheet Expansion with AnimatedSize

**What:** The sheet expands vertically when the recurrence toggle is activated.

**When to use:** Wrapping the recurrence section in `AnimatedSize` for smooth expansion.

```dart
AnimatedSize(
  duration: const Duration(milliseconds: 250),
  curve: Curves.easeInOut,
  child: _isRecurrent ? const RecurrenceSection(...) : const SizedBox.shrink(),
)
```

**Confidence: HIGH** — `AnimatedSize` is the standard Flutter widget for height transitions; used this way in Material sheets throughout the Flutter ecosystem.

### Pattern 6: Day-of-Week Chip Selection

**What:** 7 toggle chips for Mon–Sun; source slot day pre-selected; multi-select allowed.

**Existing reference:** `SlotBatchSheet._derivedDays()` already uses `_dayLabels = ['Seg','Ter','Qua','Qui','Sex','Sáb','Dom']` — reuse this constant.

```dart
// Use FilterChip for multi-select, consistent with Material 3
FilterChip(
  label: Text(_dayLabels[dow - 1]),
  selected: _selectedDays.contains(dow),
  onSelected: (selected) {
    setState(() {
      if (selected) {
        _selectedDays.add(dow);
      } else if (_selectedDays.length > 1) {
        // Must keep at least 1 day selected
        _selectedDays.remove(dow);
      }
    });
    _triggerPreviewUpdate();
  },
)
```

**Note:** Source slot day (from `slot.date`) is pre-seeded in `initState`. Dart's `DateTime.weekday` returns 1=Mon..7=Sun — same convention as `SlotModel.dayOfWeek`.

### Anti-Patterns to Avoid

- **Running preview checks inside the transaction:** The transaction should only check for the booking document. Slot existence is pre-checked in the preview phase outside the transaction.
- **Sequential Firestore reads for preview:** Don't `await` each slot check one-by-one — use `Future.wait` for parallel execution.
- **Using `.add()` for batch bookings:** Always `.doc(bookingId).set()` inside transaction — same as existing `bookSlot`. The deterministic ID is the anti-double-booking guarantee.
- **Emitting cubit state from bookSlot:** The existing pattern is to NOT emit state after booking — the stream subscription handles it. Follow this for batch creation too.
- **Querying all user bookings to find group members:** Always query by `recurrenceGroupId` field, not by filtering the loaded BookingState in memory — the stream only loads the current user's bookings but may not have future ones loaded yet.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Unique group ID | `DateTime.now().millisecondsSinceEpoch.toString()` | `uuid` package (already on lockfile) `Uuid().v4()` | Collision-proof; transitive dep available now |
| Date arithmetic for "N weeks out" | Custom date loop | `DateTime.add(Duration(days: 7 * n))` + Dart's built-in weekday | Dart's DateTime handles DST, month boundaries correctly |
| Partial-failure future handling | Custom `Future.any` combinator | Per-element try/catch inside `Future.wait` map | See Pattern 3 above — standard Dart idiom |
| Firestore batch write | Loop of individual `.update()` calls | `WriteBatch` (`_firestore.batch()`) | Atomic commit, single round-trip for up to 500 docs |
| Slot availability status text | Custom logic in widget | Sealed enum `_SlotPreviewStatus { available, alreadyBooked, notFound }` inside `RecurrenceSection` | Exhaustive switch prevents missed cases |

**Key insight:** The entire batch creation is built on top of existing `bookSlot` without changing its transaction logic — only a `recurrenceGroupId` parameter is added. This means all existing anti-double-booking guarantees remain intact.

---

## Common Pitfalls

### Pitfall 1: Preview Does Not Reflect Race Condition
**What goes wrong:** Preview shows "available" but by submit time another user has booked the same slot.
**Why it happens:** Preview is a snapshot check; submit happens later.
**How to avoid:** The existing `bookSlot` transaction will throw `slot_already_booked` for any race — catch it per-booking in the batch and include the date in the "conflicts" result sheet with reason "Horário reservado durante confirmação".
**Warning signs:** Test with two simultaneous bookings in browser; confirm conflict sheet appears for the lost race.

### Pitfall 2: Firestore Composite Index Missing at Deploy
**What goes wrong:** `cancelGroupFuture` query throws "requires an index" FirebaseException at runtime.
**Why it happens:** Compound queries with inequality on a second field need explicit composite indexes.
**How to avoid:** Add to `firestore.indexes.json` before deploy:
```json
{
  "collectionGroup": "bookings",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "recurrenceGroupId", "order": "ASCENDING" },
    { "fieldPath": "date", "order": "ASCENDING" }
  ]
}
```
**Warning signs:** Works in emulator (which auto-creates indexes), fails in production.

### Pitfall 3: `recurrenceGroupId` Field Missing in `toFirestore()`
**What goes wrong:** Field is in the Dart model but never persisted; group cancel query returns 0 docs.
**Why it happens:** Adding a nullable field to the constructor without updating `toFirestore()` and `fromFirestore()`.
**How to avoid:** Update all three locations in `BookingModel`: constructor, `fromFirestore`, and `toFirestore` (using `if (recurrenceGroupId != null)` conditional).

### Pitfall 4: Sheet Height Overflow
**What goes wrong:** Expanded recurrence section + preview list overflows sheet height on small screens.
**Why it happens:** `mainAxisSize: MainAxisSize.min` with a dynamically growing `Column` can exceed viewport.
**How to avoid:** Wrap the sheet body in `SingleChildScrollView` when recurrence is active. The existing `isScrollControlled: true` in `showModalBottomSheet` already allows the sheet to take full viewport height — pair with `DraggableScrollableSheet` or `ConstrainedBox(maxHeight: height * 0.9)`.

### Pitfall 5: Week Slider Triggers Excessive Firestore Reads
**What goes wrong:** Moving the slider fires a preview refresh on every frame, generating hundreds of Firestore reads.
**Why it happens:** `onChanged` fires continuously during drag.
**How to avoid:** Use `Slider.onChangeEnd` (not `onChanged`) to trigger the Firestore preview refresh. Update the end-date label eagerly on `onChanged` (local computation only), but defer Firestore checks to `onChangeEnd`.

### Pitfall 6: `Future.wait` Stops on First Error
**What goes wrong:** One booking creation failure cancels all remaining bookings.
**Why it happens:** Default `Future.wait` throws on first future error.
**How to avoid:** Wrap each future in a per-element try/catch (Pattern 3 above). Never rely on `Future.wait` default behaviour for partial-failure scenarios.

### Pitfall 7: `recurrenceGroupId` in `Equatable.props`
**What goes wrong:** `BookingCard` does not rebuild when `recurrenceGroupId` arrives from stream.
**Why it happens:** If `recurrenceGroupId` is not added to `props`, Equatable considers two models equal even if the field differs.
**How to avoid:** Add `recurrenceGroupId` to `BookingModel.props` list.

---

## Code Examples

### BookingModel — Add recurrenceGroupId

```dart
// lib/core/models/booking_model.dart
class BookingModel extends Equatable {
  // ... existing fields ...
  final String? recurrenceGroupId;

  const BookingModel({
    // ... existing params ...
    this.recurrenceGroupId,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return BookingModel(
      // ... existing mappings ...
      recurrenceGroupId: data['recurrenceGroupId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      // ... existing entries ...
      if (recurrenceGroupId != null) 'recurrenceGroupId': recurrenceGroupId,
    };
  }

  @override
  List<Object?> get props => [
    id, slotId, date, userId, status, createdAt, cancelledAt,
    startTime, price, userDisplayName, participants,
    recurrenceGroupId,  // ADD THIS
  ];
}
```

### Generate Candidate Dates for a Recurrence

```dart
/// Returns all dates (YYYY-MM-DD) matching the selected weekdays
/// starting from [anchorDate] for [weeks] weeks.
List<String> generateRecurrenceDates({
  required DateTime anchorDate,
  required Set<int> selectedDays,  // 1=Mon..7=Sun
  required int weeks,
}) {
  final dates = <String>[];
  // Start from the week AFTER the anchor (anchor slot is booked separately)
  for (int w = 1; w <= weeks; w++) {
    for (final dow in selectedDays) {
      // Find the date in week w that matches this weekday
      final weekStart = anchorDate.add(Duration(days: 7 * w));
      final daysFromAnchorWeekday = (dow - weekStart.weekday) % 7;
      final targetDate = weekStart.add(Duration(days: daysFromAnchorWeekday));
      final dateStr = '${targetDate.year}-'
          '${targetDate.month.toString().padLeft(2, '0')}-'
          '${targetDate.day.toString().padLeft(2, '0')}';
      dates.add(dateStr);
    }
  }
  dates.sort();
  return dates;
}
```

### Slider with Debounced Preview Refresh

```dart
// Inside RecurrenceSection StatefulWidget
int _weeks = 4;

// Eager local update on drag:
Slider(
  value: _weeks.toDouble(),
  min: 1,
  max: 52,
  divisions: 51,
  label: _endDateLabel(_weeks),
  onChanged: (v) => setState(() => _weeks = v.round()),
  onChangeEnd: (v) => widget.onWeeksChanged(v.round()),  // triggers Firestore check
),
Text(_endDateLabel(_weeks)),

String _endDateLabel(int weeks) {
  final anchor = DateTime.parse(widget.anchorDateString);
  final endDate = anchor.add(Duration(days: 7 * weeks));
  final dayName = DateFormat('EEE', 'pt_BR').format(endDate);
  final day = endDate.day.toString().padLeft(2, '0');
  final month = DateFormat('MMM', 'pt_BR').format(endDate);
  return '$weeks semana${weeks > 1 ? 's' : ''} (até ${dayName[0].toUpperCase()}${dayName.substring(1)} $day/$month)';
}
```

### Preview Item Widget

```dart
enum _PreviewStatus { loading, available, alreadyBooked, notFound }

class _PreviewDateItem extends StatelessWidget {
  final String dateString;
  final _PreviewStatus status;

  // ...

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat("EEE, d 'de' MMM", 'pt_BR')
        .format(DateTime.parse(dateString));

    return Row(
      children: [
        Icon(
          status == _PreviewStatus.available ? Icons.circle : Icons.circle_outlined,
          size: 10,
          color: status == _PreviewStatus.available
              ? AppTheme.primaryGreen
              : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          formatted,
          style: TextStyle(
            color: status == _PreviewStatus.available ? null : Colors.grey,
          ),
        ),
        if (status == _PreviewStatus.alreadyBooked)
          const Text(' · Já reservado', style: TextStyle(color: Colors.grey, fontSize: 12)),
        if (status == _PreviewStatus.notFound)
          const Text(' · Horário não cadastrado', style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
```

### BookingCard — Recorrente Badge

```dart
// Add inside BookingCard.build(), near the existing _statusBadge row
if (booking.recurrenceGroupId != null)
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: AppTheme.primaryGreen.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
    ),
    child: Text(
      'Recorrente',
      style: TextStyle(
        color: AppTheme.primaryGreen,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Single compound inequality restriction in Firestore | Firebase lifted the restriction (2023+) — multiple inequality filters on different fields allowed | Group-cancel query `where recurrenceGroupId == X AND date >= today` now works without workaround |
| Sequential async booking creation | `Future.wait` parallel execution | Preview checks for 10 weeks × 2 days (20 reads) complete in ~1 Firestore RTT instead of 20 |

**Deprecated/outdated:**
- `eagerError` parameter on `Future.wait`: Does not exist in Dart — do not use. Per-element try/catch is the correct approach.

---

## Open Questions

1. **Firestore multiple inequality filter support in current SDK version**
   - What we know: Firebase lifted the single-inequality restriction broadly in 2023; the project uses `cloud_firestore: ^6.1.3`
   - What's unclear: Whether `cloud_firestore` 6.x SDK requires Firestore database version upgrade to enable this
   - Recommendation: Test the `cancelGroupFuture` query against the real Firestore instance early (Wave 1 or Wave 2), not just the emulator. If the query fails, fall back to `where('recurrenceGroupId', isEqualTo: X).get()` and then filter `date >= today` in Dart.

2. **Composite index deployment**
   - What we know: `firestore.indexes.json` must include the `(recurrenceGroupId, date)` index
   - What's unclear: Whether the project currently deploys indexes via `firebase deploy --only firestore:indexes`
   - Recommendation: Check `firebase.json` deploy targets; add `firestore:indexes` if not already included.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK), bloc_test ^10.0.0, mocktail ^1.0.4 |
| Config file | pubspec.yaml dev_dependencies |
| Quick run command | `flutter test test/features/booking/` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BOOK-05 | `generateRecurrenceDates()` returns correct dates for multi-day selection | unit | `flutter test test/features/booking/recurrence_dates_test.dart` | Wave 0 |
| BOOK-05 | `BookingModel.toFirestore()` includes `recurrenceGroupId` when set | unit | `flutter test test/core/models/booking_model_test.dart` | Wave 0 |
| BOOK-05 | Preview: slot not found → status `notFound` | unit (mock Firestore) | `flutter test test/features/booking/recurrence_preview_test.dart` | Wave 0 |
| BOOK-05 | Conflicts listed in result — manual verification | manual | n/a | manual-only — requires real Firestore double-booking scenario |

**Note per project memory:** Do not generate unit or widget tests — `feedback_no_tests.md` says "Não gerar testes unitários nem de widget neste projeto". Skip Wave 0 test file creation. The Validation Architecture section is included per config but test files should NOT be created.

### Wave 0 Gaps
None — per project instructions, test files are not generated in this project.

---

## Sources

### Primary (HIGH confidence)
- Codebase read — `lib/core/models/booking_model.dart`, `lib/features/booking/cubit/booking_cubit.dart`, `lib/features/booking/ui/booking_confirmation_sheet.dart`, `lib/features/booking/ui/client_booking_detail_sheet.dart`, `lib/features/booking/ui/booking_card.dart`, `lib/features/admin/ui/slot_batch_sheet.dart`, `lib/features/booking/ui/my_bookings_screen.dart`
- `pubspec.yaml` + `pubspec.lock` — confirmed `uuid` as transitive dependency, all library versions

### Secondary (MEDIUM confidence)
- Flutter docs — `AnimatedSize`, `FilterChip`, `Slider.onChangeEnd`, `Future.wait` semantics
- Firestore docs — compound queries, `WriteBatch`, composite index requirements

### Tertiary (LOW confidence)
- Firestore multiple inequality filter availability in `cloud_firestore ^6.1.3` — flag for runtime validation

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already in project, versions verified from lockfile
- Architecture: HIGH — patterns extrapolated directly from existing codebase (bookSlot, SlotBatchSheet, ClientBookingDetailSheet)
- Pitfalls: HIGH for code patterns; MEDIUM for Firestore index deployment detail

**Research date:** 2026-04-04
**Valid until:** 2026-05-04 (30 days — Flutter/Firestore stack is stable)

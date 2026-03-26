# Phase 11: Melhorias Visuais - Research

**Researched:** 2026-03-26
**Domain:** Flutter UI — calendar_view DayView integration + spacing token system
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Pacote de calendar view:**
- Usar `calendar_view` (pub.dev) para a DayView com timeline vertical
- Integrar via `CalendarEventData` mapeado a partir de `SlotViewModel`
- Cada slot vira um evento com `startTime` + duração fixa de 1h (endTime = startTime + 60min)
- DayView renderiza automaticamente os blocos na timeline

**Layout da timeline (UI-02):**
- Timeline vertical contínua com timestamps na coluna esquerda (estilo Google Calendar DayView)
- Todas as horas do range são exibidas, mesmo sem slots — linha divisora leve entre horas vazias
- Range dinâmico: 1h antes do primeiro slot até 1h depois do último slot do dia (configuração atual)
- Blocos de slot com altura proporcional à duração (1h = altura de 1 linha-hora)

**Navegação por dias:**
- Manter DayChipRow + WeekHeader existentes no topo — sem swipe horizontal
- Scroll automático para o primeiro slot do dia ao selecionar um dia

**Interações:**
- Tap no bloco de slot disponível abre `BookingConfirmationSheet` (igual ao fluxo atual)
- Slots ocupados, myBooking e bloqueados não são tapáveis
- Nenhuma mudança no fluxo de booking — só o componente visual muda

**Visual dos blocos na timeline:**
- Disponível: verde claro (AppTheme.primaryGreen com opacity baixa, texto escuro)
- Ocupado: cinza claro
- Minha reserva: verde/azul escuro (cor primária sólida)
- Bloqueado: vermelho claro
- Conteúdo de cada bloco: horário (startTime), preço (para disponíveis), nome do reservante (para ocupados), status badge

**Duração dos slots:**
- Duração fixa de 1h (60 minutos) — constante no código
- endTime = startTime + 60min ao mapear para CalendarEventData
- Sem alterar SlotModel nem os documentos Firestore existentes

**Empty state e loading:**
- Dia sem slots: timeline renderizada + texto centralizado "Nenhum horário disponível para este dia"
- Dia bloqueado: timeline renderizada + texto "Dia bloqueado — sem horários disponíveis"
- Loading: blocos cinza animados (shimmer) posicionados na timeline durante carregamento

**UI-03: Spacing sistemático:**
- Criar `lib/core/theme/app_spacing.dart` com tokens: xs=4, sm=8, md=16, lg=24, xl=32
- Audit em todas as telas e substituir literais de padding/margin pelos tokens
- Abordagem: spacing sistemático (layout fixes são best-effort)
- Telas: Schedule, MyBookings, Profile, Login, Register, Admin (slots, bookings, users, blocked dates)

### Claude's Discretion
- Configuração exata da DayView (headerStyle, timeLineStringBuilder, backgroundColor)
- Configuração do shimmer (duração de animação, número de blocos simulados)
- Decisão sobre incluir "now indicator" (linha da hora atual) — pode adicionar se o `calendar_view` suportar nativamente

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| UI-02 | Agenda exibe slots em colunas verticais por hora estilo Google Calendar com navegação por dias | calendar_view DayView API, CalendarEventData mapping, eventTileBuilder pattern |
| UI-03 | Todas as telas do app usam espaçamentos, tipografia e componentes visuais consistentes; nenhuma tela com overflow em 375px/390px | AppSpacing token file, spacing literal audit pattern across all screens |
</phase_requirements>

---

## Summary

This phase has two independent workstreams: replacing `SlotList` with a `calendar_view` `DayView` (UI-02), and creating a spacing token system applied across all screens (UI-03).

For UI-02, the `calendar_view` package (current version 2.0.0, pinned — 2.x introduces breaking changes) provides a `DayView<T>` widget that renders a vertical hourly timeline. The package requires wrapping the widget tree with `CalendarControllerProvider<T>` (or passing an `EventController<T>` directly). Each slot becomes a `CalendarEventData<SlotViewModel>` carrying the original `SlotViewModel` in its `.event` field. An `eventTileBuilder` callback returns a custom widget per slot, replicating the color/label logic from `slot_card.dart`. The key integration challenge is controlling the displayed hour range dynamically (startHour/endHour computed from the day's slots) and handling `onEventTap` with the `BookingConfirmationSheet` pattern established in Phase 4.

For UI-03, the audit revealed that all screens use consistent literal values already (horizontal: 24 on forms, horizontal: 16 on lists, vertical: 8/4 on list items). The token file creation is straightforward; the audit is mechanical substitution. No overflow issues were found in the inspected screens — they all use `SingleChildScrollView` or `ListView` with proper padding.

**Primary recommendation:** Use `calendar_view: 2.0.0` (exact pin), pass `EventController<SlotViewModel>` directly to `DayView` (no `CalendarControllerProvider` needed for a single view), build a custom `eventTileBuilder`, and compute `startHour`/`endHour` from the slot list before constructing the `DayView`.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| calendar_view | 2.0.0 (exact pin) | DayView timeline widget | Decided by user; provides Google Calendar-style day timeline out-of-the-box |

### No New Supporting Libraries
All other required libraries (flutter_bloc, intl) are already in `pubspec.yaml`. The shimmer loading effect will be implemented using the existing `SlotSkeleton` animation pattern (opacity pulse via `AnimationController`) — no shimmer package needed.

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| calendar_view | flutter_calendar_carousel, syncfusion_flutter_calendar | User explicitly chose calendar_view — not open for alternatives |
| Custom EventTileBuilder | calendar_view default tile | Default tile does not expose status colors or Portuguese labels |

**Installation:**
```bash
flutter pub add calendar_view:2.0.0
```

Or in `pubspec.yaml`:
```yaml
dependencies:
  calendar_view: 2.0.0  # Exact version — 2.x series has breaking changes per pub.dev warning
```

**Version verification:** Confirmed 2.0.0 is the current latest stable (published 9 days ago as of 2026-03-26, per pub.dev).

---

## Architecture Patterns

### Recommended Project Structure Changes
```
lib/
├── core/
│   └── theme/
│       ├── app_theme.dart          # existing — add import of app_spacing.dart
│       └── app_spacing.dart        # NEW — spacing token constants
├── features/
│   └── schedule/
│       └── ui/
│           ├── schedule_screen.dart    # modified — DayView replaces SlotList
│           ├── slot_day_view.dart      # NEW — DayView widget + EventController logic
│           ├── slot_event_tile.dart    # NEW — custom eventTileBuilder widget
│           └── slot_list.dart          # kept — can be deleted or kept as fallback
```

### Pattern 1: Direct EventController (No CalendarControllerProvider)

**What:** Pass an `EventController<SlotViewModel>` directly to `DayView.controller`. Recreate the controller when the selected day changes, or use `controller.removeWhere` + `controller.addAll` to update events.

**When to use:** Single-view usage — no cross-view synchronization needed. Simpler than wrapping the subtree with `CalendarControllerProvider`.

```dart
// Source: https://raw.githubusercontent.com/SimformSolutionsPvtLtd/flutter_calendar_view/master/lib/src/day_view/day_view.dart
final _eventController = EventController<SlotViewModel>();

// Map SlotViewModel list to CalendarEventData
void _updateEvents(List<SlotViewModel> slots, DateTime selectedDay) {
  _eventController.removeWhere((_) => true);
  for (final vm in slots) {
    final parts = vm.slot.startTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final start = DateTime(
      selectedDay.year, selectedDay.month, selectedDay.day, hour, minute,
    );
    final end = start.add(const Duration(hours: 1));
    _eventController.add(CalendarEventData<SlotViewModel>(
      date: selectedDay,
      startTime: start,
      endTime: end,
      title: vm.slot.startTime,
      color: _colorForStatus(vm.status),
      event: vm,
    ));
  }
}
```

### Pattern 2: Dynamic Hour Range via startHour/endHour

**What:** Compute `startHour` and `endHour` from the loaded slots list, pass to `DayView`. Rebuild the widget (or use a key) when the selected day changes to reset scroll position.

**When to use:** Required by CONTEXT.md — range is 1h before first slot to 1h after last slot.

```dart
int _computeStartHour(List<SlotViewModel> slots) {
  if (slots.isEmpty) return 6; // fallback
  final hours = slots.map((vm) {
    return int.parse(vm.slot.startTime.split(':')[0]);
  });
  return (hours.reduce(min) - 1).clamp(0, 23);
}

int _computeEndHour(List<SlotViewModel> slots) {
  if (slots.isEmpty) return 22; // fallback
  final hours = slots.map((vm) {
    return int.parse(vm.slot.startTime.split(':')[0]) + 1; // slot ends at start+1h
  });
  return (hours.reduce(max) + 1).clamp(1, 24);
}
```

### Pattern 3: EventTileBuilder for Custom Slot Tiles

**What:** The `eventTileBuilder` callback receives `(DateTime date, List<CalendarEventData<T>> events, Rect boundary, DateTime startDuration, DateTime endDuration)`. Return a widget that fits inside `boundary`.

**Exact typedef:**
```dart
// Source: typedefs.dart
typedef EventTileBuilder<T> = Widget Function(
  DateTime date,
  List<CalendarEventData<T>> events,
  Rect boundary,
  DateTime startDuration,
  DateTime endDuration,
);
```

```dart
Widget _slotEventTileBuilder(
  DateTime date,
  List<CalendarEventData<SlotViewModel>> events,
  Rect boundary,
  DateTime startDuration,
  DateTime endDuration,
) {
  if (events.isEmpty) return const SizedBox.shrink();
  final vm = events.first.event!;
  return SlotEventTile(viewModel: vm, onTap: vm.status == SlotStatus.available
      ? () => _showBookingSheet(context, vm)
      : null);
}
```

### Pattern 4: onEventTap Callback

**Exact typedef:**
```dart
// Source: typedefs.dart
typedef CellTapCallback<T> = void Function(
  List<CalendarEventData<T>> events,
  DateTime date,
);
```

Note: `onEventTap` receives a List (multiple overlapping events possible). Since slots are non-overlapping 1h blocks, `events.first` is always the target.

```dart
// IMPORTANT: capture context.read before DayView build, per Phase 4 pattern
onEventTap: (events, date) {
  if (events.isEmpty) return;
  final vm = events.first.event as SlotViewModel?;
  if (vm == null || vm.status != SlotStatus.available) return;
  _showBookingSheet(context, vm);
},
```

### Pattern 5: AppSpacing Token File

**What:** Static constants class, imported wherever `SizedBox`, `EdgeInsets`, or `Padding` with literal values appear.

```dart
// lib/core/theme/app_spacing.dart
class AppSpacing {
  AppSpacing._(); // private constructor

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}
```

Usage pattern:
```dart
// Before
padding: const EdgeInsets.all(16)
const SizedBox(height: 24)

// After
padding: const EdgeInsets.all(AppSpacing.md)
const SizedBox(height: AppSpacing.lg)
```

### Anti-Patterns to Avoid

- **Wrapping entire app with CalendarControllerProvider unnecessarily:** Not required for single DayView usage. Only needed for multi-view sync (MonthView + DayView together).
- **Using ^ semver for calendar_view:** pub.dev explicitly warns "All 2.x.x releases may include breaking changes." Pin to `2.0.0`.
- **Calling context.read inside onEventTap builder:** Capture `bookingCubit` before `DayView.build()` per the Phase 4 pattern for `showModalBottomSheet`.
- **Hardcoded startHour/endHour:** Must be dynamic per CONTEXT.md. Computing them from the slots list is required.
- **Rebuilding EventController on every state change:** Use `controller.removeWhere` + `controller.add` pattern instead of recreating the controller, to avoid scroll position reset.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Vertical hourly timeline | Custom CustomPaint or ScrollView with positioned boxes | `DayView` from calendar_view | Hour lines, time labels, event positioning, scroll to time are all built in |
| Shimmer loading effect | New shimmer package | Adapt `SlotSkeleton` opacity animation pattern | Already in codebase; adding a shimmer package for one loading state is overkill |
| Time label formatting | Custom HH:mm builder from scratch | `timeStringBuilder` parameter on DayView | DayView accepts a callback `StringProvider` to format time labels |

**Key insight:** `DayView` handles the hardest parts — pixel-perfect event positioning within an hour grid, scroll-to-position, live time indicator — all of which are non-trivial to implement correctly.

---

## Common Pitfalls

### Pitfall 1: EventController scope and disposal

**What goes wrong:** `EventController` is created in a `StatelessWidget` build method or not disposed, causing memory leaks or stale data.

**Why it happens:** `EventController` is not a Flutter `ChangeNotifier` with automatic disposal.

**How to avoid:** Create `EventController` in `State.initState()` of a `StatefulWidget`. Dispose in `State.dispose()`.

**Warning signs:** Events still visible after navigating away; duplicate events appearing.

### Pitfall 2: DayView ignores startHour/endHour unless events are within range

**What goes wrong:** Setting `startHour: 8` but events outside that range are silently excluded.

**Why it happens:** `DayView` clips rendering to `[startHour, endHour]`.

**How to avoid:** Always compute `startHour` to be at least 1h before earliest slot, `endHour` at least 1h after latest slot end time (startTime + 1h).

**Warning signs:** Slots disappearing from the view.

### Pitfall 3: context.read inside DayView callbacks

**What goes wrong:** `context.read<BookingCubit>()` inside `onEventTap` or `eventTileBuilder` throws "Could not find the correct Provider" because the calendar widget subtree does not inherit BlocProviders.

**Why it happens:** Same issue as `showModalBottomSheet` described in Phase 4 STATE.md decision.

**How to avoid:** Capture `final bookingCubit = context.read<BookingCubit>()` before passing `onEventTap` to DayView, or pass the cubit as a parameter to the tile builder widget.

**Warning signs:** ProviderNotFoundException at runtime when tapping an event.

### Pitfall 4: DayView header conflicts with existing WeekHeader/DayChipRow

**What goes wrong:** DayView renders its own date header at the top, duplicating the existing WeekHeader/DayChipRow navigation.

**Why it happens:** DayView has a built-in `dayTitleBuilder` header enabled by default.

**How to avoid:** Pass a custom `dayTitleBuilder` that returns `const SizedBox.shrink()` to hide DayView's built-in header. The existing WeekHeader + DayChipRow remain above the DayView.

**Warning signs:** Two date rows visible at the top of the schedule screen.

### Pitfall 5: Spacing token import forgetting

**What goes wrong:** Some screens updated, others not; inconsistency remains.

**Why it happens:** Audit done in one pass but some literals missed.

**How to avoid:** After creating `app_spacing.dart`, grep the entire codebase for literal padding/margin values (4.0, 8.0, 16.0, 24.0, 32.0) to find all instances. Cross-reference with the screen list in CONTEXT.md.

---

## Code Examples

Verified patterns from official sources:

### DayView minimal setup (calendar_view 2.0.0)
```dart
// Source: https://raw.githubusercontent.com/SimformSolutionsPvtLtd/flutter_calendar_view/master/lib/src/day_view/day_view.dart
DayView<SlotViewModel>(
  controller: _eventController,
  initialDay: _selectedDay,
  startHour: _startHour,          // dynamic, computed from slots
  endHour: _endHour,              // dynamic, computed from slots
  heightPerMinute: 1.0,           // 60px per hour — adjust to taste
  showLiveTimeLineInAllDays: true, // "now" indicator — built-in, no extra work
  backgroundColor: Colors.white,
  eventTileBuilder: _slotEventTileBuilder,
  onEventTap: (events, date) { /* ... */ },
  dayTitleBuilder: (_) => const SizedBox.shrink(), // hide DayView's own header
  headerStyle: const HeaderStyle(decoration: BoxDecoration()), // minimal header
  timeStringBuilder: (dt, {secondaryDate}) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
)
```

### CalendarEventData<SlotViewModel> construction
```dart
// Source: https://raw.githubusercontent.com/SimformSolutionsPvtLtd/flutter_calendar_view/master/lib/src/calendar_event_data.dart
CalendarEventData<SlotViewModel>(
  date: selectedDay,                        // required DateTime
  startTime: startDateTime,                  // full DateTime with time
  endTime: startDateTime.add(const Duration(hours: 1)),
  title: vm.slot.startTime,                 // shown if no custom tile builder
  color: _colorForStatus(vm.status),        // background color hint
  event: vm,                                // carry the full SlotViewModel
)
```

### Color mapping from SlotStatus (mirrors slot_card.dart)
```dart
Color _colorForStatus(SlotStatus status) => switch (status) {
  SlotStatus.available  => AppTheme.primaryGreen.withOpacity(0.2),
  SlotStatus.booked     => Colors.grey.shade200,
  SlotStatus.myBooking  => AppTheme.primaryGreen,
  SlotStatus.blocked    => const Color(0xFFE53935).withOpacity(0.2),
};
```

### Scroll to first slot on day selection
```dart
// DayView exposes a scrollController parameter. Store a ScrollController and
// call animateTo after the frame renders.
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (slots.isNotEmpty && _scrollController.hasClients) {
    final firstHour = int.parse(slots.first.slot.startTime.split(':')[0]);
    final targetOffset = (firstHour - _startHour) * 60.0 * heightPerMinute;
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
});
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| SlotList (ListView of SlotCards) | DayView with eventTileBuilder | Phase 11 | Google Calendar-style vertical timeline |
| Hardcoded padding literals throughout | AppSpacing token constants | Phase 11 | Single source of truth for spacing |
| SlotSkeleton (list-style shimmer) | Timeline shimmer (blocks positioned on DayView grid) | Phase 11 | Loading state matches new timeline layout |

**Deprecated/outdated in this phase:**
- `SlotList` widget: replaced by `slot_day_view.dart`. File can be removed after DayView is stable.
- `SlotSkeleton`: repurposed for timeline loading or replaced by shimmer blocks positioned on the grid.

---

## Open Questions

1. **heightPerMinute value for usable block size**
   - What we know: `heightPerMinute: 0.7` is the DayView default, giving 42px per hour
   - What's unclear: Whether 42px is tall enough for the slot tile content (time, price, status badge) on a 375px-wide mobile
   - Recommendation: Use `heightPerMinute: 1.0` (60px per hour) as starting point; adjust if content overflows the block height

2. **keepScrollOffset behavior across day switches**
   - What we know: `DayView` has `keepScrollOffset: bool` parameter (default false)
   - What's unclear: Whether setting `true` would keep scroll position when the user switches days, which could be jarring
   - Recommendation: Keep `false` (default) and use the scroll-to-first-slot pattern from CONTEXT.md

3. **EventController.removeWhere signature**
   - What we know: API exists for removing events
   - What's unclear: Exact predicate signature in version 2.0.0 may differ from 1.x
   - Recommendation: Check at implementation time; fallback is to use a new `EventController` with a `ValueKey(_selectedDay)` on `DayView` to force rebuild per day

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK built-in) + bloc_test ^10.0.0 + mocktail ^1.0.4 |
| Config file | None — uses default Flutter test runner |
| Quick run command | `flutter test test/` |
| Full suite command | `flutter test test/` |

### Phase Requirements → Test Map

Per project memory (`feedback_no_tests.md`): **Do not generate unit tests nor widget tests for this project.**

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| UI-02 | DayView renders slots in vertical timeline | manual-only | N/A — no tests per project policy | N/A |
| UI-03 | AppSpacing tokens applied across all screens | manual-only | N/A — no tests per project policy | N/A |

### Sampling Rate
- **Per task commit:** Manual visual inspection in browser/emulator
- **Per wave merge:** Manual visual inspection on 375px viewport
- **Phase gate:** Full visual review before `/gsd:verify-work`

### Wave 0 Gaps
None — no tests to be written per project policy (feedback_no_tests.md).

---

## Sources

### Primary (HIGH confidence)
- `https://raw.githubusercontent.com/SimformSolutionsPvtLtd/flutter_calendar_view/master/lib/src/day_view/day_view.dart` — Full DayView constructor parameters
- `https://raw.githubusercontent.com/SimformSolutionsPvtLtd/flutter_calendar_view/master/lib/src/calendar_event_data.dart` — CalendarEventData constructor
- `https://raw.githubusercontent.com/SimformSolutionsPvtLtd/flutter_calendar_view/master/lib/src/typedefs.dart` — CellTapCallback, EventTileBuilder type signatures
- `https://raw.githubusercontent.com/SimformSolutionsPvtLtd/flutter_calendar_view/master/lib/src/calendar_controller_provider.dart` — CalendarControllerProvider / EventController pattern
- `https://pub.dev/packages/calendar_view` — Version 2.0.0 confirmation, breaking changes warning

### Secondary (MEDIUM confidence)
- Codebase inspection: `lib/features/schedule/ui/slot_card.dart` — color/label mapping verified
- Codebase inspection: `lib/features/schedule/models/slot_view_model.dart` — SlotViewModel fields confirmed
- Codebase inspection: `lib/features/schedule/ui/slot_list.dart` — _showBookingSheet pattern confirmed
- Codebase inspection: all target screens — spacing literal values audited

### Tertiary (LOW confidence)
- pub.dev changelog for 2.0.0: Breaking changes described as "possible" but not enumerated in detail; exact API changes vs 1.x not fully documented

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — version 2.0.0 verified on pub.dev, constructor params from actual source
- Architecture: HIGH — DayView API verified from GitHub source; integration patterns from existing codebase
- Pitfalls: HIGH — Phase 4 patterns (context.read + showModalBottomSheet) verified in STATE.md; DayView header pitfall from API inspection
- Spacing audit: HIGH — all target screen files read directly

**Research date:** 2026-03-26
**Valid until:** 2026-04-26 (stable package; 30-day window)

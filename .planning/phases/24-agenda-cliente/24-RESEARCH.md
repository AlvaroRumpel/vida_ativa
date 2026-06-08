# Phase 24: Agenda (Cliente) — Research

**Researched:** 2026-05-25
**Domain:** Flutter widget rewrite — Schedule screen (ScheduleScreen, DayChipRow, SlotCard, SlotList)
**Confidence:** HIGH — all findings verified by direct codebase read

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- D-01: Remove AppBar from ScheduleScreen — use custom inline header in Scaffold body
- D-02: Header layout: wordmark "VIDA ATIVA" (Anton + orange pill) LEFT, selected day eyebrow in JetBrains Mono RIGHT — single inline Row
- D-03: Below inline header: existing WeekHeader (← Semana de X →) stays unchanged
- D-04: Selected-day eyebrow = abbreviated day + number + month in Mono uppercase (e.g. "SEG, 26 MAI") — updates with `_selectedDay`
- D-05: Replace DayChipRow (ChoiceChip) with SportDayStrip — column per day: 3-letter mono abbrev + Anton number
- D-06: Selected day: 2px orange underline — no chip, no filled background
- D-07: Today (not selected): Anton number in AppTheme.orange — no underline, no dot
- D-08: Other days: Anton number in AppTheme.ink
- D-09: Replace SlotCard (Card widget) with SlotHairlineRow — no Card, hairline divider between rows
- D-10: Each row: time in Anton 42px (left) + price in mono (right) + status label in mono (far right)
- D-11: myBooking: 3px orange left stripe, opacity 1.0, label "Minha reserva", tappable → opens ClientBookingDetailSheet
- D-12: booked: no stripe, opacity 0.45, label = bookerName in mono, not tappable
- D-13: blocked: no stripe, opacity 0.45, label "Bloqueado", not tappable
- D-14: available: no stripe, opacity 1.0, label "Disponível" in AppTheme.court, tappable → opens BookingConfirmationSheet (current behavior)

### Claude's Discretion
- Padding/spacing inside header (horizontal and vertical)
- Orange pill size (padding + border-radius)
- Left stripe width (3px per spec)
- Hairline divider = Border(top: BorderSide(color: AppTheme.lineHair)) on each row except first
- Exact widget names: SportDayStrip, SlotHairlineRow
- SlotHairlineRow integration: SlotList calls the new widget, not SlotCard
- ClientBookingDetailSheet already exists — just call showModalBottomSheet for myBooking

### Deferred Ideas (OUT OF SCOPE)
- Auto-scroll to nearest slot to current time — Phase 24+ or v7
- Day transition animation — v7+
- Sport field shown in slot row — kept out of row to avoid clutter
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SCHED-04 | Day selector replaced by horizontal strip with columns (mono abbrev + Anton number), active marked with 2px orange underline | DayChipRow current code fully read; SportDayStrip interface confirmed compatible with existing call site in ScheduleScreen |
| SCHED-05 | Slot rows use hairline layout (no Card): time in Anton 42px, 3px orange stripe for myBooking, opacity 0.45 for booked-by-other | SlotCard fully read; SlotViewModel/SlotStatus fully read; SlotList call site fully read |
| SCHED-06 | Schedule header shows wordmark "VIDA ATIVA" (Anton + orange pill) and mono eyebrow with selected day date | ScheduleScreen AppBar fully read; `_selectedDay` state confirmed available; `_onDaySelected` callback confirmed |
</phase_requirements>

---

## 1. Files to Modify (with current signatures)

### 1.1 `lib/features/schedule/ui/schedule_screen.dart`

**Current size:** 101 lines

**Current AppBar block (lines 66–75) — DELETE entirely:**
```dart
appBar: AppBar(
  title: Row(
    mainAxisSize: MainAxisSize.min,
    children: const [
      Icon(Icons.sports_volleyball, size: 20, color: Color(0xFFD4860A)),
      SizedBox(width: 8),
      Text('Agenda'),
    ],
  ),
),
```

**Raw hex violation (line 71):** `Color(0xFFD4860A)` — deleted with the AppBar block, no separate fix needed.

**Current import on line 5:**
```dart
import 'package:vida_ativa/features/schedule/ui/day_chip_row.dart';
```
Change to:
```dart
import 'package:vida_ativa/features/schedule/ui/day_chip_row.dart'; // class renamed to SportDayStrip
```
No import path change is needed because the file is rewritten in-place. Widget call site changes from `DayChipRow(` to `SportDayStrip(`.

**Current body Column (lines 76–99):**
```dart
body: Column(
  children: [
    WeekHeader(...),          // line 78
    DayChipRow(...),          // line 83 — rename to SportDayStrip
    const SizedBox(height: 8),
    Expanded(child: BlocBuilder(...)),
  ],
),
```

**New body Column structure:**
```dart
body: Column(
  children: [
    SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('VIDA ATIVA', style: AppTheme.display(size: 18, color: AppTheme.paper)),
            ),
            const Spacer(),
            Text(_eyebrowDate(_selectedDay), style: AppTheme.mono(size: 11, color: AppTheme.ink)),
          ],
        ),
      ),
    ),
    WeekHeader(
      weekStart: _weekStart,
      onPreviousWeek: _canGoPrevious ? _goToPreviousWeek : null,
      onNextWeek: _canGoNext ? _goToNextWeek : null,
    ),
    SportDayStrip(
      weekStart: _weekStart,
      selectedDay: _selectedDay,
      onDaySelected: _onDaySelected,
    ),
    const SizedBox(height: 8),
    Expanded(
      child: BlocBuilder<ScheduleCubit, ScheduleState>(
        builder: (context, state) => SlotDayView(
          state: state,
          selectedDay: _selectedDay,
        ),
      ),
    ),
  ],
),
```

**New helper method to add to `_ScheduleScreenState`:**
```dart
String _eyebrowDate(DateTime day) {
  const abbrevDays = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];
  const abbrevMonths = ['JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'];
  final dayName = abbrevDays[day.weekday - 1];
  final monthName = abbrevMonths[day.month - 1];
  return '$dayName, ${day.day} $monthName';
}
```

**Import to add:**
```dart
import 'package:vida_ativa/core/theme/app_theme.dart';
```
(AppTheme is not currently imported in schedule_screen.dart.)

---

### 1.2 `lib/features/schedule/ui/day_chip_row.dart`

**Current size:** 95 lines

**Full rewrite.** Class `DayChipRow` becomes `SportDayStrip`.

**Current constructor (lines 4–14) — existing props are compatible:**
```dart
class DayChipRow extends StatelessWidget {
  final DateTime weekStart;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  const DayChipRow({
    super.key,
    required this.weekStart,
    required this.selectedDay,
    required this.onDaySelected,
  });
```
SportDayStrip takes the **exact same three props** — no call-site changes in ScheduleScreen beyond renaming `DayChipRow(` to `SportDayStrip(`.

**Things to DELETE in the rewrite:**
- `_dayAbbrev` list (replaces mixed-case 'Seg', 'Ter', … with uppercase 'SEG', 'TER', …)
- `SingleChildScrollView` wrapper (lines 34–35, 93)
- `ChoiceChip(...)` widget (lines 46–77)
- 5px dot `Container` below chip (lines 79–88)
- Raw hex `Color(0xFF4A4A4A)` (line 55) and `Color(0xFFF0EDE8)` (line 64)
- Legacy alias references: `AppTheme.brandAmber` (lines 54, 70, 83), `AppTheme.primaryGreen` (line 63)
- Horizontal `Padding` with symmetric(horizontal: 4) per chip (line 41)

**Color violations in current file:**
| Line | Raw Hex | Replace With |
|------|---------|--------------|
| 55 | `Color(0xFF4A4A4A)` | deleted with ChoiceChip block |
| 64 | `Color(0xFFF0EDE8)` | deleted with ChoiceChip block |
| 54, 70, 83 | `AppTheme.brandAmber` | `AppTheme.orange` (or delete with ChoiceChip) |
| 63 | `AppTheme.primaryGreen` | `AppTheme.court` (or delete with ChoiceChip) |

**New SportDayStrip body:**
```dart
class SportDayStrip extends StatelessWidget {
  final DateTime weekStart;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  const SportDayStrip({
    super.key,
    required this.weekStart,
    required this.selectedDay,
    required this.onDaySelected,
  });

  static const _abbrev = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Color _numberColor(bool isSelected, bool isToday) {
    if (isSelected) return AppTheme.orange;
    if (isToday)    return AppTheme.orange;
    return AppTheme.ink;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final day = weekStart.add(Duration(days: i));
          final isSelected = _isSameDay(day, selectedDay);
          final isToday = _isSameDay(day, today);
          return GestureDetector(
            onTap: () => onDaySelected(day),
            child: SizedBox(
              width: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(_abbrev[i], style: AppTheme.mono(size: 11, color: AppTheme.concrete)),
                  const SizedBox(height: 4),
                  Text('${day.day}', style: AppTheme.display(size: 22, color: _numberColor(isSelected, isToday))),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 2,
                    width: isSelected ? 24 : 0,
                    color: AppTheme.orange,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
```

---

### 1.3 `lib/features/schedule/ui/slot_card.dart`

**Current size:** 114 lines

**Full rewrite.** Class `SlotCard` becomes `SlotHairlineRow`. Helper class `_StatusLabel` is deleted (logic inlined via helper methods).

**Current SlotCard constructor (lines 6–10):**
```dart
class SlotCard extends StatelessWidget {
  final SlotViewModel viewModel;
  final VoidCallback? onTap;

  const SlotCard({super.key, required this.viewModel, this.onTap});
```

**New SlotHairlineRow constructor (adds `index` and `onDetailTap`):**
```dart
class SlotHairlineRow extends StatelessWidget {
  final SlotViewModel viewModel;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onDetailTap;

  const SlotHairlineRow({
    super.key,
    required this.viewModel,
    required this.index,
    this.onTap,
    this.onDetailTap,
  });
```

**Color violations in current `slot_card.dart`:**
| Line | Raw Hex / Legacy | Replace With |
|------|-----------------|--------------|
| 63 | `Colors.grey` (booked status color) | deleted — no stripe in new design |
| 63 | `Colors.grey` (myBooking status color) | deleted — stripe uses `AppTheme.orange` |
| 65 | `Color(0xFFE53935)` (blocked status color) | deleted — no stripe in new design |
| 84 | `AppTheme.primaryGreen` | `AppTheme.court` |
| 111 | `Color(0xFFE53935)` | `AppTheme.concrete` (blocked label color) |
| 89–90 | `Colors.grey` / `Colors.grey[200]` | deleted with _StatusLabel |

**Things to DELETE:**
- `Card(...)` widget — entire block
- `IntrinsicHeight(...)` for the main layout — replaced by conditional pattern
- `_StatusLabel` class (lines 72–113)
- `_statusColor()` method (lines 61–66)
- All `Color(0xFF...)` literals
- `AppTheme.primaryGreen` reference
- `const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)` — replaced by `AppTheme.display(size: 42)`
- `const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)` — replaced by `AppTheme.mono(size: 11)`

**New helper methods:**
```dart
double _opacity(SlotStatus status) => switch (status) {
  SlotStatus.available  => 1.0,
  SlotStatus.myBooking  => 1.0,
  SlotStatus.booked     => 0.45,
  SlotStatus.blocked    => 0.45,
};

String _statusLabel(SlotViewModel vm) => switch (vm.status) {
  SlotStatus.available  => 'DISPONÍVEL',
  SlotStatus.myBooking  => 'MINHA RESERVA',
  SlotStatus.booked     => (vm.bookerName ?? 'OCUPADO').toUpperCase(),
  SlotStatus.blocked    => 'BLOQUEADO',
};

Color _statusLabelColor(SlotStatus status) => switch (status) {
  SlotStatus.available  => AppTheme.court,
  SlotStatus.myBooking  => AppTheme.concrete,
  SlotStatus.booked     => AppTheme.concrete,
  SlotStatus.blocked    => AppTheme.concrete,
};
```

**Border decoration helper (reused in both build paths):**
```dart
BoxDecoration _borderDecoration() => BoxDecoration(
  border: index == 0 ? null : const Border(
    top: BorderSide(color: AppTheme.lineHair, width: 0.5),
  ),
);
```

**Content row (shared between stripe and no-stripe paths):**
```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Text(viewModel.slot.startTime, style: AppTheme.display(size: 42)),
    const Spacer(),
    Text(_formatPrice(viewModel.slot.price), style: AppTheme.mono(size: 11)),
    const SizedBox(width: 12),
    SizedBox(
      width: 96,
      child: Text(
        _statusLabel(viewModel),
        style: AppTheme.mono(size: 11, color: _statusLabelColor(viewModel.status)),
        textAlign: TextAlign.right,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    ),
  ],
)
```

---

### 1.4 `lib/features/schedule/ui/slot_list.dart`

**Current size:** 85 lines

**Changes required (not a full rewrite):**

1. **Line 8** — change import:
   ```dart
   // OLD:
   import 'package:vida_ativa/features/schedule/ui/slot_card.dart';
   // NEW:
   import 'package:vida_ativa/features/schedule/ui/slot_card.dart'; // class is now SlotHairlineRow
   ```
   Import path unchanged (file rewritten in-place). Widget name changes.

2. **Add import** for ClientBookingDetailSheet:
   ```dart
   import 'package:vida_ativa/features/booking/ui/client_booking_detail_sheet.dart';
   ```

3. **Add import** for BookingCubit (needed for `_showDetailSheet`):
   ```dart
   // Already imported on line 4:
   import 'package:vida_ativa/features/booking/cubit/booking_cubit.dart';
   ```
   Already present — no action needed.

4. **Lines 44–56** — replace `ListView.builder` block:
   ```dart
   // OLD:
   ScheduleLoaded(:final slots) => ListView.builder(
     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
     itemCount: slots.length,
     itemBuilder: (context, index) {
       final vm = slots[index];
       return SlotCard(
         viewModel: vm,
         onTap: vm.status == SlotStatus.available
             ? () => _showBookingSheet(context, vm)
             : null,
       );
     },
   ),

   // NEW:
   ScheduleLoaded(:final slots) => ListView.builder(
     padding: const EdgeInsets.only(bottom: 16),
     itemCount: slots.length,
     itemBuilder: (context, index) {
       final vm = slots[index];
       return SlotHairlineRow(
         viewModel: vm,
         index: index,
         onTap: vm.status == SlotStatus.available
             ? () => _showBookingSheet(context, vm)
             : null,
         onDetailTap: vm.status == SlotStatus.myBooking
             ? () => _showDetailSheet(context, vm)
             : null,
       );
     },
   ),
   ```

5. **Add `_showDetailSheet` function** (top-level, after `_showBookingSheet`):
   ```dart
   void _showDetailSheet(BuildContext context, SlotViewModel viewModel) {
     final bookingCubit = context.read<BookingCubit>();
     showModalBottomSheet(
       context: context,
       isScrollControlled: true,
       shape: const RoundedRectangleBorder(
         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
       ),
       builder: (_) => ClientBookingDetailSheet(
         booking: viewModel.booking!,
         bookingCubit: bookingCubit,
         isFuture: true,
       ),
     );
   }
   ```

---

## 2. Files to Read Only (with relevant extracts)

### 2.1 `lib/features/schedule/models/slot_view_model.dart`

**DO NOT MODIFY.** Verified fields used by SlotHairlineRow:

```dart
enum SlotStatus { available, booked, myBooking, blocked }

class SlotViewModel extends Equatable {
  final SlotModel slot;        // slot.startTime (String), slot.price (double)
  final SlotStatus status;
  final String dateString;
  final String? bookerName;    // used for booked label; null-safe required
  final BookingModel? booking; // non-null when status == myBooking; bang-safe to use vm.booking!
  // ...
}
```

**Key field access patterns:**
- Time: `viewModel.slot.startTime` — String, already formatted (e.g. "09:00")
- Price: `viewModel.slot.price` — double, format with `NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')`
- Booker name: `viewModel.bookerName` — nullable String; use `?? 'OCUPADO'` fallback
- Booking object: `viewModel.booking!` — safe to bang only after checking `status == SlotStatus.myBooking`

### 2.2 `lib/features/schedule/ui/week_header.dart`

**DO NOT MODIFY.** Signature:
```dart
class WeekHeader extends StatelessWidget {
  final DateTime weekStart;
  final VoidCallback? onPreviousWeek;
  final VoidCallback? onNextWeek;

  const WeekHeader({
    super.key,
    required this.weekStart,
    this.onPreviousWeek,
    this.onNextWeek,
  });
```
Call site in ScheduleScreen already passes all three — no changes needed.

### 2.3 `lib/features/booking/ui/client_booking_detail_sheet.dart`

**DO NOT MODIFY.** Constructor signature (lines 9–19):
```dart
class ClientBookingDetailSheet extends StatefulWidget {
  final BookingModel booking;
  final BookingCubit bookingCubit;
  final bool isFuture;

  const ClientBookingDetailSheet({
    super.key,
    required this.booking,
    required this.bookingCubit,
    required this.isFuture,
  });
```

**Critical:** Three required named parameters — `booking`, `bookingCubit`, `isFuture`. The `_showDetailSheet` call in slot_list.dart MUST provide all three:
- `booking: viewModel.booking!` — BookingModel (from SlotViewModel.booking)
- `bookingCubit: context.read<BookingCubit>()` — read from context (BookingCubit already provided above SlotList in the tree; confirmed by existing `_showBookingSheet` usage on line 62)
- `isFuture: true` — for slots being shown in the schedule, all are by definition upcoming

**Note on hardcoded colors inside ClientBookingDetailSheet (do not fix in Phase 24):**
- Line 32: `Color(0xFFD4860A)` (pending status color)
- Line 124: `Color(0xFFC62828)` (cancel button fill)
- Line 231: `Color(0xFFD0CAC0)` (drag handle)
- Line 283: `Color(0xFFC62828)` (error text)
These are Phase 26 cleanup items — do not touch in Phase 24.

---

## 3. Task-by-Task Implementation Notes

### Task 1 — Wordmark Header (SCHED-06)

**File:** `lib/features/schedule/ui/schedule_screen.dart`

**Delete:** Lines 66–75 (`appBar: AppBar(...)` block including closing `),`).

**Add import** (line 7 or after existing imports):
```dart
import 'package:vida_ativa/core/theme/app_theme.dart';
```

**Add `_eyebrowDate` method** inside `_ScheduleScreenState` (before `build`):
```dart
String _eyebrowDate(DateTime day) {
  const abbrevDays = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];
  const abbrevMonths = ['JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'];
  final dayName = abbrevDays[day.weekday - 1];
  final monthName = abbrevMonths[day.month - 1];
  return '$dayName, ${day.day} $monthName';
}
```

**Modify `build` method:** Change `Scaffold(appBar: ..., body: Column([WeekHeader, DayChipRow, ...]))` to `Scaffold(body: Column([SafeArea(header), WeekHeader, SportDayStrip, ...]))`.

**Rename widget call:** `DayChipRow(` → `SportDayStrip(` (same props, same argument names).

**Eyebrow reactivity:** `_eyebrowDate(_selectedDay)` is called inside `build`, so it rebuilds automatically when `setState(() => _selectedDay = day)` is called by `_onDaySelected`. No additional wiring needed.

**Do NOT add `Scaffold(appBar: null)`** — omit the `appBar:` key entirely.

**Do NOT add a `Divider`** between header Row and WeekHeader.

---

### Task 2 — SportDayStrip (SCHED-04)

**File:** `lib/features/schedule/ui/day_chip_row.dart`

**Full rewrite.** The file is short (95 lines) — replace entirely.

**Retained from DayChipRow:**
- Same three constructor params (`weekStart`, `selectedDay`, `onDaySelected`)
- `_isSameDay` helper logic (can keep as-is)
- `today = DateTime.now()` computation in `build`
- `weekStart.add(Duration(days: i))` for day generation

**Removed:**
- `_dayAbbrev` list → replaced by `_abbrev` (uppercase)
- `SingleChildScrollView` → replaced by `Row(mainAxisAlignment: MainAxisAlignment.spaceBetween)`
- `ChoiceChip` → replaced by `GestureDetector + Column`
- 5px dot `Container` → removed entirely
- All raw hex colors and legacy AppTheme aliases

**Animation:** `AnimatedContainer` for the underline with `duration: Duration(milliseconds: 150)`. Width animates from 0 to 24 on selection — clean without requiring `AnimatedSwitcher`.

**isToday detection:** `DateTime.now()` is called once in `build` — performance acceptable for 7 columns.

---

### Task 3 — SlotHairlineRow (SCHED-05)

**File:** `lib/features/schedule/ui/slot_card.dart`

**Full rewrite.** 114 lines → approximately 120 lines (similar size, different content).

**Key implementation decision:** The `myBooking` path uses `IntrinsicHeight` — this is explicitly permitted by PITFALLS.md Pitfall 5 and 24-UI-SPEC.md section 6.3, because a user can have at most one `myBooking` row per day (single occurrence in list). The non-myBooking paths MUST NOT use `IntrinsicHeight`.

**Build method pattern — conditional per status:**
```dart
@override
Widget build(BuildContext context) {
  if (viewModel.status == SlotStatus.myBooking) {
    return _buildStripeRow();
  }
  return _buildPlainRow();
}
```

**`_buildPlainRow` — for available / booked / blocked:**
Wraps in `DecoratedBox` + `Opacity` + `InkWell` + `Padding` + content `Row`.
`InkWell.onTap` receives `onTap` (null for booked/blocked — disables tap automatically).

**`_buildStripeRow` — for myBooking:**
`DecoratedBox` + `InkWell(onTap: onDetailTap)` + `IntrinsicHeight` + outer `Row(crossAxisAlignment: CrossAxisAlignment.stretch)` + `Container(width: 3, color: AppTheme.orange)` + `Expanded(Padding + content Row)`.

**Stripe position:** Left edge of row, full height via `CrossAxisAlignment.stretch` inside `IntrinsicHeight`. The 16px horizontal padding inside `Padding` applies only to the content area, not the stripe — stripe touches the left edge of the screen.

**`intl` import:** Retain `import 'package:intl/intl.dart';` — needed for `_formatPrice`.

---

### Task 4 — SlotList integration (SCHED-04 / SCHED-05)

**File:** `lib/features/schedule/ui/slot_list.dart`

**Not a full rewrite** — targeted changes only.

**Change summary:**
1. Import line 8: widget class name changed from `SlotCard` to `SlotHairlineRow` (import path unchanged)
2. Add import for `ClientBookingDetailSheet`
3. `ListView.builder` padding: `EdgeInsets.symmetric(horizontal: 16, vertical: 8)` → `EdgeInsets.only(bottom: 16)`
4. Replace `SlotCard(viewModel: vm, onTap: ...)` with `SlotHairlineRow(viewModel: vm, index: index, onTap: ..., onDetailTap: ...)`
5. Add `_showDetailSheet` top-level function

**`_showBookingSheet` (lines 61–85) — NO CHANGES.** Pattern is correct. `_showDetailSheet` mirrors it structurally but reads `bookingCubit` from context instead of injecting into the sheet (ClientBookingDetailSheet takes bookingCubit as a constructor param).

**`SlotList` class stays `StatelessWidget`.** The `_showDetailSheet` is a top-level function (same pattern as `_showBookingSheet`), so no `State` needed.

---

## 4. Color Audit (raw hex in target files)

### schedule_screen.dart
| Line | Hex | Status |
|------|-----|--------|
| 71 | `Color(0xFFD4860A)` (sports icon color) | Deleted with AppBar block |

### day_chip_row.dart
| Line | Hex / Legacy Alias | Status |
|------|-------------------|--------|
| 54 | `AppTheme.brandAmber` | Deleted with ChoiceChip block |
| 55 | `Color(0xFF4A4A4A)` | Deleted with ChoiceChip block |
| 63 | `AppTheme.primaryGreen` | Deleted with ChoiceChip block |
| 64 | `Color(0xFFF0EDE8)` | Deleted with ChoiceChip block |
| 70 | `AppTheme.brandAmber.withValues(alpha: 0.5)` | Deleted with ChoiceChip block |
| 83 | `AppTheme.brandAmber` | Deleted with dot Container block |

All violations deleted by the full rewrite — no individual line-level fixes required.

### slot_card.dart
| Line | Hex / Legacy / Stdlib | Status |
|------|----------------------|--------|
| 63 | `Colors.grey` (available stripe color) | Deleted — stripe removed for available |
| 63 | `Colors.grey` (booked stripe) | Deleted — stripe removed for booked |
| 65 | `Color(0xFFE53935)` (blocked stripe) | Deleted — stripe removed for blocked |
| 84 | `AppTheme.primaryGreen` | Deleted — use `AppTheme.court` in new _statusLabelColor |
| 88–89 | `Colors.grey` / `Colors.grey[200]` | Deleted with _StatusLabel class |
| 111 | `Color(0xFFE53935)` | Deleted with _StatusLabel class |
| Raw `TextStyle` (lines 36, 42) | no fontFamily | Deleted — replaced by AppTheme helpers |

All violations deleted by the full rewrite.

### slot_list.dart
No raw hex violations. No changes to color handling.

### client_booking_detail_sheet.dart (read-only, not modified in Phase 24)
Raw hex violations exist (lines 32, 124, 231, 283) — documented but deferred to Phase 26.

---

## 5. Integration Contracts (constructor signatures)

### SportDayStrip (new — replaces DayChipRow)
```dart
class SportDayStrip extends StatelessWidget {
  final DateTime weekStart;       // start of the displayed week (Monday)
  final DateTime selectedDay;     // currently selected day
  final ValueChanged<DateTime> onDaySelected;  // called with full DateTime on tap
```
Call site in ScheduleScreen: `DayChipRow(` → `SportDayStrip(` — identical named arguments.

### SlotHairlineRow (new — replaces SlotCard)
```dart
class SlotHairlineRow extends StatelessWidget {
  final SlotViewModel viewModel;  // from SlotList.slots[index]
  final int index;                // from ListView.builder index parameter
  final VoidCallback? onTap;      // null for booked/blocked; _showBookingSheet for available
  final VoidCallback? onDetailTap; // null for all except myBooking; _showDetailSheet for myBooking
```

### ClientBookingDetailSheet (existing — read only)
```dart
const ClientBookingDetailSheet({
  super.key,
  required this.booking,          // BookingModel — from vm.booking!
  required this.bookingCubit,     // BookingCubit — from context.read<BookingCubit>()
  required this.isFuture,         // bool — hardcode true for schedule slots
});
```
**CRITICAL:** `isFuture` controls whether the Cancel button is shown. For schedule slots, all are future — use `true`.

### WeekHeader (existing — read only, unchanged)
```dart
const WeekHeader({
  super.key,
  required this.weekStart,        // DateTime — _weekStart from ScheduleScreen state
  this.onPreviousWeek,            // VoidCallback? — null disables arrow
  this.onNextWeek,                // VoidCallback? — null disables arrow
});
```

### SlotViewModel (existing — read only, unchanged)
```dart
class SlotViewModel extends Equatable {
  final SlotModel slot;           // slot.startTime (String), slot.price (double)
  final SlotStatus status;        // available | booked | myBooking | blocked
  final String dateString;        // "YYYY-MM-DD" — not used in SlotHairlineRow
  final String? bookerName;       // nullable — for booked label
  final BookingModel? booking;    // non-null only when status == myBooking
```

---

## 6. Risks and Pitfall Mitigations

### Risk 1 — `IntrinsicHeight` misused in non-myBooking rows (Pitfall 5)
**Risk:** Developer uses `IntrinsicHeight` for all rows to simplify code.
**Mitigation:** Two separate build paths (`_buildPlainRow` / `_buildStripeRow`) enforce that `IntrinsicHeight` is used only in the stripe path. The planner must state this explicitly in the task prompt.

### Risk 2 — Anton SizedBox height clip (Pitfall 8)
**Risk:** Anton 42px at height 0.92 → logical height ~38.6px. Any `SizedBox(height: < 40)` around the time Text clips the cap.
**Mitigation:** Do NOT constrain the time `Text` with a `SizedBox`. Row height is set by the tallest child (Anton 42px) + `Padding(vertical: 12)` = ~63px. Verify visually in staging.

### Risk 3 — `_selectedDay` state desync (Pitfall 4)
**Risk:** If `_onDaySelected` is not called on week navigation, the eyebrow date and SportDayStrip selected column diverge from the cubit.
**Mitigation:** Current `_goToPreviousWeek` / `_goToNextWeek` already call both `setState` and `cubit.selectDay()` — no change needed. The eyebrow uses `_selectedDay` directly from State, not from cubit, so it stays in sync automatically.

### Risk 4 — `ClientBookingDetailSheet` missing `bookingCubit` or `isFuture`
**Risk:** Developer calls `ClientBookingDetailSheet(booking: vm.booking!)` and omits required params → compile error or incorrect cancel button behavior.
**Mitigation:** Use the exact `_showDetailSheet` implementation documented in Task 4. All three required params must be passed.

### Risk 5 — Left stripe not touching screen edge
**Risk:** If `Padding(horizontal: 16)` is applied to the outer `DecoratedBox` instead of the content area, the stripe is inset 16px.
**Mitigation:** In `_buildStripeRow`, the `Container(width: 3)` must be a direct child of the outer `Row`, before `Expanded(Padding(...))`. The `Padding(horizontal: 16)` applies only to the content, not the stripe container.

### Risk 6 — `ListView.builder` horizontal padding retained
**Risk:** Keeping `EdgeInsets.symmetric(horizontal: 16)` on the ListView makes the hairline dividers (which use `DecoratedBox`) appear inset 16px from the screen edge.
**Mitigation:** Change ListView padding to `EdgeInsets.only(bottom: 16)`. Each `SlotHairlineRow` applies its own `Padding(horizontal: 16)` to the content — the hairline border and stripe span full width.

### Risk 7 — `AppTheme` not imported in `schedule_screen.dart`
**Risk:** `AppTheme.orange`, `AppTheme.paper`, `AppTheme.mono`, `AppTheme.display` will fail to resolve.
**Mitigation:** Add `import 'package:vida_ativa/core/theme/app_theme.dart';` as a new import. This import does not exist in the current file.

### Risk 8 — `_eyebrowDate` weekday indexing
**Risk:** `DateTime.weekday` returns 1 (Monday) through 7 (Sunday) in Dart. `abbrevDays[day.weekday - 1]` maps 1→'SEG', 7→'DOM'. This is correct. BUT: if the day is Sunday (weekday == 7), index is 6 → 'DOM'. Correct.
**Mitigation:** No action needed — indexing is correct as documented.

---

## Sources

All findings are [VERIFIED] by direct codebase read in this session.

| File | Lines Read | Verification |
|------|-----------|--------------|
| `lib/features/schedule/ui/schedule_screen.dart` | 1–101 | [VERIFIED: codebase read] |
| `lib/features/schedule/ui/day_chip_row.dart` | 1–95 | [VERIFIED: codebase read] |
| `lib/features/schedule/ui/slot_card.dart` | 1–114 | [VERIFIED: codebase read] |
| `lib/features/schedule/ui/slot_list.dart` | 1–85 | [VERIFIED: codebase read] |
| `lib/features/schedule/models/slot_view_model.dart` | 1–24 | [VERIFIED: codebase read] |
| `lib/features/booking/ui/client_booking_detail_sheet.dart` | 1–341 | [VERIFIED: codebase read] |
| `lib/features/schedule/ui/week_header.dart` | 1–64 | [VERIFIED: codebase read] |
| `lib/core/theme/app_theme.dart` | 1–224 | [VERIFIED: codebase read] |
| `.planning/phases/24-agenda-cliente/24-CONTEXT.md` | full | [VERIFIED: codebase read] |
| `.planning/phases/24-agenda-cliente/24-UI-SPEC.md` | full | [VERIFIED: codebase read] |
| `.planning/REQUIREMENTS.md` | full | [VERIFIED: codebase read] |
| `.planning/research/PITFALLS.md` | full | [VERIFIED: codebase read] |

No external web searches required — all findings from codebase inspection.

---

## Assumptions Log

All claims in this research are [VERIFIED] by direct codebase read. No [ASSUMED] claims.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | — | — | — |

**Table is empty.** All claims verified by reading source files in this session.

---

## Environment Availability

Step 2.6: SKIPPED — Phase 24 is purely code changes to existing Flutter widgets. No external dependencies, CLIs, databases, or services beyond the existing Flutter/Dart toolchain.

## Validation Architecture

Step 4: SKIPPED — no test infrastructure detected for this feature area, and no `nyquist_validation` configuration present in `.planning/config.json` was read (config shows only phase-op metadata). Phase 24 is a visual-only rewrite; validation is visual review in staging. The planner should include a manual UAT step: run app in staging, navigate to Agenda tab, verify all four slot states render correctly.

## Security Domain

Not applicable — Phase 24 contains no authentication, session management, access control, input validation, or cryptography concerns. It is a pure widget rewrite with no data handling.

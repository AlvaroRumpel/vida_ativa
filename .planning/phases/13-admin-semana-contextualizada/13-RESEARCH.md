# Phase 13: Admin Semana Contextualizada - Research

**Researched:** 2026-03-31
**Domain:** Flutter UI, State Management (BLoC), Modal Bottom Sheets, Week Navigation
**Confidence:** HIGH

## Summary

Phase 13 extends the admin booking management interface with week-aware context and enhanced booking detail visibility. The phase builds directly on existing patterns established in v1.0–v2.0 (BookingConfirmationSheet, AdminBookingCard, WeekHeader) without requiring new dependencies or architectural changes.

Two requirements drive implementation:
- **ADMN-10:** Week navigation with label and date-aware day chips in SlotManagementTab
- **ADMN-11:** Booking detail bottom sheet accessible from both BookingManagementTab and SlotManagementTab

The architecture mirrors the booking detail flow (Phase 4), reusing StatefulWidget pattern for local state (loading, error), BLoC state (AdminBookingCubit), and Material 3 design system tokens already in app_theme.dart and app_spacing.dart.

**Primary recommendation:** Implement AdminBookingDetailSheet as a new StatefulWidget following BookingConfirmationSheet pattern (padding, info rows, drag handle); add `_selectedWeekStart` state to SlotManagementTab; wrap AdminBookingCard with GestureDetector in BookingManagementTab; modify day chips to display date alongside day label.

---

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| ADMN-10 | Admin vê label da semana atual (ex: "31 mar – 6 abr") na aba Slots e pode navegar ← → entre semanas; day chips exibem data real (ex: "Seg 01") | WeekHeader component exists (lib/features/schedule/ui/week_header.dart) with `_weekLabel()` formatting; SlotManagementTab manages day selection state with `_selectedDayOfWeek`; day chip rendering at line 147–173 in slot_management_tab.dart |
| ADMN-11 | Admin pode tocar em qualquer reserva (aba Reservas ou aba Slots) e abrir bottomsheet com detalhe completo: nome do cliente, status, horário, preço, participantes + ações confirmar/recusar | AdminBookingDetailSheet (new) follows BookingConfirmationSheet pattern (padding 24px, info rows with icons, drag handle, status badge); AdminBookingCard already has `_statusColor()` and `_statusLabel()` logic reusable in detail sheet; AdminBookingCubit has `confirmBooking()` and `rejectBooking()` methods; BLoC state pattern established in admin_booking_state.dart |

---

## Standard Stack

### Core State Management
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_bloc | ^9.1.1 | State management (Cubit + Sealed states) | Phase 1–11 established as project pattern; Sealed class states for exhaustive switch expressions (guaranteed compile-time safety) |
| equatable | ^2.0.8 | Value equality for BLoC states | Required for BLoC state comparison; v1–v2 consistent usage |

### UI & Navigation
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter (Material 3) | 3.11.3+ | Component library and design system | ColorScheme.fromSeed, FilledButton, OutlinedButton, ChoiceChip, AlertDialog, showModalBottomSheet all native Material 3 |
| google_fonts | ^6.2.1 | Typography (Nunito family) | Consistent with Phase 12 rebrand; already in use throughout |
| intl | ^0.20.2 | Date/time formatting (`DateFormat`, `NumberFormat`) | Phase 3–11 established; `DateFormat('EEEE, d \'de\' MMMM', 'pt_BR')` pattern in BookingConfirmationSheet |

### Firestore & Auth
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| cloud_firestore | ^6.1.3 | Database reads/writes | confirmBooking/rejectBooking mutations |
| flutter_bloc | ^9.1.1 | AdminBookingCubit manages booking stream | selectDate() already filters by date string; new week navigation will update date selection |

### Installation
Already installed (pubspec.yaml confirmed). No new dependencies for Phase 13.

---

## Architecture Patterns

### Recommended Project Structure

```
lib/features/admin/
├── cubit/
│   ├── admin_booking_cubit.dart         (EXISTING — use selectDate + confirmBooking/rejectBooking)
│   └── admin_booking_state.dart         (EXISTING — AdminBookingLoaded holds bookings list)
├── ui/
│   ├── slot_management_tab.dart         (MODIFY — add week navigation, date chips)
│   ├── booking_management_tab.dart      (MODIFY — wrap AdminBookingCard with GestureDetector)
│   ├── admin_booking_card.dart          (EXISTING — reuse _statusColor/_statusLabel methods)
│   └── admin_booking_detail_sheet.dart  (NEW — bottom sheet with booking details + actions)
└── model/
    └── admin_booking_model.dart         (NOT NEEDED — use existing BookingModel)

lib/core/
├── models/
│   └── booking_model.dart               (EXISTING — use id, status, userDisplayName, startTime, price, participants fields)
└── theme/
    ├── app_theme.dart                   (EXISTING — primaryGreen, brandAmber colors defined)
    └── app_spacing.dart                 (EXISTING — spacing tokens xs/sm/md/lg/xl)
```

### Pattern 1: StatefulWidget with Local Error/Loading State

**What:** Booking detail sheet manages `_isSubmitting` and `_errorMessage` locally; does NOT emit cubit state during action. Keeps cubit state clean and allows sheet to stay open on error.

**When to use:** Modal sheets with temporary actions (confirm/reject) where you need to show loading spinners and error messages without affecting the main screen state.

**Example:**
```dart
class AdminBookingDetailSheet extends StatefulWidget {
  final BookingModel booking;
  final AdminBookingCubit adminBookingCubit;

  const AdminBookingDetailSheet({
    required this.booking,
    required this.adminBookingCubit,
  });

  @override
  State<AdminBookingDetailSheet> createState() =>
      _AdminBookingDetailSheetState();
}

class _AdminBookingDetailSheetState extends State<AdminBookingDetailSheet> {
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _handleConfirm() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await widget.adminBookingCubit.confirmBooking(widget.booking.id);
      if (mounted) Navigator.pop(context);
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Falha ao confirmar reserva. Tente novamente.';
        });
      }
    }
  }
  // ...
}
```

**Reference:** BookingConfirmationSheet (lines 26–89) — identical pattern used for booking creation.

### Pattern 2: Week State Management in Slot Tab

**What:** SlotManagementTab maintains `_selectedWeekStart` (DateTime) state to track current week. Navigation buttons update this state and trigger filtering of displayed day chips and slots.

**When to use:** Tabbed views with temporal filtering (week, month, date range).

**Implementation detail:** Unlike BookingManagementTab which calls `cubit.selectDate()` for single days, SlotManagementTab operates on week granularity:
- Week navigation updates `_selectedWeekStart`
- Day chips display dates from that week
- DayView shows only slots for the selected day within that week

**Code pattern:**
```dart
class _SlotDayViewState extends State<_SlotDayView> {
  late DateTime _selectedWeekStart;  // NEW: track week, not just day-of-week

  void _onPreviousWeek() {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _onNextWeek() {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7));
    });
  }

  // Day chips now calculate dates from _selectedWeekStart
  DateTime _getDateForDayOfWeek(int dayOfWeek) {
    return _selectedWeekStart.add(Duration(days: dayOfWeek - 1));
  }
}
```

**Initialization:** `_selectedWeekStart = _getMonday(DateTime.now())` at initState to start on current week's Monday.

### Pattern 3: Day Chip Date Display

**What:** ChoiceChip label changed from single line "Seg" to multi-line "Seg\n31" or structured RichText showing day + numeric date.

**When to use:** When chips need to display both categorical (day label) and contextual (numeric date) information.

**Example:**
```dart
ChoiceChip(
  label: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(_dayLabels[i], style: const TextStyle(fontSize: 12)),
      Text(
        _getDateForDayOfWeek(i + 1).day.toString(),
        style: const TextStyle(fontSize: 12),
      ),
    ],
  ),
  // ... rest of styling unchanged
)
```

**Alternative (RichText):**
```dart
RichText(
  text: TextSpan(
    children: [
      TextSpan(text: _dayLabels[i], style: ...),
      TextSpan(text: '\n${_getDateForDayOfWeek(i + 1).day}', style: ...),
    ],
  ),
)
```

**Reference:** UI-SPEC section 2 specifies "Seg\n31" format with 12px font size.

### Pattern 4: Bottom Sheet Gesture Integration

**What:** Wrapping AdminBookingCard in GestureDetector with `onTap` callback that calls `showModalBottomSheet()`.

**When to use:** Making existing card components interactive to open detail views.

**Example:**
```dart
GestureDetector(
  onTap: () => _showBookingDetailSheet(context, booking),
  child: AdminBookingCard(
    booking: booking,
    bookingCubit: cubit,
  ),
)

void _showBookingDetailSheet(BuildContext context, BookingModel booking) {
  final cubit = context.read<AdminBookingCubit>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => AdminBookingDetailSheet(
      booking: booking,
      adminBookingCubit: cubit,
    ),
  );
}
```

**Reference:** SlotFormSheet opening at line 102–106 in slot_management_tab.dart shows `isScrollControlled: true` pattern.

### Anti-Patterns to Avoid

- **Embedding confirm/reject buttons in AdminBookingCard itself:** Buttons should appear only in the detail sheet, not in the card list view. Card shows status badge only.
- **Using cubit state emission during sheet actions:** Emitting state inside the sheet closes it prematurely or hides error messages. Use local StatefulWidget state instead (Phase 4 pattern).
- **Calling cubit.selectDate() for week navigation:** selectDate() is day-granular (Firestore query on `date` string). Week navigation is UI-only state in _SlotDayViewState.
- **Hardcoding week label format:** Reuse WeekHeader._weekLabel() or mirror its logic to ensure consistency.
- **Infinite scroll or lazy-loading weeks:** Keep week navigation simple — store `_selectedWeekStart` and filter/display synchronously.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Week-aware date display | Custom week calculation | DateTime arithmetic + _weekLabel() from WeekHeader | Standard calendar math is subtle (off-by-one errors, month boundaries); WeekHeader proven in codebase |
| Modal bottom sheets | Alert dialogs (showDialog) for detailed forms | showModalBottomSheet with isScrollControlled: true | Bottom sheets are Material 3 standard for mobile detail views; allows scrolling, drag-to-dismiss, safe area insets |
| Booking action dialogs | Custom confirmation logic | Reuse AlertDialog pattern from AdminBookingCard._confirmAction() | Consistent wording ("Confirmar reserva?", "Deseja confirmar esta reserva?") across admin features |
| Status color mapping | Hardcoded color switcher | _statusColor() method from AdminBookingCard | Single source of truth prevents status color desync; already verified against Phase 5 design |
| Info row layout (icon + text) | Manual Row/Column nesting | _infoRow() helper from BookingConfirmationSheet | Proven spacing (icon container + 12px gap + text), icon size (16px), icon background color (#10 opacity green) |

**Key insight:** This phase is 90% UI composition from existing patterns. The cost of custom implementations (date bugs, inconsistent styling, broken state management) far exceeds reuse cost.

---

## Common Pitfalls

### Pitfall 1: Week Navigation Updates Week Header But Not Slot View

**What goes wrong:** User taps ← button, week label updates, but DayView still shows slots from the previous week because the filtered slots list wasn't updated.

**Why it happens:** Confusing UI state (`_selectedWeekStart`) with data state (cubit). The cubit still queries for the old date.

**How to avoid:** When `_selectedWeekStart` changes, don't emit cubit state. Instead, filter the existing slots list locally by day-of-week. Week is UI-only; cubit remains responsible for single-day queries.

**Warning signs:** Clicking ← updates header label but slots don't change; manually refreshing fixes it.

---

### Pitfall 2: Date Chips Show Wrong Dates Across Month Boundaries

**What goes wrong:** Week starting March 29 shows dates [29, 30, 31, 1, 2, 3, 4] with month label "31 mar–6 abr" but chips only show numeric dates [29, 30, 31, 1, 2, 3, 4], so user sees "4" and thinks it's April 4, but it's actually in the detail or displayed with wrong formatting.

**Why it happens:** Not calculating chip dates correctly from `_selectedWeekStart`. Using hardcoded `_refDate(dow)` instead of computing actual week dates.

**How to avoid:** Always compute chip date as `_selectedWeekStart.add(Duration(days: dayOfWeek - 1))`. Verify dates span exactly 7 days and cross month boundaries correctly.

**Warning signs:** Dates jump or skip days; navigating weeks causes chips to misalign.

---

### Pitfall 3: AdminBookingDetailSheet Emits Cubit State on Confirm/Reject

**What goes wrong:** Sheet calls `cubit.confirmBooking()`, cubit emits new state, BookingManagementTab rebuilds and list updates, but the sheet closes prematurely before success message is shown.

**Why it happens:** Not following the BookingConfirmationSheet pattern. Forgetting that `confirmBooking()` is a mutation (Firestore write) that doesn't emit state — the reactive subscription in cubit's `selectDate()` updates the UI.

**How to avoid:** In the sheet's state:
1. Set `_isSubmitting = true` locally
2. Call `cubit.confirmBooking()` — it's a Future<void>, not a cubit emit
3. Firestore write completes, cubit's stream subscription fires, parent (BookingManagementTab) rebuilds
4. Close the sheet with `Navigator.pop()`

Never check cubit.state in the sheet after an action.

**Warning signs:** Confirm button pressed, sheet closes, list doesn't update or updates slowly; errors disappear immediately instead of staying on sheet.

---

### Pitfall 4: Day Chips Overflow or Text Misaligned on Multi-Line

**What goes wrong:** "Seg\n31" text doesn't fit in chip; "31" renders outside chip bounds or overlaps with next chip. Or, on some devices, single-line text breaks awkwardly.

**Why it happens:** ChoiceChip's default label size is fixed-width or doesn't account for multi-line text. Using Column() in label changes chip size unpredictably.

**How to avoid:** 
- Test label in multiple scenarios: Monday (2 chars + 1 digit = "Seg\n1"), Friday (3 chars + 2 digits = "Sex\n31")
- Use Text with explicit fontSize: 12px (from UI-SPEC) and fixed height
- Add explicit SizedBox constraints if needed
- Verify horizontal padding between chips accommodates both scenarios

**Warning signs:** Text wraps oddly; some days' chips are taller than others; label truncates with "…".

---

### Pitfall 5: Gesture Detection on Slot Cards Conflicts with Slot Editing

**What goes wrong:** Tapping a slot in SlotManagementTab should open the detail sheet for any booking on that slot, but the existing `_AdminSlotTile.onTap` opens the slot edit form instead.

**Why it happens:** Phase 13 changes the intent of tapping a slot. Original design: tap slot → edit slot. New design: tap slot → see bookings on that slot.

**How to avoid:** UI-SPEC section 5 intentionally defers exact interaction flow. Implementation options:
1. **Long-press for slot edit, tap for booking detail:** Different gestures, no conflict
2. **Open a dialog listing bookings, then tap booking to see detail:** Extra step, clearer intent
3. **Replace slot edit flow with swipe/icon button:** Preserves tap for booking detail

Choose during `/gsd:plan-phase 13`. For now, be aware this is the decision point.

**Warning signs:** Can't edit slots anymore; tapping slot shows wrong detail; two dialogs open at once.

---

## Code Examples

Verified patterns from official sources and codebase:

### Week Label Formatting

```dart
// Source: lib/features/schedule/ui/week_header.dart lines 30–36
String _weekLabel(DateTime weekStart) {
  final weekEnd = weekStart.add(const Duration(days: 6));
  if (weekStart.month == weekEnd.month) {
    return 'Semana de ${weekStart.day}–${weekEnd.day} ${_months[weekEnd.month - 1]}';
  }
  return 'Semana de ${weekStart.day} ${_months[weekStart.month - 1]}–${weekEnd.day} ${_months[weekEnd.month - 1]}';
}
```

**Usage:** `Text(_weekLabel(_selectedWeekStart))` in SlotManagementTab above day chips.

---

### Status Color & Label Helpers

```dart
// Source: lib/features/admin/ui/admin_booking_card.dart lines 18–34
Color _statusColor(String status) {
  return switch (status) {
    'pending' => Colors.orange,
    'confirmed' => AppTheme.primaryGreen,
    'rejected' => Colors.red,
    _ => Colors.grey,
  };
}

String _statusLabel(String status) {
  return switch (status) {
    'pending' => 'Aguardando',
    'confirmed' => 'Confirmado',
    'rejected' => 'Recusado',
    _ => 'Cancelado',
  };
}
```

**Usage:** Directly reusable in AdminBookingDetailSheet for status badge rendering.

---

### Info Row Layout (Icon + Text)

```dart
// Source: lib/features/booking/ui/booking_confirmation_sheet.dart lines 73–88
Widget _infoRow(IconData icon, String text) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppTheme.primaryGreen),
      ),
      const SizedBox(width: 12),
      Text(text),
    ],
  );
}
```

**Usage in AdminBookingDetailSheet:**
```dart
_infoRow(Icons.person, booking.userDisplayName ?? 'Cliente'),
_infoRow(Icons.calendar_today, formattedDate),
_infoRow(Icons.access_time, booking.startTime ?? '—'),
_infoRow(Icons.attach_money, formattedPrice),
if (booking.participants != null && booking.participants!.isNotEmpty)
  _infoRow(Icons.group, booking.participants!),
```

---

### Booking Confirmation Dialog

```dart
// Source: lib/features/admin/ui/admin_booking_card.dart lines 36–58
Future<void> _confirmAction(BuildContext context) async {
  final cubit = bookingCubit;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirmar reserva?'),
      content: const Text('Deseja confirmar esta reserva?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Não'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Sim'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await cubit.confirmBooking(booking.id);
  }
}
```

**Usage:** Extract into shared helper or inline in AdminBookingDetailSheet state's confirm button handler.

---

### Bottom Sheet Launch Pattern

```dart
// Source: lib/features/admin/ui/slot_management_tab.dart lines 100–107
void _openSheet(BuildContext context, SlotModel? existing) {
  final cubit = context.read<AdminSlotCubit>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => SlotFormSheet(existing: existing, slotCubit: cubit),
  );
}
```

**Adapted for AdminBookingDetailSheet:**
```dart
void _showBookingDetailSheet(BuildContext context, BookingModel booking) {
  final cubit = context.read<AdminBookingCubit>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => AdminBookingDetailSheet(
      booking: booking,
      adminBookingCubit: cubit,
    ),
  );
}
```

---

### Cubit Method for Confirm/Reject

```dart
// Source: lib/features/admin/cubit/admin_booking_cubit.dart lines 61–73
Future<void> confirmBooking(String bookingId) async {
  await _firestore
      .collection('bookings')
      .doc(bookingId)
      .update({'status': 'confirmed'});
}

Future<void> rejectBooking(String bookingId) async {
  await _firestore
      .collection('bookings')
      .doc(bookingId)
      .update({'status': 'rejected'});
}
```

**Note:** These are mutations that don't emit state. The reactive stream subscription in `selectDate()` updates the UI when Firestore changes.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single-day booking views | Week-aware context with navigation | Phase 13 (new) | Admin now sees temporal continuity; easier to plan across days |
| Inline confirm/reject in card | Detail sheet with modal actions | Phase 13 (new) | Cleaner card layout; dedicated space for error messages and loading states |
| Alert dialog for details | Bottom sheet with scrollable content | Phase 13 (new) | Mobile-friendly; safe area insets respected; drag-to-dismiss expected on mobile |
| Custom week calculations | Reuse WeekHeader + DateTime arithmetic | Phase 13 (from existing) | Proven, tested, consistent across app |

**Deprecated/outdated:**
- Day-level granularity in booking admin — now week-aware (Phase 13)
- AlertDialog for booking actions in detail view — now in dedicated stateful sheet (Phase 13)

---

## Open Questions

1. **Exact slot card interaction flow (Pitfall 5)**
   - What we know: Tapping slot currently opens slot edit form; Phase 13 wants to show booking detail instead
   - What's unclear: Do we replace tap entirely, use long-press, or add a sub-dialog listing bookings?
   - Recommendation: Defer to planner (`/gsd:plan-phase 13`). UI-SPEC intentionally leaves this open. Document decision in PLAN.md.

2. **Week navigation boundary behavior**
   - What we know: WeekHeader has no disabled states for buttons; always enabled
   - What's unclear: Should navigation be blocked at current week or allow infinite past/future weeks?
   - Recommendation: No business constraint identified. Allow unlimited navigation; planner may add checks during implementation.

3. **Booking status transitions in slot detail**
   - What we know: AdminBookingCard shows confirm/reject buttons for pending bookings only
   - What's unclear: Should detail sheet follow same rule (buttons hidden for confirmed/rejected)?
   - Recommendation: Yes — UI-SPEC section 3 (Interaction States) confirms: "Confirmed/Rejected booking: Buttons hidden, detail view only"

---

## Validation Architecture

**Test Framework**
| Property | Value |
|----------|-------|
| Framework | flutter_test + bloc_test + mocktail |
| Config file | none — test/* directory structure used |
| Quick run command | `flutter test test/features/admin/ui/admin_booking_detail_sheet_test.dart` |
| Full suite command | `flutter test` |

**Phase Requirements → Test Map**

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|------------|
| ADMN-10 | Week label renders "31 mar–6 abr" format | widget | `flutter test test/features/admin/ui/slot_management_tab_test.dart --grep "week label"` | ❌ Wave 0 |
| ADMN-10 | Day chips display date alongside day label | widget | `flutter test test/features/admin/ui/slot_management_tab_test.dart --grep "day chip date"` | ❌ Wave 0 |
| ADMN-10 | Previous/Next week buttons update displayed week | widget | `flutter test test/features/admin/ui/slot_management_tab_test.dart --grep "week navigation"` | ❌ Wave 0 |
| ADMN-11 | Tapping booking card opens detail sheet | widget | `flutter test test/features/admin/ui/booking_management_tab_test.dart --grep "booking card tap"` | ❌ Wave 0 |
| ADMN-11 | Detail sheet shows client name, status, date, time, price, participants | widget | `flutter test test/features/admin/ui/admin_booking_detail_sheet_test.dart --grep "detail display"` | ❌ Wave 0 |
| ADMN-11 | Confirm button on pending booking shows dialog + calls cubit | widget | `flutter test test/features/admin/ui/admin_booking_detail_sheet_test.dart --grep "confirm action"` | ❌ Wave 0 |
| ADMN-11 | Reject button on pending booking shows dialog + calls cubit | widget | `flutter test test/features/admin/ui/admin_booking_detail_sheet_test.dart --grep "reject action"` | ❌ Wave 0 |
| ADMN-11 | Error message displays inline if confirm/reject fails | widget | `flutter test test/features/admin/ui/admin_booking_detail_sheet_test.dart --grep "error handling"` | ❌ Wave 0 |

**Sampling Rate**
- **Per task commit:** `flutter test test/features/admin/` (focused test run for modified feature)
- **Per wave merge:** `flutter test` (full suite)
- **Phase gate:** Full suite green before `/gsd:verify-work`

**Wave 0 Gaps**
- [ ] `test/features/admin/ui/admin_booking_detail_sheet_test.dart` — new component, covers ADMN-11 detail display, confirm/reject actions, error handling
- [ ] `test/features/admin/ui/slot_management_tab_test.dart` — extend existing file (if any) or create new, covers ADMN-10 week navigation and day chip date display
- [ ] `test/features/admin/ui/booking_management_tab_test.dart` — extend existing file (if any) or create new, covers ADMN-11 card tap to open detail sheet
- [ ] Existing AdminBookingCubit tests validate confirmBooking/rejectBooking (already exist? verify in Wave 1 planning)

**Note:** Per project memory (feedback_no_tests.md), do NOT generate unit tests for this phase — focus on widget tests validating UI behavior only.

---

## Sources

### Primary (HIGH confidence)
- **UI-SPEC (13-UI-SPEC.md):** Full design contract — copywriting, spacing, colors, interaction states, layout constraints
- **REQUIREMENTS.md:** ADMN-10 and ADMN-11 definitions
- **Codebase patterns:**
  - `lib/features/booking/ui/booking_confirmation_sheet.dart` — bottom sheet pattern, info rows, drag handle, loading state
  - `lib/features/admin/ui/admin_booking_card.dart` — status color/label methods, confirm/reject dialogs
  - `lib/features/schedule/ui/week_header.dart` — week label formatting, navigation button layout
  - `lib/features/admin/cubit/admin_booking_cubit.dart` — confirmBooking/rejectBooking methods, selectDate subscription pattern
  - `lib/core/theme/app_theme.dart` — color tokens (primaryGreen, brandAmber)
  - `lib/core/theme/app_spacing.dart` — spacing scale (xs/sm/md/lg/xl)

### Secondary (MEDIUM confidence)
- **STATE.md:** Phase decision history confirming v2.0 complete, v3.0 starting
- **ROADMAP.md:** Phase 13 dependencies and success criteria alignment

### Tertiary (LOW confidence)
- None — all critical findings verified against codebase or official UI-SPEC

---

## Metadata

**Confidence breakdown:**
- **Standard Stack:** HIGH — All libraries already in pubspec.yaml; no new dependencies required
- **Architecture:** HIGH — Patterns directly observed in Phase 4 (BookingConfirmationSheet), Phase 5 (AdminBookingCard), and schedule features
- **Pitfalls:** HIGH — Common issues inferred from existing pattern reuse and modal sheet complexity
- **Validation:** HIGH — Test framework (flutter_test + bloc_test + mocktail) confirmed in pubspec.yaml; existing test files show structure

**Research date:** 2026-03-31
**Valid until:** 2026-04-07 (7 days — Phase 13 is UI-only, unlikely to require architectural changes mid-phase)

---

*RESEARCH.md generated by /gsd:research-phase for Phase 13: Admin Semana Contextualizada*

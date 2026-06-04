---
phase: 27-admin-slots-reservas-usuarios
reviewed: 2026-06-04T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - lib/features/admin/ui/slot_management_tab.dart
  - lib/features/admin/ui/admin_booking_row.dart
  - lib/features/admin/ui/booking_management_tab.dart
  - lib/features/admin/ui/user_detail_sheet.dart
  - lib/features/admin/ui/users_management_tab.dart
findings:
  critical: 1
  warning: 3
  info: 3
  total: 7
status: issues_found
---

# Phase 27: Code Review Report

**Reviewed:** 2026-06-04T00:00:00Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Five admin UI files reviewed: slot management tab (day view + day selector), booking row widget, booking management tab, user detail sheet, and users management tab. The overall quality is good — consistent widget patterns, proper BLoC usage, and good `mounted` guards. Three issues of note: one critical stale-read race condition in `_openSheet`, one missing `mounted` guard after an `await` inside a `StatelessWidget`-hosted closure, one logic bug in the week-navigation that reads `_weekStart` before `setState` has propagated, and several quality/info items.

---

## Critical Issues

### CR-01: `_openSheet` reads Firestore with a deterministic doc ID that may silently miss active bookings

**File:** `lib/features/admin/ui/slot_management_tab.dart:343`

**Issue:** `_openSheet` constructs the booking doc ID as `BookingModel.generateId(existing.id, existing.date)` and does a single `doc().get()`. However `existing.date` on a `SlotModel` is the *template* date embedded in the slot, which may differ from the *actual booking date* shown in the UI (the admin-selected `_selectedDate`). If the slot's stored `date` field diverges from `_selectedDate` (e.g. recurring or copy-pasted slots), the lookup returns `snap.exists == false` and the sheet falls through to the slot-edit form instead of showing the booking detail. An admin tapping a clearly-booked row would silently get the slot-edit form, allowing them to mutate a slot that has an active booking.

Additionally, the Firestore query in `_loadBookingsForDay` already retrieves all bookings for the day and stores their `slotId`. The doc ID could be derived from that same result, eliminating the second Firestore round-trip entirely.

**Fix:** Derive the booking doc ID from `_selectedDate` (the date the admin is looking at), not from `existing.date`:
```dart
Future<void> _openSheet(SlotModel? existing) async {
  if (existing != null) {
    // Use _selectedDate, not existing.date, to match what was loaded in _loadBookingsForDay
    final dateStr = _toDateString(_selectedDate);
    final docId = BookingModel.generateId(existing.id, dateStr);
    final snap = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(docId)
        .get();
    if (!mounted) return;
    if (snap.exists) {
      final booking = BookingModel.fromFirestore(snap);
      await showModalBottomSheet( ... );
      if (mounted) _loadBookingsForDay();
      return;
    }
  }
  // ... slot form fallback
}
```

---

## Warnings

### WR-01: Stale `_weekStart` read in `_previousWeek` / `_nextWeek` — wrong date emitted

**File:** `lib/features/admin/ui/slot_management_tab.dart:80-95`

**Issue:** Both `_previousWeek` and `_nextWeek` call `setState` to update `_weekStart`, then *immediately* compute the new date to emit using the now-updated `_weekStart` field. In Dart, `setState`'s callback runs synchronously, so `_weekStart` is already updated when the `onDateChanged` line executes. This is actually correct today — but only by coincidence of synchronous execution. However, the comment "Keep same day-of-week in new week" is misleading and fragile.

More concretely: in `_nextWeek`, after `setState(() { _weekStart = _weekStart.add(days: 7); })`, the `_weekStart` is the **new** week start. `dayOffset` is computed from `widget.selectedDate.weekday - 1` (old date), then added to the **already-advanced** `_weekStart`. This is the intended behavior. But in `_previousWeek`, after `setState`, `_weekStart` has moved back by 7 days. The code then reads `widget.selectedDate.weekday - 1` (which is still the old week's day index) and adds it to the already-retreated `_weekStart`. The resulting date is correct, but this relies on `setState` mutating `_weekStart` synchronously before the next line — which is true but an easy footgun if this code is ever refactored.

**Fix:** Make the intent explicit by computing the new week start first, then updating state and emitting:
```dart
void _previousWeek() {
  final newWeekStart = _weekStart.subtract(const Duration(days: 7));
  setState(() => _weekStart = newWeekStart);
  final dayOffset = widget.selectedDate.weekday - 1;
  widget.onDateChanged(newWeekStart.add(Duration(days: dayOffset)));
}

void _nextWeek() {
  final newWeekStart = _weekStart.add(const Duration(days: 7));
  setState(() => _weekStart = newWeekStart);
  final dayOffset = widget.selectedDate.weekday - 1;
  widget.onDateChanged(newWeekStart.add(Duration(days: dayOffset)));
}
```

### WR-02: `context.mounted` not checked after `await showDialog` in `StatelessWidget` closures

**File:** `lib/features/admin/ui/booking_management_tab.dart:154,180`

**Issue:** The `onConfirm` and `onReject` callbacks defined in `_BookingManagementView.build` are async closures that `await showDialog<bool>`. After the await, the code checks `context.mounted` before calling `cubit.confirmBooking` / `cubit.rejectBooking`. However, `_BookingManagementView` is a `StatelessWidget` — `context.mounted` on a `StatelessWidget`'s build context is always `true` (stateless elements are never unmounted independently). The check provides no safety here. The real risk is that `cubit` was captured from `context.read<AdminBookingCubit>()` at the top of `build` — if the widget is disposed between the `await` and the cubit call, the captured `cubit` reference may be operating on a closed stream.

**Fix:** Capture a local `cubit` reference before the await (already done), and guard with a variable that is set if the booking was removed from the list while the dialog was open, or simply accept the current behavior as safe enough given the BLoC architecture. The safer pattern for async callbacks in `StatelessWidget` is to use a `StatefulWidget` and check `mounted`:
```dart
// Option A — convert _BookingManagementView to StatefulWidget and use mounted
// Option B — use a WeakReference or null-check the scaffold after await
// Minimum fix: remove the misleading context.mounted check and add a comment
if (confirmed == true) {
  // cubit is safe — captured before await, BLoC handles disposed state
  await cubit.confirmBooking(booking.id);
}
```

### WR-03: `_loadUsers` error is swallowed silently — user sees no feedback on failure

**File:** `lib/features/admin/ui/users_management_tab.dart:35-47`

**Issue:** `_loadUsers` does not have a `try/catch`. If the Firestore query fails (network error, permission denied), the exception propagates uncaught from the async method. Flutter will log it to the console but the user will remain stuck on the loading spinner (`_isLoading` will never be set back to `false`). This is a hang/deadlock from the user's perspective.

**Fix:**
```dart
Future<void> _loadUsers() async {
  setState(() => _isLoading = true);
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .orderBy('displayName')
        .get();
    final users = snapshot.docs.map((d) => UserModel.fromFirestore(d)).toList();
    if (!mounted) return;
    setState(() {
      _users = users;
      _onSearchChanged(_searchController.text);
      _isLoading = false;
    });
  } catch (e) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    // Optionally show snackbar: SnackHelper.error(context, 'Erro ao carregar usuários');
  }
}
```

---

## Info

### IN-01: Direct Firestore access in UI layer — bypasses BLoC/cubit pattern

**File:** `lib/features/admin/ui/slot_management_tab.dart:314-338`
**File:** `lib/features/admin/ui/user_detail_sheet.dart:120-123`

**Issue:** `_loadBookingsForDay` in `_SlotDayViewState` and the demote path in `_UserDetailSheetState._handleAction` call `FirebaseFirestore.instance` directly from the UI layer. This bypasses the BLoC/cubit architecture established elsewhere in the project, making this logic untestable and duplicating query logic that may already exist in cubits.

**Fix:** Move `_loadBookingsForDay` into `AdminBookingCubit` and expose a `loadForDate(DateTime)` method. For the demote action, add a `demoteUser(String uid)` method to `AuthCubit` mirroring the existing `promoteUser` — the comment on line 119 of `user_detail_sheet.dart` explicitly notes this gap.

### IN-02: `_loadBookingsForDay` does not filter by `status == 'expired'`

**File:** `lib/features/admin/ui/slot_management_tab.dart:324`

**Issue:** The status filter skips `cancelled`, `rejected`, and `refunded` but does NOT skip `expired`. An expired booking (Pix not paid in time) would still mark a slot as "booked" in the admin view, even though the slot is available again. This creates a misleading display.

**Fix:**
```dart
if (status == 'cancelled' || status == 'rejected' ||
    status == 'refunded' || status == 'expired') {
  continue;
}
```

### IN-03: Accented characters missing in UI strings (diacritics stripped)

**File:** `lib/features/admin/ui/booking_management_tab.dart:105-110`
**File:** `lib/features/admin/ui/users_management_tab.dart:84-85`

**Issue:** Several user-visible strings are missing proper Portuguese diacritics: "Confirmacao automatica" (line 105), "Reservas sao confirmadas automaticamente" (line 108), "Reservas aguardam aprovacao manual" (line 110), "Nenhum usuario cadastrado" (line 84), "Nenhum usuario encontrado" (line 85). Other strings in the same files use correct accents (e.g. "Ação não pode ser desfeita" on line 138). The inconsistency suggests these were accidentally stripped.

**Fix:** Restore accents:
- "Confirmação automática"
- "Reservas são confirmadas automaticamente"
- "Reservas aguardam aprovação manual"
- "Nenhum usuário cadastrado"
- "Nenhum usuário encontrado"

---

_Reviewed: 2026-06-04T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

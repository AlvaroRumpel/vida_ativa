---
phase: 20-infraestrutura-de-esporte
reviewed: 2026-05-20T00:00:00Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - lib/core/models/booking_model.dart
  - lib/features/admin/cubit/sport_config_cubit.dart
  - lib/features/admin/cubit/sport_config_state.dart
  - lib/features/admin/ui/admin_booking_card.dart
  - lib/features/admin/ui/admin_booking_detail_sheet.dart
  - lib/features/admin/ui/admin_screen.dart
  - lib/features/admin/ui/settings_tab.dart
  - lib/features/booking/cubit/booking_cubit.dart
  - lib/features/booking/ui/booking_confirmation_sheet.dart
  - lib/features/schedule/ui/slot_day_view.dart
  - lib/features/schedule/ui/slot_list.dart
findings:
  critical: 0
  warning: 5
  info: 3
  total: 8
status: issues_found
---

# Phase 20: Code Review Report

**Reviewed:** 2026-05-20T00:00:00Z
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

This phase introduces a sport infrastructure layer across the booking, admin, and schedule
features. The model changes are clean and backward-compatible. The `SportConfigCubit` stream
pattern is solid. Most issues found are in error-handling gaps, a race condition in config
loading, a missing mounted-check, and code duplication between the two booking-sheet entry
points.

---

## Warnings

### WR-01: Race condition — `_pixEnabled` unset when `bookSlot` called immediately

**File:** `lib/features/booking/cubit/booking_cubit.dart:29-46`

**Issue:** `_loadConfig()` is called in the constructor but is `async` and not awaited. If a
caller invokes `bookSlot` or reads `pixEnabled` before the two Firestore fetches complete,
`_pixEnabled` is still `false` and `_confirmationMode` is still `'manual'`. On slow networks
this is a real timing window that can produce the wrong `initialStatus` for a booking.

**Fix:** Guard the public API until config is ready, or expose a `configReady` future.
The simplest safe fix is to emit a loading state and keep the submit button disabled until
config resolves:

```dart
// Add a Completer
final _configReady = Completer<void>();

Future<void> _loadConfig() async {
  try {
    final results = await Future.wait([...]);
    // ... existing logic ...
    _configReady.complete();
  } catch (e) {
    _configReady.completeError(e);
  }
}

// In bookSlot, await config before proceeding
Future<void> bookSlot({...}) async {
  await _configReady.future; // ensures config is loaded
  // ... rest of method ...
}
```

---

### WR-02: `BookingConfirmationSheet` re-fetches config from Firestore independently

**File:** `lib/features/booking/ui/booking_confirmation_sheet.dart:51-61`

**Issue:** `_fetchConfirmationMode()` makes a direct Firestore read in the UI layer to
duplicate information that `BookingCubit` already fetches (via `_loadConfig()`). This creates
two sources of truth for `confirmationMode`. If the Firestore doc is updated at runtime the
cubit and the sheet can diverge. Additionally, when the fetch fails silently (bare `catch (_)`,
line 59), the UI defaults to `_requiresConfirmation = true`, but the cubit may already have
loaded `'automatic'` mode — so the warning banner shows incorrectly.

**Fix:** Expose `confirmationMode` from `BookingCubit` as a getter (similar to `pixEnabled`)
and remove the independent fetch from the sheet entirely:

```dart
// In BookingCubit
String get confirmationMode => _confirmationMode;

// In BookingConfirmationSheet.initState — remove _fetchConfirmationMode()
// Instead derive requiresConfirmation from the cubit passed in:
_requiresConfirmation = widget.bookingCubit.confirmationMode != 'automatic';
```

---

### WR-03: Missing `mounted` check after `await` in `AdminBookingCard`

**File:** `lib/features/admin/ui/admin_booking_card.dart:108-110`

**Issue:** In `_confirmAction`, after `await showDialog<bool>(...)` resolves (line 107),
the method calls `await cubit.confirmBooking(booking.id)` (line 109) without verifying that
the widget is still mounted. If the user closes the admin screen during the dialog, the
subsequent async Firestore write still fires but the originating widget is detached, causing
a potential use-after-dispose error in any downstream `setState` path.

The same pattern exists in `_rejectAction` (lines 132-134).

**Fix:**

```dart
Future<void> _confirmAction(BuildContext context) async {
  final cubit = bookingCubit;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(/* ... */),
  );
  if (!context.mounted) return; // add this guard
  if (confirmed == true) {
    await cubit.confirmBooking(booking.id);
  }
}
```

Apply the same guard in `_rejectAction`.

---

### WR-04: `cancelGroupFuture` does not filter by active statuses

**File:** `lib/features/booking/cubit/booking_cubit.dart:198-217`

**Issue:** The batch cancellation query fetches all bookings in the recurrence group on or
after `fromDateInclusive` without filtering by status. This means bookings that are already
`cancelled`, `rejected`, or `expired` will be written with `status: 'cancelled'` again,
generating unnecessary Firestore writes and polluting the `cancelledAt` timestamp. More
importantly, if a Pix booking in `pending_payment` state is included, it gets a direct
Firestore status update to `'cancelled'` instead of going through the `cancelPixPayment`
Cloud Function, leaving the Mercado Pago order alive.

**Fix:** Filter out already-terminal states in the query, and skip Pix pending-payment docs:

```dart
// Add status filter to the Firestore query
.where('status', whereIn: ['pending', 'confirmed', 'pending_payment'])

// Then in the batch loop, handle pix pending_payment separately
for (final doc in snap.docs) {
  final data = doc.data();
  if (data['paymentMethod'] == 'pix' && data['status'] == 'pending_payment') {
    // Cannot batch-cancel a live Pix order — skip or call CF individually
    continue;
  }
  batch.update(doc.reference, {
    'status': 'cancelled',
    'cancelledAt': Timestamp.fromDate(DateTime.now()),
  });
}
```

---

### WR-05: `_syncFromState` in `_SportsSectionState` ignores remote updates after first load

**File:** `lib/features/admin/ui/settings_tab.dart:228-233`

**Issue:** The `_initialized` flag causes `_syncFromState` to silently ignore all subsequent
`SportConfigLoaded` emissions after the first one. If another admin session saves a different
sports list while this tab is open, the local list never reflects the remote change. The user
then overwrites the newer server state with their stale local copy on save.

**Fix:** Either remove the `_initialized` guard (accepting that typing-in-progress will be
reset on remote updates), or track a "dirty" flag so unsaved local changes are preserved but
the guard does not block clean syncs:

```dart
bool _isDirty = false; // set to true when user adds/removes/reorders

void _syncFromState(List<String> stateSports) {
  if (!_initialized) {
    _localSports = List<String>.from(stateSports);
    _initialized = true;
  } else if (!_isDirty) {
    // Only sync again if user has not made local changes
    setState(() => _localSports = List<String>.from(stateSports));
  }
}

void _addSport() {
  _isDirty = true;
  // ... existing logic ...
}

Future<void> _save() async {
  // On successful save, clear dirty flag
  _isDirty = false;
  // ... existing logic ...
}
```

---

## Info

### IN-01: Duplicated Firestore sports fetch in two booking entry points

**File:** `lib/features/schedule/ui/slot_day_view.dart:123-131` and
`lib/features/schedule/ui/slot_list.dart:66-73`

**Issue:** Both `SlotDayView._showBookingSheet` and `SlotList._showBookingSheet` contain
identical code to fetch the sports config from Firestore before opening the booking sheet.
This is the same 8-line block copy-pasted. Any future change (e.g., caching, error handling)
must be applied twice.

**Fix:** Extract to a shared helper in a utility or repository class:

```dart
// e.g., lib/core/utils/sports_config_fetcher.dart
Future<List<String>> fetchSportsList(FirebaseFirestore firestore) async {
  final snap = await firestore.collection('config').doc('sports').get();
  return (snap.data()?['sports'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[];
}
```

---

### IN-02: Duplicated `_statusColor` / `_statusLabel` between card and detail sheet

**File:** `lib/features/admin/ui/admin_booking_card.dart:18-29` and
`lib/features/admin/ui/admin_booking_detail_sheet.dart:28-54`

**Issue:** Both widgets implement identical `_statusColor` and `_statusLabel` switch
expressions. The detail sheet adds `'refunded'` support that the card lacks — a subtle
divergence that will likely need to be kept in sync manually.

**Fix:** Extract to a shared `BookingStatusDisplay` utility class or a top-level function
in an `admin_booking_display.dart` file, used by both widgets.

---

### IN-03: `BookingModel.fromFirestore` will crash on malformed Firestore data

**File:** `lib/core/models/booking_model.dart:46-68`

**Issue:** Required fields (`slotId`, `date`, `userId`, `status`, `createdAt`) are cast
directly without null checks (e.g., `data['slotId'] as String`). If a document is missing
any of these fields (e.g., a manually written test document, a partially-written failed
transaction), the `as String` cast throws a `TypeError` at runtime rather than surfacing a
structured error.

**Fix:** Either validate presence explicitly or use a safe cast with a fallback:

```dart
slotId: (data['slotId'] as String?) ?? (throw FormatException('missing slotId in ${doc.id}')),
```

This converts silent crashes into catchable, loggable errors.

---

_Reviewed: 2026-05-20T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

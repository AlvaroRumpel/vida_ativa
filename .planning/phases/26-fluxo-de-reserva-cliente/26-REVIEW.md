---
phase: 26-fluxo-de-reserva-cliente
reviewed: 2026-05-28T10:15:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - lib/core/widgets/sport_btn.dart
  - lib/features/booking/ui/hairline_booking_row.dart
  - lib/features/booking/ui/booking_confirmation_sheet.dart
  - lib/features/booking/ui/my_bookings_screen.dart
findings:
  critical: 1
  warning: 6
  info: 4
  total: 11
status: issues_found
---

# Phase 26: Code Review Report

**Reviewed:** 2026-05-28
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Reviewed booking flow UI components. Sport button is clean. Hairline row and my bookings screen have correct logic. Main concerns in booking confirmation sheet: unsafe casts without type guards, weak error classification via string matching, and race condition in navigator flow. Overall structure sound, but need to address 1 critical issue and 6 warnings to prevent runtime crashes.

## Critical Issues

### CR-01: Unsafe AuthCubit State Cast Without Type Guard

**File:** `lib/features/booking/ui/booking_confirmation_sheet.dart:72, 118, 170`

**Issue:** Code casts AuthCubit state to AuthAuthenticated using `as` keyword without checking actual type first. If state is AuthInitial or AuthError, this throws CastError at runtime and crashes the app.

```dart
// Lines 72, 118, 170 — all vulnerable
final authState = context.read<AuthCubit>().state as AuthAuthenticated;
```

If user is not authenticated when opening confirmation sheet, cast fails immediately.

**Fix:**
Use safe pattern matching instead of `as` cast:

```dart
final authState = context.read<AuthCubit>().state;
if (authState is! AuthAuthenticated) {
  // Handle error — show dialog or pop sheet
  if (mounted) Navigator.pop(context);
  return;
}
// Now safe to use authState
```

Apply to all three methods: `_handleConfirmRecurring`, `_handlePayPix`, `_handlePayOnArrival`.

---

## Warnings

### WR-01: Empty Catch Block Silences Errors

**File:** `lib/features/booking/ui/booking_confirmation_sheet.dart:60`

**Issue:** Bare `catch (_)` with only comment suppresses all Firebase and network exceptions. Makes debugging harder and hides real problems.

```dart
} catch (_) {
  // keep default true
}
```

**Fix:** Add minimal logging or remove catch:

```dart
} catch (e) {
  debugPrint('Failed to fetch confirmation mode: $e');
  // keep default true
}
```

---

### WR-02: Fragile String-Based Error Classification

**File:** `lib/features/booking/ui/booking_confirmation_sheet.dart:140-148, 189-197`

**Issue:** Error handling uses `e.toString().contains('slot_already_booked')` to detect error types. This is fragile — if error message changes, logic breaks. Appears in both `_handlePayPix` and `_handlePayOnArrival`.

```dart
final str = e.toString();
final isExpected = str.contains('slot_already_booked') || str.contains('slot_already_passed');
```

Backend changes message format → client stops catching it → shows generic error to user.

**Fix:** Use custom exception types or error codes instead of string matching:

```dart
// Define in booking_cubit or models
class SlotAlreadyBookedException implements Exception {
  final String message;
  SlotAlreadyBookedException(this.message);
}

// In exception handler
} on SlotAlreadyBookedException {
  _errorMessage = 'Este horario acabou de ser reservado.';
} on SlotAlreadyPassedException {
  _errorMessage = 'Este horario ja passou.';
}
```

---

### WR-03: Race Condition in Navigator.pop() Before Mounted Check

**File:** `lib/features/booking/ui/booking_confirmation_sheet.dart:153-159`

**Issue:** Code checks `if (!mounted)` then navigates. But Navigator.pop is called before the final mounted check. If widget unmounts between lines 153-159, Navigator.pop throws "Navigator not found".

```dart
if (!mounted) return;
final rootNav = Navigator.of(context, rootNavigator: true);
Navigator.pop(context);  // ← Can fail if unmounted after line 153
WidgetsBinding.instance.addPostFrameCallback((_) {
  rootNav.push(...);
});
```

**Fix:** Perform all navigation ops after final mounted check:

```dart
if (!mounted) return;
final rootNav = Navigator.of(context, rootNavigator: true);
Navigator.pop(context);
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted) {  // Double-check before push
    rootNav.push(MaterialPageRoute(...));
  }
});
```

---

### WR-04: Potential Null Weekday Array Access

**File:** `lib/features/booking/ui/hairline_booking_row.dart:81, my_bookings_screen.dart:83`

**Issue:** Code subtracts 1 from `date.weekday` to index into day abbreviation arrays. While Dart's `weekday` returns 1-7 (safe), if either DateTime.parse fails or booking.date is malformed, this can pass null or crash.

```dart
final dayAbbr = _dayAbbrevs[date.weekday - 1];
```

Currently protected by try-catch in callers, but not explicitly validated.

**Fix:** Add assertion or explicit validation:

```dart
assert(date.weekday >= 1 && date.weekday <= 7, 'Invalid weekday');
final dayAbbr = _dayAbbrevs[date.weekday - 1];
```

Or validate on input:
```dart
if (booking.date.isEmpty || DateTime.tryParse(booking.date) == null) {
  return SizedBox.shrink(); // Skip render
}
```

---

### WR-05: Unused bookingId Variable in _handlePayPix

**File:** `lib/features/booking/ui/booking_confirmation_sheet.dart:119`

**Issue:** `bookingId` is generated before `bookSlot()` call but only used after success. If exception occurs, bookingId is computed but wasted. Minor, but indicates potential refactoring.

```dart
final bookingId = BookingModel.generateId(...);
try {
  await widget.bookingCubit.bookSlot(...);  // Can throw
} on Exception catch (e, s) {
  // bookingId unused here
  ...
  return;
}
// bookingId used here after success
```

**Fix:** Move bookingId generation after successful bookSlot:

```dart
try {
  await widget.bookingCubit.bookSlot(...);
  if (!mounted) return;
  final bookingId = BookingModel.generateId(...);
  // Navigate with bookingId
} on Exception catch (e, s) {
  // Handle error
}
```

---

### WR-06: Inconsistent Null Handling in Sport Dropdown

**File:** `lib/features/booking/ui/booking_confirmation_sheet.dart:348-354`

**Issue:** Dropdown has explicit null option ("Não informado") but type is `String?`. No validation that `_selectedSport` is set before submission. User can submit with null sport if sports list is provided but they never select one.

```dart
DropdownButtonFormField<String?>(
  initialValue: _selectedSport,  // Starts as null
  items: [
    const DropdownMenuItem<String?>(value: null, child: Text('Não informado')),
    ...widget.sports.map((s) => DropdownMenuItem<String?>(value: s, child: Text(s))),
  ],
  onChanged: (v) => setState(() => _selectedSport = v),
),
```

If user never selects, `_selectedSport` remains null when passed to bookSlot.

**Fix:** Either make selection mandatory or explicitly allow null in downstream:

```dart
// Option 1: Make mandatory
DropdownButtonFormField<String>(
  initialValue: widget.sports.isNotEmpty ? widget.sports.first : '',
  items: widget.sports.map((s) => DropdownMenuItem<String>(value: s, child: Text(s))),
  onChanged: (v) => setState(() => _selectedSport = v),
  validator: (v) => (v == null || v.isEmpty) ? 'Select a sport' : null,
),

// Option 2: Document that null is allowed
sport: _selectedSport,  // OK to be null
```

---

## Info

### IN-01: Potential Page Rebuild Overhead

**File:** `lib/features/booking/ui/my_bookings_screen.dart:221-228, 234-240`

**Issue:** Each HairlineBookingRow calls `context.read<BookingCubit>()` separately. While not incorrect, this fetches cubit reference N times. In Flutter, prefer caching at parent level.

```dart
...remainingUpcoming.asMap().entries.map(
  (entry) => HairlineBookingRow(
    bookingCubit: context.read<BookingCubit>(),  // N times
    ...
  ),
),
```

**Fix:** Cache once at parent:

```dart
Widget _buildBookingsList(BuildContext context, List<BookingModel> bookings) {
  final bookingCubit = context.read<BookingCubit>();
  
  return ListView(
    children: [
      ...remainingUpcoming.asMap().entries.map(
        (entry) => HairlineBookingRow(
          bookingCubit: bookingCubit,  // Cached
          ...
        ),
      ),
    ],
  );
}
```

---

### IN-02: Magic Number in Array Indexing

**File:** `lib/features/booking/ui/hairline_booking_row.dart:31-33, my_bookings_screen.dart:83`

**Issue:** Day abbreviation arrays defined inline with magic array size 7. Better as constant.

```dart
static const _dayAbbrevs = [
  'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM',
];
```

No bug, but reduces readability. Could be moved to AppTheme or constants.

**Fix:** Extract to top-level constant or AppTheme:

```dart
// In app_theme.dart or constants.dart
static const dayAbbreviations = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];

// Usage
final dayAbbr = AppTheme.dayAbbreviations[date.weekday - 1];
```

---

### IN-03: Commented Intent in Empty Catch

**File:** `lib/features/booking/ui/booking_confirmation_sheet.dart:60-61`

**Issue:** Empty catch has comment `// keep default true`. While intent is clear, code doesn't enforce it. Better as explicit assignment.

```dart
} catch (_) {
  // keep default true
}
```

**Fix:** Remove or make explicit:

```dart
} catch (_) {
  _requiresConfirmation = true;  // Explicit, not implied by comment
}
```

---

### IN-04: Unused Import

**File:** `lib/features/booking/ui/booking_confirmation_sheet.dart:1`

**Issue:** Not found on review, but check imports for unused:

Common candidates: `cloud_firestore` (used), `intl` (used), `sentry_flutter` (used). All appear used. ✓

---

---

_Reviewed: 2026-05-28_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

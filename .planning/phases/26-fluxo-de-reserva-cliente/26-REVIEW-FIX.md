---
phase: 26-fluxo-de-reserva-cliente
fixed_at: 2026-06-04T00:00:00Z
review_path: .planning/phases/26-fluxo-de-reserva-cliente/26-REVIEW.md
iteration: 1
findings_in_scope: 7
fixed: 7
skipped: 0
status: all_fixed
---

# Phase 26: Code Review Fix Report

**Fixed at:** 2026-06-04
**Source review:** .planning/phases/26-fluxo-de-reserva-cliente/26-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 7
- Fixed: 7
- Skipped: 0

## Fixed Issues

### CR-01: Unsafe AuthCubit State Cast Without Type Guard

**Files modified:** `lib/features/booking/ui/booking_confirmation_sheet.dart`
**Commit:** c29e826
**Applied fix:** Replaced all three `as AuthAuthenticated` casts in `_handleConfirmRecurring`, `_handlePayPix`, and `_handlePayOnArrival` with `is!` type guard pattern. If state is not `AuthAuthenticated`, sheet pops and returns early — no CastError possible.

---

### WR-01: Empty Catch Block Silences Errors

**Files modified:** `lib/features/booking/ui/booking_confirmation_sheet.dart`
**Commit:** c29e826
**Applied fix:** Changed `catch (_)` to `catch (e)` and added `debugPrint('Failed to fetch confirmation mode: $e')` so Firebase/network failures are visible in development logs while still defaulting `_requiresConfirmation` to true.

---

### WR-02: Fragile String-Based Error Classification

**Files modified:** `lib/features/booking/ui/booking_confirmation_sheet.dart`
**Commit:** c29e826
**Applied fix:** Extracted two private helpers — `_classifyBookingError(String)` returning the user-facing message, and `_isExpectedBookingError(String)` for the Sentry guard. All inline string matching in `_handlePayPix` and `_handlePayOnArrival` now delegates to these helpers. Only one place needs updating if backend error codes change.

---

### WR-03: Race Condition in Navigator.pop() Before Mounted Check

**Files modified:** `lib/features/booking/ui/booking_confirmation_sheet.dart`
**Commit:** c29e826
**Applied fix:** Added `if (mounted)` check inside the `addPostFrameCallback` closure in `_handlePayPix` so `rootNav.push` is only called if widget is still mounted at callback time.

---

### WR-04: Potential Null Weekday Array Access

**Files modified:** `lib/features/booking/ui/hairline_booking_row.dart`, `lib/features/booking/ui/my_bookings_screen.dart`
**Commit:** 30f2af7
**Applied fix:** In `hairline_booking_row.dart` replaced `DateTime.parse` with `DateTime.tryParse`; returns `SizedBox.shrink()` if date is null. In `my_bookings_screen.dart` `_heroEyebrow` replaced `DateTime.parse` with `DateTime.tryParse`; returns `'PRÓXIMO'` fallback if date is null/malformed.

---

### WR-05: Unused bookingId Variable in _handlePayPix

**Files modified:** `lib/features/booking/ui/booking_confirmation_sheet.dart`
**Commit:** c29e826
**Applied fix:** Moved `BookingModel.generateId(...)` call to after the successful `bookSlot` await (after the `if (!mounted) return` guard), so it is never computed on the exception path.

---

### WR-06: Inconsistent Null Handling in Sport Dropdown

**Files modified:** `lib/features/booking/ui/booking_confirmation_sheet.dart`
**Commit:** c29e826
**Applied fix:** Applied Option 2 from review — added explicit comment documenting that null sport is intentional ("Não informado" is a valid user choice passed as-is to `bookSlot`; downstream accepts null). No structural change needed as the design intentionally allows unspecified sport.

---

_Fixed: 2026-06-04_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_

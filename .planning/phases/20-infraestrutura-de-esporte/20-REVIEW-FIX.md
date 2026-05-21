---
phase: 20-infraestrutura-de-esporte
fixed_at: 2026-05-20T00:00:00Z
review_path: .planning/phases/20-infraestrutura-de-esporte/20-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 20: Code Review Fix Report

**Fixed at:** 2026-05-20T00:00:00Z
**Source review:** .planning/phases/20-infraestrutura-de-esporte/20-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 5
- Fixed: 5
- Skipped: 0

## Fixed Issues

### WR-01: Race condition — `_pixEnabled` unset when `bookSlot` called immediately

**Files modified:** `lib/features/booking/cubit/booking_cubit.dart`
**Commit:** b928a71
**Applied fix:** Added `final _configReady = Completer<void>();` field. Wrapped `_loadConfig()` body in try/catch that calls `_configReady.complete()` on success and `_configReady.completeError(e)` on failure. Added `await _configReady.future;` as the first statement in `bookSlot()` to ensure config is loaded before any booking proceeds. Also exposed `String get confirmationMode => _confirmationMode;` getter (needed for WR-02).

---

### WR-02: `BookingConfirmationSheet` re-fetches config from Firestore independently

**Files modified:** `lib/features/booking/ui/booking_confirmation_sheet.dart`
**Commit:** dac66c3
**Applied fix:** Removed `_fetchConfirmationMode()` method and its `initState` call entirely. Changed `_requiresConfirmation` from `bool _requiresConfirmation = true` to `late bool _requiresConfirmation` initialized in `initState` via `widget.bookingCubit.confirmationMode != 'automatic'`. The `cloud_firestore` import was retained (still needed by `RecurrenceSection` on line 328).

---

### WR-03: Missing `mounted` check after `await` in `AdminBookingCard`

**Files modified:** `lib/features/admin/ui/admin_booking_card.dart`
**Commit:** 5d47d1a
**Applied fix:** Added `if (!context.mounted) return;` immediately after `await showDialog<bool>(...)` resolves in both `_confirmAction` (before the `confirmed == true` check) and `_rejectAction` (same pattern). Prevents use-after-dispose if the widget is detached while the dialog is open.

---

### WR-04: `cancelGroupFuture` does not filter by active statuses

**Files modified:** `lib/features/booking/cubit/booking_cubit.dart`
**Commit:** de314f6
**Applied fix:** Added `.where('status', whereIn: ['pending', 'confirmed', 'pending_payment'])` to the Firestore query to exclude already-terminal documents. Added a per-document guard inside the batch loop that skips (`continue`) any doc where `paymentMethod == 'pix'` and `status == 'pending_payment'`, since those require the `cancelPixPayment` Cloud Function rather than a direct Firestore write.

---

### WR-05: `_syncFromState` in `_SportsSectionState` ignores remote updates after first load

**Files modified:** `lib/features/admin/ui/settings_tab.dart`
**Commit:** 2721c1d
**Applied fix:** Added `bool _isDirty = false;` field. Updated `_syncFromState` to add an `else if (!_isDirty)` branch that syncs remote state when no unsaved local changes exist. Set `_isDirty = true` at the start of `_addSport`, `_removeSport`, and `_reorder` mutations. Reset `_isDirty = false` on successful save inside `_save`.

---

_Fixed: 2026-05-20T00:00:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_

---
phase: 05-admin
plan: "01"
subsystem: data-layer
tags: [cubit, firestore, booking, admin, bloc]
dependency_graph:
  requires: [04-booking]
  provides: [AdminSlotCubit, AdminBlockedDateCubit, AdminBookingCubit, BookingModel.isRejected, BookingModel.userDisplayName]
  affects: [booking_cubit, booking_card, booking_confirmation_sheet]
tech_stack:
  added: []
  patterns: [sealed-class-state, equatable, stream-subscription, local-sort]
key_files:
  created:
    - lib/features/admin/cubit/admin_slot_cubit.dart
    - lib/features/admin/cubit/admin_slot_state.dart
    - lib/features/admin/cubit/admin_blocked_date_cubit.dart
    - lib/features/admin/cubit/admin_blocked_date_state.dart
    - lib/features/admin/cubit/admin_booking_cubit.dart
    - lib/features/admin/cubit/admin_booking_state.dart
  modified:
    - lib/core/models/booking_model.dart
    - lib/features/booking/ui/booking_card.dart
    - lib/features/booking/cubit/booking_cubit.dart
    - lib/features/booking/ui/booking_confirmation_sheet.dart
decisions:
  - "AdminBookingCubit.selectDate cancels previous StreamSubscription before starting new date stream — avoids duplicate emissions"
  - "AdminBookingCubit._loadConfig called in constructor before selectDate — confirmationMode always set before first stream emission"
  - "setConfirmationMode re-emits current state with updated mode so UI reflects toggle immediately without waiting for stream"
  - "bookSlot reads /config/booking before transaction — defaults to 'manual' when doc absent (safest for admin control)"
metrics:
  duration_seconds: 338
  completed_date: "2026-03-20"
  tasks_completed: 2
  files_created: 6
  files_modified: 4
---

# Phase 05 Plan 01: Admin Data Layer Summary

**One-liner:** Extended BookingModel with rejected status and userDisplayName, and created three admin cubits (slot CRUD, blocked date management, booking confirmation/rejection) backed by Firestore streams.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Extend BookingModel, BookingCard, BookingCubit | 537e40c | booking_model.dart, booking_card.dart, booking_cubit.dart, booking_confirmation_sheet.dart |
| 2 | Create AdminSlotCubit, AdminBlockedDateCubit, AdminBookingCubit | 7b4b0f2 | 6 new files under lib/features/admin/cubit/ |

## What Was Built

**BookingModel extensions:**
- `userDisplayName: String?` field — nullable for backward compatibility with existing bookings; stored at booking time for admin display without extra reads.
- `isRejected` getter — `status == 'rejected'`.
- `toFirestore()` conditionally writes `userDisplayName` (only if non-null).

**BookingCard:**
- Added `'rejected'` case to both `_statusColor` (red) and `_statusLabel` ('Recusado') switch expressions. All four statuses now handled explicitly.

**BookingCubit.bookSlot:**
- Reads `/config/booking` doc before transaction to determine `confirmationMode`.
- Derives `initialStatus` from mode (`'automatic'` → `'confirmed'`, else `'pending'`).
- Accepts `userDisplayName` parameter and passes it to `BookingModel` constructor.
- `BookingConfirmationSheet` reads `AuthCubit` state to supply `userDisplayName`.

**AdminSlotCubit:**
- Streams ALL slots (no `isActive` filter — admin sees all).
- Sorts by `dayOfWeek` then `startTime` locally.
- Provides `createSlot` (Firestore `.add()` — slots use auto-generated IDs), `updateSlot`, `setSlotActive`.

**AdminBlockedDateCubit:**
- Streams `blockedDates` collection, sorts by date string.
- Provides `blockDate` (`.doc(dateString).set()`) and `unblockDate` (`.delete()`).

**AdminBookingCubit:**
- Loads `confirmationMode` from `/config/booking` in constructor before first date selection.
- `selectDate(DateTime)` cancels previous subscription and starts new stream filtered by date string.
- Sorts bookings locally by `startTime` (no `.orderBy()` — avoids composite index).
- `AdminBookingLoaded` carries `confirmationMode` so UI can display/toggle the setting.
- `setConfirmationMode` writes to Firestore with `SetOptions(merge: true)` and immediately re-emits updated state.

## Decisions Made

- `AdminBookingCubit.selectDate` cancels the previous `StreamSubscription` before starting the new date stream — prevents duplicate emissions when switching dates.
- `_loadConfig()` is awaited in the constructor chain before `selectDate(DateTime.now())` — ensures `confirmationMode` is populated before the first stream emission.
- `setConfirmationMode` re-emits current state with the new mode immediately — UI toggle responds without waiting for a Firestore round-trip.
- `bookSlot` reads config before starting the transaction (not inside it) — Firestore transactions only support reads on refs passed to `tx.get()`.

## Deviations from Plan

None — plan executed exactly as written. One minor auto-fix: removed unused `_selectedDate` field from `AdminBookingCubit` (the field was listed in initial implementation but `selectDate` uses the `date` parameter directly via closure capture, making the field redundant and causing a lint warning).

## Self-Check: PASSED

- booking_model.dart: FOUND
- admin_slot_cubit.dart: FOUND
- admin_booking_cubit.dart: FOUND
- Commit 537e40c: FOUND
- Commit 7b4b0f2: FOUND

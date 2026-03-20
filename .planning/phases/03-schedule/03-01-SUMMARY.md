---
phase: 03-schedule
plan: "01"
subsystem: schedule/data-layer
tags: [cubit, firestore, streams, state-management]
dependency_graph:
  requires: [lib/core/models/slot_model.dart, lib/core/models/booking_model.dart, lib/core/models/blocked_date_model.dart, lib/features/auth/cubit/auth_cubit.dart]
  provides: [SlotViewModel, SlotStatus, ScheduleState hierarchy, ScheduleCubit]
  affects: [lib/features/schedule/ui/ (Plan 03-02)]
tech_stack:
  added: []
  patterns: [three-stream Firestore architecture, sealed state hierarchy, Equatable view model]
key_files:
  created:
    - lib/features/schedule/models/slot_view_model.dart
    - lib/features/schedule/cubit/schedule_state.dart
    - lib/features/schedule/cubit/schedule_cubit.dart
  modified: []
decisions:
  - "ScheduleCubit caches all three stream values and recomputes on each emission — only emits ScheduleLoaded when all three caches are non-null"
  - "Cancelled bookings excluded at Firestore query level (whereIn: ['pending','confirmed']) — never reaches _resolveStatus()"
  - "date.weekday used directly as dayOfWeek filter — no adjustment needed since both use 1=Mon..7=Sun"
metrics:
  duration: "~3 min"
  completed_date: "2026-03-20"
  tasks_completed: 2
  files_created: 3
  files_modified: 0
---

# Phase 3 Plan 1: Schedule Data Layer Summary

**One-liner:** Three-stream Firestore ScheduleCubit combining /slots, /bookings, and /blockedDates into sorted SlotViewModel list with per-user booking status.

## What Was Built

Created the complete data layer for the schedule feature — three Dart files that form the bridge between Firestore and the schedule UI (Plan 02).

**SlotViewModel** (`slot_view_model.dart`): Computed view object carrying a `SlotModel`, a `SlotStatus` (available / booked / myBooking / blocked), and the `dateString`. The UI reads only these — never raw Firestore data.

**ScheduleState hierarchy** (`schedule_state.dart`): Sealed state with `ScheduleInitial`, `ScheduleLoading`, `ScheduleLoaded` (slots list + selectedDate + isBlocked flag), and `ScheduleError`. Follows the same Equatable pattern as `AuthState`.

**ScheduleCubit** (`schedule_cubit.dart`): Core data logic.
- `selectDay(DateTime date)` cancels old subscriptions, resets all caches, emits `ScheduleLoading`, then opens three Firestore streams concurrently.
- `_recompute()` guards on all three caches being populated before emitting — prevents partial state flashes.
- Blocked dates short-circuit to `ScheduleLoaded(isBlocked: true, slots: [])`.
- `_resolveStatus()` marks `myBooking` when `booking.userId == currentUserId`, `booked` for others, `available` when no booking found.
- Output sorted by `slot.startTime` (lexicographic sort is correct for "HH:mm" strings).
- `close()` cancels all subscriptions.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create SlotViewModel and ScheduleState | d1ced33 | slot_view_model.dart, schedule_state.dart |
| 2 | Create ScheduleCubit with three-stream architecture | 85edb9a | schedule_cubit.dart |

## Decisions Made

1. **Cache-then-recompute pattern**: All three Firestore streams feed into a single `_recompute()` call. The guard `if (_cachedSlots == null || _cachedBookings == null)` ensures the cubit never emits partial data when streams first connect.

2. **Cancelled bookings excluded at query level**: The Firestore query uses `whereIn: ['pending', 'confirmed']` so cancelled bookings are never fetched. `_resolveStatus()` never sees them.

3. **No weekday adjustment**: `date.weekday` is used directly as the `dayOfWeek` filter because Dart and the `SlotModel` schema both use 1=Monday..7=Sunday.

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

- `lib/features/schedule/models/slot_view_model.dart` — EXISTS
- `lib/features/schedule/cubit/schedule_state.dart` — EXISTS
- `lib/features/schedule/cubit/schedule_cubit.dart` — EXISTS
- Commit d1ced33 — EXISTS
- Commit 85edb9a — EXISTS
- `flutter analyze lib/features/schedule/` — No issues found

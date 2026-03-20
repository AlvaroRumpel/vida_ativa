---
phase: 04-booking
plan: "01"
subsystem: booking-data-layer
tags: [cubit, firestore, transaction, booking, state-management]
dependency_graph:
  requires: [03-02-SUMMARY]
  provides: [BookingCubit, BookingState, BookingModel-extended]
  affects: [app_router, main, booking-ui]
tech_stack:
  added: []
  patterns: [sealed-state-classes, firestore-transaction, stream-subscription, bloc-provider-at-shell]
key_files:
  created:
    - lib/features/booking/cubit/booking_state.dart
    - lib/features/booking/cubit/booking_cubit.dart
  modified:
    - lib/core/models/booking_model.dart
    - lib/main.dart
    - lib/core/router/app_router.dart
decisions:
  - "BookingCubit queries without .orderBy() to avoid composite index — sorted locally in Dart"
  - "bookSlot and cancelBooking do not emit cubit state — reactive stream subscription handles UI updates"
  - "BookingCubit provided at StatefulShellRoute level so Schedule and Bookings tabs share the same instance"
metrics:
  duration: 4 min
  completed_date: "2026-03-20"
  tasks_completed: 2
  files_modified: 5
---

# Phase 04 Plan 01: BookingCubit Data Layer Summary

**One-liner:** Atomic booking via Firestore Transaction with deterministic ID, user bookings stream, and BookingCubit provided at shell level for cross-tab access.

## Tasks Completed

| # | Name | Commit | Files |
|---|------|--------|-------|
| 1 | Extend BookingModel, create BookingState and BookingCubit, fix Firestore persistence | 58e5d62 | booking_model.dart, main.dart, booking_state.dart, booking_cubit.dart |
| 2 | Wire BookingCubit at StatefulShellRoute level in app_router.dart | 3440932 | app_router.dart |

## What Was Built

**BookingModel extended** with two optional display fields — `startTime` (HH:mm string) and `price` (double). Both are stored at booking time so My Bookings can display them without re-fetching slot data. `fromFirestore` and `toFirestore` updated; fields included in `props`.

**BookingState sealed hierarchy** following the same pattern as ScheduleState: `BookingInitial`, `BookingLoading`, `BookingLoaded(List<BookingModel>)`, `BookingError(String)`.

**BookingCubit** with three capabilities:
- `_startStream()`: subscribes to `bookings` where `userId == _userId`, emits `BookingLoaded` on each update. No `.orderBy()` to avoid composite Firestore index requirement.
- `bookSlot()`: uses `runTransaction` with deterministic doc ID (`{slotId}_{date}`). Reads the document inside the transaction — if it exists and `!isCancelled`, throws `slot_already_booked`. Stores `startTime` and `price` in the new booking document. No state emitted; stream reacts reactively.
- `cancelBooking()`: updates `status` to `cancelled` and writes `cancelledAt` timestamp. No state emitted; stream reacts reactively.

**main.dart**: Firestore web persistence disabled via `kIsWeb` guard before `runApp`, resolving the known Phase 4 concern about transaction interactions with offline cache.

**app_router.dart**: `StatefulShellRoute.indexedStack` builder now wraps `AppShell` in `BlocProvider<BookingCubit>`, constructed with `AuthAuthenticated.user.uid`. Both Schedule (Tab 0) and Bookings (Tab 1) can now call `context.read<BookingCubit>()`.

## Decisions Made

1. **No `.orderBy()` on bookings query** — avoids requiring a composite Firestore index for `userId + createdAt`. Plan 02 UI sorts locally if needed.
2. **Stream-reactive write methods** — `bookSlot` and `cancelBooking` intentionally do not emit any cubit state. The active stream subscription detects the Firestore change and updates `BookingLoaded` automatically. This avoids stale state and double-rendering.
3. **Shell-level BlocProvider** — BookingCubit lives at the `StatefulShellRoute` level rather than per-route, so it is shared across tabs and survives tab switches without re-streaming.

## Deviations from Plan

None — plan executed exactly as written.

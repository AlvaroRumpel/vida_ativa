---
phase: 10-monitoramento-de-erros
plan: "02"
subsystem: error-monitoring
tags: [sentry, cubits, streams, error-handling]
dependency_graph:
  requires: [10-01]
  provides: [OPS-01]
  affects: [booking, schedule, admin]
tech_stack:
  added: []
  patterns:
    - "Stream onError two-argument lambda (e, s) with synchronous Sentry.captureException"
key_files:
  created: []
  modified:
    - lib/features/booking/cubit/booking_cubit.dart
    - lib/features/admin/cubit/admin_booking_cubit.dart
    - lib/features/schedule/cubit/schedule_cubit.dart
    - lib/features/admin/cubit/admin_slot_cubit.dart
    - lib/features/admin/cubit/admin_blocked_date_cubit.dart
decisions:
  - "onError lambdas are synchronous — captureException called without await (stream listener context, not async method)"
  - "Two-argument form (e, s) used for all onError callbacks to pass StackTrace to Sentry"
metrics:
  duration: "~5 min"
  completed_date: "2026-03-26"
  tasks_completed: 2
  files_modified: 5
---

# Phase 10 Plan 02: Sentry Stream Error Instrumentation Summary

Sentry.captureException added to all five remaining feature cubit stream onError callbacks, completing full error coverage across the app.

## What Was Built

All five feature cubits now report Firestore stream errors to Sentry before emitting their error state. The `onError` lambda signature was expanded from single-argument `(e)` to two-argument `(e, s)` in every case, passing the StackTrace to Sentry for richer diagnostics.

Files modified:

| File | onError callbacks instrumented |
|------|-------------------------------|
| `lib/features/booking/cubit/booking_cubit.dart` | 1 |
| `lib/features/admin/cubit/admin_booking_cubit.dart` | 1 |
| `lib/features/schedule/cubit/schedule_cubit.dart` | 3 |
| `lib/features/admin/cubit/admin_slot_cubit.dart` | 1 |
| `lib/features/admin/cubit/admin_blocked_date_cubit.dart` | 1 |

Total: 7 new `captureException` calls, bringing the app-wide total to 14 (7 from auth_cubit in Plan 01).

## Pattern Applied

```dart
// Before (all 5 cubits):
onError: (e) => emit(const SomeCubitError('Mensagem.')),

// After:
onError: (e, s) {
  Sentry.captureException(e, stackTrace: s);
  emit(const SomeCubitError('Mensagem.'));
},
```

Note: `captureException` is called without `await` because stream `onError` callbacks are synchronous (not async methods). This matches the plan's interface spec.

## Verification Results

- `flutter analyze lib/features/... --no-pub` on all 5 files: No issues found
- `flutter analyze lib/ --no-pub`: 1 pre-existing `info` warning (deprecated `value` in `slot_form_sheet.dart`), zero errors
- `grep -r "captureException" lib/`: 14 matches across 6 cubit files
- `grep -r "onError: (e)" lib/`: 0 matches — no single-argument onError lambdas remain

## Deviations from Plan

None — plan executed exactly as written.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1 | 578b644 | feat(10-02): BookingCubit and AdminBookingCubit stream onError |
| Task 2 | 28edd11 | feat(10-02): ScheduleCubit, AdminSlotCubit, AdminBlockedDateCubit stream onError |

## Self-Check: PASSED

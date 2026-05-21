---
phase: 21-backend-do-dashboard
plan: "03"
subsystem: admin-dashboard
tags:
  - firestore-rules
  - bloc-provider
  - admin
  - security
dependency_graph:
  requires:
    - 21-01-SUMMARY.md  # DashboardCubit + DashboardData created
    - 21-02-SUMMARY.md  # Cloud Functions onBookingStateChange + scheduledDailyAggregation
  provides:
    - BlocProvider<DashboardCubit> at AdminScreen root (D-15)
    - Firestore rule restricting /config/dashboard/periods/{period} to admin read + no client write (D-16)
  affects:
    - Phase 22 UI (can now access DashboardCubit via context.read/watch)
    - Firebase staging deploy (rules must be deployed — pending checkpoint)
tech_stack:
  added: []
  patterns:
    - BlocProvider wrapping Scaffold for child tab access
    - Specific Firestore rule before wildcard (Pitfall 5 / Pattern 5)
key_files:
  created: []
  modified:
    - lib/features/admin/ui/admin_screen.dart
    - firestore.rules
decisions:
  - BlocProvider<DashboardCubit> wraps the entire BlocProvider.value(_fcmCubit) so all tabs including future Dashboard tab can access DashboardCubit via context
  - /config/dashboard/periods/{period} rule placed BEFORE /config/{docId} wildcard so specific rule wins; write=false enforces that only Cloud Functions via admin SDK can write counters
metrics:
  duration: "~15 min"
  completed_date: "2026-05-21"
  tasks_completed: 2
  tasks_pending: 1
  files_modified: 2
---

# Phase 21 Plan 03: Wiring + Security Hardening Summary

**One-liner:** DashboardCubit provisioned at AdminScreen root via BlocProvider; Firestore rules lock /config/dashboard/periods to admin-read + no-client-write.

## Tasks Completed

| Task | Status | Commit | Description |
|------|--------|--------|-------------|
| Task 1: Provisionar DashboardCubit em AdminScreen | Done | 97dabb1 | Import + BlocProvider wrapping AdminScreen.build() |
| Task 2: Adicionar regra Firestore /config/dashboard/{period} | Done | c58beaf | Specific rules before wildcard, write=false |
| Task 3: Deploy staging + verificação manual | Pending checkpoint | — | Awaiting human verification |

## What Was Built

### Task 1 — DashboardCubit provisioned at AdminScreen

`lib/features/admin/ui/admin_screen.dart` now wraps its entire widget tree with `BlocProvider<DashboardCubit>`:

```dart
return BlocProvider(
  create: (_) => DashboardCubit(firestore: FirebaseFirestore.instance),
  child: BlocProvider.value(
    value: _fcmCubit,
    child: Scaffold(...)
  ),
);
```

Phase 22 Dashboard tab can now call `context.read<DashboardCubit>()` or `context.watch<DashboardCubit>()` from any widget inside AdminScreen.

### Task 2 — Firestore rule for /config/dashboard/periods

`firestore.rules` now has two specific rules positioned BEFORE the `/config/{docId}` wildcard:

```javascript
match /config/dashboard/periods/{period} {
  allow read: if isAdmin();
  allow write: if false; // Apenas Cloud Functions via admin SDK escrevem (D-16)
}

match /config/dashboard {
  allow read: if isAdmin();
  allow write: if false;
}

match /config/{docId} {      // wildcard — AFTER specific rules
  allow read: if isAuthenticated();
  allow write: if isAdmin();
}
```

Threats mitigated:
- **T-21-01 Tampering**: `write: if false` — client Flutter cannot corrupt counters
- **T-21-10 Information Disclosure**: `read: if isAdmin()` — non-admin cannot read revenue data
- **T-21-11 Privilege Escalation**: specific block positioned before wildcard (Pitfall 5)

## Deviations from Plan

### Auto-fixed Issues

**[Rule 3 - Blocking] Restored tracked-but-missing files in worktree**
- **Found during:** Task 1 verification (flutter analyze error)
- **Issue:** Worktree was reset to base commit 7e26e65 but several files tracked in git (dashboard_cubit.dart, dashboard_state.dart, dashboard_data.dart, sport_config_cubit.dart, sport_config_state.dart, planning docs) were missing from the working directory
- **Fix:** `git checkout HEAD -- <files>` to restore all tracked-but-deleted files
- **Files modified:** lib/features/admin/cubit/dashboard_cubit.dart, dashboard_state.dart, lib/core/models/dashboard_data.dart, and others
- **Commit:** Included in feat(21-03) Task 1 commit (97dabb1) as restored context

## Known Stubs

None. Tasks 1 and 2 are wiring/configuration changes with no placeholder data.

## Threat Flags

No new threat surface introduced. Existing threats T-21-01, T-21-10, T-21-11 mitigated by Task 2 rules.

## Checkpoint Pending

Task 3 requires manual staging verification:

1. `firebase deploy --only functions:onBookingStateChange,functions:scheduledDailyAggregation,firestore:rules --project vida-ativa-staging`
2. Create confirmed booking → verify counters in /config/dashboard/periods/week
3. Rules Playground: admin read = allowed, non-admin read = denied, write = denied
4. `firebase functions:shell` → `scheduledDailyAggregation()` → verify calculated fields
5. Cancel booking → verify decrements
6. User reports "approved"

## Self-Check: PASSED

- FOUND: lib/features/admin/ui/admin_screen.dart
- FOUND: firestore.rules
- FOUND commit: 97dabb1 (Task 1)
- FOUND commit: c58beaf (Task 2)

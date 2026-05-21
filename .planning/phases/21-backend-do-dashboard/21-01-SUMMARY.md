---
phase: 21-backend-do-dashboard
plan: 01
subsystem: dashboard
tags: [flutter, cubit, firestore, equatable, tdd]

# Dependency graph
requires:
  - phase: 20-infraestrutura-de-esporte
    provides: SportConfig pattern for cubit + StreamSubscription on /config/ collection
provides:
  - DashboardData immutable model with 22 fields (4 metadata + 8 counters + 10 calculated-nullable)
  - TopClientEntry and RevenueBySportEntry value objects with fromMap + Equatable
  - DashboardState sealed hierarchy: DashboardInitial, DashboardLoading, DashboardLoaded, DashboardError
  - DashboardCubit reading /config/dashboard/periods subcollection in real-time via StreamSubscription
affects:
  - 21-02 (Cloud Functions plan — DashboardData schema is the write target)
  - 22-ui-do-dashboard (UI plan — consumes DashboardLoaded state to render charts)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - StreamSubscription on Firestore QuerySnapshot (subcollection listener pattern)
    - DashboardData.fromMap with null-tolerant num casting for all fields
    - DashboardData.empty() factory for missing period fallback

key-files:
  created:
    - lib/core/models/dashboard_data.dart
    - lib/features/admin/cubit/dashboard_state.dart
    - lib/features/admin/cubit/dashboard_cubit.dart
    - test/core/models/dashboard_data_test.dart
    - test/features/admin/cubit/dashboard_cubit_test.dart
  modified: []

key-decisions:
  - "DashboardData uses nullable types for all calculated fields (occupancyRate, avgTicket, etc.) — allows first-deploy resilience before scheduledDailyAggregation runs"
  - "DashboardCubit uses StreamSubscription on QuerySnapshot (subcollection) rather than DocumentSnapshot — mirrors pricing_cubit pattern adapted for collection"
  - "DashboardData.empty(period) factory sets period string correctly so UI can identify missing periods"

patterns-established:
  - "Subcollection listener pattern: .collection('config').doc('dashboard').collection('periods').snapshots() with per-doc byId map"
  - "Fake chain for QuerySnapshot tests: _FakeFirestore → _FakeConfigColl → _FakeDashboardDoc → _FakePeriodsColl → StreamController"

requirements-completed: [DASH-01, DASH-02, DASH-03, DASH-04, DASH-09, DASH-10, DASH-11, DASH-12]

# Metrics
duration: 25min
completed: 2026-05-20
---

# Phase 21 Plan 01: Backend do Dashboard - Flutter Layer Summary

**DashboardData model (22 fields, null-tolerant fromMap) + DashboardCubit streaming /config/dashboard/periods subcollection with TDD RED-GREEN commits**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-05-20T22:00:00Z
- **Completed:** 2026-05-20T22:25:00Z
- **Tasks:** 2
- **Files modified:** 5 (3 production + 2 test)

## Accomplishments

- DashboardData model with 22 fields covering all schema fields from D-03: 4 metadata + 8 simple counters (always set) + 10 calculated fields (nullable — set only after scheduledDailyAggregation runs)
- TopClientEntry and RevenueBySportEntry as typed value objects with Equatable, handling null sport entries (DASH-12 "Não informado")
- DashboardCubit streaming /config/dashboard/periods subcollection in real-time, emitting DashboardLoaded(week, month, year) with empty fallbacks for missing periods, and DashboardError with Sentry capture on stream failure
- 18 tests green (12 model + 6 cubit), full suite 126 tests passing

## Task Commits

1. **Task 1 RED: Failing tests for DashboardData.fromMap** - `4e0ecc8` (test)
2. **Task 1 GREEN: DashboardData model** - `7a14575` (feat)
3. **Task 2 RED: Failing tests for DashboardCubit** - `1868421` (test)
4. **Task 2 GREEN: DashboardState + DashboardCubit** - `b197271` (feat)

## Files Created/Modified

- `lib/core/models/dashboard_data.dart` - DashboardData, TopClientEntry, RevenueBySportEntry with fromMap + empty factories
- `lib/features/admin/cubit/dashboard_state.dart` - DashboardInitial, DashboardLoading, DashboardLoaded, DashboardError states
- `lib/features/admin/cubit/dashboard_cubit.dart` - Cubit streaming /config/dashboard/periods subcollection
- `test/core/models/dashboard_data_test.dart` - 12 tests covering null/empty/partial/full parse + Equatable
- `test/features/admin/cubit/dashboard_cubit_test.dart` - 6 tests covering 3-period stream, missing period fallbacks, error handling, nullable resilience, close

## Decisions Made

- Used `abstract class DashboardState` (not `sealed`) to match existing pricing_state.dart pattern in the codebase
- DashboardCubit initial state is `DashboardLoading` (not `DashboardInitial`) — UI can immediately show a loading spinner without an empty state
- Fake chain for tests creates a stream controller in `_FakePeriodsColl` that can emit either snapshots or errors, matching the `QuerySnapshot<Map<String, dynamic>>` type signature

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- DashboardData model is ready to be the write target for Plan 21-02 (Cloud Functions onBookingStateChange + scheduledDailyAggregation)
- DashboardCubit is ready to be provisioned in AdminScreen for Plan 22 (UI)
- Firestore security rules for /config/dashboard still needed (Plan 21-03 or as part of 21-02)

---
*Phase: 21-backend-do-dashboard*
*Completed: 2026-05-20*

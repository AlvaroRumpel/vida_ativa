---
phase: 03-schedule
plan: 02
subsystem: ui
tags: [flutter, flutter_bloc, go_router, firestore, intl]

# Dependency graph
requires:
  - phase: 03-01
    provides: ScheduleCubit, ScheduleState, SlotViewModel, SlotStatus

provides:
  - ScheduleScreen StatefulWidget with week navigation and BlocBuilder
  - WeekHeader with chevron navigation and Portuguese week label
  - DayChipRow with 7 ChoiceChips in Portuguese (Seg..Dom)
  - SlotList with loading/empty/blocked/error state handling
  - SlotCard with colored left border per SlotStatus and R$ price formatting
  - SlotSkeleton with AnimationController fade animation
  - app_router.dart /home route wired to ScheduleCubit + ScheduleScreen

affects: [04-booking, 05-admin]

# Tech tracking
tech-stack:
  added: [intl: ^0.20.2 (NumberFormat.currency for R$ price formatting)]
  patterns:
    - BlocProvider at route level (GoRoute builder wraps BlocProvider + Screen)
    - Sealed class exhaustive pattern matching in SlotList switch expression
    - StatefulWidget owns week/day state; BlocBuilder owns slot list state

key-files:
  created:
    - lib/features/schedule/ui/schedule_screen.dart
    - lib/features/schedule/ui/week_header.dart
    - lib/features/schedule/ui/day_chip_row.dart
    - lib/features/schedule/ui/slot_list.dart
    - lib/features/schedule/ui/slot_card.dart
    - lib/features/schedule/ui/slot_skeleton.dart
  modified:
    - lib/core/router/app_router.dart
    - pubspec.yaml

key-decisions:
  - "intl added as direct dependency for NumberFormat.currency(locale: pt_BR) — was transitive only, not safe to use without explicit declaration"
  - "BlocProvider<ScheduleCubit> placed at /home GoRoute builder level — same pattern as Phase 2 auth screens"
  - "SlotList uses Dart sealed class exhaustive switch expression — compile-time exhaustiveness guarantee, no default case needed"

patterns-established:
  - "Route-level BlocProvider: GoRoute builder creates BlocProvider with cubit requiring context.read<AuthCubit>()"
  - "Skeleton loader: StatefulWidget with AnimationController, FadeTransition/AnimatedBuilder, repeat(reverse: true)"

requirements-completed: [SCHED-01, SCHED-02, SCHED-03]

# Metrics
duration: 3min
completed: 2026-03-19
---

# Phase 03 Plan 02: Schedule UI Summary

**Six Flutter widgets plus router wiring deliver the complete read-only schedule screen: weekly navigation, Portuguese day chips, colored-border slot cards with R$ pricing, skeleton loader, and empty/blocked state messages backed by live Firestore streams.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-19T19:59:49Z
- **Completed:** 2026-03-19T20:03:00Z
- **Tasks:** 2 auto + 1 auto-approved checkpoint
- **Files modified:** 8

## Accomplishments

- Created 6 schedule UI widgets covering all display states (loading, empty, blocked, error, slots)
- Wired ScheduleCubit into the GoRouter at the /home route, replacing the placeholder screen
- Added `intl` package for locale-correct Brazilian Real price formatting (R$ XX,XX)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create schedule UI widgets** - `f983f33` (feat)
2. **Task 2: Wire ScheduleCubit into app_router.dart** - `7e1f783` (feat)
3. **Task 3: Verify schedule screen** - auto-approved (checkpoint:human-verify, auto_advance=true)

## Files Created/Modified

- `lib/features/schedule/ui/schedule_screen.dart` - Root StatefulWidget with week state, BlocBuilder, and ScheduleCubit.selectDay calls
- `lib/features/schedule/ui/week_header.dart` - Week navigation row with chevron icons and Portuguese "Semana de X-Y Mon" label
- `lib/features/schedule/ui/day_chip_row.dart` - Horizontal scrollable row of 7 ChoiceChips (Seg, Ter, Qua, Qui, Sex, Sab, Dom)
- `lib/features/schedule/ui/slot_list.dart` - State switcher rendering skeleton/error/blocked/empty/list based on ScheduleState
- `lib/features/schedule/ui/slot_card.dart` - Card with 4px colored left border, startTime, R$ price, and _StatusLabel
- `lib/features/schedule/ui/slot_skeleton.dart` - 4 pulsing grey containers with AnimationController (900ms, repeat/reverse)
- `lib/core/router/app_router.dart` - /home route now provides BlocProvider<ScheduleCubit> wrapping ScheduleScreen
- `pubspec.yaml` - Added intl: ^0.20.2

## Decisions Made

- `intl` added as explicit direct dependency: it was transitive-only via Firebase packages, which is not a safe usage pattern — adding it directly prevents breakage if upstream removes it.
- BlocProvider placed inside the GoRoute builder: follows the same pattern established in Phase 2 for auth screens, keeps the cubit scoped to the route lifetime.
- SlotList uses exhaustive sealed-class switch expression: compile-time guarantee that all ScheduleState variants are handled, no runtime surprises from unhandled states.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added intl as explicit pubspec dependency**
- **Found during:** Task 1 (slot_card.dart creation)
- **Issue:** `package:intl/intl.dart` import failed — intl was only a transitive dependency, not declared in pubspec.yaml
- **Fix:** Added `intl: ^0.20.2` to pubspec.yaml dependencies and ran `flutter pub get`
- **Files modified:** pubspec.yaml, pubspec.lock
- **Verification:** `flutter analyze lib/features/schedule/ui/` reported no issues after fix
- **Committed in:** f983f33 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking dependency)
**Impact on plan:** Necessary for correctness — transitive-only intl usage is fragile. No scope creep.

## Issues Encountered

None beyond the intl dependency gap documented above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 04 (booking) can now build on the completed read-only schedule: SlotCard tap handlers, booking confirmation flow, and Firestore transaction writes are ready to be added.
- ScheduleScreen accepts new child widgets or navigation callbacks without structural changes.
- No blockers.

---
*Phase: 03-schedule*
*Completed: 2026-03-19*

## Self-Check: PASSED

- lib/features/schedule/ui/schedule_screen.dart: FOUND
- lib/features/schedule/ui/week_header.dart: FOUND
- lib/features/schedule/ui/day_chip_row.dart: FOUND
- lib/features/schedule/ui/slot_list.dart: FOUND
- lib/features/schedule/ui/slot_card.dart: FOUND
- lib/features/schedule/ui/slot_skeleton.dart: FOUND
- .planning/phases/03-schedule/03-02-SUMMARY.md: FOUND
- Commit f983f33: FOUND
- Commit 7e1f783: FOUND

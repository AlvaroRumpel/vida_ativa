---
phase: 11-melhorias-visuais
plan: 02
subsystem: ui
tags: [flutter, spacing-tokens, design-system, theming]

# Dependency graph
requires: []
provides:
  - AppSpacing token class (xs=4, sm=8, md=16, lg=24, xl=32)
  - All in-scope screens using AppSpacing constants instead of hardcoded literals
affects: [12-rebrand]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - AppSpacing class with private constructor and static const members (same pattern as AppTheme)
    - Import app_spacing.dart in any screen that uses EdgeInsets or SizedBox spacing

key-files:
  created:
    - lib/core/theme/app_spacing.dart
  modified:
    - lib/features/schedule/ui/slot_skeleton.dart
    - lib/features/booking/ui/my_bookings_screen.dart
    - lib/features/auth/ui/profile_screen.dart
    - lib/features/auth/ui/login_screen.dart
    - lib/features/auth/ui/register_screen.dart
    - lib/features/admin/ui/slot_management_tab.dart
    - lib/features/admin/ui/booking_management_tab.dart
    - lib/features/admin/ui/blocked_dates_tab.dart

key-decisions:
  - "AppSpacing file paths in plan were wrong (profile/ui, admin/*_tab.dart) — actual files are auth/ui/profile_screen.dart and admin/ui/*_management_tab.dart; applied tokens to actual files"
  - "users_management_tab.dart has only EdgeInsets.all(12) which is not on the token scale — no substitutions made, import not added"
  - "values 6, 12, 40 left as-is per plan rules (not on xs/sm/md/lg/xl scale)"

patterns-established:
  - "AppSpacing pattern: static const members, private constructor, class-level doc comment — matches AppTheme"
  - "Substitution rule: only replace 4/8/16/24/32 in EdgeInsets/SizedBox; leave BorderRadius, fontSize, Duration, component sizes unchanged"

requirements-completed: [UI-03]

# Metrics
duration: 6min
completed: 2026-03-26
---

# Phase 11 Plan 02: Spacing Tokens Summary

**AppSpacing token system (xs/sm/md/lg/xl) created and applied across 8 screen files, replacing hardcoded EdgeInsets and SizedBox literals with named constants**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-26T20:59:57Z
- **Completed:** 2026-03-26T21:06:00Z
- **Tasks:** 2
- **Files modified:** 9 (1 created, 8 modified)

## Accomplishments

- Created `lib/core/theme/app_spacing.dart` with xs=4, sm=8, md=16, lg=24, xl=32 constants following AppTheme pattern
- Applied AppSpacing tokens to 8 screens covering all on-scale literals (4, 8, 16, 24, 32)
- `flutter build web --no-pub` passes with no regressions; all 9 files pass `flutter analyze` clean

## Task Commits

1. **Task 1: Create AppSpacing token file** - `14dad18` (feat)
2. **Task 2: Apply AppSpacing tokens to all screens** - `b9f8478` (feat)

## Files Created/Modified

- `lib/core/theme/app_spacing.dart` — New spacing token class with 5 constants and private constructor
- `lib/features/schedule/ui/slot_skeleton.dart` — horizontal: 16 -> AppSpacing.md
- `lib/features/booking/ui/my_bookings_screen.dart` — horizontal: 16, vertical: 8/4 -> AppSpacing.md/sm/xs; SizedBox(height: 16) -> AppSpacing.md
- `lib/features/auth/ui/profile_screen.dart` — SizedBox heights and sheet padding -> AppSpacing tokens
- `lib/features/auth/ui/login_screen.dart` — horizontal: 24/vertical: 32 and SizedBox heights -> AppSpacing.lg/xl/md/sm
- `lib/features/auth/ui/register_screen.dart` — horizontal: 24/vertical: 32 and SizedBox heights -> AppSpacing.lg/xl/md
- `lib/features/admin/ui/slot_management_tab.dart` — EdgeInsets.all(8) -> AppSpacing.sm
- `lib/features/admin/ui/booking_management_tab.dart` — horizontal: 8/vertical: 4 and all(8) -> AppSpacing.sm/xs
- `lib/features/admin/ui/blocked_dates_tab.dart` — EdgeInsets.all(8) -> AppSpacing.sm

## Decisions Made

- `users_management_tab.dart` only uses `EdgeInsets.all(12)` — 12 is not on the token scale, so no substitutions were made and no import added. Analyzer would warn about unused import.
- Plan referenced non-existent paths (`lib/features/profile/ui/profile_screen.dart`, `lib/features/admin/ui/admin_*_tab.dart`) — actual files located and updated correctly.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected file paths from plan frontmatter**
- **Found during:** Task 2 (Apply AppSpacing tokens to all screens)
- **Issue:** Plan listed `lib/features/profile/ui/profile_screen.dart` and `lib/features/admin/ui/admin_slots_tab.dart` etc. — none of these paths exist. Actual files are `lib/features/auth/ui/profile_screen.dart` and `lib/features/admin/ui/slot_management_tab.dart` etc.
- **Fix:** Applied all token substitutions to the correct actual files
- **Files modified:** 8 screen files (as listed above)
- **Verification:** `flutter analyze` passes on all files, `flutter build web` succeeds
- **Committed in:** b9f8478 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (wrong file paths in plan)
**Impact on plan:** All token substitutions applied as intended. No scope creep. users_management_tab.dart correctly excluded (no on-scale literals).

## Issues Encountered

- A botched revert of a blank-line edit in login_screen.dart merged a comment with the following `TextField(` constructor, causing parse errors. Fixed immediately by restoring the newline between the comment and the widget.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- AppSpacing is ready for Phase 12 rebrand: changing xs/sm/md/lg/xl values in one file updates the entire app
- All in-scope screens are tokenized; any future screen additions should import and use AppSpacing

---
*Phase: 11-melhorias-visuais*
*Completed: 2026-03-26*

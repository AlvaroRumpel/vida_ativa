---
phase: 25-estrutura-admin
plan: 01
subsystem: ui
tags: [flutter, admin, arena-identity, tabbar, fcm, notification-banner]

requires:
  - phase: 24-agenda-cliente
    provides: Arena header pattern (schedule_screen.dart SafeArea + 2-line wordmark reference)
  - phase: 22-ui-do-dashboard
    provides: DashboardTab widget used in TabBarView

provides:
  - "AdminScreen with Arena Esportivo identity frame (no AppBar)"
  - "Inline 2-line header: VIDA ATIVA wordmark pill + PAINEL ADMIN eyebrow + 'cliente →' orange link"
  - "TabBar in body Column with UPPERCASE labels, orange underline indicator, lineHair divider"
  - "_NotificationBanner restyled to orange 2px left-stripe (no green background)"
  - "FCM foreground messages as inline body banner with 5s auto-dismiss Timer"

affects:
  - "25-02 and beyond — all future admin tab rewrites depend on this frame"
  - "Phase 27, 28, 29 (aba rewrites mentioned in plan objective)"

tech-stack:
  added: []
  patterns:
    - "Arena header: SafeArea > Padding > Column(2 rows) — wordmark Row + eyebrow Text"
    - "Orange 2px left-stripe banner: IntrinsicHeight > Row(Container(width:2) + Expanded content)"
    - "Inline FCM notification: _pendingMessage state + Timer auto-dismiss (5s) + cancel in dispose"

key-files:
  created: []
  modified:
    - lib/features/admin/ui/admin_screen.dart

key-decisions:
  - "Implemented Tasks 1 and 2 in a single file write (same file, sequential changes) — committed atomically as one feat commit"
  - "Arena header pattern copied from schedule_screen.dart (Phase 24) and adapted to 2-row admin layout"
  - "AdminFcmError banner (Colors.red) left unchanged per plan — out of scope for this phase"

patterns-established:
  - "Arena banner stripe: IntrinsicHeight + Row + Container(width: 2, color: AppTheme.orange) — use for all inline notification banners"
  - "FCM inline notification pattern: setState(_pendingMessage) + Timer cancel/reset + dispose cleanup"

requirements-completed: [ADMN-13, ADMN-14, ADMN-15]

duration: 20min
completed: 2026-05-27
---

# Phase 25 Plan 01: Estrutura Admin Summary

**AdminScreen rewritten with Arena Esportivo frame: AppBar removed, inline 2-line wordmark header, TabBar moved to body Column, both notification banners restyled to orange 2px left-stripe pattern**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-05-27T00:00:00Z
- **Completed:** 2026-05-27T00:20:00Z
- **Tasks:** 3 (Tasks 1+2 combined, Task 3 verification)
- **Files modified:** 1

## Accomplishments

- AppBar completely removed from AdminScreen; no appBar: param exists
- Inline 2-line header renders: VIDA (ink) + ATIVA (orange pill) wordmark on line 1 left, "cliente →" mono orange on line 1 right, "PAINEL ADMIN" mono concrete on line 2
- TabBar moved from AppBar.bottom into body Column with UPPERCASE tab labels and lineHair divider override
- _NotificationBanner restyled from green-background container to orange 2px left-stripe (IntrinsicHeight pattern)
- showSnackBar replaced with _buildInlineBanner() in body Column, auto-dismissing after 5 seconds via Timer
- flutter analyze (file-level) clean; flutter build web --release exit code 0

## Task Commits

Each task was committed atomically:

1. **Tasks 1+2: Arena frame — inline header, TabBar in body, orange-stripe banners** - `bb784b2` (feat)
2. **Task 3: Build verification** - no commit (verification-only task, no file changes)

**Plan metadata:** (docs commit follows with SUMMARY.md)

## Files Created/Modified

- `lib/features/admin/ui/admin_screen.dart` — Full rewrite: AppBar removed, SafeArea+Column body, 2-line Arena header, TabBar inline, orange-stripe banners, Timer-based FCM banner

## Decisions Made

- Tasks 1 and 2 implemented in a single write since they affect the same file sequentially — committed as one atomic feat commit covering both tasks
- Arena header adapted from Phase 24 schedule_screen.dart pattern (single Row → 2-row Column for admin eyebrow)
- AdminFcmError banner (Colors.red) preserved unchanged per plan spec (explicitly out of scope)

## Deviations from Plan

None — plan executed exactly as written. Tasks 1 and 2 were committed as a single atomic commit (same file, one logical change set) rather than two separate commits, which is a minor process simplification with no impact on correctness.

## Issues Encountered

None. flutter analyze reported 0 issues for admin_screen.dart. Full project analyze showed 54 pre-existing warnings in test files (unrelated to this phase). flutter build web --release succeeded in ~129s.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- AdminScreen Arena frame is complete and production-ready
- Phases 27-29 (individual tab rewrites) can now be built on top of this frame
- All 7 tab widgets remain unchanged — only the surrounding frame was modified
- No blockers

---
*Phase: 25-estrutura-admin*
*Completed: 2026-05-27*

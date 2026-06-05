---
phase: 28-admin-pre-os-ajustes
plan: "01"
subsystem: core-widgets
tags: [ui, widget, sport-btn, flutter]
dependency_graph:
  requires: []
  provides: [SportBtn.filledInk]
  affects: [lib/core/widgets/sport_btn.dart]
tech_stack:
  added: []
  patterns: [named-constructor-variant-enum, switch-expression-dispatch]
key_files:
  created: []
  modified:
    - lib/core/widgets/sport_btn.dart
decisions:
  - "Replace bool _filled with _SportBtnVariant enum to support three variants cleanly without ambiguous dual-bool state"
metrics:
  duration: "~3 min"
  completed: "2026-06-05T04:15:19Z"
  tasks_completed: 1
  tasks_total: 1
  files_modified: 1
---

# Phase 28 Plan 01: SportBtn.filledInk Variant Summary

**One-liner:** Added SportBtn.filledInk variant (ink bg + paper text) via _SportBtnVariant enum replacing the bool _filled field.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Add SportBtn.filledInk variant | 5b3c495 | lib/core/widgets/sport_btn.dart |

## What Was Built

Extended `SportBtn` with a third named constructor `SportBtn.filledInk`. The boolean `_filled` field was replaced with a `_SportBtnVariant` enum (`filled`, `outlined`, `filledInk`) and the build method now uses a switch expression to dispatch to the correct button widget. The new variant uses ink background, paper foreground, Anton 15px typography, StadiumBorder, and full-width 52px height — matching the other variants' spec.

Existing callers of `SportBtn.filled` and `SportBtn.outlined` are unaffected: same public constructor signatures, same visual output.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None — pure UI widget with no data access, network calls, or trust boundary changes.

## Self-Check: PASSED

- [x] lib/core/widgets/sport_btn.dart exists and modified
- [x] commit 5b3c495 exists
- [x] flutter analyze reports "No issues found!"
- [x] SportBtn.filledInk constructor present
- [x] backgroundColor: AppTheme.ink present
- [x] foregroundColor: AppTheme.paper present (2 matches: filled + filledInk)

---
phase: 23-design-system-navigationbar
plan: "01"
subsystem: design-system
tags: [fonts, google-fonts, asset-bundling, navigation-bar, theme]
dependency_graph:
  requires: []
  provides: [offline-font-bundle, nav-bar-hairline-border]
  affects: [lib/app_shell.dart, pubspec.yaml, assets/google_fonts/]
tech_stack:
  added: []
  patterns: [google_fonts asset auto-discovery, AppTheme token usage]
key_files:
  created:
    - assets/google_fonts/Anton-Regular.ttf
    - assets/google_fonts/Manrope[wght].ttf
    - assets/google_fonts/JetBrainsMono[wght].ttf
  modified:
    - pubspec.yaml
    - lib/app_shell.dart
key_decisions:
  - "Used google_fonts asset auto-discovery (no fonts: section in pubspec.yaml needed)"
  - "Downloaded variable fonts Manrope[wght].ttf and JetBrainsMono[wght].ttf as single files covering all weights"
  - "Changed AppTheme.line to AppTheme.lineHair on NavigationBar top border (NAV-02)"
metrics:
  duration: "15min"
  completed: "2026-05-25"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 5
requirements:
  - DS-02
  - NAV-01
  - NAV-02
---

# Phase 23 Plan 01: Font Asset Bundling + NavigationBar Border Fix Summary

**One-liner:** Bundle Anton-Regular.ttf, Manrope[wght].ttf, JetBrainsMono[wght].ttf offline and fix nav bar top border from AppTheme.line to AppTheme.lineHair (NAV-02).

## Tasks Completed

| # | Name | Commit | Files |
|---|------|--------|-------|
| 1 | Download font files + update pubspec.yaml | db56eb9 | assets/google_fonts/ (3 files), pubspec.yaml |
| 2 | Fix NavigationBar hairline border token | 95e10a3 | lib/app_shell.dart |

## What Was Built

### Task 1: Font Asset Bundling
- Created `assets/google_fonts/` directory
- Downloaded 3 Google Fonts .ttf files from GitHub google/fonts:
  - `Anton-Regular.ttf` (170 KB) — static weight 400
  - `Manrope[wght].ttf` (165 KB) — variable font covering weights 400/600/700
  - `JetBrainsMono[wght].ttf` (187 KB) — variable font covering weight 700
- Added `- assets/google_fonts/` to pubspec.yaml `flutter.assets` section
- google_fonts 6.2.1 auto-discovers files by filename — no `fonts:` section needed
- `flutter pub get` exits 0

### Task 2: NavigationBar Border Token Fix
- Changed `AppTheme.line` → `AppTheme.lineHair` on the `Container > BoxDecoration > Border(top:)` wrapping the `NavigationBar` in `lib/app_shell.dart` line 44
- `AppTheme.lineHair` (#EAE3CE) is the lighter hairline token; `AppTheme.line` (#D9D2BE) is the heavier divider token
- `flutter analyze --no-fatal-infos lib/app_shell.dart` exits 0 with no issues

## Verification

```
assets/google_fonts/Anton-Regular.ttf      170812 bytes  ✓
assets/google_fonts/JetBrainsMono[wght].ttf 187208 bytes  ✓
assets/google_fonts/Manrope[wght].ttf      165420 bytes  ✓
pubspec.yaml: - assets/google_fonts/        ✓
app_shell.dart: AppTheme.lineHair           ✓
flutter pub get: OK                         ✓
flutter analyze: No issues found            ✓
```

## Deviations from Plan

### Branch Reset Required
- **Found during:** Startup
- **Issue:** Worktree branch was at `f9acdac` (v5.0 milestone) instead of `fb68c1c` (phase 23 plans). Several .planning/ files and lib/core/theme/app_theme.dart were staged as deleted in the worktree.
- **Fix:** `git reset --soft fb68c1c` to move to correct base, then `git checkout HEAD -- .planning/phases/23-design-system-navigationbar/ lib/core/theme/app_theme.dart lib/app_shell.dart` to restore deleted files.
- **Impact:** No plan tasks affected — all task work done on correct base.

## Known Stubs

None. Font files are complete binary assets; pub spec entry is wired. No placeholder data flows to UI.

## Threat Flags

None. Font files are static public assets from github.com/google/fonts. No new network endpoints, auth paths, or trust boundary changes introduced.

## Self-Check: PASSED

- assets/google_fonts/Anton-Regular.ttf: FOUND
- assets/google_fonts/Manrope[wght].ttf: FOUND
- assets/google_fonts/JetBrainsMono[wght].ttf: FOUND
- pubspec.yaml contains assets/google_fonts/: FOUND
- app_shell.dart uses AppTheme.lineHair: FOUND
- Commit db56eb9: FOUND
- Commit 95e10a3: FOUND

# Technology Stack — v6.0 Arena Esportivo Design System

**Project:** vida_ativa — Flutter PWA
**Milestone:** v6.0 Arena Esportivo — Redesign Visual
**Researched:** 2026-05-23
**Focus:** Stack additions/changes for design system implementation only

---

## TL;DR

No new packages required. The design system is fully implementable with the existing stack.
`google_fonts ^6.2.1` already provides Anton, Manrope, and JetBrains Mono.
Flutter 3.41.9 (Dart 3.11.5) already has ThemeExtension, WidgetStateProperty, and all Material 3
component theme APIs needed. The existing `app_theme.dart` is already 70% complete — palette,
three font helpers, and all Material component themes are wired up.

---

## Current Stack (Relevant to Design System)

| Package | Version in pubspec | Status |
|---------|--------------------|--------|
| google_fonts | ^6.2.1 | Sufficient — Anton, Manrope, JetBrains Mono confirmed available |
| flutter_bloc | ^9.1.1 | No change — ThemeData lives in AppTheme static, not Bloc |
| fl_chart | ^1.2.0 | No change — chart styling done via direct Color params on data models |
| flutter_heatmap_calendar | ^1.0.5 | No change — color via `colorsets` Map param |

**Flutter SDK:** 3.41.9 (stable, 2026-04-29)
**Dart SDK:** 3.11.5
**pubspec SDK constraint:** `sdk: ^3.11.3`

---

## Font Availability Confirmation (HIGH confidence)

All three fonts confirmed available in google_fonts ^6.2.1:

| Font | google_fonts API | Weight Range | Notes |
|------|-----------------|--------------|-------|
| Anton | `GoogleFonts.anton(...)` | Regular 400 only | Display/heading only. Single weight is a design constraint, not a bug. |
| Manrope | `GoogleFonts.manrope(...)` | 200–800 (variable) | Full UI text. `w400`, `w600`, `w700` all available. |
| JetBrains Mono | `GoogleFonts.jetBrainsMono(...)` | Regular + Bold | Mono labels, eyebrows, prices. |

The existing `lib/core/theme/app_theme.dart` already calls all three correctly via the
`display()`, `ui()`, `mono()` static helpers and `GoogleFonts.manropeTextTheme()` as the base `textTheme`.

**Anton weight limitation:** Anton has only Regular (400). The design system uses Anton exclusively
at display sizes (26px–88px) where weight variation is irrelevant. No workaround needed.

---

## google_fonts Version Assessment

**Current in project:** ^6.2.1
**Latest on pub.dev:** 8.1.0 (published 2026-04-27)

Notable changes between 6.2.1 and 8.1.0:
- v7.0.0: 200+ new fonts added (Anton/Manrope/JBMono were already present in 6.x)
- v7.1.0: WOFF2/WOFF support on web for bundled assets (smaller bundle, faster load)
- v8.0.0: Fixed compressed format priority in asset manifest; 19 new fonts added
- v8.1.0: Custom HTTP client support

**Recommendation: Stay on ^6.2.1 for v6.0.** All three required fonts work. Upgrading during a
pure UI milestone introduces unnecessary risk. Bump to ^8.x in a separate infra commit post-launch.

**Known WASM issue (not currently relevant):** GitHub issue #159375 (Nov 2024) documents that
google_fonts assets fail to load in Flutter web WASM builds. The project uses JS web (not WASM),
so this is not a blocker. If WASM is ever enabled, fonts must be declared in `pubspec.yaml` assets
using the standard Flutter fonts API as a workaround, or bundled individually.

---

## Flutter API Readiness (Flutter 3.41.9)

### WidgetStateProperty — ALREADY CORRECT (HIGH confidence)

`WidgetStateProperty` and `WidgetState` are the current non-deprecated APIs since Flutter 3.19.
`MaterialStateProperty`/`MaterialState` are deprecated typedef aliases — they still compile but
should not be used in new code.

The existing `app_theme.dart` already uses the correct modern API:
- `WidgetStateProperty.resolveWith((states) { ... })`
- `WidgetStateProperty.all(...)`
- `states.contains(WidgetState.selected)`

No migration needed anywhere.

### ThemeExtension — NOT NEEDED FOR v6.0 (HIGH confidence)

ThemeExtension is the right pattern for multi-theme or dark-mode-capable design systems.
For v6.0, the project has a single fixed light theme with no dark mode in scope (dark mode is v7+).
The existing static const approach in AppTheme is simpler, already works, and requires no lerp/copyWith
boilerplate. ThemeExtension adds real value only when `Theme.of(context).extension<T>()` lookups are
needed across widget boundaries, or when animated theme transitions are required. Neither applies here.

**Decision: Keep static consts + static helper methods. Do not add ThemeExtension in v6.0.**

### Material 3 Component Theme APIs — ALL CURRENT (HIGH confidence)

Flutter 3.27 renamed several component theme classes to `*ThemeData` suffixes:
- `CardTheme` → `CardThemeData`
- `DialogTheme` → `DialogThemeData`
- `TabBarTheme` → `TabBarThemeData`

The existing `app_theme.dart` already uses `CardThemeData`, `TabBarThemeData`,
`NavigationBarThemeData`, `FilledButtonThemeData` — all correct for 3.41.9. No updates needed.

### ColorScheme — MANUAL SPEC IS CORRECT (HIGH confidence)

`AppTheme` uses the explicit `ColorScheme(brightness: ..., primary: ..., ...)` constructor rather
than `ColorScheme.fromSeed()`. This is correct for a fixed brand palette. `fromSeed()` generates
tonal palette variants algorithmically and would produce unwanted colors for a sport brand with
specific hex values. Do not change this.

---

## What AppTheme Already Has (Confirmed via Source Read)

Reading `lib/core/theme/app_theme.dart` confirms the following is already implemented and correct:

**Palette (DS-01):** `sand`, `paper`, `ink`, `inkSoft`, `concrete`, `line`, `lineHair`,
`orange`, `orangeDk`, `court`, `sun` — all defined as `static const Color`.

**Typography helpers (DS-02, DS-03):**
- `display(size, color, letterSpacing)` → Anton, height 0.92
- `ui(size, weight, color)` → Manrope
- `mono(size, weight, color, letterSpacing)` → JetBrains Mono

**Material theme (DS-04):** `colorScheme`, `textTheme` (Manrope base), `appBarTheme`,
`tabBarTheme` (underline orange 2px, JBMono labels), `navigationBarTheme` (WidgetStateProperty
for selected/idle), `dividerTheme`, `cardTheme` (zero elevation, hairline border),
`filledButtonTheme` (Anton, orange, StadiumBorder), `outlinedButtonTheme`, `textButtonTheme`,
`inputDecorationTheme` (underline, JBMono labels), `switchTheme`, `snackBarTheme`,
`floatingActionButtonTheme`, `progressIndicatorTheme`, `checkboxTheme`, `chipTheme`.

DS-01 through DS-04 are substantially pre-built. v6.0 work is applying this theme to widgets,
not rebuilding the theme foundation.

---

## Integration with Existing Libraries (Chart + Heatmap)

### fl_chart ^1.2.0
Chart colors are specified directly on data model constructors — not inherited from ThemeData:
- `BarChartRodData(color: AppTheme.orange, ...)`
- `PieChartSectionData(color: AppTheme.court, ...)`
- Axis labels: `titlesData: FlTitlesData(...)` with `TextStyle` from `AppTheme.mono()`

No chart-level theme wiring exists or is needed.

### flutter_heatmap_calendar ^1.0.5
For ADMN-28 (orange intensity heatmap replacing the default calendar color scheme):
```dart
HeatMap(
  colorsets: {
    1: AppTheme.orange.withValues(alpha: 0.15),
    2: AppTheme.orange.withValues(alpha: 0.35),
    3: AppTheme.orange.withValues(alpha: 0.60),
    4: AppTheme.orange,
  },
  ...
)
```
Use `withValues(alpha: x)` — the current non-deprecated API in Dart 3.x (replaces `withOpacity`).

---

## Packages to NOT Add

| Package | Why to Skip |
|---------|-------------|
| Any `theme_extensions` pub package | Flutter's built-in ThemeExtension API is sufficient; external packages add indirection |
| `flex_color_scheme` | Powerful but heavyweight; unnecessary for a fixed single-theme app |
| `token_theme_kit` | Design tokens are already static consts in AppTheme |
| `dynamic_color` | Material You dynamic color is not part of Arena Esportivo; brand colors are fixed |
| Any icon pack package | Material Icons used throughout; no iconography change specified in v6.0 |
| `widgetbook` | Dev tooling overhead not justified for a focused UI milestone |

---

## Confidence Assessment

| Area | Confidence | Basis |
|------|------------|-------|
| Font availability in ^6.2.1 | HIGH | Confirmed in running code: app_theme.dart calls all three successfully |
| WidgetStateProperty (no migration) | HIGH | Source code already uses correct API; Flutter docs confirm deprecation path |
| ThemeExtension not needed for v6.0 | HIGH | Single light theme, no dark mode in scope, static approach already works |
| google_fonts version stay on 6.2.1 | HIGH | All fonts present; no breaking changes between 6.x and 8.x for these fonts |
| WASM font loading issue | MEDIUM | Open GitHub issue; not relevant to current JS web build |
| fl_chart color integration | HIGH | API: direct Color params on data models, confirmed in pub.dev docs |
| flutter_heatmap_calendar colorsets | MEDIUM | API confirmed in pub.dev; `withValues` is correct modern Dart 3.x API |

---

## Sources

- google_fonts pub.dev: https://pub.dev/packages/google_fonts
- google_fonts changelog: https://pub.dev/packages/google_fonts/changelog
- Flutter docs — ThemeExtension: https://api.flutter.dev/flutter/material/ThemeExtension-class.html
- Flutter breaking changes — MaterialState → WidgetState: https://docs.flutter.dev/release/breaking-changes/material-state
- Flutter 3.27 release notes (CardThemeData, TabBarThemeData): https://docs.flutter.dev/release/release-notes/release-notes-3.27.0
- Flutter web WASM google_fonts issue #159375: https://github.com/flutter/flutter/issues/159375
- Anton on Google Fonts: https://fonts.google.com/specimen/Anton
- Very Good Ventures — Scalable Theming for Custom Widgets: https://www.verygood.ventures/blog/mastering-scalable-theming-for-custom-widgets

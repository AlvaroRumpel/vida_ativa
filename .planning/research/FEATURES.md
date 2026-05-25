# Feature Landscape — Flutter Design System (Arena Esportivo v6.0)

**Domain:** Flutter design system implementation on existing Material 3 PWA
**Milestone:** v6.0 — Redesign Visual
**Researched:** 2026-05-23
**Overall confidence:** HIGH — existing AppTheme verified in codebase; findings cross-checked with Flutter official docs

---

## Critical Discovery: AppTheme Foundation Already Built

Reading `lib/core/theme/app_theme.dart` (224 lines, live in production) reveals the design system foundation is already complete:

- Full sport palette: `sand / paper / ink / inkSoft / concrete / line / lineHair / orange / orangeDk / court / sun`
- Static helpers: `AppTheme.display()` (Anton), `AppTheme.ui()` (Manrope), `AppTheme.mono()` (JetBrains Mono)
- `lightTheme` with: TabBar `UnderlineTabIndicator(width: 2)`, NavigationBar with `indicatorColor: transparent` (pill removed), `DividerThemeData`, `CardThemeData(elevation: 0, hairline border)`, filled/outlined/text buttons, input underline, switch, snackBar, FAB, chip themes
- `NavigationBarThemeData` with `WidgetStateProperty.resolveWith` for icon + label selected/idle states

**Implication:** DS-01..DS-04 requirements are satisfied. All v6.0 work is widget-level application of existing tokens — no theme reconstruction needed.

---

## Table Stakes

Features that must work correctly or the redesign feels broken.

| Feature | Why Expected | Complexity | Status |
|---------|--------------|------------|--------|
| Single ThemeData source | All widgets pull from `AppTheme.lightTheme`, no inline overrides | Low | DONE |
| google_fonts runtime fetch (Anton / Manrope / JetBrains Mono) | Three fonts, no local asset bundling needed; `google_fonts` caches on device | Low | DONE |
| `display()` / `ui()` / `mono()` static helpers | One-call TextStyle with font, size, color, letterSpacing baked in | Low | DONE |
| ColorScheme with all M3 roles populated | `primary`, `onPrimary`, `surface`, `onSurface`, `error`, `outline`, `onSurfaceVariant`, etc. | Low | DONE |
| TabBar UnderlineTabIndicator 2px orange | `TabBarThemeData.indicator: UnderlineTabIndicator(borderSide: BorderSide(color: orange, width: 2))` | Low | DONE |
| NavigationBar: no pill, sand bg, no shadow | `indicatorColor: transparent`, `surfaceTintColor: transparent`, `elevation: 0` | Low | DONE |
| NavigationBar selected = orange icon + mono label | `WidgetStateProperty.resolveWith` on `iconTheme` and `labelTextStyle` | Low | DONE |
| Hairline divider token in DividerThemeData | `DividerThemeData(color: lineHair, thickness: 1, space: 0)` | Low | DONE |
| Card zero-elevation with hairline border | `CardThemeData(elevation: 0, shape: RoundedRectangleBorder(side: BorderSide(color: lineHair)))` | Low | DONE |
| Per-screen widgets use `AppTheme.*` only | No widget redefines a color or TextStyle inline | Med | NOT DONE — this is all v6.0 work |

---

## Differentiators

Features that make Arena Esportivo feel native instead of generic Material.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Anton 88px slot time hero (BOOK-07) | Clock-face legibility; immediate hierarchy signal | Low | `AppTheme.display(size: 88)` replacing existing text widget |
| Anton 72px "Próximo" hero (BOOK-10) | Next booking stands out without a black hero block | Low | Same pattern, different screen |
| Hairline slot rows — no Card (SCHED-05) | Scoresheet feel; eliminates Material card shadow | Med | Refactor `SlotCard`; use `Container(decoration: BoxDecoration(border: Border(bottom: ...)))` |
| 3px orange left border for "my booking" (SCHED-05) | Encodes ownership with color accent, not fill | Low | `Border(left: BorderSide(color: orange, width: 3))` inside row decoration |
| Opacity 0.45 for booked-by-other slot (SCHED-05) | Visual de-emphasis without hiding info | Low | `Opacity(opacity: 0.45, child: ...)` |
| Day selector underline column, not chip (SCHED-04) | Horizontal strip: mono abbreviation + Anton number + orange underline on active | Med | New widget replacing `DayChipRow`; wire to same cubit state |
| Admin header: wordmark + eyebrow (ADMN-14) | "VIDA ATIVA" in Anton + "Painel admin" mono — replaces plain title | Low | AppBar `title:` replaced with custom `Row` widget |
| Admin tab labels in JetBrains Mono uppercase (ADMN-13) | Already configured in TabBarThemeData — verify no widget-level override | Low | Confirm no `labelStyle:` override in `TabBar(...)` call |
| Notification banner: left border 2px, no fill (ADMN-15) | Ink/quiet — reduces visual noise | Low | `Container(decoration: BoxDecoration(border: Border(left: BorderSide(color: orange, width: 2))))` |
| Booking confirmation left border 2px (BOOK-08) | Replaces colored banner/box of approval warning | Low | Same border pattern as notification |
| Section headers in JetBrains Mono uppercase (BOOK-12) | Scoreboard aesthetic — `AppTheme.mono(size: 10).copyWith(letterSpacing: 1.8)` + `.toUpperCase()` | Low | One-liner per section header |
| Admin booking row: Anton 36px + mono status pill (ADMN-18) | Time stands out; status is compact and readable | Low | `AppTheme.display(size: 36)` + pill container |
| Confirm/Reject as pills ink/quiet (ADMN-19) | Replaces colored action buttons | Low | `OutlinedButton` styled from existing theme |
| Avatar flat color: orange=admin, ink=user (ADMN-20) | Role-coded at a glance; no gradient | Low | `CircleAvatar(backgroundColor: isAdmin ? AppTheme.orange : AppTheme.ink)` |
| Price tier: Anton timeline hairline 3px (ADMN-22) | Scoresheet pricing layout | Med | Replace existing price card with hairline row + `Container(height: 3, color: orange)` timeline bar |
| KPI cards: hairline grid, Anton value, mono delta (ADMN-26) | Dashboard without card shadow stack | Med | Refactor existing KPI widget to `Container` with `Border` instead of `Card` |
| Heatmap: orange intensity scale (ADMN-28) | `flutter_heatmap_calendar` supports custom `colorsets` — use `rgba(255,77,23,α)` gradient | Low-Med | Check `colorsets` parameter of `HeatMapCalendar` |
| Sport revenue: hairline progress bar 3px (ADMN-29) | Replace pie chart widget with `LinearProgressIndicator` or custom `Container` | Low | `Container(height: 3, color: orange.withOpacity(fraction))` |

---

## Anti-Features

Features to explicitly NOT build in v6.0.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| ThemeExtension for typography | Requires `copyWith` + `lerp` boilerplate; dark mode deferred to v7+; zero benefit now | Keep static helpers `AppTheme.display()` / `ui()` / `mono()` |
| InheritedWidget for design tokens | Over-engineering; static access via `AppTheme.*` already works | Use `AppTheme.*` constants directly |
| Rebuilding AppTheme from scratch | Already built and deployed; reconstruction risks widget regressions | Apply per-widget changes only |
| Third-party bottom nav package | M3 NavigationBarThemeData already fully configured | Keep Flutter `NavigationBar` |
| Bundling fonts as local pubspec assets | Adds binary weight and font file management; `google_fonts` caches automatically | Keep runtime `google_fonts` fetch |
| Hardcoding colors or TextStyles in widget files | Breaks single-source-of-truth; palette changes become expensive | Always reference `AppTheme.*` or `Theme.of(context)` |
| Dark mode | Deferred to v7+; adds `lerp()` complexity with no current requirement | Out of scope |
| PixPaymentScreen redesign | Explicitly out of scope per REQUIREMENTS.md | Leave as-is |
| New widgets not in approved design | Out of scope per REQUIREMENTS.md | No new components |

---

## Feature Dependencies (v6.0 widget work order)

```
AppTheme.lightTheme — DONE (stable, do not touch)
  |
  +-- NavigationBar selected state (NAV-01, NAV-02) — verify no widget override
  |
  +-- AdminScreen TabBar (ADMN-13, ADMN-14, ADMN-15)
  |     └── Unblocks all admin tab refactors below
  |
  +-- Schedule screen (SCHED-04, SCHED-05, SCHED-06)
  |     ├── DayChipRow → new DaySelectorStrip widget
  |     └── SlotCard → HairlineSlotRow refactor
  |
  +-- Booking flow (BOOK-07, BOOK-08, BOOK-09)
  |     └── Confirmation sheet: Anton hero + left border
  |
  +-- My Bookings (BOOK-10, BOOK-11, BOOK-12)
  |     └── "Próximo" Anton 72px + hairline rows + mono section headers
  |
  +-- Admin Slots tab (ADMN-16, ADMN-17)
  |
  +-- Admin Bookings tab (ADMN-18, ADMN-19)
  |
  +-- Admin Users tab (ADMN-20, ADMN-21)
  |
  +-- Admin Pricing tab (ADMN-22, ADMN-23)
  |
  +-- Admin Settings tab (ADMN-24, ADMN-25)
  |
  +-- Admin Dashboard tab (ADMN-26, ADMN-27, ADMN-28, ADMN-29)  ← most complex, last
```

---

## Flutter-Specific Technical Notes (HIGH confidence unless marked)

### (1) ThemeData + Custom Fonts

`GoogleFonts.manropeTextTheme()` sets all 14 TextTheme slots to Manrope. Anton and JetBrains Mono are only accessible via `AppTheme.display()` and `AppTheme.mono()` — they do not appear in `textTheme`. Any widget using `Theme.of(context).textTheme.titleLarge` gets Manrope. Widgets needing Anton/Mono must call the static helpers. This is correct and intentional.

### (2) Static TextStyle Helpers vs ThemeExtension

Static helpers are correct for this project. `ThemeExtension` requires `copyWith` + `lerp` methods, which exist only to support animated theme transitions and dark/light mode switching. With dark mode deferred to v7+, `ThemeExtension` adds zero value. Migration path when dark mode lands: wrap existing helpers in `ArenaTypography extends ThemeExtension<ArenaTypography>` with color-aware fields.

### (3) Replacing Card Widgets with Hairline Dividers

Two patterns; choose by context:

- **List item with bottom border:** `Container(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.lineHair))))` — no layout gap artifacts
- **Sections separated by a line:** use `Divider()` which pulls from `DividerThemeData` automatically

Existing `Card` widgets that stay as `Card` will automatically get `elevation: 0` + hairline border from `CardThemeData` — no refactor needed for those. Only `Card` widgets explicitly replaced by plain rows need the `Container` border approach.

### (4) TabBar UnderlineTabIndicator 2px

Already live. Key M3 note: when `indicator:` is specified on `TabBarThemeData`, the `indicatorColor` and `indicatorWeight` properties are ignored — the `indicator` Decoration wins entirely. The `dividerColor: line` in `tabBarTheme` draws the bottom line spanning the full tab width; the `UnderlineTabIndicator` draws only under the active tab. `indicatorSize: TabBarIndicatorSize.tab` makes the 2px underline span the full tab width (correct for uppercase mono labels with visual weight).

### (5) NavigationBar M3 Pill Indicator Removal

Setting `indicatorColor: Colors.transparent` removes the pill fill. `surfaceTintColor: Colors.transparent` removes M3 tonal elevation tint. Both are already set. Known limitation (MEDIUM confidence, GitHub issue #138850): there is no `overlayColor` property on `NavigationBar`, so the ripple/ink response bounds remain pill-shaped even with transparent indicator. For Arena design (orange icon tint is the only selected feedback), this is acceptable — no workaround needed.

`labelBehavior` defaults to `NavigationDestinationLabelBehavior.alwaysShow`, which is correct — labels always visible.

### (6) google_fonts PWA Behavior

`google_fonts` caches downloaded font files in the app's file system on first load. In a Flutter Web PWA, this means fonts are fetched from Google Fonts CDN on first visit, then served from browser cache. For a PWA used in a gym environment (likely reliable WiFi), this is acceptable. If offline-first is required, local asset bundling via `pubspec.yaml` `fonts:` section is the alternative — but offline is explicitly out of scope per REQUIREMENTS.md.

---

## Recommended Phase Order for v6.0

1. **Verify NavigationBar** (NAV-01, NAV-02) — check for widget-level `NavigationBar` property overrides in `main_nav_screen.dart`; fix if any
2. **Schedule screen** (SCHED-04, SCHED-05, SCHED-06) — highest user-facing impact; new `DaySelectorStrip` + `HairlineSlotRow`
3. **Admin structure** (ADMN-13, ADMN-14, ADMN-15) — header + TabBar; unblocks all admin tabs
4. **Booking confirmation + My Bookings** (BOOK-07..12) — client flow
5. **Admin tabs: Slots, Bookings, Users** (ADMN-16..21) — mechanical hairline row refactors
6. **Admin tabs: Pricing, Settings** (ADMN-22..25) — lower complexity
7. **Admin Dashboard** (ADMN-26..29) — most complex; `fl_chart` + `flutter_heatmap_calendar` customization last

---

## Sources

- Flutter official — Use themes: https://docs.flutter.dev/cookbook/design/themes
- Flutter official — Material 3 migration: https://docs.flutter.dev/release/breaking-changes/material-3-migration
- Flutter API — NavigationBarThemeData: https://api.flutter.dev/flutter/material/NavigationBarThemeData-class.html
- Flutter API — TabBarTheme: https://api.flutter.dev/flutter/material/TabBarTheme-class.html
- Flutter API — UnderlineTabIndicator: https://api.flutter.dev/flutter/material/UnderlineTabIndicator-class.html
- Flutter API — Divider: https://api.flutter.dev/flutter/material/Divider-class.html
- google_fonts package: https://pub.dev/packages/google_fonts
- GitHub issue — NavigationBar overlayColor: https://github.com/flutter/flutter/issues/138850
- Codebase — lib/core/theme/app_theme.dart (verified 2026-05-23)

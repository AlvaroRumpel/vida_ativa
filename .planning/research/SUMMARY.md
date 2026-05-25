# Research Summary - v6.0 Arena Esportivo - Redesign Visual

**Project:** Vida Ativa - Flutter PWA
**Domain:** Flutter Material 3 design system application (widget-level migration)
**Researched:** 2026-05-23
**Confidence:** HIGH

---

## Executive Summary

v6.0 is a pure visual migration with no new packages, no BLoC changes, and no data model changes. The AppTheme.lightTheme foundation (DS-01 through DS-04) is already fully built and deployed in production: complete ColorScheme, all three fonts loaded via google_fonts 6.2.1 (Anton, Manrope, JetBrains Mono), static helpers display()/ui()/mono(), and all Material component themes (NavigationBar, TabBar, Card, Button, Input, Switch, Chip, FAB). All v6.0 work is applying existing tokens to widget build() methods that currently bypass the theme with hardcoded colors and TextStyles.

The recommended approach is a screen-by-screen migration in four visual impact groups: (A) navigation shell, (B) client schedule, (C) booking flow, (D) admin panel. Groups A and B ship a fully Arena-branded experience for all client users before a single admin widget is touched. Each group is independently deployable because BLoC/Cubit state is zero-change throughout.

The primary risk is font delivery on web: google_fonts fetches Anton/Manrope/JetBrains Mono from fonts.gstatic.com at runtime. On first load the app shows a system font before fonts load (FOUT), and in offline mode all display typography degrades completely. Mitigate before first deploy by bundling exact font weights in assets/google_fonts/. The second risk is hardcoded Color(0xFF...) literals in BookingCard, AdminBookingCard, and BookingConfirmationSheet that silently bypass the theme.

---

## Key Findings

### Stack - No New Packages

google_fonts 6.2.1 is sufficient. Anton, Manrope, and JetBrains Mono are confirmed available in the running codebase. Stay on this version; upgrading to 8.x during a visual milestone adds risk with zero benefit. flutter_bloc 9.1.1, fl_chart 1.2.0, and flutter_heatmap_calendar 1.0.5 require no changes; chart and heatmap colors are set via direct params on data models, not inherited from ThemeData.

**All Flutter APIs already correct for 3.41.9:**
- WidgetStateProperty (not deprecated MaterialStateProperty) - already used in app_theme.dart
- CardThemeData, TabBarThemeData, NavigationBarThemeData (with Data suffix) - already correct
- ThemeExtension - NOT needed; single light theme, dark mode deferred to v7+
- ColorScheme explicit constructor (not fromSeed) - correct for fixed brand palette

**Packages to NOT add:** flex_color_scheme, ThemeExtension packages, dynamic_color, widgetbook, any icon pack.

### Features - Foundation DONE, Widget Work Remaining

The entire DS-01..DS-04 surface is pre-built. What remains is 29 widget-level requirements across 7 screen groups.

**Table stakes - DONE (theme foundation):**
- Single ThemeData source wired in main.dart
- Google Fonts runtime fetch with correct API calls
- display()/ui()/mono() static helpers
- NavigationBar: no pill, sand bg, orange selected state, mono labels
- TabBar: UnderlineTabIndicator 2px orange, JetBrains Mono labels
- Card: zero elevation, hairline border
- All other Material component themes (Button, Input, Switch, Chip, FAB, SnackBar, Checkbox)

**Table stakes - NOT YET DONE (widget application):**
- All per-screen widgets using AppTheme.* tokens (NAV, SCHED, BOOK, ADMN groups)
- New components: SportDayStrip, SlotHairlineRow, SportBtn, HairlineBookingRow

**Key differentiators to build:**
- Anton 88px slot time hero (BOOK-07) and 72px Proximo hero (BOOK-10)
- Hairline slot rows with 3px orange left stripe and 0.45 opacity for booked-by-other (SCHED-05)
- Day selector underline column replacing ChoiceChip (SCHED-04)
- Admin Dashboard: KPI hairline grid, orange-intensity heatmap, simplified bar chart (ADMN-26..29)

**Defer to v7+:** dark mode, login/profile screen redesign, theme animations.
**Explicitly out of scope:** PixPaymentScreen redesign, any BLoC/model/routing changes.

### Architecture - Pure Widget Migration

AppTheme.lightTheme is already wired as the single global theme in main.dart. The migration is pure build() rewrites in */ui/*.dart files. BLoC/Cubit files, model classes, router, Cloud Functions, and AppSpacing are zero-change. Any PR that modifies a cubit file is out of scope.

**New components to create:**

| Component | Path | Replaces |
|-----------|------|---------|
| SportDayStrip | lib/features/schedule/ui/sport_day_strip.dart | DayChipRow |
| SlotHairlineRow | lib/features/schedule/ui/slot_hairline_row.dart | SlotCard |
| SportBtn | lib/core/widgets/sport_btn.dart | ad-hoc styled buttons |
| HairlineBookingRow | lib/features/booking/ui/hairline_booking_row.dart | BookingCard |

**Key patterns:**
- Never use Theme(data: Theme.of(context).copyWith(...)) inside widget subtrees
- Replace IntrinsicHeight in list rows with Stack + Positioned for status stripes
- AppTheme.court (green) = confirmed/success; AppTheme.orange = accent/primary - do NOT unify
- When rewriting SportDayStrip, preserve exact ValueChanged<DateTime> onDaySelected callback

### Critical Pitfalls

1. **Font FOUT / offline degradation** - google_fonts fetches from CDN at runtime. On cold start: system font flashes before Anton/Manrope loads. Offline: all display typography falls back to browser sans-serif, breaking 88px Anton layouts completely. Fix before first deploy: bundle Anton 400, Manrope 400/600/700, JetBrains Mono 700 in assets/google_fonts/ and declare in pubspec.yaml.

2. **Hardcoded colors bypass theme** - booking_card.dart has 6+ Color(0xFF...) literals; admin_booking_card.dart has _sportBgColors/_sportFgColors arrays of 8 Material colors; booking_confirmation_sheet.dart has amber container override. Widget tests will not catch these. Audit with grep and map each hex to the nearest AppTheme.* constant before redesigning.

3. **NavigationBar indicator ripple persists** - indicatorColor: Colors.transparent removes the pill fill but not the ink/splash overlay (open Flutter issue 138850). Already correctly set in theme. If ripple becomes visible, wrap NavigationBar in a Theme with splashColor: transparent and highlightColor: transparent. Flutter 3.32 regression: nav bar turns black - test immediately after any SDK upgrade.

4. **Anton height: 0.92 clips at large sizes** - At 88px, logical height is approximately 81px. Any SizedBox with explicit height smaller than fontSize * 0.92 * 1.1 will clip the cap. Do NOT wrap large Anton text in fixed-height SizedBox. Let Text measure its own height.

---

## Implications for Roadmap

The 7-phase sequence from FEATURES.md maps onto 7 roadmap phases. AppTheme foundation is complete and is a pre-condition, not a phase.

### Phase 1: NavigationBar Verification (NAV-01, NAV-02)
**Rationale:** Lowest risk, fastest win. Theme already configured. Font bundling in assets/google_fonts/ happens here as setup step before any screen ships fonts via CDN.
**Delivers:** Correct nav bar on all screens - orange icon, mono label, sand bg, no pill.
**Avoids:** Pitfall 3 (ripple through transparent indicator); Flutter 3.32 background regression.

### Phase 2: Schedule Screen (SCHED-04, SCHED-05, SCHED-06)
**Rationale:** Highest user-facing surface area - every client on every visit. Contains the two most complex new widgets. Establishes the hairline row pattern used in all subsequent phases.
**Delivers:** Full Arena-branded client agenda experience.
**New components:** SportDayStrip, SlotHairlineRow.
**Avoids:** Day selector cubit desync (preserve ValueChanged<DateTime> callback; update both setState and cubit.selectDay() on week navigation); Anton 42px height clipping.

### Phase 3: Admin Structure (ADMN-13, ADMN-14, ADMN-15)
**Rationale:** AppBar + TabBar + notification banner are shared across all 6 admin tabs. Must ship before any tab refactors.
**Delivers:** Arena-branded admin frame; unblocks Phases 5, 6, 7.
**Avoids:** TabBarThemeData type confusion (keep Data suffix); test underline indicator on 5+ tabs.

### Phase 4: Booking Flow (BOOK-07, BOOK-08, BOOK-09, BOOK-10, BOOK-11, BOOK-12)
**Rationale:** Second most-used client surface. Anton 88px and 72px heroes are the signature visual moments of v6.0. HairlineBookingRow created here is reused in Phase 5.
**Delivers:** Complete client booking experience in Arena identity.
**New components:** SportBtn, HairlineBookingRow.
**Avoids:** 6+ hardcoded hex in booking_card.dart; IntrinsicHeight in list rows (use Stack + Positioned); Anton clipping at 88px and 72px.

### Phase 5: Admin Slots + Bookings + Users (ADMN-16..21)
**Rationale:** Mechanical hairline row refactors using patterns from Phases 2 and 4. Reuses HairlineBookingRow from Phase 4.
**Delivers:** Three admin tabs fully Arena-branded.
**Avoids:** Admin day selector int index (migrate to DateTime); _sportBgColors/_sportFgColors hardcoded arrays in AdminBookingCard.

### Phase 6: Admin Pricing + Settings (ADMN-22..25)
**Rationale:** Lower complexity - Switch already themed, input fields already themed. Mostly layout hairline plus SportBtn.
**Delivers:** Two admin tabs fully Arena-branded.

### Phase 7: Admin Dashboard (ADMN-26..29)
**Rationale:** Most complex - fl_chart bar customization, flutter_heatmap_calendar orange colorsets, KPI grid from Card to hairline Container. Done last so all patterns are established.
**Delivers:** Fully branded dashboard with orange-intensity heatmap and simplified charts.
**Key:** Chart and heatmap colors via direct params; use AppTheme.orange.withValues(alpha: x) not deprecated withOpacity.

### Phase Ordering Rationale

- Font bundling in assets/google_fonts/ is a Phase 1 setup step, not a standalone phase.
- Admin phases 5, 6, 7 are blocked until Phase 3 ships the admin frame.
- HairlineBookingRow from Phase 4 is reused in Phase 5 - Phase 4 ships first to eliminate duplication.
- AppTheme.primaryGreen alias cleanup is post-milestone, not in v6.0 scope.

### Research Flags

Skip gsd-research-phase (patterns confirmed in source):
- **Phase 1** - verification only; theme already wired and confirmed
- **Phase 3** - admin AppBar/TabBar; APIs confirmed correct in live codebase
- **Phase 6** - Switch/input theming confirmed correct in app_theme.dart

Consider gsd-research-phase if blockers arise:
- **Phase 2** - if cubit desync during week navigation is non-trivial
- **Phase 7** - verify exact flutter_heatmap_calendar colorsets param names against installed version

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Direct codebase read of app_theme.dart; all three fonts confirmed in running code |
| Features | HIGH | Requirements cross-checked against live app_theme.dart; DS-01..04 status verified |
| Architecture | HIGH | Full widget file inventory done; BLoC files confirmed zero-change |
| Pitfalls | HIGH | Open Flutter issues cited with numbers; hardcoded color count verified in source |

**Overall confidence:** HIGH

### Gaps to Address

- **Font bundling exact filenames:** google_fonts requires exact .ttf filenames for asset detection. Wrong filenames cause silent HTTP fallback. Confirm filenames from package source before Phase 1 setup.
- **flutter_heatmap_calendar colorsets:** API confirmed on pub.dev but not tested in the live app. Verify exact parameter types against installed version before Phase 7.
- **NavigationBar ripple acceptability:** Needs visual validation in staging to determine whether splashColor: transparent workaround is necessary.

---

## Sources

- lib/core/theme/app_theme.dart - direct read, 2026-05-23 (HIGH)
- Flutter API - NavigationBarThemeData: https://api.flutter.dev/flutter/material/NavigationBarThemeData-class.html
- Flutter API - TabBarTheme: https://api.flutter.dev/flutter/material/TabBarTheme-class.html
- Flutter breaking changes - MaterialState to WidgetState: https://docs.flutter.dev/release/breaking-changes/material-state
- Flutter 3.27 release notes (CardThemeData, TabBarThemeData): https://docs.flutter.dev/release/release-notes/release-notes-3.27.0
- google_fonts pub.dev changelog: https://pub.dev/packages/google_fonts/changelog
- GitHub - NavigationBar missing overlayColor issue 138850: https://github.com/flutter/flutter/issues/138850
- GitHub - NavigationBar background regression Flutter 3.32 issue 169258: https://github.com/flutter/flutter/issues/169258
- GitHub - google_fonts WASM asset loading issue 159375: https://github.com/flutter/flutter/issues/159375
- Flutter docs - IntrinsicHeight cost: https://api.flutter.dev/flutter/widgets/IntrinsicHeight-class.html

---
*Research completed: 2026-05-23*
*Ready for roadmap: yes*
# Domain Pitfalls: v6.0 Arena Esportivo — Design System Migration

**Domain:** Flutter Web PWA — Adding design system to live Material 3 app
**Researched:** 2026-05-23
**Confidence:** HIGH (code read + official Flutter docs + verified issues)

---

## Context

This document replaces the v5.0 pitfalls file for the current milestone. The app already runs Material 3 (`useMaterial3: true`) with a partially-applied `AppTheme` (`app_theme.dart`). The `ThemeData` was already partially migrated — `NavigationBar`, `TabBar`, `Switch`, `Chip`, `Card` theming exist. The redesign adds 3 Google Fonts families (Anton/Manrope/JetBrains Mono loaded via `google_fonts: ^6.2.1`), removes `ChoiceChip`-based day selectors (already replaced by `DayChipRow` with `GestureDetector`), and rewrites remaining `Card`-based layouts to hairline rows with `IntrinsicHeight`.

---

## Critical Pitfalls

### Pitfall 1: ThemeData copyWith Cascade Failure — Subordinate Themes Silently Ignore Parent Changes

**What goes wrong:** Adding or modifying a color in `ColorScheme` (e.g., adding `surfaceContainer`, `surfaceContainerHighest`, `primaryContainer`) does not cascade into already-defined subordinate themes. Flutter documents this explicitly: `ThemeData.copyWith()` updates specified fields only — dependent sub-themes (`cardTheme`, `chipTheme`, `tabBarTheme`, etc.) are NOT recomputed.

**Why it happens:** The current `AppTheme.lightTheme` is defined in one `ThemeData(...)` constructor call, so it appears safe. The problem appears when a phase adds a second theme or calls `copyWith()` elsewhere — for example, if any screen or widget wraps children in `Theme(data: Theme.of(context).copyWith(...))`. The child theme will have stale `cardTheme`, `chipTheme`, etc. that reference the old palette.

**Specific risk in this codebase:** `BookingCard` uses hardcoded `Color(0xFF9E9A95)`, `Color(0xFF1565C0)`, `Color(0xFFC62828)` — these will NOT pick up theme changes automatically. Any screen-level `Theme.of(context).copyWith()` will propagate unchanged.

**Consequences:** Cards, chips, or icons render in old colors in specific screens but not others. Bug is invisible in widget tests that don't use a real `MaterialApp`. Only visible at integration test or visual review level.

**Prevention:**
- Define all theme tokens once in `AppTheme.lightTheme`. Never call `.copyWith()` on the app-level theme in screens.
- Audit every file with `grep -r "Theme.of(context).copyWith\|Theme(" lib/` before starting redesign.
- Replace all hardcoded `Color(0xFF...)` in UI files with `AppTheme.*` constants.
- If a local theme override is genuinely needed, override the specific sub-theme, not the whole theme.

**Detection:**
- Widget renders different color from `AppTheme` constant of same role
- Hardcoded hex codes in widget files: `booking_card.dart` has 6+ such colors

**Phase:** DS-01 / DS-04 (foundation phase). Fix hardcoded colors BEFORE applying theme globally. Confidence: HIGH.

---

### Pitfall 2: google_fonts HTTP Fetch on Web — Fonts Blocked, App Ships Without Anton/Manrope

**What goes wrong:** `google_fonts: ^6.2.1` fetches fonts from `fonts.gstatic.com` at runtime on web. The fetch:
1. Requires an outbound HTTP connection to Google servers from the user's browser.
2. Is subject to the app's Content Security Policy (CSP). Firebase Hosting's default CSP can block cross-origin font fetches.
3. On first load (cold start, no cached fonts), Anton/Manrope/JetBrains Mono are absent for 200-800ms — Flutter renders with the system fallback font, then re-renders when fonts load. This causes a visible layout jump on every PWA cold start.
4. If the user is offline (PWA cached), fonts are never fetched — all text falls back to the browser's system sans-serif. Anton's display-size (42px–88px) will look completely wrong with a narrow system font.

**Why it happens:** `google_fonts` auto-discovers font files from `pubspec.yaml` assets. If the font files are NOT listed as assets, it falls back to HTTP. The current `pubspec.yaml` only lists `assets/images/` — no `google_fonts/` folder exists, so all 3 families are fetched at runtime.

**Consequences:**
- FOUT (Flash of Unstyled Text): visible on every cold start, worse on slow connections.
- Offline mode: all Anton/Manrope/JetBrains Mono text degrades to system font. The 88px Anton slot time becomes 88px Helvetica — layout breaks.
- CSP issues: if `fonts.gstatic.com` is not in the `connect-src` / `font-src` directive of `firebase.json` headers, font fetch silently fails.

**Prevention:**
1. Download font files from fonts.google.com for exact weights used:
   - Anton: Regular 400 only (display font, no bold variant)
   - Manrope: 400, 600, 700 (UI text)
   - JetBrains Mono: 700 (mono labels)
2. Place in `assets/google_fonts/` (exact directory name required — package checks this).
3. Add to `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/google_fonts/
   ```
4. The package auto-detects asset-bundled fonts by filename and uses them instead of HTTP.
5. WASM note: `google_fonts: ^6.2.1` has a confirmed bug in WASM builds where asset fonts are not loaded. The app currently targets JS/CanvasKit (not WASM), so this is not an immediate blocker — but do NOT upgrade to Flutter WASM target without verifying font loading.

**Detection:**
- App renders system font on cold start, then jumps to Anton/Manrope
- Disable internet in browser devtools → all text degrades
- Network tab in devtools shows requests to `fonts.gstatic.com`

**Phase:** DS-02 (typography setup). Must be done BEFORE any screen uses `AppTheme.display()` / `AppTheme.mono()`. Confidence: HIGH.

---

### Pitfall 3: NavigationBar Indicator Pill Persists Despite `indicatorColor: Colors.transparent`

**What goes wrong:** Setting `indicatorColor: Colors.transparent` in `NavigationBarThemeData` removes the fill of the pill, but the pill's ink/splash overlay remains visible on tap. There is no `overlayColor` property on `NavigationBar` (confirmed open Flutter issue #138850). The ripple effect uses `ColorScheme.primary` with a hardcoded opacity, creating a colored flash on every tab tap even when the indicator itself is transparent.

**Specific risk in this codebase:** `app_shell.dart` wraps `NavigationBar` in a `Container` with a custom `Border(top: ...)`. The current `navigationBarTheme` already sets `indicatorColor: Colors.transparent` and `surfaceTintColor: Colors.transparent`. This is correctly set. The outstanding risk is the **background color resolution**:

- Material 3's `NavigationBar` defaults `backgroundColor` to `ColorScheme.surfaceContainer` when null.
- The current theme sets `backgroundColor: sand` in `NavigationBarThemeData`.
- If any phase resets `navigationBarTheme` or creates a nested `Theme`, the bar reverts to `surfaceContainer` (which is not `sand`).

**Second risk — Flutter 3.32 regression:** A confirmed bug in Flutter 3.32.x causes `NavigationBar` background to render black regardless of theme settings. If the project upgrades Flutter during this milestone, test the nav bar immediately.

**Prevention:**
- Keep `NavigationBarThemeData.backgroundColor: sand` explicitly set in all theme variants.
- Do not add a `NavigationBar(backgroundColor: ...)` parameter directly — let it come from theme. The `Container` wrapper in `app_shell.dart` for the top border is fine.
- After any Flutter SDK upgrade, render the nav bar in staging and visually verify background color.
- To suppress ripple: wrap `NavigationBar` in a `Theme` that sets `splashColor: Colors.transparent` and `highlightColor: Colors.transparent` if ink splash becomes visible.

**Detection:**
- Nav bar turns wrong color after Flutter upgrade
- Tap on nav item shows colored ripple circle even though `indicatorColor` is transparent

**Phase:** NAV-01 / NAV-02. Confidence: HIGH (official docs + open Flutter issue confirmed).

---

### Pitfall 4: DayChipRow State Split Between StatefulWidget and Cubit — Risk of Desync

**What goes wrong:** The current `ScheduleScreen` is a `StatefulWidget` that stores `_weekStart`, `_selectedDay`, and `_currentWeekMonday` in local `State`. It calls `context.read<ScheduleCubit>().selectDay(day)` to drive the slot list. The `DayChipRow` is a pure `StatelessWidget` driven by `selectedDay` prop.

This architecture is already correct and does NOT use `ChoiceChip`. The risk appears when the admin `_SlotDayView` tab is redesigned — it uses a different pattern (`_selectedDayOfWeek` as `int` in `_SlotDayViewState`, with a different cubit). If the designer creates a shared `DaySelector` component and it is wired incorrectly, two common desync bugs appear:

**Bug A — Selected day not reset on week navigation:** If the replacement widget doesn't call `cubit.selectDay()` when `weekStart` changes, the cubit still holds the old day, and the slot list shows data for a day in the previous week while the UI shows the new week's chips.

**Bug B — Widget rebuild loses `_selectedDay`:** If the parent `StatefulWidget` is replaced by a `StatelessWidget` (e.g., to simplify code), local state is gone. `setState` must not be moved into the cubit unless `_weekStart` and `_selectedDay` are emitted as part of cubit state.

**Consequences:** Day selector shows "Wednesday" visually selected, but slot list shows Tuesday's slots. Intermittent depending on rebuild path. Hard to repro in tests.

**Prevention:**
- Do NOT change the `ScheduleScreen` to `StatelessWidget`. Local UI state (`_weekStart`, `_selectedDay`) belongs in `State`, not in cubit state.
- If creating a shared `DaySelectorWidget`, keep the `onDaySelected` callback pattern — caller drives state, widget is stateless.
- When week changes (`_goToPreviousWeek`/`_goToNextWeek`), always update BOTH `setState(_weekStart)` AND call `cubit.selectDay()` in the same method. Never forget one.
- Admin tab day selector: mirror the same pattern used in `ScheduleScreen` — don't use `_selectedDayOfWeek` as an `int` index (current code). Convert to `DateTime` to match the client pattern and avoid off-by-one errors in week boundaries.

**Detection:**
- Slot list updates only on day tap, not on week navigation arrow tap
- Selected day chip and slot list are out of sync after rapid week flipping

**Phase:** SCHED-04, ADMN-17. Confidence: HIGH (code-verified pattern).

---

## Moderate Pitfalls

### Pitfall 5: BookingCard IntrinsicHeight — Layout Pass Cost in Long Lists

**What goes wrong:** `BookingCard` currently uses `IntrinsicHeight` to make the left status stripe (`Container(width: 4, color: _statusColor(...))`) fill the card's height. `IntrinsicHeight` triggers a two-pass layout: one to measure intrinsic height of children, one to lay out at the resolved size. In `ListView` with many bookings, each card pays this double-pass cost.

For the redesign, `IntrinsicHeight` will remain necessary unless the stripe is replaced with a different approach. The risk is that replacing `Card` with a hairline-divider row (as per BOOK-10, BOOK-11) removes the need — but if `IntrinsicHeight` is inadvertently kept in the new layout, performance degrades.

**Prevention:**
- In the new hairline layout, replace the stripe + `IntrinsicHeight` pattern with a `Stack` or `DecoratedBox` that uses `Positioned(left: 0, top: 0, bottom: 0)` — this avoids the intrinsic pass entirely because `Positioned` with explicit `top`/`bottom` fills the stack height without needing intrinsic measurement.
- If `IntrinsicHeight` is retained for the "Próximo" hero section (single item), it is acceptable — the cost only matters in unbounded lists.
- Do NOT use `IntrinsicHeight` inside `ListView.builder` rows.

**Example replacement:**
```dart
// AVOID: IntrinsicHeight in list rows
IntrinsicHeight(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(width: 4, color: statusColor),
      Expanded(child: content),
    ],
  ),
)

// USE: Stack with Positioned fills height without intrinsic pass
SizedBox(
  height: 72, // fixed or constrained by parent
  child: Stack(
    children: [
      Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 3, color: statusColor)),
      Padding(padding: EdgeInsets.only(left: 12), child: content),
    ],
  ),
)
```

**Detection:**
- `IntrinsicHeight` inside `ListView.builder` itemBuilder
- Profiler shows double layout passes in booking list

**Phase:** BOOK-10, BOOK-11. Confidence: HIGH (Flutter docs explicit: IntrinsicHeight is expensive, avoid in lists).

---

### Pitfall 6: Chip Theme Overrides ChoiceChip Selected Color Globally

**What goes wrong:** `AppTheme` defines `chipTheme: ChipThemeData(selectedColor: ink, ...)`. Any `ChoiceChip` anywhere in the app (including third-party widgets or admin forms that were not audited) will now render with `ink` as selected background. If admin has a filter chip or choice chip not in scope for redesign, it silently picks up the wrong color.

**Why it happens:** `ChipThemeData` applies to ALL chip subtypes (`ChoiceChip`, `FilterChip`, `InputChip`, `ActionChip`) unless they define their own `ChipThemeData` via `ChoiceChip.style`.

**Prevention:**
- Audit all chip usages: `grep -rn "ChoiceChip\|FilterChip\|InputChip\|ActionChip" lib/`
- The `DayChipRow` already replaces `ChoiceChip` for the day selector — no `ChoiceChip` remains there.
- Any remaining chip usage (found in admin slot/booking filtering) must be tested after `chipTheme` change.
- If a chip needs different colors, use `ChoiceChip(...)` with explicit `style: ButtonStyle(...)` not relying on theme.

**Detection:**
- Admin area chips render with `ink` (near-black) background when selected, instead of a distinguishable color
- `grep -rn "ChoiceChip" lib/` returns unexpected results

**Phase:** DS-04 (theme foundation). Confidence: HIGH.

---

### Pitfall 7: TabBarTheme Type Change — `TabBarThemeData` vs `TabBarTheme`

**What goes wrong:** Flutter 3.16+ changed `ThemeData.tabBarTheme` type from `TabBarTheme` to `TabBarThemeData`. The current `app_theme.dart` already uses `TabBarThemeData` correctly. The risk is that if any developer copies old documentation or Stack Overflow snippets using `TabBarTheme(...)`, Dart will compile silently (both are valid types) but the wrong type may not apply all properties, particularly `indicator` and `dividerColor`.

**Additional risk — `UnderlineTabIndicator` with Material 3:** The `indicator: UnderlineTabIndicator(borderSide: ...)` in the current `tabBarTheme` may not render the underline at the correct position when used inside an `AdminScreen` that wraps `TabBar` in a custom `Container`. Material 3 `TabBar` positions the indicator based on `TabBarIndicatorSize.tab` — if the admin screen adds extra padding or `PreferredSize`, the indicator clips.

**Prevention:**
- Keep `TabBarThemeData` (with `Data` suffix) in all theme definitions.
- Test the admin TabBar underline indicator in staging at full scroll range.
- The `indicatorSize: TabBarIndicatorSize.tab` setting in the current theme causes the indicator to span the full tab width, not just the label — this is correct for the design intent but verify it doesn't overflow when admin has 5+ tabs.

**Phase:** ADMN-13. Confidence: MEDIUM (code-verified, type change is documented).

---

### Pitfall 8: Anton Font Renders at Wrong Height — `height: 0.92` Clips Text in Some Contexts

**What goes wrong:** `AppTheme.display()` sets `height: 0.92` (line height). Anton is a condensed display font with tight metrics. At `height < 1.0`, descenders are clipped in some Flutter rendering contexts, particularly:
- Inside `SizedBox` with fixed height
- Inside `FittedBox`
- Inside `Row` where `CrossAxisAlignment.center` is used — the text baseline shifts

**Specific risk:** BOOK-07 requires Anton at 88px for slot time. At `height: 0.92`, an 88px Anton string has a logical height of ~81px. If wrapped in a `SizedBox(height: 80)`, the top cap is clipped. The `SlotCard` already uses Anton at 42px with `height: 0.92` — test at 88px before deploying.

**Prevention:**
- Test Anton at 42px, 72px, 88px in isolation on the target device (mobile Chrome on Android).
- Use `overflow: TextOverflow.visible` and unbounded height when first prototyping display sizes.
- For the 88px hero element, do NOT wrap in a fixed `SizedBox` — let the `Text` widget measure its own height.
- Keep `height: 0.92` — it produces correct visual rhythm — but ensure parent has no explicit height constraint smaller than `fontSize * 0.92 * 1.1` (safety margin for cap height).

**Detection:**
- Anton text visually cut off at top or bottom edge
- SizedBox height constraint smaller than `fontSize * 0.92`

**Phase:** BOOK-07, BOOK-10, ADMN-16. Confidence: MEDIUM (Anton metrics verified by testing; `height: 0.92` is in current codebase but untested at 88px).

---

## Minor Pitfalls

### Pitfall 9: Hardcoded Colors in booking_card.dart Block Theme Adoption

**What goes wrong:** `booking_card.dart` contains 6+ hardcoded hex values: `Color(0xFF9E9A95)` (icon gray), `Color(0xFF1565C0)` (on-arrival blue), `Color(0xFFC62828)` (cancel red), `Color(0xFF7B1FA2)` (refunded purple), etc. When `AppTheme` palette is applied globally, these elements stay on the old palette because they bypass the theme entirely.

**Prevention:**
- Before redesigning `BookingCard`, run: `grep -n "Color(0x" lib/features/booking/ui/booking_card.dart`
- Map each hardcoded color to the nearest `AppTheme` constant:
  - `0xFF9E9A95` → `AppTheme.concrete`
  - `0xFFC62828` → `AppTheme.orangeDk` (cancel action)
  - Status colors → already in `_statusColor()` switch — extend with `AppTheme` palette
- The `recurrenceGroupId` badge uses `AppTheme.primaryGreen` (which is `court`) — already correct.

**Phase:** BOOK-10, BOOK-11. Confidence: HIGH (code-verified).

---

### Pitfall 10: NavigationBar Label `UPPERCASE` From Mono Font, Not CSS

**What goes wrong:** The design calls for nav labels in JetBrains Mono uppercase (`'AGENDA'`, `'RESERVAS'`, `'PERFIL'`). The current `app_shell.dart` passes uppercase strings as `label:` directly in `NavigationDestination`. This is fine for static strings. The risk is that `labelTextStyle` in `NavigationBarThemeData` uses `GoogleFonts.jetBrainsMono(...)` — if the font fails to load (HTTP fail), the labels fall back to Manrope (the `textTheme` base) in whatever case the string is in.

**Prevention:**
- Bundle JetBrains Mono as an asset (covered by Pitfall 2 prevention).
- The label strings should remain UPPERCASE in code (already correct) — do not rely on CSS `text-transform` since Flutter does not have it.
- After bundling fonts, verify labels render correctly in offline mode.

**Phase:** NAV-01, DS-02. Confidence: MEDIUM.

---

### Pitfall 11: `AppTheme.primaryGreen` Alias — Silent Reference to Wrong Color

**What goes wrong:** `app_theme.dart` defines `static const Color primaryGreen = court;` as a legacy alias for backward compatibility. `booking_card.dart` and other v4.0 files use `AppTheme.primaryGreen`. After the redesign, `court` (`Color(0xFF1B5E2A)` — success green) may be correct for status-confirmed color, but any developer reading the code sees "primaryGreen" and assumes it is the "primary" color — which is now `orange`.

**Prevention:**
- After v6.0 ships, in a follow-up cleanup commit, remove the `primaryGreen` alias and update all call sites to use `AppTheme.court` explicitly.
- Do NOT remove it during v6.0 (unrelated change, risks silent breakage if any callsite is missed).
- `brandAmber` alias (`= orange`) has the same issue — rename in cleanup.

**Phase:** Post v6.0 cleanup. Confidence: HIGH.

---

## Phase-Specific Warnings

| Phase Area | Likely Pitfall | Mitigation |
|------------|---------------|------------|
| DS-01 ColorScheme | `ThemeData.copyWith()` cascade failure | Define all tokens in one `ThemeData()` constructor; no runtime `copyWith()` |
| DS-02 Typography | Anton/Manrope not bundled — FOUT on cold start | Bundle as assets in `assets/google_fonts/` before first deploy |
| DS-02 Typography | Anton `height: 0.92` clips at large sizes | Test at 72px and 88px; no fixed-height constraints on Anton containers |
| DS-04 Theme | `ChipThemeData.selectedColor` breaks unaudited chips | Audit all chip usages before applying global chip theme |
| DS-04 Theme | `TabBarThemeData` type mismatch | Keep `TabBarThemeData` suffix; test admin tab underline in staging |
| NAV-01 NavigationBar | Ink ripple visible through transparent indicator | Add `splashColor: transparent` if needed; do not rely on `indicatorColor: transparent` alone |
| NAV-01 NavigationBar | Flutter 3.32 regression: nav bar turns black | Test after any Flutter SDK upgrade; pin to tested version during milestone |
| SCHED-04 Day Selector | Selected day desyncs from slot cubit on week change | Always update both `setState` and `cubit.selectDay()` in week navigation handlers |
| ADMN-17 Admin Day Selector | `int` day-of-week index vs `DateTime` mismatch | Migrate to `DateTime`-based selection to match client pattern |
| BOOK-10/11 Booking rows | `IntrinsicHeight` in list rows | Replace with `Stack + Positioned` for status stripe; reserve `IntrinsicHeight` for single hero item only |
| BOOK-07 Slot time hero | Hardcoded colors in `booking_card.dart` | Audit and replace all 6+ hardcoded hex colors before redesigning |
| All screens | Legacy `AppTheme.primaryGreen` alias misleads | Document alias clearly; schedule removal post-milestone |

---

## Sources

- Flutter Material 3 migration guide: https://docs.flutter.dev/release/breaking-changes/material-3-migration
- `ThemeData.copyWith()` cascade limitation (issue #22913): https://github.com/flutter/flutter/issues/22913
- `NavigationBar` missing `overlayColor` (issue #138850): https://github.com/flutter/flutter/issues/138850
- `NavigationBar` background color regression Flutter 3.32 (issue #169258): https://github.com/flutter/flutter/issues/169258
- `google_fonts` WASM asset loading bug (issue #159375): https://github.com/flutter/flutter/issues/159375
- `google_fonts` FOUT and asset bundling: https://pub.dev/packages/google_fonts
- `IntrinsicHeight` performance cost: https://api.flutter.dev/flutter/widgets/IntrinsicHeight-class.html
- `IntrinsicHeight` alternatives: https://www.logique.co.id/blog/en/2025/03/25/intrinsic-widget-alternatives/
- ThemeExtension approach for custom tokens: https://apparencekit.dev/flutter-tips/flutter-create-custom-color-theme/

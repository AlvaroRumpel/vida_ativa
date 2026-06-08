# Phase 23: Design System + NavigationBar - Research

**Researched:** 2026-05-25
**Domain:** Flutter Material 3 Design System — Font Bundling, Theme Validation, Color Audit
**Confidence:** HIGH

## Summary

Phase 23 closes the design system foundation (DS-01..DS-04, NAV-01..NAV-02) by bundling 5 Google Fonts files offline, auditing hardcoded colors, fixing the NavigationBar top border token, and validating the build. AppTheme.lightTheme is already constructed (224 lines, verified in codebase) — no rebuild needed. Work is 100% integration: copy .ttf files, update pubspec.yaml, grep-and-replace colors, fix one border constant, then `flutter build web` + `flutter analyze` for completion.

**Primary recommendation:** Download 3 font files (Anton-Regular.ttf, Manrope[wght].ttf, JetBrainsMono[wght].ttf), place in assets/google_fonts/, add to pubspec.yaml assets, audit 3 files for hardcoded Color(0xFF...), replace with AppTheme tokens, change AppTheme.line → AppTheme.lineHair in app_shell.dart line 44, run flutter analyze + flutter build web clean.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Bundle 5 font files as assets in `assets/google_fonts/`:
  - Anton — weight 400 (only available weight)
  - Manrope — weights 400, 600, 700
  - JetBrains Mono — weight 700
  - Add `fonts:` section to pubspec.yaml and `assets/google_fonts/` to assets list
  - google_fonts auto-detects local files by filename — zero code changes needed

- **D-02:** Audit and replace all hardcoded `Color(0xFF...)` inline by tokens `AppTheme.*` in:
  - `lib/features/booking/ui/booking_card.dart` (6+ occurrences)
  - `lib/features/admin/ui/admin_booking_card.dart` (`_sportBgColors`/`_sportFgColors` maps)
  - `lib/features/booking/ui/booking_confirmation_sheet.dart`

- **D-03:** Phase 23 done when:
  - `flutter build web` completes without compilation errors
  - `flutter analyze` returns zero warnings/errors (hints OK)
  - Visual verification in staging NOT required this phase

### Claude's Discretion

- Fix `AppTheme.line` → `AppTheme.lineHair` in app_shell.dart (borda top do NavigationBar) — NAV-02 specifies hairline
- Task execution order (fonts → pubspec → audit → build verify)
- Exact .ttf filenames from Google Fonts registry before committing

### Deferred Ideas (OUT OF SCOPE)

- Visual verification in staging (diff for Phase 24+ when screens exist to view)
- Dark mode (v7+)
- Bundling additional font weights beyond 400/600/700

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DS-01 | AppTheme implements sport palette (sand, ink, orange, court, sun, line, lineHair, concrete) | ✅ AppTheme.lightTheme verified: all colors defined as static const Color |
| DS-02 | AppTheme configures typography: Anton (display), Manrope (UI), JetBrains Mono (mono) | ✅ Helpers AppTheme.display(), .ui(), .mono() verified; google_fonts 6.2.1 configured |
| DS-03 | AppTheme exposes helpers display(), ui(), mono() for consistent widget use | ✅ All 3 helpers exist with correct signatures; used in app_theme.dart lines 25–46 |
| DS-04 | Theme Material (colorScheme, tabBarTheme, navigationBarTheme, cardTheme, etc.) updated | ✅ lightTheme includes: TabBarThemeData + UnderlineTabIndicator, NavigationBarThemeData with sand bg + transparent indicator, CardThemeData with elevation:0 + hairline border, all sub-themes complete |
| NAV-01 | Bottom navigation bar: orange selected icon + concrete idle, mono uppercase labels | ✅ NavigationBarThemeData.labelTextStyle and iconTheme use WidgetStateProperty.resolveWith; labels already uppercase in code; theme complete |
| NAV-02 | Bottom navigation bar: sand background + hairline border on top, no elevation/shadow | ✅ Current: AppTheme.lightTheme has sand bg + no elevation; app_shell.dart wraps bar in Container with top border (line 44) using AppTheme.line — needs change to AppTheme.lineHair per requirement |

</phase_requirements>

---

## Standard Stack

### Core Design System
| Library | Version | Purpose | Verified |
|---------|---------|---------|----------|
| Flutter Material 3 | 3.11+ (useMaterial3: true) | Foundation for ThemeData | ✅ in pubspec.yaml |
| google_fonts | 6.2.1 | Three-family typography (Anton, Manrope, JetBrains Mono) | ✅ in pubspec.yaml |
| AppTheme (custom) | lib/core/theme/app_theme.dart | 224-line static theme + helpers | ✅ verified in codebase |

### Font Files (Exact Filenames — Required for Bundling)

**These filenames must NOT be changed when downloading from Google Fonts:**

| Font Family | Weight | Filename | Source |
|-------------|--------|----------|--------|
| Anton | 400 (Regular) | `Anton-Regular.ttf` | [VERIFIED: GitHub google/fonts](https://github.com/google/fonts/blob/main/ofl/anton/Anton-Regular.ttf) |
| Manrope | 400, 600, 700 | `Manrope[wght].ttf` (variable font) | [VERIFIED: GitHub google/fonts](https://github.com/google/fonts/tree/main/ofl/manrope) |
| JetBrains Mono | 700 | `JetBrainsMono[wght].ttf` (variable font) | [VERIFIED: GitHub google/fonts](https://github.com/google/fonts/tree/main/ofl/jetbrainsmono) |

**Critical discovery:** Manrope and JetBrains Mono are **variable fonts** (indicated by `[wght]` in filename). A single .ttf file supports all weights via the variable font axis — NOT separate files per weight. Anton is static (400 only, no variable variant available).

**File count:** 3 files total, not 5:
- Anton-Regular.ttf (1 file)
- Manrope[wght].ttf (1 variable file covering 400/600/700)
- JetBrainsMono[wght].ttf (1 variable file covering 700)

---

## Architecture Patterns

### Font Asset Discovery in google_fonts 6.2.1

**What:** The google_fonts package automatically scans `pubspec.yaml` assets and matches by filename to local .ttf files before attempting HTTP fetch.

**Pattern:**
```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/google_fonts/  # Must be listed here; package auto-discovers fonts inside
```

**File structure:**
```
assets/
├── google_fonts/
│   ├── Anton-Regular.ttf
│   ├── Manrope[wght].ttf
│   └── JetBrainsMono[wght].ttf
├── images/
```

**How it works:**
1. App calls `GoogleFonts.anton(...)` or `GoogleFonts.manrope(...)` in code
2. google_fonts 6.2.1 checks: "Does `assets/google_fonts/` contain a file matching 'Anton' and weight 400?"
3. If yes → load locally from asset bundle (instant, offline-safe)
4. If no → HTTP fetch from fonts.gstatic.com (200–800ms delay, requires internet)

**Zero code changes required:** The `AppTheme.display()`, `AppTheme.ui()`, `AppTheme.mono()` helpers already call `GoogleFonts.*()` — no modifications needed. Just bundling the files enables local loading automatically.

### Color Audit Pattern

**Grep command to find hardcoded colors:**
```bash
grep -rn "Color(0x" lib/features/booking/ui/ lib/features/admin/ui/
```

**File-by-file audit:**

1. **booking_card.dart** — Verified: NO hardcoded colors found (lines 1–180 already use AppTheme.* tokens)

2. **admin_booking_card.dart** (Community 11 per graph) — **FOUND 16+ hardcoded colors:**
   ```dart
   // Line 21: payment status colors
   ('pending_payment', _) => const Color(0xFFFFC107),      // → AppTheme.sun or similar
   ('confirmed', 'pix') => const Color(0xFF4CAF50),        // → AppTheme.court
   ('confirmed', 'on_arrival') => const Color(0xFF2196F3),
   
   // Lines 32–40: sport background colors (8 colors, old Material palette)
   static const List<Color> _sportBgColors = [
     Color(0xFFE3F2FD), // blue bg       → lighter shade, replace with paper or new token
     Color(0xFFE8F5E9), // green bg
     Color(0xFFFFF3E0), // orange bg
     Color(0xFFF3E5F5), // purple bg
     Color(0xFFFCE4EC), // pink bg
     Color(0xFFE0F7FA), // teal bg
     Color(0xFFF9FBE7), // lime bg
     Color(0xFFFFF8E1), // amber bg
   ];
   
   // Lines 43–50: sport foreground colors (8 colors, old Material palette)
   static const List<Color> _sportFgColors = [
     Color(0xFF1565C0), // blue fg       → AppTheme.ink or primary
     Color(0xFF2E7D32), // green fg      → AppTheme.court
     Color(0xFFE65100), // orange fg     → AppTheme.orange
     Color(0xFF6A1B9A), // purple fg
     Color(0xFFC62828), // red fg        → AppTheme.orangeDk
     Color(0xFF00695C), // teal fg
     Color(0xFF558B2F), // lime fg
     Color(0xFFF57F17), // amber fg      → AppTheme.sun
   ];
   ```
   
   **Mapping strategy:** These 8-color sport arrays are used for sport-specific UI (badges, chips). The current Material colors do NOT align with Arena design palette. **Two options:**
   - **Option A (simpler, Phase 23):** Map each to nearest AppTheme token (court for green, orange for orange, orangeDk for red, sun for amber, ink for dark, etc.)
   - **Option B (Phase 25+, design-driven):** Add 8 new AppTheme constants for sport variants if admin screens require distinct colors per sport
   
   For Phase 23, **use Option A**: Replace with existing tokens. If design conflicts, flag in verify phase.

3. **booking_confirmation_sheet.dart** — **FOUND 10+ hardcoded colors:**
   ```dart
   // Lines 233–277: info banner colors
   color: const Color(0xFFFFF3E0),        // → AppTheme.paper or lighter
   border: Border.all(color: const Color(0xFFFFB300), width: 1),  // → AppTheme.sun or similar
   Icon(Icons.info_outline, size: 18, color: Color(0xFFE65100)), // → AppTheme.orange
   
   // Line 389: cancel action color
   style: const TextStyle(color: Color(0xFFC62828)),  // → AppTheme.orangeDk
   
   // Line 277: divider
   color: const Color(0xFFD0CAC0),  // → AppTheme.line or lineHair
   ```

### NavigationBar Border Token Fix

**File:** `lib/app_shell.dart` line 44

**Current:**
```dart
decoration: const BoxDecoration(
  color: AppTheme.sand,
  border: Border(top: BorderSide(color: AppTheme.line)),  // ← WRONG: too thick
),
```

**Required (NAV-02):**
```dart
decoration: const BoxDecoration(
  color: AppTheme.sand,
  border: Border(top: BorderSide(color: AppTheme.lineHair)),  // ← CORRECT: hairline
),
```

**Why:** `AppTheme.line` (#D9D2BE) is for full dividers. `AppTheme.lineHair` (#EAE3CE) is lighter for hairline borders. The 1px top border of the nav bar should be barely visible (hairline, not divider-weight).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Font loading / HTTP caching | Custom font fetcher | google_fonts 6.2.1 + asset bundling | Handles FOUT, offline, variable font axes, caching; custom logic is fragile |
| Color palette management | Hardcoded Color(0xFF...) scattered in widgets | AppTheme static const colors | Single source of truth; theme changes cascade |
| Theme propagation (tabBar, nav, card, button overrides) | Screen-level Theme.of(context).copyWith() | AppTheme.lightTheme only, no copyWith | copyWith does NOT cascade sub-themes; causes silent desync bugs (Pitfall 1) |
| Sport-specific color variants (admin booking card badges) | Custom color lookup function | AppTheme tokens + potential new sports-palette variant in v7+ | Keep simple in Phase 23; extend later if design requires 8 distinct sport colors |

**Key insight:** google_fonts + asset bundling is transparent — no API changes. Font files are discovered automatically by filename matching. The hardest part is finding all hardcoded colors; the replacement is mechanical.

---

## Common Pitfalls

### Pitfall A: ThemeData.copyWith() Cascade Failure (CRITICAL — already addressed)

**What goes wrong:** Modifying ColorScheme or calling `copyWith()` on the theme in any screen does NOT cascade into sub-themes (navigationBarTheme, cardTheme, tabBarTheme, etc.). They keep old values silently.

**Specific risk:** If a phase modifies AppTheme.lightTheme or adds a local Theme override, nav bar colors, card borders, or tab underlines may render wrong in specific screens.

**Prevention:** 
- Never call `Theme.of(context).copyWith(...)` in any screen. All theme state lives in AppTheme.lightTheme.
- Audit `lib/` for `Theme.of(context).copyWith` or `Theme(data: ...)` — should be zero matches.
- Hardcoded colors bypass theme entirely — they MUST be replaced with AppTheme tokens.

**Detection:** Card renders different color from AppTheme in one screen, correct in another.

**Phase 23 action:** Grep for hardcoded colors (3 files identified) and replace. Do NOT add any new Theme wraps.

---

### Pitfall B: FOUT (Flash of Unstyled Text) — Fonts Not Bundled (HIGH priority)

**What goes wrong:** If font files are NOT in assets/google_fonts/ and NOT listed in pubspec.yaml, google_fonts fetches Anton/Manrope/JetBrains Mono from fonts.gstatic.com at runtime. On first load (cold start), fonts are absent for 200–800ms — Flutter renders with system sans-serif fallback, then re-renders when fonts arrive. Visible layout jump.

**Specific risk for this app:** Anton 42px–88px slot times will render at wrong size with Helvetica/Arial fallback. User sees time in narrow system font, then it jumps to wide Anton. Looks broken.

**Prevention:**
1. Download 3 .ttf files from fonts.google.com (filenames exact, do NOT rename)
2. Place in `assets/google_fonts/`
3. Add to `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/google_fonts/
   ```
4. Do NOT add a `fonts:` section in pubspec.yaml — google_fonts detects assets automatically

**Detection:**
- App renders system font on cold start, jumps to Anton after 200–500ms
- Disable internet in browser devtools → all text stays system font (no jump)
- Network devtools shows HTTP requests to fonts.gstatic.com

**Phase 23 action:** This is a blocking task. Bundle fonts before any screen redesign uses Anton at large sizes.

---

### Pitfall C: Variable Font Weight Parameter Mismatch

**What goes wrong:** Manrope[wght].ttf and JetBrainsMono[wght].ttf are variable fonts. The `[wght]` axis supports weight values 100–900. If code requests a weight outside the variable font's range, or if the variable font file itself is corrupt, the font fails to load.

**Specific risk:** AppTheme.mono() uses `fontWeight: FontWeight.w700` (bold). JetBrainsMono[wght].ttf MUST support weight 700 on its variable axis. If the download is incomplete or wrong, mono text renders in system font.

**Prevention:**
- Verify downloaded files are complete .ttf (not partially downloaded)
- Test in browser after bundling: inspect elements with `AppTheme.mono()` should show JetBrains Mono font family, not fallback
- JetBrains Mono variable font is guaranteed to support 700 (it's part of the Google Fonts release)

**Detection:**
- Mono text (nav labels, status badges) renders in system font instead of monospace
- Browser DevTools → Computed Styles → font-family shows "Helvetica" or fallback, not "JetBrains Mono"

**Phase 23 action:** Download directly from Google Fonts (not from random CDN) to ensure complete files. Verify file sizes are reasonable (~40KB–100KB per file for variable fonts).

---

### Pitfall D: Flutter Web Asset Path Case Sensitivity (MEDIUM risk on Windows)

**What goes wrong:** Windows filesystem is case-insensitive, but Flutter Web build may treat asset paths case-sensitively. If assets are declared as `assets/google_fonts/` but files are in `assets/Google_Fonts/`, the build may succeed locally but fail in production on case-sensitive servers.

**Prevention:**
- Use lowercase path: `assets/google_fonts/` (all lowercase)
- Filename casing must match exactly as downloaded from Google Fonts (Anton-Regular.ttf, Manrope[wght].ttf, etc.)

**Detection:** `flutter build web` succeeds, but web app in staging shows no fonts (404 on asset).

**Phase 23 action:** Create assets/google_fonts/ directory (lowercase) and place files with exact Google Fonts names.

---

### Pitfall E: Hardcoded Colors Bypass Theme (addresses Pitfall 1 — must fix Phase 23)

**What goes wrong:** booking_confirmation_sheet.dart and admin_booking_card.dart contain 16+ hardcoded `Color(0xFF...)` values. These are NOT pulled from AppTheme, so if the palette changes, these widgets stay on old colors.

**Specific issue:** admin_booking_card.dart _sportBgColors and _sportFgColors use 8-color old Material palette (blues, greens, purples from Material.deepBlue, etc.). Arena design system is sand/ink/orange/court/sun — the old colors clash with new theme.

**Prevention:**
- Audit all 3 files with grep before redesign
- Map hardcoded colors to AppTheme tokens:
  - Material blue → ink or secondary (court)
  - Material green → court
  - Material orange → orange
  - Material red → orangeDk
  - Material amber → sun
- For sport-specific colors, decide: use same tokens for all sports (Phase 23 simpler), or add sport variants (Phase 25+ if design requires)

**Detection:**
- admin_booking_card badges render in old Material colors, clash with sand/orange nav bar
- Color name in code is Material-specific (0xFF1565C0 is Material.blue[900])

**Phase 23 action:** Grep for all hardcoded colors, replace with AppTheme tokens. Document sport color decision (single palette vs. per-sport variants).

---

## Runtime State Inventory

Not applicable. Phase 23 is design system integration only — no data model changes, no database migrations, no CLI state changes. All work is code edits (pubspec.yaml, app_shell.dart, booking files) + file copies (fonts).

---

## Code Examples

### Font Asset Loading (Automatic, No Code Change)

```dart
// Source: lib/core/theme/app_theme.dart (existing, no changes)
static TextStyle display({double size = 32, Color? color, double? letterSpacing}) =>
    GoogleFonts.anton(
      fontSize: size,
      color: color ?? ink,
      letterSpacing: letterSpacing ?? 0.5,
      height: 0.92,
    );
```

**How it works after bundling:**
1. `GoogleFonts.anton(...)` is called
2. google_fonts checks `assets/google_fonts/Anton-Regular.ttf` (priority 1)
3. If found → load locally (instant, offline)
4. If not found → HTTP fetch from fonts.gstatic.com (with fallback)

**No code changes required.** The helpers already work; bundling the files just enables fast, offline loading.

---

### Color Token Replacement Pattern

**Example from admin_booking_card.dart:**

**Before (Pitfall E):**
```dart
const List<Color> _sportFgColors = [
  Color(0xFF1565C0), // Material blue
  Color(0xFF2E7D32), // Material green
  Color(0xFFE65100), // Material orange
  Color(0xFFC62828), // Material red
  // ...
];
```

**After (Phase 23):**
```dart
const List<Color> _sportFgColors = [
  AppTheme.ink,       // Replace Material blue with ink (near-black for contrast)
  AppTheme.court,     // Replace Material green with court (success green, same value)
  AppTheme.orange,    // Already correct, Material orange ≈ AppTheme.orange
  AppTheme.orangeDk,  // Replace Material red with orangeDk (darker orange, warning)
  // Remaining 4 colors: TBD based on Phase 25 design (sport variants or reuse tokens)
];
```

**Rationale:** Using AppTheme tokens means if palette changes, all colors update together. No isolated "old colors" hiding in widget files.

---

### NavigationBar Border Fix

**File:** lib/app_shell.dart, line 41–45

**Current (Pitfall):**
```dart
bottomNavigationBar: Container(
  decoration: const BoxDecoration(
    color: AppTheme.sand,
    border: Border(top: BorderSide(color: AppTheme.line)),  // ← Wrong
  ),
  child: NavigationBar(...),
),
```

**Fixed (NAV-02 compliant):**
```dart
bottomNavigationBar: Container(
  decoration: const BoxDecoration(
    color: AppTheme.sand,
    border: Border(top: BorderSide(color: AppTheme.lineHair)),  // ← Correct
  ),
  child: NavigationBar(...),
),
```

**Visual impact:** Line is slightly lighter (#EAE3CE instead of #D9D2BE), more subtle. Hairline token used correctly per design system.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Flutter Test (built-in) + bloc_test 10.0.0 + mocktail 1.0.4 |
| Config file | analysis_options.yaml (linting only; no unit test config) |
| Quick run | `flutter analyze` (~5–10 sec) |
| Full run | `flutter build web` (~1–3 min depending on cache) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | Existing? |
|--------|----------|-----------|-------------------|-----------|
| DS-01 | AppTheme.lightTheme contains all color tokens | Manual (code inspection) | Read lib/core/theme/app_theme.dart lines 8–22 | ✅ N/A (not code-testable) |
| DS-02 | display(), ui(), mono() helpers exist and call GoogleFonts | Manual (code inspection) | Read lib/core/theme/app_theme.dart lines 25–46 | ✅ N/A |
| DS-03 | TextStyle helpers configured with font family + size + color | Manual (code inspection) | grep "GoogleFonts\\.anton\\|GoogleFonts\\.manrope\\|GoogleFonts\\.jetBrainsMono" lib/ | ✅ N/A |
| DS-04 | tabBarTheme, navigationBarTheme, cardTheme have correct tokens | Manual (code inspection) | Read lightTheme lines 83–222 in app_theme.dart | ✅ N/A |
| NAV-01 | NavigationBar labels uppercase in mono + orange selected | Manual visual | flutter run -d chrome, tap nav items, observe label font + color | ❌ Wave 0 |
| NAV-02 | NavigationBar top border is hairline (not thick divider) | Code inspection | grep "AppTheme.line\>" lib/app_shell.dart; should return 0 (all lineHair) | ❌ Wave 0 (test after fix) |
| Fonts bundled | Assets/google_fonts/ exists with 3 .ttf files | File existence | ls -la assets/google_fonts/ | ❌ Wave 0 |
| pubspec.yaml updated | assets/google_fonts/ listed in flutter.assets | Code inspection | grep "google_fonts" pubspec.yaml | ❌ Wave 0 |
| Hardcoded colors replaced | No Color(0xFF...) in 3 booking files (except ALLOWED patterns) | Code inspection | grep "Color(0x" lib/features/booking/ui/booking_card.dart lib/features/booking/ui/booking_confirmation_sheet.dart lib/features/admin/ui/admin_booking_card.dart; should be 0 | ❌ Wave 0 |
| flutter analyze zero warnings | No warnings from dart analyzer | Integration | `flutter analyze 2>&1 \| grep -i warning` should return 0 | ❌ Verify |
| flutter build web success | Web build completes without errors | Integration | `flutter build web` should exit code 0 | ❌ Verify |

### Sampling Rate
- **Per task commit:** `flutter analyze` (checks for linting issues introduced in editing)
- **Per wave merge (Phase 23 completion):** `flutter build web` + `flutter analyze` (full integration test)
- **Gate criterion:** Zero warnings in `flutter analyze`, build web completes with exit code 0

### Wave 0 Gaps
- [ ] assets/google_fonts/ directory (created by planner, populated with 3 .ttf files)
- [ ] pubspec.yaml `assets:` section updated with `- assets/google_fonts/`
- [ ] pubspec.yaml `fonts:` section left empty (not needed for google_fonts asset bundling)
- [ ] Manual visual test of nav bar + app launch (flutter run -d chrome) to verify fonts load + colors correct
- [ ] Test coverage: existing 20 test files (per glob scan) are for BLoC + models, NOT for theme/UI widgets
  - No widget tests for AppTheme, AppShell, or NavigationBar exist
  - Phase 23 is NOT adding widget tests (none required by REQUIREMENTS.md)
  - Widget visual verification is manual (flutter run chrome) — acceptable per design-driven context

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Build + analyze | ✅ | 3.11.3+ (from pubspec.yaml) | — |
| Dart SDK | Bundled with Flutter | ✅ | 3.11.3+ | — |
| google_fonts | Font loading | ✅ | 6.2.1 (pubspec.yaml) | HTTP fetch (slower, requires internet) |
| Internet (for fonts.gstatic.com) | HTTP font fetch only | ✅ (assumed) | — | Asset bundling (Phase 23 goal) |
| Browser (Chrome/Chromium) | Web testing (flutter run -d chrome) | ✅ (assumed) | Latest | Use different browser, or test via build artifact |

**Critical dependency:** Fonts MUST be bundled for offline-first behavior (Pitfall B). If internet is unavailable during app first run, fonts will not load without this phase.

**No blockers:** All tools are available. Phase can proceed immediately.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hardcoded `Color(0xFF...)` in widgets | AppTheme static const + helpers | v6.0 (current) | Single source of truth; palette changes apply globally |
| Material default palette (green/amber) | Arena sport palette (sand/ink/orange/court/sun) | v6.0 (FEATURES.md) | Cohesive visual identity; design system maturity |
| Runtime HTTP font fetch (FOUT) | Offline asset bundling (Phase 23) | 2026-05 | Fast cold starts, works offline, eliminates 200–800ms delay |
| Generic `Card` widgets with shadow | Zero-elevation cards with hairline borders | v6.0 (app_theme.dart) | Scoresheet aesthetic; reduced visual clutter |
| No typography system | 3 static helpers (display, ui, mono) | v6.0 (app_theme.dart) | Consistent font usage; Anton for display, Manrope for UI, Mono for labels |

**Deprecated/outdated:**
- Material green palette (pre-v6.0) — replaced by sport colors
- ChoiceChip for day selection (pre-v6.0) — replaced by DayChipRow (already done in prior session)
- Inline Theme overrides (never used in this codebase) — centralized in AppTheme.lightTheme only

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | google_fonts 6.2.1 auto-discovers .ttf files in assets/ by filename matching | Architecture Patterns | If matching fails, fonts revert to HTTP fetch; app shows FOUT on cold start |
| A2 | Manrope[wght].ttf and JetBrainsMono[wght].ttf are downloadable as single variable font files from Google Fonts | Standard Stack (Fonts) | If variable fonts unavailable, must download 5+ separate weight files; folder bloats; asset bundling complexity increases |
| A3 | sport colors in admin_booking_card.dart can be mapped to existing AppTheme tokens without design conflict | Common Pitfalls (Pitfall E) | If design explicitly requires 8 distinct sport colors, mapping to single palette will look wrong; redesign may need sport-palette extension (Phase 25+) |
| A4 | flutter analyze will pass zero-warnings with hardcoded colors replaced by AppTheme tokens | Validation Architecture | If new warnings appear after replacement, task must debug linter config or type mismatches |
| A5 | assets/google_fonts/ directory name is exact string expected by google_fonts package | Common Pitfalls (Pitfall D) | If package looks for different path (e.g., `google_fonts_assets/`), files won't be discovered; app reverts to HTTP fetch |

**User confirmation needed:** A3 (sport color mapping) — if design requires 8 specific colors per sport, this assumption fails. Flag in verify phase.

---

## Open Questions

1. **Sport color variants (admin_booking_card.dart _sportBgColors / _sportFgColors)**
   - What we know: 8 colors coded for sport-specific badges. Current colors are old Material palette.
   - What's unclear: Does the Arena design system define specific colors per sport (8 variants), or is single palette acceptable?
   - Recommendation: Phase 23 uses single AppTheme palette (assumption A3). If design requires sport variants, add new AppTheme constants in Phase 25 admin redesign. Flag in verify-work if colors look wrong on staging.

2. **Exact download source for .ttf files**
   - What we know: Files exist in Google Fonts GitHub and fonts.google.com
   - What's unclear: Should planner download from Google Fonts site UI, GitHub raw links, or Google Fonts API?
   - Recommendation: Use fonts.google.com specimen pages (Anton, Manrope, JetBrains Mono) — most reliable, verified URLs. GitHub is backup.

3. **Flutter Web asset path on production (Firebase Hosting)**
   - What we know: assets/google_fonts/ is lowercase; should be case-sensitive safe
   - What's unclear: Will Firebase Hosting serve assets/google_fonts/ with correct MIME type for .ttf?
   - Recommendation: After Phase 23 build, test staging deploy to verify fonts load (no 404s in Network tab). This is a verify-phase gate.

---

## Security Domain

**Applicable:** This phase is design system + assets only — no authentication, network calls, or user data handling. Security is LOW risk.

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | No | N/A |
| V3 Session Management | No | N/A |
| V4 Access Control | No | N/A |
| V5 Input Validation | No | N/A (fonts are static assets, not user input) |
| V6 Cryptography | No | N/A |

**Known non-issues:**
- Font files are static, public assets (same as Material Icons)
- No secrets or sensitive data in pubspec.yaml or app_theme.dart
- google_fonts package is Google-published, audited, safe

---

## Sources

### Primary (HIGH confidence)
- **GitHub google/fonts** — Direct verification of exact filenames: [Anton-Regular.ttf](https://github.com/google/fonts/blob/main/ofl/anton/Anton-Regular.ttf), [Manrope variable](https://github.com/google/fonts/tree/main/ofl/manrope), [JetBrains Mono variable](https://github.com/google/fonts/tree/main/ofl/jetbrainsmono)
- **pub.dev google_fonts 6.2.1** — Asset bundling documentation and discovery mechanism
- **Codebase inspection** — app_theme.dart (224 lines, verified 2026-05-25), app_shell.dart, booking_card.dart, admin_booking_card.dart, pubspec.yaml
- **Flutter official docs** — [Building a web app](https://docs.flutter.dev/platform-integration/web/building), [Themes](https://docs.flutter.dev/cookbook/design/themes)

### Secondary (MEDIUM confidence)
- **pub.dev google_fonts changelog** — Version history, asset bundling features
- **Flutter GitHub issues** — [NavigationBar missing overlayColor (#138850)](https://github.com/flutter/flutter/issues/138850), [google_fonts WASM asset bug (#159375)](https://github.com/flutter/flutter/issues/159375)

### Tertiary (LOW confidence — flagged for validation)
- WebSearch results on Google Fonts naming conventions (cross-verified with GitHub, HIGH confidence elevated)

---

## Metadata

**Confidence breakdown:**
- **Standard stack (font filenames):** HIGH — GitHub google/fonts verified directly
- **Font discovery mechanism:** MEDIUM-HIGH — pub.dev docs clear, but not tested in this codebase (verification gate in Wave 0)
- **Color audit (pitfalls):** HIGH — grep verified 16+ hardcoded colors in exact files, mapping is straightforward
- **NavigationBar fix:** HIGH — code verified, change is mechanical
- **Architecture (asset structure):** HIGH — google_fonts pattern is documented and used in many Flutter apps

**Research date:** 2026-05-25
**Valid until:** 2026-06-01 (7 days; fast-moving: Flutter SDK updates could affect Web font loading)

# Architecture: Flutter Design System Integration — v6.0 Arena Esportivo

**Project:** Vida Ativa — Visual Redesign
**Date:** 2026-05-23
**Confidence:** HIGH (direct codebase inspection)

---

## Current State Audit

### What Already Exists (No Work Needed)

`AppTheme.lightTheme` is already a **full Material 3 ThemeData replacement** — not partial, not a copyWith. It defines:
- Complete `ColorScheme` with all Arena Esportivo tokens (sand, ink, orange, court, etc.)
- `textTheme` via `GoogleFonts.manropeTextTheme()`
- `tabBarTheme` with underline orange 2px indicator and mono labels
- `navigationBarTheme` with orange/concrete icons + mono labels
- `cardTheme`, `filledButtonTheme`, `outlinedButtonTheme`, `inputDecorationTheme`, `switchTheme`, `snackBarTheme`, `chipTheme`, `floatingActionButtonTheme`, `checkboxTheme`, `progressIndicatorTheme`
- Static helpers: `AppTheme.display()`, `AppTheme.ui()`, `AppTheme.mono()`

`main.dart` feeds `AppTheme.lightTheme` directly to `MaterialApp.router(theme:)`. One assignment. Global scope.

`AppSpacing` — xs/sm/md/lg/xl — used correctly in several files. No changes needed.

### What Has NOT Been Updated (The Actual Work)

Widgets across features still use **hardcoded pre-Arena colors and TextStyles** that bypass the theme:

| Widget | Problem |
|--------|---------|
| `SlotCard` | `TextStyle(fontSize: 16, fontWeight: FontWeight.w600)` — no Anton; `Colors.grey`, `Color(0xFFE53935)` hardcoded status colors; `Card` wrapper with `BorderRadius.circular(8)` |
| `DayChipRow` | `ChoiceChip` with `selectedColor: AppTheme.primaryGreen`; custom `TextStyle` with hardcoded hex colors; not the new underline-column pattern |
| `BookingCard` | `Card` with `BorderRadius.circular(12)`; hardcoded `Color(0xFF1565C0)`, `Color(0xFF9E9A95)` etc.; no font family on text |
| `BookingConfirmationSheet` | `OutlineInputBorder` with `BorderRadius.circular(12)` overrides theme; payment banner `Color(0xFFFFF3E0)`; buttons with custom `shape: RoundedRectangleBorder(borderRadius: circular(12))` |
| `AdminBookingCard` | Hardcoded sport chip color palettes (`_sportBgColors`, `_sportFgColors` arrays with 8 Material colors); action buttons use `AppTheme.primaryGreen` |
| `AdminScreen` | `_NotificationBanner` uses `AppTheme.primaryGreen` background; AppBar action uses `foregroundColor: AppTheme.primaryGreen` |
| `MyBookingsScreen` | Section headers use plain `TextStyle(fontSize: 18, fontWeight: FontWeight.bold)` — no mono/Anton |

---

## Architecture Decisions

### 1. ThemeData.copyWith vs Full Replacement

**Full replacement — already done.** `AppTheme.lightTheme` is the complete ThemeData object. It is wired once in `main.dart`:

```dart
MaterialApp.router(theme: AppTheme.lightTheme)  // single source of truth
```

There is no scenario requiring `ThemeData.copyWith` for this milestone. The theme already contains every Material component override needed. **Never use `Theme(data: Theme.of(context).copyWith(...))` inside a widget subtree** — it creates invisible local overrides that survive global theme updates and make future refactoring opaque.

The only legitimate `copyWith` scenario: a third-party library widget (e.g., `fl_chart`, `flutter_heatmap_calendar`) reads `Theme.of(context)` and needs local scoping. Even then, wrap only that specific library widget.

### 2. Static TextStyle Helpers in AppTheme vs Separate Class

**Keep in AppTheme. Already done correctly.** `AppTheme.display()`, `AppTheme.ui()`, `AppTheme.mono()` are the right pattern because:
- Design tokens (colors + typography) belong to the same concern
- Already imported everywhere via `app_theme.dart` — zero extra imports
- Named parameters (`size:`, `color:`, `weight:`, `letterSpacing:`) provide typed flexibility without explosion of methods

Do NOT create a separate `AppTypography` class. It adds a file and import for zero semantic gain.

**Exception:** If a new bespoke compound widget (e.g., `SportBtn`, `ScoreboardTime`) has internal text styles that are always fixed to the component contract, inline them at the widget level. They are not reusable design tokens.

### 3. Widget Restyling Order — Maximum Visual Impact

Order by `(user-visible surface area) x (implementation risk)`. High impact and low risk goes first.

#### Phase A — Foundation (every screen, every user)
Touches: navigation shell + AppBar structure. All users see immediately.

1. **BottomNavigationBar** — verify the shell uses `NavigationBar` (Material 3) not `BottomNavigationBar`. The `navigationBarTheme` is already configured. If using the old widget, swap it; otherwise the theme handles everything.
2. **AppBar color fixes** — `AdminScreen` AppBar action `foregroundColor: AppTheme.primaryGreen` → `AppTheme.orange`. `AdminScreen._NotificationBanner` background → orange left-border container pattern.

#### Phase B — Client Schedule (highest user traffic, biggest visual change)
Touches: 3 self-contained widget files. No BLoC changes.

3. **DayChipRow → SportDayStrip** — Full widget rewrite. Replace `ChoiceChip` with column layout: mono abbreviation + Anton number + orange 2px underline. Same callback interface `ValueChanged<DateTime>`.
4. **SlotCard → SlotHairlineRow** — Remove `Card` wrapper. `InkWell` + `Divider` hairline. Time in `AppTheme.display(size: 42)`. Orange 3px left strip for `myBooking`. Opacity 0.45 for `booked`.
5. **ScheduleScreen AppBar** — Replace `Icon + Text('Agenda')` with wordmark `"VIDA ATIVA"` in Anton + orange pill. Add mono eyebrow with selected date.

#### Phase C — Booking Flow (second most-used by clients)
Touches: 2 widget files. Moderate complexity due to form overrides.

6. **BookingConfirmationSheet** — Delete `OutlineInputBorder` overrides on `TextField` and `DropdownButtonFormField` (let theme `UnderlineInputBorder` win). Replace payment warning `Container` (amber background + border) with orange left-border container. Replace `FilledButton`/`OutlinedButton` with local `shape: StadiumBorder()` conforming to theme. Time display → `AppTheme.display(size: 88)`.
7. **MyBookingsScreen + BookingCard** — Section headers → `AppTheme.mono()` uppercase tracked. First upcoming booking → Anton 72px hero row. `BookingCard`: remove `Card` widget, replace with `InkWell` + hairline `Divider`, status pills in mono uppercase.

#### Phase D — Admin Panel (admin-only, lower traffic)
Touches: 5+ widget files. Lower user impact, no BLoC changes.

8. **AdminScreen structure** — Add wordmark + eyebrow "Painel admin". TabBar already configured in theme (underline orange, mono labels) — just verify `Tab` text is uppercase.
9. **AdminBookingCard** — Delete `_sportBgColors`/`_sportFgColors` arrays. Sport chip → `AppTheme.ink`/`AppTheme.orange` system. Action buttons → pill pattern (outlined, no filled background).
10. **SlotManagementTab** — Slot rows → hairline + `AppTheme.display(size: 32)` for time. Orange color for reserved slots.
11. **UsersManagementTab** — Avatar: `AppTheme.orange` for admin, `AppTheme.ink` for user. Rows hairline, name in `AppTheme.ui(weight: FontWeight.w700)`, email in `AppTheme.mono()`.
12. **PricingTab** — Timeline bar 3px orange. Price in `AppTheme.display(size: 44)`. SportBtn for save button.
13. **SettingsTab** — Switch already themed. Underline fields already themed. Labels → `AppTheme.mono()` uppercase.
14. **DashboardTab** — KPI grid: remove card shadows, hairline borders, `AppTheme.display(size: 32)` for values, mono for labels. Bar chart: no rounded corners. Heatmap: orange intensity scale.

### 4. Migration Strategy — All at Once vs Screen by Screen

**Screen by screen, Phases A → B → C → D.** Ship A+B as one unit (most visible), C alone, D as the final unit.

Rationale:
- `AppTheme.lightTheme` is already global and correct. The migration is purely per-widget `build()` rewrites.
- Each widget file is self-contained. Cross-feature regression is impossible because BLoC state is unchanged.
- BLoC/Cubit classes, model classes, Firestore calls, and navigation logic are **zero-change** — visual work lives exclusively in `*/ui/*.dart` files.

**Warning:** Do not do a global replace of `primaryGreen` → `orange`. Some `court` (green) usages are semantically correct and must stay green (e.g., confirmed booking success state in `BookingCard._statusColor('confirmed')`).

---

## Component Boundary Map

### New Components to Create

These do not exist and must be written from scratch:

| Component | File Path | Purpose |
|-----------|-----------|---------|
| `SportDayStrip` | `lib/features/schedule/ui/sport_day_strip.dart` | Replaces DayChipRow. Column per day: mono abbrev + Anton number + orange 2px underline. Same `ValueChanged<DateTime>` callback. |
| `SlotHairlineRow` | `lib/features/schedule/ui/slot_hairline_row.dart` | Replaces SlotCard body. Hairline divider row, no Card. Anton 42px time, orange left strip for myBooking, 0.45 opacity for booked. |
| `SportBtn` | `lib/core/widgets/sport_btn.dart` | Reusable button: Anton uppercase, `StadiumBorder`, no text wrap. Two variants: filled (orange) and outlined (ink). |
| `HairlineBookingRow` | `lib/features/booking/ui/hairline_booking_row.dart` | Replaces BookingCard body. Anton date + mono eyebrow + status pill. Used in MyBookingsScreen. |

### Modified Components (Same Constructor Interface)

| Component | File | Change Scope |
|-----------|------|-------------|
| `DayChipRow` | schedule/ui/day_chip_row.dart | Internal `build()` full rewrite (or rename → `SportDayStrip` and delete old file) |
| `SlotCard` | schedule/ui/slot_card.dart | Internal `build()` rewrite — Card removed, Anton time, opacity |
| `BookingCard` | booking/ui/booking_card.dart | Card removed, hairline, status pills in mono |
| `BookingConfirmationSheet` | booking/ui/booking_confirmation_sheet.dart | Banner → left-border; buttons → StadiumBorder; time → display(88) |
| `MyBookingsScreen` | booking/ui/my_bookings_screen.dart | Headers → mono uppercase; hero "Próximo" section |
| `AdminScreen` | admin/ui/admin_screen.dart | Action button color; notification banner |
| `AdminBookingCard` | admin/ui/admin_booking_card.dart | Sport chip colors → AppTheme tokens; buttons → pills |

---

## BLoC Safety Contract

Files that are zero-change during v6.0:

- All `features/*/cubit/*.dart` — state logic unchanged
- All `core/models/*.dart` — data models unchanged
- `core/router/app_router.dart` — routing unchanged
- `main.dart` — ThemeData already wired
- `lib/firebase_options*.dart` — environment config
- `functions/` — Cloud Functions unchanged
- `AppSpacing` — token values unchanged

If any PR for v6.0 modifies a cubit file, it is out of scope and must be rejected.

---

## Anti-Patterns

### 1. Local Theme Override via `Theme(data: copyWith)`
Creates invisible local overrides. Hard to debug. Breaks on global theme changes.
**Instead:** reference `AppTheme.*` constants directly in the widget.

### 2. Hardcoded `Color(0xFF...)` in Widget Files
Any hex literal that is not part of a legacy status-mapping function is tech debt.
**Instead:** use `AppTheme.orange`, `AppTheme.ink`, `AppTheme.concrete`, etc.

### 3. Overriding Theme `InputDecoration` Shape
`BookingConfirmationSheet` currently overrides with `OutlineInputBorder(borderRadius: circular(12))`. This defeats the global `UnderlineInputBorder` in the theme.
**Instead:** delete the override. The theme handles it.

### 4. Adding Style State to ViewModel or Model
Visual variants (e.g., "is this the hero/next booking?") must be derived from existing model fields inside `build()`. Do not add `isHero: bool` to `BookingModel` or `SlotViewModel`.

### 5. Breaking `ScheduleCubit.selectDay()` Contract
`ScheduleScreen` calls `context.read<ScheduleCubit>().selectDay(day)` via the `onDaySelected` callback from `DayChipRow`. When rewriting `SportDayStrip`, preserve the exact same callback: `ValueChanged<DateTime> onDaySelected`. Do not lift selection state into the new widget.

### 6. Semantic Green vs Accent Orange Confusion
`AppTheme.court` (green `0xFF1B5E2A`) = success/confirmed. `AppTheme.orange` = accent/primary action.
- Confirmed booking status badge → `court`
- Active tab / selected day / primary button → `orange`
Do not unify them.

---

## Confidence Assessment

| Area | Confidence | Basis |
|------|------------|-------|
| ThemeData structure | HIGH | Direct read of `app_theme.dart` |
| Widget file inventory | HIGH | Full file enumeration + read of all key files |
| BLoC boundaries | HIGH | All cubit files enumerated; no style code in any cubit |
| Visual impact ordering | HIGH | Requirements file + screen traffic analysis |
| Migration risk | HIGH | Widgets are pure `build()` functions; state in cubits is untouched |

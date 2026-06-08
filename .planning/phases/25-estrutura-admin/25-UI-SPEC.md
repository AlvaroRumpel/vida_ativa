---
phase: 25
slug: estrutura-admin
status: draft
tool: flutter-apptheme
preset: none
created: 2026-05-27
---

# Phase 25 — UI Design Contract: Estrutura Admin

> Visual and interaction contract for admin frame redesign (header, TabBar, notification banners). Applied via widget-level builds only — zero AppTheme changes.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Flutter AppTheme (existing) |
| Design system | Arena Esportivo (v6.0) |
| Preset | Not applicable — inline tokens only |
| Component library | Flutter Material 3 |
| Icon library | Material Icons |
| Font | Anton (display), Manrope (UI), JetBrains Mono (mono labels) |

**Source of truth:** `lib/core/theme/app_theme.dart` — Phase 23 (verified, no changes)

---

## Spacing Scale

Declared values (all existing, no new tokens):

| Token | Value | Usage in Phase 25 |
|-------|-------|-------------------|
| xs | 4px | Border width (orange stripe 2px = 2×xs) |
| sm | 8px | Internal gaps in header lines, banner padding |
| md | 16px | Header padding horizontal, vertical gaps |
| lg | 24px | Not used in this phase |
| xl | 32px | Not used in this phase |
| 2xl | 48px | Not used in this phase |
| 3xl | 64px | Not used in this phase |

**Exceptions:** Border stripe exactly 2px (override via inline `BorderSide(width: 2)`).

---

## Typography

| Role | Size | Weight | Font | Line Height | Usage in Phase 25 |
|------|------|--------|------|-------------|-------------------|
| Display (wordmark) | 18px | 400 | Anton | 0.92 | "VIDA" + "ATIVA" in header line 1 |
| Mono (labels) | 10px | 700 | JetBrains Mono | auto | TabBar labels (UPPERCASE), eyebrow "PAINEL ADMIN", link "cliente →" |
| Mono (eyebrow) | 10px | 700 | JetBrains Mono | auto | "PAINEL ADMIN" header line 2 |
| Mono (link) | 11px | 700 | JetBrains Mono | auto | "cliente →" header line 1 right, orange colored |

**No new font sizes needed.** All text uses existing `AppTheme.display()`, `AppTheme.mono()` helpers. Letter spacing auto-calculated per helper definition.

---

## Color

All colors pre-existing from Phase 23:

| Role | Hex | Token | Usage in Phase 25 |
|------|-----|-------|-------------------|
| Dominant (60%) | #F4EFE2 | `AppTheme.sand` | Scaffold background, header background, TabBar background |
| Secondary (30%) | #FBFBF0 | `AppTheme.paper` | "ATIVA" pill background, action button text |
| Primary text | #0E0E0C | `AppTheme.ink` | "VIDA" text, "PAINEL ADMIN" text, TabBar selected label |
| Dim text | #6B6B66 | `AppTheme.concrete` | TabBar unselected label, "cliente →" secondary |
| Divider (thin) | #EAEBE3 | `AppTheme.lineHair` | TabBar bottom border (override `dividerColor`) |
| Accent/Action | #FF4D17 | `AppTheme.orange` | Orange stripe (left border of banners), TabBar underline indicator 2px, "cliente →" text |

**Accent reserved for:**
- Orange underline indicator (TabBar selected state)
- Orange left stripe in notification banners (2px width)
- "cliente →" link text (header line 1)

---

## Copywriting Contract

| Element | Copy | Context |
|---------|------|---------|
| Header line 1 left | "VIDA ATIVA" | Wordmark: "VIDA" in ink, "ATIVA" in pill orange background |
| Header line 1 right | "cliente →" | Link text, nav to `/home`, orange colored, JBM mono |
| Header line 2 left | "PAINEL ADMIN" | Eyebrow, JBM mono uppercase, concrete color (discretion: could be ink for higher contrast) |
| TabBar labels | "DASHBOARD", "SLOTS", "BLOQUEIOS", "RESERVAS", "USUÁRIOS", "PREÇOS", "AJUSTES" | All UPPERCASE in code (no CSS text-transform) |
| Notification banner (FCM permission) | "Ative as notificações para receber alertas de novas reservas." | Faixa laranja 2px left, no background color |
| Notification banner (new booking) | "{title}\n{body}" | From FCM message, faixa laranja 2px left, auto-dismiss 5s |
| Banner button (FCM permission) | "Ativar" | TextButton, calls `AdminFcmCubit.requestPermission()` |
| Banner button (new booking) | "Ver" | TextButton, navigates to Reservas tab (index 3) |

---

## Visual Structure — Header

**Phase 25 removes AppBar entirely.** Inline header with 2 lines:

```
Line 1 (Row):
  [VIDA {ATIVA-pill}] ____________ [cliente →]
  └─ "VIDA" = AppTheme.display(18px, ink)
  └─ "ATIVA" = pill [orange rect, 6px horiz pad, 2px vert pad, borderRadius 4] + Text(AppTheme.display(18px, paper))
  └─ Spacer in middle
  └─ "cliente →" = GestureDetector → context.go('/home') = AppTheme.mono(11px, orange)

Line 2 (Row):
  [PAINEL ADMIN] __________ [empty / future use]
  └─ "PAINEL ADMIN" = AppTheme.mono(10px, concrete/ink — discretion)

Spacing:
  - Horizontal padding: 16px (EdgeInsets.symmetric(horizontal: 16))
  - Vertical padding: 8px
  - Gap between lines 1 & 2: 2px (SizedBox height)
  - Gap between "VIDA" and pill: 4px
```

**Wrapper:** `SafeArea(bottom: false, child: Padding(...))`

---

## Visual Structure — TabBar

**Moved from AppBar.bottom to body Column, below header.** Properties:

- **Controller:** `_tabController` (length: 7)
- **Scrollable:** `isScrollable: true` (needed for 7 tabs on mobile)
- **Labels:** JetBrains Mono, 10px, weight 700, UPPERCASE, letter-spacing 1.6
- **Selected label color:** `AppTheme.ink`
- **Unselected label color:** `AppTheme.concrete`
- **Indicator:** `UnderlineTabIndicator(borderSide: BorderSide(color: AppTheme.orange, width: 2))`
- **Indicator size:** `TabBarIndicatorSize.tab`
- **Divider color:** `AppTheme.lineHair` (override default `line` via inline `dividerColor` parameter)
- **Background:** inherits `scaffoldBackgroundColor: sand` from Scaffold

**Important:** All Tab texts MUST be UPPERCASE in code (Flutter has no text-transform CSS).

---

## Visual Structure — Notification Banners

### FCM Permission Banner (_NotificationBanner restyled)

**Current state:** Container with green background.

**Redesign:** Remove background color. Use left stripe pattern.

```
Layout:
  IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Stripe
        Container(width: 2, color: AppTheme.orange),
        SizedBox(width: 12),
        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(Icons.notifications_outlined, size: 18, color: AppTheme.ink),
                SizedBox(width: 8),
                Expanded(
                  child: Text("Ative as notificações...", style: AppTheme.ui(size: 13)),
                ),
                TextButton(
                  onPressed: onEnable,
                  child: Text("Ativar"),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  )
```

**Color:** No background color. Inherits sand from Scaffold. Stripe is orange 2px.

---

### New Booking Inline Banner

**Current state:** SnackBar via `ScaffoldMessenger.showSnackBar()`.

**Redesign:** Inline widget in body Column, controlled by `String? _pendingMessage` state.

```
Layout:
  if (_pendingMessage != null)
    IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 2, color: AppTheme.orange),
          SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_pendingMessage!, style: AppTheme.ui(size: 13)),
                  ),
                  TextButton(
                    onPressed: _goToReservas,
                    child: Text("Ver", style: AppTheme.mono(size: 11, color: AppTheme.ink)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
```

**Auto-dismiss:** 5 seconds via `Timer` from `dart:async`.

```dart
String? _pendingMessage;
Timer? _bannerTimer;

_fcmCubit.onForegroundMessage.listen((message) {
  if (!mounted) return;
  final title = message.notification?.title ?? 'Nova Reserva';
  final body = message.notification?.body ?? '';
  setState(() => _pendingMessage = '$title\n$body');
  _bannerTimer?.cancel();
  _bannerTimer = Timer(const Duration(seconds: 5), () {
    if (mounted) setState(() => _pendingMessage = null);
  });
});

// In dispose():
_bannerTimer?.cancel();
```

---

## Body Column Structure

```dart
Scaffold(
  body: SafeArea(
    bottom: false,
    child: Column([
      // 1. Header inline (2 lines)
      _AdminHeader(),
      
      // 2. TabBar (sticky at top)
      TabBar(controller: _tabController, ...),
      
      // 3. Notification banners (conditional)
      if (_pendingMessage != null) _InlineBookingBanner(...),
      BlocBuilder<AdminFcmCubit, AdminFcmState>(
        builder: (context, state) => 
          state is AdminFcmPermissionRequired
            ? _NotificationBanner(onEnable: ...)
            : SizedBox.shrink(),
      ),
      
      // 4. Tab content (expanded)
      Expanded(
        child: TabBarView(controller: _tabController, children: [
          DashboardTab(),
          SlotManagementTab(),
          BlockedDatesTab(),
          BookingManagementTab(),
          UsersManagementTab(),
          PricingTab(),
          SettingsTab(),
        ]),
      ),
    ]),
  ),
)
```

---

## Interaction Contract

| Interaction | Behavior | Target |
|-------------|----------|--------|
| Header "cliente →" link | Tap → navigate to `/home` | `context.go('/home')` |
| FCM permission "Ativar" button | Tap → request FCM permissions | `AdminFcmCubit.requestPermission()` |
| New booking banner "Ver" button | Tap → scroll TabBar to Reservas (index 3) | `_tabController.animateTo(3)` |
| New booking banner | Auto-dismiss after 5 seconds | `Timer(Duration(seconds: 5), ...)` |
| TabBar tab | Tap → scroll to corresponding TabView | `TabController` handles animation |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| Material 3 (Flutter native) | AppBar, TabBar, TabBarView, UnderlineTabIndicator, TextButton, Icon, Row, Column, Scaffold, SafeArea | Not required — native Flutter |
| google_fonts | Anton 400, Manrope 400, JetBrains Mono 700 | Already verified Phase 23; fonts bundled in assets/google_fonts/ |
| flutter_bloc | BlocProvider, BlocBuilder, AdminFcmCubit | Existing, no new blocks |
| go_router | `context.go('/home')` | Existing, no new blocks |
| dart:async | Timer | Standard library, no vetting required |

**No third-party component registries involved.** Phase 25 is pure Flutter Material + existing cubits.

---

## Requirements Traceability

| Requirement | Phase 25 Contract | Verified |
|-------------|-------------------|----------|
| ADMN-13: TabBar underline orange 2px, JBM uppercase, fondo sand | UnderlineTabIndicator(borderSide: orange 2px), labelStyle JBM 10/700 uppercase, inherits sand | ✓ |
| ADMN-14: Header wordmark + eyebrow + link "cliente →" orange | 2-line header: VIDA pill ATIVA + PAINEL ADMIN + cliente → (orange) | ✓ |
| ADMN-15: Notification banner faixa laranja 2px (no background) | IntrinsicHeight + Row + Container(width:2, orange), no background color | ✓ |

---

## Implementation Checklist

- [ ] **Header:** SafeArea + Column with 2 Row layouts
- [ ] **Header line 1:** "VIDA" ink + pill orange "ATIVA" + Spacer + GestureDetector "cliente →"
- [ ] **Header line 2:** Text "PAINEL ADMIN" mono concrete/ink
- [ ] **TabBar:** Moved to Column body, below header; 7 tabs UPPERCASE; dividerColor override to lineHair
- [ ] **_NotificationBanner:** Restyled to IntrinsicHeight + stripe pattern; background removed
- [ ] **FCM message listener:** Removes SnackBar; calls `setState(() => _pendingMessage = ...)`
- [ ] **Inline banner:** if (_pendingMessage != null), IntrinsicHeight + stripe + auto-dismiss Timer
- [ ] **dispose():** Added `_bannerTimer?.cancel()`
- [ ] **No changes:** AppTheme, tab widgets, BLoCs, routing

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS

**Approval:** pending

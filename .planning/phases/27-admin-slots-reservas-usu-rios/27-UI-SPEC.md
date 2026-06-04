---
phase: 27
slug: admin-slots-reservas-usuarios
status: draft
shadcn_initialized: false
design_system: AppTheme
created: 2026-06-04
---

# Phase 27 — UI Design Contract
Admin Slots + Reservas + Usuários

> Visual and interaction contract for redesigning admin UI tabs with hairline rows, bottom sheets, and Arena Esportivo identity. Consumed by gsd-planner and gsd-executor.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | None (Flutter + AppTheme) |
| Preset | not applicable |
| Theme | AppTheme (`lib/core/theme/app_theme.dart` Phase 23) |
| Typography | Google Fonts: Anton, Manrope, JetBrains Mono |
| Icon library | Material Icons (Flutter built-in) |
| Build framework | Flutter 3.11+ (Material 3 stable) |

---

## Spacing Scale

Declared values (multiples of 4):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Hairline border width (0.5px as division) |
| sm | 8px | Compact gaps, row vertical padding |
| md | 16px | Default horizontal padding in rows |
| lg | 24px | Section spacing, avatar gaps |
| xl | 32px | Major section breaks |
| 2xl | 48px | Page-level spacing |
| 3xl | 64px | Full page margins |

**Row-specific spacing (locked):**
- Horizontal padding: **16px** (both sides, confirmed Phase 26 pattern)
- Vertical padding: **8px** (row height, compact hairline rows, confirmed Phase 26 pattern)
- Avatar circular row: **40×40px** (radius 20px, confirmed)
- Avatar sheet: **64×64px** (radius 32px, confirmed)

**Exceptions:** None beyond row-standard 16×8 pattern established Phase 26.

---

## Typography

Consolidated to 4 display sizes + 2 weights:

| Role | Size | Weight | Font | Line Height | Usage |
|------|------|--------|------|-------------|-------|
| Display Large (Bookings time) | 36px | inherent | Anton | 0.92 | Hour in booking rows (AdminBookingRow) |
| Display Medium (Slots time) | 32px | inherent | Anton | 0.92 | Hour in slot rows (SlotRow) + day selector dates + avatar initials in UserDetailSheet |
| Body Strong (Row names) | 14px | 600 (bold) | Manrope | 1.5 | User names in rows (AdminBookingRow, UserRow) |
| Body (Row details) | 14px | 400 (regular) | Manrope | 1.5 | Secondary text in rows (participant count) |
| Label (Status, email, small text) | 11px | standard | JetBrains Mono | 1.5 | Status labels, counters, email displays, day abbr |

**Font declarations:**
- **Anton:** Display font with inherent weight (single weight by design, do NOT declare as separate weight)
- **Manrope:** 2 weights only — 400 (regular), 600 (bold)
- **JetBrains Mono:** Mono font with standard weight (do NOT declare as separate weight entry)

**Locked constraints:**
- Anton `height: 0.92` (Phase 23 AppTheme standard — do NOT override)
- Do NOT apply `SizedBox(height: fixed)` that cuts descenders (Pitfall 8)
- Manrope row names always 14px bold (weight: 600)
- Manrope secondary details always 14px regular (weight: 400)
- Status/counters always mono 11px (standard weight)
- Avatar initials in UserDetailSheet: Anton 32px (not 36px, not 40px) inside CircleAvatar 64×64

---

## Color

| Role | Token | Value | Usage |
|------|-------|-------|-------|
| Dominant surface (60%) | AppTheme.paper | #F9F8F7 | Screen background, row backgrounds (no coloring) |
| Secondary surface (30%) | AppTheme.lineHair | #E8E3DC | Hairline divisor borders (0.5px top of rows) |
| Accent — Reserved (10%) | AppTheme.orange | #FF6B35 | Time hour color when slot reserved; day selector underline; active/focused states |
| Semantic — Info | AppTheme.concrete | #9A9490 | Dimmed text (participant count, helper text, counters) |
| Semantic — Inactive | AppTheme.ink | #1A1A1A | Default text, unselected elements, inactive hour |
| Semantic — Admin avatar | AppTheme.orange | #FF6B35 | Avatar circle background for admin users (dark text overlay) |
| Semantic — User avatar | AppTheme.ink | #1A1A1A | Avatar circle background for regular users (light text overlay) |
| Semantic — Success/Sports | AppTheme.court | {from AppTheme} | Status "PIX PAGO" or "CONFIRMADO" (ref: admin_booking_card.dart line 29) |
| Semantic — Warning | AppTheme.sun | {from AppTheme} | Status "AGUARDANDO PIX" (ref: admin_booking_card.dart line 28) |

**Accent reserved for:**
1. Slot hour text (Anton 32px/36px) when reserved/booked
2. Day selector underline (2px height when selected)
3. Active/focused interactive elements (switch on state)
4. No other elements may use orange without explicit requirement

**60/30/10 split:**
- 60%: Paper (background fill)
- 30%: LineHair (divisors between elements, creates visual separation)
- 10%: Orange (slot status, day selection, admin indicators)

---

## Component Inventory

### New Components

#### 1. AdminBookingRow
**Purpose:** Replace AdminBookingCard. Display booking with hour (Anton 36px), name (Manrope 14px bold), participant count, status (mono 11px uppercase), and action pills.

**Props:**
- `booking: BookingModel` — data source
- `onConfirm: VoidCallback?` — "Confirmar" action (pending only)
- `onReject: VoidCallback?` — "Recusar" action (pending only)

**Layout:**
```
[Time 36px Anton] [Padding 16px] [Column: Name (bold 14px) / Count (regular 14px concrete)]
  [Padding 8px left]
  [Status mono 11px bold colorized] [Padding 8px] [Pills: if pending → SportBtn.outlined 'CONFIRMAR' + 'RECUSAR']
```

**Render rules:**
- Hairline top border: `BorderSide(color: AppTheme.lineHair, width: 0.5)` (skip if first item)
- Padding: 16px horizontal, 8px vertical (DecoratedBox inner)
- Pills visible ONLY when `booking.status == 'pending'`
- Status color map: see Color contract above (`_statusColor` method from admin_booking_card.dart)
- No Card background, no shadow, no colored Container

**Nesting:** Lives in `lib/features/admin/ui/admin_booking_row.dart` (new file, separate from HairlineBookingRow)

---

#### 2. UserDetailSheet
**Purpose:** Bottom sheet for user admin actions (promote/demote). Triggered by tap on UserRow.

**Props:**
- `user: UserModel` — data source (name, email, isAdmin, photoUrl, bookingCount)
- `authCubit: AuthCubit` — for promoteUser / demoteUser calls

**Layout:**
```
[Drag handle: 32px wide × 4px tall, color: lineHair, radius 2px]
[Padding 20px]
[Avatar: CircleAvatar radius 32px, bg: orange if admin else ink, child: Text initial Anton 32px white/paper]
[Padding 16px]
[Name: Manrope 14px bold]
[Padding 4px]
[Email: JBM 11px]
[Padding 8px]
[Counter: "N reservas", JBM 11px concrete]
[Padding 24px]
[SportBtn.filled: "PROMOVER A ADMIN" or "REMOVER ADMIN", full width]
[SafeArea bottom]
```

**Render rules:**
- Sheet uses `DraggableScrollableSheet` (Material 3 standard, slide-from-bottom animation)
- Avatar fallback: Image.network(photoUrl) with errorBuilder → Text(initial)
- Avatar text: Anton 32px, color: AppTheme.paper (white)
- Action button: 52px height (SportBtn standard), full width with horizontal padding 16px
- Sheet background: AppTheme.paper (no color override needed)
- Interact on button press: set `_isSubmitting = true`, call `authCubit.promoteUser()` or `demoteUser()`, pop on success

**Nesting:** Lives in `lib/features/admin/ui/user_detail_sheet.dart` (new file)

---

### Modified Components

#### 1. SlotManagementTab (redesigned)
**What changes:**
- Day selector (from ChoiceChip) → underline pattern (SportDayStrip reference or local GestureDetector)
- Slot row rows → hairline pattern (DecoratedBox + Border.top)
- Hour color: Anton 32px, orange if booked, ink if empty
- Switch ativo/inativo: uses AppTheme.lightTheme.switchTheme (no hardcoded Colors.grey/primaryGreen)

**Pattern:**
- Row structure: [Time 32px Anton (color=booked?orange:ink)] + [Padding 16px] + [Expanded(Column[reserved name, sport])] + [Switch]
- Day selector: 7 day chips with underline (2px orange when selected) + navigation buttons ← → (MaterialIconButton)
- No Card wrapper, hairline top divisor only

---

#### 2. BookingManagementTab (redesigned)
**What changes:**
- Delete AdminBookingCard completely (dead code removal D-08)
- Replace with AdminBookingRow in ListView.builder
- Pills visible only for pending status (D-10)
- Hairline top divisor (no Card background)

**Pattern:**
- Same hairline row structure as AdminBookingRow (see Component Inventory)

---

#### 3. UsersManagementTab (redesigned)
**What changes:**
- User row: avatar circular (laranja admin / ink user) + name (Manrope 14px bold) + email (mono 11px) + counter (mono 11px)
- Tap on row → open UserDetailSheet (new bottom sheet)
- Remove inline promote/demote buttons (consolidate into sheet per D-15)
- Hairline top divisor (no Card background)

**Pattern:**
- Row structure: [Avatar 40×40 CircleAvatar] + [Padding 16px] + [Column[Name 14px bold / Email 11px mono / Counter 11px mono]] + [Icon chevron right indicator]
- Avatar: if photoUrl valid → Image.network(photoUrl) with errorBuilder → Text(initial Anton 20px); else → initial always
- Counter color: AppTheme.concrete (confirmed locked decision)
- No inline buttons, tap entire row

---

### Existing Components (No Changes)

- `AdminBookingDetailSheet` — tap on slot reserved (keep as-is, D-04)
- `SlotFormSheet` — tap on slot empty (keep as-is, D-03)
- `SportBtn.filled / .outlined` — reuse for sheet actions + pills
- `HairlineBookingRow` — reference pattern only, do NOT duplicate (AdminBookingRow is separate new widget, adapted 26px → 36px)
- `AppTheme.*` — use as-is, no token overrides

---

## Copywriting Contract

| Element | Copy | Usage |
|---------|------|-------|
| Slot empty time | "{HH:mm}" (e.g., "14:00") | Anton 32px, color ink |
| Slot reserved time | "{HH:mm}" (e.g., "14:00") | Anton 32px, color orange (indicates occupied) |
| Booking row time | "{HH:mm}" (e.g., "14:00") | Anton 36px, color ink |
| Status label pending | "AGUARDANDO" | JBM 11px, color orange |
| Status label pending_payment | "AGUARDANDO PIX" | JBM 11px, color sun |
| Status label confirmed (PIX) | "PIX PAGO" | JBM 11px, color court |
| Status label confirmed (on-arrival) | "PAGAR NA HORA" | JBM 11px, color ink |
| Pills confirm button | "CONFIRMAR" | SportBtn.outlined, ink outline, visible pending only |
| Pills reject button | "RECUSAR" | SportBtn.outlined, ink outline, visible pending only |
| Admin promote button (sheet) | "PROMOVER A ADMIN" | SportBtn.filled, orange background, full width |
| Admin remove button (sheet) | "REMOVER ADMIN" | SportBtn.filled, orange background, full width |
| Booking count label | "{N} reservas" (e.g., "3 reservas") | JBM 11px, color concrete |
| User row email | "{email}" (e.g., "user@example.com") | JBM 11px, color ink |
| Day selector abbr | "Seg", "Ter", "Qua", "Qui", "Sex", "Sab", "Dom" | JBM 11px, color ink |
| Day selector date | "{day_number}" (e.g., "4", "15") | Anton 32px, color ink |
| Empty state (no slots/bookings) | "Nenhuma reserva" (or provided by cubit) | Manrope 14px, color concrete |
| Error state (load failure) | "{error message from cubit}" + "Tente novamente" link | Manrope 14px, color ink + link action |

**Destructive actions in Phase 27:**
1. **Booking rejection (pills):** Confirm copy: "Deseja recusar esta reserva? Ação não pode ser desfeita."
2. **Remove admin (sheet):** Confirm copy: "Deseja remover privilégios de admin? Ação não pode ser desfeita."

No soft delete confirmation in UI — backend (Cloud Functions) must validate admin-only operations.

---

## Layout Specifications

### Aba Slots (SlotManagementTab)

**Frame:**
- Header: Day selector (7 days, underline pattern, ← → nav)
- Body: ListView of SlotRow widgets
- BG: AppTheme.paper
- Safe area: applies (system insets)

**Row structure per slot:**
```
Hairline top (if not first) → Padding 16×8 → Row([
  Text(time, style: AppTheme.display(32, color: booked?orange:ink)),
  SizedBox(16),
  Expanded(Column([
    if (booked) Text(reservantName, style: AppTheme.ui(14, weight: 600)),
    if (booked) Text(sport, style: AppTheme.ui(14, color: concrete)),
  ])),
  Switch(value: slot.isActive, onChanged: toggleCallback),
])
```

**Day selector:**
```
Row([
  IconButton(← previous week),
  Expanded(Row([
    for (day in weekDays)
      GestureDetector(
        Column([
          Text('Seg'/'Ter'..., style: AppTheme.mono(11)),
          Text('4'/'5'..., style: AppTheme.display(32)),
          if (selected) Container(width: 20, height: 2, color: orange),
        ])
      ),
  ])),
  IconButton(→ next week),
])
```

---

### Aba Reservas (BookingManagementTab)

**Frame:**
- Body: ListView of AdminBookingRow widgets
- BG: AppTheme.paper
- Safe area: applies

**Row structure per booking (AdminBookingRow):**
```
Hairline top (if not first) → Padding 16×8 → Row([
  Text(time, style: AppTheme.display(36, color: ink)),
  SizedBox(16),
  Expanded(Column([
    Text(userName, style: AppTheme.ui(14, weight: 600)),
    Text('N pessoas', style: AppTheme.ui(14, color: concrete)),
    SizedBox(4),
    Text(statusLabel, style: AppTheme.mono(11, color: statusColor)),
  ])),
  if (status == 'pending') SizedBox(8),
  if (status == 'pending') SportBtn.outlined('CONFIRMAR', onPressed: confirmCallback),
  if (status == 'pending') SizedBox(8),
  if (status == 'pending') SportBtn.outlined('RECUSAR', onPressed: rejectCallback),
])
```

---

### Aba Usuários (UsersManagementTab)

**Frame:**
- Body: ListView of UserRow widgets
- BG: AppTheme.paper
- Safe area: applies

**Row structure per user (UserRow):**
```
Hairline top (if not first) → Padding 16×8 → InkWell(onTap: openUserDetailSheet, child:
  Row([
    CircleAvatar(radius: 20, bg: isAdmin?orange:ink, child: Text(initial, Anton 20, color: paper)),
    SizedBox(16),
    Expanded(Column([
      Text(name, style: AppTheme.ui(14, weight: 600)),
      Text(email, style: AppTheme.mono(11)),
      Text('N reservas', style: AppTheme.mono(11, color: concrete)),
    ])),
    Icon(Icons.chevron_right, color: concrete),
  ])
)
```

**UserDetailSheet (bottom sheet):**
```
DraggableScrollableSheet(
  expand: false,
  builder: (context, controller) => SingleChildScrollView(
    controller: controller,
    child: SafeArea(child: Padding(16 horizontal, 8 vertical, child:
      Column([
        Center(Container(32×4, color: lineHair, radius: 2)),
        SizedBox(20),
        CircleAvatar(radius: 32, bg: isAdmin?orange:ink, child: Text(initial, Anton 32, color: paper)),
        SizedBox(16),
        Center(Text(name, Manrope 14 bold)),
        SizedBox(4),
        Center(Text(email, JBM 11)),
        SizedBox(8),
        Center(Text('N reservas', JBM 11 concrete)),
        SizedBox(24),
        Padding(16 horizontal, child: SportBtn.filled(label, onPressed: actionCallback, width: max)),
      ])
    ))
  )
)
```

---

## Registry Safety

| Registry | Tool Used | Blocks | Safety Status |
|----------|-----------|--------|---------------|
| Flutter Material 3 | Built-in | DraggableScrollableSheet, CircleAvatar, Switch, IconButton, TabBar | not required (first-party) |
| AppTheme (internal) | Phase 23 library | AppTheme.display, AppTheme.ui, AppTheme.mono, AppTheme.orange, etc. | not required (first-party) |
| SportBtn (internal) | lib/core/widgets/sport_btn.dart | SportBtn.filled, SportBtn.outlined | not required (first-party) |
| Google Fonts (pubspec.yaml 6.2.1) | google_fonts package | Anton, Manrope, JetBrains Mono | not required (established) |

**No third-party registries declared.** All components sourced from Flutter SDK, internal theme library, and established pubspec.yaml dependencies.

---

## Checker Sign-Off

- [ ] **Dimension 1 Copywriting:** All labels, button text, error messages match contract
- [ ] **Dimension 2 Visuals:** Layout matches ASCII specs; hairline rows; no Card backgrounds; no hardcoded colors
- [ ] **Dimension 3 Color:** Accent orange reserved for time/selection only; concrete for secondary; ink for primary
- [ ] **Dimension 4 Typography:** 4 unique sizes (36, 32, 14, 11px); 2 weights only (400 and 600 Manrope); Anton and JBM Mono as display fonts without weight declarations; avatar initials 32px Anton
- [ ] **Dimension 5 Spacing:** Rows 16×8 padding; avatar 40×40 (row), 64×64 (sheet); hairline 0.5px top; section gaps 16-24px
- [ ] **Dimension 6 Registry Safety:** No flags on AppTheme/SportBtn/Material3/google_fonts usage

**Approval:** pending (awaiting gsd-ui-checker)

---

## Pre-Population Sources

| Source | Decisions Used |
|--------|-----------------|
| 27-CONTEXT.md | D-01 to D-15 (10 locked decisions) |
| 27-RESEARCH.md | Standard Stack (AppTheme, HairlineBookingRow, SportBtn, Material 3), Architecture patterns, Pitfalls |
| User input (phase discussion) | Padding 8px vertical (updated from 12px), Avatar 40px row / 64px sheet, Counter color concrete, Sheet animation slide-from-bottom |
| AppTheme codebase | All color tokens, typography helpers, spacing values |
| UI Checker feedback (2026-06-04) | Consolidated typography to 4 sizes, 2 weights only; removed 24px and 16px Manrope; avatar initials 32px Anton; Anton/JBM as display fonts without weight entries |

---

*Phase: 27-admin-slots-reservas-usuarios*
*Contract updated: 2026-06-04 (revision)*
*Status: draft — awaiting gsd-ui-checker approval*

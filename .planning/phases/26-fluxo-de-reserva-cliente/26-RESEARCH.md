# Phase 26: Fluxo de Reserva (Cliente) - Research

**Researched:** 2026-05-27
**Domain:** Flutter UI — booking confirmation sheet and my bookings screen redesign with Arena identity
**Confidence:** HIGH

## Summary

Phase 26 redesigns two core booking client screens (BookingConfirmationSheet and MyBookingsScreen) to match Arena Esportivo identity established in Phase 23. Requires two new reusable widgets (SportBtn and HairlineBookingRow), one new screen (inline header for MyBookingsScreen), and precise typography (Anton display sizes 88px, 72px, 30px, 26px). No business logic changes — 100% UI/styling.

All current code exists: BookingConfirmationSheet at `lib/features/booking/ui/booking_confirmation_sheet.dart` (lines 212–255 contain the `_infoRow` and `_paymentWarningBanner` methods to replace). MyBookingsScreen exists at `lib/features/booking/ui/my_bookings_screen.dart` (uses old AppBar and BookingCard; needs header inline, hero "Próximo" block, HairlineBookingRow). Reference patterns from Phase 24 (schedule_screen.dart wordmark + SportDayStrip) and Phase 25 (admin_screen.dart inline banner with orange stripe).

**Primary recommendation:** Execute in waves — Wave 0 creates SportBtn and HairlineBookingRow widgets, Wave 1 rewrites BookingConfirmationSheet, Wave 2 rewrites MyBookingsScreen. All three can run in parallel once Wave 0 completes.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Hero do Horário na Confirmation Sheet (BOOK-07):**
- After drag handle: hero block with eyebrow mono of date + hora in Anton 88px + preço in mono below
- Removes current 3 `_infoRow()` calls (date/time/price), replaces with single hero block
- Hero block before recurrence section

**Banner de Aprovação Manual (BOOK-08):**
- `_paymentWarningBanner()` redesigned with orange stripe 2px left (no colored background)
- Uses `IntrinsicHeight` + `Container(width:2, color:AppTheme.orange)` + `Expanded` pattern from Phase 25
- Lógica exibição **não muda**: aparece apenas quando `_requiresConfirmation && !pixEnabled`

**SportBtn (BOOK-09):**
- New reusable widget at `lib/core/widgets/sport_btn.dart`
- Variants: `filled` (orange bg, paper text) and `outlined` (ink border, ink text)
- Anton uppercase 15px, `StadiumBorder()`, no icons
- "PAGAR COM PIX" → filled orange; "PAGAR NA HORA" → outlined ink
- Used for recurrence button and confirm button too

**Campo de Participantes e Dropdown de Esporte:**
- Migrate to `UnderlineInputBorder` (not OutlineInputBorder with 12px radius)
- Consistent with ADMN-25 Phase 28 spec

**Switch de Recorrência:**
- Uses `AppTheme.switchTheme` (orange/paper active, line/paper inactive)
- Removes hardcoded `activeThumbColor: AppTheme.primaryGreen`

**MyBookings Header (BOOK-10/12):**
- Remove AppBar; inline header like Phase 24/25
- Wordmark "VIDA ATIVA" (Anton 18px + orange pill rect) + eyebrow "MINHAS RESERVAS" mono
- Uses `SafeArea(bottom: false)` + Column structure

**Hero "Próximo" (BOOK-10):**
- First upcoming booking becomes hero block
- Eyebrow dynamic: "PRÓXIMO · HOJE", "PRÓXIMO · AMANHÃ", or "PRÓXIMO · [DAY_ABBR]"
- Hora in Anton 72px, data in mono below
- GestureDetector tap: if `pending_payment + paymentId != null` → PixPaymentScreen; else → ClientBookingDetailSheet

**Section Headers (BOOK-12):**
- "EM SEGUIDA" and "HISTÓRICO" in JetBrains Mono uppercase tracked
- "EM SEGUIDA" = upcoming excluding hero; "HISTÓRICO" = past/cancelled

**HairlineBookingRow — novo widget (BOOK-11):**
- New file `lib/features/booking/ui/hairline_booking_row.dart`
- Row: left (day as Anton 30px + abbrev mono) | middle (time Anton 26px) | right (status pill outline)
- Status pill: border outline, no fill, status-dependent color (court, orange, orangeDk, concrete)
- Hairline separator top: 0.5px `AppTheme.lineHair`
- Tap behavior: `pending_payment + paymentId` → PixPaymentScreen; else → ClientBookingDetailSheet
- Special eyebrow "AGUARDANDO PIX" above pill for pending_payment

**Empty State (MyBookings):**
- Redesigned: mono uppercase + SportBtn outlined "VER AGENDA"

### Claude's Discretion

- Padding/spacing interno do hero block na confirmation sheet — suggest 8px between elements
- Tamanho da pílula/rect laranja do wordmark — use same as Phase 24
- Padding horizontal/vertical do hero "Próximo" em MyBookings — suggest 16px h / 12px v
- Largura do status pill e padding interno — suggest 12px h / 6px v, border-radius 16px
- Ordem exata dos campos no hero block da sheet (eyebrow antes ou depois da hora?)

### Deferred Ideas (OUT OF SCOPE)

- Redesign da PixPaymentScreen
- Animação de transição entre estados do hero
- ClientBookingDetailSheet visual Arena — não é escopo
- BookingCard remoção — cleanup Phase 27+
- RecurrenceResultSheet redesign

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BOOK-07 | Hora do slot exibida em Anton 88px como elemento principal (sem bloco preto) | AppTheme.display(size: 88) helper exists; hero block pattern from Phase 25 admin banner (IntrinsicHeight + stripe); `_infoRow()` and `_paymentWarningBanner()` methods identified at booking_confirmation_sheet.dart:212–255 |
| BOOK-08 | Aviso de aprovação manual indicado por faixa lateral laranja 2px (sem colored background) | Admin stripe pattern exists in admin_screen.dart:77–100 (`IntrinsicHeight + Row` with `Container(width:2, color:orange)`); `_paymentWarningBanner()` currently line 229–255 using deprecated colored Container |
| BOOK-09 | Botões "Pagar com Pix" e "Pagar na hora" em SportBtn Anton uppercase sem quebra de linha | Need to create SportBtn widget; booking_confirmation_sheet.dart lines 411–433 show current FilledButton/OutlinedButton usage; AppTheme.filledButtonTheme and outlinedButtonTheme already support StadiumBorder and Anton 15px |
| BOOK-10 | Seção "Próximo" exibe horário em Anton 72px com eyebrow laranja "Próximo · hoje" (sem bloco preto) | AppTheme.display(size: 72) exists; schedule_screen.dart shows inline header pattern (wordmark + eyebrow); need to extract first upcoming booking and make it hero block in my_bookings_screen.dart |
| BOOK-11 | Demais reservas em rows hairline: data em Anton 30px, horário em Anton 26px, status pill quiet | Need to create HairlineBookingRow widget; slot_hairline_row.dart (Phase 24) provides reference pattern (border decoration, opacity handling, row layout); BookingCard (current my_bookings_screen.dart) is dead code after this phase |
| BOOK-12 | Section headers em JetBrains Mono uppercase tracked ("EM SEGUIDA" / "HISTÓRICO") | AppTheme.mono() exists with letterSpacing; my_bookings_screen.dart lines 74–79 and 113–118 show current section headers as simple Text widgets |

</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter | ^3.11.3 | UI framework | Project baseline |
| google_fonts | 6.2.1 | Font loading | Phase 23 bundled Anton/Manrope/JetBrains Mono offline |
| intl | 0.20.2 | Date/number formatting | Localization (pt_BR), currency, DateFormat |
| flutter_bloc | 9.1.1 | State management | BLoC pattern established; BookingCubit exists |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| cloud_firestore | 6.1.3 | Firebase reads | ClientBookingDetailSheet and PixPaymentScreen use Firestore |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom SportBtn | Material3 FilledButton/OutlinedButton with custom styling | Reinventing loses StadiumBorder convention; SportBtn centralizes design for Phase 27+ |
| Custom HairlineBookingRow | Reuse BookingCard | BookingCard has hardcoded colors (0xFF9E9A95) and Card elevation — breaks Arena hairline pattern |

**Installation:**
Existing dependencies in pubspec.yaml. No new packages required.

**Current state:** All dependencies already installed and used throughout project. Phase 23 confirmed google_fonts bundling and AppTheme tokens are locked.

## Architecture Patterns

### Recommended Project Structure
```
lib/
├── core/
│   └── widgets/
│       └── sport_btn.dart              [NEW] Reusable button widget
├── features/
│   └── booking/
│       └── ui/
│           ├── booking_confirmation_sheet.dart  [MODIFY] Hero block, SportBtn, underline inputs
│           ├── my_bookings_screen.dart          [MODIFY] Inline header, hero "Próximo", HairlineBookingRow
│           └── hairline_booking_row.dart        [NEW] Reusable row widget
```

### Pattern 1: Hero Block (Confirmation Sheet)

**What:** Large typographic display of slot start time (Anton 88px) with supporting eyebrow and price, replacing three separate info rows.

**When to use:** Display the most important information (time of a booking slot) in a way that draws attention and establishes hierarchy.

**Example:**
```dart
// Source: CONTEXT.md + AppTheme helpers
Widget _buildHeroBlock() {
  final dateDisplay = DateFormat('E, d MMM', 'pt_BR')
      .format(DateTime.parse(widget.viewModel.dateString))
      .toUpperCase(); // "QUA, 28 MAI"
  
  final timeDisplay = widget.viewModel.slot.startTime; // "18:00"
  
  final priceDisplay = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
      .format(widget.viewModel.slot.price); // "R$ 50,00"

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(dateDisplay, style: AppTheme.mono(size: 11, color: AppTheme.concrete)),
      const SizedBox(height: 8),
      Text(timeDisplay, style: AppTheme.display(size: 88, color: AppTheme.ink)),
      const SizedBox(height: 8),
      Text(priceDisplay, style: AppTheme.mono(size: 16, color: AppTheme.concrete)),
      const SizedBox(height: 16),
      const Divider(color: AppTheme.lineHair, height: 1, thickness: 0.5),
    ],
  );
}
```

### Pattern 2: Orange Stripe Banner (Approval Warning)

**What:** Left-aligned orange stripe (2px) adjacent to message text, no colored background container.

**When to use:** Show informational or warning messages that need visual distinction without heavy styling.

**Example:**
```dart
// Source: admin_screen.dart:77–100 (Phase 25 reference)
Widget _buildApprovalWarningBanner() {
  return IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(width: 2, color: AppTheme.orange),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Sua reserva aguarda confirmação. Admin aprovará em breve.',
              style: AppTheme.ui(size: 13, color: AppTheme.ink),
            ),
          ),
        ),
      ],
    ),
  );
}
```

### Pattern 3: Inline Header (No AppBar)

**What:** Custom header widget using SafeArea, wordmark row, and eyebrow text instead of Material AppBar.

**When to use:** When AppBar's default behavior (elevation, height, constraints) conflicts with design system (hair-thin borders, custom spacing, wordmark branding).

**Example:**
```dart
// Source: schedule_screen.dart:73–106 (Phase 24 reference)
Widget _buildInlineHeader() {
  return SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wordmark row
          Row(
            children: [
              Text('VIDA', style: AppTheme.display(size: 18, color: AppTheme.ink)),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('ATIVA', style: AppTheme.display(size: 18, color: AppTheme.paper)),
              ),
              const Spacer(),
              Text('MINHAS RESERVAS', style: AppTheme.mono(size: 11, color: AppTheme.concrete)),
            ],
          ),
        ],
      ),
    ),
  );
}
```

### Pattern 4: Hairline Row with Status Pill

**What:** Horizontal row with left column (day/abbrev), middle column (time), right column (status pill outline), separated by 0.5px border-top.

**When to use:** Display list items with minimal visual noise, aligned with Arena hairline aesthetic (no cards, no shadows).

**Example:**
```dart
// Source: slot_hairline_row.dart (Phase 24 reference) + CONTEXT.md HairlineBookingRow spec
Widget _buildHairlineBookingRow(BookingModel booking, {required int index}) {
  final dayNum = DateTime.parse(booking.date).day;
  final dayAbbr = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM']
      [DateTime.parse(booking.date).weekday - 1];
  
  final timeDisplay = DateFormat('HH:mm').format(
    DateTime.parse('${booking.date} ${booking.startTime}'),
  ); // "14:30"
  
  final (statusColor, statusLabel) = _statusPill(booking.status, booking.paymentMethod);

  return DecoratedBox(
    decoration: BoxDecoration(
      border: index == 0
          ? null
          : const Border(top: BorderSide(color: AppTheme.lineHair, width: 0.5)),
    ),
    child: InkWell(
      onTap: () => _onBookingTap(booking),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$dayNum', style: AppTheme.display(size: 30, color: AppTheme.ink)),
                const SizedBox(width: 8),
                Text(dayAbbr, style: AppTheme.mono(size: 10, color: AppTheme.concrete)),
              ],
            ),
            const Spacer(),
            Text(timeDisplay, style: AppTheme.display(size: 26, color: AppTheme.ink)),
            const SizedBox(width: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: statusColor, width: 1),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(statusLabel, style: AppTheme.mono(size: 10, color: statusColor)),
            ),
          ],
        ),
      ),
    ),
  );
}
```

### Anti-Patterns to Avoid

- **Hardcoding colors with `Color(0xFF...)`:** booking_card.dart has 6+ instances of `Color(0xFF9E9A95)`. Use AppTheme tokens instead (AppTheme.concrete, etc).
- **Wrapping Anton text in SizedBox with fixed height:** Anton has `height: 0.92` built in to prevent clipping. Don't override with SizedBox(height: X). See pitfalls below.
- **Using OutlineInputBorder with borderRadius: 12:** Phase 26 requires `UnderlineInputBorder` (no radius). Current booking_confirmation_sheet.dart lines 354–362 use OutlineInputBorder — must refactor.
- **Using deprecated `activeThumbColor` on Switch:** Current line 323 has `activeThumbColor: AppTheme.primaryGreen` — use AppTheme.switchTheme instead.
- **Mixing FilledButton/OutlinedButton styles with SportBtn:** SportBtn centralizes padding, border radius, text style. Don't define custom FilledButton.styleFrom elsewhere; use SportBtn.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Rounded action button with custom colors | Custom RoundedRectangleBorder button | SportBtn widget | Button styling has edge cases (disabled opacity, hover, ripple); centralizing ensures consistency across phases 26–28 |
| Booking list rows with status colors | Custom row with colored containers | HairlineBookingRow widget | Booking status has 4–5 states (confirmed, pending_payment, cancelled, expired, pending); pill styling needs opacity, border color, label color logic; duplication risk across admin tabs (phase 27) |
| Date display in multiple formats | Multiple DateFormat calls scattered | Use helper: `_formatBookingDate(booking.date)` or phase-scoped function | Localization (pt_BR), abbreviation logic (SEG/TER/QUA) should be centralized |
| Status color mapping | Switch(booking.status) in multiple places | Centralized `(Color, String) _statusPill(String status, String? paymentMethod)` | 4+ places need this logic (HairlineBookingRow, header "AGUARDANDO PIX", admin tabs); reduce duplication |

**Key insight:** HairlineBookingRow and SportBtn are reusable beyond phase 26. Phase 27 (admin slots/reservas/usuários) will use HairlineBookingRow for rows and SportBtn for "Salvar tabela" button in phase 28. Centralizing prevents 3x the code duplication.

## Common Pitfalls

### Pitfall 1: Anton Height Clipping at Large Sizes

**What goes wrong:** Anton 88px or 72px text gets cut off vertically if wrapped in a container with fixed height.

**Why it happens:** Anton's custom font has `height: 0.92` (9px below baseline for 100px text). If you do `SizedBox(height: 88)` around `Text(..., style: display(size: 88))`, the 8px margin below the 88px text gets clipped.

**How to avoid:** 
- Always use `AppTheme.display(size: X)` which includes `height: 0.92` — don't wrap in SizedBox with fixed height
- Use SizedBox only for spacing gaps (height: 8, 16, 24), not for containing Anton text
- Example: `Column([Text(..., style: display(88)), SizedBox(height: 8), ...])` ✅ not `SizedBox(height: 88, child: Text(...))`

**Warning signs:** 
- Bottom 2–3px of "g", "y", "8", "9" are missing visually
- Designer says "text is cut off" when comparing to spec

### Pitfall 2: Hardcoded Colors Breaking Design System

**What goes wrong:** Code references `Color(0xFF9E9A95)` instead of `AppTheme.concrete`, making recoloring/dark mode impossible.

**Why it happens:** Old code (booking_card.dart, admin_booking_card.dart) was written before Phase 23 AppTheme. Copy-paste perpetuates the antipattern.

**How to avoid:**
- Always use `AppTheme.*` constants (AppTheme.ink, AppTheme.concrete, AppTheme.orange, etc.)
- Run grep before phase start to find stray `Color(0xFF` and audit them
- booking_card.dart has 6 hardcoded instances — note it becomes dead code after Phase 26, don't propagate pattern to new widgets

**Warning signs:**
- Color values don't match AppTheme constant names
- "I can't find where this color came from" when refactoring

### Pitfall 3: Switch activeThumbColor Hardcoded

**What goes wrong:** Current booking_confirmation_sheet.dart line 323 has `activeThumbColor: AppTheme.primaryGreen`, which is the old v5 color (green) not the new Arena orange.

**Why it happens:** Code predates AppTheme.switchTheme from Phase 23 lightTheme.

**How to avoid:**
- Remove `activeThumbColor`, `activeTrackColor`, and other hardcoded Switch properties
- Let Switch use `AppTheme.lightTheme.switchTheme` (orange/paper active, line/paper inactive) by default
- Only override if truly needed per-widget (rare)

**Warning signs:**
- Switch thumb color doesn't match orange accent in design spec
- Toggling recurrence switch shows wrong color

### Pitfall 4: Incorrect Input Border Type (Outline vs Underline)

**What goes wrong:** TextField/DropdownButtonFormField uses `OutlineInputBorder(borderRadius: 12)` instead of `UnderlineInputBorder`.

**Why it happens:** Old Material 2 pattern (rounded borders everywhere). Phase 26 spec requires underline borders per ADMN-25 (Phase 28) consistency.

**How to avoid:**
- Phase 26 booking_confirmation_sheet.dart lines 351–382 must change from OutlineInputBorder to UnderlineInputBorder
- AppTheme.lightTheme.inputDecorationTheme already defines UnderlineInputBorder — just remove custom border definitions
- Label/hint styles automatically apply from theme (no manual override needed)

**Warning signs:**
- Design spec shows underline, code shows rounded box
- Inconsistency with admin inputs (future phase 28 vision)

### Pitfall 5: Status Pill Appearance (Filled vs Outline)

**What goes wrong:** Status pill is a solid container with background color instead of an outline-only pill.

**Why it happens:** Copy-paste from Chip or Pill patterns that use filled backgrounds.

**How to avoid:**
- Status pill is **outline only**: `Container(decoration: BoxDecoration(border: Border.all(color, width: 1), borderRadius: 16), ...)`
- No `color:` in the BoxDecoration
- Text color matches border color
- Example: confirmed (court green outline) vs cancelled (orangeDk outline) vs pending (orange outline)

**Warning signs:**
- Pill has solid background color
- Text color doesn't match outline color
- Looks too heavy/colored compared to spec

## Code Examples

Verified patterns from official/Phase 23–25 sources:

### Text formatting: Time and Date

```dart
// Source: intl 0.20.2 + AppTheme
// Format time
final timeDisplay = booking.startTime; // Already stored as "HH:mm"
// Or if you have DateTime:
final timeDisplay = DateFormat('HH:mm').format(dateTime);

// Format date with day abbreviation
final dateDisplay = DateFormat('E, d MMM', 'pt_BR')
    .format(DateTime.parse(booking.date))
    .toUpperCase(); // "QUA, 28 MAI"

// Short day abbreviation (mon/tue/wed...)
final dayAbbr = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM']
    [DateTime.parse(booking.date).weekday - 1]; // "SEG"

// Format currency
final priceDisplay = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
    .format(booking.price); // "R$ 50,00"
```

### SportBtn Variants

```dart
// Source: AppTheme.filledButtonTheme + AppTheme.outlinedButtonTheme (Phase 23)
// Filled variant — orange background, paper text
FilledButton(
  onPressed: () => _handlePayPix(),
  child: const Text('PAGAR COM PIX'),
);
// Theme applies: AppTheme.orange bg, AppTheme.paper text, StadiumBorder, Anton 15px

// Outlined variant — ink border, ink text
OutlinedButton(
  onPressed: () => _handlePayOnArrival(),
  child: const Text('PAGAR NA HORA'),
);
// Theme applies: ink border 1.5px, ink text, StadiumBorder, Anton 15px

// After Phase 26: use SportBtn widget instead (centralizes these)
```

### Status Color and Label Logic

```dart
// Source: CONTEXT.md + slot_hairline_row.dart pattern
(Color, String) _statusPill(String status, String? paymentMethod) {
  if (status == 'confirmed') {
    return (AppTheme.court, 'CONFIRMADO');
  } else if (status == 'pending_payment' && paymentMethod == 'pix') {
    return (AppTheme.orange, 'PIX PENDENTE'); // With "AGUARDANDO PIX" eyebrow above
  } else if (status == 'cancelled') {
    return (AppTheme.orangeDk, 'CANCELADO');
  } else if (status == 'expired') {
    return (AppTheme.concrete, 'EXPIRADO');
  } else if (status == 'pending') {
    return (AppTheme.ink, 'PENDENTE');
  }
  return (AppTheme.concrete, status.toUpperCase());
}
```

### Inline Header Example

```dart
// Source: schedule_screen.dart:73–106 + admin_screen.dart:116–163
SafeArea(
  bottom: false,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('VIDA', style: AppTheme.display(size: 18, color: AppTheme.ink)),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('ATIVA', style: AppTheme.display(size: 18, color: AppTheme.paper)),
                ),
              ],
            ),
            const Spacer(),
            Text('MINHAS RESERVAS', style: AppTheme.mono(size: 11, color: AppTheme.concrete)),
          ],
        ),
      ),
      Expanded(child: contentWidget),
    ],
  ),
)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| AppBar with Material defaults | Inline header (SafeArea + custom Row) | Phase 24 (Schedule) | No elevation, no center-alignment, custom wordmark/eyebrow spacing |
| Colored Card with elevation | Hairline border (0.5px lineHair) + Opacity for state | Phase 24 (Slots) | Minimal visual noise, better focus on content; status indicated by stripe or pill, not card color |
| FilledButton/OutlinedButton with borderRadius: 12 | SportBtn with StadiumBorder | Phase 26 | Rounded pill shape standard across phases 26–28; Anton uppercase centralized |
| green accent (AppTheme.primaryGreen) | orange accent (AppTheme.orange) | Phase 23 (AppTheme) | Complete redesign from green/gold to sand/ink/orange (Arena identity) |
| OutlineInputBorder with 12px radius | UnderlineInputBorder | Phase 26+ | Minimal input decoration, consistent with admin fields (phase 28 vision) |
| Multiple status color switch statements | Centralized `_statusPill()` helper | Phase 26+ | Reduce duplication across HairlineBookingRow, admin rows (phase 27), empty state |

**Deprecated/outdated:**
- `_infoRow()` (booking_confirmation_sheet.dart:212–227): Replaced by hero block pattern
- `_paymentWarningBanner()` (booking_confirmation_sheet.dart:229–255): Replaced by orange stripe pattern
- `BookingCard` (booking_card.dart): Dead code after Phase 26; use HairlineBookingRow instead
- AppBar on MyBookingsScreen: Replaced by inline header
- `activeThumbColor: AppTheme.primaryGreen` on Switch: Use AppTheme.switchTheme (orange) instead

## Assumptions Log

> List all claims tagged `[ASSUMED]` in this research. The planner uses this section to identify decisions needing user confirmation.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | BookingModel.date is stored as "YYYY-MM-DD" string format | Booking Model Fields | Incorrect date parsing in hero block and HairlineBookingRow; wrong eyebrow display |
| A2 | BookingModel.startTime is stored as "HH:mm" string format | Booking Model Fields | Time display in hero block would need reformatting; pitch shows "18:00" but data might be DateTime |
| A3 | BookingModel.status values are: 'pending', 'confirmed', 'pending_payment', 'cancelled', 'expired' | Status Mapping | Status pill colors and labels would be wrong; missing or extra states |
| A4 | PixPaymentScreen accepts bookingId and optional paymentId as constructor parameters | Navigation Flow | Pending payment tap would fail to navigate correctly |
| A5 | ClientBookingDetailSheet accepts (booking, bookingCubit, isFuture) as parameters | Navigation Flow | Detail sheet navigation would fail with wrong parameter count |
| A6 | StatefulNavigationShell.of(context).goBranch(0) navigates to Schedule tab | Navigation Flow | Empty state "Ver Agenda" button would navigate to wrong tab |

**Notes on assumptions:**
- A1–A2 verified by BookingModel class (lines 6–12 of booking_model.dart)
- A3 verified by getters in BookingModel (lines 91–100)
- A4–A5 verified by usage in my_bookings_screen.dart (lines 88–100, 149–154)
- A6 verified by schedule_screen.dart pattern (uses `goBranch(0)` for tab navigation)

All assumptions are **VERIFIED** — no user confirmation needed.

## Open Questions

1. **Eyebrow date format in hero block (BOOK-07):**
   - What we know: CONTEXT.md says `DateFormat('E, d MMM', 'pt_BR').format(...).toUpperCase()` → "QUA, 28 MAI"
   - What's unclear: Should day name and month be uppercase ("QUA, 28 MAI") or mixed case ("Qua, 28 Mai")?
   - Recommendation: Follow schedule_screen.dart pattern which does `.toUpperCase()` on full string

2. **Hero "Próximo" eyebrow dynamic date suffix for dates beyond tomorrow:**
   - What we know: CONTEXT.md says "PRÓXIMO · HOJE", "PRÓXIMO · AMANHÃ", or "PRÓXIMO · [DAY_ABBR]"
   - What's unclear: For dates 3+ days away, should we show day abbreviation (SEG/TER/QUA) or full date (D MMM)?
   - Recommendation: Use day abbreviation (more compact, consistent with SportDayStrip pattern)

3. **Status pill border width and padding exactness:**
   - What we know: CONTEXT.md discretion section suggests "12px h / 6px v" padding and "16px" border-radius
   - What's unclear: Border width (1px vs 1.5px)? Should pill scale with other rows or fixed size?
   - Recommendation: Use `Border.all(color, width: 1)` and `borderRadius: circular(16)` to match Chip/FilterChip convention

## Environment Availability

**Skipped:** Phase 26 is pure UI changes (widget rebuild) — no external dependencies (databases, CLIs, APIs) beyond what phases 23–25 already verified. All Flutter, Dart, and Pub packages already installed and tested.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (built-in) + bloc_test 10.0.0 |
| Config file | None — standard flutter test discovery |
| Quick run command | `flutter test test/features/booking/ui/ -x` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BOOK-07 | Hero block displays date eyebrow, hora Anton 88px, price mono | unit | `flutter test test/features/booking/ui/booking_confirmation_sheet_test.dart::test_hero_block -x` | ❌ Wave 0 |
| BOOK-08 | Approval warning banner shows orange stripe left (width 2px), no colored bg | unit | `flutter test test/features/booking/ui/booking_confirmation_sheet_test.dart::test_approval_stripe -x` | ❌ Wave 0 |
| BOOK-09 | SportBtn filled shows orange bg + paper text, outlined shows ink border + ink text | unit | `flutter test test/core/widgets/sport_btn_test.dart -x` | ❌ Wave 0 |
| BOOK-10 | MyBookings hero "Próximo" displays hora Anton 72px + dynamic eyebrow + hairline separator | unit | `flutter test test/features/booking/ui/my_bookings_screen_test.dart::test_hero_next_section -x` | ❌ Wave 0 |
| BOOK-11 | HairlineBookingRow displays day (Anton 30px) + time (Anton 26px) + status pill (outline, no fill) | unit | `flutter test test/features/booking/ui/hairline_booking_row_test.dart -x` | ❌ Wave 0 |
| BOOK-12 | Section headers show "EM SEGUIDA" and "HISTÓRICO" in mono uppercase tracked | unit | `flutter test test/features/booking/ui/my_bookings_screen_test.dart::test_section_headers -x` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/features/booking/ui/booking_confirmation_sheet_test.dart -x` (fast verification)
- **Per wave merge:** Full test suite in 3–5 min
- **Phase gate:** All tests green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/core/widgets/sport_btn_test.dart` — covers BOOK-09 (filled/outlined variants, text styling, tap handling)
- [ ] `test/features/booking/ui/hairline_booking_row_test.dart` — covers BOOK-11 (row layout, status colors, tap navigation)
- [ ] `test/features/booking/ui/booking_confirmation_sheet_test.dart` — updated to cover BOOK-07, BOOK-08 (hero block, stripe banner)
- [ ] `test/features/booking/ui/my_bookings_screen_test.dart` — updated to cover BOOK-10, BOOK-12 (hero, section headers, hairline rows)
- [ ] Fixture: mock BookingModel with status/paymentMethod variants
- [ ] Fixture: mock SlotViewModel for confirmation sheet tests

*(Wave 0 scaffolds test files; Wave 1–2 implement test bodies alongside feature code)*

## Security Domain

This phase has no security implications beyond those already established in phases 23–25:

- **Input validation:** Participants field already has `maxLength: 200` in TextField; no SQL/injection risk (Firebase Firestore)
- **Navigation:** PixPaymentScreen and ClientBookingDetailSheet handle payment/detail data; phase 26 does not modify their internals
- **Authentication:** BookingCubit reads AuthCubit state; phase 26 does not change auth logic
- **Data access:** Reads from BookingModel (Firestore) already vetted; no new Firestore access introduced

**Skipped:** No ASVS categories triggered — this is a read-only UI redesign.

## Sources

### Primary (HIGH confidence)
- **AppTheme.dart** (lib/core/theme/) — Display/ui/mono helpers verified at lines 25–46; theme tokens at lines 8–22; filledButtonTheme/outlinedButtonTheme at lines 137–154; switchTheme at lines 180–188
- **booking_confirmation_sheet.dart** (lib/features/booking/ui/) — Current implementation of `_infoRow()`, `_paymentWarningBanner()`, and payment button code at lines 212–255, 411–433
- **my_bookings_screen.dart** (lib/features/booking/ui/) — Current AppBar, BookingCard usage, section headers at lines 19, 81–110, 113–136
- **schedule_screen.dart** (lib/features/schedule/ui/) — Inline header pattern (wordmark + eyebrow) at lines 73–106; SportDayStrip integration
- **admin_screen.dart** (lib/features/admin/ui/) — Orange stripe banner pattern (IntrinsicHeight + orange Container) at lines 77–100
- **slot_hairline_row.dart** (lib/features/schedule/ui/) — Hairline border pattern at line 24; row layout at lines 52–95; status label logic at lines 35–47
- **booking_model.dart** (lib/core/models/) — Status values, date/startTime formats at lines 4–69

### Secondary (MEDIUM confidence)
- **CONTEXT.md** (phase 26) — Decisions D-01 through D-23 provide UI contract and implementation guidance
- **UI-SPEC.md** (phase 26) — Design tokens, copywriting contract, pixel specifications verified against AppTheme and phase 24/25 examples

### Tertiary (LOW confidence)
- None — all claims verified with code or official phase docs

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** — all libraries already in pubspec.yaml and verified in phases 23–25; no new dependencies
- Architecture patterns: **HIGH** — Phase 24 schedule_screen and Phase 25 admin_screen provide reference implementations for inline header and stripe banner; slot_hairline_row.dart exists as pattern source
- Pitfalls: **HIGH** — v5→v6 pitfalls documented in STATE.md; Anton height issue and hardcoded color issues identified in code (booking_card.dart has 6 Color(0xFF) instances)
- Booking model fields: **HIGH** — Verified in booking_model.dart class definition (lines 4–39)
- Status mapping: **HIGH** — getters at booking_model.dart:91–100
- Navigation: **HIGH** — Usage patterns verified in my_bookings_screen.dart (lines 88–100, 149–154)

**Research date:** 2026-05-27
**Valid until:** 2026-06-03 (7 days — Flutter/Dart stable, AppTheme locked, no breaking changes expected)

---

*Phase: 26-fluxo-de-reserva-cliente*
*Research: Complete*
*Confidence: HIGH — all patterns verified via code inspection and phase 23–25 reference*

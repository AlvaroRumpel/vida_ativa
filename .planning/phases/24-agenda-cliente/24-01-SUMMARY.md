---
plan: 24-01
phase: 24
status: complete
created: 2026-05-26
self_check: PASSED
---

# Plan 24-01 Summary — Agenda Cliente Widget Rewrites

## What Was Built

Four schedule UI files rewritten to implement Arena Esportivo visual identity on the client Agenda screen. Zero BLoC/model/router changes.

## Files Modified

| File | Change | Description |
|------|--------|-------------|
| `lib/features/schedule/ui/schedule_screen.dart` | Edit | Removed AppBar; added inline wordmark header (SafeArea → Row: orange pill "VIDA ATIVA" + mono eyebrow date); added `_eyebrowDate()` helper; added AppTheme import; renamed DayChipRow call to SportDayStrip |
| `lib/features/schedule/ui/day_chip_row.dart` | Full rewrite | DayChipRow → SportDayStrip: 7-column underline strip (GestureDetector + SizedBox(40) + Column: mono abbrev + Anton 22px number + AnimatedContainer 2px orange underline); removed ChoiceChip, SingleChildScrollView, dot indicator |
| `lib/features/schedule/ui/slot_card.dart` | Full rewrite | SlotCard → SlotHairlineRow: DecoratedBox hairline divider (0.5px lineHair), Opacity 0.45 for booked/blocked, IntrinsicHeight only for myBooking stripe path (3px orange Container), Anton 42px time + mono 11px price + mono 11px status label (SizedBox 96px) |
| `lib/features/schedule/ui/slot_list.dart` | Edit | Added ClientBookingDetailSheet import; changed ListView padding to `only(bottom: 16)`; replaced SlotCard call with SlotHairlineRow (viewModel, index, onTap, onDetailTap); added `_showDetailSheet()` with all 3 required params (booking, bookingCubit, isFuture: true) |

## Deviations from Plan

None. All tasks implemented as specified. `_showDetailSheet` is a top-level function matching the pattern of `_showBookingSheet`.

## Verification Results

| Check | Command | Result |
|-------|---------|--------|
| Task 1 analyze | `flutter analyze --no-fatal-infos schedule_screen.dart day_chip_row.dart` | ✅ No issues |
| Task 3 analyze | `flutter analyze --no-fatal-infos slot_card.dart` | ✅ No issues |
| Task 4 analyze | `flutter analyze --no-fatal-infos slot_list.dart` | ✅ No issues |
| Full build | `flutter build web --release` | ✅ Built build\web |
| Color audit | `grep -rn "Color(0x" lib/features/schedule/ui/{schedule_screen,day_chip_row,slot_card,slot_list}.dart` | ✅ 0 results |
| Legacy alias audit | `grep -rn "brandAmber\|primaryGreen"` on 4 modified files | ✅ 0 results |
| ChoiceChip audit | `grep -rn "ChoiceChip\|SingleChildScrollView" day_chip_row.dart` | ✅ 0 results |
| Card audit | `grep -n "Card(" slot_card.dart` | ✅ 0 results |

Note: `Color(0xFF...)` and `AppTheme.primaryGreen` references found in `slot_day_view.dart` and `slot_event_tile.dart` are out of Phase 24 scope — those files handle the admin calendar view and are addressed in a future phase.

## Requirements Satisfied

| Requirement | Status |
|-------------|--------|
| SCHED-04 — Day selector → underline strip (SportDayStrip) | ✅ Complete |
| SCHED-05 — Slot rows hairline, myBooking stripe, opacity 0.45 (SlotHairlineRow) | ✅ Complete |
| SCHED-06 — Wordmark header + eyebrow date (no AppBar) | ✅ Complete |

## Human Verification Required

Deploy to staging (vida-ativa-staging) and verify:
1. No AppBar — orange pill "VIDA ATIVA" left, eyebrow date right
2. Day strip: 7 columns with underline on selected, no ChoiceChip
3. Slot rows: no Card/elevation, hairline dividers
4. myBooking: 3px orange left stripe, opens ClientBookingDetailSheet on tap
5. booked/blocked: dimmed ~0.45 opacity, not tappable
6. available: full opacity, "DISPONÍVEL" green, opens BookingConfirmationSheet on tap

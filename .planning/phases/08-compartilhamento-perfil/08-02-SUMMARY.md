---
phase: 08-compartilhamento-perfil
plan: 02
subsystem: booking, auth
tags: [flutter, whatsapp, url_launcher, share, phone, profile, bottomsheet]

requires:
  - phase: 07-visibilidade-social
    provides: BookingCard with participants display, BookingModel with participants
  - plan: 08-01
    provides: PhoneInputFormatter, AuthCubit.updatePhone()

provides:
  - feature: SOCIAL-03 — WhatsApp share button in BookingCard
  - feature: PROF-02 — Phone edit BottomSheet in ProfileScreen

key-files:
  modified:
    - lib/features/booking/ui/booking_card.dart
    - lib/features/auth/ui/profile_screen.dart
    - pubspec.yaml
---

# Plan 08-02 Summary

## What Was Built

### Task 1: WhatsApp Share Button in BookingCard
Added `url_launcher: ^6.3.1` to `pubspec.yaml`. Added `_shareWhatsApp()` method to `BookingCard` that builds the pre-formatted message and opens `https://wa.me/?text=...` via `launchUrl`. Share icon (`Icons.share`) appears alongside edit/cancel buttons for bookings with status `confirmed` or `pending` (condition: `!booking.isCancelled && booking.status != 'rejected'`). The participants line (`👥 ...`) is omitted from the message when `booking.participants` is null or empty.

### Task 2: Phone Edit BottomSheet in ProfileScreen
Added phone display row with edit icon to `ProfileScreen`. `_showEditPhoneSheet()` top-level function opens a `showModalBottomSheet` with a pre-filled phone field using `PhoneInputFormatter`, a `Salvar` button calling `authCubit.updatePhone()`, and a SnackBar confirmation "Telefone salvo" on success.

## Commits
- `745315e` feat(08-02): add WhatsApp share button to BookingCard
- `fa02803` feat(08-02): add phone edit BottomSheet to ProfileScreen

## Self-Check: PASSED

- BookingCard contains `_shareWhatsApp` method ✓
- Share icon condition: `!booking.isCancelled && booking.status != 'rejected'` ✓
- Message template: "🏐 Reserva confirmada para {nome}" with participants line conditional ✓
- url_launcher in pubspec.yaml ✓
- ProfileScreen shows phone field with edit icon ✓
- BottomSheet uses PhoneInputFormatter ✓
- SnackBar shows "Telefone salvo" ✓
- flutter analyze: 6 pre-existing issues, 0 new ✓

## Decisions Logged
- [Phase 08-02]: `context.read<AuthCubit>()` captured before `showModalBottomSheet` builder — avoids context access in sheet subtree
- [Phase 08-02]: `_showEditPhoneSheet` is a top-level function (not a method) — ProfileScreen is StatelessWidget, consistent with existing pattern
- [Phase 08-02]: Share button omits 👥 line entirely when participants null/empty — cleaner message for solo bookings

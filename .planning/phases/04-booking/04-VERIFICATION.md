---
phase: 04-booking
verified: 2026-03-20T00:00:00Z
status: approved
score: 10/10 must-haves verified
human_verification:
  - test: "Tap available slot, confirm booking, verify reactive slot status change"
    expected: "Bottom sheet opens with Portuguese date/time/price; tapping Reservar shows spinner, closes sheet with SnackBar 'Reserva feita!'; slot card switches to 'Minha reserva' badge without refresh"
    why_human: "Visual flow, reactive Firestore stream, and real-time UI update require a running app and live Firebase connection"
  - test: "Navigate to Minhas Reservas tab and verify Proximas / Passadas sections"
    expected: "Booking appears under Proximas with correct date, time, price, orange 'Aguardando' badge, and red Cancelar button"
    why_human: "Screen rendering and section layout require a running app"
  - test: "Cancel a future booking via AlertDialog"
    expected: "Tapping Cancelar shows dialog with 'Cancelar reserva?' title and Sim/Nao; tapping Sim shows SnackBar 'Reserva cancelada.' and booking moves to Passadas with grey 'Cancelado' badge; slot becomes available again on Tab 0"
    why_human: "End-to-end cancel flow and reactive state update require a running app with live Firebase"
  - test: "Double-booking prevention: attempt to book same slot from two browser tabs simultaneously"
    expected: "Second attempt receives error and SnackBar shows 'Este horario acabou de ser reservado.' — sheet stays open"
    why_human: "Concurrency behavior requires two simultaneous browser sessions and live Firestore transaction"
  - test: "Empty state: Minhas Reservas with no bookings"
    expected: "Shows 'Voce nao tem nenhuma reserva ainda.' and a 'Ver Agenda' button that navigates to Tab 0"
    why_human: "Navigation behavior and empty-state rendering require a running app"
---

# Phase 4: Booking Verification Report

**Phase Goal:** Users can reserve an available slot, view their own bookings, and cancel a booking — with zero risk of double-booking due to concurrent reservations
**Verified:** 2026-03-20
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths — Plan 01

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Firestore web persistence is disabled before runApp | VERIFIED | `main.dart` lines 16-20: `if (kIsWeb) { FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false); }` placed before `runApp` |
| 2 | BookingCubit streams the current user bookings from Firestore | VERIFIED | `booking_cubit.dart` lines 23-37: `_startStream()` subscribes to `bookings` collection filtered by `userId`, maps docs via `BookingModel.fromFirestore`, emits `BookingLoaded` |
| 3 | BookingCubit.bookSlot uses runTransaction with deterministic doc ID and checks !isCancelled | VERIFIED | `booking_cubit.dart` lines 39-68: `runTransaction` used, `BookingModel.generateId(slotId, dateString)` for doc ID, `if (!existing.isCancelled) throw Exception('slot_already_booked')` on line 52 |
| 4 | BookingCubit.cancelBooking updates status to cancelled with cancelledAt timestamp | VERIFIED | `booking_cubit.dart` lines 70-76: `.update({'status': 'cancelled', 'cancelledAt': Timestamp.fromDate(DateTime.now())})` |
| 5 | BookingCubit is provided at StatefulShellRoute level so both Schedule and Bookings tabs access it | VERIFIED | `app_router.dart` lines 96-106: `StatefulShellRoute.indexedStack` builder wraps `AppShell` with `BlocProvider<BookingCubit>` using `authState.user.uid` |
| 6 | BookingModel stores startTime and price for display in My Bookings | VERIFIED | `booking_model.dart` lines 12-13: `final String? startTime` and `final double? price`; `fromFirestore` reads both; `toFirestore` writes both conditionally; included in `props` |

### Observable Truths — Plan 02

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 7 | User can tap an available slot and see a confirmation bottom sheet with date, time, and price | VERIFIED (automated) | `slot_list.dart` line 50-52: `onTap: vm.status == SlotStatus.available ? () => _showBookingSheet(context, vm) : null`; `slot_card.dart` line 14: `InkWell(onTap: onTap, ...)`; `booking_confirmation_sheet.dart` renders date, time, price rows |
| 8 | User can confirm booking and the bottom sheet closes with a SnackBar on success | VERIFIED (automated) | `booking_confirmation_sheet.dart` lines 38-43: `Navigator.pop(context)` then `showSnackBar('Reserva feita!')` after `bookSlot` awaits |
| 9 | User can see their bookings split into Proximas and Passadas sections | VERIFIED (automated) | `my_bookings_screen.dart` lines 39-47: filters and sorts `upcoming` and `past` lists; lines 69-104: renders both sections with bold headers |
| 10 | User can cancel a future booking via inline red Cancel button with AlertDialog confirmation | VERIFIED (automated) | `booking_card.dart` line 69-76: `TextButton('Cancelar', color: Colors.red)` shown when `isFuture && !booking.isCancelled`; `my_bookings_screen.dart` lines 109-145: `_confirmCancel` shows `AlertDialog` with Sim/Nao and calls `cancelBooking` |

**Score:** 10/10 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/features/booking/cubit/booking_state.dart` | Sealed BookingState classes | VERIFIED | `sealed class BookingState extends Equatable`; all 4 subclasses present (Initial, Loading, Loaded, Error) |
| `lib/features/booking/cubit/booking_cubit.dart` | BookingCubit with stream, bookSlot, cancelBooking | VERIFIED | All three methods implemented; `runTransaction` present; `close()` cancels subscription |
| `lib/main.dart` | Firestore persistence disabled for web | VERIFIED | `persistenceEnabled: false` inside `if (kIsWeb)` before `runApp` |
| `lib/core/router/app_router.dart` | BookingCubit provided at shell level | VERIFIED | `BlocProvider<BookingCubit>` at `StatefulShellRoute` builder; `MyBookingsScreen` wired to `/bookings` route; no reference to `MyBookingsPlaceholderScreen` |
| `lib/core/models/booking_model.dart` | BookingModel with optional startTime and price fields | VERIFIED | Both fields present, serialized in `fromFirestore`/`toFirestore`, included in `props` |
| `lib/features/schedule/ui/slot_card.dart` | SlotCard with onTap callback for available slots | VERIFIED | `VoidCallback? onTap` parameter; `InkWell(onTap: onTap)` wraps Card |
| `lib/features/schedule/ui/slot_list.dart` | SlotList passing onTap to SlotCard and showing bottom sheet | VERIFIED | `_showBookingSheet` called for `SlotStatus.available`; `showModalBottomSheet` with `BookingConfirmationSheet`; `context.read<BookingCubit>()` captured before builder |
| `lib/features/booking/ui/booking_confirmation_sheet.dart` | Bottom sheet StatefulWidget with local isSubmitting, inline loading button | VERIFIED | `StatefulWidget`; `_isSubmitting` and `_errorMessage` state fields; `CircularProgressIndicator` inline; error shown without closing |
| `lib/features/booking/ui/booking_card.dart` | Booking card with status badge and cancel button | VERIFIED | Status badges (Aguardando/Confirmado/Cancelado) with correct colors; Cancelar TextButton conditional on `isFuture && !booking.isCancelled` |
| `lib/features/booking/ui/my_bookings_screen.dart` | My Bookings screen with Proximas/Passadas sections | VERIFIED | `BlocBuilder<BookingCubit, BookingState>`; Proximas/Passadas sections; empty state with `Ver Agenda` + `goBranch(0)` |
| `lib/features/booking/ui/my_bookings_placeholder_screen.dart` | Must NOT exist | VERIFIED | File does not exist; no references in codebase |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `slot_list.dart` | `booking_confirmation_sheet.dart` | `showModalBottomSheet` triggered by SlotCard onTap | WIRED | `_showBookingSheet` captures cubit, calls `showModalBottomSheet` passing `BookingConfirmationSheet` |
| `booking_confirmation_sheet.dart` | `booking_cubit.dart` | `bookingCubit.bookSlot()` call | WIRED | `widget.bookingCubit.bookSlot(slotId, dateString, price, startTime)` called in `_handleConfirm` |
| `my_bookings_screen.dart` | `booking_cubit.dart` | `BlocBuilder<BookingCubit, BookingState>` | WIRED | `BlocBuilder<BookingCubit, BookingState>` at root of body; exhaustive switch on all states |
| `booking_card.dart` | `booking_cubit.dart` | `cancelBooking()` from AlertDialog | WIRED | `context.read<BookingCubit>().cancelBooking(booking.id)` in `_confirmCancel` in `my_bookings_screen.dart` |
| `app_router.dart` | `booking_cubit.dart` | `BlocProvider` at `StatefulShellRoute` builder | WIRED | `BlocProvider(create: (_) => BookingCubit(firestore: FirebaseFirestore.instance, userId: authState.user.uid))` |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| BOOK-01 | 04-01, 04-02 | Usuário pode reservar um horário disponível (transação atômica — sem double booking) | SATISFIED | `runTransaction` with deterministic doc ID + `!isCancelled` check; `BookingConfirmationSheet` calls `bookSlot`; error surfaced inline |
| BOOK-02 | 04-01, 04-02 | Usuário pode cancelar sua própria reserva | SATISFIED | `cancelBooking` updates Firestore; `_confirmCancel` + `AlertDialog` flow in `MyBookingsScreen`; reactive stream updates UI |
| BOOK-03 | 04-01, 04-02 | Usuário pode ver suas reservas futuras e passadas | SATISFIED | `MyBookingsScreen` with `BlocBuilder`; Proximas/Passadas sections with correct sort order |

No orphaned requirements: BOOK-01, BOOK-02, BOOK-03 are the only Phase 4 requirements in REQUIREMENTS.md; all three are claimed by both plans.

### Anti-Patterns Found

No anti-patterns detected. Scanned all booking feature files and modified schedule UI files for TODO/FIXME/placeholder comments, empty return values, and stub implementations — none found.

### Human Verification Required

#### 1. Reserve a slot end-to-end

**Test:** Open the app, navigate to Tab 0 (Agenda), tap a green available slot.
**Expected:** Bottom sheet opens showing Portuguese-formatted date (e.g., "Sexta-feira, 20 de marco"), time, and price. Tap "Reservar" — button shows spinner, then sheet closes and SnackBar "Reserva feita!" appears. Slot card reactively changes to "Minha reserva" badge without page refresh.
**Why human:** Visual rendering, Portuguese locale formatting via `intl`, and Firestore stream reactivity require a live app and Firebase.

#### 2. View My Bookings with Proximas / Passadas split

**Test:** After booking, switch to Tab 1 (Minhas Reservas).
**Expected:** Booking appears under "Proximas" section header with formatted date, time, price, orange "Aguardando" status badge, and red "Cancelar" TextButton.
**Why human:** Screen layout, color rendering, and section display require a running app.

#### 3. Cancel a booking via AlertDialog

**Test:** In Minhas Reservas, tap "Cancelar" on a future booking.
**Expected:** AlertDialog appears with title "Cancelar reserva?" and "Nao"/"Sim" buttons. Tapping "Sim" dismisses dialog, shows SnackBar "Reserva cancelada.", and booking moves to "Passadas" with grey "Cancelado" badge. Switching to Tab 0 shows the slot as available again.
**Why human:** End-to-end cancel flow with reactive updates requires live Firebase.

#### 4. Double-booking prevention

**Test:** Open two browser tabs simultaneously. As user A in tab 1, open the confirmation sheet for a slot but do not confirm yet. As user B in tab 2, book the same slot first. Then confirm as user A.
**Expected:** User A's confirmation fails; error message "Este horario acabou de ser reservado." appears inline in the sheet without closing it.
**Why human:** Concurrency behavior requires simultaneous browser sessions and live Firestore transactions.

#### 5. Empty state navigation

**Test:** Access Minhas Reservas with a new account that has no bookings.
**Expected:** Shows "Voce nao tem nenhuma reserva ainda." and a filled "Ver Agenda" button. Tapping it switches to Tab 0.
**Why human:** `StatefulNavigationShell.of(context).goBranch(0)` navigation behavior requires a running app.

### Gaps Summary

No gaps found. All 10 observable truths are verified at all three levels (exists, substantive, wired). All 11 required artifacts pass. All 5 key links are wired. Requirements BOOK-01, BOOK-02, and BOOK-03 are fully satisfied by the implementation.

The remaining human verification items are behavioral/visual checks that cannot be confirmed via static code analysis. The automated evidence strongly supports the implementation is correct and complete.

---

_Verified: 2026-03-20_
_Verifier: Claude (gsd-verifier)_

---
plan: 05-02
phase: 05-admin
status: complete
tasks_completed: 2
tasks_total: 2
commits:
  - "feat(05-02): create AdminScreen, SlotManagementTab, SlotFormSheet, BlockedDatesTab"
  - "feat(05-02): wire admin router, add BookingManagementTab, AdminBookingCard, profile admin button"
  - "chore(05-02): remove AdminPlaceholderScreen now replaced by real AdminScreen"
---

# Plan 05-02 Summary — Admin UI

## What Was Built

**Task 1 — Admin screen structure and slot/blocked-date management:**
- `AdminScreen` — `DefaultTabController` with 3 tabs (Slots, Bloqueios, Reservas); no BlocProviders here (provided by router)
- `SlotManagementTab` — `BlocBuilder<AdminSlotCubit>` with slot list; each card shows day name, time, price, and `Switch` for active toggle; tap to edit; FAB to create; inactive slots shown at 50% opacity
- `SlotFormSheet` — `StatefulWidget` bottom sheet; create/edit form with `DropdownButtonFormField` for day, `showTimePicker` for time, `TextFormField` for price; receives `AdminSlotCubit` as constructor param to avoid context loss in modal
- `BlockedDatesTab` — `BlocBuilder<AdminBlockedDateCubit>`; list with delete button per entry; FAB opens `showDatePicker`; confirms unblock via `AlertDialog`

**Task 2 — Booking management, router wiring, profile entry:**
- `BookingManagementTab` — date navigation row (prev/next day + date picker), `SwitchListTile` for confirmation mode toggle (automatic/manual), `Expanded` list of `AdminBookingCard` widgets
- `AdminBookingCard` — 4-status card (pending/confirmed/rejected/cancelled) with `userDisplayName` display; confirm/reject action buttons shown only for pending bookings; receives `AdminBookingCubit` as constructor param
- `app_router.dart` — `/admin` route builder replaced: now provides `AdminSlotCubit`, `AdminBlockedDateCubit`, `AdminBookingCubit` via `MultiBlocProvider`, renders real `AdminScreen`
- `profile_screen.dart` — `FilledButton.icon('Painel Admin')` added above logout button, conditionally shown for `user.isAdmin`; navigates via `GoRouter.of(context).go('/admin')`
- `admin_placeholder_screen.dart` deleted

## Key Files Created/Modified

### Created
- `lib/features/admin/ui/admin_screen.dart`
- `lib/features/admin/ui/slot_management_tab.dart`
- `lib/features/admin/ui/slot_form_sheet.dart`
- `lib/features/admin/ui/blocked_dates_tab.dart`
- `lib/features/admin/ui/booking_management_tab.dart`
- `lib/features/admin/ui/admin_booking_card.dart`

### Modified
- `lib/core/router/app_router.dart` — MultiBlocProvider with 3 admin cubits, AdminScreen wired
- `lib/features/auth/ui/profile_screen.dart` — admin entry button added

### Deleted
- `lib/features/admin/ui/admin_placeholder_screen.dart`

## Build Verification

`flutter build web --no-tree-shake-icons` → exit 0 ✓

## Notable Decisions

- `SlotFormSheet` and `AdminBookingCard` receive their cubits as constructor parameters (not `context.read`) — follows Phase 4 pattern for context capture before modal/dialog
- `AdminScreen` has no `BlocProvider` — all cubits provided at router level via `MultiBlocProvider` so all 3 tabs share the same cubit instances
- Confirmation mode toggle uses `SwitchListTile` in `BookingManagementTab` — reads `state.confirmationMode` and calls `cubit.setConfirmationMode`

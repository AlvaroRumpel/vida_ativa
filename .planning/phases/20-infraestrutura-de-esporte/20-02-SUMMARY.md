---
phase: 20-infraestrutura-de-esporte
plan: "02"
subsystem: sport-booking-ui
tags:
  - flutter
  - bloc
  - ui
  - booking
dependency_graph:
  requires:
    - BookingModel.sport (Plan 01)
    - SportConfigCubit (Plan 01 — /config/sports)
  provides:
    - BookingConfirmationSheet.sports param + DropdownButtonFormField
    - bookSlot String? sport param
    - bookRecurring String? sport param
  affects:
    - lib/features/admin/ui/settings_tab.dart (Plan 03 consumer — admin edits sports list)
tech_stack:
  added: []
  patterns:
    - One-shot Firestore read before showModalBottomSheet (avoids BlocProvider coupling)
    - Conditional widget rendering via if (list.isNotEmpty)
    - DropdownButtonFormField<String?> with null item for "Não informado"
key_files:
  created: []
  modified:
    - lib/features/booking/cubit/booking_cubit.dart
    - lib/features/booking/ui/booking_confirmation_sheet.dart
    - lib/features/schedule/ui/slot_day_view.dart
    - lib/features/schedule/ui/slot_list.dart
decisions:
  - "Sports list passed as constructor param to BookingConfirmationSheet (not BlocBuilder) — avoids admin cubit coupling in client UI"
  - "One-shot FirebaseFirestore.instance.collection('config').doc('sports').get() per tap — no stream, no polling; refresh on next sheet open"
  - "DropdownButtonFormField uses initialValue (not deprecated value param) per Flutter 3.33+ API"
  - "slot_day_view uses mounted (State property) instead of context.mounted after async gap per lint recommendation"
metrics:
  duration_minutes: 12
  completed_date: "2026-05-20"
  tasks_completed: 3
  tasks_total: 3
  files_modified: 4
---

# Phase 20 Plan 02: Sport Booking UI Summary

**One-liner:** Optional sport dropdown added to BookingConfirmationSheet via constructor param + one-shot Firestore read in both schedule callers; sport propagates through bookSlot/bookRecurring into BookingModel and persists to Firestore.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Estender BookingCubit.bookSlot e bookRecurring com parâmetro sport | cf1d8cf | lib/features/booking/cubit/booking_cubit.dart |
| 2 | Adicionar parâmetro sports e dropdown ao BookingConfirmationSheet | 624a3b9 | lib/features/booking/ui/booking_confirmation_sheet.dart |
| 3 | Wire callers em slot_day_view e slot_list para passar sports ao sheet | d3dfbbe | lib/features/schedule/ui/slot_day_view.dart, lib/features/schedule/ui/slot_list.dart |

## Verification

- `flutter analyze lib/features/booking/cubit/booking_cubit.dart` — No issues found
- `flutter analyze lib/features/booking/ui/booking_confirmation_sheet.dart` — No issues found
- `flutter analyze lib/features/schedule/ui/slot_day_view.dart lib/features/schedule/ui/slot_list.dart` — No issues found

**Manual smoke (to be done on device/browser):**
1. Open slot — see dropdown "Esporte (opcional)" between participants field and action buttons
2. Select "Vôlei", confirm on_arrival — Firestore doc shows `sport: "Vôlei"`
3. Leave "Não informado" selected, confirm — Firestore doc has no `sport` field
4. Clear /config/sports in console, open slot — dropdown not rendered
5. Recurring booking with sport selected — all group bookings have `sport: "X"`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Replaced deprecated `value` with `initialValue` in DropdownButtonFormField**
- **Found during:** Task 2
- **Issue:** `DropdownButtonFormField.value` is deprecated after Flutter v3.33.0-1.0.pre; IDE diagnostic flagged as Information severity
- **Fix:** Changed `value: _selectedSport` to `initialValue: _selectedSport`
- **Files modified:** lib/features/booking/ui/booking_confirmation_sheet.dart
- **Commit:** 624a3b9

**2. [Rule 1 - Bug] Used `mounted` instead of `context.mounted` in slot_day_view**
- **Found during:** Task 3
- **Issue:** Analyzer flagged `context.mounted` in State subclass — should use `mounted` (State property) for clarity
- **Fix:** Changed `if (!context.mounted) return;` to `if (!mounted) return;` in `_SlotDayViewState._showBookingSheet`
- **Files modified:** lib/features/schedule/ui/slot_day_view.dart
- **Commit:** d3dfbbe

## Known Stubs

None. All UI is wired to live Firestore data; sports list comes from /config/sports written by Plan 01 SportConfigCubit with defaults.

## Threat Flags

No new threat surface beyond what is documented in the plan's threat model (T-20-05 through T-20-08).

- T-20-05 (Tampering — client injects arbitrary sport string): Accepted per plan; dropdown restricts UI but Firestore client SDK allows any value; no server-side validation in scope.
- T-20-07 (DoS via repeated sheet opens): Mitigated by one-shot read per tap; Firestore native rate limiting applies.
- T-20-08 (null sport when dropdown hidden): Mitigated — `_selectedSport` defaults null; `if (sport != null)` in toFirestore omits the key.

## Self-Check: PASSED

Files exist:
- lib/features/booking/cubit/booking_cubit.dart — FOUND
- lib/features/booking/ui/booking_confirmation_sheet.dart — FOUND
- lib/features/schedule/ui/slot_day_view.dart — FOUND
- lib/features/schedule/ui/slot_list.dart — FOUND

Commits exist:
- cf1d8cf — Task 1
- 624a3b9 — Task 2
- d3dfbbe — Task 3

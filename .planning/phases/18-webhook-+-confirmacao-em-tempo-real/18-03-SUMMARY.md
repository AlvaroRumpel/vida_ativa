---
phase: 18-webhook-confirmacao-em-tempo-real
plan: 03
subsystem: admin-ui
tags: [flutter, admin, pix, status-badges, manual-confirm]
dependency_graph:
  requires: [18-01, 18-02]
  provides: [admin-pix-status-display, admin-manual-pix-confirm]
  affects: [admin_booking_card, admin_booking_detail_sheet]
tech_stack:
  added: []
  patterns: [(status, paymentMethod) tuple switch, FirebaseFirestore manual update, FilledButton.icon with loading state]
key_files:
  created: []
  modified:
    - lib/features/admin/ui/admin_booking_card.dart
    - lib/features/admin/ui/admin_booking_detail_sheet.dart
decisions:
  - "(status, paymentMethod) tuple switch used in both files for consistent badge logic"
  - "Manual confirm updates PaymentRecord subcollection directly via FirebaseFirestore instance (no cubit abstraction needed for one-off admin action)"
  - "pending_payment button placed ABOVE isPending confirm/reject row — primary action for that status"
metrics:
  duration: 5min
  completed_date: "2026-04-09T02:37:16Z"
  tasks_completed: 2
  files_modified: 2
---

# Phase 18 Plan 03: Admin UI Pix Status Badges + Manual Confirm Summary

Admin UI updated with payment-aware status badges and manual Pix confirmation fallback for when webhook fails.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Extend AdminBookingCard with payment status badges | 3d6b61d | lib/features/admin/ui/admin_booking_card.dart |
| 2 | Add manual payment confirmation to AdminBookingDetailSheet | 3eebd24 | lib/features/admin/ui/admin_booking_detail_sheet.dart |

## What Was Built

### AdminBookingCard
- `_statusColor(String status, String? paymentMethod)` — tuple switch replaces single-arg version
- `_statusLabel(String status, String? paymentMethod)` — tuple switch
- 4 new badge states: "Aguardando Pix" (#FFC107 amber), "Pix pago" (#4CAF50 green), "Expirada" (grey), "Pagar na hora" (#2196F3 blue)

### AdminBookingDetailSheet
- Same tuple-based `_statusColor`/`_statusLabel` methods for consistency
- `_handleManualConfirm()`: shows confirmation dialog, calls `confirmBooking()`, updates PaymentRecord subcollection to `status: paid` + `paidAt: serverTimestamp()`, shows snackbar, closes sheet
- "Confirmar pagamento manual" `FilledButton.icon` visible only when `booking.status == 'pending_payment'`
- Placed above the existing confirm/reject row

## Deviations from Plan

None — plan executed exactly as written.

## Verification

- `dart analyze lib/features/admin/` — No issues found
- Both files have consistent (status, paymentMethod) tuple switch statements
- Manual confirm button guarded by `booking.status == 'pending_payment'`
- PaymentRecord update guarded by `booking.paymentId != null` null check

## Self-Check

- [x] `lib/features/admin/ui/admin_booking_card.dart` — exists and committed (3d6b61d)
- [x] `lib/features/admin/ui/admin_booking_detail_sheet.dart` — exists and committed (3eebd24)
- [x] Both commits exist in git log

## Self-Check: PASSED

---
status: partial
phase: 24-agenda-cliente
source: [24-VERIFICATION.md]
started: 2026-05-26
updated: 2026-05-26
---

## Current Test

[awaiting human testing in staging]

## Tests

### 1. Header visual
expected: Orange pill "VIDA ATIVA" on left, eyebrow date (e.g. "SEG, 26 MAI") on right, no AppBar chrome
result: [pending]

### 2. Day strip interaction
expected: Tapping a different day moves the orange underline to that column; eyebrow date updates to match
result: [pending]

### 3. Today highlight
expected: Today's day number renders in AppTheme.orange even when not the selected day
result: [pending]

### 4. Slot row appearance
expected: No Card elevation or shadow; hairline dividers visible between rows
result: [pending]

### 5. myBooking tap
expected: Tapping a myBooking slot (orange left stripe) opens ClientBookingDetailSheet
result: [pending]

### 6. Available slot tap
expected: Tapping an available slot ("DISPONÍVEL" in green) opens BookingConfirmationSheet
result: [pending]

### 7. Booked/blocked dimmed
expected: Booked and blocked rows render at ~45% opacity; tapping produces no ripple or action
result: [pending]

## Summary

total: 7
passed: 0
issues: 0
pending: 7
skipped: 0
blocked: 0

## Gaps

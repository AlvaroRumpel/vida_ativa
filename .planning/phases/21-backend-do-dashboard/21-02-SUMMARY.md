---
phase: 21-backend-do-dashboard
plan: "02"
subsystem: cloud-functions
tags:
  - firebase
  - cloud-functions
  - aggregation
  - firestore
  - dashboard
dependency_graph:
  requires:
    - functions/index.js (existing exports: onDocumentWritten, onSchedule, admin)
  provides:
    - exports.onBookingStateChange (write-time booking counter aggregation)
    - exports.scheduledDailyAggregation (daily full recalculation at 03:00 BRT)
    - helpers: toDateStr, getCurrentPeriodRanges, getActivePeriods, computeDeltas, aggregateForPeriod
  affects:
    - /config/dashboard/periods/week (Firestore doc)
    - /config/dashboard/periods/month (Firestore doc)
    - /config/dashboard/periods/year (Firestore doc)
tech_stack:
  added: []
  patterns:
    - FieldValue.increment for atomic write-time counter updates
    - batch.set+merge to handle first-deploy doc-not-found case
    - onSchedule with timeZone options object (not bare string)
    - per-period try/catch in scheduled to isolate failures
key_files:
  modified:
    - functions/index.js (+398 lines, 2 new exports, 5 helper functions)
decisions:
  - "batch.set+merge used instead of batch.update to prevent NOT_FOUND on first-deploy (Pitfall 1)"
  - "timeZone specified in options object {schedule, timeZone} not bare string (Pitfall 4)"
  - "pending_payment->confirmed always uses pixRevenue path (all pending_payment bookings are Pix in this codebase)"
  - "expired and refunded statuses skipped in aggregateForPeriod (consistent with write-time behavior)"
  - "per-period try/catch in scheduledDailyAggregation: one bad period does not block the others"
metrics:
  duration_minutes: 15
  completed_date: "2026-05-21"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 1
---

# Phase 21 Plan 02: Backend do Dashboard — Cloud Functions Summary

Two Cloud Functions added to `functions/index.js` providing complete write-time and scheduled aggregation for dashboard metrics covering DASH-01..04 and DASH-09..12.

## What Was Built

**Task 1: Helpers + onBookingStateChange**

Four helper functions plus the `onBookingStateChange` export:

- `toDateStr(d)` — formats Date to `YYYY-MM-DD` using local components (avoids UTC offset bugs)
- `getCurrentPeriodRanges()` — returns Mon-Sun / 1st-last / Jan1-Dec31 for current rolling windows (D-02: ISO week)
- `getActivePeriods(bookingDate)` — returns subset of `['week','month','year']` containing the booking date
- `computeDeltas(before, after)` — maps all 9 status transitions to signed counter deltas

`onBookingStateChange` trigger: `onDocumentWritten('bookings/{bookingId}')`. On every booking write, computes deltas via `computeDeltas`, wraps with `FieldValue.increment`, and writes to `/config/dashboard/periods/{week|month|year}` via `batch.set({...}, {merge:true})`. The merge option handles the first-deploy case where docs don't yet exist.

**Task 2: aggregateForPeriod + scheduledDailyAggregation**

Helper `aggregateForPeriod(db, period, startDate, endDate)` reads `/bookings` and `/slots` for the period and computes all 8 dashboard metrics:
- Simple counters: totalBookings, confirmedBookings, cancelledBookings, pendingBookings, totalSlotsBooked, totalRevenue, pixRevenue, onArrivalRevenue
- Slot-based: totalSlotsAvailable (query `slots where isActive==true`), occupancyRate
- Calculated: avgTicket, conversionRate, noShowRate
- Client metrics: uniqueClients, newClients (first-ever confirmed booking in period), returnRate, topClients (top 5 with displayName lookup), revenueBySport

`scheduledDailyAggregation` runs at `every day 03:00` with `timeZone: 'America/Sao_Paulo'`. Loops over week/month/year, calls `aggregateForPeriod`, and does a full `set()` overwrite. Each period wrapped in try/catch so a failure in one period does not block the others.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | `1be9874` | feat(21-02): add onBookingStateChange CF maintaining /config/dashboard/periods counters (D-01..D-06) |
| 2 | `6edfc5f` | feat(21-02): add scheduledDailyAggregation CF recalculating all dashboard fields at 03:00 BRT (D-07..D-12) |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — both Cloud Functions are complete implementations. No placeholder values or TODO stubs present.

## Threat Flags

None — no new network endpoints, auth paths, or schema changes beyond what the plan's threat model (`T-21-04` through `T-21-09`) already covers.

## Self-Check: PASSED

- `functions/index.js` contains `exports.onBookingStateChange` — FOUND
- `functions/index.js` contains `exports.scheduledDailyAggregation` — FOUND
- `functions/index.js` contains all 5 helper functions — FOUND
- `node --check functions/index.js` — exit code 0
- Commits `1be9874` and `6edfc5f` — FOUND in git log

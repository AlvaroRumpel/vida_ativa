---
phase: 18-webhook-confirmacao-em-tempo-real
plan: 01
subsystem: payments
tags: [mercadopago, firebase-functions, webhook, hmac-sha256, firestore, scheduler]

requires:
  - phase: 17-pagamento-pix-qr-code
    provides: createPixPayment CF that creates PaymentRecord subcollection and sets expiresAt on booking

provides:
  - handlePixWebhook onRequest Cloud Function export with HMAC-SHA256 signature verification
  - expireUnpaidBookings onSchedule Cloud Function export running every 15 minutes

affects:
  - 18-02 (Flutter real-time listener — depends on booking.status being updated to confirmed by this webhook)
  - 18-03 (deploy + Mercado Pago webhook URL registration)

tech-stack:
  added: [onRequest (firebase-functions/v2/https), onSchedule (firebase-functions/v2/scheduler), crypto (Node.js built-in), MP_WEBHOOK_SECRET (Secret Manager)]
  patterns: [202-before-async webhook pattern, HMAC-SHA256 x-signature verification, transactionId idempotency key, Firestore runTransaction for atomic booking confirmation, batch.update for bulk expiry]

key-files:
  created: []
  modified: [functions/index.js]

key-decisions:
  - "res.status(202).send() fires before all async work — prevents Mercado Pago retry on slow processing"
  - "transactionId (MP payment ID) used as idempotency key — duplicate webhooks silently skipped"
  - "expireUnpaidBookings uses Firestore batch.update in chunks of 500 to respect Firestore batch limit"

patterns-established:
  - "Webhook pattern: return 202 first, process in background"
  - "HMAC verification: manifest = id:{dataId};request-id:{xRequestId};ts:{tsValue};"

requirements-completed: [PIX-04, PIX-07]

duration: 8min
completed: 2026-04-08
---

# Phase 18 Plan 01: Webhook Backend Summary

**HMAC-SHA256 verified Mercado Pago webhook CF (202-before-async) + 15-min expiry scheduler CF using Firestore transactions and batch updates**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-08T20:50:00Z
- **Completed:** 2026-04-08T20:58:00Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- handlePixWebhook onRequest CF: verifies x-signature HMAC-SHA256 with MP_WEBHOOK_SECRET, returns 202 before async work, idempotent via transactionId, atomically updates booking to confirmed + PaymentRecord to paid
- expireUnpaidBookings onSchedule CF: runs every 15 minutes, finds pending_payment bookings past expiresAt, batch-updates status to expired (500 docs/batch)
- Both functions syntactically valid — Node.js require succeeds, all 4 exports listed

## Task Commits

1. **Task 1: Add handlePixWebhook Cloud Function** - `090533f` (feat)
2. **Task 2: Add expireUnpaidBookings Scheduled Cloud Function** - `090533f` (feat — committed together, same file)

## Files Created/Modified

- `functions/index.js` - Added onRequest + onSchedule imports, crypto require, mpWebhookSecret defineSecret, verifyMpSignature helper, handlePixWebhook export, expireUnpaidBookings export

## Decisions Made

- Tasks 1 and 2 committed together (single file, single logical change — both new CF exports)
- verifyMpSignature implemented as module-private helper function (not exported)
- external_reference field from MP webhook body used as bookingId — matches createPixPayment setup in Phase 17

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

**MP_WEBHOOK_SECRET must be configured before deploy.** Steps:
1. Get webhook signing secret from Mercado Pago developer dashboard (Integraciones > Webhooks)
2. Add to Firebase Secret Manager: `echo "your_secret" | firebase functions:secrets:set MP_WEBHOOK_SECRET`
3. Deploy functions: `firebase deploy --only functions`
4. Register webhook URL `https://us-central1-{project}.cloudfunctions.net/handlePixWebhook` in MP dashboard

## Next Phase Readiness

- Backend webhook loop is complete — payments confirmed automatically, unpaid bookings expire automatically
- Ready for 18-02: Flutter Firestore real-time listener that reacts to booking.status changing to confirmed
- Ready for 18-03: deploy + end-to-end sandbox test

---
*Phase: 18-webhook-confirmacao-em-tempo-real*
*Completed: 2026-04-08*

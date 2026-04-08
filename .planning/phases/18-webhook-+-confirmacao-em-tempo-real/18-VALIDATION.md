---
phase: 18
slug: webhook-confirmacao-em-tempo-real
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-08
---

# Phase 18 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter Test + Cloud Functions local emulator (jest/mocha) |
| **Config file** | `test/`, `pubspec.yaml`, `firebase.json` (emulator config) |
| **Quick run command** | `flutter test test/features/booking/ -k "pix"` |
| **Full suite command** | `flutter test` + `firebase emulators:exec "npm test"` |
| **Estimated runtime** | ~15-20 min (full suite) |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/features/booking/ -k "pix"`
- **After every plan wave:** Run `flutter test` + `firebase emulators:exec "npm test"`
- **Before `/gsd:verify-work`:** Full suite must be green + manual webhook test with Mercado Pago sandbox
- **Max feedback latency:** 10 minutes

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 18-01 | 01 | 0 | PIX-03 | widget | `flutter test test/features/booking/pix_payment_screen_test.dart` | ❌ W0 | ⬜ pending |
| 18-02 | 01 | 0 | PIX-04 | integration/CF | `firebase emulators:exec "npm test -- handlePixWebhook"` | ❌ W0 | ⬜ pending |
| 18-03 | 01 | 0 | PIX-05 | integration | `flutter test test/features/booking/my_bookings_screen_test.dart` | ❌ W0 | ⬜ pending |
| 18-04 | 01 | 0 | PIX-06 | widget | `flutter test test/features/admin/admin_booking_card_test.dart` | ❌ W0 | ⬜ pending |
| 18-05 | 01 | 0 | PIX-07 | integration/CF | `firebase emulators:exec "npm test -- expireUnpaidBookings"` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/features/booking/pix_payment_screen_test.dart` — stubs para PIX-03 (countdown, regenerate, auto-nav)
- [ ] `test/features/booking/my_bookings_screen_test.dart` — stubs para PIX-05 (real-time badge update)
- [ ] `test/features/admin/admin_booking_card_test.dart` — stubs para PIX-06 (payment badges)
- [ ] `test/features/admin/admin_booking_detail_sheet_test.dart` — stubs para PIX-06 (manual confirm button)
- [ ] `functions/test/handlePixWebhook.test.js` — stubs para PIX-04 (signature, idempotency)
- [ ] `functions/test/expireUnpaidBookings.test.js` — stubs para PIX-07 (expiration logic)
- [ ] Firebase Emulator config: `firebase.json` com `"functions"` e `"firestore"` emulator entries
- [ ] Cloud Functions test setup: jest ou mocha em `functions/package.json`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `expireUnpaidBookings` roda a cada 15 min via Cloud Scheduler | PIX-07 | Scheduling não é testável em emulator | Verificar `onSchedule('every 15 minutes', ...)` em `functions/src/index.ts` |
| Webhook recebe chamada real do Mercado Pago sandbox | PIX-04 | Requer ambiente real/sandbox | Testar com `ngrok` + sandbox MP antes do verify-work |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10 min
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

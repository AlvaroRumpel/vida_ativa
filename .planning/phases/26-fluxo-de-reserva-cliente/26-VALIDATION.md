---
phase: 26
slug: fluxo-de-reserva-cliente
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 26 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter test (widget tests) |
| **Config file** | pubspec.yaml |
| **Quick run command** | `flutter analyze` |
| **Full suite command** | `flutter build web --release` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze`
- **After every plan wave:** Run `flutter build web --release`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 26-01-01 | 01 | 1 | BOOK-07 | — | N/A | analyze | `flutter analyze` | ✅ | ⬜ pending |
| 26-01-02 | 01 | 1 | BOOK-08 | — | N/A | analyze | `flutter analyze` | ✅ | ⬜ pending |
| 26-01-03 | 01 | 1 | BOOK-09 | — | N/A | analyze | `flutter analyze` | ✅ | ⬜ pending |
| 26-01-04 | 01 | 1 | BOOK-10 | — | N/A | analyze | `flutter analyze` | ✅ | ⬜ pending |
| 26-01-05 | 01 | 1 | BOOK-11 | — | N/A | analyze | `flutter analyze` | ✅ | ⬜ pending |
| 26-01-06 | 01 | 1 | BOOK-12 | — | N/A | analyze | `flutter analyze` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new test files needed — this is a pure UI/widget rebuild phase.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Anton 88px heroic time display in BookingConfirmationSheet | BOOK-07 | Visual typography — no automated visual regression | Open app, make a booking, verify time displays in Anton 88px as primary element |
| Orange stripe 2px aviso de aprovação manual | BOOK-08 | Visual layout — stripe width pixel-exact | Verify booking with manual approval mode; check left stripe is 2px orange, no colored background |
| Botões Pix/manual uppercase Anton sem quebra | BOOK-09 | Mobile viewport text wrapping | Test on 375px viewport; both buttons must show full text in one line |
| Anton 72px "Próximo" section in MyBookings | BOOK-10 | Visual typography | Navigate to Minhas Reservas; verify next booking shows time in Anton 72px with orange eyebrow |
| Hairline rows for other bookings | BOOK-11 | Visual layout | Other bookings appear as hairline rows with Anton 30px date and quiet pill status |
| Full booking flow end-to-end | BOOK-12 | Integration — requires real Firestore | Complete a booking flow from schedule → confirmation → my bookings |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

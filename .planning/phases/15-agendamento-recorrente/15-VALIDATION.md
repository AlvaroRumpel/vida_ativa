---
phase: 15
slug: agendamento-recorrente
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-04
---

# Phase 15 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter analyze + manual flutter run |
| **Config file** | none — uses dart analyze |
| **Quick run command** | `dart analyze lib/` |
| **Full suite command** | `dart analyze lib/` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `dart analyze lib/`
- **After every plan wave:** Run `dart analyze lib/`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 15-01-01 | 01 | 1 | BOOK-05 | static | `dart analyze lib/core/models/booking_model.dart` | ✅ | ⬜ pending |
| 15-01-02 | 01 | 1 | BOOK-05 | static | `dart analyze lib/features/booking/cubit/booking_cubit.dart` | ✅ | ⬜ pending |
| 15-02-01 | 02 | 2 | BOOK-05 | static | `dart analyze lib/features/booking/ui/booking_confirmation_sheet.dart` | ✅ | ⬜ pending |
| 15-02-02 | 02 | 2 | BOOK-05 | static | `dart analyze lib/features/booking/ui/booking_card.dart` | ✅ | ⬜ pending |
| 15-02-03 | 02 | 2 | BOOK-05 | static | `dart analyze lib/features/booking/ui/client_booking_detail_sheet.dart` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- None — no new test infrastructure needed; existing `dart analyze` covers static verification.

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Toggle expands sheet with chips + slider | BOOK-05 | UI interaction | Tap slot → activate toggle → verify chips and slider appear |
| Preview updates on slider drag end | BOOK-05 | UI interaction | Move slider → release → verify dates list updates |
| Preview shows correct date states (available/reserved/not-registered) | BOOK-05 | Requires live Firestore data | Book a slot manually → open recurrence for same time next week → verify grey "Já reservado" |
| Batch creation succeeds in parallel | BOOK-05 | Requires live Firestore + auth | Confirm recurrence → verify N bookings created in Firestore |
| Result sheet shows created vs conflicts | BOOK-05 | UI + Firestore | Create recurrence with known conflict → verify amber conflict row in result sheet |
| Badge "Recorrente" appears in MyBookingsScreen | BOOK-05 | UI | After recurrence → navigate to Minhas Reservas → verify badge on cards |
| "Cancelar esta e as próximas" cancels future group | BOOK-05 | Firestore + UI | Open booking detail from recurrence → tap cancel future → verify Firestore docs updated |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

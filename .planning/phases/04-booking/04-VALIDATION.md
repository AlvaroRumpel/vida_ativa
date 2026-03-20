---
phase: 4
slug: booking
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-03-20
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> **Note:** Per project convention (feedback_no_tests.md), automated unit/widget tests are NOT generated. All verification is manual + grep-based acceptance criteria.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual verification (no test files per project convention) |
| **Config file** | none |
| **Quick run command** | `flutter build web --no-tree-shake-icons` (compile check) |
| **Full suite command** | `flutter build web --no-tree-shake-icons` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** `flutter build web --no-tree-shake-icons` must exit 0
- **After every plan wave:** Manual browser test against success criteria
- **Before `/gsd:verify-work`:** All manual verifications complete
- **Max feedback latency:** Build error within 30s of commit

---

## Per-Task Verification Map

| Task ID | Requirement | Test Type | Automated Command | Status |
|---------|-------------|-----------|-------------------|--------|
| BookingCubit + Firestore Transaction | BOOK-01 | compile + grep | `flutter build web` + grep `runTransaction` | ⬜ pending |
| Bottom sheet confirmation UI | BOOK-01 | compile + manual | `flutter build web` | ⬜ pending |
| SlotCard tap handler | BOOK-01 | compile + grep | grep `onTap` in slot_card.dart | ⬜ pending |
| My Bookings screen | BOOK-03 | compile + manual | `flutter build web` | ⬜ pending |
| Cancel booking flow | BOOK-02 | compile + manual | `flutter build web` | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No test stubs needed per project convention.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Double-booking prevention (concurrent) | BOOK-01 | Requires two simultaneous browser sessions | Open app in two tabs, attempt same slot simultaneously — second user must see error SnackBar |
| Slot card updates reactively after booking | BOOK-01 | Requires live Firestore stream | Book a slot, verify card changes to "Minha reserva" without page reload |
| Bottom sheet closes + SnackBar shows | BOOK-01 | UI behavior | Tap available slot, confirm booking — sheet closes, SnackBar "Reserva feita!" appears |
| Cancel booking removes from Próximas | BOOK-02 | UI behavior | Cancel a future booking, verify it disappears from "Próximas" section |
| Bookings grouped by Próximas / Passadas | BOOK-03 | UI behavior | Verify past bookings appear in "Passadas", future in "Próximas" |
| Empty state shows "Ver Agenda" | BOOK-03 | UI behavior | User with no bookings sees empty state + "Ver Agenda" button navigates to Tab 0 |
| Offline persistence disabled | BOOK-01 | Runtime behavior | Verify `Settings(persistenceEnabled: false)` is set before booking Transaction |

---

## Validation Sign-Off

- [ ] All tasks compile cleanly (`flutter build web`)
- [ ] Manual verification of all behaviors above
- [ ] No ghost bookings (no confirmation before server write acknowledged)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

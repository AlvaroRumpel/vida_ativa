---
phase: 5
slug: admin
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-03-20
---

# Phase 5 — Validation Strategy

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
| AdminSlotCubit + Firestore write | ADMN-01, ADMN-02 | compile + grep | `flutter build web` + grep `AdminSlotCubit` | ⬜ pending |
| Slot form UI + create/deactivate | ADMN-01, ADMN-02 | compile + manual | `flutter build web` | ⬜ pending |
| AdminBlockedDateCubit | ADMN-03 | compile + grep | `flutter build web` + grep `AdminBlockedDateCubit` | ⬜ pending |
| AdminBookingCubit + confirm/reject | ADMN-04, ADMN-05 | compile + grep | `flutter build web` + grep `runTransaction\|confirmBooking\|rejectBooking` | ⬜ pending |
| Admin booking list UI | ADMN-04, ADMN-05 | compile + manual | `flutter build web` | ⬜ pending |
| Confirmation mode toggle | ADMN-06 | compile + grep | grep `confirmationMode\|/config/booking` | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No test stubs needed per project convention.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Create slot appears in schedule | ADMN-01 | Requires live Firestore + schedule screen | Create slot for today's weekday, navigate to Schedule tab — slot must appear |
| Deactivate slot hides it | ADMN-02 | Requires reactive Firestore stream | Deactivate a slot, verify it disappears from Schedule tab without refresh |
| Block date hides all slots | ADMN-03 | Requires live Firestore blocked date doc | Block today's date, verify Schedule shows no slots / blocked state |
| Confirm booking updates status | ADMN-05 | Requires live Firestore + client view | Admin confirms booking, client sees "Confirmado" badge in Minhas Reservas |
| Reject booking updates status | ADMN-05 | Requires live Firestore + client view | Admin rejects booking, client sees "Cancelado" badge in Minhas Reservas |
| Automatic mode skips pending | ADMN-06 | Runtime behavior | Set mode to "automatic", client books — booking goes directly to "confirmed" status |
| Manual mode uses pending | ADMN-06 | Runtime behavior | Set mode to "manual", client books — booking stays "pending" until admin confirms |
| Admin route is role-gated | ADMN-01 | Security | Log in as non-admin, navigate to /admin — must redirect to access denied |

---

## Validation Sign-Off

- [ ] All tasks compile cleanly (`flutter build web`)
- [ ] Manual verification of all behaviors above
- [ ] Admin route inaccessible to non-admin users
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

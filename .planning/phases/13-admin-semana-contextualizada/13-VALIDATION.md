---
phase: 13
slug: admin-semana-contextualizada
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-31
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test + bloc_test + mocktail |
| **Config file** | none — test/* directory structure |
| **Quick run command** | `flutter test test/features/admin/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/features/admin/`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 13-01-01 | 01 | 1 | ADMN-10 | widget | `flutter test test/features/admin/ui/slot_management_tab_test.dart --name "week label"` | ❌ W0 | ⬜ pending |
| 13-01-02 | 01 | 1 | ADMN-10 | widget | `flutter test test/features/admin/ui/slot_management_tab_test.dart --name "day chip date"` | ❌ W0 | ⬜ pending |
| 13-01-03 | 01 | 1 | ADMN-10 | widget | `flutter test test/features/admin/ui/slot_management_tab_test.dart --name "week navigation"` | ❌ W0 | ⬜ pending |
| 13-02-01 | 02 | 2 | ADMN-11 | widget | `flutter test test/features/admin/ui/admin_booking_detail_sheet_test.dart --name "detail display"` | ❌ W0 | ⬜ pending |
| 13-02-02 | 02 | 2 | ADMN-11 | widget | `flutter test test/features/admin/ui/admin_booking_detail_sheet_test.dart --name "confirm action"` | ❌ W0 | ⬜ pending |
| 13-02-03 | 02 | 2 | ADMN-11 | widget | `flutter test test/features/admin/ui/admin_booking_detail_sheet_test.dart --name "reject action"` | ❌ W0 | ⬜ pending |
| 13-02-04 | 02 | 2 | ADMN-11 | widget | `flutter test test/features/admin/ui/booking_management_tab_test.dart --name "booking card tap"` | ❌ W0 | ⬜ pending |
| 13-02-05 | 02 | 2 | ADMN-11 | widget | `flutter test test/features/admin/ui/admin_booking_detail_sheet_test.dart --name "error handling"` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/features/admin/ui/slot_management_tab_test.dart` — week navigation and date chip stubs for ADMN-10
- [ ] `test/features/admin/ui/admin_booking_detail_sheet_test.dart` — detail display, confirm/reject, error handling stubs for ADMN-11
- [ ] `test/features/admin/ui/booking_management_tab_test.dart` — card tap stub for ADMN-11

*Note: Per project conventions, do NOT generate unit tests — widget tests only.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Week label "31 mar – 6 abr" correct locale formatting | ADMN-10 | Date formatting depends on pt_BR locale, not easily testable in CI | Open admin Slots tab, verify label reads current week in "d mmm – d mmm" format |
| Day chips show correct calendar dates | ADMN-10 | Calendar alignment across month boundaries | Navigate to a week spanning two months, verify chips show correct date numbers |
| Confirm/Reject sheet closes after action | ADMN-11 | Sheet dismiss interaction | Tap confirm on pending booking, verify sheet closes and card status updates |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

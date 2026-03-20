---
phase: 3
slug: schedule
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-19
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual verification (no unit/widget tests per project convention) |
| **Config file** | none |
| **Quick run command** | `flutter run -d chrome` — visual inspection |
| **Full suite command** | `flutter run -d chrome` — full screen walkthrough |
| **Estimated runtime** | ~2 minutes manual walkthrough |

---

## Sampling Rate

- **After every task commit:** `flutter run -d chrome` — verify the screen compiles and renders
- **After every plan wave:** Full manual walkthrough of built features
- **Before `/gsd:verify-work`:** All manual verification steps complete

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 3-01-01 | 01 | 1 | SCHED-01 | manual | flutter run -d chrome | N/A | ⬜ pending |
| 3-01-02 | 01 | 1 | SCHED-01 | manual | flutter run -d chrome | N/A | ⬜ pending |
| 3-02-01 | 02 | 2 | SCHED-02 | manual | flutter run -d chrome | N/A | ⬜ pending |
| 3-03-01 | 03 | 2 | SCHED-03 | manual | flutter run -d chrome | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

*Per project convention: no unit tests or widget tests are generated. All verification is manual via `flutter run`.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Weekly calendar renders with day chips (Seg/Ter/...) and today selected | SCHED-01 | No widget tests per convention | Open app, navigate to Agenda tab, verify chips visible and today highlighted |
| Week navigation arrows work (left disabled on current week, right disabled at week 8) | SCHED-01 | No widget tests per convention | Tap > arrow repeatedly, verify disable after 7 forward jumps; on current week verify < is disabled |
| Selecting a day shows that day's slots | SCHED-02 | No widget tests per convention | Tap different day chips, verify slot list updates |
| Blocked date shows blocked message | SCHED-02 | No widget tests per convention | Requires a blocked date in Firestore; verify message "Dia bloqueado — sem horários disponíveis." |
| Slot card shows price | SCHED-03 | No widget tests per convention | Verify each card displays "R$ XX,XX" formatted price |
| Slot card left border color matches status | SCHED-01/02 | No widget tests per convention | Verify green=available, grey=booked, red=blocked, grey+badge=my booking |
| Loading skeleton displays while Firestore loads | SCHED-02 | No widget tests per convention | On first open or day change, verify 3-4 pulsing skeleton cards appear briefly |
| Inactive slots hidden | SCHED-01 | No widget tests per convention | Verify slots with isActive=false do not appear in list |

---

## Validation Sign-Off

- [ ] All tasks have manual verification steps defined
- [ ] Sampling continuity: visual check after each wave
- [ ] Wave 0 covers all MISSING references — N/A (no test files)
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter when all manual checks pass

**Approval:** pending

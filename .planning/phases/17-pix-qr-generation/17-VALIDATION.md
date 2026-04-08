---
phase: 17
slug: pix-qr-generation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-07
---

# Phase 17 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter integration tests + Firebase emulator |
| **Config file** | none — manual verification primary |
| **Quick run command** | `flutter analyze` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 17-01-01 | 01 | 1 | PIX-01 | manual | Cloud Function deploy + call | ❌ W0 | ⬜ pending |
| 17-01-02 | 01 | 1 | PIX-02 | manual | Firestore check pending_payment | ❌ W0 | ⬜ pending |
| 17-02-01 | 02 | 2 | PIX-01 | manual | UI renders QR code | ❌ W0 | ⬜ pending |
| 17-02-02 | 02 | 2 | PIX-02 | static | `flutter analyze` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements (no new test framework needed).
- Manual verification via Firebase emulator or staging environment for Mercado Pago integration.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| QR code displays after booking | PIX-01 | Requires MP sandbox credentials + live API call | Create booking → check PixPaymentScreen shows QR image and copy-paste code |
| Slot blocked for other users | PIX-02 | Requires concurrent Firestore reads | Create pending_payment booking → verify slot absent from schedule for different user |
| QR expires after 30 min | PIX-01 | Time-based, requires waiting or mock | Check expiresAt field in Firestore = createdAt + 30min |
| ScheduleCubit blocks pending_payment | PIX-02 | Firestore query filter | Verify `whereIn: ['pending', 'confirmed', 'pending_payment']` in schedule_cubit.dart |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

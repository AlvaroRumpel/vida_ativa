---
phase: 16
slug: push-notifications-admin
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-04
---

# Phase 16 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual (no automated test framework — Flutter web + FCM requires browser + Firebase) |
| **Config file** | none |
| **Quick run command** | `flutter analyze` |
| **Full suite command** | `flutter analyze && flutter build web --dart-define=ENV=staging` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze`
- **After every plan wave:** Run `flutter analyze && flutter build web --dart-define=ENV=staging`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 16-01-01 | 01 | 1 | NOTF-01 | static | `flutter analyze` | ✅ | ⬜ pending |
| 16-01-02 | 01 | 1 | NOTF-01 | static | `flutter analyze` | ❌ W0 | ⬜ pending |
| 16-01-03 | 01 | 1 | NOTF-01 | manual | browser permission flow | — | ⬜ pending |
| 16-02-01 | 02 | 2 | NOTF-01 | static | `flutter analyze` | ❌ W0 | ⬜ pending |
| 16-02-02 | 02 | 2 | NOTF-01 | manual | create booking → notification received | — | ⬜ pending |
| 16-02-03 | 02 | 2 | NOTF-01 | manual | browser closed → notification displayed | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `firebase_messaging` added to `pubspec.yaml`
- [ ] `web/firebase-messaging-sw.js` stub created
- [ ] Cloud Functions project initialized (if not already)

*Existing flutter analyze infrastructure covers static analysis; FCM flows require manual verification.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Admin grants browser permission → token saved | NOTF-01 | Requires browser interaction | Open app as admin → trigger permission dialog → check Firestore `admins/{uid}/fcmTokens` |
| New booking triggers push notification | NOTF-01 | Requires FCM delivery pipeline | Create booking as client → confirm admin receives push in browser |
| Notification shows client name + time | NOTF-01 | Visual/content verification | Inspect notification payload after booking |
| Notification works with browser closed | NOTF-01 | Service worker behavior | Close browser → create booking → confirm OS-level notification appears |
| Invalid token cleaned up after 403 | NOTF-01 | Requires FCM error response | Revoke token manually → trigger booking → confirm token removed from Firestore |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

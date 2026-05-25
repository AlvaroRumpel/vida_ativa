---
phase: 23
slug: design-system-navigationbar
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-25
---

# Phase 23 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter analyze + flutter build web |
| **Config file** | pubspec.yaml |
| **Quick run command** | `flutter analyze --no-fatal-infos` |
| **Full suite command** | `flutter build web --release` |
| **Estimated runtime** | ~30s analyze, ~4min build |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze --no-fatal-infos`
- **After every plan wave:** Run `flutter build web --release`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds (analyze) / 4 minutes (full build)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Secure Behavior | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------------|-----------|-------------------|--------|
| 23-01-01 | 01 | 1 | DS-02 | Fontes disponíveis offline | integration | `flutter analyze --no-fatal-infos` | ⬜ pending |
| 23-01-02 | 01 | 1 | NAV-02 | Borda hairline no nav bar | integration | `flutter analyze --no-fatal-infos` | ⬜ pending |
| 23-01-03 | 01 | 2 | DS-01 | Sem Color(0xFF) em admin_booking_card | grep | `grep -n "Color(0x" lib/features/admin/ui/admin_booking_card.dart` → 0 results | ⬜ pending |
| 23-01-04 | 01 | 2 | DS-01 | Sem Color(0xFF) em booking_confirmation_sheet | grep | `grep -n "Color(0x" lib/features/booking/ui/booking_confirmation_sheet.dart` → 0 results | ⬜ pending |
| 23-01-05 | 01 | 3 | DS-01..04, NAV-01..02 | Build limpo sem erros | build | `flutter build web --release` exits 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new test files needed — validation is via:
- `flutter analyze` (static analysis)
- `flutter build web` (compilation)
- `grep` commands (color audit confirmation)

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| NavigationBar visual appearance | NAV-01, NAV-02 | Requires browser/device | Open app in browser, verify bottom nav: orange selected icon, concrete idle icon, sand bg, hairline top border |
| Font rendering offline | DS-02 | Requires network disabled | Disable network, reload PWA, verify Anton/Manrope/JBM render correctly |

*Visual verification deferred to Phase 24+ when full screens are available.*

---

## Validation Sign-Off

- [ ] All tasks have automated verify or grep command
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0: existing flutter infra covers all requirements
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s (analyze) / 4min (build)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

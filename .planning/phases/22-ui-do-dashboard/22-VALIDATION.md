---
phase: 22
slug: ui-do-dashboard
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-21
---

# Phase 22 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (built-in) + bloc_test |
| **Config file** | pubspec.yaml (dev_dependencies) |
| **Quick run command** | `flutter test test/features/admin/ui/dashboard_tab_test.dart` |
| **Full suite command** | `flutter test test/` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/features/admin/ui/dashboard_tab_test.dart`
- **After every plan wave:** Run `flutter test test/`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 22-01-01 | 01 | 1 | DASH-05..08 | — | N/A | unit | `flutter pub add fl_chart flutter_heatmap_calendar && flutter pub get` | ✅ pubspec | ⬜ pending |
| 22-01-02 | 01 | 1 | DASH-05..08 | — | N/A | widget | `flutter test test/features/admin/ui/dashboard_tab_test.dart` | ❌ W0 | ⬜ pending |
| 22-02-01 | 02 | 2 | DASH-05 | — | N/A | widget | `flutter test test/features/admin/ui/dashboard_tab_test.dart -n revenue` | ❌ W0 | ⬜ pending |
| 22-02-02 | 02 | 2 | DASH-06 | — | N/A | widget | `flutter test test/features/admin/ui/dashboard_tab_test.dart -n heatmap` | ❌ W0 | ⬜ pending |
| 22-02-03 | 02 | 2 | DASH-07 | — | N/A | widget | `flutter test test/features/admin/ui/dashboard_tab_test.dart -n pie` | ❌ W0 | ⬜ pending |
| 22-02-04 | 02 | 2 | DASH-08 | — | N/A | widget | `flutter test test/features/admin/ui/dashboard_tab_test.dart -n donut` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/features/admin/ui/dashboard_tab_test.dart` — stubs for DASH-05, DASH-06, DASH-07, DASH-08 (period toggle, KPI cards, charts rendering, conditional donut)

*Existing infrastructure covers shared fixtures (test/ directory already present).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Charts render correctly on device (colors, proportions) | DASH-05..08 | Visual correctness requires real device/emulator | Run app on emulator, navigate to Admin → Dashboard, verify each chart visual |
| Period toggle updates all cards and charts | DASH-05..08 | Integration with live Firestore data | Toggle Semana/Mês/Ano while online; verify all 5 KPI cards and 4 charts update |
| Heatmap shows booking density visually | DASH-06 | Color intensity map requires visual inspection | Navigate to Dashboard, select "Semana", verify heatmap grid with hour×day cells |
| Timestamp "Última atualização" shows correct time | D-05 | Requires live data or mock setup | Verify timestamp below SegmentedButton shows "HH:MM" or "--" when null |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

---
phase: 21
slug: backend-do-dashboard
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-20
---

# Phase 21 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (built-in Flutter SDK) |
| **Config file** | pubspec.yaml |
| **Quick run command** | `flutter test test/features/admin/cubit/dashboard_cubit_test.dart` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/features/admin/cubit/dashboard_cubit_test.dart`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 21-01-01 | 01 | 1 | DASH-01..04, DASH-09..11 | — | N/A | unit | `flutter test test/features/admin/cubit/dashboard_cubit_test.dart` | ❌ W0 | ⬜ pending |
| 21-01-02 | 01 | 1 | DASH-12 | — | N/A | unit | `flutter test test/core/models/` | ❌ W0 | ⬜ pending |
| 21-02-01 | 02 | 1 | DASH-01..04 | T-21-01 | allow write: if false em /config/dashboard/{period} | manual | Firebase emulator rules test | ❌ W0 | ⬜ pending |
| 21-03-01 | 03 | 2 | DASH-01..04, DASH-09..12 | — | N/A | manual | Deploy staging + verificar logs CF | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/features/admin/cubit/dashboard_cubit_test.dart` — stubs para DASH-01..04, DASH-09..11; replica padrão de `pricing_cubit_test.dart`
- [ ] `test/core/models/dashboard_data_test.dart` — cobre `DashboardData.fromMap()` com campos nullable e doc nulo (DASH-12)

*Infraestrutura existente (flutter_test, Fake Firestore pattern) disponível — apenas novos arquivos de teste.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| onBookingStateChange incrementa contadores ao confirmar reserva | DASH-01, DASH-02 | Requer deploy de CF em staging | 1. Deploy CF staging. 2. Confirmar booking via admin. 3. Verificar doc /config/dashboard/periods/week incrementou confirmedBookings e totalRevenue |
| scheduledDailyAggregation recalcula todos os campos às 03:00 BRT | DASH-03, DASH-04, DASH-09..12 | Requer trigger manual ou esperar schedule | `firebase functions:shell` → `scheduledDailyAggregation()` → verificar docs Firestore |
| Firestore rules bloqueiam escrita direta em /config/dashboard/{period} | DASH-16 / segurança | Requer Firebase emulator | `firebase emulators:start` → tentar write como admin Flutter → verificar erro PERMISSION_DENIED |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

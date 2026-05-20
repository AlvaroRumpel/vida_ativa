---
phase: 20-infraestrutura-de-esporte
plan: "01"
subsystem: sport-infrastructure
tags:
  - flutter
  - bloc
  - firestore
  - model
dependency_graph:
  requires: []
  provides:
    - BookingModel.sport (nullable field)
    - SportConfigCubit (stream /config/sports)
    - SportConfigState (sealed)
  affects:
    - lib/features/admin/ui/settings_tab.dart (Plan 03 consumer)
    - lib/features/booking/ui/booking_flow.dart (Plan 02 consumer)
tech_stack:
  added: []
  patterns:
    - StreamSubscription in Cubit (mirrors PricingCubit pattern)
    - Nullable field backward-compat (mirrors paymentMethod/paymentId pattern)
    - MultiBlocProvider wrapping SettingsTab
key_files:
  created:
    - lib/features/admin/cubit/sport_config_state.dart
    - lib/features/admin/cubit/sport_config_cubit.dart
  modified:
    - lib/core/models/booking_model.dart
    - lib/features/admin/ui/admin_screen.dart
decisions:
  - "sport field is String? (not enum) — allows free-text extension without migration"
  - "set() without merge for saveSports — full document replacement per RESEARCH anti-pattern guidance"
  - "_initializingDefaults flag prevents _writeDefaults loop on stream re-emit"
metrics:
  duration_minutes: 15
  completed_date: "2026-05-20"
  tasks_completed: 3
  tasks_total: 3
  files_modified: 4
---

# Phase 20 Plan 01: Sport Infrastructure Foundation Summary

**One-liner:** Nullable `sport` field added to BookingModel + `SportConfigCubit` streaming `/config/sports` with auto-init of defaults Vôlei/Beach Tênis/Futevôlei, provisioned in AdminScreen via MultiBlocProvider.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Estender BookingModel com campo sport opcional | 55a6fac | lib/core/models/booking_model.dart |
| 2 | Criar SportConfigState e SportConfigCubit com auto-init de defaults | 06a2dcc | lib/features/admin/cubit/sport_config_state.dart, lib/features/admin/cubit/sport_config_cubit.dart |
| 3 | Provisionar SportConfigCubit no AdminScreen junto com SettingsCubit | 5e7fb5c | lib/features/admin/ui/admin_screen.dart |

## Verification

- `flutter analyze lib/core/models/booking_model.dart` — No issues found
- `flutter analyze lib/features/admin/cubit/sport_config_cubit.dart lib/features/admin/cubit/sport_config_state.dart` — No issues found
- `flutter analyze lib/features/admin/ui/admin_screen.dart` — No issues found

**Manual smoke (to be done on first deploy):**
- Navigate Admin > Ajustes; verify Firestore Console shows `/config/sports` created with `{sports: ['Vôlei', 'Beach Tênis', 'Futevôlei']}`
- Open an old booking (without sport field) — confirm no crash in fromFirestore (sport returns null)

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. No UI rendering in this plan — purely data/state layer.

## Threat Flags

No new threat surface introduced beyond what is documented in the plan's threat model.

- T-20-01 (Tampering /config/sports by non-admin): Mitigated by existing Firestore rules on `/config/{document}` — no new code needed.
- T-20-02 (DoS loop in _writeDefaults): Mitigated by `_initializingDefaults` flag implemented in SportConfigCubit.
- T-20-04 (Backward compat on fromFirestore): Mitigated by `data['sport'] as String?` returning null for old docs.

## Self-Check: PASSED

Files exist:
- lib/core/models/booking_model.dart — FOUND
- lib/features/admin/cubit/sport_config_state.dart — FOUND
- lib/features/admin/cubit/sport_config_cubit.dart — FOUND
- lib/features/admin/ui/admin_screen.dart — FOUND

Commits exist:
- 55a6fac — FOUND
- 06a2dcc — FOUND
- 5e7fb5c — FOUND

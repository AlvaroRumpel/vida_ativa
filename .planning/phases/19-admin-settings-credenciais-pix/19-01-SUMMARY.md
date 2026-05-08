---
phase: 19-admin-settings-credenciais-pix
plan: "01"
subsystem: admin
tags: [settings, mercadopago, credentials, pix, cubit, flutter]
dependency_graph:
  requires: []
  provides:
    - SettingsCubit (lib/features/admin/cubit/settings_cubit.dart)
    - SettingsState (lib/features/admin/cubit/settings_state.dart)
    - SettingsTab (lib/features/admin/ui/settings_tab.dart)
  affects:
    - lib/features/admin/ui/admin_screen.dart
tech_stack:
  added: []
  patterns:
    - BLoC/Cubit sealed states com Equatable
    - obscureText com show/hide toggle
    - SetOptions(merge: true) para escrita parcial no Firestore
    - Future.wait para leituras paralelas no Firestore
key_files:
  created:
    - lib/features/admin/cubit/settings_state.dart
    - lib/features/admin/cubit/settings_cubit.dart
    - lib/features/admin/ui/settings_tab.dart
  modified:
    - lib/features/admin/ui/admin_screen.dart
decisions:
  - SettingsCubit gerencia config/mercadopago (credenciais) e config/booking (pixEnabled) num único cubit — evita duplicação de lógica
  - Estado SettingsLoaded contém apenas flags booleanas (isAccessTokenConfigured, isWebhookSecretConfigured, pixEnabled) — token nunca exposto no estado Flutter
  - Badge check_circle verde exibido inline via Row(Expanded + Icon) quando credencial já configurada
  - obscureText com sufixIcon visibility_off/visibility em cada campo — padrão de password field
metrics:
  duration_minutes: 25
  completed_date: "2026-05-07"
  tasks_completed: 2
  tasks_total: 2
  files_created: 3
  files_modified: 1
---

# Phase 19 Plan 01: Admin Settings — Credenciais Pix Summary

**One-liner:** Aba Config no painel admin com campos mascarados para credenciais Mercado Pago e toggle pixEnabled migrado de BookingManagementTab.

## What Was Built

### Task 1: SettingsCubit e SettingsState (commit: 5fa3ce4)

- `settings_state.dart`: sealed class com `SettingsInitial`, `SettingsLoaded` (apenas flags booleanas), `SettingsError`
- `settings_cubit.dart`: lê `config/mercadopago` e `config/booking` em paralelo via `Future.wait`; `saveCredentials()` escreve com `SetOptions(merge: true)`; `setPixEnabled()` centraliza o toggle Pix

**Segurança:** estado Flutter nunca contém o valor do token — apenas `isAccessTokenConfigured: bool` e `isWebhookSecretConfigured: bool`.

### Task 2: SettingsTab + AdminScreen atualizado (commit: fc7493d)

- `settings_tab.dart`: BlocBuilder com switch pattern; `_SettingsForm` StatefulWidget com campos `obscureText`, show/hide toggle, badge `check_circle` verde quando configurado, `FilledButton` salvar com loading state, toggle pixEnabled via `SwitchListTile`
- `admin_screen.dart`: `TabController(length: 6)`, `Tab(text: 'Config')` adicionada, `BlocProvider<SettingsCubit>` wrapping `SettingsTab()` no `TabBarView`

**Migração pixEnabled:** toggle removido de `BookingManagementTab` (já removido no base commit `62c1674`); centralizado em `SettingsTab`.

## Deviations from Plan

None — plan executed exactly as written. The worktree base (`62c1674`) already had `pixEnabled` removed from `AdminBookingCubit`, `AdminBookingState`, and `BookingManagementTab` — these migrations were pre-committed. This plan only created the new SettingsTab and updated AdminScreen.

## Known Stubs

None — SettingsCubit lê estado real do Firestore; campos exibem status real de configuração.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: write_without_server_validation | lib/features/admin/cubit/settings_cubit.dart | Admin escreve credenciais MP diretamente no Firestore via Flutter SDK — mitigado por regras Firestore `allow write: if isAdmin()` implementadas no 19-02-PLAN.md |

## Self-Check: PASSED

- lib/features/admin/cubit/settings_state.dart: FOUND
- lib/features/admin/cubit/settings_cubit.dart: FOUND
- lib/features/admin/ui/settings_tab.dart: FOUND
- lib/features/admin/ui/admin_screen.dart: MODIFIED (6 tabs, SettingsTab present)
- Commit 5fa3ce4: FOUND
- Commit fc7493d: FOUND
- flutter analyze lib/features/admin/ → No issues found

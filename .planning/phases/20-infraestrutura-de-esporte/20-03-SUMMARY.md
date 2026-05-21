---
phase: 20-infraestrutura-de-esporte
plan: "03"
subsystem: admin-sport-ui
tags:
  - flutter
  - bloc
  - admin
  - ui
dependency_graph:
  requires:
    - SportConfigCubit (Plan 01 — /config/sports stream)
    - BookingModel.sport (Plan 01 — nullable field)
  provides:
    - SettingsTab._SportsSection (admin gerencia lista de esportes)
    - AdminBookingCard._buildSportChip (chip colorido condicional)
    - AdminBookingDetailSheet sport info-row (condicional)
  affects: []
tech_stack:
  added: []
  patterns:
    - ReorderableListView com ValueKey por item (evita Pitfall 3)
    - _initialized flag para sync one-time do estado remoto para lista local
    - Cor determinística por hash de string (hashCode.abs() % N)
    - Container com BoxDecoration para chip (sem Material Chip widget)
    - Reutilização de _infoRow existente para linha de esporte
key_files:
  created: []
  modified:
    - lib/features/admin/ui/settings_tab.dart
    - lib/features/admin/ui/admin_booking_card.dart
    - lib/features/admin/ui/admin_booking_detail_sheet.dart
decisions:
  - "_initialized flag em _SportsSectionState evita reset da lista local a cada re-emit do stream — admin pode editar localmente sem perder edits antes de salvar"
  - "Chip em AdminBookingCard usa Container+BoxDecoration (não Material Chip) para consistência com status chip existente"
  - "Sport info-row em DetailSheet reutiliza _infoRow helper existente — sem widget novo"
  - "Remover esporte do /config não invalida reservas existentes — field é String? própria do doc (não FK)"
metrics:
  duration_minutes: 5
  completed_date: "2026-05-20"
  tasks_completed: 3
  tasks_total: 3
  files_modified: 3
---

# Phase 20 Plan 03: Admin Sport UX Summary

**One-liner:** Seção Esportes no SettingsTab com ReorderableListView add/remove/save via SportConfigCubit + chip colorido determinístico em AdminBookingCard + info-row em AdminBookingDetailSheet, ambos condicionais a booking.sport != null.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Adicionar seção Esportes no SettingsTab com ReorderableListView | 84712d0 | lib/features/admin/ui/settings_tab.dart |
| 2 | Renderizar chip de esporte em AdminBookingCard | 259c295 | lib/features/admin/ui/admin_booking_card.dart |
| 3 | Renderizar info-row de esporte em AdminBookingDetailSheet | 8f15f60 | lib/features/admin/ui/admin_booking_detail_sheet.dart |

## Verification

- `flutter analyze lib/features/admin/ui/settings_tab.dart` — No issues found
- `flutter analyze lib/features/admin/ui/admin_booking_card.dart` — No issues found
- `flutter analyze lib/features/admin/ui/admin_booking_detail_sheet.dart` — No issues found

**Manual smoke (a fazer no dispositivo/browser):**
1. Abrir Admin > Ajustes; ver seção "Esportes" com lista Vôlei, Beach Tênis, Futevôlei (defaults do Plano 01)
2. Adicionar "Tênis", arrastar para o topo, remover "Futevôlei", clicar Salvar Esportes → SnackHelper.success "Esportes salvos.", Firestore Console reflete nova lista
3. Tentar adicionar esporte duplicado → SnackHelper.error "Esporte já existe."
4. Tentar adicionar nome >50 chars → SnackHelper.error "Nome muito longo (máx 50 caracteres)."
5. Criar reserva com sport selecionado, abrir aba Reservas no admin: card mostra chip colorido com nome do esporte; abrir bottomsheet do detalhe: linha "Esporte" com ícone Icons.sports
6. Reserva sem sport (anterior): card NÃO mostra chip; detail sheet NÃO mostra linha

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. Toda UI está conectada a dados reais (SportConfigCubit stream + BookingModel.sport do Firestore).

## Threat Flags

No new threat surface beyond what is documented in the plan's threat model.

- T-20-09 (Tampering — string longa): Mitigado por maxLength: 50 no TextField + validação manual name.length > 50 em _addSport
- T-20-10 (Tampering — duplicatas): Mitigado por _localSports.contains(name) antes de adicionar
- T-20-12 (Chip vaza dado de cliente): Aceito — sport não é PII; chip visível apenas no painel admin
- T-20-13 (Remover esporte em uso): Mitigado por design — reservas mantêm String? própria (não FK); remover do /config não corrompe reservas antigas

## Self-Check: PASSED

Files exist:
- lib/features/admin/ui/settings_tab.dart — FOUND
- lib/features/admin/ui/admin_booking_card.dart — FOUND
- lib/features/admin/ui/admin_booking_detail_sheet.dart — FOUND

Commits exist:
- 84712d0 — Task 1
- 259c295 — Task 2
- 8f15f60 — Task 3

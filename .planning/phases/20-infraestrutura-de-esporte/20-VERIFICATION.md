---
phase: 20-infraestrutura-de-esporte
verified: 2026-05-20T12:00:00Z
status: human_needed
score: 11/11 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Abrir app como cliente, tocar em um slot disponível e confirmar que o dropdown 'Esporte (opcional)' aparece entre o campo de participantes e os botões de pagamento"
    expected: "Dropdown visível com opções Vôlei, Beach Tênis, Futevôlei (e 'Não informado'); ao selecionar e confirmar, o doc Firestore em /bookings/{id} contém campo sport com o valor selecionado"
    why_human: "Renderização condicional do dropdown e persistência Firestore requerem device/browser; não testável estaticamente"
  - test: "Abrir app como cliente com /config/sports ausente no Firestore (deletar o doc manualmente no Console) e tocar em um slot"
    expected: "Dropdown NÃO renderiza (lista vazia); reserva criada sem campo sport no doc Firestore"
    why_human: "Comportamento D-04 (lista vazia = dropdown oculto) depende de estado real do Firestore"
  - test: "Abrir Admin > Ajustes e verificar seção 'Esportes' com ReorderableListView"
    expected: "Lista mostra Vôlei, Beach Tênis, Futevôlei (defaults); admin consegue arrastar item para reordenar, adicionar novo esporte via TextField, remover com ícone de delete, e clicar 'Salvar Esportes' mostrando SnackHelper.success 'Esportes salvos.' e refletindo nova lista no Firestore Console"
    why_human: "Interação de drag-and-drop, feedback visual, e escrita Firestore requerem execução real"
  - test: "No Admin > Ajustes, tentar adicionar esporte duplicado e esporte com nome >50 caracteres"
    expected: "Duplicado: SnackHelper.error 'Esporte já existe.'; Nome longo: SnackHelper.error 'Nome muito longo (máx 50 caracteres).'"
    why_human: "Validações de UI e mensagens de erro requerem interação real"
  - test: "Criar reserva com sport selecionado, abrir aba Reservas no Admin"
    expected: "AdminBookingCard mostra chip colorido com o nome do esporte; abrir bottomsheet do detalhe mostra linha com ícone Icons.sports e o nome do esporte"
    why_human: "Renderização de chip e info-row dependem de dados reais da reserva no Firestore"
  - test: "Abrir AdminBookingCard de reserva antiga (sem campo sport)"
    expected: "Card NÃO mostra chip de esporte; detail sheet NÃO mostra linha de esporte"
    why_human: "Backward compat D-11 requer reserva antiga real no Firestore"
---

# Phase 20: Infraestrutura de Esporte Verification Report

**Phase Goal:** Clientes podem selecionar esporte ao reservar e admin pode gerenciar a lista de esportes
**Verified:** 2026-05-20T12:00:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | BookingModel aceita campo sport opcional sem quebrar reservas existentes | VERIFIED | `final String? sport` declared; `data['sport'] as String?` in fromFirestore; `if (sport != null) 'sport': sport` in toFirestore; `sport` in props list |
| 2 | SportConfigCubit emite SportConfigLoaded com lista de esportes via stream em /config/sports | VERIFIED | `_firestore.collection('config').doc('sports').snapshots().listen(...)` in `_startStream()`; emits `SportConfigLoaded(sports)` when doc exists and non-empty |
| 3 | Se /config/sports não existe ou tem lista vazia, SportConfigCubit escreve defaults automaticamente | VERIFIED | `if (!snap.exists || sports.isEmpty)` guard calls `_writeDefaults()`; `defaultSports = ['Vôlei', 'Beach Tênis', 'Futevôlei']`; `_initializingDefaults` flag prevents loop |
| 4 | SportConfigCubit está disponível dentro de AdminScreen para SettingsTab consumir | VERIFIED | `MultiBlocProvider` in AdminScreen with `BlocProvider(create: (_) => SportConfigCubit(firestore: FirebaseFirestore.instance))` wrapping `SettingsTab()` |
| 5 | Cliente vê dropdown 'Esporte (opcional)' no BookingConfirmationSheet quando lista não está vazia | VERIFIED | `if (widget.sports.isNotEmpty)` conditional; `DropdownButtonFormField<String?>` with `labelText: 'Esporte (opcional)'`; null item 'Não informado' |
| 6 | Quando lista está vazia, dropdown é completamente escondido (não renderizado) | VERIFIED | `if (widget.sports.isNotEmpty)` — entire dropdown block including SizedBox is inside the conditional |
| 7 | Cliente seleciona esporte e valor é propagado para BookingCubit.bookSlot e bookRecurring | VERIFIED | `sport: _selectedSport` appears in all three call sites: `_handlePayPix`, `_handlePayOnArrival`, `_handleConfirmRecurring`; `bookSlot` and `bookRecurring` both have `String? sport` param |
| 8 | Reservas criadas persistem campo sport no Firestore quando selecionado | VERIFIED | `bookSlot` passes `sport: sport` to `BookingModel(...)`; `toFirestore()` writes `if (sport != null) 'sport': sport`; `bookRecurring` passes `sport: sport` to inner `bookSlot` call |
| 9 | Admin vê seção 'Esportes' no SettingsTab com ReorderableListView add/remove/reorder/save | VERIFIED | `_SportsSection` StatefulWidget with `ReorderableListView`, `ValueKey('sport_$sport')`, add/remove/reorder logic, `BlocBuilder<SportConfigCubit, SportConfigState>`, `context.read<SportConfigCubit>().saveSports(_localSports)` |
| 10 | Admin vê chip colorido de esporte em AdminBookingCard apenas quando booking.sport != null | VERIFIED | `if (booking.sport != null)` guard; `_buildSportChip(booking.sport!)` with deterministic palette via `sport.hashCode.abs() % 8`; `Container+BoxDecoration` (no Material Chip) |
| 11 | Admin vê linha de esporte em AdminBookingDetailSheet apenas quando booking.sport != null | VERIFIED | `if (booking.sport != null)` guard; `_infoRow(Icons.sports, booking.sport!)` reuses existing helper |

**Score:** 11/11 truths verified

### Roadmap Success Criteria

| # | Success Criterion | Status | Evidence |
|---|-------------------|--------|----------|
| 1 | Cliente vê dropdown "Esporte (opcional)" no formulário de reserva e pode selecionar Vôlei, Beach Tênis ou Futevôlei | VERIFIED (programmatic) / NEEDS HUMAN (visual) | DropdownButtonFormField wired; sports list fetched from /config/sports before sheet opens; defaults written by cubit |
| 2 | Admin vê seção "Esportes" nas configurações e pode adicionar, remover e reordenar esportes da lista | VERIFIED (programmatic) / NEEDS HUMAN (interaction) | _SportsSection fully implemented with all operations |
| 3 | Sistema popula automaticamente a lista padrão (Vôlei, Beach Tênis, Futevôlei) se /config/sports não existir | VERIFIED | _writeDefaults() called when !snap.exists || sports.isEmpty; defaultSports constant defined |
| 4 | Reservas antigas sem campo de esporte abrem normalmente sem erro | VERIFIED | fromFirestore uses `data['sport'] as String?` returning null for old docs; null-safe throughout |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/core/models/booking_model.dart` | Campo sport opcional, fromFirestore, toFirestore, props | VERIFIED | All four touchpoints confirmed: field, constructor, fromFirestore, toFirestore, props |
| `lib/features/admin/cubit/sport_config_state.dart` | Sealed state com Initial/Loaded/Error | VERIFIED | `sealed class SportConfigState`, all three subclasses present |
| `lib/features/admin/cubit/sport_config_cubit.dart` | Stream listener + writeDefaults + saveSports | VERIFIED | All three methods; Sentry in all catch blocks; no SetOptions(merge: true) |
| `lib/features/admin/ui/admin_screen.dart` | MultiBlocProvider injeta SportConfigCubit junto com SettingsCubit | VERIFIED | MultiBlocProvider with both cubits wrapping SettingsTab confirmed at line 136-150 |
| `lib/features/booking/ui/booking_confirmation_sheet.dart` | DropdownButtonFormField + sports param + _selectedSport | VERIFIED | All confirmed; deviation: uses `initialValue` instead of deprecated `value` — correct fix |
| `lib/features/booking/cubit/booking_cubit.dart` | String? sport em bookSlot e bookRecurring | VERIFIED | `String? sport` in both signatures; propagated to BookingModel and inner bookSlot call |
| `lib/features/schedule/ui/slot_day_view.dart` | One-shot Firestore read + sports passed to sheet | VERIFIED | `.get()` call, null-safe list parse, `if (!mounted) return`, `sports: sports` in sheet constructor |
| `lib/features/schedule/ui/slot_list.dart` | One-shot Firestore read + sports passed to sheet | VERIFIED | Same pattern as slot_day_view; `if (!context.mounted) return` (top-level function, uses context.mounted correctly) |
| `lib/features/admin/ui/settings_tab.dart` | _SportsSection with ReorderableListView add/remove/save | VERIFIED | All acceptance criteria confirmed including exact strings, maxLength, ValueKey pattern |
| `lib/features/admin/ui/admin_booking_card.dart` | Chip colorido condicional | VERIFIED | _sportBgColors (8 colors), _sportFgColors (8 colors), hashCode.abs(), Container+BoxDecoration |
| `lib/features/admin/ui/admin_booking_detail_sheet.dart` | Linha de info com ícone + label condicional | VERIFIED | `if (booking.sport != null)` + `_infoRow(Icons.sports, booking.sport!)` + `SizedBox(height: 10)` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| sport_config_cubit.dart | /config/sports (Firestore) | `.collection('config').doc('sports').snapshots().listen` | WIRED | Pattern found at line 22-26 of cubit file |
| admin_screen.dart | sport_config_cubit.dart | `BlocProvider(...SportConfigCubit(...))` in MultiBlocProvider | WIRED | Lines 143-147 of admin_screen.dart |
| settings_tab.dart | sport_config_cubit.dart | `BlocBuilder<SportConfigCubit, SportConfigState>` + `context.read<SportConfigCubit>().saveSports` | WIRED | Both patterns confirmed in _SportsSectionState |
| booking_confirmation_sheet.dart | booking_cubit.dart | `sport: _selectedSport` in bookSlot and bookRecurring calls | WIRED | 3 occurrences confirmed |
| slot_day_view.dart | sport_config_cubit.dart (indirectly) | Direct Firestore .get() before sheet open | WIRED | One-shot read pattern at lines 122-131 |
| slot_list.dart | sport_config_cubit.dart (indirectly) | Direct Firestore .get() before sheet open | WIRED | Same pattern at lines 65-73 |
| admin_booking_card.dart | booking_model.dart | `booking.sport` | WIRED | `if (booking.sport != null)` + `_buildSportChip(booking.sport!)` |
| admin_booking_detail_sheet.dart | booking_model.dart | `booking.sport` | WIRED | `if (booking.sport != null)` + `_infoRow(Icons.sports, booking.sport!)` |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| sport_config_cubit.dart | `sports` list | Firestore `/config/sports` snapshot stream | Yes — live Firestore stream; falls back to _writeDefaults when empty | FLOWING |
| booking_confirmation_sheet.dart | `widget.sports` | Caller reads Firestore .get() before opening sheet | Yes — one-shot Firestore read per tap | FLOWING |
| booking_cubit.dart | `sport` param | Passed from BookingConfirmationSheet._selectedSport | Yes — user selection propagated | FLOWING |
| settings_tab.dart (_SportsSection) | `_localSports` | SportConfigCubit stream via BlocBuilder (one-time sync via _initialized flag) | Yes — stream-backed, persisted via saveSports | FLOWING |
| admin_booking_card.dart | `booking.sport` | BookingModel.fromFirestore from /bookings collection | Yes — Firestore document field | FLOWING |
| admin_booking_detail_sheet.dart | `booking.sport` | BookingModel.fromFirestore from /bookings collection | Yes — Firestore document field | FLOWING |

### Behavioral Spot-Checks

Step 7b: SKIPPED — no runnable entry points without Flutter device/browser; all code is Flutter UI requiring app execution.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| SPORT-01 | 20-02-PLAN.md | Cliente pode selecionar esporte opcional via dropdown | SATISFIED | DropdownButtonFormField in BookingConfirmationSheet; wired through bookSlot/bookRecurring |
| SPORT-02 | 20-03-PLAN.md | Admin pode gerenciar lista de esportes (adicionar, remover, reordenar) | SATISFIED | _SportsSection with full CRUD + ReorderableListView + saveSports |
| SPORT-03 | 20-01-PLAN.md | Sistema inicializa lista com padrão Vôlei, Beach Tênis, Futevôlei | SATISFIED | _writeDefaults() writes defaultSports when !snap.exists or empty |
| SPORT-04 | 20-01-PLAN.md | Reservas existentes sem campo de esporte continuam funcionando | SATISFIED | `data['sport'] as String?` returns null; `if (sport != null)` in toFirestore omits key |

**Orphaned requirements check:** REQUIREMENTS.md Traceability table maps SPORT-01 through SPORT-04 exclusively to Phase 20. No orphaned requirements found.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| booking_confirmation_sheet.dart | ~360 | `initialValue: _selectedSport` instead of plan's `value: _selectedSport` | INFO | Not a defect — plan specified `value` but executor auto-fixed to `initialValue` per Flutter 3.33+ deprecation. Correct behavior. |

No stubs, no TODOs/FIXMEs, no placeholder returns, no hardcoded empty arrays flowing to render, no console.log-only handlers found across any of the 9 modified files.

### Human Verification Required

### 1. Dropdown visível e persistência Firestore

**Test:** Abrir app como cliente, tocar em um slot disponível
**Expected:** Dropdown "Esporte (opcional)" aparece entre participantes e botões; selecionar "Vôlei" e confirmar; doc /bookings/{id} no Firestore Console contém `sport: "Vôlei"`
**Why human:** Renderização condicional e escrita Firestore requerem device/browser

### 2. Dropdown oculto quando lista vazia (D-04)

**Test:** Deletar /config/sports no Firestore Console; abrir sheet de reserva
**Expected:** Dropdown não renderiza; reserva criada sem campo sport no Firestore
**Why human:** Estado real do Firestore necessário; comportamento condicional de widget

### 3. Admin seção Esportes — operações completas

**Test:** Admin > Ajustes; seção Esportes visível com lista padrão
**Expected:** Drag para reordenar funciona; adicionar "Tênis" via TextField funciona; remover "Futevôlei" funciona; clicar "Salvar Esportes" mostra snackbar de sucesso e Firestore reflete nova lista
**Why human:** Interação de drag-and-drop e feedback visual requerem execução real

### 4. Validações de input no admin

**Test:** Tentar adicionar esporte já existente; tentar adicionar nome com mais de 50 caracteres
**Expected:** Snackbar "Esporte já existe." / "Nome muito longo (máx 50 caracteres)."
**Why human:** Mensagens de erro requerem interação UI real

### 5. Chip de esporte em AdminBookingCard

**Test:** Criar reserva com sport "Vôlei", abrir aba Reservas no Admin
**Expected:** Card mostra chip colorido "Vôlei"; detalhe mostra linha com ícone esporte e "Vôlei"; reserva antiga sem sport não mostra chip nem linha
**Why human:** Chip colorido e info-row dependem de dados reais no Firestore

### Gaps Summary

No gaps found. All 11 must-haves verified, all 4 requirements satisfied, all 8 key links wired, all 6 data flows confirmed. Phase code is complete and correct.

The only open items are human verification of visual rendering and real Firestore interaction — standard for Flutter UI phases that cannot be tested statically.

---

_Verified: 2026-05-20T12:00:00Z_
_Verifier: Claude (gsd-verifier)_

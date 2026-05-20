# Phase 20: Infraestrutura de Esporte - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Entrega a infraestrutura completa do campo de esporte: BookingModel estendido com `sport?` nullable, coleção `/config/sports` no Firestore, `SportConfigCubit` com stream, dropdown opcional no formulário de reserva, gestão de esportes no SettingsTab do admin, e exibição de esporte como chip colorido nas views de admin.

</domain>

<decisions>
## Implementation Decisions

### Sport Selector no Formulário de Reserva
- **D-01:** Widget: `DropdownButtonFormField` — nativo Material, consistente com outros campos do app
- **D-02:** Label: "Esporte (opcional)" — campo nullable, não obrigatório
- **D-03:** Posição no `BookingConfirmationSheet`: depois do campo de participantes, antes dos botões de confirmação
- **D-04:** Empty state: se `/config/sports` vazio ou inexistente, esconde o dropdown completamente (não exibe campo desabilitado)

### Admin: Gestão de Esportes (SettingsTab)
- **D-05:** Seção nova "Esportes" dentro do `SettingsTab` existente — card/seção separada, igual ao padrão das outras seções
- **D-06:** SPORT-02 (reordenar): implementar com `ReorderableListView` — SPORT-02 diz explicitamente "reordenar", implementar completo
- **D-07:** Adicionar esporte: `TextField` inline + botão de adicionar
- **D-08:** Remover esporte: `IconButton` delete por item na lista

### Esporte em Views de Admin
- **D-09:** Phase 20 exibe esporte em `AdminBookingCard` e `AdminBookingDetailSheet`
- **D-10:** Display: chip colorido com cor determinada por hash do nome do esporte (algoritmo determinístico: mesma string → mesma cor de um conjunto predefinido)
- **D-11:** Quando `sport == null`: não exibe o chip (backward compatible — reservas antigas sem campo)

### Inicialização dos Esportes Padrão
- **D-12:** Inicialização client-side no `SportConfigCubit`: ao detectar doc `/config/sports` ausente ou com lista vazia, o cubit escreve os defaults automaticamente
- **D-13:** Padrão inicial: `['Vôlei', 'Beach Tênis', 'Futevôlei']`

### Claude's Discretion
- Estrutura exata do doc Firestore `/config/sports` (ex: `{sports: ['Vôlei', ...]}` seguindo padrão de `/config/pricing` com campo `tiers`)
- Conjunto de cores para o algoritmo de hash (usar palette de cores Material distintas — ex: 8-10 cores)
- `SportConfigCubit` usa `StreamSubscription` igual ao `PricingCubit` (não `_loadSettings` one-shot do `SettingsCubit`)
- Placement do `SportConfigCubit` no widget tree (provavelmente `AdminScreen` ou `SettingsTab`)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` §Phase 20 — Goal, success criteria, dependencies
- `.planning/REQUIREMENTS.md` §Campo de Esporte na Reserva — SPORT-01..04

### Models e Patterns
- `lib/core/models/booking_model.dart` — BookingModel a estender com `sport?`; padrão de campos nullable com `if (field != null)` em `toFirestore()`
- `lib/core/models/price_tier_model.dart` — Padrão de `listFromFirestore` para modelo de config

### Cubit Patterns
- `lib/features/admin/cubit/pricing_cubit.dart` — Padrão de `StreamSubscription` em `/config/pricing`; referência para `SportConfigCubit`
- `lib/features/admin/cubit/settings_cubit.dart` — Padrão de escrita em `/config/` com `SetOptions(merge: true)`

### UI Files a Modificar
- `lib/features/booking/ui/booking_confirmation_sheet.dart` — Adicionar dropdown após campo participantes
- `lib/features/admin/ui/settings_tab.dart` — Adicionar seção "Esportes"
- `lib/features/admin/ui/admin_booking_card.dart` — Adicionar chip de esporte
- `lib/features/admin/ui/admin_booking_detail_sheet.dart` — Adicionar chip de esporte

### Admin Screen (para injeção do cubit)
- `lib/features/admin/ui/admin_screen.dart` — Entry point do admin; onde `SportConfigCubit` deve ser provisionado

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PricingCubit._startStream()`: padrão exato de `StreamSubscription` em doc Firestore — replicar para `SportConfigCubit` em `/config/sports`
- `SettingsCubit.saveCredentials()`: padrão de escrita com `SetOptions(merge: true)` e error handling via Sentry
- `BookingConfirmationSheet._participantsController`: campo opcional existente — dropdown de esporte entra depois deste campo
- `SnackHelper.success/error`: usar para feedback de salvar esportes no SettingsTab

### Established Patterns
- Campos nullable no `BookingModel` usam `if (field != null)` em `toFirestore()` — sem quebrar docs existentes
- Config Firestore em `/config/{name}` doc com campos estruturados
- `BlocBuilder<XCubit, XState>` com switch de estados `Initial/Loaded/Error`
- Sentry `captureException` em todos os catch blocks

### Integration Points
- `BookingConfirmationSheet`: recebe `pixEnabled: bool` no construtor — `sport` dropdown seria state interno ou requer `SportConfigCubit` via `BlocBuilder`
- `SettingsTab`: já tem `BlocBuilder<SettingsCubit, SettingsState>` — seção de esportes pode ser `BlocBuilder<SportConfigCubit, SportConfigState>` separado ou consolidado
- `AdminBookingCard`: lê `BookingModel` fields diretamente — acessar `booking.sport`

</code_context>

<specifics>
## Specific Ideas

- Chip de esporte: cor determinada por `sport.hashCode % colors.length` onde `colors` é lista de cores Material distintas — mesma string sempre gera mesma cor, sem config extra
- SPORT-02 inclui "reordenar" explicitamente — usar `ReorderableListView` para implementar completo
- `SportConfigCubit` escreve defaults apenas uma vez (checar se doc existe antes de escrever, não sobrescrever lista que admin já configurou)

</specifics>

<deferred>
## Deferred Ideas

- Cores configuráveis por esporte (admin escolhe cor de cada esporte) — Out of Scope conforme REQUIREMENTS.md
- Múltiplos preços por esporte — v6+ conforme REQUIREMENTS.md
- Dashboard por esporte — Phase 22 (DASH-08, DASH-12)

</deferred>

---

*Phase: 20-infraestrutura-de-esporte*
*Context gathered: 2026-05-20*

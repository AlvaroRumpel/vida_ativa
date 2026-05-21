# Phase 20: Infraestrutura de Esporte - Research

**Researched:** 2026-05-20
**Domain:** Flutter/Dart — BLoC, Firestore config doc, Material widgets, nullable model fields
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Sport Selector no Formulário de Reserva**
- D-01: Widget: `DropdownButtonFormField` — nativo Material, consistente com outros campos do app
- D-02: Label: "Esporte (opcional)" — campo nullable, não obrigatório
- D-03: Posição no `BookingConfirmationSheet`: depois do campo de participantes, antes dos botões de confirmação
- D-04: Empty state: se `/config/sports` vazio ou inexistente, esconde o dropdown completamente (não exibe campo desabilitado)

**Admin: Gestão de Esportes (SettingsTab)**
- D-05: Seção nova "Esportes" dentro do `SettingsTab` existente — card/seção separada, igual ao padrão das outras seções
- D-06: SPORT-02 (reordenar): implementar com `ReorderableListView`
- D-07: Adicionar esporte: `TextField` inline + botão de adicionar
- D-08: Remover esporte: `IconButton` delete por item na lista

**Esporte em Views de Admin**
- D-09: Phase 20 exibe esporte em `AdminBookingCard` e `AdminBookingDetailSheet`
- D-10: Display: chip colorido com cor determinada por hash do nome do esporte (algoritmo determinístico)
- D-11: Quando `sport == null`: não exibe o chip (backward compatible)

**Inicialização dos Esportes Padrão**
- D-12: Inicialização client-side no `SportConfigCubit`: ao detectar doc ausente ou com lista vazia, cubit escreve os defaults automaticamente
- D-13: Padrão inicial: `['Vôlei', 'Beach Tênis', 'Futevôlei']`

### Claude's Discretion
- Estrutura exata do doc Firestore `/config/sports` (ex: `{sports: ['Vôlei', ...]}`)
- Conjunto de cores para o algoritmo de hash (palette Material distintas — 8-10 cores)
- `SportConfigCubit` usa `StreamSubscription` igual ao `PricingCubit`
- Placement do `SportConfigCubit` no widget tree (AdminScreen ou SettingsTab)

### Deferred Ideas (OUT OF SCOPE)
- Cores configuráveis por esporte (admin escolhe cor de cada esporte)
- Múltiplos preços por esporte — v6+
- Dashboard por esporte — Phase 22 (DASH-08, DASH-12)
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SPORT-01 | Cliente pode selecionar esporte opcional ao criar reserva via dropdown | `DropdownButtonFormField` nativo Material; `SportConfigCubit` fornece lista via stream; field state interno no sheet |
| SPORT-02 | Admin pode gerenciar lista de esportes nas configurações (adicionar, remover, reordenar) | `ReorderableListView` para reordenar; `TextField` inline + botão add; `IconButton` delete; `SportConfigCubit.saveSports()` persiste |
| SPORT-03 | Sistema inicializa lista de esportes com padrão: Vôlei, Beach Tênis, Futevôlei | `SportConfigCubit._startStream()` detecta doc ausente/vazio e escreve defaults |
| SPORT-04 | Reservas existentes sem campo de esporte continuam funcionando normalmente | `BookingModel.sport` nullable String?; `fromFirestore` usa `data['sport'] as String?`; `toFirestore` usa `if (sport != null)`; UI exibe chip apenas quando não-null |
</phase_requirements>

---

## Summary

Phase 20 é inteiramente interna ao projeto — sem dependências externas novas. Todo o trabalho é extensão de padrões já estabelecidos: um novo campo nullable em `BookingModel`, um novo cubit com `StreamSubscription` sobre `/config/sports`, e UI em três locais (formulário de reserva, settings admin, cards admin).

O projeto já tem dois padrões de cubit bem estabelecidos: `PricingCubit` (stream) e `SportConfigCubit` deve replicar esse padrão exatamente. `SettingsCubit` demonstra o padrão de escrita com `SetOptions(merge: true)`. `BookingModel` já tem dez campos nullable com o padrão `if (field != null)` em `toFirestore()` — `sport` é mais um campo no mesmo molde.

O único ponto de atenção de integração é o `BookingConfirmationSheet`: ele atualmente não consome nenhum cubit de config via `BlocBuilder` além do próprio `BookingCubit`. Para que o dropdown apareça, o sheet precisa ter acesso à lista de esportes — isso requer que `SportConfigCubit` esteja provisionado acima do sheet no widget tree (provavelmente `AdminScreen` ou no ponto de abertura do sheet).

**Primary recommendation:** Criar `SportConfigCubit` modelado em `PricingCubit`; provisionar no `AdminScreen` junto com `SettingsCubit`; passar a lista de esportes como parâmetro ao `BookingConfirmationSheet` ou acessar via `context.read<SportConfigCubit>()` se provisionado acima.

---

## Standard Stack

### Core (já no projeto — sem instalações novas)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter_bloc` | existente | BLoC/Cubit state management | Padrão do projeto |
| `cloud_firestore` | existente | Persistência `/config/sports` | Padrão do projeto |
| `sentry_flutter` | existente | Error reporting em catch blocks | Padrão do projeto |
| `equatable` | existente | Comparação de estados | Padrão do projeto |

**Nenhum pacote novo necessário.** [VERIFIED: leitura dos arquivos do projeto]

### Widgets Flutter relevantes

| Widget | Purpose | Configuração |
|--------|---------|-------------|
| `DropdownButtonFormField<String?>` | Selector de esporte no BookingConfirmationSheet | Valor inicial `null`; items da lista + item nulo implícito via `hint` |
| `ReorderableListView` | Reordenar esportes no SettingsTab | `onReorder` callback; cada item precisa de `key` obrigatório |
| `Chip` | Exibição de esporte em cards admin | `label`, `backgroundColor`, `labelStyle` |

[ASSUMED] Versões Flutter/Material específicas — mas esses widgets são estáveis desde Material 3 e estão no SDK, sem risco de breaking change.

---

## Architecture Patterns

### Estrutura de arquivos novos

```
lib/features/admin/cubit/
├── sport_config_cubit.dart      # StreamSubscription em /config/sports
├── sport_config_state.dart      # SportConfigInitial / SportConfigLoaded / SportConfigError
```

Nenhuma pasta nova necessária — segue estrutura existente de `lib/features/admin/cubit/`.

### Pattern 1: SportConfigCubit — StreamSubscription em doc Firestore

**O que é:** Cubit que abre stream em `/config/sports`, emite estado com lista de strings, escreve defaults se doc ausente/vazio.

**Referência exata (verificada):** `lib/features/admin/cubit/pricing_cubit.dart`

```dart
// Source: lib/features/admin/cubit/pricing_cubit.dart (padrão verificado)
class SportConfigCubit extends Cubit<SportConfigState> {
  final FirebaseFirestore _firestore;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  SportConfigCubit({required FirebaseFirestore firestore})
      : _firestore = firestore,
        super(const SportConfigInitial()) {
    _startStream();
  }

  void _startStream() {
    _sub = _firestore
        .collection('config')
        .doc('sports')
        .snapshots()
        .listen(
      (snap) {
        final data = snap.data();
        final sports = (data?['sports'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ?? [];
        if (!snap.exists || sports.isEmpty) {
          _writeDefaults();
        } else {
          emit(SportConfigLoaded(sports));
        }
      },
      onError: (e, s) {
        Sentry.captureException(e, stackTrace: s);
        emit(const SportConfigError('Erro ao carregar esportes.'));
      },
    );
  }

  Future<void> _writeDefaults() async {
    const defaults = ['Vôlei', 'Beach Tênis', 'Futevôlei'];
    try {
      await _firestore.collection('config').doc('sports').set(
        {'sports': defaults},
      );
      // Stream listener vai emitir SportConfigLoaded automaticamente após write
    } catch (e, s) {
      Sentry.captureException(e, stackTrace: s);
      emit(const SportConfigError('Erro ao inicializar esportes.'));
    }
  }

  Future<void> saveSports(List<String> sports) async {
    try {
      await _firestore.collection('config').doc('sports').set(
        {'sports': sports},
      );
      // Stream vai emitir SportConfigLoaded automaticamente
    } catch (e, s) {
      Sentry.captureException(e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
```

[VERIFIED: padrão copiado de pricing_cubit.dart com adaptação para lista de strings]

### Pattern 2: Estrutura do doc Firestore `/config/sports`

**Decisão Claude:** Seguir exatamente o padrão de `/config/pricing` que usa `{tiers: [...]}`:

```
/config/sports  →  { "sports": ["Vôlei", "Beach Tênis", "Futevôlei"] }
```

Motivo: padrão uniforme com outros docs de config; `PriceTierModel.listFromFirestore` usa `data['tiers'] as List<dynamic>?` — replicar com `data['sports'] as List<dynamic>?`. [VERIFIED: leitura de price_tier_model.dart]

### Pattern 3: Extensão de BookingModel com campo nullable

**Referência exata (verificada):** padrão `paymentMethod` em `booking_model.dart` (linha 18) — nullable String, `if (paymentMethod != null)` em `toFirestore()`, `data['paymentMethod'] as String?` em `fromFirestore`.

```dart
// Adicionar ao BookingModel — segue padrão paymentMethod/participants/etc.
final String? sport;

// No construtor:
this.sport,

// No fromFirestore:
sport: data['sport'] as String?,

// No toFirestore:
if (sport != null) 'sport': sport,

// No props list:
// Adicionar sport à lista de props no final
```

[VERIFIED: leitura de booking_model.dart]

### Pattern 4: Extensão de bookSlot / bookRecurring com sport

`BookingCubit.bookSlot()` aceita `String? participants` como opcional. `sport` segue o mesmo padrão:

```dart
// Em bookSlot — parâmetro adicional opcional:
String? sport,

// Na criação do BookingModel dentro da transação:
sport: sport,
```

Ambos `bookSlot` e `bookRecurring` precisam do parâmetro propagado. [VERIFIED: leitura de booking_cubit.dart]

### Pattern 5: Chip de esporte com cor por hash

**Decisão Claude:** Usar 8 cores Material distintas e `sport.hashCode % colors.length`.

```dart
// Fora do build, como constante ou método estático:
static const _sportColors = [
  Color(0xFF1976D2), // blue
  Color(0xFF388E3C), // green
  Color(0xFFF57C00), // orange
  Color(0xFF7B1FA2), // purple
  Color(0xFFD32F2F), // red
  Color(0xFF0288D1), // light blue
  Color(0xFF5D4037), // brown
  Color(0xFF455A64), // blue grey
];

Color _sportColor(String sport) =>
    _sportColors[sport.hashCode.abs() % _sportColors.length];

Widget _buildSportChip(String sport) => Chip(
  label: Text(sport, style: const TextStyle(color: Colors.white, fontSize: 12)),
  backgroundColor: _sportColor(sport),
  padding: EdgeInsets.zero,
  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
);
```

[ASSUMED] Conjunto específico de cores — qualquer palette Material com 8+ cores distintas funciona.

### Pattern 6: Provisão do SportConfigCubit no widget tree

**Decisão Claude:** Provisionar no `AdminScreen` junto ao `SettingsCubit` (linha 136 do admin_screen.dart). Porém `BookingConfirmationSheet` é aberto de fora do admin (na tela do cliente). Dois caminhos:

**Opção A (recomendada):** Passar `List<String> sports` como parâmetro ao `BookingConfirmationSheet`. O chamador lê `context.read<SportConfigCubit>().state` antes de abrir o sheet. Isso evita provisionar `SportConfigCubit` na árvore de cliente.

**Opção B:** Provisionar `SportConfigCubit` no nível de app (acima de ambas as telas). Mais invasivo.

**Recomendação:** Opção A — passa a lista já resolvida como parâmetro, consistente com como `pixEnabled: bool` já é passado ao sheet (linha 23 de `booking_confirmation_sheet.dart`). [VERIFIED: leitura de booking_confirmation_sheet.dart e admin_screen.dart]

O `SportConfigCubit` precisa existir em algum ponto acima do `BookingConfirmationSheet` no client flow. Verificar onde o sheet é aberto:

```
BookingConfirmationSheet é criado em: lib/features/schedule/ui/ (a verificar)
```

### Pattern 7: Provisão de SportConfigCubit no SettingsTab

`SettingsCubit` é provisionado dentro do `TabBarView` no `AdminScreen` (linha 136). `SportConfigCubit` pode ser provisionado de forma independente logo acima, ou como `MultiBlocProvider`:

```dart
// Em admin_screen.dart, substituir o BlocProvider atual do SettingsTab por:
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => SettingsCubit(firestore: FirebaseFirestore.instance)),
    BlocProvider(create: (_) => SportConfigCubit(firestore: FirebaseFirestore.instance)),
  ],
  child: const SettingsTab(),
),
```

[VERIFIED: padrão lido de admin_screen.dart linha 135-140]

### Anti-Patterns to Avoid

- **Não usar `set` com `merge: true` para a lista de esportes.** Ao salvar a lista completa (reordenada, com item removido), usar `set` sem merge para sobrescrever o doc inteiro — assim a lista é a fonte verdadeira e não há risco de entradas fantasma.
- **Não omitir `key` em itens do `ReorderableListView`.** Cada item precisa de `ValueKey(sport)` — sem isso, Flutter não consegue rastrear itens durante o reorder.
- **Não chamar `_writeDefaults()` se o stream retornar doc existente com lista não-vazia.** Checar `!snap.exists || sports.isEmpty` antes de escrever.
- **Não adicionar `sport` ao `toFirestore()` sem o guard `if (sport != null)`.** Reservas antigas sem sport não devem ter a chave no doc.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Reordenar lista de strings | Drag manual com GestureDetector | `ReorderableListView` | Handles drag, accessibility, animation — complex to re-implement |
| Cor estável por string | Map string→color hardcoded | `hashCode % colors.length` | Determinístico, sem config extra, escala para qualquer esporte futuro |
| Stream em doc Firestore | Polling / Future.wait em loop | `.snapshots().listen()` | Padrão do SDK, já em uso no projeto (PricingCubit) |

---

## Common Pitfalls

### Pitfall 1: SportConfigCubit não disponível quando BookingConfirmationSheet abre

**What goes wrong:** Sheet abre, tenta ler lista de esportes, cubit não está no contexto → exception.
**Why it happens:** Sheet é aberto na área do cliente, onde cubit não está provisionado.
**How to avoid:** Passar `List<String> sports` como parâmetro ao sheet (Opção A acima). O chamador resolve a lista antes de abrir o sheet.
**Warning signs:** `BlocProvider.of<SportConfigCubit>` não encontrado → crash imediato.

### Pitfall 2: `_writeDefaults()` chamado em loop infinito

**What goes wrong:** Stream detecta doc vazio → `_writeDefaults()` escreve → stream dispara novamente antes do write completar → `_writeDefaults()` chamado de novo.
**Why it happens:** Latência entre write e próximo snapshot; se o guard não é síncrono.
**How to avoid:** Após chamar `_writeDefaults()`, não emitir mais estado até o stream retornar o doc com dados; ou guardar flag `_initializingDefaults` no cubit.

### Pitfall 3: `ReorderableListView` sem `key` nos itens

**What goes wrong:** Flutter lança assertion error ou itens trocam de posição errada durante drag.
**Why it happens:** `ReorderableListView` requer `key` em todos os filhos diretos.
**How to avoid:** Sempre usar `ValueKey(sport)` — ou `ValueKey('sport_$index')` se nomes puderem repetir.

### Pitfall 4: `bookSlot` não propagando `sport` para `bookRecurring`

**What goes wrong:** Reservas recorrentes criadas sem esporte mesmo usuário tendo selecionado.
**Why it happens:** `bookRecurring` chama `bookSlot` — se `bookSlot` não recebe `sport`, o field é `null` em todos.
**How to avoid:** Adicionar `String? sport` em ambos `bookSlot` e `bookRecurring`; propagar em todas as chamadas dentro de `bookRecurring`.

### Pitfall 5: `DropdownButtonFormField` com lista vazia causa layout vazio sem hint

**What goes wrong:** Lista vazia → dropdown exibe sem itens, confunde usuário.
**How to avoid:** D-04 já resolve: se lista vazia, esconder o widget completamente com `if (sports.isNotEmpty)`.

---

## Code Examples

### SportConfigState

```dart
// Source: padrão de pricing_state.dart (verificado)
sealed class SportConfigState extends Equatable {
  const SportConfigState();
}

class SportConfigInitial extends SportConfigState {
  const SportConfigInitial();
  @override List<Object?> get props => [];
}

class SportConfigLoaded extends SportConfigState {
  final List<String> sports;
  const SportConfigLoaded(this.sports);
  @override List<Object?> get props => [sports];
}

class SportConfigError extends SportConfigState {
  final String message;
  const SportConfigError(this.message);
  @override List<Object?> get props => [message];
}
```

### Dropdown no BookingConfirmationSheet

```dart
// Adicionar ao state da sheet:
String? _selectedSport;

// Widget (após campo participantes, antes botões):
// sports vem como parâmetro do construtor: final List<String> sports
if (widget.sports.isNotEmpty) ...[
  const SizedBox(height: 16),
  DropdownButtonFormField<String?>(
    value: _selectedSport,
    decoration: const InputDecoration(
      labelText: 'Esporte (opcional)',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    items: [
      const DropdownMenuItem<String?>(value: null, child: Text('Não informado')),
      ...widget.sports.map((s) => DropdownMenuItem(value: s, child: Text(s))),
    ],
    onChanged: (v) => setState(() => _selectedSport = v),
  ),
],
```

### ReorderableListView no SettingsTab

```dart
// Inside _SportsSectionState
ReorderableListView(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  onReorder: (oldIndex, newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _sports.removeAt(oldIndex);
      _sports.insert(newIndex, item);
    });
  },
  children: [
    for (final sport in _sports)
      ListTile(
        key: ValueKey(sport),
        title: Text(sport),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => setState(() => _sports.remove(sport)),
            ),
            const Icon(Icons.drag_handle),
          ],
        ),
      ),
  ],
),
```

---

## Runtime State Inventory

> Fase de extensão (adicionar campo + nova coleção config) — não é rename/refactor. Itens relevantes:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | Reservas existentes em `/bookings` — nenhuma tem campo `sport` | Nenhuma migração; `fromFirestore` usa `data['sport'] as String?` — retorna null silenciosamente |
| Live service config | `/config/sports` não existe ainda | `SportConfigCubit` cria automaticamente na primeira execução |
| OS-registered state | None — sem tarefas agendadas relacionadas | None |
| Secrets/env vars | None — sem nova chave de segredo | None |
| Build artifacts | None | None |

**Backward compatibility:** SPORT-04 garantida — `data['sport'] as String?` retorna `null` para docs antigos sem o campo. Chip não exibido quando `null` (D-11). [VERIFIED: padrão de campos nullable em booking_model.dart]

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Detectar via projeto — verificar `pubspec.yaml` para `flutter_test` |
| Config file | `pubspec.yaml` (flutter_test built-in) |
| Quick run command | `flutter test --name "sport"` |
| Full suite command | `flutter test` |

> Projeto tem `feedback_no_tests.md` na memória: "Não gerar testes unitários nem de widget neste projeto". Portanto a seção de Wave 0 Gaps é vazia — sem testes a criar.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SPORT-01 | Dropdown aparece com esportes | manual-only | — | N/A (no tests policy) |
| SPORT-02 | Admin adiciona/remove/reordena | manual-only | — | N/A (no tests policy) |
| SPORT-03 | Defaults escritos se doc ausente | manual-only | — | N/A (no tests policy) |
| SPORT-04 | Reservas antigas abrem sem erro | manual-only | — | N/A (no tests policy) |

### Wave 0 Gaps
None — política do projeto proíbe geração de testes unitários/widget.

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | yes (parcial) | Regras Firestore existentes em `/config/*` devem bloquear escrita por não-admin |
| V5 Input Validation | yes | Nome de esporte: String não vazia, max length razoável (ex: 50 chars) antes de salvar |
| V6 Cryptography | no | — |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cliente escreve em `/config/sports` | Tampering | Regras Firestore: `allow write: if request.auth.token.admin == true` — verificar que regra existente para `/config/*` já cobre este doc |
| Esporte com string muito longa enviada via UI | Tampering | Adicionar `maxLength` no `TextField` de adicionar esporte (ex: 50 chars) |
| Lista de esportes com item duplicado | — | Checar antes de adicionar: `if (!_sports.contains(name))` |

> Verificar se as Firestore Security Rules atuais já cobrem `/config/sports` — se `/config/{document}` já tem regra de escrita admin-only, está coberto sem alteração.

---

## Open Questions

1. **Onde `BookingConfirmationSheet` é instanciado no client flow?**
   - O que sabemos: sheet recebe `pixEnabled: bool` como parâmetro do construtor
   - Gap: não lemos o arquivo que abre o sheet (provavelmente `lib/features/schedule/ui/`)
   - Recomendação: Planner deve incluir tarefa de ler o caller e adicionar `sports` como parâmetro; caller lê `SportConfigCubit` antes de abrir sheet

2. **`BookingConfirmationSheet` precisa de `SportConfigCubit` provisionado acima para ler a lista?**
   - Recomendado: Opção A — passar lista resolvida como parâmetro `List<String> sports`, idêntico ao padrão `pixEnabled: bool`
   - Isso mantém o sheet stateless em relação ao cubit e não muda a arquitetura de provisão

3. **Firestore Security Rules cobrem `/config/sports`?**
   - O que sabemos: `/config/pricing` e `/config/booking` existem; presumivelmente regras cobrem `/config/{doc}`
   - Recomendação: Confirmar no console Firebase antes de deploy; sem alteração esperada

---

## Environment Availability

Step 2.6: SKIPPED — fase é puramente código Flutter/Dart + Firestore, sem novas ferramentas externas ou CLIs além das já em uso no projeto.

---

## Sources

### Primary (HIGH confidence)
- `lib/features/admin/cubit/pricing_cubit.dart` — padrão StreamSubscription em doc Firestore
- `lib/features/admin/cubit/pricing_state.dart` — padrão sealed class de estado
- `lib/core/models/booking_model.dart` — padrão de campos nullable, fromFirestore, toFirestore, props
- `lib/core/models/price_tier_model.dart` — padrão listFromFirestore e estrutura de doc config
- `lib/features/admin/cubit/settings_cubit.dart` — padrão de escrita com SetOptions(merge: true)
- `lib/features/booking/ui/booking_confirmation_sheet.dart` — estrutura atual do sheet, ponto de inserção do dropdown
- `lib/features/admin/ui/settings_tab.dart` — estrutura atual, ponto de inserção seção Esportes
- `lib/features/admin/ui/admin_booking_card.dart` — ponto de inserção chip de esporte
- `lib/features/admin/ui/admin_booking_detail_sheet.dart` — ponto de inserção chip de esporte
- `lib/features/admin/ui/admin_screen.dart` — ponto de provisão do SportConfigCubit
- `lib/features/booking/cubit/booking_cubit.dart` — bookSlot / bookRecurring a estender com sport

### Secondary (MEDIUM confidence)
- Flutter documentation: `ReorderableListView` requer `key` em filhos diretos [ASSUMED — padrão bem documentado]
- Flutter documentation: `DropdownButtonFormField<String?>` aceita valor null como "sem seleção" [ASSUMED]

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Conjunto de cores para hash (8 cores Material) | Architecture Pattern 5 | Baixo — qualquer palette funciona; só impacto visual |
| A2 | `DropdownButtonFormField<String?>` aceita null como valor sem seleção | Code Examples | Baixo — padrão Flutter bem estabelecido |
| A3 | `ReorderableListView` requer `key` obrigatório em todos os filhos | Common Pitfalls 3 | Médio — sem key causa assertion error em debug |
| A4 | Firestore Security Rules existentes cobrem `/config/sports` | Security Domain | Médio — se não cobrir, qualquer usuário autenticado pode escrever esportes |

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — sem novas dependências, tudo verificado no projeto
- Architecture: HIGH — padrões copiados diretamente de arquivos verificados
- Pitfalls: HIGH — derivados da leitura direta do código existente
- Security: MEDIUM — regras Firestore não foram lidas diretamente

**Research date:** 2026-05-20
**Valid until:** 2026-06-20 (estável — sem dependências de terceiros novas)

# Phase 21: Backend do Dashboard - Research

**Researched:** 2026-05-20
**Domain:** Firebase Cloud Functions (Node.js v2) + Flutter BLoC / Cubit + Firestore rules
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Rolling window — 3 docs fixos: `/config/dashboard/week`, `/config/dashboard/month`, `/config/dashboard/year`. Representam sempre o período atual (semana civil corrente, mês corrente, ano corrente). `scheduledDailyAggregation` sobrescreve esses docs diariamente.
- **D-02:** "Semana atual" = Seg–Dom da semana civil corrente (não janela de 7 dias móvel).
- **D-03:** Cada doc contém todos os campos necessários para as métricas do período.
- **D-04:** CF conta `/slots` onde `active == true` para calcular total de slots disponíveis. Query executada a cada disparo do `onBookingStateChange`.
- **D-05:** `occupancyRate = totalSlotsBooked / totalSlotsAvailable` (0–1).
- **D-06:** `onBookingStateChange` atualiza apenas contadores simples via increment/decrement atômico.
- **D-07:** Métricas complexas ficam exclusivamente no `scheduledDailyAggregation` (top 5 clientes, taxa retorno, clientes únicos/novos, receita por esporte, no-show rate, taxa de conversão). Défasagem D+1 aceitável.
- **D-08:** `scheduledDailyAggregation` roda às 03:00 AM America/Sao_Paulo. Recalcula todos os campos dos 3 docs do zero.
- **D-09:** "Novo cliente" = userId cuja primeira reserva `confirmed` ever foi nesse período. Calculado buscando MIN(createdAt) do userId nos bookings históricos.
- **D-10:** Taxa de conversão = todos bookings confirmados / todos bookings criados no período. On_arrival confirmadas contam como 100% convertidas.
- **D-11:** No-show rate = bookings com `paymentMethod == 'on_arrival'` que não foram confirmados (status `cancelled` ou `rejected`) / total on_arrival criados.
- **D-12:** Top 5 clientes: CF desnormaliza `{userId, displayName, bookingCount}` no array `topClients`. Lê `users/{id}.displayName` na hora do scheduled.
- **D-13:** `DashboardCubit` usa `StreamSubscription` em `/config/dashboard` collection (igual ao `PricingCubit`).
- **D-14:** Estado: `DashboardLoading`, `DashboardLoaded(week, month, year)`, `DashboardError`. Os 3 docs carregados de uma vez.
- **D-15:** `DashboardCubit` provisionado em `AdminScreen` (igual ao padrão do `SportConfigCubit`).
- **D-16:** `/config/dashboard` read restrito a admin; escrita bloqueada para cliente Flutter (apenas CFs escrevem via `admin.firestore()`).

### Claude's Discretion

- Lógica de increment/decrement no `onBookingStateChange` — quais transições de status disparam increment vs. decrement
- Estrutura da query para contar `/slots` ativos por período (consultar padrão do `updateSlotPricesFromTiers`)
- Tratamento de falha no `scheduledDailyAggregation` — log via `console.error`, Sentry já captura via runtime
- `DashboardData` model Dart com campos nullables para retrocompatibilidade caso doc não exista

### Deferred Ideas (OUT OF SCOPE)

- Histórico de períodos anteriores (comparar semana atual vs. semana passada)
- Export de relatório em CSV/PDF
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DASH-01 | Admin vê taxa de ocupação (% slots reservados) com toggle semana/mês/ano | `onBookingStateChange` incrementa `totalSlotsBooked`; `scheduledDailyAggregation` calcula `occupancyRate = totalSlotsBooked / totalSlotsAvailable` |
| DASH-02 | Admin vê receita total confirmada e split Pix vs presencial por período | `onBookingStateChange` incrementa `totalRevenue`, `pixRevenue`, `onArrivalRevenue` na transição para `confirmed` |
| DASH-03 | Admin vê ticket médio e taxa de conversão por período | `scheduledDailyAggregation` calcula `avgTicket = totalRevenue / confirmedBookings` e `conversionRate` |
| DASH-04 | Admin vê no-show rate de reservas on_arrival por período | `scheduledDailyAggregation` calcula `noShowRate` com query filtrada por `paymentMethod == 'on_arrival'` |
| DASH-09 | Admin vê total de clientes únicos e novos no período | `scheduledDailyAggregation` calcula `uniqueClients` e `newClients` buscando MIN(createdAt) por userId |
| DASH-10 | Admin vê top 5 clientes mais frequentes com nome e n° de reservas | `scheduledDailyAggregation` desnormaliza `topClients[]` lendo `users/{id}.displayName` |
| DASH-11 | Admin vê taxa de retorno (% clientes com >1 booking no período) | `scheduledDailyAggregation` calcula `returnRate` |
| DASH-12 | Admin vê receita gerada por esporte no período | `scheduledDailyAggregation` agrupa `totalRevenue` por `booking.sport`; nulls agrupados como "Não informado" |
</phase_requirements>

---

## Summary

Phase 21 entrega o backend completo de agregação do dashboard: duas Cloud Functions Node.js v2 (`onBookingStateChange` e `scheduledDailyAggregation`) que mantêm 3 documentos fixos em `/config/dashboard/{week|month|year}`, e o `DashboardCubit` Flutter que lê esses documentos via stream em tempo real.

O padrão de `onDocumentWritten` em `bookings/{bookingId}` já existe no projeto (`notifyAdminNewBooking`) — `onBookingStateChange` replica exatamente essa estrutura. O `scheduledDailyAggregation` usa `onSchedule` com objeto de opções que inclui `timeZone: 'America/Sao_Paulo'` (v2 suporta esse campo no objeto de config). O `DashboardCubit` é cópia direta do `PricingCubit` com tipo diferente.

**Primary recommendation:** Copiar padrões existentes do projeto. Não inventar nada novo — cada peça desta fase tem um análogo exato no codebase atual.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| firebase-functions v2 | ^7.2.5 [VERIFIED: npm registry] | `onDocumentWritten`, `onSchedule` | Já em uso no projeto |
| firebase-admin | ^13.0.0 [VERIFIED: functions/package.json] | Firestore writes via SDK admin (bypass rules) | Padrão para CFs |
| cloud_firestore (Flutter) | já no pubspec [ASSUMED] | Stream de `/config/dashboard` | Já em uso em PricingCubit |
| flutter_bloc | já no pubspec [ASSUMED] | Cubit pattern | Padrão estabelecido no projeto |
| sentry_flutter | já no pubspec [ASSUMED] | Error capture no cubit | Padrão em todos cubits |
| equatable | já no pubspec [ASSUMED] | State equality | Padrão em todos states |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| FieldValue.increment | (firebase-admin built-in) | Incrementos atômicos nos contadores | `onBookingStateChange` — evita race condition |

**Installation:** Nenhum pacote novo necessário. Tudo já instalado.

---

## Architecture Patterns

### Recommended Project Structure

Novos arquivos a criar:

```
functions/index.js              # + exports.onBookingStateChange
                                # + exports.scheduledDailyAggregation

lib/features/admin/
  cubit/
    dashboard_cubit.dart        # novo — replica PricingCubit
    dashboard_state.dart        # novo — DashboardLoading/Loaded/Error
  models/
    dashboard_data.dart         # novo — DashboardData com campos nullable

firestore.rules                 # + regra /config/dashboard/{period}
```

### Pattern 1: onBookingStateChange — Trigger e Guard

**What:** `onDocumentWritten` em `bookings/{bookingId}` que detecta transições de status relevantes e aplica incrementos/decrementos atômicos nos 3 docs de dashboard.

**When to use:** Toda escrita em `/bookings` dispara o trigger; o guard `before.status → after.status` decide se há ação.

**Status transitions que disparam ação:**

```
CRIAÇÃO (before == null):
  after.status == 'pending'          → pendingBookings +1, totalBookings +1
  after.status == 'confirmed'        → confirmedBookings +1, totalBookings +1, totalRevenue +price, pixRevenue/onArrivalRevenue +price, totalSlotsBooked +1
  after.status == 'pending_payment'  → totalBookings +1 (não conta como confirmed)

TRANSIÇÃO (before != null → after != null):
  pending → confirmed                → pendingBookings -1, confirmedBookings +1, totalRevenue +price, totalSlotsBooked +1
  pending_payment → confirmed        → confirmedBookings +1, totalRevenue +price, pixRevenue +price, totalSlotsBooked +1
  pending → cancelled                → pendingBookings -1, cancelledBookings +1
  pending → rejected                 → pendingBookings -1, cancelledBookings +1
  confirmed → cancelled              → confirmedBookings -1, cancelledBookings +1, totalRevenue -price, totalSlotsBooked -1
  confirmed → rejected               → confirmedBookings -1, cancelledBookings +1, totalRevenue -price, totalSlotsBooked -1
  pending_payment → cancelled        → cancelledBookings +1
  pending_payment → expired          → ignorar (não conta nos contadores de dashboard)
```

**Example:**

```javascript
// Source: functions/index.js (notifyAdminNewBooking — padrão base)
// Path Firestore RESOLVIDO (ver Q-1 abaixo): collection('config').doc('dashboard').collection('periods').doc(period)
exports.onBookingStateChange = onDocumentWritten('bookings/{bookingId}', async (event) => {
  const before = event.data.before?.data();
  const after = event.data.after?.data();

  if (!after) return; // document deleted — ignore

  const db = admin.firestore();
  const bookingDate = after.date; // 'YYYY-MM-DD'

  // Determine which periods this booking falls in
  const periods = getActivePeriods(bookingDate); // returns ['week'|'month'|'year'] subset

  if (periods.length === 0) return; // booking outside current rolling windows

  const deltas = computeDeltas(before, after); // returns {field: increment_value}
  if (Object.keys(deltas).length === 0) return;

  const batch = db.batch();
  for (const period of periods) {
    const ref = db.collection('config').doc('dashboard').collection('periods').doc(period);
    // set+merge handles first-deploy case where doc does not exist (Pitfall 1)
    batch.set(ref, Object.fromEntries(
      Object.entries(deltas).map(([k, v]) => [k, admin.firestore.FieldValue.increment(v)])
    ), { merge: true });
  }
  batch.commit();
});
```

### Pattern 2: scheduledDailyAggregation — onSchedule com timezone

**What:** `onSchedule` v2 com objeto de opções que suporta `schedule` (string App Engine ou cron) e `timeZone` (IANA timezone string).

**Example:**

```javascript
// Source: [CITED: firebase.google.com/docs/functions/schedule-functions + scheduler.ScheduleOptions]
exports.scheduledDailyAggregation = onSchedule(
  { schedule: 'every day 03:00', timeZone: 'America/Sao_Paulo' },
  async (event) => {
    const db = admin.firestore();
    // Recalculate all 3 docs from scratch
    for (const period of ['week', 'month', 'year']) {
      const { startDate, endDate } = getPeriodRange(period); // compute current rolling window
      const data = await aggregateForPeriod(db, startDate, endDate);
      await db.collection('config').doc('dashboard').collection('periods').doc(period).set({
        period,
        startDate,
        endDate,
        updatedAt: admin.firestore.Timestamp.now(),
        ...data,
      });
    }
  }
);
```

### Pattern 3: DashboardCubit — Stream em collection (não doc único)

**What:** D-14 especifica que os 3 docs são carregados de uma vez. Isso requer escutar a **subcollection** `periods` dentro do doc `/config/dashboard`. Resolvido em Q-1: path é `collection('config').doc('dashboard').collection('periods').snapshots()`.

```dart
// Source: cloud_firestore docs — CollectionReference.snapshots()
// Subcollection escutada: /config/dashboard/periods (3 docs: week, month, year)
_sub = _firestore
    .collection('config')
    .doc('dashboard')
    .collection('periods')
    .snapshots()
    .listen((snap) {
      // snap.docs contém week, month, year
      final docs = {for (final d in snap.docs) d.id: d.data()};
      emit(DashboardLoaded(
        week: DashboardData.fromMap(docs['week']),
        month: DashboardData.fromMap(docs['month']),
        year: DashboardData.fromMap(docs['year']),
      ));
    }, onError: (e, s) {
      Sentry.captureException(e, stackTrace: s);
      emit(DashboardError('Erro ao carregar dashboard.'));
    });
```

### Pattern 4: DashboardData — model Dart com campos nullable

```dart
// Source: BookingModel pattern (lib/core/models/booking_model.dart) — nullable fields
class DashboardData {
  final String period;
  final String startDate;
  final String endDate;
  final DateTime? updatedAt;

  // Contadores simples (set by onBookingStateChange)
  final int totalBookings;
  final int confirmedBookings;
  final int cancelledBookings;
  final int pendingBookings;
  final int totalSlotsBooked;
  final double totalRevenue;
  final double pixRevenue;
  final double onArrivalRevenue;

  // Calculados pelo scheduled (nullable — podem não existir no primeiro dia)
  final int? totalSlotsAvailable;
  final double? occupancyRate;
  final double? avgTicket;
  final double? conversionRate;
  final double? noShowRate;
  final int? uniqueClients;
  final int? newClients;
  final double? returnRate;
  final List<TopClientEntry>? topClients;
  final List<RevenueBySportEntry>? revenueBySport;

  // factory DashboardData.fromMap(Map<String, dynamic>? map)
  // Se map == null → retorna DashboardData vazio (todos contadores = 0)
}
```

### Pattern 5: Firestore Rules — bloco específico antes do wildcard

**What:** Regra `/config/dashboard/periods/{period}` deve aparecer ANTES do wildcard `/config/{docId}` no arquivo `firestore.rules`. Regras Firestore usam first-match por especificidade, mas para garantir, posicionar o bloco mais específico primeiro.

```javascript
// Source: firestore.rules (padrão existente /config/mercadopago)
// Path 4 segmentos: config/dashboard/periods/{period}

match /config/dashboard/periods/{period} {
  allow read: if isAdmin();
  allow write: if false; // apenas Cloud Functions via admin SDK escrevem
}

// Mantém o wildcard existente abaixo
match /config/{docId} {
  allow read: if isAuthenticated();
  allow write: if isAdmin();
}
```

### Pattern 6: AdminScreen — provisão do DashboardCubit

**What:** `AdminScreen` usa `MultiBlocProvider` apenas no SettingsTab hoje. `DashboardCubit` deve ser provisionado no nível mais alto que o DashboardTab precisar — provavelmente na raiz do `AdminScreen.build()`, não dentro de um tab específico.

**Recommendation:** Envolver o `Scaffold` inteiro com `BlocProvider<DashboardCubit>` no `AdminScreen.build()`, similar a como `_fcmCubit` é provisionado com `BlocProvider.value`.

```dart
// Adaptar admin_screen.dart — envolver com BlocProvider no build():
return BlocProvider(
  create: (_) => DashboardCubit(firestore: FirebaseFirestore.instance),
  child: BlocProvider.value(
    value: _fcmCubit,
    child: Scaffold(...),
  ),
);
```

### Pattern 7: Lógica de Período — getActivePeriods()

**What:** Dado um `bookingDate` ('YYYY-MM-DD'), determinar quais dos 3 períodos rolling (week, month, year) contêm essa data. Chamado tanto em `onBookingStateChange` quanto em `scheduledDailyAggregation`.

```javascript
// Source: [ASSUMED] — lógica de datas padrão JavaScript
function getCurrentPeriodRanges() {
  const now = new Date();
  // Week: Monday to Sunday of current ISO week
  const dayOfWeek = now.getDay() === 0 ? 7 : now.getDay(); // 1=Mon, 7=Sun
  const monday = new Date(now);
  monday.setDate(now.getDate() - (dayOfWeek - 1));
  const sunday = new Date(monday);
  sunday.setDate(monday.getDate() + 6);

  // Month: 1st to last day of current month
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
  const monthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0);

  // Year: Jan 1 to Dec 31
  const yearStart = new Date(now.getFullYear(), 0, 1);
  const yearEnd = new Date(now.getFullYear(), 11, 31);

  return { week: [toDateStr(monday), toDateStr(sunday)],
           month: [toDateStr(monthStart), toDateStr(monthEnd)],
           year: [toDateStr(yearStart), toDateStr(yearEnd)] };
}

function getActivePeriods(bookingDate) {
  const ranges = getCurrentPeriodRanges();
  return ['week', 'month', 'year'].filter(p =>
    bookingDate >= ranges[p][0] && bookingDate <= ranges[p][1]
  );
}
```

### Anti-Patterns to Avoid

- **Não usar Firestore aggregation queries (`count()`) em listeners:** Firestore aggregation não suporta real-time — confirma arquitetura write-time via CF [VERIFIED: STATE.md decisão arquitetural v5.0].
- **Não inicializar docs com `merge: true` + `FieldValue.increment` sem doc existente:** `FieldValue.increment` em campo inexistente funciona (cria com o valor delta), mas `batch.update()` falha se o doc não existe. Usar `set({...}, {merge: true})` no lugar de `update()` para os incrementos.
- **Não calcular `new Date()` sem considerar fuso horário:** O `scheduledDailyAggregation` roda às 03:00 BRT — quando `new Date()` é chamado no contexto da função, o horário UTC será 06:00. Usar a date string de `bookingDate` (sempre 'YYYY-MM-DD' local) como âncora, não UTC timestamp.
- **Não ignorar o caso `doc não existe` no DashboardData.fromMap():** No primeiro deploy, os docs ainda não existem. `DashboardData.fromMap(null)` deve retornar um objeto com zeros, não throw.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Incrementos atômicos | Lógica de read-modify-write | `FieldValue.increment(n)` | Race condition se dois eventos simultâneos |
| Batch multi-doc writes | Promises individuais | `db.batch()` | Atomicidade garantida |
| Error capture nas CFs | `try/catch` manual com log | `console.error()` + Sentry runtime | Padrão existente; Sentry já configurado |
| Firestore stream Flutter | Polling manual | `CollectionReference.snapshots()` | Real-time nativo; Cubit já tem padrão |

---

## Common Pitfalls

### Pitfall 1: `batch.update()` em doc inexistente

**What goes wrong:** `onBookingStateChange` tenta incrementar contadores num doc que ainda não existe → Firestore lança `NOT_FOUND` error, a CF falha silenciosamente (ou com retry storm).

**Why it happens:** Os docs de dashboard não existem antes do primeiro deploy + primeiro booking.

**How to avoid:** Usar `batch.set(ref, deltas, { merge: true })` em vez de `batch.update()`. `FieldValue.increment` funciona com `set+merge` — se o campo não existe, cria com o valor do delta.

**Warning signs:** CF retries em loop após primeiro deploy em produção.

---

### Pitfall 2: Dupla contagem no `onBookingStateChange`

**What goes wrong:** Um booking muda de status duas vezes em sequência (ex: `pending → confirmed → cancelled`). Cada transição dispara a CF. Se a CF não checar corretamente `before.status → after.status`, pode incrementar e não decrementar, ou decrementar em -1 abaixo de zero.

**Why it happens:** Comparação incompleta do par `(before.status, after.status)`.

**How to avoid:** A função `computeDeltas(before, after)` deve checar o par exato de transição — não apenas `after.status`. Ver tabela de transições no Pattern 1.

**Warning signs:** Contadores de confirmedBookings divergem do count real de bookings confirmados no Firestore.

---

### Pitfall 3: Período incorreto no `getActivePeriods()`

**What goes wrong:** Booking de mês passado (ex: 30/abr com hoje = 01/mai) recebe increments no doc do mês corrente. Contadores ficam inflados.

**Why it happens:** `bookingDate` é a data da reserva; os ranges são calculados no momento do trigger, não no momento da criação da reserva. Para on-time bookings isso é correto; para bookings retroativos ou de teste pode haver edge cases.

**How to avoid:** `getActivePeriods(bookingDate)` retorna `[]` se a data não está em nenhum período corrente — a CF retorna cedo. Isso é o comportamento correto (bookings fora do rolling window não afetam os contadores do período corrente).

**Warning signs:** Taxa de ocupação > 100%.

---

### Pitfall 4: `onSchedule` sem `timeZone` — roda às 03:00 UTC não BRT

**What goes wrong:** `onSchedule('every day 03:00', ...)` sem `timeZone` usa UTC por padrão. Às 03:00 UTC = 00:00 BRT (meia-noite) — aceitável mas não é o que foi especificado.

**Why it happens:** O `expireUnpaidBookings` existente usa a forma sem opções — funcionar para ele (15min interval) mas não para schedule horário específico.

**How to avoid:** Sempre usar objeto de opções: `onSchedule({ schedule: 'every day 03:00', timeZone: 'America/Sao_Paulo' }, handler)`.

**Warning signs:** Logs da CF aparecendo às 06:00 UTC no Cloud Console.

---

### Pitfall 5: Regra Firestore — escrita de admin bloqueada por nova regra

**What goes wrong:** A nova regra `/config/dashboard/{period}` com `allow write: if false` pode bloquear o admin Flutter de escrever — mas isso é INTENCIONAL (D-16). O que pode dar errado: se a regra for adicionada DEPOIS do wildcard `/config/{docId}`, o Firestore pode aplicar o wildcard primeiro (admin pode escrever).

**Why it happens:** Firestore rules matching — regras mais específicas NÃO têm precedência automática em todos os casos quando estão em blocos separados do mesmo nível.

**How to avoid:** Testar com Firebase emulator após deploy. Verificar com `firebase emulators:start` que admin não consegue escrever direto no `/config/dashboard/week`.

**Warning signs:** Admin consegue escrever diretamente via Flutter sem CF — contadores ficam inconsistentes.

---

## Runtime State Inventory

> Fase de greenfield (novos documentos Firestore). Sem rename/migration de dados existentes.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | Nenhum — `/config/dashboard/*` docs não existem ainda | Wave 0: CFs criam docs na primeira execução |
| Live service config | Cloud Functions `onBookingStateChange` e `scheduledDailyAggregation` são novos exports | Deploy via `firebase deploy --only functions` |
| OS-registered state | Nenhum | — |
| Secrets/env vars | Nenhum — usa mesmo `admin.initializeApp()` existente | — |
| Build artifacts | Nenhum — sem renaming | — |

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | Cloud Functions runtime | ✓ | 22 (engines field) [VERIFIED: functions/package.json] | — |
| firebase-functions | CF exports | ✓ | ^7.2.5 [VERIFIED: npm registry] | — |
| firebase-admin | CF admin writes | ✓ | ^13.0.0 [VERIFIED: functions/package.json] | — |
| Firebase emulator | Firestore rules testing | [ASSUMED] | — | Deploy to staging (feedback_firebase_deploy.md: sempre staging) |

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (built-in Flutter SDK) |
| Config file | pubspec.yaml |
| Quick run command | `flutter test test/features/admin/cubit/dashboard_cubit_test.dart` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DASH-01 | DashboardCubit emite `DashboardLoaded` com `occupancyRate` do doc Firestore | unit | `flutter test test/features/admin/cubit/dashboard_cubit_test.dart` | ❌ Wave 0 |
| DASH-02 | `DashboardLoaded.week.totalRevenue` reflete valor do doc Firestore | unit | `flutter test test/features/admin/cubit/dashboard_cubit_test.dart` | ❌ Wave 0 |
| DASH-03 | `DashboardLoaded.month.avgTicket` e `conversionRate` parseados corretamente | unit | `flutter test test/features/admin/cubit/dashboard_cubit_test.dart` | ❌ Wave 0 |
| DASH-04 | `noShowRate` nullable — não lança quando campo ausente no doc | unit | `flutter test test/features/admin/cubit/dashboard_cubit_test.dart` | ❌ Wave 0 |
| DASH-09 | `uniqueClients` e `newClients` nullable — padrão 0 quando doc não existe | unit | `flutter test test/features/admin/cubit/dashboard_cubit_test.dart` | ❌ Wave 0 |
| DASH-10 | `topClients` lista parseada corretamente de array Firestore | unit | `flutter test test/features/admin/cubit/dashboard_cubit_test.dart` | ❌ Wave 0 |
| DASH-11 | `returnRate` nullable — sem throw | unit | `flutter test test/features/admin/cubit/dashboard_cubit_test.dart` | ❌ Wave 0 |
| DASH-12 | `revenueBySport` lista parseada; entrada com sport=null agrupada como "Não informado" | unit (DashboardData.fromMap) | `flutter test test/core/models/` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `flutter test test/features/admin/cubit/dashboard_cubit_test.dart`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green antes do `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/features/admin/cubit/dashboard_cubit_test.dart` — cobre DASH-01..04, DASH-09..11; replica padrão de `pricing_cubit_test.dart` (Fake Firestore já disponível como template)
- [ ] `test/core/models/dashboard_data_test.dart` — cobre `DashboardData.fromMap()` com campos nullable e doc nulo (DASH-12)

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | `isAuthenticated()` já existente em firestore.rules |
| V3 Session Management | no | — |
| V4 Access Control | yes | Nova regra `allow read: if isAdmin()` em `/config/dashboard/{period}`; `allow write: if false` |
| V5 Input Validation | no | CFs não recebem input externo — são triggers internos |
| V6 Cryptography | no | — |

### Known Threat Patterns for stack (Cloud Functions + Firestore rules)

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cliente Flutter escreve diretamente em `/config/dashboard` | Tampering | `allow write: if false` na regra Firestore |
| CF `onBookingStateChange` chamada com booking de outro tenant (se multi-tenant) | Tampering | N/A — projeto single-tenant |
| Admin lê dados de receita de outro admin | Info Disclosure | `isAdmin()` verifica role do usuário autenticado; todos os admins têm acesso |

---

## Code Examples

### Fake Firestore template para dashboard_cubit_test.dart

```dart
// Source: test/features/admin/cubit/pricing_cubit_test.dart (padrão estabelecido)
// Adaptar para CollectionReference ao invés de DocumentReference

class _FakeQuerySnapshot extends Fake
    implements QuerySnapshot<Map<String, dynamic>> {
  final List<_FakeDocSnapshot> _docs;
  _FakeQuerySnapshot(this._docs);
  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => _docs.cast();
}

class _FakeCollRef extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final StreamController<QuerySnapshot<Map<String, dynamic>>> _ctrl =
      StreamController.broadcast();

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({...}) => _ctrl.stream;

  void addSnapshots(Map<String, Map<String, dynamic>?> docs) => _ctrl.add(
        _FakeQuerySnapshot(
          docs.entries.map((e) => _FakeDocSnapshot(e.key, e.value)).toList(),
        ),
      );
}
```

### FieldValue.increment com set+merge (evita NOT_FOUND)

```javascript
// Source: [CITED: firebase.google.com/docs/firestore/manage-data/add-data#update_fields_in_nested_objects]
const ref = db.collection('config').doc('dashboard').collection('periods').doc('week');
await ref.set(
  { confirmedBookings: admin.firestore.FieldValue.increment(1),
    totalRevenue: admin.firestore.FieldValue.increment(price ?? 0) },
  { merge: true }
);
// Se doc não existe, cria com os valores. Se existe, faz merge incremental.
```

### onSchedule com timezone (v2)

```javascript
// Source: [CITED: firebase.google.com/docs/reference/functions/2nd-gen/node/firebase-functions.scheduler.scheduleoptions]
exports.scheduledDailyAggregation = onSchedule(
  { schedule: 'every day 03:00', timeZone: 'America/Sao_Paulo' },
  async (event) => { /* ... */ }
);
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Firestore aggregation queries em listeners | Write-time counters via CF | v5.0 Architecture decision | Real-time listener possível em DashboardCubit |
| onSchedule sem timezone (v1 style) | onSchedule com ScheduleOptions object (v2) | firebase-functions v2 | Especificar `timeZone: 'America/Sao_Paulo'` corretamente |

---

## Open Questions

> **Status:** Todas as open questions originalmente identificadas foram RESOLVIDAS via decisões locked no CONTEXT.md (gathered 2026-05-20). Mantidas aqui com a resolução para rastreabilidade.

### Q-1: Path exato de `/config/dashboard/{period}` no Firestore — RESOLVED

- **Original question:** D-01 refere-se a `/config/dashboard/{period}`. Em Firestore, paths têm alternância collection/document. Se `dashboard` é um documento com subcollection, qual o nome da subcollection?
- **Resolution:** RESOLVED via CONTEXT.md §D-01 + Plans 21-01/21-02/21-03.
  - **Path final:** `collection('config').doc('dashboard').collection('periods').doc(period)` onde `period in ['week','month','year']`.
  - **Plans status:** 21-01 (DashboardCubit), 21-02 (Cloud Functions) e 21-03 (Firestore rules) já usam esse path consistentemente. Ver:
    - `21-01-PLAN.md` linha 55: `collection('config').doc('dashboard').collection('periods')`
    - `21-02-PLAN.md` linhas 343-347: `db.collection('config').doc('dashboard').collection('periods').doc(period)`
    - `21-03-PLAN.md` linhas 237-241: `match /config/dashboard/periods/{period}` (4 segmentos, regra específica antes do wildcard).
  - **Subcollection naming:** `periods` (escolha de Claude's Discretion confirmada nos plans).
- **Citation:** CONTEXT.md §D-01 (locked decision); 21-01-PLAN.md key_links; 21-02-PLAN.md acceptance_criteria; 21-03-PLAN.md interfaces block.
- **Action required:** Nenhuma — plans já corretos.

### Q-2: Campo `active` em `/slots` — RESOLVED

- **Original question:** D-04 diz "CF conta `/slots` onde `active == true`". O campo `active` existe no SlotModel atual?
- **Resolution:** RESOLVED via CONTEXT.md §"SlotModel CRITICAL" + Plans 21-02 acceptance criteria.
  - **Campo correto:** O nome real é `isActive` (não `active`). CONTEXT.md afirma textualmente: "SlotModel CRITICAL: campo Dart é `isActive` (não `active`). Firestore stores key `isActive`. Query DEVE ser `.where('isActive', '==', true)`."
  - **Plans status:** Plan 21-02 já usa o valor correto:
    - `21-02-PLAN.md` linha 47: key_link pattern `where\\('isActive', '==', true\\)`
    - `21-02-PLAN.md` linha 477: `db.collection('slots').where('isActive', '==', true)`
    - `21-02-PLAN.md` linha 625: acceptance criteria exige `where('isActive', '==', true)` (não `'active'`).
  - **D-04 interpretação:** A decisão D-04 usa "active" como termo conceitual, mas o nome técnico do campo é `isActive`. CONTEXT.md já fez essa tradução. Plans honram o nome técnico real.
- **Citation:** CONTEXT.md §"SlotModel CRITICAL" (interfaces block do Plan 21-02); 21-02-PLAN.md key_links + acceptance_criteria; SlotModel source (`lib/core/models/slot_model.dart`).
- **Action required:** Nenhuma — plans já corretos.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `cloud_firestore`, `flutter_bloc`, `sentry_flutter`, `equatable` já no pubspec.yaml | Standard Stack | Se algum não estiver, Wave 0 precisa adicionar dependência — baixo risco |
| A2 | Firebase emulator disponível no ambiente de desenvolvimento | Environment Availability | Testes de Firestore rules requerem emulator; fallback é deploy em staging |
| A3 | Campo `isActive` existe em `/slots` documents (resolvido em Q-2) | Open Questions Q-2 | RESOLVED — CONTEXT.md confirma campo `isActive` |
| A4 | `onSchedule` v2 aceita objeto `{ schedule, timeZone }` como primeiro argumento | Code Examples | MEDIUM — verificado via search cross-referencing official ScheduleOptions interface |

---

## Sources

### Primary (HIGH confidence)
- `functions/index.js` linhas 39-56, 505-538, 716-791 — padrões `onDocumentWritten`, `onSchedule`, query de slots
- `lib/features/admin/cubit/pricing_cubit.dart` — padrão StreamSubscription em `/config/`
- `lib/features/admin/cubit/sport_config_cubit.dart` — padrão mais recente, mesma família
- `lib/core/models/booking_model.dart` — campos existentes (status, paymentMethod, sport, price, date, userId)
- `lib/core/models/slot_model.dart` — confirma campo `isActive` (Q-2 resolved)
- `firestore.rules` — estrutura atual de regras
- `lib/features/admin/ui/admin_screen.dart` — ponto de provisão do cubit
- `.planning/phases/21-backend-do-dashboard/21-CONTEXT.md` — todas as decisões D-01..D-16 (Q-1 e Q-2 resolved)
- `.planning/STATE.md` — decisões arquiteturais v5.0

### Secondary (MEDIUM confidence)
- [firebase.google.com/docs/functions/schedule-functions](https://firebase.google.com/docs/functions/schedule-functions) — `onSchedule` v2 string formats
- [firebase.google.com/docs/reference/functions/2nd-gen/node/firebase-functions.scheduler.scheduleoptions](https://firebase.google.com/docs/reference/functions/2nd-gen/node/firebase-functions.scheduler.scheduleoptions) — `ScheduleOptions.timeZone` field

### Tertiary (LOW confidence)
- Nenhum item de confiança baixa nesta pesquisa.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — tudo verificado no codebase existente
- Architecture: HIGH — todos os padrões têm análogos diretos no projeto
- Pitfalls: HIGH — baseados em comportamento documentado do Firestore (batch.update em doc inexistente) e análise do codebase
- Open questions: 0 itens pendentes — Q-1 e Q-2 RESOLVED via CONTEXT.md

**Research date:** 2026-05-20
**Last revised:** 2026-05-20 (revision iteration 1 — closed Q-1 and Q-2 with citations to CONTEXT.md)
**Valid until:** 2026-06-20 (firebase-functions v2 API estável)

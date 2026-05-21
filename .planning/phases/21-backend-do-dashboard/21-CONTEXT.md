# Phase 21: Backend do Dashboard - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Entrega o backend completo de agregação do dashboard: Cloud Functions que mantêm contadores em `/config/dashboard/{period}` e `DashboardCubit` Flutter que lê esses dados. Fase 22 consome este backend para renderizar gráficos e métricas na UI.

</domain>

<decisions>
## Implementation Decisions

### Schema dos Documentos de Dashboard
- **D-01:** Rolling window — 3 docs fixos: `/config/dashboard/week`, `/config/dashboard/month`, `/config/dashboard/year`. Representam sempre o período atual (semana civil corrente, mês corrente, ano corrente). `scheduledDailyAggregation` sobrescreve esses docs diariamente.
- **D-02:** "Semana atual" = Seg–Dom da semana civil corrente (não janela de 7 dias móvel). Ex: se hoje é quinta 22/mai, semana = seg 19/mai a dom 25/mai.
- **D-03:** Cada doc contém todos os campos necessários para as métricas do período (ver Estrutura dos Campos abaixo).

### Denominador da Taxa de Ocupação (DASH-01)
- **D-04:** CF conta `/slots` onde `active == true` para calcular o total de slots disponíveis do período. Query executada a cada disparo do `onBookingStateChange` — pequena mas precisa.
- **D-05:** `occupancyRate = totalSlotsBooked / totalSlotsAvailable` (valor entre 0–1, representado como percentual na UI).

### Atualização de Métricas
- **D-06:** `onBookingStateChange` atualiza apenas contadores simples via increment/decrement atômico: `totalBookings`, `confirmedBookings`, `cancelledBookings`, `pendingBookings`, `totalRevenue`, `pixRevenue`, `onArrivalRevenue`, `totalSlotsBooked`.
- **D-07:** Métricas complexas ficam exclusivamente no `scheduledDailyAggregation`: top 5 clientes, taxa de retorno, clientes únicos/novos, receita por esporte, no-show rate, taxa de conversão. Aceitável défasagem D+1 para essas métricas.
- **D-08:** `scheduledDailyAggregation` roda às 03:00 AM America/Sao_Paulo. Recalcula todos os campos dos 3 docs (week/month/year) do zero, garantindo consistência.

### Definições de Métricas
- **D-09:** "Novo cliente" = userId cuja primeira reserva `confirmed` ever foi nesse período. Calculado buscando MIN(createdAt) do userId nos bookings históricos.
- **D-10:** Taxa de conversão (DASH-03) = todos os bookings confirmados / todos os bookings criados no período. On_arrival confirmadas contam como 100% convertidas — não excluir.
- **D-11:** No-show rate (DASH-04) = bookings com paymentMethod `on_arrival` que não foram confirmados (status `cancelled` ou `rejected`) / total on_arrival criados.
- **D-12:** Top 5 clientes (DASH-10): CF desnormaliza `{userId, displayName, bookingCount}` no array `topClients` do doc de dashboard. Lê `users/{id}.displayName` na hora do scheduled.

### Estrutura dos Campos do Documento de Dashboard
Cada doc em `/config/dashboard/{period}` contém:
```
{
  period: 'week' | 'month' | 'year',
  startDate: 'YYYY-MM-DD',
  endDate: 'YYYY-MM-DD',
  updatedAt: Timestamp,

  // Contadores simples (atualizados por onBookingStateChange)
  totalBookings: int,
  confirmedBookings: int,
  cancelledBookings: int,
  pendingBookings: int,
  totalSlotsBooked: int,
  totalRevenue: double,       // soma de bookings confirmed
  pixRevenue: double,
  onArrivalRevenue: double,

  // Calculado no scheduled
  totalSlotsAvailable: int,   // contagem de /slots active==true no período
  occupancyRate: double,      // totalSlotsBooked / totalSlotsAvailable
  avgTicket: double,          // totalRevenue / confirmedBookings
  conversionRate: double,     // confirmedBookings / totalBookings
  noShowRate: double,         // on_arrival não confirmados / total on_arrival
  uniqueClients: int,
  newClients: int,
  returnRate: double,         // % clientes com >1 booking no período
  topClients: [{userId, displayName, bookingCount}],  // top 5
  revenueBySport: [{sport, revenue}],                 // DASH-12
}
```

### DashboardCubit
- **D-13:** `DashboardCubit` usa `StreamSubscription` em `/config/dashboard` collection (igual ao `PricingCubit` em `/config/pricing`) — atualiza em tempo real quando `onBookingStateChange` escreve.
- **D-14:** Estado: `DashboardLoading`, `DashboardLoaded(week, month, year)`, `DashboardError`. Todos os 3 docs são carregados de uma vez; a UI seleciona qual exibir via toggle.
- **D-15:** `DashboardCubit` provisionado em `AdminScreen` (igual ao padrão do `SportConfigCubit`).

### Regras Firestore
- **D-16:** `/config/dashboard` read restrito a admin; escrita bloqueada para cliente Flutter (apenas CFs escrevem via `admin.firestore()`). Regra específica sobrepõe o wildcard `/config/{docId}`.

### Claude's Discretion
- Lógica de increment/decrement no `onBookingStateChange` — quais transições de status disparam increment vs. decrement
- Estrutura da query para contar `/slots` ativos por período (consultar padrão do `updateSlotPricesFromTiers`)
- Tratamento de falha no `scheduledDailyAggregation` — log via `console.error`, Sentry já captura via runtime
- `DashboardData` model Dart com campos nullables para retrocompatibilidade caso doc não exista

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` §Phase 21 — Goal, success criteria, dependencies
- `.planning/REQUIREMENTS.md` §Dashboard — Contadores e Métricas (DASH-01..04, DASH-09..12)

### Cloud Functions — Patterns
- `functions/index.js:39` — `notifyAdminNewBooking`: padrão de `onDocumentWritten` em `/bookings/{bookingId}` — modelo direto para `onBookingStateChange`
- `functions/index.js:505` — `expireUnpaidBookings`: padrão de `onSchedule` com fuso horário — modelo para `scheduledDailyAggregation`
- `functions/index.js:716` — `updateSlotPricesFromTiers`: padrão de query em `/slots` — modelo para contar slots ativos

### Cubit Patterns
- `lib/features/admin/cubit/pricing_cubit.dart` — Padrão de `StreamSubscription` em `/config/pricing`; modelo direto para `DashboardCubit`
- `lib/features/admin/cubit/sport_config_cubit.dart` — Implementação mais recente do mesmo padrão (Phase 20)

### Firestore Rules
- `firestore.rules` — Regra atual `/config/{docId}`: read if isAuthenticated(). Nova regra `/config/dashboard/{period}` deve restringir a isAdmin()

### Admin Screen (provisão do cubit)
- `lib/features/admin/ui/admin_screen.dart` — Entry point do admin; onde `DashboardCubit` deve ser provisionado (igual ao `SportConfigCubit` da Phase 20)

### Architecture Decision
- `.planning/ARCHITECTURE.md` (se existir) §v5.0 Decisions — "Firestore aggregation queries NÃO suportam real-time listeners — usar write-time counters via Cloud Functions"

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `onDocumentWritten('bookings/{bookingId}', ...)`: trigger pattern já estabelecido — `onBookingStateChange` usa o mesmo hook
- `onSchedule('every 15 minutes', ...)` em `expireUnpaidBookings`: padrão de scheduled com region e fuso — adaptar para `every day 03:00` com timezone `America/Sao_Paulo`
- `PricingCubit._startStream()` / `SportConfigCubit._startStream()`: padrão de StreamSubscription em coleção `/config/` — DashboardCubit replica este padrão
- `SnackHelper.success/error`: feedback visual existente (não usado no dashboard diretamente mas disponível)

### Established Patterns
- `admin.firestore().collection('config').doc('mercadopago')`: padrão de leitura de config nas CFs — adaptar para `/config/dashboard/{period}`
- Batch writes com `db.batch()`: já usado em `expireUnpaidBookings` para múltiplos updates atômicos — usar em `onBookingStateChange` para garantir atomicidade
- `console.error()` + Sentry runtime capture: padrão de error logging nas CFs

### Integration Points
- `functions/index.js`: novos exports `onBookingStateChange` e `scheduledDailyAggregation` adicionados ao final
- `lib/features/admin/ui/admin_screen.dart`: `MultiBlocProvider` recebe `DashboardCubit` (igual à adição do `SportConfigCubit` na Phase 20)
- `firestore.rules`: adição de bloco específico para `/config/dashboard/{period}` antes do wildcard `/config/{docId}`

</code_context>

<specifics>
## Specific Ideas

- `onBookingStateChange` deve checar `before.status` vs `after.status` para decidir se é increment ou decrement — igual ao padrão do `notifyAdminNewBooking` que compara `before?.status` com `after.status`
- Para o período `week`: calcular `startDate = segunda-feira da semana ISO corrente`, `endDate = domingo da mesma semana`
- Para `revenueBySport` (DASH-12): sport pode ser null em reservas antigas — agrupar nulls como "Não informado" ou excluir do cálculo

</specifics>

<deferred>
## Deferred Ideas

- Histórico de períodos anteriores (ex: comparar semana atual vs. semana passada) — seria útil para tendências, mas adiciona complexidade de storage; considerar para v6+
- Export de relatório em CSV/PDF — out of scope do milestone v5.0

</deferred>

---

*Phase: 21-backend-do-dashboard*
*Context gathered: 2026-05-20*

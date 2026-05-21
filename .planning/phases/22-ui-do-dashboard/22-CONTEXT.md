# Phase 22: UI do Dashboard - Context

**Gathered:** 2026-05-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Entrega a aba Dashboard na tela Admin: toggle de período (Semana/Mês/Ano) + cards de KPIs + 4 visualizações gráficas (DASH-05..08). Consome `DashboardCubit` e `DashboardData` prontos da Phase 21. Não modifica backend nem Cloud Functions.

</domain>

<decisions>
## Implementation Decisions

### Tab e Estrutura no AdminScreen
- **D-01:** Dashboard é a **primeira aba** (index 0) no TabBar do `AdminScreen`. `_reservasTabIndex` muda de 2 para 3. Label: "Dashboard".
- **D-02:** Toda a DashboardTab em uma única aba — cards de KPIs e gráficos juntos no mesmo scroll. Sem sub-tabs.

### Toggle de Período
- **D-03:** `SegmentedButton<String>` nativo Material 3 com 3 segmentos: "Semana" | "Mês" | "Ano". Nenhum package extra.
- **D-04:** Toggle **fixo no topo** da aba (fora do scroll). Estrutura: `Column` → toggle + divider + `Expanded(SingleChildScrollView(...))`.
- **D-05:** Timestamp "Última atualização: HH:MM" exibido discretamente abaixo do SegmentedButton, usando `DashboardData.updatedAt` do período selecionado. Mostra "--" quando `updatedAt` é null.

### Gráfico de Receita (DASH-05)
- **D-06:** Implementado como **BarChart** (fl_chart). DASH-05 diz "linha ou barra" — serie temporal diária não disponível no `DashboardData`, então: barras de split de pagamento.
- **D-07:** 3 barras: **Total** (`totalRevenue`), **Pix** (`pixRevenue`), **Presencial** (`onArrivalRevenue`).
- **D-08:** Legenda abaixo do gráfico (padrão fl_chart `FlTitlesData`).

### Layout e Scroll
- **D-09:** Ordem de scroll (topo → fundo): Cards KPIs → Receita (BarChart) → Heatmap hora×dia → Pizza status → Donut esporte.
- **D-10:** Cada gráfico envolto em `Card` Flutter com `Text` de título acima. Consistente com os outros tabs do admin.
- **D-11:** Cards de KPIs em `GridView` 2 colunas (5 métricas: ocupação, receita, ticket médio, conversão, no-show). Cada card: rótulo pequeno + valor grande + unidade.
- **D-12:** Gráficos de barra/pizza/donut: altura via `AspectRatio(aspectRatio: 16/9)`.
- **D-13:** Donut de esporte (DASH-08) é condicional — exibe card com mensagem **"Nenhum dado de esporte ainda"** quando `revenueBySport` é null ou lista vazia. Card sempre visível (não some).

### Packages (novos — não estão no pubspec.yaml)
- **D-14:** Adicionar `fl_chart` ao `pubspec.yaml` — gráfico de barras (DASH-05), pizza (DASH-07) e donut (DASH-08).
- **D-15:** Adicionar `flutter_heatmap_calendar` ao `pubspec.yaml` — heatmap hora×dia (DASH-06).

### Estados Vazios e Erros
- **D-16:** Métricas calculadas null (D+1 delay do scheduled): exibir **"--"** no card de KPI, sem spinner extra.
- **D-17:** `DashboardLoading`: `CircularProgressIndicator` centralizado na aba. Padrão do app.
- **D-18:** `DashboardError`: `SnackBar` de erro com botão **"Tentar Novamente"** que chama `context.read<DashboardCubit>().retry()` (ou reconstrói o cubit).

### Claude's Discretion
- Estrutura interna de `DashboardTab` (StatefulWidget vs StatelessWidget com BlocBuilder)
- Seleção de período: state local (`selectedPeriod`) dentro de `DashboardTab` — não precisa ir ao Cubit
- Cores das barras do fl_chart (usar `AppTheme.primaryGreen` + variações)
- Heatmap: configuração de `HeatMapCalendar` ou `HeatMapWidget` do flutter_heatmap_calendar — dados de hora×dia precisam ser derivados de `totalSlotsBooked` agrupado por hora (se disponível) ou simulado com dados do período
- Formatação de valores monetários (intl `NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')`)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` §Phase 22 — Goal, success criteria, requirements DASH-05..08
- `.planning/REQUIREMENTS.md` §Dashboard — Visualizações — Definições exatas de DASH-05..08

### Backend Phase 21 (dados disponíveis)
- `.planning/phases/21-backend-do-dashboard/21-CONTEXT.md` — Schema completo de `DashboardData`, decisões de arquitetura (D-01..D-16), campos disponíveis vs calculados D+1

### DashboardCubit e Model
- `lib/core/models/dashboard_data.dart` — Campos disponíveis, quais são nullable (D+1), estrutura de `TopClientEntry` e `RevenueBySportEntry`
- `lib/features/admin/cubit/dashboard_cubit.dart` — Stream em `/config/dashboard/periods`, estados emitidos
- `lib/features/admin/cubit/dashboard_state.dart` — `DashboardLoading`, `DashboardLoaded`, `DashboardError`

### AdminScreen (ponto de integração)
- `lib/features/admin/ui/admin_screen.dart` — `DashboardCubit` já provisionado (linha 76); TabBar com 6 abas; `_reservasTabIndex = 2` deve mudar para 3 após inserir Dashboard como índice 0

### Architecture Decision (v5.0)
- `.planning/STATE.md` §v5.0 Architecture — "fl_chart para gráficos; flutter_heatmap_calendar para heatmap hora×dia"

### Packages a adicionar
- `pubspec.yaml` — fl_chart e flutter_heatmap_calendar **não estão instalados** — Phase 22 deve adicioná-los

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `DashboardCubit` já provisionado em `admin_screen.dart:76` via `BlocProvider` — DashboardTab acessa via `context.read<DashboardCubit>()`
- `AppTheme.primaryGreen`: cor primária do app — usar nas barras do fl_chart
- `SnackHelper.success/error` (se existir): padrão de feedback visual do app
- `intl` package: já no pubspec — usar `NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')` para formatar receita

### Established Patterns
- `BlocBuilder<XCubit, XState>` com switch de estados `Loading/Loaded/Error` — replicar em `DashboardTab`
- Tabs existentes (ex: `BookingManagementTab`) como referência de estrutura de widget
- `Card` widget com `Padding` interno: padrão dos outros tabs do admin

### Integration Points
- `admin_screen.dart`: TabController `length` passa de 6 para 7; Tab "Dashboard" inserida como índice 0; `_reservasTabIndex` incrementa de 2 para 3
- TabBarView: `DashboardTab()` adicionado como primeiro filho
- `DashboardCubit` já no BlocProvider — sem alteração necessária

</code_context>

<specifics>
## Specific Ideas

- Toggle de período: `SegmentedButton<String>` com `segments: [ButtonSegment(value: 'week', label: Text('Semana')), ...]`
- Timestamp: `Text('Última atualização: ${_formatTime(data.updatedAt)}', style: TextStyle(fontSize: 11, color: Colors.grey))` — abaixo do SegmentedButton, alinhado à direita
- BarChart DASH-05: eixo X com labels "Total", "Pix", "Presencial"; eixo Y em R$
- Donut DASH-08 quando sem dados: `Center(child: Text('Nenhum dado de esporte ainda', style: TextStyle(color: Colors.grey)))` dentro do Card

</specifics>

<deferred>
## Deferred Ideas

- Série temporal diária de receita (linha de evolução real) — requer campo `dailyRevenue[]` no backend; considerar v6+
- Export CSV/PDF do dashboard — DASH-F01, out of scope v5.0
- Atualização em tempo real via FCM — DASH-F02, out of scope v5.0
- Filtros avançados por esporte/cliente — DASH-F03, out of scope v5.0

</deferred>

---

*Phase: 22-ui-do-dashboard*
*Context gathered: 2026-05-21*

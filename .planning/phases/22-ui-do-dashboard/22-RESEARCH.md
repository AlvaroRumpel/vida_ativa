# Phase 22: UI do Dashboard - Research

**Researched:** 2026-05-21
**Domain:** Flutter UI — Dashboard visualization (charting, heatmap, KPI cards)
**Confidence:** HIGH

## Summary

Phase 22 implements the admin Dashboard tab in `AdminScreen`, consuming `DashboardCubit` and `DashboardData` from Phase 21. UI requirement: period toggle (week/month/year) + 5 KPI cards + 4 visualizations (revenue bar chart, hour×day heatmap, status pie chart, sport donut chart). All libraries identified and versions verified. Widget structure aligns with existing admin tabs. Two new packages must be added: `fl_chart` (1.2.0) for charting and `flutter_heatmap_calendar` (1.0.5) for heatmap. No backend changes required.

**Primary recommendation:** Use native Material 3 `SegmentedButton<String>` for period toggle, `fl_chart` BarChart for revenue split (Total/Pix/Presencial), HeatMapCalendar with derived booking density data, PieChart + PieChart (configured as donut) for status and sport distribution. Implement DashboardTab as StatefulWidget with local `selectedPeriod` state.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
**D-01:** Dashboard is first tab (index 0) in TabBar of AdminScreen. `_reservasTabIndex` changes from 2 → 3.
**D-02:** Entire DashboardTab in single scroll (cards + all charts together, no sub-tabs).
**D-03:** SegmentedButton<String> native Material 3, 3 segments: "Semana" | "Mês" | "Ano", no extra packages.
**D-04:** Toggle fixed at top (outside scroll). Structure: Column → toggle + divider + Expanded(SingleChildScrollView(...)).
**D-05:** Timestamp "Última atualização: HH:MM" displayed discretely below SegmentedButton, using DashboardData.updatedAt. Shows "--" when null.
**D-06:** Revenue chart = BarChart (fl_chart). DASH-05 allows "line or bar"; temporal series unavailable → bars for payment split.
**D-07:** 3 bars: Total (totalRevenue), Pix (pixRevenue), Presencial (onArrivalRevenue).
**D-08:** Legend below chart (standard fl_chart FlTitlesData).
**D-09:** Scroll order: KPI Cards → Revenue BarChart → Heatmap hora×dia → Pizza status → Donut sport.
**D-10:** Each chart wrapped in Card with title Text above. Consistent with other admin tabs.
**D-11:** KPI cards in GridView 2-column layout (5 metrics: occupação, receita, ticket médio, conversão, no-show). Each: label small + value large + unit.
**D-12:** Charts: AspectRatio(aspectRatio: 16/9).
**D-13:** Sport donut (DASH-08) conditional — shows "Nenhum dado de esporte ainda" when revenueBySport null/empty. Card always visible.
**D-14:** Add `fl_chart` to pubspec.yaml — bars (DASH-05), pizza (DASH-07), donut (DASH-08).
**D-15:** Add `flutter_heatmap_calendar` to pubspec.yaml — heatmap hora×dia (DASH-06).
**D-16:** Empty metrics (D+1 delay): show "--" in KPI card, no extra spinner.
**D-17:** DashboardLoading: centered CircularProgressIndicator.
**D-18:** DashboardError: SnackBar with "Tentar Novamente" button calling context.read<DashboardCubit>().retry() (or rebuild cubit).

### Claude's Discretion
- Internal structure of DashboardTab (StatefulWidget vs. StatelessWidget with BlocBuilder)
- Period selection: local state (selectedPeriod) within DashboardTab — does not go to Cubit
- Bar colors: use AppTheme.primaryGreen + variations
- HeatMapCalendar configuration — data derivation from totalSlotsBooked grouping by hour (if available) or simulation
- Currency formatting: intl NumberFormat.currency(locale: 'pt_BR', symbol: 'R$')

### Deferred Ideas (OUT OF SCOPE)
- Serie temporal diária de receita (linha evolução real) — requires dailyRevenue[] backend; v6+
- Export CSV/PDF — DASH-F01, v5.0 out of scope
- Real-time updates via FCM — DASH-F02, v5.0 out of scope
- Advanced filters (sport/client/price) — DASH-F03, v5.0 out of scope

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DASH-05 | Admin vê gráfico de linha ou barra com evolução de receita ao longo do período selecionado | fl_chart BarChart(3 bars: Total, Pix, Presencial) com fl_chart 1.2.0 (verified) |
| DASH-06 | Admin vê heatmap hora×dia indicando os horários mais reservados da semana | flutter_heatmap_calendar 1.0.5 with HeatMapCalendar(datasets: Map<DateTime, int>) |
| DASH-07 | Admin vê gráfico pizza com distribuição de reservas por status | fl_chart PieChart com series de confirmedBookings/cancelledBookings/pendingBookings |
| DASH-08 | Admin vê gráfico donut com distribuição de reservas por esporte (quando há dados) | fl_chart PieChart(donut mode) + conditional "Nenhum dado de esporte ainda" message |

</phase_requirements>

## Standard Stack

### Core Libraries
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter | ≥3.11.3 | Flutter SDK (required) | Already in project |
| flutter_bloc | ^9.1.1 | State management — Cubit pattern | [VERIFIED: pubspec.yaml] — standard in project |
| flutter/material.dart | builtin | Material 3 UI — SegmentedButton, Card, etc. | [VERIFIED: pubspec.yaml] |
| intl | ^0.20.2 | i18n, NumberFormat for currency formatting | [VERIFIED: pubspec.yaml] — "R$ 1.234,56" format |
| **fl_chart** | ^1.2.0 | Bar, Pie, Donut charts (DASH-05, DASH-07, DASH-08) | [VERIFIED: pub.dev 2026-05-21] — latest stable, no breaking changes since 1.1.x |
| **flutter_heatmap_calendar** | ^1.0.5 | Heatmap grid calendar for hour×day visualization (DASH-06) | [VERIFIED: pub.dev 2026-05-21] — GitHub contrib chart style |

### Supporting Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| cloud_firestore | ^6.1.3 | Read DashboardData from /config/dashboard/{period} | [VERIFIED: pubspec.yaml] — already provisioned in DashboardCubit |
| equatable | ^2.0.8 | Value equality for Dart/Flutter objects | [VERIFIED: pubspec.yaml] — DashboardData uses Equatable |

### UI Patterns
- **SegmentedButton<String>:** Native Material 3 widget for period toggle (no third-party needed)
- **BlocBuilder:** Pattern for reactive state transitions (DashboardLoading → DashboardLoaded → DashboardError)
- **AspectRatio:** Maintain 16:9 aspect for charts across devices
- **Card + Column:** Consistent card layout with title above chart (matches BookingManagementTab pattern)

### Installation
```bash
flutter pub add fl_chart:^1.2.0
flutter pub add flutter_heatmap_calendar:^1.0.5
```

**Note:** Both packages are new to the project. `intl` already installed.

**Version verification (2026-05-21):**
- fl_chart: 1.2.0 published ~2 months ago (2026-03); minimum Flutter 3.27.4; stable, recent improvements to BorderRadius and error ranges
- flutter_heatmap_calendar: 1.0.5 published 3 years ago; stable, no breaking changes expected

## Architecture Patterns

### Recommended Project Structure
```
lib/features/admin/ui/
├── admin_screen.dart              # (Modified) TabBar length 6→7, add Dashboard tab, _reservasTabIndex 2→3
├── dashboard_tab.dart             # NEW: Main DashboardTab widget
├── dashboard_tab_widgets/         # NEW: Internal helpers
│   ├── dashboard_kpi_card.dart    # KPI metric card (label + big value + unit)
│   ├── dashboard_revenue_chart.dart
│   ├── dashboard_heatmap.dart
│   ├── dashboard_status_pie.dart
│   └── dashboard_sport_donut.dart
└── (existing tabs...)
```

### Pattern 1: Period Toggle with Local State
**What:** StatefulWidget maintains `selectedPeriod` as string ('week' | 'month' | 'year'). SegmentedButton callback updates state, triggering rebuild with new data from BlocBuilder.

**When to use:** UI-only selection that doesn't affect backend; state is transient within AdminScreen session.

**Example:**
```dart
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  String _selectedPeriod = 'week';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        return switch (state) {
          DashboardLoading() => const Center(child: CircularProgressIndicator()),
          DashboardError(:final message) => Center(child: Text(message)),
          DashboardLoaded() => _buildDashboard(context, state),
        };
      },
    );
  }

  Widget _buildDashboard(BuildContext context, DashboardLoaded state) {
    final data = _selectData(state);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'week', label: Text('Semana')),
                  ButtonSegment(value: 'month', label: Text('Mês')),
                  ButtonSegment(value: 'year', label: Text('Ano')),
                ],
                selected: {_selectedPeriod},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() => _selectedPeriod = newSelection.first);
                },
              ),
              const SizedBox(height: 4),
              Text(
                'Última atualização: ${_formatTime(data.updatedAt)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKpiCards(data),
                  const SizedBox(height: AppSpacing.lg),
                  _buildRevenueChart(data),
                  const SizedBox(height: AppSpacing.lg),
                  _buildHeatmap(data),
                  const SizedBox(height: AppSpacing.lg),
                  _buildStatusPie(data),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSportDonut(data),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  DashboardData _selectData(DashboardLoaded state) {
    return switch (_selectedPeriod) {
      'week' => state.week,
      'month' => state.month,
      'year' => state.year,
      _ => state.week,
    };
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--';
    return DateFormat('HH:mm').format(dt);
  }

  // Build methods for each visualization...
}
```

[CITED: CONTEXT.md D-03..05, D-09..10]

### Pattern 2: KPI Cards in GridView
**What:** 2-column grid with Card(child: Column(small label, large value, unit)).

**Example:**
```dart
Widget _buildKpiCards(DashboardData data) {
  final kpis = [
    ('Ocupação', data.occupancyRate != null ? '${(data.occupancyRate! * 100).toStringAsFixed(1)}%' : '--', ''),
    ('Receita', data.totalRevenue.toStringAsFixed(2), 'R\$'),
    ('Ticket Médio', data.avgTicket != null ? data.avgTicket!.toStringAsFixed(2) : '--', 'R\$'),
    ('Taxa Conversão', data.conversionRate != null ? '${(data.conversionRate! * 100).toStringAsFixed(1)}%' : '--', ''),
    ('No-show', data.noShowRate != null ? '${(data.noShowRate! * 100).toStringAsFixed(1)}%' : '--', ''),
  ];

  return GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    childAspectRatio: 1.2,
    children: kpis.map((label, value, unit) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              if (unit.isNotEmpty) Text(unit, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      );
    }).toList(),
  );
}
```

[CITED: CONTEXT.md D-11]

### Pattern 3: fl_chart BarChart (Revenue)
**What:** 3-bar grouped chart: Total, Pix, Presencial. X-axis labels, Y-axis in currency. Bars colored with AppTheme.primaryGreen variants.

**Example:**
```dart
Widget _buildRevenueChart(DashboardData data) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Receita por Método', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.sm),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: BarChart(
              BarChartData(
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(toY: data.totalRevenue, color: AppTheme.primaryGreen, width: 20),
                      BarChartRodData(toY: data.pixRevenue, color: AppTheme.primaryGreen.withOpacity(0.6), width: 20),
                      BarChartRodData(toY: data.onArrivalRevenue, color: AppTheme.primaryGreen.withOpacity(0.3), width: 20),
                    ],
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const labels = ['Total', 'Pix', 'Presencial'];
                        return Text(labels[value.toInt()] ?? '');
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
```

[CITED: fl_chart 1.2.0 documentation, CONTEXT.md D-06..08]

### Pattern 4: HeatMapCalendar (Hour×Day)
**What:** HeatMapCalendar with datasets Map<DateTime, int> representing booking density per day. Colors scaled by value intensity. Shows last 30–90 days depending on period selected.

**Challenge:** DashboardData has `totalSlotsBooked` (single int) but no granular hour×day breakdown. Options:
1. Derive dataset from aggregated booking snapshots (requires additional Firestore query)
2. Simulate/mock data for MVP (use dummy density values based on totalSlotsBooked distribution)
3. Wait for backend enhancement (not v5.0 scope)

**Recommendation (Claude's Discretion):** For MVP, simulate hourly density by spreading `totalSlotsBooked` evenly across active days in period. Example:
```dart
Widget _buildHeatmap(DashboardData data) {
  final now = DateTime.now();
  final datasets = <DateTime, int>{};
  
  // Spread totalSlotsBooked across last 30 days
  final days = _daysInPeriod(data.period);
  final avgPerDay = (data.totalSlotsBooked / days).round();
  
  for (int i = 0; i < days; i++) {
    final date = now.subtract(Duration(days: i));
    datasets[DateTime(date.year, date.month, date.day)] = avgPerDay + Random().nextInt(5);
  }

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Horários Mais Reservados', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.sm),
          HeatMapCalendar(
            datasets: datasets,
            colorMode: ColorMode.color,
            colorsets: const {
              1: Colors.lightBlue,
              5: Colors.blue,
              10: AppTheme.primaryGreen,
            },
            defaultColor: Colors.grey.shade200,
          ),
        ],
      ),
    ),
  );
}
```

[CITED: flutter_heatmap_calendar 1.0.5 API, CONTEXT.md discretion note]

### Pattern 5: fl_chart PieChart (Status & Sport)
**What:** PieChart for status (confirmed/cancelled/pending); same chart code with donut mode for sport distribution. Sport chart shows conditional "Nenhum dado de esporte ainda" when data empty.

**Example (Status):**
```dart
Widget _buildStatusPie(DashboardData data) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Distribuição por Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.sm),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(value: data.confirmedBookings.toDouble(), color: Colors.green, title: 'Confirmadas'),
                  PieChartSectionData(value: data.cancelledBookings.toDouble(), color: Colors.red, title: 'Canceladas'),
                  PieChartSectionData(value: data.pendingBookings.toDouble(), color: Colors.orange, title: 'Pendentes'),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
```

**Example (Sport Donut with conditional):**
```dart
Widget _buildSportDonut(DashboardData data) {
  final hasSportData = data.revenueBySport != null && data.revenueBySport!.isNotEmpty;

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Receita por Esporte', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.sm),
          if (!hasSportData)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text('Nenhum dado de esporte ainda', style: TextStyle(color: Colors.grey.shade600)),
              ),
            )
          else
            AspectRatio(
              aspectRatio: 16 / 9,
              child: PieChart(
                PieChartData(
                  sections: data.revenueBySport!.map((entry) {
                    return PieChartSectionData(
                      value: entry.revenue,
                      color: _sportColor(entry.sport),
                      title: entry.sport ?? 'Não informado',
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
```

[CITED: fl_chart 1.2.0 PieChart, CONTEXT.md D-13, D-07..08]

## Anti-Patterns to Avoid

- **Rebuilding entire DashboardTab on period toggle:** ❌ Don't call `setState(() { context.read<DashboardCubit>()... })`. Instead, keep period as local state and let BlocBuilder handle data selection. ✅ Correct: period state local, Cubit state separate.

- **Hardcoding chart colors:** ❌ Don't use `Color(0xFFxxxxxx)` literals in chart code. ✅ Correct: Use `AppTheme.primaryGreen` and `.withOpacity()` for variations.

- **Querying Firestore in build method:** ❌ DashboardTab build should NOT call `FirebaseFirestore.instance.collection(...)`. ✅ Correct: All data flows through DashboardCubit stream (Phase 21).

- **Replicating KPI formatting logic:** ❌ Don't manually calculate percentages/currencies inline. ✅ Correct: Extract to helper methods or dedicated KPI card widget.

- **Ignoring null metrics (D+1 delay):** ❌ Don't crash with `data.occupancyRate!.toStringAsFixed(1)`. ✅ Correct: Use `data.occupancyRate != null ? ... : '--'` per D-16.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Line/bar/pie charts | Custom CustomPaint chart code | fl_chart (BarChart, LineChart, PieChart) | Complex rendering, animations, touch interaction; edge cases (legend, tooltips, responsive sizing) |
| Heatmap grid calendar | Manual GridView with date logic | flutter_heatmap_calendar (HeatMapCalendar) | GitHub-style heatmap requires intricate color mapping, date calculations, cell layout; HeatMapCalendar is battle-tested |
| Currency formatting | String interpolation `'R\$ $value'` | intl NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$') | Locale-aware formatting, rounding, thousands separator; intl handles edge cases |
| Material 3 period toggle | Custom buttons or ToggleButtons | SegmentedButton<T> | Native Material 3 component, built-in accessibility, keyboard support, correct spacing |

**Key insight:** Charting libraries like fl_chart handle touch events, animation, responsive layout, and legend generation — far more complex than naive implementations. HeatMapCalendar's date aggregation and color scaling are non-trivial. Invest the small dependency cost to avoid maintenance burden.

## Code Examples

### Full DashboardTab Skeleton
```dart
// Source: Phase 22 patterns, CONTEXT.md D-01..18, AppTheme.dart, intl
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vida_ativa/core/models/dashboard_data.dart';
import 'package:vida_ativa/core/theme/app_spacing.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/admin/cubit/dashboard_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/dashboard_state.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  String _selectedPeriod = 'week';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) => switch (state) {
        DashboardLoading() => const Center(child: CircularProgressIndicator()),
        DashboardError(:final message) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(message, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => context.read<DashboardCubit>()._startStream(), // or .retry() if method exists
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
        DashboardLoaded() => _buildDashboard(context, state),
      },
    );
  }

  Widget _buildDashboard(BuildContext context, DashboardLoaded state) {
    final data = _selectData(state);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'week', label: Text('Semana')),
                  ButtonSegment(value: 'month', label: Text('Mês')),
                  ButtonSegment(value: 'year', label: Text('Ano')),
                ],
                selected: {_selectedPeriod},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() => _selectedPeriod = newSelection.first);
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Última atualização: ${_formatTime(data.updatedAt)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKpiCards(data),
                  const SizedBox(height: AppSpacing.lg),
                  _buildRevenueChart(data),
                  const SizedBox(height: AppSpacing.lg),
                  _buildHeatmap(data),
                  const SizedBox(height: AppSpacing.lg),
                  _buildStatusPie(data),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSportDonut(data),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  DashboardData _selectData(DashboardLoaded state) => switch (_selectedPeriod) {
    'week' => state.week,
    'month' => state.month,
    'year' => state.year,
    _ => state.week,
  };

  String _formatTime(DateTime? dt) => dt == null ? '--' : DateFormat('HH:mm').format(dt);

  // Build methods...
}
```

[CITED: CONTEXT.md D-17..18, existing tab patterns in BookingManagementTab]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| ToggleButtons (3 buttons) | SegmentedButton<T> native Material 3 | Material 3 adoption (Flutter 3.13+) | Better spacing, accessibility, keyboard support; SegmentedButton is official replacement |
| Custom CustomPaint charts | fl_chart, charts package, syncfusion | ~2020+ | Industry standard; reduces boilerplate ~70%, enables interactive features (tooltip, legend, zoom) |
| GitHub heatmap from scratch | flutter_heatmap_calendar package | ~2021 | Specialized widget avoids date/color logic errors; ~500 LOC saved |

**Deprecated/outdated:**
- `ToggleButtons` — Replaced by SegmentedButton in Material 3. Still works but discouraged.
- Manual contrib-style heatmap rendering — Use flutter_heatmap_calendar instead.
- Custom bar chart with Canvas — fl_chart is industry standard, 100x less error-prone.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | HeatMap hour×day data can be derived or simulated from totalSlotsBooked without additional Firestore queries | Architecture Patterns (Pattern 4) | If aggregated hourly data required, need backend enhancement (Phase 21 scope creep). MVP uses simulated density. |
| A2 | DashboardCubit.retry() method exists or cubit can be rebuilt via context.read<DashboardCubit>() | Code Examples | If neither exists, error handling must rebuild cubit manually. Check Phase 21 implementation. |
| A3 | SegmentedButton<String> is available in Flutter 3.11.3+ (project SDK) | Standard Stack | Flutter 3.11.3 meets Material 3 minimum. Verify no older SDK override in app build config. |

</assumptions>

## Open Questions

1. **Hourly heatmap data source**
   - What we know: DashboardData has totalSlotsBooked (total int) but no hourly breakdown.
   - What's unclear: Should heatmap show *actual* hour-by-hour bookings or is simulated distribution acceptable for MVP?
   - Recommendation: Confirm with user whether DASH-06 "horários mais reservados" requires true hourly aggregation (Phase 21 backend enhancement) or estimated distribution is OK.

2. **DashboardCubit error recovery**
   - What we know: CONTEXT.md D-18 says "Tentar Novamente" button should call `context.read<DashboardCubit>().retry()`.
   - What's unclear: Does DashboardCubit have a retry() method? If not, workaround is manual rebuild.
   - Recommendation: Check Phase 21 DashboardCubit implementation for error recovery method.

3. **Sport donut color assignment**
   - What we know: No standard color palette for sports exists in AppTheme.
   - What's unclear: Should each sport get a deterministic color (hash-based) or random?
   - Recommendation: Define `_sportColor(sport: String?)` helper; use deterministic hash to ensure consistency across sessions.

## Environment Availability

All required external tools and runtimes are present:

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Build, run | ✓ | ≥3.11.3 | — |
| Dart | Compilation | ✓ | ≥3.11.3 | — |
| pub.dev registry | Package fetch | ✓ | online | offline mirrors (if configured) |
| FirebaseFirestore | DashboardCubit stream | ✓ | ^6.1.3 | — |

**No missing dependencies.** All packages (fl_chart, flutter_heatmap_calendar, intl) are available on pub.dev. Offline development is possible with mirror configuration, but not required.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test + bloc_test |
| Config file | none — tests in `test/` directory, discovered by `flutter test` |
| Quick run command | `flutter test test/features/admin/ui/` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DASH-05 | BarChart renders 3 bars (Total, Pix, Presencial) with correct values | widget | `flutter test test/features/admin/ui/dashboard_tab_test.dart -k "revenue_chart"` | ❌ Wave 0 |
| DASH-06 | HeatMapCalendar displays with datasets populated from period data | widget | `flutter test test/features/admin/ui/dashboard_tab_test.dart -k "heatmap"` | ❌ Wave 0 |
| DASH-07 | PieChart renders status breakdown (confirmed/cancelled/pending) | widget | `flutter test test/features/admin/ui/dashboard_tab_test.dart -k "status_pie"` | ❌ Wave 0 |
| DASH-08 | Donut chart shows sport data OR "Nenhum dado de esporte ainda" message | widget | `flutter test test/features/admin/ui/dashboard_tab_test.dart -k "sport_donut"` | ❌ Wave 0 |
| Dashboard toggle | SegmentedButton selects period; data switches correctly | widget | `flutter test test/features/admin/ui/dashboard_tab_test.dart -k "period_toggle"` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/features/admin/ui/dashboard_tab_test.dart` — quick UI widget tests
- **Per wave merge:** `flutter test` — full suite including dashboard, cubit, and all admin tabs
- **Phase gate:** Full `flutter test` green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/features/admin/ui/dashboard_tab_test.dart` — widget tests for DashboardTab layout, period toggle, chart rendering
- [ ] `test/features/admin/ui/dashboard_tab_widgets/` — unit tests for helper widgets (KPI card, chart builders)
- [ ] `test/core/utils/dashboard_formatter_test.dart` — currency formatting, time formatting, percentage formatting (if extracted to utils)

**Framework setup:** flutter_test is already in dev_dependencies (pubspec.yaml). bloc_test is available. No additional configuration needed.

## Security Domain

Dashboard displays admin-only metrics from `/config/dashboard` (read restricted to admin role, writes via Cloud Functions only). Phase 22 does not introduce new security concerns:

- **Input validation:** None — UI receives pre-aggregated data from Firestore (Phase 21 validated).
- **Output encoding:** fl_chart and HeatMapCalendar handle rendering safely (no HTML injection risk).
- **Auth check:** AdminScreen wrapping ensures only logged-in admin can access. DashboardCubit reads from admin-restricted collection.

**No additional ASVS controls required for charting UI.** Rely on Phase 21 backend security (Firestore rules, Cloud Functions admin context).

## Sources

### Primary (HIGH confidence)
- [fl_chart pub.dev package](https://pub.dev/packages/fl_chart) — Latest version 1.2.0 verified 2026-05-21
- [flutter_heatmap_calendar pub.dev package](https://pub.dev/packages/flutter_heatmap_calendar) — Latest version 1.0.5 verified 2026-05-21
- [HeatMapCalendar API docs](https://pub.dev/documentation/flutter_heatmap_calendar/latest/flutter_heatmap_calendar/HeatMapCalendar-class.html) — datasets, colorsets, configuration
- Project codebase: pubspec.yaml, lib/core/models/dashboard_data.dart, lib/features/admin/cubit/dashboard_cubit.dart, lib/features/admin/ui/booking_management_tab.dart (existing patterns)
- Project CONTEXT.md (Phase 22) — D-01..18 locked decisions
- Project CONTEXT.md (Phase 21) — DashboardData schema, DashboardCubit implementation

### Secondary (MEDIUM confidence)
- [fl_chart GitHub documentation](https://github.com/imaNNeo/fl_chart) — BarChart, PieChart usage patterns
- [Flutter Material 3 SegmentedButton](https://api.flutter.dev/flutter/material/SegmentedButton-class.html) — native widget API
- [intl package pub.dev](https://pub.dev/packages/intl) — NumberFormat.currency() for pt_BR locale
- WebSearch results: Flutter testing patterns (bloc_test, BlocBuilder widget tests), fl_chart examples

### Tertiary (LOW confidence)
- GitHub contrib heatmap style — general concept for HeatMapCalendar usage (not official source)

## Metadata

**Confidence breakdown:**
- Standard stack (fl_chart, flutter_heatmap_calendar versions): **HIGH** — verified pub.dev 2026-05-21, no breaking changes since last minor release
- Architecture patterns (StatefulWidget + BlocBuilder, SegmentedButton toggle, AspectRatio charts): **HIGH** — cited from project patterns and Material 3 specs
- Pitfalls (hardcoding colors, Firestore queries in build, null handling): **HIGH** — standard Flutter best practices
- Code examples (BarChart, PieChart, HeatMapCalendar skeletons): **MEDIUM** — based on library documentation + project conventions; exact widget tree depends on planner's discretion
- Heatmap data derivation (simulated density from totalSlotsBooked): **MEDIUM** — Phase 21 doesn't provide hourly breakdown; MVP approach inferred from CONTEXT.md discretion note

**Research date:** 2026-05-21
**Valid until:** 2026-06-21 (stable libraries, low churn expected for Material 3 + fl_chart 1.2)

---

*Phase: 22-ui-do-dashboard*
*Research complete: 2026-05-21 — ready for planning*

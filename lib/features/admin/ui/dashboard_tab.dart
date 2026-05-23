import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vida_ativa/core/models/dashboard_data.dart';
import 'package:vida_ativa/core/theme/app_spacing.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/admin/cubit/dashboard_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/dashboard_state.dart';

/// Main dashboard tab for admin panel.
/// Shows KPI cards and chart implementations (Plan 22-03).
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  String _selectedPeriod = 'week';

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DashboardCubit, DashboardState>(
      listener: (context, state) {
        if (state is DashboardError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is DashboardLoading || state is DashboardInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is DashboardError) {
          // SnackBar shown via listener above; show spinner while user decides.
          return const Center(child: CircularProgressIndicator());
        }
        if (state is DashboardLoaded) {
          return _buildDashboard(context, state);
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildDashboard(BuildContext context, DashboardLoaded state) {
    final data = _selectData(state);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
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
                onSelectionChanged: (newSelection) {
                  setState(() => _selectedPeriod = newSelection.first);
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Última atualização: ${_formatTime(data.updatedAt)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKpiGrid(data),
                const SizedBox(height: AppSpacing.lg),
                _buildRevenueChart(data),
                const SizedBox(height: AppSpacing.lg),
                _buildHeatmap(data),
                const SizedBox(height: AppSpacing.lg),
                _buildStatusPie(data),
                const SizedBox(height: AppSpacing.lg),
                _buildSportDonut(data),
                const SizedBox(height: AppSpacing.xl),
              ],
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

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--';
    return DateFormat('HH:mm').format(dt);
  }

  Widget _buildKpiGrid(DashboardData data) {
    final currencyFmt =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final kpis = [
      (
        label: 'Taxa de Ocupação',
        value: data.occupancyRate != null
            ? '${(data.occupancyRate! * 100).toStringAsFixed(1)}%'
            : '--',
        unit: '',
      ),
      (
        label: 'Receita Total',
        value: currencyFmt.format(data.totalRevenue),
        unit: '',
      ),
      (
        label: 'Ticket Médio',
        value: data.avgTicket != null
            ? currencyFmt.format(data.avgTicket!)
            : '--',
        unit: '',
      ),
      (
        label: 'Taxa de Conversão',
        value: data.conversionRate != null
            ? '${(data.conversionRate! * 100).toStringAsFixed(1)}%'
            : '--',
        unit: '',
      ),
      (
        label: 'Taxa de No-Show',
        value: data.noShowRate != null
            ? '${(data.noShowRate! * 100).toStringAsFixed(1)}%'
            : '--',
        unit: '',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.3,
      children: kpis
          .map((kpi) => _buildKpiCard(kpi.label, kpi.value, kpi.unit))
          .toList(),
    );
  }

  Widget _buildKpiCard(String label, String value, String unit) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
            if (unit.isNotEmpty)
              Text(unit,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  // --- Chart implementations (DASH-05 through DASH-08) ---

  Widget _buildRevenueChart(DashboardData data) {
    final barData = [
      ('Total', data.totalRevenue, AppTheme.primaryGreen),
      ('Pix', data.pixRevenue, AppTheme.brandAmber),
      (
        'Presencial',
        data.onArrivalRevenue,
        AppTheme.primaryGreen.withValues(alpha: 0.5)
      ),
    ];

    final maxY = [data.totalRevenue, data.pixRevenue, data.onArrivalRevenue]
        .reduce((a, b) => a > b ? a : b);
    final yInterval = maxY > 0 ? (maxY / 4).ceilToDouble() : 100.0;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Receita',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY > 0 ? maxY * 1.2 : 100,
                  barGroups: List.generate(3, (i) {
                    final item = barData[i];
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: item.$2,
                          color: item.$3,
                          width: 36,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final labels = ['Total', 'Pix', 'Presencial'];
                          final idx = value.toInt();
                          if (idx < 0 || idx >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(labels[idx],
                                style: const TextStyle(fontSize: 12)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 64,
                        interval: yInterval,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text(
                            'R\$ ${value.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(
                      show: true, drawVerticalLine: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmap(DashboardData data) {
    // Per-day occupancy data is not yet available from the backend.
    // Show a placeholder until DashboardData exposes bookingsPerDay.
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ocupação por Hora e Dia',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text('Dados em breve',
                    style:
                        TextStyle(color: Colors.grey[600], fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPie(DashboardData data) {
    final rawExpired = data.totalBookings -
        data.confirmedBookings -
        data.cancelledBookings -
        data.pendingBookings;

    assert(rawExpired >= 0,
        'Dashboard data inconsistency: booking counts exceed totalBookings');

    final expired = rawExpired.clamp(0, data.totalBookings);

    final sections = <_PieSection>[
      _PieSection(
          'Confirmadas', data.confirmedBookings.toDouble(), Colors.green.shade600),
      _PieSection(
          'Canceladas', data.cancelledBookings.toDouble(), Colors.red.shade400),
      _PieSection(
          'Pendentes', data.pendingBookings.toDouble(), Colors.orange.shade400),
      _PieSection('Expiradas', expired.toDouble(), Colors.grey.shade500),
    ].where((s) => s.value > 0).toList();

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Distribuição de Reservas por Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            if (sections.isEmpty)
              Center(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text('Sem reservas no período',
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: 14)),
                ),
              )
            else ...[
              AspectRatio(
                aspectRatio: 16 / 9,
                child: PieChart(
                  PieChartData(
                    sections: sections
                        .map((s) => PieChartSectionData(
                              value: s.value,
                              color: s.color,
                              title: '${s.value.toInt()}',
                              radius: 80,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ))
                        .toList(),
                    centerSpaceRadius: 0,
                    sectionsSpace: 2,
                    pieTouchData: PieTouchData(enabled: false),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: sections
                    .map((s) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                    color: s.color,
                                    shape: BoxShape.circle)),
                            const SizedBox(width: AppSpacing.xs),
                            Text(s.label,
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSportDonut(DashboardData data) {
    final hasSportData =
        data.revenueBySport != null && data.revenueBySport!.isNotEmpty;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Receita por Esporte',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            if (!hasSportData)
              Center(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    'Nenhum dado de esporte ainda',
                    style:
                        TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
              )
            else ...[
              AspectRatio(
                aspectRatio: 16 / 9,
                child: PieChart(
                  PieChartData(
                    sections: data.revenueBySport!
                        .asMap()
                        .entries
                        .map((entry) {
                          final idx = entry.key;
                          final sport = entry.value;
                          return PieChartSectionData(
                            value: sport.revenue,
                            color: _sportColor(idx),
                            title: sport.revenue > 0
                                ? 'R\$ ${sport.revenue.toStringAsFixed(0)}'
                                : '',
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          );
                        })
                        .toList(),
                    centerSpaceRadius: 40, // donut mode per D-12
                    sectionsSpace: 2,
                    pieTouchData: PieTouchData(enabled: false),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: data.revenueBySport!
                    .asMap()
                    .entries
                    .map((entry) {
                      final idx = entry.key;
                      final sport = entry.value;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                  color: _sportColor(idx),
                                  shape: BoxShape.circle)),
                          const SizedBox(width: AppSpacing.xs),
                          Text(sport.sport ?? 'Não informado',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      );
                    })
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Paleta de cores determinística para esportes (index-based)
  Color _sportColor(int index) {
    const palette = [
      AppTheme.primaryGreen,
      AppTheme.brandAmber,
      Color(0xFF2196F3), // blue
      Color(0xFF9C27B0), // purple
      Color(0xFFFF5722), // deep orange
      Color(0xFF00BCD4), // cyan
    ];
    return palette[index % palette.length];
  }
}

class _PieSection {
  final String label;
  final double value;
  final Color color;
  const _PieSection(this.label, this.value, this.color);
}

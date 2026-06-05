import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vida_ativa/core/models/dashboard_data.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/admin/cubit/dashboard_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/dashboard_state.dart';

/// Main dashboard tab for admin panel.
/// Redesigned with Arena Esportivo identity (Phase 29).
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
        _buildPeriodSelector(data),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: _buildKpiGrid(data),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: _buildRevenueChart(data),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: _buildHeatmap(data),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: _buildStatusPie(data),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: _buildSportDonut(data),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Period Selector (D-13, D-14) ────────────────────────────────────────────

  Widget _buildPeriodSelector(DashboardData data) {
    const tabs = [
      ('SEMANA', 'week'),
      ('MÊS', 'month'),
      ('ANO', 'year'),
    ];
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.line, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ...tabs.map((tab) {
              final label = tab.$1;
              final value = tab.$2;
              final isActive = _selectedPeriod == value;
              return GestureDetector(
                onTap: () => setState(() => _selectedPeriod = value),
                child: Container(
                  padding: const EdgeInsets.only(top: 14, bottom: 12),
                  margin: const EdgeInsets.only(right: 22),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? AppTheme.orange : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    label,
                    style: AppTheme.mono(
                      size: 10,
                      color: isActive ? AppTheme.ink : AppTheme.concrete,
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Atualizado: ${_formatTime(data.updatedAt)}',
                style: AppTheme.mono(size: 9, color: AppTheme.concrete),
              ),
            ),
          ],
        ),
      ),
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

  // ── KPI Grid 2×N hairline (D-07 through D-12, ADMN-26) ──────────────────────

  Widget _buildKpiGrid(DashboardData data) {
    final kpis = [
      _KpiItem(kicker: 'TAXA DE OCUPAÇÃO', rawValue: data.occupancyRate != null ? (data.occupancyRate! * 100) : null, unit: 'pct'),
      _KpiItem(kicker: 'RECEITA TOTAL',    rawValue: data.totalRevenue, unit: 'currency'),
      _KpiItem(kicker: 'TICKET MÉDIO',     rawValue: data.avgTicket, unit: 'currency'),
      _KpiItem(kicker: 'CONVERSÃO',        rawValue: data.conversionRate != null ? (data.conversionRate! * 100) : null, unit: 'pct'),
      _KpiItem(kicker: 'NO-SHOW',          rawValue: data.noShowRate != null ? (data.noShowRate! * 100) : null, unit: 'pct'),
    ];

    final List<Widget> rows = [];
    for (int i = 0; i < kpis.length; i += 2) {
      final isLastOdd = i == kpis.length - 1 && kpis.length % 2 == 1;
      if (isLastOdd) {
        rows.add(_buildKpiCell(kpis[i], isFirst: i < 2, spanFull: true));
      } else {
        rows.add(IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildKpiCell(kpis[i], isFirst: i < 2)),
              Container(width: 0.5, color: AppTheme.lineHair),
              Expanded(child: _buildKpiCell(kpis[i + 1], isFirst: i < 2, isRightCol: true)),
            ],
          ),
        ));
      }
      if (i + 2 < kpis.length) {
        rows.add(Container(height: 0.5, color: AppTheme.lineHair));
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.lineHair, width: 0.5),
      ),
      child: Column(children: rows),
    );
  }

  Widget _buildKpiCell(
    _KpiItem kpi, {
    bool isFirst = false,
    bool isRightCol = false,
    bool spanFull = false,
  }) {
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0);
    final rawValue = kpi.rawValue;
    final isNull = rawValue == null;

    Widget valueWidget;
    if (isNull) {
      valueWidget = Text('--', style: AppTheme.display(size: 32, color: AppTheme.concrete));
    } else if (kpi.unit == 'currency') {
      final formatted = currencyFmt.format(rawValue).replaceFirst('R\$', '').trim();
      valueWidget = Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('R\$', style: AppTheme.mono(size: 11, color: AppTheme.concrete)),
          const SizedBox(width: 2),
          Text(formatted, style: AppTheme.display(size: 32)),
        ],
      );
    } else {
      // pct
      final formatted = rawValue.toStringAsFixed(1);
      valueWidget = Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(formatted, style: AppTheme.display(size: 32)),
          Text('%', style: AppTheme.display(size: 18, color: AppTheme.concrete)),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kpi.kicker, style: AppTheme.mono(size: 9.5, color: AppTheme.concrete)),
          const SizedBox(height: 4),
          valueWidget,
          const SizedBox(height: 4),
          Text('--', style: AppTheme.mono(size: 10, color: AppTheme.concrete)),
        ],
      ),
    );
  }

  // ── Revenue Chart ────────────────────────────────────────────────────────────

  Widget _buildRevenueChart(DashboardData data) {
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0);
    final bars = [
      (label: 'TOTAL',      value: data.totalRevenue,      color: AppTheme.ink),
      (label: 'PIX',        value: data.pixRevenue,        color: AppTheme.orange),
      (label: 'PRESENCIAL', value: data.onArrivalRevenue,  color: AppTheme.concrete),
    ];
    final maxVal = bars.map((b) => b.value).reduce((a, b) => a > b ? a : b);
    const chartHeight = 130.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RECEITA', style: AppTheme.mono(size: 9.5, color: AppTheme.concrete)),
        const SizedBox(height: 4),
        Text(currencyFmt.format(data.totalRevenue), style: AppTheme.display(size: 32)),
        const SizedBox(height: 16),
        SizedBox(
          height: chartHeight + 40,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: bars.map((bar) {
              final barH = maxVal > 0 ? (bar.value / maxVal) * chartHeight : 0.0;
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      currencyFmt.format(bar.value),
                      style: AppTheme.mono(size: 9, color: AppTheme.ink),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: barH.clamp(2.0, chartHeight),
                      color: bar.color,
                    ),
                    const SizedBox(height: 6),
                    Text(bar.label, style: AppTheme.mono(size: 9, color: AppTheme.concrete)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Heatmap (placeholder structure) ─────────────────────────────────────────

  Widget _buildHeatmap(DashboardData data) {
    const hours = ['08h', '09h', '10h', '11h', '12h', '13h', '14h', '15h', '16h', '17h', '18h', '19h', '20h'];
    const days = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('OCUPAÇÃO POR HORA', style: AppTheme.mono(size: 9.5, color: AppTheme.concrete)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Y-axis labels
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 20), // header offset
                ...hours.map((h) => SizedBox(
                  height: 22,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(h, style: AppTheme.mono(size: 9, color: AppTheme.concrete)),
                  ),
                )),
              ],
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                children: [
                  // X-axis labels
                  Row(
                    children: days.map((d) => Expanded(
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: AppTheme.mono(size: 8, color: AppTheme.concrete),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 4),
                  // Grid cells
                  ...hours.map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: days.map((d) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: Container(
                            height: 18,
                            color: AppTheme.lineHair,
                          ),
                        ),
                      )).toList(),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Scale legend
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('BAIXA', style: AppTheme.mono(size: 9, color: AppTheme.concrete)),
            const SizedBox(width: 6),
            ...const [0.15, 0.35, 0.55, 0.75, 1.0].map((opacity) => Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              color: AppTheme.orange.withValues(alpha: opacity),
            )),
            const SizedBox(width: 6),
            Text('ALTA', style: AppTheme.mono(size: 9, color: AppTheme.concrete)),
          ],
        ),
      ],
    );
  }

  // ── Status Pie / Donut ───────────────────────────────────────────────────────

  Widget _buildStatusPie(DashboardData data) {
    final rawExpired = data.totalBookings -
        data.confirmedBookings -
        data.cancelledBookings -
        data.pendingBookings;

    final expired = rawExpired.clamp(0, data.totalBookings);

    final sections = <_PieSection>[
      _PieSection('CONFIRMADAS', data.confirmedBookings.toDouble(), AppTheme.court),
      _PieSection('PENDENTES',   data.pendingBookings.toDouble(),   AppTheme.sun),
      _PieSection('CANCELADAS',  data.cancelledBookings.toDouble(), AppTheme.orangeDk),
      _PieSection('EXPIRADAS',   expired.toDouble(),                AppTheme.concrete),
    ].where((s) => s.value > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DISTRIBUIÇÃO DE RESERVAS', style: AppTheme.mono(size: 9.5, color: AppTheme.concrete)),
        const SizedBox(height: 12),
        if (sections.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('Sem reservas no período', style: AppTheme.mono(size: 11, color: AppTheme.concrete)),
            ),
          )
        else
          Row(
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: sections
                            .map((s) => PieChartSectionData(
                                  value: s.value,
                                  color: s.color,
                                  title: '',
                                  radius: 52,
                                ))
                            .toList(),
                        centerSpaceRadius: 52,
                        sectionsSpace: 2,
                        pieTouchData: PieTouchData(enabled: false),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          data.totalBookings.toString(),
                          style: AppTheme.display(size: 28),
                        ),
                        Text('RESERVAS', style: AppTheme.mono(size: 9, color: AppTheme.concrete)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sections.map((s) {
                    final total = sections.fold(0.0, (sum, sec) => sum + sec.value);
                    final pct = total > 0 ? (s.value / total * 100).toStringAsFixed(0) : '0';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(width: 8, height: 8, color: s.color),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(s.label, style: AppTheme.ui(size: 12)),
                          ),
                          Text('$pct%', style: AppTheme.mono(size: 10, color: AppTheme.concrete)),
                          const SizedBox(width: 6),
                          Text(s.value.toInt().toString(), style: AppTheme.display(size: 18)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ── Revenue by Sport ─────────────────────────────────────────────────────────

  Widget _buildSportDonut(DashboardData data) {
    final hasSportData = data.revenueBySport != null && data.revenueBySport!.isNotEmpty;
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RECEITA POR ESPORTE', style: AppTheme.mono(size: 9.5, color: AppTheme.concrete)),
        const SizedBox(height: 4),
        if (!hasSportData)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('Nenhum dado de esporte ainda', style: AppTheme.mono(size: 11, color: AppTheme.concrete)),
            ),
          )
        else
          ...data.revenueBySport!.asMap().entries.map((entry) {
            final idx = entry.key;
            final sport = entry.value;
            final share = data.totalRevenue > 0 ? sport.revenue / data.totalRevenue : 0.0;
            final pct = (share * 100).toStringAsFixed(0);
            return DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: idx == 0 ? AppTheme.line : AppTheme.lineHair,
                    width: 1,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sport.sport ?? 'Não informado',
                            style: AppTheme.ui(size: 14, weight: FontWeight.w700),
                          ),
                        ),
                        Text(currencyFmt.format(sport.revenue), style: AppTheme.mono(size: 11, color: AppTheme.ink)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            Container(height: 3, color: AppTheme.lineHair),
                            Container(
                              height: 3,
                              width: constraints.maxWidth * share,
                              color: AppTheme.orange,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('$pct%', style: AppTheme.mono(size: 10, color: AppTheme.concrete)),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _PieSection {
  final String label;
  final double value;
  final Color color;
  const _PieSection(this.label, this.value, this.color);
}

class _KpiItem {
  final String kicker;
  final double? rawValue;
  final String unit; // 'currency' | 'pct'
  const _KpiItem({required this.kicker, required this.rawValue, required this.unit});
}

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
                _buildRevenueChart(data),
                const SizedBox(height: 24),
                _buildHeatmap(data),
                const SizedBox(height: 24),
                _buildStatusPie(data),
                _buildSportRows(data),
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
      _KpiItem(kicker: 'TAXA DE OCUPAÇÃO', rawValue: data.occupancyRate != null ? (data.occupancyRate! * 100) : null, unit: 'pct',
        trend: data.occupancyTrend, delta: data.occupancyDelta, tooltipText: 'Slots reservados ÷ slots disponíveis no período.'),
      _KpiItem(kicker: 'RECEITA TOTAL',    rawValue: data.totalRevenue, unit: 'currency',
        trend: data.revenueTrend, delta: data.revenueDelta, tooltipText: 'Soma de todas as reservas confirmadas no período.'),
      _KpiItem(kicker: 'TICKET MÉDIO',     rawValue: data.avgTicket, unit: 'currency',
        trend: data.avgTicketTrend, delta: data.avgTicketDelta, tooltipText: 'Receita total ÷ número de reservas confirmadas.'),
      _KpiItem(kicker: 'CONVERSÃO',        rawValue: data.conversionRate != null ? (data.conversionRate! * 100) : null, unit: 'pct',
        trend: data.conversionTrend, delta: data.conversionDelta, tooltipText: 'Reservas confirmadas ÷ total de reservas criadas.'),
      _KpiItem(kicker: 'NO-SHOW',          rawValue: data.noShowRate != null ? (data.noShowRate! * 100) : null, unit: 'pct',
        trend: data.noShowTrend, delta: data.noShowDelta, tooltipText: 'Reservas expiradas ou canceladas depois de confirmadas.'),
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

    final hasTrend = kpi.trend != null && kpi.trend!.length >= 2;
    final delta = kpi.delta;
    final deltaLabel = delta != null
        ? '${delta >= 0 ? '↑' : '↓'} ${(delta.abs() * 100).toStringAsFixed(1)}%'
        : '--';
    final deltaColor = delta != null
        ? (delta >= 0 ? AppTheme.court : AppTheme.orange)
        : AppTheme.concrete;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(kpi.kicker, style: AppTheme.mono(size: 9.5, color: AppTheme.concrete)),
              if (kpi.tooltipText.isNotEmpty) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: kpi.tooltipText,
                  triggerMode: TooltipTriggerMode.tap,
                  child: Text('?', style: AppTheme.mono(size: 9, color: AppTheme.concrete)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              valueWidget,
              if (hasTrend) ...[
                const Spacer(),
                CustomPaint(
                  size: const Size(64, 36),
                  painter: _SparklinePainter(kpi.trend!),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(deltaLabel, style: AppTheme.mono(size: 10, color: deltaColor)),
        ],
      ),
    );
  }

  // ── Revenue Chart (D-15 through D-20, ADMN-27) ──────────────────────────────

  Widget _buildRevenueChart(DashboardData data) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RECEITA', style: AppTheme.mono(size: 9.5)),
                      const SizedBox(height: 6),
                      Text(
                        'R\$ ${NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 0).format(data.totalRevenue)}',
                        style: AppTheme.display(size: 26),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bar chart
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
            child: SizedBox(
              height: 130 + 20 + 16 + 14, // 180: bar(130) + spacers(16) + labels(14) + top pad(20)
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _buildRevenueBars(data),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRevenueBars(DashboardData data) {
    final bars = [
      (label: 'TOTAL',      value: data.totalRevenue,     color: AppTheme.ink),
      (label: 'PIX',        value: data.pixRevenue,        color: AppTheme.orange),
      (label: 'PRESENCIAL', value: data.onArrivalRevenue,  color: AppTheme.concrete),
    ];
    final maxVal = bars.map((b) => b.value).reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal > 0 ? maxVal : 1.0;
    final currFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0);

    return bars.map((b) {
      final barHeight = ((b.value / safeMax) * 130.0).clamp(0.0, 130.0);
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(currFmt.format(b.value), style: AppTheme.mono(size: 10, color: AppTheme.ink)),
            const SizedBox(height: 8),
            if (barHeight > 0)
              Container(
                height: barHeight,
                color: b.color,
              ),
            const SizedBox(height: 8),
            Text(b.label, style: AppTheme.mono(size: 9.5)),
          ],
        ),
      );
    }).toList();
  }

  // ── Heatmap custom GridView (D-01 through D-06, ADMN-28) ────────────────────

  Widget _buildHeatmap(DashboardData data) {
    const days = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];
    const slots = ['08h', '10h', '12h', '14h', '16h', '18h', '20h'];
    final heat = data.heatmap ?? List.generate(7, (_) => List.filled(7, 0.0)); // [dayIdx][slotIdx]

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('OCUPAÇÃO', style: AppTheme.mono(size: 9.5)),
                      const SizedBox(height: 6),
                      Text('HORA · DIA', style: AppTheme.display(size: 26)),
                    ],
                  ),
                ),
                // Legend: BAIXA · 5 squares · ALTA
                Row(
                  children: [
                    Text('BAIXA', style: AppTheme.mono(size: 9)),
                    const SizedBox(width: 6),
                    ...[0.15, 0.35, 0.55, 0.75, 1.0].map((o) => Container(
                      width: 10,
                      height: 10,
                      color: Color.fromRGBO(255, 77, 23, o),
                      margin: const EdgeInsets.only(right: 1),
                    )),
                    const SizedBox(width: 6),
                    Text('ALTA', style: AppTheme.mono(size: 9)),
                  ],
                ),
              ],
            ),
          ),
          // Grid body
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Y-axis: slot labels
                SizedBox(
                  width: 32,
                  child: Column(
                    children: slots.map((s) => SizedBox(
                      height: 22,
                      child: Text(s, style: AppTheme.mono(size: 9)),
                    )).toList(),
                  ),
                ),
                const SizedBox(width: 6),
                // Grid: 7 slot rows × 7 day columns
                Expanded(
                  child: Column(
                    children: List.generate(slots.length, (slotIdx) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: List.generate(days.length, (dayIdx) {
                          final v = heat[dayIdx][slotIdx];
                          return Expanded(
                            child: Container(
                              height: 22,
                              margin: dayIdx < days.length - 1
                                  ? const EdgeInsets.only(right: 3)
                                  : EdgeInsets.zero,
                              color: v == 0.0
                                  ? AppTheme.lineHair
                                  : Color.fromRGBO(255, 77, 23, (0.12 + v * 0.88).clamp(0.0, 1.0)),
                            ),
                          );
                        }),
                      ),
                    )),
                  ),
                ),
              ],
            ),
          ),
          // X-axis labels
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
            child: Row(
              children: [
                const SizedBox(width: 32 + 6), // match Y-axis offset
                Expanded(
                  child: Row(
                    children: days.map((d) => Expanded(
                      child: Text(
                        d,
                        style: AppTheme.mono(size: 8.5),
                        textAlign: TextAlign.center,
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Status Pie / Donut (D-21 through D-25, ADMN-28) ────────────────────────

  Widget _buildStatusPie(DashboardData data) {
    final rawExpired = data.totalBookings -
        data.confirmedBookings -
        data.cancelledBookings -
        data.pendingBookings;
    final expired = rawExpired.clamp(0, data.totalBookings);
    final total = data.totalBookings;

    final categories = [
      (label: 'Confirmadas', count: data.confirmedBookings, color: AppTheme.court),
      (label: 'Pendentes',   count: data.pendingBookings,   color: AppTheme.sun),
      (label: 'Canceladas',  count: data.cancelledBookings, color: AppTheme.orangeDk),
      (label: 'Expiradas',   count: expired,                color: AppTheme.concrete),
    ].where((c) => c.count > 0).toList();

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RESERVAS', style: AppTheme.mono(size: 9.5)),
                      const SizedBox(height: 6),
                      Text('DISTRIBUIÇÃO', style: AppTheme.display(size: 26)),
                    ],
                  ),
                ),
                Text(
                  '${total.toString().padLeft(2, '0')} TOTAL',
                  style: AppTheme.mono(size: 11),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
            child: categories.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Sem reservas no período',
                        style: AppTheme.ui(size: 13, color: AppTheme.concrete),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      // Donut
                      SizedBox(
                        width: 132,
                        height: 132,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                sections: categories
                                    .map((c) => PieChartSectionData(
                                          value: c.count.toDouble(),
                                          color: c.color,
                                          radius: 18,
                                          title: '',
                                        ))
                                    .toList(),
                                centerSpaceRadius: 48,
                                sectionsSpace: 2,
                                pieTouchData: PieTouchData(enabled: false),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('$total', style: AppTheme.display(size: 28)),
                                Text('RESERVAS', style: AppTheme.mono(size: 9)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 22),
                      // Legend
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: categories.map((c) {
                            final pct = total > 0 ? (c.count / total * 100).round() : 0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: c.color,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      c.label,
                                      style: AppTheme.ui(size: 12.5, weight: FontWeight.w600),
                                    ),
                                  ),
                                  Text('$pct%', style: AppTheme.mono(size: 10)),
                                  const SizedBox(width: 8),
                                  Text('${c.count}', style: AppTheme.display(size: 18)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── Revenue by Sport — hairline rows (D-26 through D-31, ADMN-29) ───────────

  Widget _buildSportRows(DashboardData data) {
    final sports = data.revenueBySport;
    final currFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RECEITA', style: AppTheme.mono(size: 9.5)),
                    const SizedBox(height: 6),
                    Text('POR ESPORTE', style: AppTheme.display(size: 26)),
                  ],
                ),
              ),
              if (sports != null && sports.isNotEmpty)
                Text('${sports.length} MODALIDADES', style: AppTheme.mono(size: 11)),
            ],
          ),
          const SizedBox(height: 18),

          // Empty state
          if (sports == null || sports.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Nenhum dado de esporte ainda',
                style: AppTheme.ui(size: 13, color: AppTheme.concrete),
              ),
            )
          else
            Column(
              children: sports.asMap().entries.map((entry) {
                final idx = entry.key;
                final sp = entry.value;
                final share = data.totalRevenue > 0
                    ? (sp.revenue / data.totalRevenue).clamp(0.0, 1.0)
                    : 0.0;
                final pct = (share * 100).round();

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
                        // Line 1: sport name + revenue
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                sp.sport ?? 'Não informado',
                                style: AppTheme.ui(size: 14, weight: FontWeight.w700),
                              ),
                            ),
                            Text(
                              currFmt.format(sp.revenue),
                              style: AppTheme.display(size: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Line 2: progress bar + percentage
                        Row(
                          children: [
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) => SizedBox(
                                  height: 3,
                                  child: Stack(
                                    children: [
                                      Container(color: AppTheme.lineHair),
                                      Container(
                                        width: constraints.maxWidth * share,
                                        color: AppTheme.orange,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('$pct%', style: AppTheme.mono(size: 10)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _KpiItem {
  final String kicker;
  final double? rawValue;
  final String unit; // 'currency' | 'pct'
  final List<double>? trend;
  final double? delta; // period-over-period ratio, e.g. 0.082 = +8.2%
  final String tooltipText;
  const _KpiItem({
    required this.kicker,
    required this.rawValue,
    required this.unit,
    this.trend,
    this.delta,
    this.tooltipText = '',
  });
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  const _SparklinePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final min = points.reduce((a, b) => a < b ? a : b);
    final max = points.reduce((a, b) => a > b ? a : b);
    final range = max - min;
    final isUp = points.last >= points.first;
    final paint = Paint()
      ..color = isUp ? AppTheme.court : AppTheme.orangeDk
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final normalized = range > 0 ? (points[i] - min) / range : 0.5;
      final y = size.height - normalized * size.height;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.points != points;
}

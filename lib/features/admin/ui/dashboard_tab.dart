import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vida_ativa/core/models/dashboard_data.dart';
import 'package:vida_ativa/core/theme/app_spacing.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/admin/cubit/dashboard_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/dashboard_state.dart';

/// Main dashboard tab for admin panel.
/// Shows KPI cards and chart placeholders (stubs replaced in Plan 22-03).
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
            SnackBar(
              content: Text(state.message),
              action: SnackBarAction(
                label: 'Tentar Novamente',
                onPressed: () {
                  // DashboardCubit re-fetches automatically via stream.
                  // No explicit retry method needed — stream will reconnect.
                },
              ),
            ),
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

  // --- Chart stubs — Plan 22-03 replaces these with real implementations ---

  Widget _buildRevenueChart(DashboardData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Receita',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: AppSpacing.sm),
            AspectRatio(
                aspectRatio: 16 / 9,
                child: Center(child: Text('Carregando...'))),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmap(DashboardData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Ocupação por Hora e Dia',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: AppSpacing.sm),
            Center(child: Text('Carregando...')),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPie(DashboardData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Distribuição de Reservas por Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: AppSpacing.sm),
            AspectRatio(
                aspectRatio: 16 / 9,
                child: Center(child: Text('Carregando...'))),
          ],
        ),
      ),
    );
  }

  Widget _buildSportDonut(DashboardData data) {
    final hasSportData =
        data.revenueBySport != null && data.revenueBySport!.isNotEmpty;
    return Card(
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
            else
              const AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Center(child: Text('Carregando...'))),
          ],
        ),
      ),
    );
  }
}

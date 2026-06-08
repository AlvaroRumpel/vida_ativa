import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vida_ativa/core/models/dashboard_data.dart';
import 'package:vida_ativa/features/admin/cubit/dashboard_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/dashboard_state.dart';
import 'package:vida_ativa/features/admin/ui/dashboard_tab.dart';

class MockDashboardCubit extends MockCubit<DashboardState>
    implements DashboardCubit {}

DashboardData testDashboardData({
  double totalRevenue = 1000.0,
  double pixRevenue = 600.0,
  double onArrivalRevenue = 400.0,
  int totalBookings = 10,
  int confirmedBookings = 7,
  int cancelledBookings = 2,
  int pendingBookings = 1,
  int totalSlotsBooked = 8,
  double? occupancyRate = 0.8,
  double? avgTicket = 100.0,
  double? conversionRate = 0.7,
  double? noShowRate = 0.1,
  List<RevenueBySportEntry>? revenueBySport,
}) =>
    DashboardData(
      period: 'week',
      startDate: '2026-01-01',
      endDate: '2026-01-07',
      updatedAt: DateTime(2026, 5, 21, 10, 30),
      totalBookings: totalBookings,
      confirmedBookings: confirmedBookings,
      cancelledBookings: cancelledBookings,
      pendingBookings: pendingBookings,
      totalSlotsBooked: totalSlotsBooked,
      totalRevenue: totalRevenue,
      pixRevenue: pixRevenue,
      onArrivalRevenue: onArrivalRevenue,
      totalSlotsAvailable: 10,
      occupancyRate: occupancyRate,
      avgTicket: avgTicket,
      conversionRate: conversionRate,
      noShowRate: noShowRate,
      uniqueClients: 5,
      newClients: 2,
      returnRate: 0.6,
      topClients: null,
      revenueBySport: revenueBySport,
    );

Widget buildSubject(MockDashboardCubit cubit) => MaterialApp(
      home: BlocProvider<DashboardCubit>.value(
        value: cubit,
        child: const Scaffold(body: DashboardTab()),
      ),
    );

void main() {
  late MockDashboardCubit cubit;

  setUp(() {
    cubit = MockDashboardCubit();
  });

  group('DashboardTab', () {
    group('loading state', () {
      testWidgets('mostra CircularProgressIndicator quando DashboardLoading',
          (tester) async {
        when(() => cubit.state).thenReturn(const DashboardLoading());
        await tester.pumpWidget(buildSubject(cubit));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('period_toggle', () {
      testWidgets('SegmentedButton com 3 segmentos Semana/Mes/Ano visivel',
          (tester) async {
        when(() => cubit.state).thenReturn(DashboardLoaded(
          week: testDashboardData(),
          month: testDashboardData(),
          year: testDashboardData(),
        ));
        await tester.pumpWidget(buildSubject(cubit));
        expect(find.text('SEMANA'), findsOneWidget);
        expect(find.text('MÊS'), findsOneWidget);
        expect(find.text('ANO'), findsOneWidget);
      });
    });

    group('kpi_cards', () {
      testWidgets('mostra 5 KPI cards com labels corretos', (tester) async {
        when(() => cubit.state).thenReturn(DashboardLoaded(
          week: testDashboardData(),
          month: testDashboardData(),
          year: testDashboardData(),
        ));
        await tester.pumpWidget(buildSubject(cubit));
        expect(find.text('TAXA DE OCUPAÇÃO'), findsOneWidget);
        expect(find.text('RECEITA TOTAL'), findsOneWidget);
        expect(find.text('TICKET MÉDIO'), findsOneWidget);
        expect(find.text('CONVERSÃO'), findsOneWidget);
        expect(find.text('NO-SHOW'), findsOneWidget);
      });

      testWidgets('mostra -- quando metricas nullable sao null',
          (tester) async {
        when(() => cubit.state).thenReturn(DashboardLoaded(
          week: testDashboardData(
              occupancyRate: null,
              avgTicket: null,
              conversionRate: null,
              noShowRate: null),
          month: testDashboardData(),
          year: testDashboardData(),
        ));
        await tester.pumpWidget(buildSubject(cubit));
        expect(find.text('--'), findsAtLeastNWidgets(4));
      });
    });

    group('revenue_chart', () {
      testWidgets('BarChart de receita renderiza com dados', (tester) async {
        when(() => cubit.state).thenReturn(DashboardLoaded(
          week: testDashboardData(),
          month: testDashboardData(),
          year: testDashboardData(),
        ));
        await tester.pumpWidget(buildSubject(cubit));
        expect(find.text('RECEITA'), findsAtLeastNWidgets(1));
      });
    });

    group('heatmap', () {
      testWidgets('heatmap ocupa e dia renderiza titulo', (tester) async {
        when(() => cubit.state).thenReturn(DashboardLoaded(
          week: testDashboardData(),
          month: testDashboardData(),
          year: testDashboardData(),
        ));
        await tester.pumpWidget(buildSubject(cubit));
        expect(find.text('OCUPAÇÃO'), findsOneWidget);
        expect(find.text('HORA · DIA'), findsOneWidget);
      });
    });

    group('status_pie', () {
      testWidgets('PieChart de status renderiza titulo', (tester) async {
        when(() => cubit.state).thenReturn(DashboardLoaded(
          week: testDashboardData(),
          month: testDashboardData(),
          year: testDashboardData(),
        ));
        await tester.pumpWidget(buildSubject(cubit));
        expect(find.text('RESERVAS'), findsAtLeastNWidgets(1));
        expect(find.text('DISTRIBUIÇÃO'), findsOneWidget);
      });
    });

    group('donut_sport', () {
      testWidgets('mostra mensagem quando revenueBySport e null',
          (tester) async {
        when(() => cubit.state).thenReturn(DashboardLoaded(
          week: testDashboardData(revenueBySport: null),
          month: testDashboardData(),
          year: testDashboardData(),
        ));
        await tester.pumpWidget(buildSubject(cubit));
        expect(find.text('Nenhum dado de esporte ainda'), findsOneWidget);
      });

      testWidgets('Donut chart renderiza quando revenueBySport tem dados',
          (tester) async {
        when(() => cubit.state).thenReturn(DashboardLoaded(
          week: testDashboardData(revenueBySport: [
            const RevenueBySportEntry(sport: 'Vôlei', revenue: 500.0),
          ]),
          month: testDashboardData(),
          year: testDashboardData(),
        ));
        await tester.pumpWidget(buildSubject(cubit));
        expect(find.text('RECEITA'), findsAtLeastNWidgets(1));
        expect(find.text('POR ESPORTE'), findsOneWidget);
      });
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:vida_ativa/core/models/booking_model.dart';
import 'package:vida_ativa/core/models/month_bookings_summary.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/admin/ui/booking_month_view.dart';

BookingModel _booking(
  String date, {
  String status = 'confirmed',
  String? group,
  String name = 'Ana',
  String startTime = '18:00',
}) =>
    BookingModel(
      id: 'slot_$date',
      slotId: 'slot',
      date: date,
      userId: 'u1',
      status: status,
      createdAt: DateTime(2026, 11, 1),
      startTime: startTime,
      userDisplayName: name,
      recurrenceGroupId: group,
    );

void main() {
  final bookings = [
    _booking('2026-11-03', group: 'g1'), // Terça
    _booking('2026-11-10', group: 'g1'),
    _booking('2026-11-17', group: 'g1', status: 'cancelled'),
    _booking('2026-11-02', group: 'g2', name: 'Bia Souza', startTime: '08:00'), // Segunda
    _booking('2026-11-03', startTime: '21:00'),
    _booking('2026-11-03', startTime: '20:00'),
    _booking('2026-11-04', status: 'rejected'),
    _booking('2026-11-05', status: 'expired'),
    _booking('2026-11-06', status: 'refunded'),
    _booking('2026-11-07', status: 'pending_payment'),
  ];

  test('summary ignores dead bookings and groups recurring series', () {
    final summary = MonthBookingsSummary.from(bookings);

    expect(summary.total, 6);
    expect(summary.recurring, 3);
    expect(summary.single, 3);
    expect(summary.bookingsByDay[3]!.map((b) => b.startTime),
        ['18:00', '20:00', '21:00']);
    expect(summary.bookingsByDay.containsKey(17), isFalse);
    expect(summary.series.map((s) => s.clientName), ['Bia Souza', 'Ana']);
    expect(summary.series.last.count, 2);
    expect(summary.series.last.weekday, DateTime.tuesday);
  });

  testWidgets('month grid fits a phone, navigates months and selects a day',
      (tester) async {
    await initializeDateFormatting('pt_BR');
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final requested = <DateTime>[];
    DateTime? selected;
    BookingModel? tapped;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: BookingMonthView(
          initialMonth: DateTime(2026, 11, 15),
          watchMonth: (month) {
            requested.add(month);
            return Stream.value(bookings);
          },
          onDaySelected: (date) => selected = date,
          onBookingSelected: (booking) => tapped = booking,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('NOVEMBRO 2026'), findsOneWidget);
    expect(find.text('RECORRENTES'), findsOneWidget);
    expect(find.text('Bia'), findsOneWidget); // First name on the chip
    expect(find.text('+1'), findsOneWidget); // Third booking on day 3
    expect(find.text('TER 18:00'), findsOneWidget);

    // Novembro 2026 começa num domingo: 6 células vazias antes do dia 1.
    await tester.tap(find.text('30'));
    expect(selected, DateTime(2026, 11, 30));

    // Chip opens the booking, not the day.
    selected = null;
    await tester.tap(find.text('Bia'));
    expect(tapped?.userDisplayName, 'Bia Souza');
    expect(selected, isNull);

    await tester.tap(find.byTooltip('Próximo mês'));
    await tester.pumpAndSettle();
    expect(requested.last, DateTime(2026, 12));
    expect(find.text('DEZEMBRO 2026'), findsOneWidget);
  });
}

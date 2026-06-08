import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vida_ativa/core/models/booking_model.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/admin/ui/admin_booking_row.dart';

BookingModel _makeBooking({
  String status = 'pending',
  String? paymentMethod,
  String? participants,
}) =>
    BookingModel(
      id: 'slot1_2026-06-04',
      slotId: 'slot1',
      date: '2026-06-04',
      userId: 'user1',
      status: status,
      createdAt: DateTime(2026, 6, 4),
      startTime: '08:00',
      userDisplayName: 'João Silva',
      participants: participants,
      paymentMethod: paymentMethod,
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    );

void main() {
  group('AdminBookingRow — ADMN-18 typography', () {
    testWidgets('ADMN-18a: startTime rendered with Anton 36px style', (tester) async {
      await tester.pumpWidget(
        _wrap(AdminBookingRow(booking: _makeBooking(), index: 0)),
      );
      final textWidget = tester.widgetList<Text>(find.text('08:00')).first;
      expect(textWidget.style, isNotNull);
      expect(textWidget.style!.fontSize, 36.0);
    });

    testWidgets('ADMN-18b: userDisplayName rendered with Manrope 14px bold', (tester) async {
      await tester.pumpWidget(
        _wrap(AdminBookingRow(booking: _makeBooking(), index: 0)),
      );
      final textWidget = tester.widgetList<Text>(find.text('João Silva')).first;
      expect(textWidget.style, isNotNull);
      expect(textWidget.style!.fontSize, 15.0);
      expect(textWidget.style!.fontWeight, FontWeight.w700);
    });

    testWidgets('ADMN-18c: status pending renders AGUARDANDO in orange', (tester) async {
      await tester.pumpWidget(
        _wrap(AdminBookingRow(booking: _makeBooking(status: 'pending'), index: 0)),
      );
      expect(find.text('AGUARDANDO'), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text('AGUARDANDO'));
      expect(textWidget.style!.color, AppTheme.orange);
    });

    testWidgets('ADMN-18d: status confirmed/pix renders PIX PAGO in court', (tester) async {
      await tester.pumpWidget(
        _wrap(AdminBookingRow(
          booking: _makeBooking(status: 'confirmed', paymentMethod: 'pix'),
          index: 0,
        )),
      );
      expect(find.text('PIX PAGO'), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text('PIX PAGO'));
      expect(textWidget.style!.color, AppTheme.court);
    });

    testWidgets('ADMN-18e: index > 0 has top hairline border', (tester) async {
      await tester.pumpWidget(
        _wrap(AdminBookingRow(booking: _makeBooking(), index: 1)),
      );
      final decorated = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox)).first;
      final box = decorated.decoration as BoxDecoration;
      expect(box.border, isNotNull);
      final border = box.border as Border;
      expect(border.top.color, AppTheme.lineHair);
      expect(border.top.width, 0.5);
    });
  });

  group('AdminBookingRow — ADMN-19 pills', () {
    testWidgets('ADMN-19a: status pending renders CONFIRMAR and RECUSAR', (tester) async {
      await tester.pumpWidget(
        _wrap(AdminBookingRow(booking: _makeBooking(status: 'pending'), index: 0)),
      );
      expect(find.text('CONFIRMAR'), findsOneWidget);
      expect(find.text('RECUSAR'), findsOneWidget);
    });

    testWidgets('ADMN-19b: status confirmed does NOT render CONFIRMAR or RECUSAR', (tester) async {
      await tester.pumpWidget(
        _wrap(AdminBookingRow(
          booking: _makeBooking(status: 'confirmed'),
          index: 0,
        )),
      );
      expect(find.text('CONFIRMAR'), findsNothing);
      expect(find.text('RECUSAR'), findsNothing);
    });

    testWidgets('ADMN-19c: tap CONFIRMAR calls onConfirm callback', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _wrap(AdminBookingRow(
          booking: _makeBooking(status: 'pending'),
          index: 0,
          onConfirm: () => called = true,
        )),
      );
      await tester.tap(find.text('CONFIRMAR'));
      await tester.pump();
      expect(called, isTrue);
    });

    testWidgets('ADMN-19d: tap RECUSAR calls onReject callback', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _wrap(AdminBookingRow(
          booking: _makeBooking(status: 'pending'),
          index: 0,
          onReject: () => called = true,
        )),
      );
      await tester.tap(find.text('RECUSAR'));
      await tester.pump();
      expect(called, isTrue);
    });
  });
}

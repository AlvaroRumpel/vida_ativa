import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:vida_ativa/core/models/slot_model.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/booking/cubit/booking_cubit.dart';
import 'package:vida_ativa/features/booking/ui/booking_confirmation_sheet.dart';
import 'package:vida_ativa/features/schedule/models/slot_view_model.dart';

class _FakeBookingCubit extends Fake implements BookingCubit {}

void main() {
  testWidgets('shows late-cancellation notice with and without Pix',
      (tester) async {
    await initializeDateFormatting('pt_BR');
    tester.view.physicalSize = const Size(480, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final pixEnabled in [true, false]) {
      await tester.pumpWidget(MaterialApp(
        key: ValueKey(pixEnabled),
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: BookingConfirmationSheet(
            viewModel: SlotViewModel(
              slot: const SlotModel(
                id: 'slot',
                date: '2026-11-10',
                startTime: '18:00',
                price: 50,
                isActive: true,
              ),
              status: SlotStatus.available,
              dateString: '2026-11-10',
            ),
            bookingCubit: _FakeBookingCubit(),
            pixEnabled: pixEnabled,
          ),
        ),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(
        find.text(
          'Cancelamentos com menos de 1 hora de antecedência serão cobrados normalmente.',
        ),
        findsOneWidget,
      );
    }
  });
}

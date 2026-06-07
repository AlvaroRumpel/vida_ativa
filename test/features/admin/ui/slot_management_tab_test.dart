import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vida_ativa/core/models/slot_model.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/admin/cubit/admin_booking_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/admin_booking_state.dart';
import 'package:vida_ativa/features/admin/cubit/admin_slot_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/admin_slot_state.dart';
import 'package:vida_ativa/features/admin/ui/slot_management_tab.dart';

// ── Fake cubits ──────────────────────────────────────────────────────────────

class FakeAdminSlotCubit extends MockCubit<AdminSlotState>
    implements AdminSlotCubit {}

class FakeAdminBookingCubit extends MockCubit<AdminBookingState>
    implements AdminBookingCubit {}

// ── Helpers ──────────────────────────────────────────────────────────────────

SlotModel _makeSlot({
  String id = 'slot1',
  String date = '2026-06-02',
  String startTime = '08:00',
  double price = 120.0,
  bool isActive = true,
}) =>
    SlotModel(
      id: id,
      date: date,
      startTime: startTime,
      price: price,
      isActive: isActive,
    );

String _todayStr() {
  final today = DateTime.now();
  return '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
}

/// Wraps widget in BlocProviders required by SlotManagementTab.
Widget _wrap({
  required Widget child,
  required FakeAdminSlotCubit slotCubit,
  required FakeAdminBookingCubit bookingCubit,
}) {
  return MaterialApp(
    home: MultiBlocProvider(
      providers: [
        BlocProvider<AdminSlotCubit>.value(value: slotCubit),
        BlocProvider<AdminBookingCubit>.value(value: bookingCubit),
      ],
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  late FakeAdminSlotCubit slotCubit;
  late FakeAdminBookingCubit bookingCubit;

  setUp(() {
    slotCubit = FakeAdminSlotCubit();
    bookingCubit = FakeAdminBookingCubit();

    final todayStr = _todayStr();
    when(() => slotCubit.state).thenReturn(AdminSlotLoaded([
      _makeSlot(id: 'slot1', date: todayStr, startTime: '08:00'),
      _makeSlot(id: 'slot2', date: todayStr, startTime: '10:00'),
    ]));
    when(() => bookingCubit.state).thenReturn(const AdminBookingInitial());
  });

  // ── ADMN-16 Tests ────────────────────────────────────────────────────────

  group('ADMN-16a: SlotRow — empty slot uses Anton 32px with ink color', () {
    testWidgets('renders startTime text with Anton 32px and ink color', (tester) async {
      final todayStr = _todayStr();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SlotRow(
            slot: _makeSlot(id: 's1', date: todayStr, startTime: '08:00'),
            isBooked: false,
            bookedByName: null,
            sport: null,
            index: 0,
            onTap: () {},
            onSwitchToggle: (_) {},
          ),
        ),
      ));
      await tester.pump();

      final timeText = tester.widget<Text>(find.text('08:00'));
      expect(timeText.style?.fontSize, 32.0,
          reason: 'startTime should be 32px');
      expect(timeText.style?.color, AppTheme.ink,
          reason: 'Empty slot time should use ink color');
    });
  });

  group('ADMN-16b: SlotRow — booked slot uses Anton 32px with orange color', () {
    testWidgets('renders startTime text with Anton 32px and orange color when booked', (tester) async {
      final todayStr = _todayStr();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SlotRow(
            slot: _makeSlot(id: 's1', date: todayStr, startTime: '09:00'),
            isBooked: true,
            bookedByName: 'João Silva',
            sport: 'Vôlei',
            index: 0,
            onTap: () {},
          ),
        ),
      ));
      await tester.pump();

      final timeText = tester.widget<Text>(find.text('09:00'));
      expect(timeText.style?.fontSize, 32.0);
      expect(timeText.style?.color, AppTheme.orange,
          reason: 'Booked slot time should use orange color');
    });
  });

  group('ADMN-16c: SlotRow — empty slot renders Switch', () {
    testWidgets('shows Switch when slot is not booked', (tester) async {
      final todayStr = _todayStr();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SlotRow(
            slot: _makeSlot(id: 's1', date: todayStr, startTime: '08:00'),
            isBooked: false,
            bookedByName: null,
            sport: null,
            index: 0,
            onTap: () {},
            onSwitchToggle: (_) {},
          ),
        ),
      ));
      await tester.pump();

      expect(find.byType(Switch), findsOneWidget,
          reason: 'Empty slot should have a Switch toggle');
    });
  });

  group('ADMN-16d: SlotRow — booked slot shows bookedByName', () {
    testWidgets('shows booker name text when slot is booked', (tester) async {
      final todayStr = _todayStr();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SlotRow(
            slot: _makeSlot(id: 's1', date: todayStr, startTime: '10:00'),
            isBooked: true,
            bookedByName: 'Maria Oliveira',
            sport: null,
            index: 0,
            onTap: () {},
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('Maria Oliveira'), findsOneWidget,
          reason: 'Booked slot should show bookedByName');

      final nameText = tester.widget<Text>(find.text('Maria Oliveira'));
      expect(nameText.style?.fontSize, 13.0,
          reason: 'Name should be 13px Manrope');
    });
  });

  group('ADMN-16e: SlotRow — no Card nor hardcoded backgroundColor', () {
    testWidgets('SlotRow does not use Card widgets', (tester) async {
      final todayStr = _todayStr();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SlotRow(
                slot: _makeSlot(id: 's1', date: todayStr, startTime: '08:00'),
                isBooked: false,
                bookedByName: null,
                sport: null,
                index: 0,
                onTap: () {},
                onSwitchToggle: (_) {},
              ),
              SlotRow(
                slot: _makeSlot(id: 's2', date: todayStr, startTime: '10:00'),
                isBooked: true,
                bookedByName: 'Ana Costa',
                sport: 'Beach Tênis',
                index: 1,
                onTap: () {},
              ),
            ],
          ),
        ),
      ));
      await tester.pump();

      expect(find.byType(Card), findsNothing,
          reason: 'SlotRow should not use Card widgets');
    });
  });

  // ── ADMN-17 Tests ────────────────────────────────────────────────────────

  group('ADMN-17a: AdminDaySelector — renders 7 day items', () {
    testWidgets('shows 7 GestureDetector for days of the week', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AdminDaySelector(
            selectedDate: DateTime(2026, 6, 2), // Monday
            onDateChanged: (_) {},
          ),
        ),
      ));
      await tester.pump();

      // There should be at least 7 GestureDetectors (one per day)
      expect(find.byType(GestureDetector), findsAtLeast(7),
          reason: 'Should render 7 day selectors');
    });
  });

  group('ADMN-17b: AdminDaySelector — renders prev/next navigation buttons', () {
    testWidgets('shows chevron_left and chevron_right buttons', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AdminDaySelector(
            selectedDate: DateTime(2026, 6, 2),
            onDateChanged: (_) {},
          ),
        ),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });

  group('ADMN-17c: AdminDaySelector — selected day shows orange underline', () {
    testWidgets('selected day renders orange underline container', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AdminDaySelector(
            selectedDate: DateTime(2026, 6, 2), // Monday
            onDateChanged: (_) {},
          ),
        ),
      ));
      await tester.pump();

      // Find Container with orange color (the underline indicator).
      // The widget uses Container(color: AppTheme.orange) directly, so we
      // check c.color rather than c.decoration.
      final containers = tester.widgetList<Container>(find.byType(Container));
      final orangeIndicator = containers.where((c) => c.color == AppTheme.orange);

      expect(orangeIndicator, isNotEmpty,
          reason: 'Selected day should have an orange underline container');
    });
  });
}

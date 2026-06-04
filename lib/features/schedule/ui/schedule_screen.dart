import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vida_ativa/features/schedule/cubit/schedule_cubit.dart';
import 'package:vida_ativa/features/schedule/cubit/schedule_state.dart';
import 'package:vida_ativa/features/schedule/ui/day_chip_row.dart';
import 'package:vida_ativa/features/schedule/ui/slot_day_view.dart';
import 'package:vida_ativa/features/schedule/ui/week_header.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late DateTime _weekStart;
  late DateTime _selectedDay;
  late DateTime _currentWeekMonday;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentWeekMonday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    _weekStart = _currentWeekMonday;
    _selectedDay = DateTime(now.year, now.month, now.day);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleCubit>().selectDay(_selectedDay);
    });
  }

  DateTime get _maxWeekStart =>
      _currentWeekMonday.add(const Duration(days: 7 * 7));

  bool get _canGoPrevious => _weekStart.isAfter(_currentWeekMonday);

  bool get _canGoNext => _weekStart.isBefore(_maxWeekStart);

  void _goToPreviousWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
      _selectedDay = _weekStart;
    });
    context.read<ScheduleCubit>().selectDay(_selectedDay);
  }

  void _goToNextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
      _selectedDay = _weekStart;
    });
    context.read<ScheduleCubit>().selectDay(_selectedDay);
  }

  void _onDaySelected(DateTime day) {
    setState(() => _selectedDay = day);
    context.read<ScheduleCubit>().selectDay(day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.sports_volleyball, size: 20, color: Color(0xFFD4860A)),
            SizedBox(width: 8),
            Text('Agenda'),
          ],
        ),
      ),
      body: Column(
        children: [
          WeekHeader(
            weekStart: _weekStart,
            onPreviousWeek: _canGoPrevious ? _goToPreviousWeek : null,
            onNextWeek: _canGoNext ? _goToNextWeek : null,
          ),
          DayChipRow(
            weekStart: _weekStart,
            selectedDay: _selectedDay,
            onDaySelected: _onDaySelected,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<ScheduleCubit, ScheduleState>(
              builder: (context, state) => SlotDayView(
                    state: state,
                    selectedDay: _selectedDay,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

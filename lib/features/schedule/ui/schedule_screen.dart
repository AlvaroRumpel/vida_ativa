import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/schedule/cubit/schedule_cubit.dart';
import 'package:vida_ativa/features/schedule/cubit/schedule_state.dart';
import 'package:vida_ativa/features/schedule/ui/day_chip_row.dart';
import 'package:vida_ativa/features/schedule/ui/slot_list.dart';
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

  String _eyebrowDate(DateTime day) {
    const abbrevDays = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];
    const abbrevMonths = ['JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'];
    final dayName = abbrevDays[day.weekday - 1];
    final monthName = abbrevMonths[day.month - 1];
    return '$dayName, ${day.day} $monthName';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('VIDA', style: AppTheme.display(size: 18, color: AppTheme.ink)),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('ATIVA', style: AppTheme.display(size: 18, color: AppTheme.paper)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    _eyebrowDate(_selectedDay),
                    style: AppTheme.mono(size: 11, color: AppTheme.ink),
                  ),
                ],
              ),
            ),
          ),
          WeekHeader(
            weekStart: _weekStart,
            onPreviousWeek: _canGoPrevious ? _goToPreviousWeek : null,
            onNextWeek: _canGoNext ? _goToNextWeek : null,
          ),
          SportDayStrip(
            weekStart: _weekStart,
            selectedDay: _selectedDay,
            onDaySelected: _onDaySelected,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<ScheduleCubit, ScheduleState>(
              builder: (context, state) => SlotList(state: state),
            ),
          ),
        ],
      ),
    );
  }
}

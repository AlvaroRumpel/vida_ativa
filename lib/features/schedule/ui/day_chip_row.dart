import 'package:flutter/material.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';

class SportDayStrip extends StatelessWidget {
  final DateTime weekStart;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  const SportDayStrip({
    super.key,
    required this.weekStart,
    required this.selectedDay,
    required this.onDaySelected,
  });

  static const _abbrev = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Color _numberColor(bool isSelected, bool isToday) {
    if (isSelected) return AppTheme.orange;
    if (isToday) return AppTheme.orange;
    return AppTheme.ink;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final day = weekStart.add(Duration(days: i));
          final isSelected = _isSameDay(day, selectedDay);
          final isToday = _isSameDay(day, today);
          return GestureDetector(
            onTap: () => onDaySelected(day),
            child: SizedBox(
              width: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _abbrev[i],
                    style: AppTheme.mono(size: 11, color: AppTheme.concrete),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: AppTheme.display(
                      size: 22,
                      color: _numberColor(isSelected, isToday),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 2,
                    width: isSelected ? 24 : 0,
                    color: AppTheme.orange,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

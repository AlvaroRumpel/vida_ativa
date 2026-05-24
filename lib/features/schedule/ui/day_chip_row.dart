import 'package:flutter/material.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';

class DayChipRow extends StatelessWidget {
  final DateTime weekStart;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  const DayChipRow({
    super.key,
    required this.weekStart,
    required this.selectedDay,
    required this.onDaySelected,
  });

  static const _dayAbbrev = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: List.generate(7, (i) {
          final day = weekStart.add(Duration(days: i));
          final isSelected = _isSameDay(day, selectedDay);
          return Expanded(
            child: GestureDetector(
              onTap: () => onDaySelected(day),
              behavior: HitTestBehavior.opaque,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? AppTheme.orange : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                padding: const EdgeInsets.only(top: 10, bottom: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _dayAbbrev[i],
                      style: AppTheme.mono(
                        size: 9,
                        color: isSelected ? AppTheme.ink : AppTheme.concrete,
                        letterSpacing: 1.44,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${day.day}',
                      style: AppTheme.display(
                        size: 22,
                        color: isSelected ? AppTheme.ink : AppTheme.concrete,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

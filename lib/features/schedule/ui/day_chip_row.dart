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

  static const _dayAbbrev = [
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'S\u00e1b',
    'Dom',
  ];

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(7, (i) {
            final day = weekStart.add(Duration(days: i));
            final isSelected = _isSameDay(day, selectedDay);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text('${_dayAbbrev[i]} ${day.day}'),
                selected: isSelected,
                selectedColor: AppTheme.primaryGreen,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : null,
                ),
                onSelected: (_) => onDaySelected(day),
              ),
            );
          }),
        ),
      ),
    );
  }
}

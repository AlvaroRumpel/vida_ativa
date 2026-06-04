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
    'Sáb',
    'Dom',
  ];

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(7, (i) {
            final day = weekStart.add(Duration(days: i));
            final isSelected = _isSameDay(day, selectedDay);
            final isToday = _isSameDay(day, today);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChoiceChip(
                    label: Text(
                      '${_dayAbbrev[i]} ${day.day}',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? AppTheme.brandAmber
                                : const Color(0xFF4A4A4A),
                        fontWeight: (isSelected || isToday)
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    showCheckmark: false,
                    selectedColor: AppTheme.primaryGreen,
                    backgroundColor: const Color(0xFFF0EDE8),
                    side: isSelected
                        ? BorderSide.none
                        : BorderSide(
                            color: isToday
                                ? AppTheme.brandAmber.withValues(alpha: 0.5)
                                : const Color(0xFFCFC5B0),
                            width: isToday ? 1.5 : 0.5,
                          ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onSelected: (_) => onDaySelected(day),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isToday ? AppTheme.brandAmber : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

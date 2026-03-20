import 'package:flutter/material.dart';

class WeekHeader extends StatelessWidget {
  final DateTime weekStart;
  final VoidCallback? onPreviousWeek;
  final VoidCallback? onNextWeek;

  const WeekHeader({
    super.key,
    required this.weekStart,
    this.onPreviousWeek,
    this.onNextWeek,
  });

  static const _months = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  String _weekLabel(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    if (weekStart.month == weekEnd.month) {
      return 'Semana de ${weekStart.day}\u2013${weekEnd.day} ${_months[weekEnd.month - 1]}';
    }
    return 'Semana de ${weekStart.day} ${_months[weekStart.month - 1]}\u2013${weekEnd.day} ${_months[weekEnd.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPreviousWeek,
          ),
          Text(
            _weekLabel(weekStart),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNextWeek,
          ),
        ],
      ),
    );
  }
}

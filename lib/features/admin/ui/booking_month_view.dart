import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vida_ativa/core/models/booking_model.dart';
import 'package:vida_ativa/core/models/month_bookings_summary.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';

const _weekdayLabels = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];

// Below this width day cells stack the time over the client's first name.
const _compactGridWidth = 640.0;

/// Month calendar for the admin: totals, bookings per day and recurring series.
class BookingMonthView extends StatefulWidget {
  final DateTime initialMonth;
  final Stream<List<BookingModel>> Function(DateTime month) watchMonth;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<BookingModel> onBookingSelected;

  const BookingMonthView({
    super.key,
    required this.initialMonth,
    required this.watchMonth,
    required this.onDaySelected,
    required this.onBookingSelected,
  });

  @override
  State<BookingMonthView> createState() => _BookingMonthViewState();
}

class _BookingMonthViewState extends State<BookingMonthView> {
  late DateTime _month;
  late Stream<List<BookingModel>> _bookings;

  @override
  void initState() {
    super.initState();
    _setMonth(DateTime(widget.initialMonth.year, widget.initialMonth.month));
  }

  void _setMonth(DateTime month) {
    _month = month;
    _bookings = widget.watchMonth(month);
  }

  void _moveMonth(int delta) => setState(
        () => _setMonth(DateTime(_month.year, _month.month + delta)),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Mês anterior',
                onPressed: () => _moveMonth(-1),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    DateFormat('MMMM yyyy', 'pt_BR').format(_month).toUpperCase(),
                    style: AppTheme.display(size: 24),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Próximo mês',
                onPressed: () => _moveMonth(1),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<BookingModel>>(
            stream: _bookings,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erro ao carregar reservas.',
                    style: AppTheme.ui(color: AppTheme.orangeDk),
                  ),
                );
              }
              // StreamBuilder keeps the previous month's data while waiting.
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final summary = MonthBookingsSummary.from(snapshot.data ?? const []);
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    children: [
                      _Totals(summary: summary),
                      const SizedBox(height: 16),
                      _MonthGrid(
                        month: _month,
                        summary: summary,
                        onDaySelected: widget.onDaySelected,
                        onBookingSelected: widget.onBookingSelected,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'RECORRÊNCIAS',
                        style: AppTheme.mono(size: 10, color: AppTheme.concrete),
                      ),
                      const SizedBox(height: 4),
                      if (summary.series.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Nenhuma recorrência neste mês.',
                            style: AppTheme.ui(size: 13, color: AppTheme.concrete),
                          ),
                        )
                      else
                        for (final series in summary.series)
                          _SeriesRow(series: series),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Totals extends StatelessWidget {
  final MonthBookingsSummary summary;

  const _Totals({required this.summary});

  Widget _total(String label, int value, {Color? color}) => Expanded(
        child: Column(
          children: [
            Text('$value', style: AppTheme.display(size: 32, color: color)),
            Text(label, style: AppTheme.mono(size: 10, color: AppTheme.concrete)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _total('TOTAL', summary.total),
        _total('RECORRENTES', summary.recurring, color: AppTheme.orange),
        _total('AVULSAS', summary.single),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final MonthBookingsSummary summary;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<BookingModel> onBookingSelected;

  const _MonthGrid({
    required this.month,
    required this.summary,
    required this.onDaySelected,
    required this.onBookingSelected,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = DateTime(month.year, month.month).weekday - 1;
    final now = DateTime.now();

    // IntrinsicHeight below rules out a LayoutBuilder inside each cell.
    return LayoutBuilder(
      builder: (context, constraints) {
        final cells = <Widget>[
          for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
          for (var day = 1; day <= daysInMonth; day++)
            _DayCell(
              date: DateTime(month.year, month.month, day),
              bookings: summary.bookingsByDay[day] ?? const [],
              compact: constraints.maxWidth < _compactGridWidth,
              isToday: now.year == month.year &&
                  now.month == month.month &&
                  now.day == day,
              onTap: onDaySelected,
              onBookingTap: onBookingSelected,
            ),
        ];
        while (cells.length % 7 != 0) {
          cells.add(const SizedBox.shrink());
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  for (final label in _weekdayLabels)
                    Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: AppTheme.mono(size: 9, color: AppTheme.concrete),
                      ),
                    ),
                ],
              ),
            ),
            for (var i = 0; i < cells.length; i += 7)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final cell in cells.sublist(i, i + 7))
                      Expanded(child: cell),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final List<BookingModel> bookings;
  final bool compact;
  final bool isToday;
  final ValueChanged<DateTime> onTap;
  final ValueChanged<BookingModel> onBookingTap;

  const _DayCell({
    required this.date,
    required this.bookings,
    required this.compact,
    required this.isToday,
    required this.onTap,
    required this.onBookingTap,
  });

  @override
  Widget build(BuildContext context) {
    final maxChips = compact ? 2 : 4;
    final hidden = bookings.length - maxChips;

    return Semantics(
      button: true,
      label: '${DateFormat("d 'de' MMMM", 'pt_BR').format(date)}: '
          '${bookings.length} reservas',
      child: InkWell(
        onTap: () => onTap(date),
        child: Container(
          margin: const EdgeInsets.all(1),
          padding: const EdgeInsets.all(2),
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            border: Border.all(
              color: isToday ? AppTheme.ink : AppTheme.lineHair,
              width: isToday ? 1 : 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${date.day}',
                textAlign: TextAlign.center,
                style: AppTheme.mono(size: 10, color: AppTheme.concrete),
              ),
              for (final booking in bookings.take(maxChips))
                _BookingChip(
                  booking: booking,
                  compact: compact,
                  onTap: () => onBookingTap(booking),
                ),
              if (hidden > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '+$hidden',
                    textAlign: TextAlign.center,
                    style: AppTheme.mono(size: 9, color: AppTheme.concrete),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Calendar event: time and client. Orange marks a recurring booking.
class _BookingChip extends StatelessWidget {
  final BookingModel booking;
  final bool compact;
  final VoidCallback onTap;

  const _BookingChip({
    required this.booking,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRecurring = booking.recurrenceGroupId != null;
    final fullName = booking.userDisplayName ?? 'Cliente';
    final time = Text(
      booking.startTime ?? '',
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: AppTheme.mono(size: compact ? 8 : 10, color: AppTheme.inkSoft),
    );
    Widget name(String text) => Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.ui(
            size: compact ? 9 : 12,
            weight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        );

    return Semantics(
      button: true,
      label: '${booking.startTime ?? ''} $fullName'
          '${isRecurring ? ', recorrente' : ''}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Material(
          color: (isRecurring ? AppTheme.orange : AppTheme.ink)
              .withValues(alpha: isRecurring ? 0.14 : 0.07),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: isRecurring ? AppTheme.orange : AppTheme.ink,
                    width: 2,
                  ),
                ),
              ),
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [time, name(fullName.split(' ').first)],
                    )
                  : Row(
                      children: [
                        time,
                        const SizedBox(width: 4),
                        Expanded(child: name(fullName)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeriesRow extends StatelessWidget {
  final RecurringSeries series;

  const _SeriesRow({required this.series});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.lineHair, width: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Text(
              '${_weekdayLabels[series.weekday - 1]} ${series.startTime}',
              style: AppTheme.mono(size: 11),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                series.clientName,
                style: AppTheme.ui(size: 14, weight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${series.count}x',
              style: AppTheme.mono(size: 11, color: AppTheme.orange),
            ),
          ],
        ),
      ),
    );
  }
}

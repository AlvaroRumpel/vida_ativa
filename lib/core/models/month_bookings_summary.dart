import 'package:vida_ativa/core/models/booking_model.dart';

class RecurringSeries {
  final String clientName;
  final int weekday; // DateTime.monday..DateTime.sunday
  final String startTime;
  final int count; // Occurrences within the month

  const RecurringSeries({
    required this.clientName,
    required this.weekday,
    required this.startTime,
    required this.count,
  });
}

/// Monthly view over bookings that still hold their slot: cancelled, rejected,
/// expired and refunded bookings are ignored.
class MonthBookingsSummary {
  final Map<int, List<BookingModel>> bookingsByDay; // Sorted by startTime
  final List<RecurringSeries> series;

  const MonthBookingsSummary._(this.bookingsByDay, this.series);

  factory MonthBookingsSummary.from(List<BookingModel> bookings) {
    final bookingsByDay = <int, List<BookingModel>>{};
    final groups = <String, List<BookingModel>>{};

    for (final b in bookings) {
      if (b.isCancelled || b.isRejected || b.isExpired || b.isRefunded) continue;
      (bookingsByDay[DateTime.parse(b.date).day] ??= []).add(b);
      final groupId = b.recurrenceGroupId;
      if (groupId != null) (groups[groupId] ??= []).add(b);
    }

    for (final day in bookingsByDay.values) {
      day.sort((a, b) => (a.startTime ?? '').compareTo(b.startTime ?? ''));
    }

    final series = groups.values.map((group) {
      final first = group.first;
      return RecurringSeries(
        clientName: first.userDisplayName ?? 'Cliente',
        weekday: DateTime.parse(first.date).weekday,
        startTime: first.startTime ?? '',
        count: group.length,
      );
    }).toList()
      ..sort((a, b) {
        final byWeekday = a.weekday.compareTo(b.weekday);
        return byWeekday != 0 ? byWeekday : a.startTime.compareTo(b.startTime);
      });

    return MonthBookingsSummary._(bookingsByDay, series);
  }

  int get total =>
      bookingsByDay.values.fold(0, (sum, day) => sum + day.length);
  int get recurring => bookingsByDay.values.fold(
        0,
        (sum, day) => sum + day.where((b) => b.recurrenceGroupId != null).length,
      );
  int get single => total - recurring;
}

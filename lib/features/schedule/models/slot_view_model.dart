import 'package:equatable/equatable.dart';
import 'package:vida_ativa/core/models/slot_model.dart';

enum SlotStatus { available, booked, myBooking, blocked }

class SlotViewModel extends Equatable {
  final SlotModel slot;
  final SlotStatus status;
  final String dateString; // "YYYY-MM-DD"
  final String? bookerName; // Display name of the user who booked (null if not booked by another user)

  const SlotViewModel({
    required this.slot,
    required this.status,
    required this.dateString,
    this.bookerName,
  });

  @override
  List<Object?> get props => [slot, status, dateString, bookerName];
}

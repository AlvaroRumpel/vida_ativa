import 'package:equatable/equatable.dart';
import 'package:vida_ativa/core/models/slot_model.dart';

enum SlotStatus { available, booked, myBooking, blocked }

class SlotViewModel extends Equatable {
  final SlotModel slot;
  final SlotStatus status;
  final String dateString; // "YYYY-MM-DD"

  const SlotViewModel({
    required this.slot,
    required this.status,
    required this.dateString,
  });

  @override
  List<Object?> get props => [slot, status, dateString];
}

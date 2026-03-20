import 'package:equatable/equatable.dart';
import 'package:vida_ativa/features/schedule/models/slot_view_model.dart';

sealed class ScheduleState extends Equatable {
  const ScheduleState();
}

class ScheduleInitial extends ScheduleState {
  const ScheduleInitial();
  @override
  List<Object?> get props => [];
}

class ScheduleLoading extends ScheduleState {
  const ScheduleLoading();
  @override
  List<Object?> get props => [];
}

class ScheduleLoaded extends ScheduleState {
  final List<SlotViewModel> slots;
  final DateTime selectedDate;
  final bool isBlocked;

  const ScheduleLoaded({
    required this.slots,
    required this.selectedDate,
    this.isBlocked = false,
  });

  @override
  List<Object?> get props => [slots, selectedDate, isBlocked];
}

class ScheduleError extends ScheduleState {
  final String message;
  const ScheduleError(this.message);
  @override
  List<Object?> get props => [message];
}

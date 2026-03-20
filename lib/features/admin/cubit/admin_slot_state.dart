import 'package:equatable/equatable.dart';
import 'package:vida_ativa/core/models/slot_model.dart';

sealed class AdminSlotState extends Equatable {
  const AdminSlotState();
}

class AdminSlotInitial extends AdminSlotState {
  const AdminSlotInitial();

  @override
  List<Object?> get props => [];
}

class AdminSlotLoaded extends AdminSlotState {
  final List<SlotModel> slots;

  const AdminSlotLoaded(this.slots);

  @override
  List<Object?> get props => [slots];
}

class AdminSlotError extends AdminSlotState {
  final String message;

  const AdminSlotError(this.message);

  @override
  List<Object?> get props => [message];
}

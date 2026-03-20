import 'package:equatable/equatable.dart';
import 'package:vida_ativa/core/models/blocked_date_model.dart';

sealed class AdminBlockedDateState extends Equatable {
  const AdminBlockedDateState();
}

class AdminBlockedDateInitial extends AdminBlockedDateState {
  const AdminBlockedDateInitial();

  @override
  List<Object?> get props => [];
}

class AdminBlockedDateLoaded extends AdminBlockedDateState {
  final List<BlockedDateModel> dates;

  const AdminBlockedDateLoaded(this.dates);

  @override
  List<Object?> get props => [dates];
}

class AdminBlockedDateError extends AdminBlockedDateState {
  final String message;

  const AdminBlockedDateError(this.message);

  @override
  List<Object?> get props => [message];
}

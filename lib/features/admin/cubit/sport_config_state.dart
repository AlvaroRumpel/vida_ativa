import 'package:equatable/equatable.dart';

sealed class SportConfigState extends Equatable {
  const SportConfigState();
}

class SportConfigInitial extends SportConfigState {
  const SportConfigInitial();
  @override
  List<Object?> get props => [];
}

class SportConfigLoaded extends SportConfigState {
  final List<String> sports;
  const SportConfigLoaded(this.sports);
  @override
  List<Object?> get props => [sports];
}

class SportConfigError extends SportConfigState {
  final String message;
  const SportConfigError(this.message);
  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';
import 'package:vida_ativa/core/models/dashboard_data.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardData week;
  final DashboardData month;
  final DashboardData year;

  const DashboardLoaded({
    required this.week,
    required this.month,
    required this.year,
  });

  @override
  List<Object?> get props => [week, month, year];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

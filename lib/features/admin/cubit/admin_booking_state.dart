import 'package:equatable/equatable.dart';
import 'package:vida_ativa/core/models/booking_model.dart';

sealed class AdminBookingState extends Equatable {
  const AdminBookingState();
}

class AdminBookingInitial extends AdminBookingState {
  const AdminBookingInitial();

  @override
  List<Object?> get props => [];
}

class AdminBookingLoaded extends AdminBookingState {
  final List<BookingModel> bookings;
  final DateTime selectedDate;
  final String confirmationMode; // 'automatic' | 'manual'

  const AdminBookingLoaded(
    this.bookings, {
    required this.selectedDate,
    required this.confirmationMode,
  });

  @override
  List<Object?> get props => [bookings, selectedDate, confirmationMode];
}

class AdminBookingError extends AdminBookingState {
  final String message;

  const AdminBookingError(this.message);

  @override
  List<Object?> get props => [message];
}

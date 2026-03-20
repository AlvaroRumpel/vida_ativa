import 'package:equatable/equatable.dart';
import 'package:vida_ativa/core/models/booking_model.dart';

sealed class BookingState extends Equatable {
  const BookingState();
}

class BookingInitial extends BookingState {
  const BookingInitial();

  @override
  List<Object?> get props => [];
}

class BookingLoading extends BookingState {
  const BookingLoading();

  @override
  List<Object?> get props => [];
}

class BookingLoaded extends BookingState {
  final List<BookingModel> bookings;

  const BookingLoaded(this.bookings);

  @override
  List<Object?> get props => [bookings];
}

class BookingError extends BookingState {
  final String message;

  const BookingError(this.message);

  @override
  List<Object?> get props => [message];
}

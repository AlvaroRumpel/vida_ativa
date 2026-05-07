import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:vida_ativa/core/models/booking_model.dart';
import 'package:vida_ativa/core/models/slot_model.dart';
import 'package:vida_ativa/features/auth/cubit/auth_cubit.dart';
import 'package:vida_ativa/features/auth/cubit/auth_state.dart';
import 'package:vida_ativa/features/schedule/cubit/schedule_state.dart';
import 'package:vida_ativa/features/schedule/models/slot_view_model.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  final FirebaseFirestore _firestore;
  final AuthCubit _authCubit;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _slotsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _bookingsSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _blockedDateSubscription;

  // Cache last values from each stream for recomputation
  List<SlotModel>? _cachedSlots;
  List<BookingModel>? _cachedBookings;
  bool _cachedIsBlocked = false;
  DateTime? _selectedDate;

  // Guards against firing duplicate Firestore writes for the same booking
  final Set<String> _cancellingBookingIds = {};

  ScheduleCubit({
    required FirebaseFirestore firestore,
    required AuthCubit authCubit,
  })  : _firestore = firestore,
        _authCubit = authCubit,
        super(const ScheduleInitial());

  void selectDay(DateTime date) {
    _selectedDate = date;
    _cancelSubscriptions();
    _cachedSlots = null;
    _cachedBookings = null;
    _cachedIsBlocked = false;
    emit(const ScheduleLoading());

    final dateString = _toDateString(date);

    // Stream 1 — Active slots for this specific date
    _slotsSubscription = _firestore
        .collection('slots')
        .where('isActive', isEqualTo: true)
        .where('date', isEqualTo: dateString)
        .snapshots()
        .listen(
      (snapshot) {
        _cachedSlots =
            snapshot.docs.map((d) => SlotModel.fromFirestore(d)).toList();
        _recompute();
      },
      onError: (e, s) {
        Sentry.captureException(e, stackTrace: s);
        emit(const ScheduleError('Erro ao carregar horários.'));
      },
    );

    // Stream 2 — Non-cancelled bookings for this date
    _bookingsSubscription = _firestore
        .collection('bookings')
        .where('date', isEqualTo: dateString)
        .where('status', whereIn: ['pending', 'confirmed'])
        .snapshots()
        .listen(
      (snapshot) {
        _cachedBookings =
            snapshot.docs.map((d) => BookingModel.fromFirestore(d)).toList();
        _recompute();
      },
      onError: (e, s) {
        Sentry.captureException(e, stackTrace: s);
        emit(const ScheduleError('Erro ao carregar reservas.'));
      },
    );

    // Stream 3 — Blocked date check (single document)
    _blockedDateSubscription = _firestore
        .collection('blockedDates')
        .doc(dateString)
        .snapshots()
        .listen(
      (snapshot) {
        _cachedIsBlocked = snapshot.exists;
        _recompute();
      },
      onError: (e, s) {
        Sentry.captureException(e, stackTrace: s);
        emit(const ScheduleError('Erro ao verificar bloqueios.'));
      },
    );
  }

  void _recompute() {
    if (_cachedSlots == null ||
        _cachedBookings == null ||
        _selectedDate == null) {
      return; // Wait for all three streams to emit at least once
    }

    if (_cachedIsBlocked) {
      emit(ScheduleLoaded(
        slots: const [],
        selectedDate: _selectedDate!,
        isBlocked: true,
      ));
      return;
    }

    final currentUserId = _authCubit.state is AuthAuthenticated
        ? (_authCubit.state as AuthAuthenticated).user.uid
        : '';

    final dateString = _toDateString(_selectedDate!);

    final viewModels = _cachedSlots!.map((slot) {
      BookingModel? booking = _cachedBookings!.cast<BookingModel?>().firstWhere(
        (b) => b!.slotId == slot.id,
        orElse: () => null,
      );

      // Auto-cancel pending bookings whose slot time has already passed
      if (booking != null && booking.isPending) {
        final parts = slot.date.split('-');
        final timeParts = slot.startTime.split(':');
        final slotDateTime = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]),
          int.parse(timeParts[0]), int.parse(timeParts[1]),
        );
        if (slotDateTime.isBefore(DateTime.now()) &&
            !_cancellingBookingIds.contains(booking.id)) {
          final bookingId = booking.id;
          _cancellingBookingIds.add(bookingId);
          _firestore.collection('bookings').doc(bookingId).update({
            'status': 'cancelled',
            'cancelledAt': Timestamp.now(),
          }).then((_) => _cancellingBookingIds.remove(bookingId));
          booking = null; // Treat as available locally while update propagates
        }
      }

      final status = booking == null
          ? SlotStatus.available
          : booking.userId == currentUserId
              ? SlotStatus.myBooking
              : SlotStatus.booked;
      final bookerName = (status == SlotStatus.booked) ? booking?.userDisplayName : null;
      return SlotViewModel(
        slot: slot,
        status: status,
        dateString: dateString,
        bookerName: bookerName,
        booking: status == SlotStatus.myBooking ? booking : null,
      );
    }).toList();

    // Lexicographic sort on "HH:mm" strings is correct
    viewModels.sort((a, b) => a.slot.startTime.compareTo(b.slot.startTime));

    // Filter out slots whose time has already passed when viewing today
    final now = DateTime.now();
    final isToday = _selectedDate!.year == now.year &&
        _selectedDate!.month == now.month &&
        _selectedDate!.day == now.day;
    final filtered = isToday
        ? viewModels.where((vm) {
            final parts = vm.slot.startTime.split(':');
            final h = int.parse(parts[0]);
            final m = int.parse(parts[1]);
            return h > now.hour || (h == now.hour && m > now.minute);
          }).toList()
        : viewModels;

    emit(ScheduleLoaded(
      slots: filtered,
      selectedDate: _selectedDate!,
      isBlocked: false,
    ));
  }

  void _cancelSubscriptions() {
    _slotsSubscription?.cancel();
    _slotsSubscription = null;
    _bookingsSubscription?.cancel();
    _bookingsSubscription = null;
    _blockedDateSubscription?.cancel();
    _blockedDateSubscription = null;
  }

  String _toDateString(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}

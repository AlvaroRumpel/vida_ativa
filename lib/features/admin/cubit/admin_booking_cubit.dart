import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:vida_ativa/core/models/booking_model.dart';
import 'package:vida_ativa/features/admin/cubit/admin_booking_state.dart';

class AdminBookingCubit extends Cubit<AdminBookingState> {
  final FirebaseFirestore _firestore;
  final String _adminUid;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  String _confirmationMode = 'manual';

  AdminBookingCubit({
    required FirebaseFirestore firestore,
    required String adminUid,
  })  : _firestore = firestore,
        _adminUid = adminUid,
        super(const AdminBookingInitial()) {
    _loadConfig().then((_) {
      if (!isClosed) selectDate(DateTime.now());
    });
  }

  Future<void> _loadConfig() async {
    final configSnap =
        await _firestore.collection('config').doc('booking').get();
    _confirmationMode = configSnap.data()?['confirmationMode'] ?? 'manual';
  }

  Future<void> selectDate(DateTime date) async {
    await _sub?.cancel();
    final dateString = _toDateString(date);
    _sub = _firestore
        .collection('bookings')
        .where('date', isEqualTo: dateString)
        .snapshots()
        .listen(
      (snapshot) {
        if (isClosed) return;
        final bookings = snapshot.docs
            .map((d) => BookingModel.fromFirestore(d))
            .toList()
          ..sort((a, b) => (a.startTime ?? '').compareTo(b.startTime ?? ''));
        emit(AdminBookingLoaded(
          bookings,
          selectedDate: date,
          confirmationMode: _confirmationMode,
        ));
      },
      onError: (e, s) {
        if (isClosed) return;
        Sentry.captureException(e, stackTrace: s);
        emit(const AdminBookingError('Erro ao carregar reservas.'));
      },
    );
  }

  Future<void> confirmBooking(String bookingId) async {
    await _firestore
        .collection('bookings')
        .doc(bookingId)
        .update({'status': 'confirmed'});
  }

  Future<void> rejectBooking(String bookingId) async {
    await _firestore
        .collection('bookings')
        .doc(bookingId)
        .update({'status': 'rejected'});
  }

  Future<void> setConfirmationMode(String mode) async {
    await _firestore
        .collection('config')
        .doc('booking')
        .set({'confirmationMode': mode}, SetOptions(merge: true));
    _confirmationMode = mode;
    final current = state;
    if (current is AdminBookingLoaded) {
      emit(AdminBookingLoaded(
        current.bookings,
        selectedDate: current.selectedDate,
        confirmationMode: mode,
      ));
    }
  }

  String _toDateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // _adminUid is available for future use (e.g. audit logging)
  String get adminUid => _adminUid;

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

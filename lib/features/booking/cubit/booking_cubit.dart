import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:vida_ativa/core/models/booking_model.dart';
import 'package:vida_ativa/features/booking/cubit/booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  final FirebaseFirestore _firestore;
  final String _userId;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  BookingCubit({
    required FirebaseFirestore firestore,
    required String userId,
  })  : _firestore = firestore,
        _userId = userId,
        super(const BookingInitial()) {
    _startStream();
  }

  void _startStream() {
    emit(const BookingLoading());
    _sub = _firestore
        .collection('bookings')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .listen(
      (snapshot) {
        final bookings =
            snapshot.docs.map((d) => BookingModel.fromFirestore(d)).toList();
        emit(BookingLoaded(bookings));
      },
      onError: (e, s) {
        Sentry.captureException(e, stackTrace: s);
        emit(const BookingError('Erro ao carregar reservas.'));
      },
    );
  }

  Future<void> bookSlot({
    required String slotId,
    required String dateString,
    required double price,
    required String startTime,
    required String userDisplayName,
    String? participants,
  }) async {
    final docId = BookingModel.generateId(slotId, dateString);
    final ref = _firestore.collection('bookings').doc(docId);

    final configSnap = await _firestore.collection('config').doc('booking').get();
    final mode = configSnap.data()?['confirmationMode'] ?? 'manual';
    final initialStatus = mode == 'automatic' ? 'confirmed' : 'pending';

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
        final existing = BookingModel.fromFirestore(snap);
        if (!existing.isCancelled) throw Exception('slot_already_booked');
      }

      final booking = BookingModel(
        id: docId,
        slotId: slotId,
        date: dateString,
        userId: _userId,
        status: initialStatus,
        createdAt: DateTime.now(),
        startTime: startTime,
        price: price,
        userDisplayName: userDisplayName,
        participants: participants,
      );
      tx.set(ref, booking.toFirestore());
    });
    // Stream subscription picks up the new booking reactively — no state emit here.
  }

  Future<void> cancelBooking(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': 'cancelled',
      'cancelledAt': Timestamp.fromDate(DateTime.now()),
    });
    // Stream subscription picks up the change reactively — no state emit here.
  }

  Future<void> updateParticipants(String bookingId, String? participants) async {
    final data = participants != null && participants.isNotEmpty
        ? {'participants': participants}
        : {'participants': FieldValue.delete()};
    await _firestore.collection('bookings').doc(bookingId).update(data);
    // Stream subscription picks up the change reactively — no state emit here.
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

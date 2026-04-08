import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';

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
    required String paymentMethod, // 'pix' | 'on_arrival'
    String? participants,
    String? recurrenceGroupId,
  }) async {
    // Guard: prevent booking a slot that has already passed today
    final now = DateTime.now();
    final todayString =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (dateString == todayString) {
      final parts = startTime.split(':');
      final slotDt = DateTime(
        now.year, now.month, now.day,
        int.parse(parts[0]), int.parse(parts[1]),
      );
      if (slotDt.isBefore(now)) throw Exception('slot_already_passed');
    }

    final docId = BookingModel.generateId(slotId, dateString);
    final ref = _firestore.collection('bookings').doc(docId);

    // Payment method determines initial status:
    // - 'pix': always pending_payment (slot blocked, QR will be generated next)
    // - 'on_arrival': always confirmed (payment happens in person, no QR needed)
    // confirmationMode is bypassed for Pix — webhook (Phase 18) handles confirmation.
    final initialStatus =
        paymentMethod == 'on_arrival' ? 'confirmed' : 'pending_payment';

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
        recurrenceGroupId: recurrenceGroupId,
        paymentMethod: paymentMethod, // NEW
      );
      tx.set(ref, booking.toFirestore());
    });
    // Stream subscription picks up the new booking reactively — no state emit here.
  }

  /// Creates multiple bookings in parallel under a shared recurrenceGroupId.
  /// Each booking is created with the existing bookSlot transaction pattern.
  /// Per-element try/catch ensures partial failures don't cancel other bookings.
  /// Returns a list of outcomes (success + failures) for the result sheet.
  Future<List<RecurrenceOutcome>> bookRecurring({
    required List<RecurrenceEntry> entries,
    required String startTime,
    required String userDisplayName,
    required String paymentMethod, // NEW
    String? participants,
  }) async {
    final groupId = const Uuid().v4();

    final settled = await Future.wait(
      entries.map((entry) async {
        try {
          await bookSlot(
            slotId: entry.slotId,
            dateString: entry.dateString,
            price: entry.price,
            startTime: startTime,
            userDisplayName: userDisplayName,
            participants: participants,
            recurrenceGroupId: groupId,
            paymentMethod: paymentMethod, // NEW
          );
          return RecurrenceOutcome.success(entry.dateString);
        } on Exception catch (e) {
          final msg = e.toString();
          final reason = msg.contains('slot_already_booked')
              ? 'slot_already_booked'
              : msg.contains('slot_already_passed')
                  ? 'slot_already_passed'
                  : msg;
          return RecurrenceOutcome.failed(entry.dateString, reason);
        }
      }),
    );
    return settled;
  }

  Future<void> cancelBooking(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': 'cancelled',
      'cancelledAt': Timestamp.fromDate(DateTime.now()),
    });
    // Stream subscription picks up the change reactively — no state emit here.
  }

  /// Batch-cancels all bookings in a recurrence group dated on or after [fromDateInclusive].
  /// Uses Firestore WriteBatch for atomic commit of all cancellations.
  /// Safety: filters by userId so user can only cancel their own bookings.
  Future<void> cancelGroupFuture({
    required String recurrenceGroupId,
    required String fromDateInclusive, // "YYYY-MM-DD"
  }) async {
    final snap = await _firestore
        .collection('bookings')
        .where('recurrenceGroupId', isEqualTo: recurrenceGroupId)
        .where('date', isGreaterThanOrEqualTo: fromDateInclusive)
        .get();

    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {
        'status': 'cancelled',
        'cancelledAt': Timestamp.fromDate(DateTime.now()),
      });
    }
    await batch.commit();
    // Stream subscription picks up the changes reactively — no state emit here.
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

/// Data class for a single booking entry in a recurring batch.
class RecurrenceEntry {
  final String slotId;
  final String dateString;
  final double price;

  const RecurrenceEntry({
    required this.slotId,
    required this.dateString,
    required this.price,
  });
}

/// Result of a single recurring booking attempt.
class RecurrenceOutcome {
  final String dateString;
  final bool success;
  final String? failureReason; // "slot_already_booked" | "slot_already_passed" | other

  const RecurrenceOutcome._({
    required this.dateString,
    required this.success,
    this.failureReason,
  });

  factory RecurrenceOutcome.success(String dateString) =>
      RecurrenceOutcome._(dateString: dateString, success: true);

  factory RecurrenceOutcome.failed(String dateString, String reason) =>
      RecurrenceOutcome._(dateString: dateString, success: false, failureReason: reason);
}

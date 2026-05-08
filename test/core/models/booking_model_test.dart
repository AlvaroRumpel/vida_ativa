import 'package:flutter_test/flutter_test.dart';
import 'package:vida_ativa/core/models/booking_model.dart';

BookingModel _make({
  String status = 'pending',
  String? paymentMethod,
}) =>
    BookingModel(
      id: 'slot1_2026-05-08',
      slotId: 'slot1',
      date: '2026-05-08',
      userId: 'user1',
      status: status,
      createdAt: DateTime(2026, 5, 8),
      paymentMethod: paymentMethod,
    );

void main() {
  group('BookingModel.generateId', () {
    test('produces {slotId}_{date}', () {
      expect(BookingModel.generateId('slot1', '2026-05-08'), 'slot1_2026-05-08');
    });
  });

  group('status getters', () {
    test('isPending true for pending', () {
      expect(_make(status: 'pending').isPending, isTrue);
    });

    test('isConfirmed true for confirmed', () {
      expect(_make(status: 'confirmed').isConfirmed, isTrue);
    });

    test('isCancelled true for cancelled', () {
      expect(_make(status: 'cancelled').isCancelled, isTrue);
    });

    test('isPendingPayment true for pending_payment, false for pending', () {
      expect(_make(status: 'pending_payment').isPendingPayment, isTrue);
      expect(_make(status: 'pending').isPendingPayment, isFalse);
    });

    test('isExpired true for expired', () {
      expect(_make(status: 'expired').isExpired, isTrue);
    });
  });

  group('isOnArrival', () {
    test('true when confirmed + on_arrival', () {
      expect(
        _make(status: 'confirmed', paymentMethod: 'on_arrival').isOnArrival,
        isTrue,
      );
    });

    test('false when pending_payment + on_arrival (not confirmed)', () {
      expect(
        _make(status: 'pending_payment', paymentMethod: 'on_arrival').isOnArrival,
        isFalse,
      );
    });

    test('false when confirmed + pix', () {
      expect(
        _make(status: 'confirmed', paymentMethod: 'pix').isOnArrival,
        isFalse,
      );
    });
  });
}

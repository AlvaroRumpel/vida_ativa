import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vida_ativa/core/models/booking_model.dart';

class _FakeDoc extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic> _data;
  _FakeDoc(this._id, this._data);
  @override
  String get id => _id;
  @override
  Map<String, dynamic>? data() => _data;
  @override
  bool get exists => true;
}

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

  group('isRejected / isRefunded', () {
    test('isRejected true for rejected', () {
      expect(_make(status: 'rejected').isRejected, isTrue);
    });

    test('isRejected false for pending', () {
      expect(_make(status: 'pending').isRejected, isFalse);
    });

    test('isRefunded true for refunded', () {
      expect(_make(status: 'refunded').isRefunded, isTrue);
    });
  });

  group('fromFirestore', () {
    final createdAt = DateTime(2026, 5, 8, 10, 0);

    test('maps required fields', () {
      final doc = _FakeDoc('slot1_2026-05-08', {
        'slotId': 'slot1',
        'date': '2026-05-08',
        'userId': 'user1',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(createdAt),
      });

      final model = BookingModel.fromFirestore(doc);

      expect(model.id, 'slot1_2026-05-08');
      expect(model.slotId, 'slot1');
      expect(model.date, '2026-05-08');
      expect(model.userId, 'user1');
      expect(model.status, 'pending');
      expect(model.createdAt, createdAt);
      expect(model.price, isNull);
      expect(model.paymentMethod, isNull);
    });

    test('maps optional fields when present', () {
      final expiresAt = DateTime(2026, 5, 8, 10, 30);
      final doc = _FakeDoc('slot1_2026-05-08', {
        'slotId': 'slot1',
        'date': '2026-05-08',
        'userId': 'user1',
        'status': 'pending_payment',
        'createdAt': Timestamp.fromDate(createdAt),
        'startTime': '10:00',
        'price': 60,
        'userDisplayName': 'João',
        'participants': 'João, Maria',
        'recurrenceGroupId': 'grp1',
        'paymentMethod': 'pix',
        'expiresAt': Timestamp.fromDate(expiresAt),
        'paymentId': 'mp_tx_123',
      });

      final model = BookingModel.fromFirestore(doc);

      expect(model.startTime, '10:00');
      expect(model.price, 60.0);
      expect(model.userDisplayName, 'João');
      expect(model.participants, 'João, Maria');
      expect(model.recurrenceGroupId, 'grp1');
      expect(model.paymentMethod, 'pix');
      expect(model.expiresAt, expiresAt);
      expect(model.paymentId, 'mp_tx_123');
    });

    test('price parsed as double when stored as int', () {
      final doc = _FakeDoc('s_d', {
        'slotId': 's',
        'date': 'd',
        'userId': 'u',
        'status': 'confirmed',
        'createdAt': Timestamp.fromDate(createdAt),
        'price': 50, // int in Firestore
      });

      expect(BookingModel.fromFirestore(doc).price, 50.0);
      expect(BookingModel.fromFirestore(doc).price, isA<double>());
    });
  });

  group('toFirestore', () {
    test('includes required fields', () {
      final model = _make();
      final map = model.toFirestore();

      expect(map['slotId'], 'slot1');
      expect(map['date'], '2026-05-08');
      expect(map['userId'], 'user1');
      expect(map['status'], 'pending');
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('omits null optional fields', () {
      final map = _make().toFirestore();

      expect(map.containsKey('cancelledAt'), isFalse);
      expect(map.containsKey('startTime'), isFalse);
      expect(map.containsKey('price'), isFalse);
      expect(map.containsKey('paymentMethod'), isFalse);
    });

    test('includes optional fields when set', () {
      final model = BookingModel(
        id: 'slot1_2026-05-08',
        slotId: 'slot1',
        date: '2026-05-08',
        userId: 'user1',
        status: 'confirmed',
        createdAt: DateTime(2026, 5, 8),
        startTime: '10:00',
        price: 60.0,
        paymentMethod: 'on_arrival',
        userDisplayName: 'João',
      );

      final map = model.toFirestore();

      expect(map['startTime'], '10:00');
      expect(map['price'], 60.0);
      expect(map['paymentMethod'], 'on_arrival');
      expect(map['userDisplayName'], 'João');
    });
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vida_ativa/core/models/slot_model.dart';

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

void main() {
  group('SlotModel.fromFirestore', () {
    test('maps all fields', () {
      final doc = _FakeDoc('slot_abc', {
        'date': '2026-05-08',
        'startTime': '08:00',
        'price': 60.0,
        'isActive': true,
      });

      final slot = SlotModel.fromFirestore(doc);

      expect(slot.id, 'slot_abc');
      expect(slot.date, '2026-05-08');
      expect(slot.startTime, '08:00');
      expect(slot.price, 60.0);
      expect(slot.isActive, isTrue);
    });

    test('parses int price as double', () {
      final doc = _FakeDoc('s', {
        'date': '2026-05-08',
        'startTime': '09:00',
        'price': 50, // int stored in Firestore
        'isActive': false,
      });

      expect(SlotModel.fromFirestore(doc).price, 50.0);
      expect(SlotModel.fromFirestore(doc).price, isA<double>());
    });
  });

  group('SlotModel.toFirestore', () {
    test('round-trip preserves all fields', () {
      const slot = SlotModel(
        id: 'slot_xyz',
        date: '2026-06-01',
        startTime: '10:00',
        price: 75.0,
        isActive: true,
      );

      final map = slot.toFirestore();

      expect(map['date'], '2026-06-01');
      expect(map['startTime'], '10:00');
      expect(map['price'], 75.0);
      expect(map['isActive'], isTrue);
      expect(map.containsKey('id'), isFalse);
    });
  });

  group('SlotModel Equatable', () {
    test('equal when all fields match', () {
      const a = SlotModel(
        id: 'slot1',
        date: '2026-05-08',
        startTime: '08:00',
        price: 60.0,
        isActive: true,
      );
      const b = SlotModel(
        id: 'slot1',
        date: '2026-05-08',
        startTime: '08:00',
        price: 60.0,
        isActive: true,
      );
      expect(a, equals(b));
    });

    test('not equal when price differs', () {
      const a = SlotModel(
        id: 'slot1',
        date: '2026-05-08',
        startTime: '08:00',
        price: 60.0,
        isActive: true,
      );
      const b = SlotModel(
        id: 'slot1',
        date: '2026-05-08',
        startTime: '08:00',
        price: 70.0,
        isActive: true,
      );
      expect(a, isNot(equals(b)));
    });
  });
}

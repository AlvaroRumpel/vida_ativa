import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vida_ativa/core/models/price_tier_model.dart';

class _FakeDoc extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic>? _data;
  _FakeDoc(this._data);
  @override
  String get id => 'pricing';
  @override
  Map<String, dynamic>? data() => _data;
  @override
  bool get exists => _data != null;
}

void main() {
  group('PriceTierModel.fromMap', () {
    test('parses all fields including daysOfWeek', () {
      final tier = PriceTierModel.fromMap({
        'daysOfWeek': [1, 6, 7],
        'fromHour': 8,
        'toHour': 12,
        'price': 60.0,
      });

      expect(tier.daysOfWeek, [1, 6, 7]);
      expect(tier.fromHour, 8);
      expect(tier.toHour, 12);
      expect(tier.price, 60.0);
    });

    test('defaults daysOfWeek to empty list when absent', () {
      final tier = PriceTierModel.fromMap({
        'fromHour': 8,
        'toHour': 18,
        'price': 50.0,
      });

      expect(tier.daysOfWeek, isEmpty);
    });
  });

  group('PriceTierModel.toMap', () {
    test('round-trip is idempotent', () {
      final original = PriceTierModel(
        daysOfWeek: [1, 2, 3],
        fromHour: 9,
        toHour: 17,
        price: 75.0,
      );

      final restored = PriceTierModel.fromMap(original.toMap());

      expect(restored.daysOfWeek, original.daysOfWeek);
      expect(restored.fromHour, original.fromHour);
      expect(restored.toHour, original.toHour);
      expect(restored.price, original.price);
    });
  });

  group('PriceTierModel.listFromFirestore', () {
    test('returns list of tiers from doc data', () {
      final doc = _FakeDoc({
        'tiers': [
          {'daysOfWeek': [1, 2], 'fromHour': 8, 'toHour': 12, 'price': 60.0},
          {'daysOfWeek': [], 'fromHour': 12, 'toHour': 18, 'price': 50.0},
        ],
      });

      final tiers = PriceTierModel.listFromFirestore(doc);

      expect(tiers.length, 2);
      expect(tiers[0].price, 60.0);
      expect(tiers[1].fromHour, 12);
    });

    test('returns empty list when tiers key absent', () {
      final doc = _FakeDoc({});
      expect(PriceTierModel.listFromFirestore(doc), isEmpty);
    });

    test('returns empty list when doc data is null', () {
      final doc = _FakeDoc(null);
      expect(PriceTierModel.listFromFirestore(doc), isEmpty);
    });
  });
}

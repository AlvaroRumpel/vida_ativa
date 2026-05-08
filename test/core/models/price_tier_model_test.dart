import 'package:flutter_test/flutter_test.dart';
import 'package:vida_ativa/core/models/price_tier_model.dart';

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
}

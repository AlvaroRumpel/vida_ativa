import 'package:cloud_firestore/cloud_firestore.dart';

class PriceTierModel {
  final List<int> daysOfWeek; // [] = all days; 1=Mon … 7=Sun
  final int fromHour; // inclusive
  final int toHour; // exclusive
  final double price;

  const PriceTierModel({
    this.daysOfWeek = const [],
    required this.fromHour,
    required this.toHour,
    required this.price,
  });

  factory PriceTierModel.fromMap(Map<String, dynamic> map) {
    return PriceTierModel(
      daysOfWeek: (map['daysOfWeek'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
      fromHour: (map['fromHour'] as num).toInt(),
      toHour: (map['toHour'] as num).toInt(),
      price: (map['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'daysOfWeek': daysOfWeek,
        'fromHour': fromHour,
        'toHour': toHour,
        'price': price,
      };

  static List<PriceTierModel> listFromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return [];
    final tiers = data['tiers'] as List<dynamic>? ?? [];
    return tiers
        .map((t) => PriceTierModel.fromMap(t as Map<String, dynamic>))
        .toList();
  }
}

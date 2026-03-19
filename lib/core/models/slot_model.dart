import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class SlotModel extends Equatable {
  final String id;
  final int dayOfWeek; // 1=Monday..7=Sunday (Dart DateTime.weekday convention)
  final String startTime; // "HH:mm" format, e.g. "08:00"
  final double price;
  final bool isActive;

  const SlotModel({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.price,
    required this.isActive,
  });

  factory SlotModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SlotModel(
      id: doc.id,
      dayOfWeek: data['dayOfWeek'] as int,
      startTime: data['startTime'] as String,
      price: (data['price'] as num).toDouble(),
      isActive: data['isActive'] as bool,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'price': price,
      'isActive': isActive,
    };
  }

  @override
  List<Object?> get props => [id, dayOfWeek, startTime, price, isActive];
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class BookingModel extends Equatable {
  final String id; // Deterministic: "{slotId}_{date}"
  final String slotId;
  final String date; // "YYYY-MM-DD" format
  final String userId;
  final String status; // "pending" | "confirmed" | "cancelled"
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final String? startTime; // "HH:mm" — stored at booking time for display
  final double? price; // Stored at booking time for display

  const BookingModel({
    required this.id,
    required this.slotId,
    required this.date,
    required this.userId,
    required this.status,
    required this.createdAt,
    this.cancelledAt,
    this.startTime,
    this.price,
  });

  /// Generates the deterministic document ID for anti-double-booking.
  /// Always use this instead of Firestore auto-generated IDs.
  static String generateId(String slotId, String date) => '${slotId}_$date';

  factory BookingModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return BookingModel(
      id: doc.id,
      slotId: data['slotId'] as String,
      date: data['date'] as String,
      userId: data['userId'] as String,
      status: data['status'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
      startTime: data['startTime'] as String?,
      price: data['price'] != null ? (data['price'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'slotId': slotId,
      'date': date,
      'userId': userId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (cancelledAt != null) 'cancelledAt': Timestamp.fromDate(cancelledAt!),
      if (startTime != null) 'startTime': startTime,
      if (price != null) 'price': price,
    };
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';

  @override
  List<Object?> get props => [id, slotId, date, userId, status, createdAt, cancelledAt, startTime, price];
}

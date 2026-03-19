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

  const BookingModel({
    required this.id,
    required this.slotId,
    required this.date,
    required this.userId,
    required this.status,
    required this.createdAt,
    this.cancelledAt,
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
    };
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';

  @override
  List<Object?> get props => [id, slotId, date, userId, status, createdAt, cancelledAt];
}

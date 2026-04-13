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
  final String? userDisplayName; // Stored at booking time for admin display
  final String? participants; // Optional list of participant names (free-text)
  final String? recurrenceGroupId;
  final String? paymentMethod; // 'pix' | 'on_arrival' | null
  final DateTime? expiresAt;   // Timestamp Firestore; so para Pix
  final String? paymentId;     // txId Mercado Pago; so para Pix

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
    this.userDisplayName,
    this.participants,
    this.recurrenceGroupId,
    this.paymentMethod,
    this.expiresAt,
    this.paymentId,
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
      userDisplayName: data['userDisplayName'] as String?,
      participants: data['participants'] as String?,
      recurrenceGroupId: data['recurrenceGroupId'] as String?,
      paymentMethod: data['paymentMethod'] as String?,
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      paymentId: data['paymentId'] as String?,
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
      if (userDisplayName != null) 'userDisplayName': userDisplayName,
      if (participants != null) 'participants': participants,
      if (recurrenceGroupId != null) 'recurrenceGroupId': recurrenceGroupId,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      if (paymentId != null) 'paymentId': paymentId,
    };
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
  bool get isRejected => status == 'rejected';
  bool get isPendingPayment => status == 'pending_payment';
  bool get isExpired => status == 'expired';
  bool get isRefunded => status == 'refunded';
  // NOTE: isOnArrival checks both confirmed status AND on_arrival method
  // because on_arrival bookings go directly to 'confirmed'
  bool get isOnArrival => isConfirmed && paymentMethod == 'on_arrival';

  @override
  List<Object?> get props => [id, slotId, date, userId, status, createdAt,
      cancelledAt, startTime, price, userDisplayName, participants,
      recurrenceGroupId, paymentMethod, expiresAt, paymentId];
}

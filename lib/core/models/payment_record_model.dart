import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a payment record stored in /bookings/{bookingId}/payment/{txId}.
/// Document ID = Mercado Pago transaction ID (used as idempotency key in Phase 18 webhook).
class PaymentRecordModel extends Equatable {
  final String id;           // txId from Mercado Pago (document ID)
  final String qrCode;       // copia-e-cola Pix string
  final String qrCodeBase64; // base64 QR image (decoded with Image.memory)
  final DateTime expiresAt;
  final String status;       // 'pending' | 'paid' | 'expired'
  final DateTime? createdAt;

  const PaymentRecordModel({
    required this.id,
    required this.qrCode,
    required this.qrCodeBase64,
    required this.expiresAt,
    required this.status,
    this.createdAt,
  });

  factory PaymentRecordModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PaymentRecordModel(
      id: doc.id,
      qrCode: data['qrCode'] as String,
      qrCodeBase64: data['qrCodeBase64'] as String,
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      status: data['status'] as String,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  @override
  List<Object?> get props =>
      [id, qrCode, qrCodeBase64, expiresAt, status, createdAt];
}

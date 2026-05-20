import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vida_ativa/core/models/payment_record_model.dart';

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
  final expiresAt = DateTime(2026, 5, 8, 11, 0);
  final createdAt = DateTime(2026, 5, 8, 10, 0);

  group('PaymentRecordModel.fromFirestore', () {
    test('maps all fields including Timestamps', () {
      final doc = _FakeDoc('tx_123', {
        'qrCode': 'pix_copia_cola_string',
        'qrCodeBase64': 'base64imgdata==',
        'expiresAt': Timestamp.fromDate(expiresAt),
        'status': 'pending',
        'createdAt': Timestamp.fromDate(createdAt),
      });

      final model = PaymentRecordModel.fromFirestore(doc);

      expect(model.id, 'tx_123');
      expect(model.qrCode, 'pix_copia_cola_string');
      expect(model.qrCodeBase64, 'base64imgdata==');
      expect(model.expiresAt, expiresAt);
      expect(model.status, 'pending');
      expect(model.createdAt, createdAt);
    });

    test('createdAt is null when absent', () {
      final doc = _FakeDoc('tx_456', {
        'qrCode': 'qr',
        'qrCodeBase64': 'b64',
        'expiresAt': Timestamp.fromDate(expiresAt),
        'status': 'paid',
      });

      expect(PaymentRecordModel.fromFirestore(doc).createdAt, isNull);
    });

    test('uses doc.id as model id', () {
      final doc = _FakeDoc('mp_tx_789', {
        'qrCode': 'qr',
        'qrCodeBase64': 'b64',
        'expiresAt': Timestamp.fromDate(expiresAt),
        'status': 'expired',
      });

      expect(PaymentRecordModel.fromFirestore(doc).id, 'mp_tx_789');
    });
  });
}

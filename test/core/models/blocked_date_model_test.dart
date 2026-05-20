import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vida_ativa/core/models/blocked_date_model.dart';

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
  group('BlockedDateModel.fromFirestore', () {
    test('uses doc.id as date field', () {
      final doc = _FakeDoc('2026-05-10', {'createdBy': 'admin_uid'});
      final model = BlockedDateModel.fromFirestore(doc);

      expect(model.date, '2026-05-10');
      expect(model.createdBy, 'admin_uid');
    });
  });

  group('BlockedDateModel.toFirestore', () {
    test('includes date and createdBy', () {
      const model = BlockedDateModel(date: '2026-05-10', createdBy: 'admin_uid');
      final map = model.toFirestore();

      expect(map['date'], '2026-05-10');
      expect(map['createdBy'], 'admin_uid');
    });
  });

  group('BlockedDateModel Equatable', () {
    test('equal when date and createdBy match', () {
      const a = BlockedDateModel(date: '2026-05-10', createdBy: 'admin_uid');
      const b = BlockedDateModel(date: '2026-05-10', createdBy: 'admin_uid');
      expect(a, equals(b));
    });

    test('not equal when date differs', () {
      const a = BlockedDateModel(date: '2026-05-10', createdBy: 'admin_uid');
      const b = BlockedDateModel(date: '2026-05-11', createdBy: 'admin_uid');
      expect(a, isNot(equals(b)));
    });
  });
}

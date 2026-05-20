import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vida_ativa/core/models/user_model.dart';

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
  group('UserModel.fromFirestore', () {
    test('maps all fields including optional phone', () {
      final doc = _FakeDoc('uid1', {
        'email': 'test@example.com',
        'displayName': 'João Silva',
        'role': 'client',
        'phone': '(11) 91234-5678',
      });

      final user = UserModel.fromFirestore(doc);

      expect(user.uid, 'uid1');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'João Silva');
      expect(user.role, 'client');
      expect(user.phone, '(11) 91234-5678');
    });

    test('phone is null when absent from doc', () {
      final doc = _FakeDoc('uid2', {
        'email': 'a@b.com',
        'displayName': 'Maria',
        'role': 'admin',
      });

      expect(UserModel.fromFirestore(doc).phone, isNull);
    });

    test('uses doc.id as uid', () {
      final doc = _FakeDoc('my-uid', {
        'email': 'x@y.com',
        'displayName': 'X',
        'role': 'client',
      });

      expect(UserModel.fromFirestore(doc).uid, 'my-uid');
    });
  });

  group('UserModel.toFirestore', () {
    test('includes all fields when phone set', () {
      const user = UserModel(
        uid: 'uid1',
        email: 'a@b.com',
        displayName: 'Ana',
        role: 'client',
        phone: '(11) 99999-9999',
      );

      final map = user.toFirestore();

      expect(map['email'], 'a@b.com');
      expect(map['displayName'], 'Ana');
      expect(map['role'], 'client');
      expect(map['phone'], '(11) 99999-9999');
      expect(map.containsKey('uid'), isFalse);
    });

    test('omits phone when null', () {
      const user = UserModel(
        uid: 'uid1',
        email: 'a@b.com',
        displayName: 'Ana',
        role: 'client',
      );

      expect(user.toFirestore().containsKey('phone'), isFalse);
    });
  });

  group('UserModel.isAdmin', () {
    test('true for admin role', () {
      const user = UserModel(
        uid: 'u',
        email: 'e',
        displayName: 'd',
        role: 'admin',
      );
      expect(user.isAdmin, isTrue);
    });

    test('false for client role', () {
      const user = UserModel(
        uid: 'u',
        email: 'e',
        displayName: 'd',
        role: 'client',
      );
      expect(user.isAdmin, isFalse);
    });
  });
}

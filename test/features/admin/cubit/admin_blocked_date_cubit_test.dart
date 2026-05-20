import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vida_ativa/features/admin/cubit/admin_blocked_date_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/admin_blocked_date_state.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────────
class _FakeQDocSnapshot extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic> _data;
  _FakeQDocSnapshot(this._id, this._data);
  @override
  String get id => _id;
  @override
  Map<String, dynamic> data() => _data;
  @override
  bool get exists => true;
}

class _FakeQuerySnapshot extends Fake
    implements QuerySnapshot<Map<String, dynamic>> {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs;
  _FakeQuerySnapshot([this._docs = const []]);
  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => _docs;
}

class _FakeDocRef extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  final String _id;
  Map<String, dynamic>? _data;
  bool _deleted = false;

  _FakeDocRef(this._id);

  @override
  String get id => _id;

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    _data = data;
  }

  @override
  Future<void> delete() async {
    _deleted = true;
    _data = null;
  }
}

class _FakeCollRef extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  final Map<String, _FakeDocRef> _docs;

  _FakeCollRef({
    required Stream<QuerySnapshot<Map<String, dynamic>>> stream,
    Map<String, _FakeDocRef>? docs,
  })  : _stream = stream,
        _docs = docs ?? {};

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) =>
      _stream;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _docs[path] ?? _FakeDocRef(path ?? '');
}

class _FakeFirestore extends Fake implements FirebaseFirestore {
  final _FakeCollRef _coll;
  _FakeFirestore(this._coll);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) => _coll;
}

// ─── Tests ────────────────────────────────────────────────────────────────────
void main() {
  group('AdminBlockedDateCubit stream', () {
    test('emits AdminBlockedDateLoaded with sorted dates on snapshot', () async {
      final ctrl =
          StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
      final docRef1 = _FakeDocRef('2026-05-10');
      final docRef2 = _FakeDocRef('2026-05-08');
      final coll = _FakeCollRef(
        stream: ctrl.stream,
        docs: {'2026-05-10': docRef1, '2026-05-08': docRef2},
      );
      final cubit = AdminBlockedDateCubit(firestore: _FakeFirestore(coll));

      ctrl.add(_FakeQuerySnapshot([
        _FakeQDocSnapshot('2026-05-10', {'createdBy': 'admin1'}),
        _FakeQDocSnapshot('2026-05-08', {'createdBy': 'admin1'}),
      ]));
      await pumpEventQueue();

      final state = cubit.state as AdminBlockedDateLoaded;
      expect(state.dates.length, 2);
      // Sorted ascending by date
      expect(state.dates[0].date, '2026-05-08');
      expect(state.dates[1].date, '2026-05-10');

      await cubit.close();
      await ctrl.close();
    });
  });

  group('AdminBlockedDateCubit.blockDate', () {
    test('sets document in Firestore with date and createdBy', () async {
      final ctrl =
          StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
      final docRef = _FakeDocRef('2026-05-15');
      final coll = _FakeCollRef(
        stream: ctrl.stream,
        docs: {'2026-05-15': docRef},
      );
      final cubit = AdminBlockedDateCubit(firestore: _FakeFirestore(coll));

      await cubit.blockDate('2026-05-15', 'admin_uid');

      expect(docRef._data, isNotNull);
      expect(docRef._data!['createdBy'], 'admin_uid');
      expect(docRef._data!['date'], '2026-05-15');

      await cubit.close();
      await ctrl.close();
    });
  });

  group('AdminBlockedDateCubit.unblockDate', () {
    test('deletes document from Firestore', () async {
      final ctrl =
          StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
      final docRef = _FakeDocRef('2026-05-15');
      final coll = _FakeCollRef(
        stream: ctrl.stream,
        docs: {'2026-05-15': docRef},
      );
      final cubit = AdminBlockedDateCubit(firestore: _FakeFirestore(coll));

      await cubit.unblockDate('2026-05-15');

      expect(docRef._deleted, isTrue);

      await cubit.close();
      await ctrl.close();
    });
  });
}

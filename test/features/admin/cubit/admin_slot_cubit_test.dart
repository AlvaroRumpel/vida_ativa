import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vida_ativa/features/admin/cubit/admin_slot_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/admin_slot_state.dart';

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
  bool _deleted = false;
  final List<Map<Object, Object?>> updates = [];

  _FakeDocRef(this._id);

  @override
  String get id => _id;

  @override
  Future<void> update(Map<Object, Object?> data) async => updates.add(data);

  @override
  Future<void> delete() async => _deleted = true;

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {}
}

class _FakeQuery extends Fake implements Query<Map<String, dynamic>> {
  final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  final Future<QuerySnapshot<Map<String, dynamic>>>? _getFuture;
  _FakeQuery(this._stream, [this._getFuture]);

  @override
  Query<Map<String, dynamic>> where(Object field,
          {Object? isEqualTo,
          Object? isNotEqualTo,
          Object? isLessThan,
          Object? isLessThanOrEqualTo,
          Object? isGreaterThan,
          Object? isGreaterThanOrEqualTo,
          Object? arrayContains,
          Iterable<Object?>? arrayContainsAny,
          Iterable<Object?>? whereIn,
          Iterable<Object?>? whereNotIn,
          bool? isNull}) =>
      this;

  @override
  Query<Map<String, dynamic>> limit(int limit) => this;

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) =>
      _stream;

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) =>
      _getFuture ?? Future.value(_FakeQuerySnapshot());
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
  Query<Map<String, dynamic>> where(Object field,
          {Object? isEqualTo,
          Object? isNotEqualTo,
          Object? isLessThan,
          Object? isLessThanOrEqualTo,
          Object? isGreaterThan,
          Object? isGreaterThanOrEqualTo,
          Object? arrayContains,
          Iterable<Object?>? arrayContainsAny,
          Iterable<Object?>? whereIn,
          Iterable<Object?>? whereNotIn,
          bool? isNull}) =>
      _FakeQuery(_stream);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _docs[path] ?? _FakeDocRef(path ?? 'auto');

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(
      Map<String, dynamic> data) async =>
      _FakeDocRef('auto_${data.hashCode}');
}

class _FakeFirestore extends Fake implements FirebaseFirestore {
  final Map<String, _FakeCollRef> _collections;
  _FakeFirestore(this._collections);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _collections[path] ??
      _FakeCollRef(stream: const Stream.empty());

  @override
  WriteBatch batch() => _FakeWriteBatch();
}

class _FakeWriteBatch extends Fake implements WriteBatch {
  int setCalls = 0;
  @override
  void set<T extends Object?>(
      DocumentReference<T> document, T data,
      [SetOptions? options]) =>
      setCalls++;

  @override
  Future<void> commit() async {}
}

// ─── Tests ────────────────────────────────────────────────────────────────────
void main() {
  group('AdminSlotCubit stream', () {
    test('emits AdminSlotLoaded with sorted slots on snapshot', () async {
      final ctrl =
          StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
      final firestore = _FakeFirestore({
        'slots': _FakeCollRef(stream: ctrl.stream),
      });

      final cubit = AdminSlotCubit(firestore: firestore);

      ctrl.add(_FakeQuerySnapshot([
        _FakeQDocSnapshot('s2', {
          'date': '2026-05-09',
          'startTime': '08:00',
          'price': 60.0,
          'isActive': true,
        }),
        _FakeQDocSnapshot('s1', {
          'date': '2026-05-08',
          'startTime': '10:00',
          'price': 60.0,
          'isActive': true,
        }),
      ]));
      await pumpEventQueue();

      final state = cubit.state as AdminSlotLoaded;
      expect(state.slots.length, 2);
      expect(state.slots[0].date, '2026-05-08'); // sorted by date
      expect(state.slots[1].date, '2026-05-09');

      await cubit.close();
      await ctrl.close();
    });
  });

  group('AdminSlotCubit.updateSlot', () {
    test('updates date, startTime, price on Firestore doc', () async {
      final docRef = _FakeDocRef('slot_abc');
      final firestore = _FakeFirestore({
        'slots': _FakeCollRef(
          stream: const Stream.empty(),
          docs: {'slot_abc': docRef},
        ),
      });

      final cubit = AdminSlotCubit(firestore: firestore);
      await cubit.updateSlot(
        'slot_abc',
        date: '2026-06-01',
        startTime: '09:00',
        price: 75.0,
      );

      expect(docRef.updates, isNotEmpty);
      expect(docRef.updates.first['date'], '2026-06-01');
      expect(docRef.updates.first['startTime'], '09:00');
      expect(docRef.updates.first['price'], 75.0);

      await cubit.close();
    });
  });

  group('AdminSlotCubit.deleteSlot', () {
    test('deletes Firestore doc', () async {
      final docRef = _FakeDocRef('slot_xyz');
      final firestore = _FakeFirestore({
        'slots': _FakeCollRef(
          stream: const Stream.empty(),
          docs: {'slot_xyz': docRef},
        ),
      });

      final cubit = AdminSlotCubit(firestore: firestore);
      await cubit.deleteSlot('slot_xyz');

      expect(docRef._deleted, isTrue);
      await cubit.close();
    });
  });

  group('AdminSlotCubit.setSlotActive', () {
    test('updates isActive to false', () async {
      final docRef = _FakeDocRef('slot_abc');
      final firestore = _FakeFirestore({
        'slots': _FakeCollRef(
          stream: const Stream.empty(),
          docs: {'slot_abc': docRef},
        ),
      });

      final cubit = AdminSlotCubit(firestore: firestore);
      await cubit.setSlotActive('slot_abc', false);

      expect(docRef.updates.first['isActive'], isFalse);
      await cubit.close();
    });

    test('updates isActive to true', () async {
      final docRef = _FakeDocRef('slot_abc');
      final firestore = _FakeFirestore({
        'slots': _FakeCollRef(
          stream: const Stream.empty(),
          docs: {'slot_abc': docRef},
        ),
      });

      final cubit = AdminSlotCubit(firestore: firestore);
      await cubit.setSlotActive('slot_abc', true);

      expect(docRef.updates.first['isActive'], isTrue);
      await cubit.close();
    });
  });
}

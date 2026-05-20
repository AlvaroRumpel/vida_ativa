import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vida_ativa/core/models/user_model.dart';
import 'package:vida_ativa/features/auth/cubit/auth_cubit.dart';
import 'package:vida_ativa/features/auth/cubit/auth_state.dart';
import 'package:vida_ativa/features/schedule/cubit/schedule_cubit.dart';
import 'package:vida_ativa/features/schedule/cubit/schedule_state.dart';
import 'package:vida_ativa/features/schedule/models/slot_view_model.dart';

// ─── Auth mock ────────────────────────────────────────────────────────────────
class MockAuthCubit extends Mock implements AuthCubit {}

// ─── Firestore fakes ──────────────────────────────────────────────────────────
class _FakeDocSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic>? _data;
  _FakeDocSnapshot(this._id, [this._data]);
  @override
  String get id => _id;
  @override
  Map<String, dynamic>? data() => _data;
  @override
  bool get exists => _data != null;
}

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
  final StreamController<DocumentSnapshot<Map<String, dynamic>>>? _snapCtrl;
  final List<Map<Object, Object?>> updates = [];

  _FakeDocRef(this._id, [this._data, this._snapCtrl]);

  @override
  String get id => _id;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async =>
      _FakeDocSnapshot(_id, _data);

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) =>
      _snapCtrl?.stream ??
      Stream.value(_FakeDocSnapshot(_id, _data));

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    _data = data;
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    updates.add(data);
  }

  @override
  Future<void> delete() async {
    _data = null;
  }
}

class _FakeQuery extends Fake implements Query<Map<String, dynamic>> {
  final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  _FakeQuery(this._stream);

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) =>
      this;

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) =>
      _stream;
}

class _FakeCollRef extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final Stream<QuerySnapshot<Map<String, dynamic>>> _queryStream;
  final Map<String, _FakeDocRef> _docs;

  _FakeCollRef({
    required Stream<QuerySnapshot<Map<String, dynamic>>> queryStream,
    Map<String, _FakeDocRef>? docs,
  })  : _queryStream = queryStream,
        _docs = docs ?? {};

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) =>
      _FakeQuery(_queryStream);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _docs[path] ?? _FakeDocRef(path ?? '');

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) =>
      _queryStream;
}

class _FakeFirestore extends Fake implements FirebaseFirestore {
  final Map<String, _FakeCollRef> _collections;
  _FakeFirestore(this._collections);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _collections[path] ??
      _FakeCollRef(queryStream: const Stream.empty());
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
const _testDate = '2030-06-10'; // far future — avoids auto-cancel timing issues
final _selectedDate = DateTime(2030, 6, 10);

_FakeQDocSnapshot _slotDoc(String id, String startTime, {double price = 60.0}) =>
    _FakeQDocSnapshot(id, {
      'date': _testDate,
      'startTime': startTime,
      'price': price,
      'isActive': true,
    });

_FakeQDocSnapshot _bookingDoc(String id, String slotId, String userId) =>
    _FakeQDocSnapshot(id, {
      'slotId': slotId,
      'date': _testDate,
      'userId': userId,
      'status': 'confirmed',
      'createdAt': Timestamp.fromDate(DateTime(2030, 6, 1)),
    });

// ─── Tests ────────────────────────────────────────────────────────────────────
void main() {
  late MockAuthCubit mockAuthCubit;

  setUp(() {
    mockAuthCubit = MockAuthCubit();
    when(() => mockAuthCubit.state).thenReturn(
      const AuthAuthenticated(
        UserModel(uid: 'current_user', email: 'e', displayName: 'd', role: 'client'),
      ),
    );
  });

  // ─── selectDay emits Loading ───────────────────────────────────────────────
  group('selectDay', () {
    test('emits ScheduleLoading immediately', () async {
      final slotsCtrl = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
      final bookingsCtrl = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
      final blockedCtrl = StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();

      final firestore = _FakeFirestore({
        'slots': _FakeCollRef(queryStream: slotsCtrl.stream),
        'bookings': _FakeCollRef(queryStream: bookingsCtrl.stream),
        'blockedDates': _FakeCollRef(
          queryStream: const Stream.empty(),
          docs: {_testDate: _FakeDocRef(_testDate, null, blockedCtrl)},
        ),
      });

      final cubit = ScheduleCubit(firestore: firestore, authCubit: mockAuthCubit);
      cubit.selectDay(_selectedDate);

      expect(cubit.state, isA<ScheduleLoading>());

      await cubit.close();
      await slotsCtrl.close();
      await bookingsCtrl.close();
      await blockedCtrl.close();
    });

    test('slot available when no booking matches', () async {
      final slotsCtrl = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
      final bookingsCtrl = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
      final blockedCtrl = StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();

      final firestore = _FakeFirestore({
        'slots': _FakeCollRef(queryStream: slotsCtrl.stream),
        'bookings': _FakeCollRef(queryStream: bookingsCtrl.stream),
        'blockedDates': _FakeCollRef(
          queryStream: const Stream.empty(),
          docs: {_testDate: _FakeDocRef(_testDate, null, blockedCtrl)},
        ),
      });

      final cubit = ScheduleCubit(firestore: firestore, authCubit: mockAuthCubit);
      cubit.selectDay(_selectedDate);

      slotsCtrl.add(_FakeQuerySnapshot([_slotDoc('slot1', '10:00')]));
      bookingsCtrl.add(_FakeQuerySnapshot([])); // no bookings
      await pumpEventQueue();

      final state = cubit.state as ScheduleLoaded;
      expect(state.isBlocked, isFalse);
      expect(state.slots.length, 1);
      expect(state.slots.first.status, SlotStatus.available);

      await cubit.close();
      await slotsCtrl.close();
      await bookingsCtrl.close();
      await blockedCtrl.close();
    });

    test('myBooking when current user owns the booking', () async {
      final slotsCtrl = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
      final bookingsCtrl = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
      final blockedCtrl = StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();

      final firestore = _FakeFirestore({
        'slots': _FakeCollRef(queryStream: slotsCtrl.stream),
        'bookings': _FakeCollRef(queryStream: bookingsCtrl.stream),
        'blockedDates': _FakeCollRef(
          queryStream: const Stream.empty(),
          docs: {_testDate: _FakeDocRef(_testDate, null, blockedCtrl)},
        ),
      });

      final cubit = ScheduleCubit(firestore: firestore, authCubit: mockAuthCubit);
      cubit.selectDay(_selectedDate);

      slotsCtrl.add(_FakeQuerySnapshot([_slotDoc('slot1', '10:00')]));
      bookingsCtrl.add(_FakeQuerySnapshot([
        _bookingDoc('b1', 'slot1', 'current_user'), // matches current user
      ]));
      await pumpEventQueue();

      final state = cubit.state as ScheduleLoaded;
      expect(state.slots.first.status, SlotStatus.myBooking);

      await cubit.close();
      await slotsCtrl.close();
      await bookingsCtrl.close();
      await blockedCtrl.close();
    });

    test('booked when another user owns the booking', () async {
      final slotsCtrl = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
      final bookingsCtrl = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
      final blockedCtrl = StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();

      final firestore = _FakeFirestore({
        'slots': _FakeCollRef(queryStream: slotsCtrl.stream),
        'bookings': _FakeCollRef(queryStream: bookingsCtrl.stream),
        'blockedDates': _FakeCollRef(
          queryStream: const Stream.empty(),
          docs: {_testDate: _FakeDocRef(_testDate, null, blockedCtrl)},
        ),
      });

      final cubit = ScheduleCubit(firestore: firestore, authCubit: mockAuthCubit);
      cubit.selectDay(_selectedDate);

      slotsCtrl.add(_FakeQuerySnapshot([_slotDoc('slot1', '10:00')]));
      bookingsCtrl.add(_FakeQuerySnapshot([
        _bookingDoc('b1', 'slot1', 'other_user'), // different user
      ]));
      await pumpEventQueue();

      final state = cubit.state as ScheduleLoaded;
      expect(state.slots.first.status, SlotStatus.booked);

      await cubit.close();
      await slotsCtrl.close();
      await bookingsCtrl.close();
      await blockedCtrl.close();
    });

    test('isBlocked=true when blockedDate doc exists', () async {
      final slotsCtrl = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
      final bookingsCtrl = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
      final blockedCtrl = StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();

      final firestore = _FakeFirestore({
        'slots': _FakeCollRef(queryStream: slotsCtrl.stream),
        'bookings': _FakeCollRef(queryStream: bookingsCtrl.stream),
        'blockedDates': _FakeCollRef(
          queryStream: const Stream.empty(),
          docs: {_testDate: _FakeDocRef(_testDate, null, blockedCtrl)},
        ),
      });

      final cubit = ScheduleCubit(firestore: firestore, authCubit: mockAuthCubit);
      cubit.selectDay(_selectedDate);

      slotsCtrl.add(_FakeQuerySnapshot([_slotDoc('slot1', '10:00')]));
      bookingsCtrl.add(_FakeQuerySnapshot([]));
      // Fire blocked date as existing doc
      blockedCtrl.add(_FakeDocSnapshot(_testDate, {'createdBy': 'admin'}));
      await pumpEventQueue();

      final state = cubit.state as ScheduleLoaded;
      expect(state.isBlocked, isTrue);
      expect(state.slots, isEmpty);

      await cubit.close();
      await slotsCtrl.close();
      await bookingsCtrl.close();
      await blockedCtrl.close();
    });

    test('slots sorted by startTime', () async {
      final slotsCtrl = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
      final bookingsCtrl = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
      final blockedCtrl = StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();

      final firestore = _FakeFirestore({
        'slots': _FakeCollRef(queryStream: slotsCtrl.stream),
        'bookings': _FakeCollRef(queryStream: bookingsCtrl.stream),
        'blockedDates': _FakeCollRef(
          queryStream: const Stream.empty(),
          docs: {_testDate: _FakeDocRef(_testDate, null, blockedCtrl)},
        ),
      });

      final cubit = ScheduleCubit(firestore: firestore, authCubit: mockAuthCubit);
      cubit.selectDay(_selectedDate);

      slotsCtrl.add(_FakeQuerySnapshot([
        _slotDoc('s3', '14:00'),
        _slotDoc('s1', '08:00'),
        _slotDoc('s2', '10:00'),
      ]));
      bookingsCtrl.add(_FakeQuerySnapshot([]));
      await pumpEventQueue();

      final state = cubit.state as ScheduleLoaded;
      expect(state.slots.map((s) => s.slot.startTime).toList(),
          ['08:00', '10:00', '14:00']);

      await cubit.close();
      await slotsCtrl.close();
      await bookingsCtrl.close();
      await blockedCtrl.close();
    });
  });
}

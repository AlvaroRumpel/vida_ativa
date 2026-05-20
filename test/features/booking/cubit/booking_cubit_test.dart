import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vida_ativa/core/models/booking_model.dart';
import 'package:vida_ativa/features/booking/cubit/booking_cubit.dart';
import 'package:vida_ativa/features/booking/cubit/booking_state.dart';

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
  _FakeDocSnapshot _snap;
  final List<Map<Object, Object?>> updates = [];

  _FakeDocRef(this._id, [Map<String, dynamic>? data])
      : _snap = _FakeDocSnapshot(_id, data);

  @override
  String get id => _id;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async => _snap;

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    _snap = _FakeDocSnapshot(_id, data);
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    updates.add(data);
    final current = _snap.data() ?? {};
    final updated = {...current, ...data.map((k, v) => MapEntry(k.toString(), v))};
    _snap = _FakeDocSnapshot(_id, updated);
  }
}

class _FakeQuery extends Fake implements Query<Map<String, dynamic>> {
  final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  final Future<QuerySnapshot<Map<String, dynamic>>>? _getFuture;
  _FakeQuery(this._stream, [this._getFuture]);

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

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) =>
      _getFuture ?? Future.value(_FakeQuerySnapshot());
}

class _FakeCollRef extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  final Future<QuerySnapshot<Map<String, dynamic>>>? _getFuture;
  final Map<String, _FakeDocRef> _docs;

  _FakeCollRef({
    required Stream<QuerySnapshot<Map<String, dynamic>>> stream,
    Future<QuerySnapshot<Map<String, dynamic>>>? getFuture,
    Map<String, _FakeDocRef>? docs,
  })  : _stream = stream,
        _getFuture = getFuture,
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
      _FakeQuery(_stream, _getFuture);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _docs[path] ?? _FakeDocRef(path ?? '');
}

class _FakeTx extends Fake implements Transaction {
  final Map<String, _FakeDocRef> _docs;
  _FakeTx(this._docs);

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
      DocumentReference<T> documentReference) async {
    final ref = _docs[documentReference.id];
    if (ref != null) return ref._snap as DocumentSnapshot<T>;
    return _FakeDocSnapshot(documentReference.id) as DocumentSnapshot<T>;
  }

  @override
  Transaction set<T extends Object?>(
    DocumentReference<T> documentReference,
    T data, [
    SetOptions? options,
  ]) {
    final ref = _docs[documentReference.id];
    if (ref != null && data is Map<String, dynamic>) {
      ref._snap = _FakeDocSnapshot(documentReference.id, data);
    }
    return this;
  }
}

class _FakeWriteBatch extends Fake implements WriteBatch {
  final List<Map<Object, Object?>> updates = [];

  @override
  void update(DocumentReference<Object?> document, Map<Object, Object?> data) {
    updates.add(data);
  }

  @override
  Future<void> commit() async {}
}

class _FakeFirestore extends Fake implements FirebaseFirestore {
  final Map<String, _FakeCollRef> _collections;
  final Map<String, _FakeDocRef> _txDocs;

  _FakeFirestore(this._collections, [this._txDocs = const {}]);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _collections[path] ??
      _FakeCollRef(stream: const Stream.empty());

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration? timeout,
    int maxAttempts = 5,
  }) async {
    final tx = _FakeTx(_txDocs);
    return await transactionHandler(tx);
  }

  @override
  WriteBatch batch() => _FakeWriteBatch();
}

// ─── Helper: build a minimal Firestore fake for BookingCubit constructor ───────
_FakeFirestore _makeFirestore({
  StreamController<QuerySnapshot<Map<String, dynamic>>>? bookingStream,
  Map<String, dynamic>? bookingConfig,
  Map<String, dynamic>? mpConfig,
  Map<String, _FakeDocRef>? bookingDocs,
  Map<String, _FakeDocRef>? txDocs,
}) {
  final stream = bookingStream?.stream ??
      Stream<QuerySnapshot<Map<String, dynamic>>>.value(
          _FakeQuerySnapshot());

  final configColl = _FakeCollRef(
    stream: const Stream.empty(),
    docs: {
      'booking': _FakeDocRef('booking', bookingConfig ?? {}),
      'mercadopago': _FakeDocRef('mercadopago', mpConfig ?? {}),
    },
  );

  final bookingColl = _FakeCollRef(
    stream: stream,
    docs: bookingDocs ?? {},
  );

  return _FakeFirestore(
    {'bookings': bookingColl, 'config': configColl},
    txDocs ?? {},
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────
void main() {
  // ─── RecurrenceOutcome data class ──────────────────────────────────────────
  group('RecurrenceOutcome', () {
    test('success factory sets success=true, failureReason=null', () {
      final outcome = RecurrenceOutcome.success('2026-05-08');
      expect(outcome.dateString, '2026-05-08');
      expect(outcome.success, isTrue);
      expect(outcome.failureReason, isNull);
    });

    test('failed factory sets success=false and reason', () {
      final outcome =
          RecurrenceOutcome.failed('2026-05-09', 'slot_already_booked');
      expect(outcome.dateString, '2026-05-09');
      expect(outcome.success, isFalse);
      expect(outcome.failureReason, 'slot_already_booked');
    });
  });

  // ─── Constructor stream → BookingLoaded ────────────────────────────────────
  group('constructor', () {
    test('emits BookingLoading then BookingLoaded([]) on empty snapshot',
        () async {
      final ctrl =
          StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
      final firestore = _makeFirestore(bookingStream: ctrl);

      final cubit = BookingCubit(firestore: firestore, userId: 'user1');
      expect(cubit.state, isA<BookingLoading>());

      ctrl.add(_FakeQuerySnapshot([]));
      await pumpEventQueue();

      expect(cubit.state, isA<BookingLoaded>());
      expect((cubit.state as BookingLoaded).bookings, isEmpty);

      await cubit.close();
      await ctrl.close();
    });
  });

  // ─── bookSlot ──────────────────────────────────────────────────────────────
  group('bookSlot', () {
    test('slot_already_passed: throws when today slot time is in the past',
        () async {
      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final firestore = _makeFirestore();
      final cubit = BookingCubit(firestore: firestore, userId: 'user1');

      expect(
        () => cubit.bookSlot(
          slotId: 'slot1',
          dateString: today,
          price: 60.0,
          startTime: '00:01', // always in the past
          userDisplayName: 'João',
          paymentMethod: 'on_arrival',
        ),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('slot_already_passed'))),
      );

      await cubit.close();
    });

    test('future date skips timing guard and calls runTransaction', () async {
      // Pre-populate the tx doc as non-existent (no conflict)
      final docId = BookingModel.generateId('slot1', '2030-01-01');
      final txDocs = {docId: _FakeDocRef(docId)}; // no data → exists=false

      final bookingColl = _FakeCollRef(
        stream: Stream.value(_FakeQuerySnapshot()),
        docs: {docId: _FakeDocRef(docId)},
      );

      final firestore = _FakeFirestore(
        {
          'bookings': bookingColl,
          'config': _FakeCollRef(
            stream: const Stream.empty(),
            docs: {
              'booking': _FakeDocRef('booking', {}),
              'mercadopago': _FakeDocRef('mercadopago', {}),
            },
          ),
        },
        txDocs,
      );

      final cubit = BookingCubit(firestore: firestore, userId: 'user1');

      // Should not throw for a future date
      await expectLater(
        cubit.bookSlot(
          slotId: 'slot1',
          dateString: '2030-01-01',
          price: 60.0,
          startTime: '10:00',
          userDisplayName: 'João',
          paymentMethod: 'on_arrival',
        ),
        completes,
      );

      await cubit.close();
    });
  });

  // ─── cancelBookingById ─────────────────────────────────────────────────────
  group('cancelBookingById', () {
    test('updates booking doc status to cancelled', () async {
      final docRef = _FakeDocRef('booking_id_1', {
        'slotId': 's',
        'date': 'd',
        'userId': 'user1',
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });

      final firestore = _makeFirestore(
        bookingDocs: {'booking_id_1': docRef},
      );

      final cubit = BookingCubit(firestore: firestore, userId: 'user1');
      await cubit.cancelBookingById('booking_id_1');

      expect(docRef.updates, isNotEmpty);
      expect(docRef.updates.first['status'], 'cancelled');
      await cubit.close();
    });
  });

  // ─── updateParticipants ────────────────────────────────────────────────────
  group('updateParticipants', () {
    test('updates participants field when non-empty', () async {
      final docRef = _FakeDocRef('booking_id_1', {'status': 'confirmed'});
      final firestore = _makeFirestore(bookingDocs: {'booking_id_1': docRef});
      final cubit = BookingCubit(firestore: firestore, userId: 'user1');

      await cubit.updateParticipants('booking_id_1', 'Ana, Bob');

      expect(docRef.updates.first['participants'], 'Ana, Bob');
      await cubit.close();
    });

    test('deletes participants field when null', () async {
      final docRef = _FakeDocRef('bid', {'participants': 'someone'});
      final firestore = _makeFirestore(bookingDocs: {'bid': docRef});
      final cubit = BookingCubit(firestore: firestore, userId: 'user1');

      await cubit.updateParticipants('bid', null);

      expect(docRef.updates.first['participants'], isA<FieldValue>());
      await cubit.close();
    });
  });
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vida_ativa/features/admin/cubit/admin_booking_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/admin_booking_state.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────────
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
  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => [];
}

class _FakeDocRef extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic>? _docData;
  Map<String, dynamic>? _setData;
  final List<Map<Object, Object?>> updates = [];

  _FakeDocRef(this._id, [this._docData]);

  @override
  String get id => _id;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get(
          [GetOptions? options]) async =>
      _FakeDocSnapshot(_id, _docData);

  @override
  Future<void> update(Map<Object, Object?> data) async => updates.add(data);

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async =>
      _setData = data;
}

class _FakeQuery extends Fake implements Query<Map<String, dynamic>> {
  final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  _FakeQuery(this._stream);

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
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) =>
      _stream;
}

class _FakeCollRef extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  final Map<String, _FakeDocRef> _docs;

  _FakeCollRef({
    Stream<QuerySnapshot<Map<String, dynamic>>>? stream,
    Map<String, _FakeDocRef>? docs,
  })  : _stream = stream ?? const Stream.empty(),
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
      _docs[path] ?? _FakeDocRef(path ?? '');
}

class _FakeFirestore extends Fake implements FirebaseFirestore {
  final Map<String, _FakeCollRef> _collections;
  _FakeFirestore(this._collections);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _collections[path] ?? _FakeCollRef();
}

// ─── Helper ───────────────────────────────────────────────────────────────────
_FakeFirestore _makeFirestore({
  Map<String, dynamic>? bookingConfig,
  StreamController<QuerySnapshot<Map<String, dynamic>>>? bookingsStream,
  Map<String, _FakeDocRef>? bookingDocs,
  _FakeDocRef? configDocRef,
}) {
  final ctrl = bookingsStream;
  return _FakeFirestore({
    'config': _FakeCollRef(
      docs: {
        'booking': configDocRef ??
            _FakeDocRef('booking', bookingConfig ?? {}),
      },
    ),
    'bookings': _FakeCollRef(
      stream: ctrl?.stream ?? Stream.value(_FakeQuerySnapshot()),
      docs: bookingDocs ?? {},
    ),
  });
}

// ─── Tests ────────────────────────────────────────────────────────────────────
void main() {
  group('AdminBookingCubit.confirmBooking', () {
    test('updates booking status to confirmed', () async {
      final docRef = _FakeDocRef('booking_abc');
      final firestore = _makeFirestore(
        bookingDocs: {'booking_abc': docRef},
      );

      final cubit =
          AdminBookingCubit(firestore: firestore, adminUid: 'admin1');
      await pumpEventQueue(); // allow constructor async to settle

      await cubit.confirmBooking('booking_abc');

      expect(docRef.updates, isNotEmpty);
      expect(docRef.updates.first['status'], 'confirmed');

      await cubit.close();
    });
  });

  group('AdminBookingCubit.rejectBooking', () {
    test('updates booking status to rejected', () async {
      final docRef = _FakeDocRef('booking_xyz');
      final firestore = _makeFirestore(
        bookingDocs: {'booking_xyz': docRef},
      );

      final cubit =
          AdminBookingCubit(firestore: firestore, adminUid: 'admin1');
      await pumpEventQueue();

      await cubit.rejectBooking('booking_xyz');

      expect(docRef.updates.first['status'], 'rejected');
      await cubit.close();
    });
  });

  group('AdminBookingCubit.setConfirmationMode', () {
    test('writes confirmationMode to config doc', () async {
      final configDocRef = _FakeDocRef('booking', {});
      final firestore = _FakeFirestore({
        'config': _FakeCollRef(docs: {'booking': configDocRef}),
        'bookings': _FakeCollRef(
          stream: Stream.value(_FakeQuerySnapshot()),
        ),
      });

      final cubit =
          AdminBookingCubit(firestore: firestore, adminUid: 'admin1');
      await pumpEventQueue();

      // Seed loaded state so emit inside setConfirmationMode works
      cubit.emit(AdminBookingLoaded(
        [],
        selectedDate: DateTime(2026, 5, 8),
        confirmationMode: 'manual',
        pixEnabled: true,
      ));

      await cubit.setConfirmationMode('auto');

      expect(configDocRef._setData, isNotNull);
      expect(configDocRef._setData!['confirmationMode'], 'auto');
      // State updated
      final state = cubit.state as AdminBookingLoaded;
      expect(state.confirmationMode, 'auto');

      await cubit.close();
    });
  });

  group('AdminBookingCubit.setPixEnabled', () {
    test('writes pixEnabled to config doc and updates state', () async {
      final configDocRef = _FakeDocRef('booking', {});
      final firestore = _FakeFirestore({
        'config': _FakeCollRef(docs: {'booking': configDocRef}),
        'bookings': _FakeCollRef(
          stream: Stream.value(_FakeQuerySnapshot()),
        ),
      });

      final cubit =
          AdminBookingCubit(firestore: firestore, adminUid: 'admin1');
      await pumpEventQueue();

      cubit.emit(AdminBookingLoaded(
        [],
        selectedDate: DateTime(2026, 5, 8),
        confirmationMode: 'manual',
        pixEnabled: true,
      ));

      await cubit.setPixEnabled(false);

      expect(configDocRef._setData!['pixEnabled'], isFalse);
      final state = cubit.state as AdminBookingLoaded;
      expect(state.pixEnabled, isFalse);

      await cubit.close();
    });
  });
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vida_ativa/features/admin/cubit/pricing_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/pricing_state.dart';

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

class _FakeDocRef extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  final String _id;
  Map<String, dynamic>? _setData;
  final StreamController<DocumentSnapshot<Map<String, dynamic>>> _ctrl;

  _FakeDocRef(this._id)
      : _ctrl = StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();

  @override
  String get id => _id;

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) =>
      _ctrl.stream;

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async =>
      _setData = data;

  void addSnapshot(Map<String, dynamic>? data) =>
      _ctrl.add(_FakeDocSnapshot(_id, data));

  Future<void> close() => _ctrl.close();
}

class _FakeCollRef extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final Map<String, _FakeDocRef> _docs;
  _FakeCollRef(this._docs);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _docs[path] ?? _FakeDocRef(path ?? '');
}

class _FakeFirestore extends Fake implements FirebaseFirestore {
  final Map<String, _FakeCollRef> _collections;
  _FakeFirestore(this._collections);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _collections[path] ?? _FakeCollRef({});
}

// ─── Tests ────────────────────────────────────────────────────────────────────
void main() {
  group('PricingCubit stream', () {
    test('emits PricingLoaded([]) when pricing doc has no tiers', () async {
      final pricingDocRef = _FakeDocRef('pricing');
      final firestore = _FakeFirestore({
        'config': _FakeCollRef({'pricing': pricingDocRef}),
      });

      final cubit = PricingCubit(firestore: firestore);

      pricingDocRef.addSnapshot({'tiers': []});
      await pumpEventQueue();

      final state = cubit.state as PricingLoaded;
      expect(state.tiers, isEmpty);

      await cubit.close();
      await pricingDocRef.close();
    });

    test('emits PricingLoaded with parsed tiers from snapshot', () async {
      final pricingDocRef = _FakeDocRef('pricing');
      final firestore = _FakeFirestore({
        'config': _FakeCollRef({'pricing': pricingDocRef}),
      });

      final cubit = PricingCubit(firestore: firestore);

      pricingDocRef.addSnapshot({
        'tiers': [
          {'daysOfWeek': [], 'fromHour': 8, 'toHour': 12, 'price': 60.0},
          {'daysOfWeek': [6, 7], 'fromHour': 8, 'toHour': 18, 'price': 80.0},
        ],
      });
      await pumpEventQueue();

      final state = cubit.state as PricingLoaded;
      expect(state.tiers.length, 2);
      expect(state.tiers[0].price, 60.0);
      expect(state.tiers[1].daysOfWeek, [6, 7]);

      await cubit.close();
      await pricingDocRef.close();
    });

    test('emits PricingLoaded([]) when doc data is null', () async {
      final pricingDocRef = _FakeDocRef('pricing');
      final firestore = _FakeFirestore({
        'config': _FakeCollRef({'pricing': pricingDocRef}),
      });

      final cubit = PricingCubit(firestore: firestore);

      pricingDocRef.addSnapshot(null); // doc doesn't exist
      await pumpEventQueue();

      final state = cubit.state as PricingLoaded;
      expect(state.tiers, isEmpty);

      await cubit.close();
      await pricingDocRef.close();
    });
  });

  group('PricingCubit.saveTiers (Firestore write only)', () {
    test('writes tiers map to config/pricing doc', () async {
      final pricingDocRef = _FakeDocRef('pricing');
      final firestore = _FakeFirestore({
        'config': _FakeCollRef({'pricing': pricingDocRef}),
      });

      final cubit = PricingCubit(firestore: firestore);

      // saveTiers calls Firestore set then Cloud Function.
      // Cloud Function will throw in test env — catch and verify Firestore was written.
      try {
        await cubit.saveTiers([]);
      } catch (_) {
        // Cloud Function not available in test env — expected
      }

      expect(pricingDocRef._setData, isNotNull);
      expect(pricingDocRef._setData!['tiers'], isA<List>());

      await cubit.close();
      await pricingDocRef.close();
    });
  });
}

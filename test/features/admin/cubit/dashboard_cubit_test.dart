import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vida_ativa/core/models/dashboard_data.dart';
import 'package:vida_ativa/features/admin/cubit/dashboard_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/dashboard_state.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────────

class _FakeQueryDocSnapshot extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic> _data;
  _FakeQueryDocSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  Map<String, dynamic> data() => _data;
}

class _FakeQuerySnapshot extends Fake
    implements QuerySnapshot<Map<String, dynamic>> {
  final List<_FakeQueryDocSnapshot> _docs;
  _FakeQuerySnapshot(this._docs);

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => _docs.cast();
}

class _FakePeriodsColl extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final StreamController<QuerySnapshot<Map<String, dynamic>>> ctrl =
      StreamController.broadcast();

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) =>
      ctrl.stream;
}

class _FakeDashboardDoc extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  final _FakePeriodsColl periods;
  _FakeDashboardDoc(this.periods);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    if (path == 'periods') return periods;
    throw StateError('Unexpected subcollection: $path');
  }
}

class _FakeConfigColl extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final _FakeDashboardDoc dashboardDoc;
  _FakeConfigColl(this.dashboardDoc);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    if (path == 'dashboard') return dashboardDoc;
    throw StateError('Unexpected doc: $path');
  }
}

class _FakeFirestore extends Fake implements FirebaseFirestore {
  final _FakeConfigColl configColl;
  _FakeFirestore(this.configColl);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    if (path == 'config') return configColl;
    throw StateError('Unexpected collection: $path');
  }
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late _FakePeriodsColl periods;
  late _FakeFirestore firestore;

  setUp(() {
    periods = _FakePeriodsColl();
    firestore = _FakeFirestore(_FakeConfigColl(_FakeDashboardDoc(periods)));
  });

  test('initial state is DashboardLoading', () {
    final cubit = DashboardCubit(firestore: firestore);
    expect(cubit.state, isA<DashboardLoading>());
    cubit.close();
  });

  test('emits DashboardLoaded with 3 periods parsed from snapshot', () async {
    final cubit = DashboardCubit(firestore: firestore);
    periods.ctrl.add(_FakeQuerySnapshot([
      _FakeQueryDocSnapshot('week', {
        'period': 'week',
        'totalBookings': 10,
        'confirmedBookings': 8,
        'totalRevenue': 800.0,
        'noShowRate': 0.1,
      }),
      _FakeQueryDocSnapshot('month', {
        'period': 'month',
        'totalBookings': 40,
        'totalRevenue': 3200.0,
      }),
      _FakeQueryDocSnapshot('year', {
        'period': 'year',
        'confirmedBookings': 350,
        'totalRevenue': 28000.0,
      }),
    ]));
    await pumpEventQueue();
    final state = cubit.state as DashboardLoaded;
    expect(state.week.totalBookings, 10);
    expect(state.week.confirmedBookings, 8);
    expect(state.week.totalRevenue, 800.0);
    expect(state.week.noShowRate, 0.1);
    expect(state.month.totalRevenue, 3200.0);
    expect(state.year.confirmedBookings, 350);
    await cubit.close();
  });

  test('emits DashboardLoaded with empty fallbacks when periods missing', () async {
    final cubit = DashboardCubit(firestore: firestore);
    periods.ctrl.add(_FakeQuerySnapshot([
      _FakeQueryDocSnapshot('week', {
        'period': 'week',
        'totalBookings': 5,
      }),
    ]));
    await pumpEventQueue();
    final state = cubit.state as DashboardLoaded;
    expect(state.week.totalBookings, 5);
    expect(state.month.period, 'month');
    expect(state.month.totalBookings, 0);
    expect(state.year.period, 'year');
    expect(state.year.totalBookings, 0);
    await cubit.close();
  });

  test('emits DashboardError on stream error', () async {
    final cubit = DashboardCubit(firestore: firestore);
    periods.ctrl.addError(Exception('boom'));
    await pumpEventQueue();
    expect(cubit.state, isA<DashboardError>());
    expect((cubit.state as DashboardError).message, 'Erro ao carregar dashboard.');
    await cubit.close();
  });

  test('parses doc with missing optional fields without throwing (DASH-04 nullable resilience)', () async {
    final cubit = DashboardCubit(firestore: firestore);
    periods.ctrl.add(_FakeQuerySnapshot([
      _FakeQueryDocSnapshot('week', {
        'period': 'week',
        'totalBookings': 3,
        // no noShowRate, no occupancyRate, no topClients
      }),
    ]));
    await pumpEventQueue();
    final state = cubit.state as DashboardLoaded;
    expect(state.week.noShowRate, isNull);
    expect(state.week.occupancyRate, isNull);
    expect(state.week.topClients, isNull);
    await cubit.close();
  });

  test('close cancels subscription without errors on subsequent stream events', () async {
    final cubit = DashboardCubit(firestore: firestore);
    await cubit.close();
    // Should not throw after close
    periods.ctrl.add(_FakeQuerySnapshot([]));
    await pumpEventQueue();
    // No assertion needed — just verifying no throw
  });
}

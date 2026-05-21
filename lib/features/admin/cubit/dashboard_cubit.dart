import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:vida_ativa/core/models/dashboard_data.dart';
import 'package:vida_ativa/features/admin/cubit/dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final FirebaseFirestore _firestore;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  DashboardCubit({required FirebaseFirestore firestore})
      : _firestore = firestore,
        super(const DashboardLoading()) {
    _startStream();
  }

  void _startStream() {
    _sub = _firestore
        .collection('config')
        .doc('dashboard')
        .collection('periods')
        .snapshots()
        .listen(
      (snap) {
        final byId = <String, DashboardData>{};
        for (final doc in snap.docs) {
          byId[doc.id] = DashboardData.fromMap(doc.data());
        }
        emit(DashboardLoaded(
          week: byId['week'] ?? DashboardData.empty('week'),
          month: byId['month'] ?? DashboardData.empty('month'),
          year: byId['year'] ?? DashboardData.empty('year'),
        ));
      },
      onError: (e, s) {
        Sentry.captureException(e, stackTrace: s);
        emit(const DashboardError('Erro ao carregar dashboard.'));
      },
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:vida_ativa/core/models/blocked_date_model.dart';
import 'package:vida_ativa/features/admin/cubit/admin_blocked_date_state.dart';

class AdminBlockedDateCubit extends Cubit<AdminBlockedDateState> {
  final FirebaseFirestore _firestore;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  AdminBlockedDateCubit({required FirebaseFirestore firestore})
      : _firestore = firestore,
        super(const AdminBlockedDateInitial()) {
    _startStream();
  }

  void _startStream() {
    _sub = _firestore.collection('blockedDates').snapshots().listen(
      (snapshot) {
        final dates = snapshot.docs
            .map((d) => BlockedDateModel.fromFirestore(d))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        emit(AdminBlockedDateLoaded(dates));
      },
      onError: (e) =>
          emit(const AdminBlockedDateError('Erro ao carregar datas bloqueadas.')),
    );
  }

  Future<void> blockDate(String dateString, String adminUid) async {
    final model = BlockedDateModel(date: dateString, createdBy: adminUid);
    await _firestore
        .collection('blockedDates')
        .doc(dateString)
        .set(model.toFirestore());
  }

  Future<void> unblockDate(String dateString) async {
    await _firestore.collection('blockedDates').doc(dateString).delete();
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

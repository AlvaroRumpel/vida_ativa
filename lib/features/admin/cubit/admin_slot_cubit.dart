import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:vida_ativa/core/models/slot_model.dart';
import 'package:vida_ativa/features/admin/cubit/admin_slot_state.dart';

class AdminSlotCubit extends Cubit<AdminSlotState> {
  final FirebaseFirestore _firestore;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  AdminSlotCubit({required FirebaseFirestore firestore})
      : _firestore = firestore,
        super(const AdminSlotInitial()) {
    _startStream();
  }

  void _startStream() {
    _sub = _firestore.collection('slots').snapshots().listen(
      (snapshot) {
        final slots = snapshot.docs
            .map((d) => SlotModel.fromFirestore(d))
            .toList()
          ..sort((a, b) {
            final dayCompare = a.dayOfWeek.compareTo(b.dayOfWeek);
            if (dayCompare != 0) return dayCompare;
            return a.startTime.compareTo(b.startTime);
          });
        emit(AdminSlotLoaded(slots));
      },
      onError: (e) => emit(const AdminSlotError('Erro ao carregar horários.')),
    );
  }

  Future<void> createSlot({
    required int dayOfWeek,
    required String startTime,
    required double price,
  }) async {
    await _firestore.collection('slots').add({
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'price': price,
      'isActive': true,
    });
  }

  Future<void> updateSlot(
    String slotId, {
    required int dayOfWeek,
    required String startTime,
    required double price,
  }) async {
    await _firestore.collection('slots').doc(slotId).update({
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'price': price,
    });
  }

  Future<void> setSlotActive(String slotId, bool isActive) async {
    await _firestore.collection('slots').doc(slotId).update({
      'isActive': isActive,
    });
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:vida_ativa/core/models/slot_model.dart';
import 'package:vida_ativa/features/admin/cubit/admin_slot_state.dart';

class AdminSlotCubit extends Cubit<AdminSlotState> {
  final FirebaseFirestore _firestore;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  AdminSlotCubit({required FirebaseFirestore firestore})
      : _firestore = firestore,
        super(const AdminSlotInitial()) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    loadSlotsForWeek(DateTime(monday.year, monday.month, monday.day));
  }

  void loadSlotsForWeek(DateTime weekStart) {
    _sub?.cancel();
    final start = _toDateString(weekStart);
    final end = _toDateString(weekStart.add(const Duration(days: 7)));
    _sub = _firestore
        .collection('slots')
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .snapshots()
        .listen(
      (snapshot) {
        final slots = snapshot.docs
            .map((d) => SlotModel.fromFirestore(d))
            .toList()
          ..sort((a, b) {
            final d = a.date.compareTo(b.date);
            return d != 0 ? d : a.startTime.compareTo(b.startTime);
          });
        emit(AdminSlotLoaded(slots));
      },
      onError: (e, s) {
        Sentry.captureException(e, stackTrace: s);
        emit(const AdminSlotError('Erro ao carregar horários.'));
      },
    );
  }

  Future<void> createSlot({
    required String date,
    required String startTime,
    required double price,
  }) async {
    final snap = await _firestore
        .collection('slots')
        .where('date', isEqualTo: date)
        .where('startTime', isEqualTo: startTime)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) throw 'slot_already_exists';
    await _firestore.collection('slots').add({
      'date': date,
      'startTime': startTime,
      'price': price,
      'isActive': true,
    });
  }

  Future<int> createBatchSlots(
    List<({String date, String startTime, double price})> slots,
  ) async {
    final dates = slots.map((s) => s.date).toList()..sort();
    final snap = await _firestore
        .collection('slots')
        .where('date', isGreaterThanOrEqualTo: dates.first)
        .where('date', isLessThanOrEqualTo: dates.last)
        .get();
    final existing = snap.docs.map((d) {
      final data = d.data();
      return '${data['date']}_${data['startTime']}';
    }).toSet();

    final toCreate = slots
        .where((s) => !existing.contains('${s.date}_${s.startTime}'))
        .toList();

    final batch = _firestore.batch();
    for (final s in toCreate) {
      batch.set(_firestore.collection('slots').doc(), {
        'date': s.date,
        'startTime': s.startTime,
        'price': s.price,
        'isActive': true,
      });
    }
    await batch.commit();
    return toCreate.length;
  }

  Future<void> updateSlot(
    String slotId, {
    required String date,
    required String startTime,
    required double price,
  }) async {
    await _firestore.collection('slots').doc(slotId).update({
      'date': date,
      'startTime': startTime,
      'price': price,
    });
  }

  Future<void> deleteSlot(String slotId) async {
    await _firestore.collection('slots').doc(slotId).delete();
  }

  Future<void> setSlotActive(String slotId, bool isActive) async {
    await _firestore.collection('slots').doc(slotId).update({
      'isActive': isActive,
    });
  }

  String _toDateString(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

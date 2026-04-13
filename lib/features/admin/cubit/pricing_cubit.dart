import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:vida_ativa/core/models/price_tier_model.dart';
import 'package:vida_ativa/features/admin/cubit/pricing_state.dart';

class PricingCubit extends Cubit<PricingState> {
  final FirebaseFirestore _firestore;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  PricingCubit({required FirebaseFirestore firestore})
      : _firestore = firestore,
        super(const PricingInitial()) {
    _startStream();
  }

  void _startStream() {
    _sub = _firestore
        .collection('config')
        .doc('pricing')
        .snapshots()
        .listen(
      (snap) {
        emit(PricingLoaded(PriceTierModel.listFromFirestore(snap)));
      },
      onError: (e, s) {
        Sentry.captureException(e, stackTrace: s);
        emit(const PricingError('Erro ao carregar preços.'));
      },
    );
  }

  Future<int> saveTiers(List<PriceTierModel> tiers) async {
    await _firestore.collection('config').doc('pricing').set({
      'tiers': tiers.map((t) => t.toMap()).toList(),
    });
    final callable = FirebaseFunctions.instance.httpsCallable('updateSlotPricesFromTiers');
    final result = await callable.call();
    return (result.data['updatedCount'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

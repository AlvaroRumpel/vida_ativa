import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:vida_ativa/features/admin/cubit/sport_config_state.dart';

class SportConfigCubit extends Cubit<SportConfigState> {
  static const List<String> defaultSports = ['Vôlei', 'Beach Tênis', 'Futevôlei'];

  final FirebaseFirestore _firestore;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  bool _initializingDefaults = false; // guard contra Pitfall 2 (loop infinito)

  SportConfigCubit({required FirebaseFirestore firestore})
      : _firestore = firestore,
        super(const SportConfigInitial()) {
    _startStream();
  }

  void _startStream() {
    _sub = _firestore
        .collection('config')
        .doc('sports')
        .snapshots()
        .listen(
      (snap) {
        final data = snap.data();
        final sports = (data?['sports'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            <String>[];
        if (!snap.exists || sports.isEmpty) {
          if (!_initializingDefaults) {
            _writeDefaults();
          }
        } else {
          _initializingDefaults = false;
          emit(SportConfigLoaded(sports));
        }
      },
      onError: (e, s) {
        Sentry.captureException(e, stackTrace: s);
        emit(const SportConfigError('Erro ao carregar esportes.'));
      },
    );
  }

  Future<void> _writeDefaults() async {
    _initializingDefaults = true;
    try {
      await _firestore.collection('config').doc('sports').set({
        'sports': defaultSports,
      });
      // Stream listener vai emitir SportConfigLoaded automaticamente após o write completar.
    } catch (e, s) {
      _initializingDefaults = false;
      Sentry.captureException(e, stackTrace: s);
      emit(const SportConfigError('Erro ao inicializar esportes.'));
    }
  }

  Future<void> saveSports(List<String> sports) async {
    try {
      await _firestore.collection('config').doc('sports').set({
        'sports': sports,
      });
      // Stream vai emitir SportConfigLoaded automaticamente após o write.
    } catch (e, s) {
      Sentry.captureException(e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:vida_ativa/features/admin/cubit/settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final FirebaseFirestore _firestore;

  SettingsCubit({required FirebaseFirestore firestore})
      : _firestore = firestore,
        super(const SettingsInitial()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final results = await Future.wait([
        _firestore.collection('config').doc('mercadopago').get(),
        _firestore.collection('config').doc('booking').get(),
      ]);
      final mpData = results[0].data();
      final bookingData = results[1].data();

      emit(SettingsLoaded(
        isAccessTokenConfigured:
            (mpData?['accessToken'] ?? '').toString().isNotEmpty,
        isWebhookSecretConfigured:
            (mpData?['webhookSecret'] ?? '').toString().isNotEmpty,
        pixEnabled: bookingData?['pixEnabled'] ?? true,
      ));
    } catch (e, s) {
      Sentry.captureException(e, stackTrace: s);
      emit(const SettingsError('Erro ao carregar configurações.'));
    }
  }

  /// Salva credenciais em config/mercadopago.
  /// Apenas campos não-vazios são escritos (merge: true).
  /// NUNCA retorna ou armazena o valor do token no estado Flutter.
  Future<void> saveCredentials({
    String? accessToken,
    String? webhookSecret,
  }) async {
    final data = <String, dynamic>{};
    if (accessToken != null && accessToken.trim().isNotEmpty) {
      data['accessToken'] = accessToken.trim();
    }
    if (webhookSecret != null && webhookSecret.trim().isNotEmpty) {
      data['webhookSecret'] = webhookSecret.trim();
    }
    if (data.isEmpty) return;

    data['updatedAt'] = FieldValue.serverTimestamp();

    try {
      await _firestore
          .collection('config')
          .doc('mercadopago')
          .set(data, SetOptions(merge: true));
      await _loadSettings();
    } catch (e, s) {
      Sentry.captureException(e, stackTrace: s);
      rethrow;
    }
  }

  /// Atualiza pixEnabled em config/booking (mesmo path que AdminBookingCubit).
  Future<void> setPixEnabled(bool enabled) async {
    try {
      await _firestore
          .collection('config')
          .doc('booking')
          .set({'pixEnabled': enabled}, SetOptions(merge: true));
      await _loadSettings();
    } catch (e, s) {
      Sentry.captureException(e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> reload() => _loadSettings();
}

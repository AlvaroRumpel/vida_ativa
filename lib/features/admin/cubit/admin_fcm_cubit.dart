import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'admin_fcm_state.dart';

class AdminFcmCubit extends Cubit<AdminFcmState> {
  AdminFcmCubit() : super(AdminFcmInitial());

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;

  /// Call once when AdminScreen initializes.
  /// Checks current permission status and emits the appropriate state.
  Future<void> init() async {
    final settings = await _messaging.getNotificationSettings();
    final status = settings.authorizationStatus;

    if (status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional) {
      await _activateToken();
    } else if (status == AuthorizationStatus.denied) {
      emit(AdminFcmDenied());
    } else {
      // notDetermined — show banner prompting admin to enable
      emit(AdminFcmPermissionRequired());
    }
  }

  /// Called when admin taps "Ativar Notificações" in the permission banner.
  Future<void> requestPermission() async {
    try {
      final result = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      if (result.authorizationStatus == AuthorizationStatus.authorized ||
          result.authorizationStatus == AuthorizationStatus.provisional) {
        await _activateToken();
      } else {
        emit(AdminFcmDenied());
      }
    } catch (e) {
      // ignore: avoid_print
      print('[AdminFcmCubit] requestPermission error: $e');
      emit(AdminFcmError('Erro ao solicitar permissão: $e'));
    }
  }

  Future<void> _activateToken() async {
    try {
      const env = String.fromEnvironment('ENV', defaultValue: 'prod');
      const vapidStaging = 'BKljao1LlvttrjI6nbvvVRfRD4VeZmMp32uyEaDqU3u6XoGIVkd9AdrnhCl_9-Q1rm2AHHMu9CUyrOvtzO5xQUw';
      const vapidProd = 'BE4IVHDfXnkE9o2xxSfYWpKxggsOlYKDI14_VW0wAEj_mWIx-K6lSDKQoLBbzFdgI8Ajrsv8FCen99oI-ST6qB4';
      const vapidKey = env == 'staging' ? vapidStaging : vapidProd;

      // ignore: avoid_print
      print('[AdminFcmCubit] getToken vapidKey=${vapidKey.isNotEmpty ? "${vapidKey.substring(0, 10)}..." : "(empty)"}');

      final token = await _messaging.getToken(
        vapidKey: vapidKey.isNotEmpty ? vapidKey : null,
      );

      // ignore: avoid_print
      print('[AdminFcmCubit] token=${token != null ? "${token.substring(0, 20)}..." : "null"}');

      if (token != null) {
        await _storeTokenInFirestore(token);
        emit(AdminFcmActive(token));
      } else {
        emit(AdminFcmError('Token FCM nulo — verifique VAPID key e service worker'));
      }

      // Listen for token refreshes (browser rotates token ~every 7 days)
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _messaging.onTokenRefresh.listen(_storeTokenInFirestore);
    } catch (e) {
      // ignore: avoid_print
      print('[AdminFcmCubit] _activateToken error: $e');
      emit(AdminFcmError('Erro ao obter token FCM: $e'));
    }
  }

  Future<void> _storeTokenInFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('fcmTokens')
        .doc(token)
        .set({
          'token': token,
          'createdAt': Timestamp.now(),
          'platform': 'web',
        });
  }

  /// Returns the foreground message stream for the UI to subscribe to.
  Stream<RemoteMessage> get onForegroundMessage => FirebaseMessaging.onMessage;

  @override
  Future<void> close() {
    _tokenRefreshSub?.cancel();
    _foregroundMessageSub?.cancel();
    return super.close();
  }
}

// STUB — substitua este arquivo com o output real de:
//   flutterfire configure --project vida-ativa-staging --out lib/firebase_options_staging.dart
//
// Este stub usa as credenciais de prod como placeholder para que o projeto compile.
// Builds com --dart-define=ENV=staging usarão este arquivo — não faça deploy de staging
// sem substituir pelo arquivo real gerado pelo flutterfire CLI.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for android.',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAUBQohx_R-v2nauF4BduWkLWOgb5GJb28',
    appId: '1:901130410262:web:afe75feef948f108b99837',
    messagingSenderId: '901130410262',
    projectId: 'vida-ativa-staging',
    authDomain: 'vida-ativa-staging.firebaseapp.com',
    storageBucket: 'vida-ativa-staging.firebasestorage.app',
    measurementId: 'G-GQ6MMVG3CN',
  );

  // PLACEHOLDER — substitua com os valores reais do projeto vida-ativa-staging
}
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/cubit/auth_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  if (kReleaseMode) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.environment = 'production';
        options.tracesSampleRate = 0.0;
      },
      appRunner: _initAndRun,
    );
  } else {
    await _initAndRun();
  }
}

Future<void> _initAndRun() async {
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    initializeDateFormatting('pt_BR'),
  ]);
  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  }
  runApp(const VidaAtivaApp());
}

class VidaAtivaApp extends StatefulWidget {
  const VidaAtivaApp({super.key});

  @override
  State<VidaAtivaApp> createState() => _VidaAtivaAppState();
}

class _VidaAtivaAppState extends State<VidaAtivaApp> {
  late final AuthCubit _authCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authCubit = AuthCubit();
    _router = createRouter(_authCubit);
  }

  @override
  void dispose() {
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authCubit,
      child: MaterialApp.router(
        title: 'Vida Ativa',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
      ),
    );
  }
}

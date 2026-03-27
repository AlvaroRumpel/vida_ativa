import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:vida_ativa/app_shell.dart';
import 'package:vida_ativa/features/admin/cubit/admin_blocked_date_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/admin_booking_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/admin_slot_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/pricing_cubit.dart';
import 'package:vida_ativa/features/admin/ui/admin_screen.dart';
import 'package:vida_ativa/features/auth/cubit/auth_cubit.dart';
import 'package:vida_ativa/features/auth/cubit/auth_state.dart';
import 'package:vida_ativa/features/auth/ui/access_denied_screen.dart';
import 'package:vida_ativa/features/auth/ui/login_screen.dart';
import 'package:vida_ativa/features/auth/ui/profile_screen.dart';
import 'package:vida_ativa/features/auth/ui/register_screen.dart';
import 'package:vida_ativa/features/auth/ui/splash_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vida_ativa/features/booking/cubit/booking_cubit.dart';
import 'package:vida_ativa/features/booking/ui/my_bookings_screen.dart';
import 'package:vida_ativa/features/schedule/cubit/schedule_cubit.dart';
import 'package:vida_ativa/features/schedule/ui/schedule_screen.dart';

class _AuthStateNotifier extends ChangeNotifier {
  final AuthCubit _cubit;
  late final StreamSubscription<AuthState> _subscription;

  _AuthStateNotifier(this._cubit) {
    _subscription = _cubit.stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter createRouter(AuthCubit authCubit) {
  final notifier = _AuthStateNotifier(authCubit);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = authCubit.state;
      final location = state.matchedLocation;

      // Still initializing — stay on splash
      if (authState is AuthInitial || authState is AuthLoading) {
        return location == '/splash' ? null : '/splash';
      }

      final isAuthenticated = authState is AuthAuthenticated;
      final isOnAuthPage =
          location == '/login' || location == '/register';

      // Not authenticated — must go to login
      if (!isAuthenticated && !isOnAuthPage) return '/login';

      // Authenticated but on auth page — go home
      if (isAuthenticated && isOnAuthPage) return '/home';

      // Admin guard: non-admin or admin in client mode cannot access /admin
      if (authState is AuthAuthenticated && location.startsWith('/admin')) {
        if (!authState.user.isAdmin || authState.viewMode == ViewMode.client) {
          return '/home';
        }
      }

      // Splash after auth resolved — route to destination
      if (location == '/splash') {
        return isAuthenticated ? '/home' : '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/access-denied',
        builder: (_, _) => const AccessDeniedScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, _) {
          final authState =
              context.read<AuthCubit>().state as AuthAuthenticated;
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) =>
                    AdminSlotCubit(firestore: FirebaseFirestore.instance),
              ),
              BlocProvider(
                create: (_) => AdminBlockedDateCubit(
                    firestore: FirebaseFirestore.instance),
              ),
              BlocProvider(
                create: (_) => AdminBookingCubit(
                  firestore: FirebaseFirestore.instance,
                  adminUid: authState.user.uid,
                ),
              ),
              BlocProvider(
                create: (_) =>
                    PricingCubit(firestore: FirebaseFirestore.instance),
              ),
            ],
            child: const AdminScreen(),
          );
        },
      ),
      // Main app shell with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          final authState = context.read<AuthCubit>().state as AuthAuthenticated;
          return BlocProvider(
            create: (_) => BookingCubit(
              firestore: FirebaseFirestore.instance,
              userId: authState.user.uid,
            ),
            child: AppShell(navigationShell: navigationShell),
          );
        },
        branches: [
          // Tab 0: Agenda
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => BlocProvider(
                  create: (context) => ScheduleCubit(
                    firestore: FirebaseFirestore.instance,
                    authCubit: context.read<AuthCubit>(),
                  ),
                  child: const ScheduleScreen(),
                ),
              ),
            ],
          ),
          // Tab 1: Minhas Reservas
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bookings',
                builder: (context, state) =>
                    const MyBookingsScreen(),
              ),
            ],
          ),
          // Tab 2: Perfil
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

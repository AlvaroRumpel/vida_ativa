import 'package:go_router/go_router.dart';

import 'package:vida_ativa/app_shell.dart';
import 'package:vida_ativa/features/schedule/ui/schedule_placeholder_screen.dart';
import 'package:vida_ativa/features/booking/ui/my_bookings_placeholder_screen.dart';
import 'package:vida_ativa/features/auth/ui/profile_placeholder_screen.dart';
import 'package:vida_ativa/features/auth/ui/login_placeholder_screen.dart';
import 'package:vida_ativa/features/admin/ui/admin_placeholder_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    // Main app shell with bottom navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Agenda
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const SchedulePlaceholderScreen(),
            ),
          ],
        ),
        // Tab 1: Minhas Reservas
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/bookings',
              builder: (context, state) => const MyBookingsPlaceholderScreen(),
            ),
          ],
        ),
        // Tab 2: Perfil
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePlaceholderScreen(),
            ),
          ],
        ),
      ],
    ),
    // Login route (outside shell -- no bottom nav)
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPlaceholderScreen(),
    ),
    // Admin route (outside shell -- separate layout, Phase 2 adds role guard)
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminPlaceholderScreen(),
    ),
  ],
  // Redirect / to /home
  redirect: (context, state) {
    if (state.matchedLocation == '/') {
      return '/home';
    }
    return null;
  },
);

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vida_ativa/core/services/fcm_navigation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/admin/cubit/admin_fcm_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/dashboard_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/settings_cubit.dart';
import 'package:vida_ativa/features/admin/cubit/sport_config_cubit.dart';
import 'package:vida_ativa/features/admin/ui/blocked_dates_tab.dart';
import 'package:vida_ativa/features/admin/ui/booking_management_tab.dart';
import 'package:vida_ativa/features/admin/ui/pricing_tab.dart';
import 'package:vida_ativa/features/admin/ui/settings_tab.dart';
import 'package:vida_ativa/features/admin/ui/slot_management_tab.dart';
import 'package:vida_ativa/features/admin/ui/dashboard_tab.dart';
import 'package:vida_ativa/features/admin/ui/users_management_tab.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late final AdminFcmCubit _fcmCubit;
  late final TabController _tabController;
  StreamSubscription<dynamic>? _foregroundSub;

  String? _pendingMessage;
  Timer? _bannerTimer;

  static const int _reservasTabIndex = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _fcmCubit = AdminFcmCubit();
    _fcmCubit.init();

    // Listen for foreground messages and show an inline banner
    _foregroundSub = _fcmCubit.onForegroundMessage.listen((message) {
      if (!mounted) return;
      final title = message.notification?.title ?? 'Nova Reserva';
      final body = message.notification?.body ?? '';
      setState(() => _pendingMessage = '$title\n$body');
      _bannerTimer?.cancel();
      _bannerTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _pendingMessage = null);
      });
    });

    // Navigate to Reservas if notification was tapped before this screen mounted
    if (navigateToReservasNotifier.value) {
      navigateToReservasNotifier.value = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToReservas());
    }
    navigateToReservasNotifier.addListener(_onFcmNavigation);
  }

  void _goToReservas() {
    _tabController.animateTo(_reservasTabIndex);
  }

  void _onFcmNavigation() {
    if (navigateToReservasNotifier.value && mounted) {
      navigateToReservasNotifier.value = false;
      _goToReservas();
    }
  }

  Widget _buildInlineBanner(String message) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 2, color: AppTheme.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(message, style: AppTheme.ui(size: 13)),
                  ),
                  TextButton(
                    onPressed: _goToReservas,
                    child: Text('Ver', style: AppTheme.mono(size: 11, color: AppTheme.ink)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _foregroundSub?.cancel();
    _bannerTimer?.cancel();
    navigateToReservasNotifier.removeListener(_onFcmNavigation);
    _tabController.dispose();
    _fcmCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DashboardCubit(firestore: FirebaseFirestore.instance),
      child: BlocProvider.value(
        value: _fcmCubit,
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // --- HEADER ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Line 1: wordmark + "cliente →"
                      Row(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('VIDA', style: AppTheme.display(size: 18, color: AppTheme.ink)),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.orange,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('ATIVA', style: AppTheme.display(size: 18, color: AppTheme.paper)),
                              ),
                            ],
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => context.go('/home'),
                            child: Text('cliente →', style: AppTheme.mono(size: 11, color: AppTheme.orange)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Line 2: eyebrow
                      Text('PAINEL ADMIN', style: AppTheme.mono(size: 10, color: AppTheme.concrete)),
                    ],
                  ),
                ),

                // --- TABBAR ---
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  dividerColor: AppTheme.lineHair,
                  tabs: const [
                    Tab(text: 'DASHBOARD'),
                    Tab(text: 'SLOTS'),
                    Tab(text: 'BLOQUEIOS'),
                    Tab(text: 'RESERVAS'),
                    Tab(text: 'USUÁRIOS'),
                    Tab(text: 'PREÇOS'),
                    Tab(text: 'AJUSTES'),
                  ],
                ),

                // --- INLINE NEW BOOKING BANNER ---
                if (_pendingMessage != null) _buildInlineBanner(_pendingMessage!),

                // --- FCM PERMISSION / ERROR BANNERS ---
                BlocBuilder<AdminFcmCubit, AdminFcmState>(
                  builder: (context, state) {
                    if (state is AdminFcmPermissionRequired) {
                      return _NotificationBanner(
                        onEnable: () => context.read<AdminFcmCubit>().requestPermission(),
                      );
                    }
                    if (state is AdminFcmError) {
                      return Container(
                        width: double.infinity,
                        color: AppTheme.orangeDk.withValues(alpha: 0.1),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Text(
                          'FCM Error: ${state.message}',
                          style: AppTheme.ui(size: 12, color: AppTheme.orangeDk),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // --- TAB CONTENT ---
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      const DashboardTab(),
                      const SlotManagementTab(),
                      const BlockedDatesTab(),
                      const BookingManagementTab(),
                      const UsersManagementTab(),
                      const PricingTab(),
                      MultiBlocProvider(
                        providers: [
                          BlocProvider(create: (_) => SettingsCubit(firestore: FirebaseFirestore.instance)),
                          BlocProvider(create: (_) => SportConfigCubit(firestore: FirebaseFirestore.instance)),
                        ],
                        child: const SettingsTab(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationBanner extends StatelessWidget {
  final VoidCallback onEnable;
  const _NotificationBanner({required this.onEnable});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 2, color: AppTheme.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ative notificações para alertas de novas reservas.',
                      style: AppTheme.ui(size: 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onEnable,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Text(
                        'ATIVAR',
                        style: AppTheme.mono(size: 12, color: AppTheme.orange),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

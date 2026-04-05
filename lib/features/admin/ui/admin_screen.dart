import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:vida_ativa/core/theme/app_theme.dart';
import 'package:vida_ativa/features/admin/cubit/admin_fcm_cubit.dart';
import 'package:vida_ativa/features/admin/ui/blocked_dates_tab.dart';
import 'package:vida_ativa/features/admin/ui/booking_management_tab.dart';
import 'package:vida_ativa/features/admin/ui/pricing_tab.dart';
import 'package:vida_ativa/features/admin/ui/slot_management_tab.dart';
import 'package:vida_ativa/features/admin/ui/users_management_tab.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late final AdminFcmCubit _fcmCubit;

  @override
  void initState() {
    super.initState();
    _fcmCubit = AdminFcmCubit();
    _fcmCubit.init();

    // Listen for foreground messages and show a SnackBar
    _fcmCubit.onForegroundMessage.listen((message) {
      if (!mounted) return;
      final title = message.notification?.title ?? 'Nova Reserva';
      final body = message.notification?.body ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title\n$body'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Ver',
            onPressed: () {
              // Already in admin screen — dismiss only
            },
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _fcmCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _fcmCubit,
      child: DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Painel Admin'),
            actions: [
              TextButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.person_outline, size: 18),
                label: const Text('Área do Cliente'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                ),
              ),
            ],
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Slots'),
                Tab(text: 'Bloqueios'),
                Tab(text: 'Reservas'),
                Tab(text: 'Usuarios'),
                Tab(text: 'Preços'),
              ],
            ),
          ),
          body: Column(
            children: [
              BlocBuilder<AdminFcmCubit, AdminFcmState>(
                builder: (context, state) {
                  if (state is AdminFcmPermissionRequired) {
                    return _NotificationBanner(
                      onEnable: () =>
                          context.read<AdminFcmCubit>().requestPermission(),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    SlotManagementTab(),
                    BlockedDatesTab(),
                    BookingManagementTab(),
                    UsersManagementTab(),
                    PricingTab(),
                  ],
                ),
              ),
            ],
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
    return Container(
      width: double.infinity,
      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.notifications_outlined, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Ative as notificações para receber alertas de novas reservas.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onEnable,
            child: const Text('Ativar'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vida_ativa/core/theme/app_theme.dart';

import 'package:vida_ativa/features/admin/ui/blocked_dates_tab.dart';
import 'package:vida_ativa/features/admin/ui/booking_management_tab.dart';
import 'package:vida_ativa/features/admin/ui/pricing_tab.dart';
import 'package:vida_ativa/features/admin/ui/slot_management_tab.dart';
import 'package:vida_ativa/features/admin/ui/users_management_tab.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
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
        body: const TabBarView(
          children: [
            SlotManagementTab(),
            BlockedDatesTab(),
            BookingManagementTab(),
            UsersManagementTab(),
            PricingTab(),
          ],
        ),
      ),
    );
  }
}

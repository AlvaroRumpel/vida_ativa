import 'package:flutter/material.dart';

import 'package:vida_ativa/features/admin/ui/blocked_dates_tab.dart';
import 'package:vida_ativa/features/admin/ui/booking_management_tab.dart';
import 'package:vida_ativa/features/admin/ui/slot_management_tab.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Painel Admin'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Slots'),
              Tab(text: 'Bloqueios'),
              Tab(text: 'Reservas'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SlotManagementTab(),
            BlockedDatesTab(),
            BookingManagementTab(),
          ],
        ),
      ),
    );
  }
}

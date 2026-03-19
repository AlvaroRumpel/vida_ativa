import 'package:flutter/material.dart';

class AdminPlaceholderScreen extends StatelessWidget {
  const AdminPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.admin_panel_settings, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Painel Admin', style: TextStyle(fontSize: 24, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Em breve', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

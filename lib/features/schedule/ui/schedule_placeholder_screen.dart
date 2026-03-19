import 'package:flutter/material.dart';

class SchedulePlaceholderScreen extends StatelessWidget {
  const SchedulePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Agenda', style: TextStyle(fontSize: 24, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Em breve', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

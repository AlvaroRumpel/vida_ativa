import 'package:flutter/material.dart';

class MyBookingsPlaceholderScreen extends StatelessWidget {
  const MyBookingsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.book_online, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Minhas Reservas', style: TextStyle(fontSize: 24, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Em breve', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

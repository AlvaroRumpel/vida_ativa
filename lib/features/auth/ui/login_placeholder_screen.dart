import 'package:flutter/material.dart';

class LoginPlaceholderScreen extends StatelessWidget {
  const LoginPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Login', style: TextStyle(fontSize: 24, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Em breve', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

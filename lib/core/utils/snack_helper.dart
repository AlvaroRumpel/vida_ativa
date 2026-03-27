import 'package:flutter/material.dart';

class SnackHelper {
  SnackHelper._();

  static void success(BuildContext context, String message) => _show(
        context,
        message,
        Icons.check_circle_outline,
        const Color(0xFFD4A800),
      );

  static void error(BuildContext context, String message) => _show(
        context,
        message,
        Icons.error_outline,
        const Color(0xFFFF6B6B),
      );

  static void info(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
  }) =>
      _show(
        context,
        message,
        Icons.info_outline,
        Colors.white70,
        action: action,
        duration: duration,
      );

  static void _show(
    BuildContext context,
    String message,
    IconData icon,
    Color iconColor, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      action: action,
      duration: duration,
    ));
  }
}

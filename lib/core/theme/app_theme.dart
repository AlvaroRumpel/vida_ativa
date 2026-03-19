import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._(); // Private constructor -- use static members only

  // Brand colors -- change these to rebrand the entire app
  static const Color primaryGreen = Color(0xFF2E7D32); // Material Green 800
  static const Color primaryBlue = Color(0xFF0175C2);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      primary: primaryGreen,
      secondary: primaryBlue,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: primaryGreen,
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._(); // Private constructor -- use static members only

  // Brand colors -- change these to rebrand the entire app
  static const Color primaryGreen = Color(0xFF1B5E3A); // Arena Vida Ativa deep green
  static const Color brandAmber = Color(0xFFD4860A);   // Sandy amber accent

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      primary: primaryGreen,
      secondary: brandAmber,
      surface: const Color(0xFFFDFAF5),
      error: const Color(0xFFC62828),
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.nunitoTextTheme(),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: const Color(0xFFFDFAF5),
      foregroundColor: primaryGreen,
      titleTextStyle: GoogleFonts.nunito(
        color: primaryGreen,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: const IconThemeData(color: primaryGreen),
    ),
  );
}

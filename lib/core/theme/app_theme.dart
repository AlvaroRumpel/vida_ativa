import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Sport palette ────────────────────────────────────────────
  static const Color sand      = Color(0xFFF4EFE2); // bg principal
  static const Color paper     = Color(0xFFFBF8F0); // surface lifted
  static const Color ink       = Color(0xFF0E0E0C); // near-black
  static const Color inkSoft   = Color(0xFF2A2A26);
  static const Color concrete  = Color(0xFF6B6B66); // text dim
  static const Color line      = Color(0xFFD9D2BE); // divider
  static const Color lineHair  = Color(0xFFEAE3CE); // thin divider
  static const Color orange    = Color(0xFFFF4D17); // primary accent
  static const Color orangeDk  = Color(0xFFC9300A);
  static const Color court     = Color(0xFF1B5E2A); // success green
  static const Color sun       = Color(0xFFFFB800); // yellow

  // Legacy aliases kept so existing references compile
  static const Color primaryGreen = court;
  static const Color brandAmber   = orange;

  // ── Typography helpers ───────────────────────────────────────
  static TextStyle display({double size = 32, Color? color, double? letterSpacing}) =>
      GoogleFonts.anton(
        fontSize: size,
        color: color ?? ink,
        letterSpacing: letterSpacing ?? 0.5,
        height: 0.92,
      );

  static TextStyle ui({double size = 14, FontWeight weight = FontWeight.w400, Color? color}) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: weight,
        color: color ?? ink,
      );

  static TextStyle mono({double size = 11, FontWeight weight = FontWeight.w700, Color? color, double? letterSpacing}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color ?? concrete,
        letterSpacing: letterSpacing ?? 0.18 * (size),
      );

  // ── Theme ────────────────────────────────────────────────────
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: sand,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: orange,
      onPrimary: paper,
      secondary: court,
      onSecondary: paper,
      surface: sand,
      onSurface: ink,
      error: orangeDk,
      onError: paper,
      tertiary: sun,
      onTertiary: ink,
      outline: line,
      surfaceContainerHighest: paper,
      onSurfaceVariant: concrete,
    ),
    textTheme: GoogleFonts.manropeTextTheme(),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: sand,
      foregroundColor: ink,
      centerTitle: false,
      titleTextStyle: GoogleFonts.anton(
        color: ink,
        fontSize: 28,
        letterSpacing: 0.5,
        height: 1,
      ),
      iconTheme: const IconThemeData(color: ink),
    ),
    tabBarTheme: TabBarThemeData(
      indicatorColor: orange,
      indicatorSize: TabBarIndicatorSize.tab,
      labelColor: ink,
      unselectedLabelColor: concrete,
      dividerColor: line,
      labelStyle: GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
      ),
      unselectedLabelStyle: GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
      ),
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: orange, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: sand,
      indicatorColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: selected ? orange : concrete,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? orange : concrete, size: 22);
      }),
    ),
    dividerTheme: const DividerThemeData(
      color: line,
      thickness: 1,
      space: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: const BorderSide(color: lineHair),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: orange,
        foregroundColor: paper,
        textStyle: GoogleFonts.anton(fontSize: 15, letterSpacing: 1),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: const BorderSide(color: ink, width: 1.5),
        textStyle: GoogleFonts.anton(fontSize: 15, letterSpacing: 1),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: orange,
        textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: line),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: line),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: orange, width: 2),
      ),
      labelStyle: GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.8,
        color: concrete,
      ),
      hintStyle: GoogleFonts.manrope(fontSize: 13, color: concrete),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? paper : paper,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? orange
            : concrete.withValues(alpha: 0.55),
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ink,
      contentTextStyle: GoogleFonts.manrope(color: paper, fontSize: 14),
      actionTextColor: orange,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: orange,
      foregroundColor: paper,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: CircleBorder(),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: orange,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? orange : Colors.transparent,
      ),
      checkColor: WidgetStateProperty.all(paper),
      side: const BorderSide(color: line, width: 1.5),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: paper,
      selectedColor: ink,
      labelStyle: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4),
      side: const BorderSide(color: line),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
  );
}

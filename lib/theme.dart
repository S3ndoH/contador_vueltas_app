import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF3B82F6); // Blue-500
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate-50
  static const Color backgroundDark = Color(0xFF0F172A); // Slate-900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate-800
  static const Color textMuted = Color(0xFF64748B); // Slate-500
  static const Color textWhite = Colors.white;

  // Status Colors
  static const Color success = Color(0xFF22C55E); // Green-500
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color error = Color(0xFFEF4444); // Red-500
  static const Color intensityHigh = Color(0xFF7C3AED); // Violet-600
}

ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.backgroundDark,
  fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
  textTheme: GoogleFonts.spaceGroteskTextTheme(
    const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textWhite),
      bodyMedium: TextStyle(color: AppColors.textWhite),
      displayLarge: TextStyle(
        color: AppColors.textWhite,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceDark,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primary, width: 1),
    ),
    hintStyle: const TextStyle(color: Color(0x807A8490)), // primary muted / 50
  ),
);

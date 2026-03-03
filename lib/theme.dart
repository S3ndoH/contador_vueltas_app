import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF17A1CF);
  static const Color backgroundLight = Color(0xFFF1F2F4);
  static const Color backgroundDark = Color(0xFF121416);
  static const Color surfaceDark = Color(0xFF1A1D21);
  static const Color textMuted = Color(0xFF7A8490);
  static const Color textWhite = Colors.white;
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

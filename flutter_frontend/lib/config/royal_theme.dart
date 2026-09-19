import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RoyalTheme {
  static const Color primaryGold = Color(0xFFC5A059);
  static const Color brightGold = Color(0xFFD4AF37);
  static const Color lightGold = Color(0xFFF3E5AB);
  static const Color darkGold = Color(0xFF855B14);
  static const Color deepGold = Color(0xFF5B3D0B);

  // Dark Theme Colors
  static const Color obsidianDark = Color(0xFF0E0F12);
  static const Color surfaceDark = Color(0xFF14161F);
  static const Color cardDark = Color(0xFF1A1C26);
  static const Color borderDark = Color(0x66C5A059);

  // Light Theme Colors
  static const Color alabasterLight = Color(0xFFFAF8F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFAF6ED);
  static const Color borderLight = Color(0x66C5A059);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: obsidianDark,
      primaryColor: primaryGold,
      colorScheme: const ColorScheme.dark(
        primary: primaryGold,
        secondary: brightGold,
        surface: surfaceDark,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderDark, width: 1.2),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cinzel(
          color: brightGold,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.cinzel(
          color: lightGold,
          fontSize: 32,
          fontWeight: FontWeight.w900,
        ),
        titleLarge: GoogleFonts.cinzel(
          color: lightGold,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: GoogleFonts.inter(
          color: const Color(0xFFDCD6CD),
          fontSize: 14,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: alabasterLight,
      primaryColor: darkGold,
      colorScheme: const ColorScheme.light(
        primary: darkGold,
        secondary: brightGold,
        surface: surfaceLight,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Color(0xFF1E1E1E),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderLight, width: 1.2),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cinzel(
          color: darkGold,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.cinzel(
          color: const Color(0xFF1C1917),
          fontSize: 32,
          fontWeight: FontWeight.w900,
        ),
        titleLarge: GoogleFonts.cinzel(
          color: const Color(0xFF1C1917),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: GoogleFonts.inter(
          color: const Color(0xFF1C1917),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: GoogleFonts.inter(
          color: const Color(0xFF44403C),
          fontSize: 14,
        ),
      ),
    );
  }
}

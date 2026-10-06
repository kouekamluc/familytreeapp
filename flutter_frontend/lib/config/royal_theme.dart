import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared mobile palette. Bright fills are paired with readable dark labels.
class RoyalTheme {
  static const primaryGold = Color(0xFFFFC83D);
  static const brightGold = primaryGold;
  static const lightGold = Color(0xFFFFF3CE);
  static const darkGold = Color(0xFFA55D00);
  static const deepGold = Color(0xFF724100);
  static const green = Color(0xFF58C928);
  static const greenDepth = Color(0xFF329C18);
  static const greenInk = Color(0xFF173B22);
  static const mint = Color(0xFFEDFAE5);
  static const blue = Color(0xFF1CA7EC);
  static const coral = Color(0xFFFF6B5F);
  static const violet = Color(0xFF8C65D8);
  static const ink = Color(0xFF24322A);
  static const obsidianDark = Color(0xFF131D1A);
  static const surfaceDark = Color(0xFF1D2A24);
  static const cardDark = Color(0xFF28382F);
  static const borderDark = Color(0xFF4E6355);
  static const alabasterLight = Colors.white;
  static const surfaceLight = Colors.white;
  static const cardLight = Color(0xFFF4F6F4);
  static const borderLight = Color(0xFFDEE5DE);

  /// Accents used as text must remain readable on neutral/tinted surfaces.
  static Color accentText(BuildContext context, Color color) {
    final background = Theme.of(context).colorScheme.surface;
    final dark = Theme.of(context).brightness == Brightness.dark;
    for (var step = 0; step <= 20; step++) {
      final candidate = Color.lerp(
        color,
        dark ? Colors.white : Colors.black,
        step / 20,
      )!;
      final light = candidate.computeLuminance();
      final surface = background.computeLuminance();
      final ratio =
          (light > surface ? light + .05 : surface + .05) /
          (light > surface ? surface + .05 : light + .05);
      if (ratio >= 4.8) return candidate;
    }
    return dark ? Colors.white : ink;
  }

  static ThemeData get lightTheme => _theme(false);
  static ThemeData get darkTheme => _theme(true);
  static ThemeData _theme(bool dark) {
    final background = dark ? obsidianDark : alabasterLight;
    final surface = dark ? surfaceDark : surfaceLight;
    final text = dark ? const Color(0xFFEDF5ED) : ink;
    final outline = dark ? borderDark : borderLight;
    final primary = dark ? const Color(0xFF79DD4E) : green;
    final base = dark ? ThemeData.dark() : ThemeData.light();
    final fonts = GoogleFonts.nunitoTextTheme(
      base.textTheme,
    ).apply(bodyColor: text, displayColor: text);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: green,
            brightness: dark ? Brightness.dark : Brightness.light,
          ).copyWith(
            primary: primary,
            onPrimary: greenInk,
            secondary: blue,
            onSecondary: ink,
            primaryContainer: dark ? cardDark : mint,
            onPrimaryContainer: text,
            secondaryContainer: dark ? cardDark : const Color(0xFFEAF7FE),
            onSecondaryContainer: text,
            tertiary: coral,
            onTertiary: ink,
            error: dark ? const Color(0xFFFFA79E) : const Color(0xFFC33732),
            errorContainer: dark
                ? const Color(0xFF452723)
                : const Color(0xFFFFEFEC),
            onErrorContainer: dark
                ? const Color(0xFFFFDBD5)
                : const Color(0xFF772824),
            surface: surface,
            onSurface: text,
            onSurfaceVariant: dark
                ? const Color(0xFFB5C9BB)
                : const Color(0xFF56665A),
            outline: outline,
            surfaceContainer: dark ? cardDark : cardLight,
            surfaceContainerHighest: dark ? cardDark : cardLight,
          ),
      textTheme: fonts.copyWith(
        headlineLarge: fonts.headlineLarge?.copyWith(
          fontSize: 34,
          fontWeight: FontWeight.w900,
          letterSpacing: -.6,
          height: 1.15,
        ),
        headlineMedium: fonts.headlineMedium?.copyWith(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          letterSpacing: -.4,
          height: 1.2,
        ),
        headlineSmall: fonts.headlineSmall?.copyWith(
          fontSize: 23,
          fontWeight: FontWeight.w800,
          letterSpacing: -.5,
        ),
        titleLarge: fonts.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -.4,
        ),
        titleMedium: fonts.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        bodyLarge: fonts.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
        bodyMedium: fonts.bodyMedium?.copyWith(fontSize: 14, height: 1.5),
        labelLarge: fonts.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: fonts.titleLarge?.copyWith(
          color: text,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: outline, width: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? surface : cardLight,
        labelStyle: fonts.bodyMedium?.copyWith(
          color: text,
          fontWeight: FontWeight.w700,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: dark ? borderDark : const Color(0xFF859582),
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: dark ? borderDark : const Color(0xFF859582),
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: dark ? primary : greenDepth, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 54),
          shape: shape,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle: fonts.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: greenInk,
          elevation: 0,
          minimumSize: const Size(48, 52),
          shape: shape,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          side: BorderSide(color: outline, width: 2),
          shape: shape,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dark ? primary : const Color(0xFF267A13),
          minimumSize: const Size(48, 48),
          shape: shape,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: dark ? cardDark : mint,
        checkmarkColor: dark ? primary : greenInk,
        side: BorderSide(color: outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelStyle: fonts.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: dark ? cardDark : mint,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => fonts.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: states.contains(WidgetState.selected)
                ? text
                : (dark ? const Color(0xFFB5C9BB) : const Color(0xFF56665A)),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: green,
        foregroundColor: greenInk,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: dark ? primary : greenDepth,
        linearTrackColor: dark ? cardDark : borderLight,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? mint : ink,
        contentTextStyle: fonts.bodyMedium?.copyWith(
          color: dark ? ink : Colors.white,
        ),
        shape: shape,
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1.5),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

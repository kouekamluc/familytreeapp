import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_frontend/config/royal_theme.dart';

double contrast(Color text, Color background) {
  final values = [text.computeLuminance(), background.computeLuminance()]
    ..sort();
  return (values.last + .05) / (values.first + .05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'mobile palette keeps action and body labels readable in both themes',
    () {
      GoogleFonts.config.allowRuntimeFetching = false;
      for (final theme in [RoyalTheme.lightTheme, RoyalTheme.darkTheme]) {
        final colors = theme.colorScheme;
        for (final pair in [
          (colors.onPrimary, colors.primary),
          (colors.onSecondary, colors.secondary),
          (colors.onSurface, colors.surface),
          (colors.onSurfaceVariant, colors.surface),
          (colors.onErrorContainer, colors.errorContainer),
        ]) {
          expect(
            contrast(pair.$1, pair.$2),
            greaterThanOrEqualTo(4.5),
            reason: '${theme.brightness}: text $pair',
          );
        }
      }
    },
  );
}

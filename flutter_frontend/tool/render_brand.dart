// Deterministic rendering of the code-native Eban mark, not a bitmap edit.
// Run explicitly with flutter test tool/render_brand.dart.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_frontend/widgets/kkevo_brand.dart';
import 'package:flutter_frontend/config/royal_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('render Eban brand assets', () async {
    Future<void> render(String path, int pixels, {bool badge = false}) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = pixels.toDouble();
      if (badge) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size, size),
            Radius.circular(size * .25),
          ),
          Paint()..color = RoyalTheme.green,
        );
      }
      canvas.save();
      final padding = size * (badge ? .18 : .04);
      canvas.translate(padding, padding);
      EbanPainter(
        badge ? RoyalTheme.greenInk : RoyalTheme.green,
      ).paint(canvas, Size.square(size - padding * 2));
      canvas.restore();
      final picture = recorder.endRecording();
      final image = await picture.toImage(pixels, pixels);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    }

    await render('assets/logo.png', 512);
    await render('assets/logo_badge.png', 512, badge: true);
    for (final entry in {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    }.entries) {
      await render(
        'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
        entry.value,
        badge: true,
      );
    }
  });
}

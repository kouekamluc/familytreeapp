// Render the same mobile workflows in two surface treatments for visual review.
// Run explicitly: flutter test tool/render_mobile_design.dart
// This explicit test renderer uses isolated plugin storage fixtures.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_frontend/config/royal_theme.dart';
import 'package:flutter_frontend/providers/auth_provider.dart';
import 'package:flutter_frontend/providers/tree_provider.dart';
import 'package:flutter_frontend/providers/theme_provider.dart';
import 'package:flutter_frontend/providers/accessibility_provider.dart';
import 'package:flutter_frontend/services/api_service.dart';
import 'package:flutter_frontend/views/mobile/mobile_welcome_view.dart';
import 'package:flutter_frontend/views/shell_view.dart';
import 'package:flutter_frontend/views/tree/tree_view.dart';
import 'package:flutter_frontend/widgets/relative_editor_dialog.dart';
import '../test/workflow_ui_test.dart' show WorkflowApi;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('compare green and warm mobile treatments', (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = WorkflowApi();
    final auth = AuthProvider(api), tree = TreeProvider(api);
    await tree.loadData();
    for (final treatment in ['green', 'warm', 'dark']) {
      final warm = treatment == 'warm';
      final base = treatment == 'dark'
          ? RoyalTheme.darkTheme
          : RoyalTheme.lightTheme;
      final theme = warm
          ? base.copyWith(
              scaffoldBackgroundColor: const Color(0xFFFFF9F0),
              colorScheme: base.colorScheme.copyWith(
                surface: const Color(0xFFFFFDF8),
              ),
              appBarTheme: base.appBarTheme.copyWith(
                backgroundColor: const Color(0xFFFFF9F0),
              ),
            )
          : base;
      for (final screen in ['welcome', 'home', 'tree', 'relationship']) {
        final capture = GlobalKey();
        final Widget content = switch (screen) {
          'welcome' => MobileWelcomeView(onExplore: () {}, onSignIn: () {}),
          'home' => const ShellView(),
          'tree' => const TreeView(),
          _ => RelativeEditorDialog(source: tree.people.first),
        };
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ApiService>.value(value: api),
              ChangeNotifierProvider.value(value: auth),
              ChangeNotifierProvider.value(value: tree),
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
            ],
            child: RepaintBoundary(
              key: capture,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: theme,
                home: content,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final frame = await boundary.toImage(pixelRatio: 2);
          final data = await frame.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/mobile-design/$treatment-$screen.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data!.buffer.asUint8List());
          frame.dispose();
        });
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    }
    auth.dispose();
    tree.dispose();
    api.dispose();
  });
}

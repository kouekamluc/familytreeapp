import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_frontend/main.dart';
import 'package:flutter_frontend/providers/auth_provider.dart';
import 'package:flutter_frontend/providers/tree_provider.dart';
import 'package:flutter_frontend/providers/theme_provider.dart';
import 'package:flutter_frontend/providers/accessibility_provider.dart';
import 'package:flutter_frontend/services/api_service.dart';
import 'package:flutter_frontend/widgets/mobile_person_sheet.dart';
import 'redesign_journey_test.dart' as journey;

void main() {
  journey.main();
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('phone tree: readable cards, zoom focal point, pan and profile', (
    tester,
  ) async {
    // A separate native journey must not inherit the previous Navigator.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    GoogleFonts.config.allowRuntimeFetching = false;
    final api = ApiService();
    await api.init();
    await api.demoLogin();
    final auth = AuthProvider(api), tree = TreeProvider(api);
    await tree.loadData();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ApiService>.value(value: api),
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: tree),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
        ],
        child: const RoyalAncestryApp(),
      ),
    );
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();
    await binding.takeScreenshot('mobile-home-example');
    await tester.drag(find.byType(ListView).first, const Offset(0, -460));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('mobile-journey-path');
    await tester.tap(find.text('Tree').last);
    await tester.pumpAndSettle();
    final viewer = find.byType(InteractiveViewer);
    final controller = tester
        .widget<InteractiveViewer>(viewer)
        .transformationController!;
    expect(controller.value.getMaxScaleOnAxis(), closeTo(1, .01));
    await binding.takeScreenshot('mobile-tree-example');
    final initial = controller.value.clone();
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pumpAndSettle();
    expect(
      controller.value.getMaxScaleOnAxis(),
      greaterThan(initial.getMaxScaleOnAxis()),
    );
    await tester.tap(find.byTooltip('Zoom out'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zoom out'));
    await tester.pumpAndSettle();
    final local = const Offset(40, 40);
    final point = tester.getTopLeft(viewer) + local;
    final sceneBefore = controller.toScene(local);
    final scaleBefore = controller.value.getMaxScaleOnAxis();
    await tester.tapAt(point);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tapAt(point);
    await tester.pumpAndSettle();
    expect(controller.value.getMaxScaleOnAxis(), greaterThan(scaleBefore));
    expect((controller.toScene(local) - sceneBefore).distance, lessThan(2));
    final beforePan = controller.value.clone();
    await tester.dragFrom(
      tester.getTopLeft(viewer) + const Offset(60, 90),
      const Offset(80, 50),
    );
    await tester.pumpAndSettle();
    expect(
      controller.value.storage[12],
      isNot(closeTo(beforePan.storage[12], 1)),
    );
    await tester.tap(find.byTooltip('View roots'));
    await tester.pumpAndSettle();
    final root = tree.people.where((p) => p.generationTier == 1).first;
    await tester.tap(find.text(root.fullName).last);
    await tester.pumpAndSettle();
    expect(find.byType(MobilePersonSheet), findsOneWidget);
    await binding.takeScreenshot('mobile-tree-profile');
    final beforeCenter = controller.value.clone();
    await tester.tap(find.text('Centre in tree'));
    await tester.pumpAndSettle();
    expect(find.byType(MobilePersonSheet), findsNothing);
    expect(
      controller.value.storage[13],
      isNot(closeTo(beforeCenter.storage[13], 1)),
    );
    expect(tester.takeException(), isNull);
    await api.logout();
  });
}

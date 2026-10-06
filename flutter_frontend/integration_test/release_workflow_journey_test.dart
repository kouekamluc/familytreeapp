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
import 'package:flutter_frontend/views/shell_view.dart';
import 'package:flutter_frontend/views/report_issue_view.dart';
import 'package:flutter_frontend/widgets/story_editor.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android stale story review, preserved unrelated changes and report receipt',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final api = ApiService();
      await api.init();
      await api.logout();
      final username = 'finish_${DateTime.now().millisecondsSinceEpoch}';
      expect(
        await api.register(
          username: username,
          email: '$username@example.test',
          password: 'Complete-Workflow-482!',
          firstName: 'Native',
          lastName: 'Tester',
        ),
        isTrue,
      );
      final family = await api.createTree(
        'Finishing workflow fixture',
        'Synthetic records',
      );
      expect(family, isNotNull);
      final person = await api.createPerson({
        'family_tree': family!.id,
        'first_name': 'Native',
        'last_name': 'Profile',
        'gender': 'O',
        'biography': 'Original memory',
      });
      expect(person, isNotNull);
      final tree = TreeProvider(api);
      await tree.loadData(targetTreeId: family.id);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ApiService>.value(value: api),
            ChangeNotifierProvider.value(value: AuthProvider(api)),
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
      Future<void> wait(bool Function() ready) async {
        for (var i = 0; i < 100 && !ready(); i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(ready(), isTrue, reason: api.lastError);
        await tester.pumpAndSettle();
      }

      Future<void> tap(String text) async {
        final target = find.text(text).last;
        await wait(() => target.evaluate().isNotEmpty);
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      expect(
        await api.updatePerson(person!.id, {
          'biography': 'Other editor’s memory',
          'birth_place': 'Other editor’s saved place',
          'revision': person.revision,
        }),
        isNotNull,
      );
      Navigator.of(
        tester.element(find.byType(ShellView)),
      ).push(MaterialPageRoute(builder: (_) => StoryEditor(person: person)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'My corrected memory');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tap('Save this memory');
      await wait(
        () => find.text('Review the latest version').evaluate().isNotEmpty,
      );
      await tap('Review the latest version');
      await wait(() => find.text('Use this revision').evaluate().isNotEmpty);
      expect(find.text('Other editor’s memory'), findsOneWidget);
      await binding.takeScreenshot('mobile-review-stale-memory');
      await tap('Use this revision');
      await tap('Save this memory');
      await wait(() => find.byType(StoryEditor).evaluate().isEmpty);
      final saved = await api.getPerson(person.id);
      expect(saved!.biography, 'My corrected memory');
      expect(saved.birthPlace, 'Other editor’s saved place');
      Navigator.of(
        tester.element(find.byType(ShellView)),
      ).push(MaterialPageRoute(builder: (_) => ReportIssueView(person: saved)));
      await wait(() => find.text('Send report').evaluate().isNotEmpty);
      await tester.tap(find.byType(TextFormField));
      await tester.enterText(
        find.byType(TextFormField),
        'Synthetic privacy concern for the review queue.',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tap('Send report');
      await wait(
        () => find
            .text('Report received. You can follow its review here.')
            .evaluate()
            .isNotEmpty,
      );
      expect((await api.getContentReports())!.length, 1);
      await binding.takeScreenshot('mobile-content-report-received');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await api.logout();
      tree.dispose();
    },
  );
}

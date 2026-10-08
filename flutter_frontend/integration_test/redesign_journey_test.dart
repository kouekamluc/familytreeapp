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
import 'package:flutter_frontend/widgets/person_editor_dialog.dart';
import 'package:flutter_frontend/widgets/relative_editor_dialog.dart';
import 'package:flutter_frontend/widgets/story_editor.dart';
import 'package:flutter_frontend/views/people/person_detail_view.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'redesigned native app: first family, guided adoption, story and relationship path',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final api = ApiService();
      await api.init();
      await api.logout();
      final username = 'redesign_${DateTime.now().millisecondsSinceEpoch}';
      expect(
        await api.register(
          username: username,
          email: '$username@example.test',
          password: 'Redesign-Test-482!',
          firstName: 'Camille',
          lastName: 'Famille',
        ),
        isTrue,
        reason: api.lastError,
      );
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
      Future<void> waitFor(bool Function() ready, String reason) async {
        for (var i = 0; i < 100 && !ready(); i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(ready(), isTrue, reason: reason);
        await tester.pumpAndSettle();
      }

      Future<void> tap(String text) async {
        final target = find.text(text).last;
        await waitFor(
          () => target.evaluate().isNotEmpty,
          'Missing action: $text',
        );
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      Future<void> enter(String label, String value) async {
        final field = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == label,
        );
        await waitFor(
          () => field.evaluate().isNotEmpty,
          'Missing field: $label',
        );
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        await tester.enterText(field, value);
        await tester.pump();
      }

      await tap('Start my family tree');
      await tap('Create a family tree');
      await enter('Family name *', 'Notre famille');
      await enter('Description', 'Notre histoire commence ici.');
      await tap('Save');
      await waitFor(
        () => tree.selectedTree != null,
        'Family creation failed: ${tree.lastSaveError}',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tap('Add your first person');
      expect(find.byType(PersonEditorDialog), findsOneWidget);
      await enter('First name *', 'Camille');
      await enter('Last name *', 'Famille');
      // Malformed manual dates must remain recoverable through Android's
      // calendar flow, without losing the profile draft.
      await enter('Date of birth', '0000-01-01');
      final birthCalendar = find.byIcon(Icons.calendar_today_outlined).first;
      await tester.ensureVisible(birthCalendar);
      await tester.pumpAndSettle();
      await tester.tap(birthCalendar);
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tap('Cancel');
      await enter('Date of birth', '1989-06-15');
      await tap('Save');
      await waitFor(
        () => find.byType(PersonEditorDialog).evaluate().isEmpty,
        'Person save failed: ${tree.lastSaveError}',
      );
      await tap('Continue');
      expect(tree.people.length, 1);
      await tap('Connect your family');
      expect(find.byType(RelativeEditorDialog), findsOneWidget);
      await tap('Adoption');
      await tap('Continue');
      await enter('First name *', 'Anna');
      await enter('Last name *', 'Famille');
      await tap('Continue');
      expect(
        find.text(
          'Camille Famille will be the adoptive parent of Anna Famille.',
        ),
        findsOneWidget,
      );
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot('redesign-relationship-preview');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('One person, one profile.'), findsOneWidget);
      await tap('Continue');
      await tap('Confirm connection');
      await waitFor(
        () => find.byType(RelativeEditorDialog).evaluate().isEmpty,
        'Adoption save failed: ${tree.lastSaveError}',
      );
      await tap('Continue');
      expect(tree.people.length, 2);
      expect(tree.relationships.single.relationshipType, 'ADOPTED');
      await tap('People');
      await tap('Camille Famille');
      expect(find.byType(PersonDetailView), findsOneWidget);
      await tap('Write a memory');
      await enter(
        'Their story',
        'Chaque dimanche, nous préparons ensemble les recettes de grand-mère.',
      );
      // Settle the real Android keyboard before scrolling to the save action.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tap('Save this memory');
      await waitFor(
        () => find.byType(StoryEditor).evaluate().isEmpty,
        'Story save failed: ${tree.lastSaveError}',
      );
      await tap('Continue');
      await tree.loadData();
      await tester.pumpAndSettle();
      expect(
        tree.people.firstWhere((p) => p.firstName == 'Camille').biography,
        contains('recettes de grand-mère'),
      );
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, 1800),
      );
      await tester.pumpAndSettle();
      await binding.takeScreenshot('redesign-profile');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tap('Links');
      await tap('Explore a relationship');
      final selectors = find.byType(DropdownButtonFormField<int>);
      await tester.tap(selectors.at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Camille Famille').last);
      await tester.pumpAndSettle();
      await tester.tap(selectors.at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anna Famille').last);
      await tester.pumpAndSettle();
      expect(find.text('Adopted child'), findsOneWidget);
      await binding.takeScreenshot('redesign-kinship');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tap('Tree');
      await binding.takeScreenshot('redesign-tree');
      await tap('Home');
      await tester.drag(find.byType(ListView).first, const Offset(0, 2200));
      await tester.pumpAndSettle();
      expect(find.text('3 / 5'), findsOneWidget);
      await binding.takeScreenshot('redesign-home');
      expect(tester.takeException(), isNull);
      await api.logout();
      debugPrint(
        'REDESIGN NATIVE JOURNEY PASSED: real family/person UI, adopted child preview and save, story persistence, parentage path, navigation and real-data progress.',
      );
    },
  );
}

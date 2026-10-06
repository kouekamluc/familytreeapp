import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_frontend/config/royal_theme.dart';
import 'package:flutter_frontend/models/family_tree.dart';
import 'package:flutter_frontend/models/person.dart';
import 'package:flutter_frontend/models/relationship.dart';
import 'package:flutter_frontend/providers/auth_provider.dart';
import 'package:flutter_frontend/providers/tree_provider.dart';
import 'package:flutter_frontend/services/api_service.dart';
import 'package:flutter_frontend/views/home_view.dart';
import 'package:flutter_frontend/widgets/relative_editor_dialog.dart';
import 'package:flutter_frontend/widgets/relationship_editor_dialog.dart';
import 'package:flutter_frontend/widgets/story_editor.dart';
import 'workflow_ui_test.dart' show WorkflowApi;

class RedesignApi extends WorkflowApi {
  Map<String, dynamic>? relativeRequest, update;
  int? source;
  bool onlyUnion = false;
  @override
  Future<List<Relationship>> getRelationships({int? treeId}) async => onlyUnion
      ? [
          Relationship(
            id: 1,
            person1Id: 1,
            person2Id: 2,
            relationshipType: 'SPOUSE',
          ),
        ]
      : await super.getRelationships(treeId: treeId);
  @override
  Future<Map<String, dynamic>?> createRelative(
    int personId,
    String role,
    Map<String, dynamic> person, {
    int? existingPersonId,
    int? coParentId,
    String? relationshipNotes,
    String? relationshipType,
  }) async {
    source = personId;
    relativeRequest = {
      'role': role,
      'person': person,
      'existing': existingPersonId,
      'coParent': coParentId,
      'type': relationshipType,
    };
    lastError = 'La connexion a été interrompue. Réessayez.';
    return null;
  }

  @override
  Future<Person?> updatePerson(int id, Map<String, dynamic> data) async {
    update = data;
    lastError = 'Le serveur refuse la modification.';
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });
  test('member progress uses accepted members rather than people', () {
    final tree = FamilyTree.fromJson({
      'id': 1,
      'name': 'Family',
      'members': [2, 3],
      'people': List.generate(30, (i) => i),
    });
    expect(tree.membersCount, 2);
    expect(
      FamilyTree.fromJson({
        'id': 2,
        'name': 'Empty',
        'people': [1],
      }).membersCount,
      0,
    );
  });
  Future<({RedesignApi api, TreeProvider tree})> pump(
    WidgetTester tester,
    Widget Function(TreeProvider) child, {
    double scale = 1,
  }) async {
    final api = RedesignApi();
    final provider = TreeProvider(api);
    await provider.loadData();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ApiService>.value(value: api),
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider(create: (_) => AuthProvider(api)),
        ],
        child: MaterialApp(
          theme: RoyalTheme.lightTheme,
          builder: (ctx, value) => MediaQuery(
            data: MediaQuery.of(
              ctx,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: value!,
          ),
          home: Scaffold(body: child(provider)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (api: api, tree: provider);
  }

  Future<void> tap(WidgetTester tester, String text) async {
    final target = find.text(text).last;
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String label, String value) async {
    final field = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == label,
    );
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.enterText(field, value);
    await tester.pump();
  }

  testWidgets(
    'family progress follows records and stays readable at large text',
    (tester) async {
      await pump(
        tester,
        (_) => HomeView(onNavigate: (_) {}, onOpenPerson: (_) {}),
        scale: 2,
      );
      expect(find.text('2 / 5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'adoptive branch previews direction and keeps failed save choices',
    (tester) async {
      final f = await pump(
        tester,
        (tree) => RelativeEditorDialog(source: tree.people.first),
      );
      await tap(tester, 'Adoption');
      await tap(tester, 'Continue');
      await enter(tester, 'First name *', 'Anna');
      await enter(tester, 'Last name *', 'Family');
      await tap(tester, 'Continue');
      expect(
        find.text(
          'Parent with a long recorded name Example will be the adoptive parent of Anna Family.',
        ),
        findsOneWidget,
      );
      await tap(tester, 'Confirm connection');
      expect(f.api.relativeRequest!['type'], 'ADOPTED');
      expect(f.api.relativeRequest!['role'], 'child');
      expect(f.api.source, 1);
      expect(
        find.text('La connexion a été interrompue. Réessayez.'),
        findsOneWidget,
      );
      await tap(tester, 'Back');
      final field = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'First name *',
      );
      expect(tester.widget<TextField>(field).controller!.text, 'Anna');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'existing relationship preview shows parent and child before saving',
    (tester) async {
      await pump(
        tester,
        (tree) =>
            RelationshipEditorDialog(relationship: tree.relationships.first),
      );
      await tap(tester, 'Continue');
      await tap(tester, 'Continue');
      expect(
        find.text('Parent with a long recorded name Example'),
        findsOneWidget,
      );
      expect(find.text('Child Example'), findsOneWidget);
      expect(find.text('Adoptive parent → child'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('story editor keeps the draft when saving fails', (tester) async {
    final f = await pump(
      tester,
      (tree) => StoryEditor(person: tree.people.first),
    );
    await enter(
      tester,
      'Their story',
      'Une tradition familiale à transmettre.',
    );
    await tap(tester, 'Save this memory');
    expect(
      f.api.update!['biography'],
      'Une tradition familiale à transmettre.',
    );
    expect(f.api.update!['revision'], 1);
    expect(find.text('Le serveur refuse la modification.'), findsOneWidget);
    expect(find.text('Une tradition familiale à transmettre.'), findsOneWidget);
  });
  testWidgets(
    'ancestor branch preserves life dates and Android Back preserves the draft',
    (tester) async {
      final f = await pump(
        tester,
        (tree) =>
            RelativeEditorDialog(source: tree.people.first, role: 'parent'),
      );
      await tap(tester, 'Continue');
      await enter(tester, 'First name *', 'Grandparent');
      await enter(tester, 'Last name *', 'Family');
      await tap(tester, 'Dates and roots (optional)');
      await enter(tester, 'Date of birth', '1940-03-02');
      await tap(tester, 'Living person');
      await enter(tester, 'Date of death', '2020-04-03');
      await tap(tester, 'Continue');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('One person, one profile.'), findsOneWidget);
      await tap(tester, 'Continue');
      await tap(tester, 'Confirm connection');
      final person = f.api.relativeRequest!['person'] as Map<String, dynamic>;
      expect(person['is_living'], isFalse);
      expect(person['date_of_birth'], '1940-03-02');
      expect(person['date_of_death'], '2020-04-03');
      expect(f.api.relativeRequest!['role'], 'parent');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('a recorded partnership completes the connection step', (
    tester,
  ) async {
    final f = await pump(
      tester,
      (_) => HomeView(onNavigate: (_) {}, onOpenPerson: (_) {}),
    );
    f.api.onlyUnion = true;
    await f.tree.loadData();
    await tester.pumpAndSettle();
    expect(find.text('2 / 5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter_frontend/providers/auth_provider.dart';
import 'package:flutter_frontend/widgets/tree_manager_sheet.dart';
import 'package:flutter_frontend/widgets/relationship_editor_dialog.dart';
import 'package:flutter_frontend/widgets/relative_editor_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_frontend/models/family_tree.dart';
import 'package:flutter_frontend/models/person.dart';
import 'package:flutter_frontend/providers/tree_provider.dart';
import 'package:flutter_frontend/services/api_service.dart';
import 'package:flutter_frontend/services/android_handoff.dart';
import 'package:flutter_frontend/services/edit_drafts.dart';
import 'package:flutter_frontend/services/credential_storage.dart';
import 'package:flutter_frontend/services/mutation_ticket.dart';
import 'package:flutter_frontend/config/api_config.dart';
import 'package:flutter_frontend/widgets/person_editor_dialog.dart';
import 'package:flutter_frontend/widgets/story_editor.dart';
import 'package:flutter_frontend/views/report_issue_view.dart';
import 'workflow_ui_test.dart' show WorkflowApi;

class ReleaseApi extends WorkflowApi {
  Person record = Person(
    id: 1,
    familyTreeId: 1,
    firstName: 'Original',
    lastName: 'Family',
    gender: 'O',
    biography: 'Original story',
  );
  Person latest = Person(
    id: 1,
    familyTreeId: 1,
    firstName: 'Original',
    lastName: 'Family',
    gender: 'O',
    birthPlace: 'Saved by the other editor',
    biography: 'Other story',
    revision: 2,
  );
  Map<String, dynamic>? sent;
  int updates = 0;
  bool revoked = false, graphFailure = false, multiplePeople = false;
  int reportCalls = 0, importCalls = 0;
  @override
  Future<bool> importTreeData(
    Map<String, dynamic> data, {
    required int treeId,
    String? requestKey,
  }) async {
    importCalls++;
    lastError = 'Unable to import right now. Your records have not been added.';
    return false;
  }

  String? reportKey;
  @override
  Future<List<dynamic>?> getContentReports() async => [];
  @override
  Future<Map<String, dynamic>?> reportContent(
    Map<String, dynamic> payload,
  ) async {
    reportCalls++;
    if (reportCalls == 1) {
      reportKey = payload['request_key'] as String;
      lastError = 'Unable to send the report. Your information is kept.';
      return null;
    }
    expect(payload['request_key'], reportKey);
    return {
      'id': 1,
      'reason': payload['reason'],
      'details': payload['details'],
      'status': 'OPEN',
      'response': '',
    };
  }

  @override
  Future<List<FamilyTree>> getTrees() async => revoked
      ? [FamilyTree(id: 2, name: 'Other family', owner: 'owner', canEdit: true)]
      : super.getTrees();
  @override
  Future<List<Person>> getPeople({int? treeId}) async {
    if (graphFailure) throw StateError('Synthetic interrupted load');
    return [
      record,
      if (multiplePeople)
        Person(
          id: 2,
          familyTreeId: 1,
          firstName: "Other",
          lastName: "Family",
          gender: "O",
        ),
    ];
  }

  @override
  Future<Person?> getPerson(int id) async => latest;
  @override
  Future<Person?> updatePerson(int id, Map<String, dynamic> data) async {
    sent = Map.of(data);
    updates++;
    if (updates == 1) {
      lastRevisionConflict = true;
      lastError =
          'This record has changed. Review the latest version before saving your changes.';
      return null;
    }
    expect(data['revision'], 2);
    record = Person.fromJson({...latest.toJson(), ...data, 'revision': 3});
    lastRevisionConflict = false;
    return record;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  test(
    'pending mutation survives service recreation, changes with the payload and clears on acknowledgement',
    () async {
      final first = MutationTicket('server:account1', 'create-person:2');
      final key = await first.begin('same synthetic payload');
      final recreated = MutationTicket('server:account1', 'create-person:2');
      expect(await recreated.begin('same synthetic payload'), key);
      expect(
        await MutationTicket(
          'server:account2',
          'create-person:2',
        ).begin('same synthetic payload'),
        isNot(key),
      );
      final corrected = await recreated.begin('corrected payload');
      expect(corrected, isNot(key));
      await recreated.finish(
        key,
      ); // A late acknowledgement must not clear a newer attempt.
      expect(await first.begin('corrected payload'), corrected);
      await recreated.finish(corrected);
      expect(await first.begin('corrected payload'), isNot(corrected));
      await MutationTicket.clearAccount('server:account1');
    },
  );
  test(
    'server settings reject credentials and unrelated URL paths before any request',
    () {
      expect(
        ApiConfig.normalizeBaseUrl('https://family.example/'),
        'https://family.example/api',
      );
      for (final url in [
        'https://user:password@family.example/api',
        'https://family.example/api?token=secret',
        'https://family.example/api#fragment',
        'https://family.example/unrelated',
        'file:///private',
        'javascript:alert(1)',
      ]) {
        expect(() => ApiConfig.normalizeBaseUrl(url), throwsFormatException);
      }
    },
  );
  Future<TreeProvider> pump(
    WidgetTester tester,
    ReleaseApi api,
    Widget Function(TreeProvider) editor,
  ) async {
    final tree = TreeProvider(api);
    await tree.loadData();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ApiService>.value(value: api),
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(api),
          ),
          ChangeNotifierProvider<TreeProvider>.value(value: tree),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: ctx,
                  barrierDismissible: false,
                  builder: (_) => editor(tree),
                ),
                child: const Text('Open editor'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    return tree;
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'profile conflict requires review and preserves another editor’s untouched fields',
    (tester) async {
      final api = ReleaseApi();
      await pump(tester, api, (_) => PersonEditorDialog(person: api.record));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'First name *'),
        'My correction',
      );
      await tap(tester, 'Save');
      expect(api.updates, 1);
      await tap(tester, 'Review the latest version');
      expect(find.text('Original'), findsOneWidget);
      expect(find.text('My correction'), findsNWidgets(2));
      await tap(tester, 'Use this revision');
      expect(api.updates, 1, reason: 'Review never sends a write.');
      await tap(tester, 'Save');
      expect(api.sent!.keys.toSet(), {'first_name', 'revision'});
      expect(api.record.birthPlace, 'Saved by the other editor');
      expect(api.record.biography, 'Other story');
      expect(find.text('Open editor'), findsOneWidget);
    },
  );

  testWidgets(
    'a failed report keeps the concern and retries the same receipt at large phone text',
    (tester) async {
      final api = ReleaseApi();
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pump(
        tester,
        api,
        (_) => MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            textScaler: TextScaler.linear(2),
          ),
          child: ReportIssueView(person: api.record),
        ),
      );
      await tester.enterText(
        find.byType(TextFormField),
        'Please review this synthetic portrait.',
      );
      await tap(tester, 'Send report');
      expect(
        find.text('Please review this synthetic portrait.'),
        findsOneWidget,
      );
      expect(
        find.text('Unable to send the report. Your information is kept.'),
        findsOneWidget,
      );
      await tap(tester, 'Send report');
      expect(find.text('Received'), findsOneWidget);
      expect(api.reportCalls, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'story conflict and native back keep the draft until explicit discard',
    (tester) async {
      final api = ReleaseApi();
      await pump(tester, api, (_) => StoryEditor(person: api.record));
      await tester.enterText(find.byType(TextField), 'My memory');
      await tap(tester, 'Save this memory');
      await tap(tester, 'Review the latest version');
      expect(find.text('Other story'), findsOneWidget);
      await tap(tester, 'Use this revision');
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      await navigator.maybePop();
      await tester.pumpAndSettle();
      expect(find.text('Discard your changes?'), findsOneWidget);
      await tap(tester, 'Keep editing');
      expect(find.text('My memory'), findsOneWidget);
      await tap(tester, 'Save this memory');
      expect(api.record.biography, 'My memory');
      expect(api.record.birthPlace, 'Saved by the other editor');
    },
  );

  testWidgets(
    'interrupted profile draft restores privately and discard removes it',
    (tester) async {
      final api = ReleaseApi();
      await pump(tester, api, (_) => PersonEditorDialog(person: api.record));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'First name *'),
        'Unfinished',
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        const SizedBox.shrink(),
      ); // Dispose the view without a save or discard.
      await tester.pumpAndSettle();
      await pump(tester, api, (_) => PersonEditorDialog(person: api.record));
      expect(find.text('Continue your unsaved changes?'), findsOneWidget);
      await tap(tester, 'Restore draft');
      expect(find.text('Unfinished'), findsOneWidget);
      await tap(tester, 'Cancel');
      await tap(tester, 'Discard');
      await tap(tester, 'Open editor');
      expect(find.text('Continue your unsaved changes?'), findsNothing);
      expect(find.text('Original'), findsOneWidget);
    },
  );

  testWidgets(
    'relative wizard restores entered facts and stage after interruption without writing',
    (tester) async {
      final api = ReleaseApi();
      await pump(tester, api, (_) => RelativeEditorDialog(source: api.record));
      await tap(tester, 'Continue');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'First name *'),
        'Unsaved relative',
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await pump(tester, api, (_) => RelativeEditorDialog(source: api.record));
      expect(find.text('Continue your unsaved changes?'), findsOneWidget);
      await tap(tester, 'Restore draft');
      expect(find.text('STEP 2 OF 3'), findsOneWidget);
      expect(find.text('Unsaved relative'), findsOneWidget);
      expect(api.createCalls, 0);
      await tap(tester, 'Back');
      await tap(tester, 'Cancel');
      await tap(tester, 'Discard');
      await tester.pumpWidget(const SizedBox());
      await pump(tester, api, (_) => RelativeEditorDialog(source: api.record));
      expect(find.text('Continue your unsaved changes?'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'connection wizard restores changed type and notes without submitting',
    (tester) async {
      final api = ReleaseApi()..multiplePeople = true;
      await pump(tester, api, (_) => const RelationshipEditorDialog());
      await tap(tester, 'Adoptive parent → child');
      await tap(tester, 'Continue');
      await tap(tester, 'Continue');
      await tap(tester, 'Dates and details (optional)');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Notes'),
        'Unfinished connection',
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await pump(tester, api, (_) => const RelationshipEditorDialog());
      expect(find.text('Continue your unsaved changes?'), findsOneWidget);
      await tap(tester, 'Restore draft');
      expect(find.text('STEP 3 OF 3'), findsOneWidget);
      await tap(tester, 'Dates and details (optional)');
      expect(find.text('Unfinished connection'), findsOneWidget);
      expect(api.sent, isNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'import previews counts and destination before any write, with cancellation and retry',
    (tester) async {
      final api = ReleaseApi();
      await pump(tester, api, (_) => const Material(child: TreeManagerSheet()));
      await tap(tester, 'Import JSON');
      final input = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'JSON export',
      );
      await tester.enterText(input, '{}');
      await tap(tester, 'Add records');
      expect(
        find.text('Use a family export with people and connections.'),
        findsOneWidget,
      );
      expect(api.importCalls, 0);
      await tester.enterText(
        input,
        '{"people":[{"pk":1,"fields":{"first_name":"Synthetic","last_name":"Person","gender":"O"}}],"relationships":[]}',
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tap(tester, 'Add records');
      expect(find.text('Review these copies'), findsOneWidget);
      expect(find.text('Recorded family'), findsWidgets);
      expect(find.text('1'), findsOneWidget);
      expect(api.importCalls, 0);
      await tap(tester, 'Cancel');
      expect(find.text('Import people'), findsOneWidget);
      expect(api.importCalls, 0);
      await tap(tester, 'Add records');
      await tap(tester, 'Add these copies');
      expect(api.importCalls, 1);
      expect(
        find.text(
          'Unable to import right now. Your records have not been added.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  test('drafts do not cross accounts or servers and expire', () async {
    final draft = EditDrafts('https://one.example/api:1', 'family:3:story:4');
    await draft.write({'story': 'Private'});
    expect(
      await EditDrafts('https://one.example/api:2', 'family:3:story:4').read(),
      isNull,
    );
    expect(
      await EditDrafts('https://two.example/api:1', 'family:3:story:4').read(),
      isNull,
    );
    expect((await draft.read())!['story'], 'Private');
    await EditDrafts.clearAccount('https://one.example/api:1');
    expect(await draft.read(), isNull);
    final expiredKey = '${EditDrafts.prefix('expired')}Zm9ybQ==';
    await CredentialStorage().write(
      expiredKey,
      '{"saved_at":"2000-01-01T00:00:00Z","draft":{"story":"Old"}}',
    );
    expect(await EditDrafts('expired', 'form').read(), isNull);
  });

  test(
    'fresh removal of access clears records even if the next family load fails',
    () async {
      final api = ReleaseApi(), tree = TreeProvider(ReleaseApi());
      tree.dispose();
      final provider = TreeProvider(api);
      await provider.loadData();
      expect(provider.people, isNotEmpty);
      api.revoked = api.graphFailure = true;
      await provider.loadData();
      expect(provider.people, isEmpty);
      expect(provider.selectedTree, isNull);
      expect(provider.trees.single.id, 2);
      provider.dispose();
    },
  );

  test(
    'Android handoff distinguishes cancellation and keeps invitation secrets out of filenames',
    () async {
      const channel = MethodChannel('com.kkevo.family/handoff');
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return switch (call.method) {
              'openJson' => '{"people":[]}',
              'saveJson' => null,
              _ => null,
            };
          });
      expect(await AndroidHandoff.openJson(), '{"people":[]}');
      expect(await AndroidHandoff.saveJson('{"people":[]}'), isFalse);
      await AndroidHandoff.shareInvitation(
        'Synthetic invitation',
        'Share invitation',
      );
      expect(calls.last.arguments, {
        'text': 'Synthetic invitation',
        'title': 'Share invitation',
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    },
  );
}

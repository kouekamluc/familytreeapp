import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_frontend/config/royal_theme.dart';
import 'package:flutter_frontend/models/family_tree.dart';
import 'package:flutter_frontend/models/heritage_key.dart';
import 'package:flutter_frontend/models/person.dart';
import 'package:flutter_frontend/models/relationship.dart';
import 'package:flutter_frontend/models/user.dart';
import 'package:flutter_frontend/utils/kinship_solver.dart';
import 'package:flutter_frontend/providers/accessibility_provider.dart';
import 'package:flutter_frontend/providers/auth_provider.dart';
import 'package:flutter_frontend/providers/theme_provider.dart';
import 'package:flutter_frontend/providers/tree_provider.dart';
import 'package:flutter_frontend/services/api_service.dart';
import 'package:flutter_frontend/services/local_storage_service.dart';
import 'package:flutter_frontend/views/shell_view.dart';
import 'package:flutter_frontend/views/family_connections_view.dart';
import 'package:flutter_frontend/views/auth/login_view.dart';
import 'package:flutter_frontend/views/people/people_list_view.dart';
import 'package:flutter_frontend/views/people/person_detail_view.dart';
import 'package:flutter_frontend/views/kinship/kinship_calculator_view.dart';
import 'package:flutter_frontend/views/relationships/relationship_list_view.dart';
import 'package:flutter_frontend/views/tree/tree_view.dart';
import 'package:flutter_frontend/views/vault/heritage_vault_view.dart';
import 'package:flutter_frontend/widgets/person_editor_dialog.dart';
import 'package:flutter_frontend/widgets/relationship_editor_dialog.dart';
import 'package:flutter_frontend/widgets/relative_editor_dialog.dart';
import 'package:flutter_frontend/widgets/royal_button.dart';
import 'package:flutter_frontend/widgets/tree_manager_sheet.dart';
import 'package:flutter_frontend/widgets/ancestor_search_form.dart';
import 'package:flutter_frontend/widgets/user_profile_sheet.dart';
import 'package:flutter_frontend/widgets/mobile_person_sheet.dart';
import 'package:flutter_frontend/widgets/node_action_sheet.dart';

class WorkflowApi extends ApiService {
  @override
  Future<Map<String, dynamic>?> familyBranches(
    int treeId, {
    Map<String, dynamic>? payload,
  }) async => {'outgoing': [], 'incoming': [], 'visible': []};
  Map<String, dynamic> accessData = {
    'requests': [],
    'members': [],
    'invitations': [],
  };
  bool accessFail = false;
  List<dynamic> matches = [];
  final List<Map<String, dynamic>> accessPayloads = [];
  int treeCreates = 0;
  @override
  Future<FamilyTree?> createTree(String name, String description) async {
    treeCreates++;
    return null;
  }

  @override
  Future<Map<String, dynamic>?> getFamilyAccess({int? treeId}) async =>
      accessData;
  @override
  Future<Map<String, dynamic>?> familyAccess(
    Map<String, dynamic> payload,
  ) async {
    accessPayloads.add(payload);
    if (accessFail) {
      lastError = 'Code inconnu, expiré ou révoqué.';
      return null;
    }
    return payload['action'] == 'matches' ? {'matches': matches} : {'id': 1};
  }

  bool signedIn = true;
  bool editable = true;
  int createCalls = 0;
  Completer<Person?>? pendingPerson;
  Completer<List<HeritageKey>>? pendingKeys;
  User user = User(
    id: 1,
    username: 'owner',
    email: 'owner@example.test',
    firstName: 'Account',
    lastName: 'Owner',
  );
  @override
  User? get currentUser => signedIn ? user : null;
  @override
  bool get isAuthenticated => signedIn;
  @override
  String get identity => signedIn ? 'workflow:${user.id}' : 'guest';
  @override
  Future<List<FamilyTree>> getTrees() async => [
    FamilyTree(
      id: 1,
      name: 'Recorded family',
      owner: editable ? 'owner' : 'someone-else',
      canEdit: editable,
      canManage: editable,
      peopleCount: 3,
    ),
  ];
  @override
  Future<List<Person>> getPeople({int? treeId}) async => [
    Person(
      id: 1,
      familyTreeId: 1,
      firstName: 'Parent with a long recorded name',
      lastName: 'Example',
      gender: 'O',
      generationTier: 1,
    ),
    Person(
      id: 2,
      familyTreeId: 1,
      firstName: 'Child',
      lastName: 'Example',
      gender: 'F',
      generationTier: 5,
    ),
    Person(
      id: 3,
      familyTreeId: 1,
      firstName: 'Sibling',
      lastName: 'Example',
      gender: 'M',
      generationTier: 5,
    ),
  ];
  @override
  Future<List<Relationship>> getRelationships({int? treeId}) async => [
    Relationship(
      id: 1,
      person1Id: 1,
      person2Id: 2,
      relationshipType: 'ADOPTED',
    ),
    Relationship(
      id: 2,
      person1Id: 2,
      person2Id: 3,
      relationshipType: 'SIBLING',
    ),
    Relationship(
      id: 3,
      person1Id: 1,
      person2Id: 3,
      relationshipType: 'SPOUSE',
      isCurrent: false,
    ),
  ];
  @override
  Future<Person?> createPerson(Map<String, dynamic> data) async {
    createCalls++;
    if (pendingPerson != null) return pendingPerson!.future;
    lastError = 'Le serveur refuse cette fiche.';
    return null;
  }

  @override
  Future<List<HeritageKey>> getHeritageKeys() async =>
      pendingKeys?.future ??
      [
        HeritageKey(
          id: 1,
          key: 'PERSONAL-EXAMPLE-KEY',
          name: 'Personal key with a long descriptive name',
          role: 'FAMILY_MEMBER',
          isActive: true,
          usageCount: 2,
        ),
      ];
}

void main() {
  test('ancestor form rejects invented dates and omits unknown facts', () {
    final facts = {
      'parent_name': 'Mariam Family',
      'grandparent_name': 'Samuel Family',
      'ancestor_level': 2,
      'parent_birth_date': '',
    };
    expect(AncestorSearchForm.validate(facts), isNull);
    expect(
      AncestorSearchForm.payload(facts).containsKey('parent_birth_date'),
      isFalse,
    );
    expect(
      AncestorSearchForm.validate({
        ...facts,
        'parent_birth_date': '1900-02-30',
      }),
      isNotNull,
    );
    expect(
      AncestorSearchForm.validate({
        ...facts,
        'grandparent_birth_date': '2999-01-01',
      }),
      isNotNull,
    );
    expect(
      AncestorSearchForm.validate({...facts, 'grandparent_name': ''}),
      isNotNull,
    );
  });
  test('kinship generation badges follow recorded links for every gender', () {
    final people = [
      Person(id: 1, firstName: 'Parent', lastName: 'Test', gender: 'O'),
      Person(id: 2, firstName: 'Child', lastName: 'Test', gender: 'O'),
      Person(id: 3, firstName: 'Grandchild', lastName: 'Test', gender: 'O'),
    ];
    KinshipResult result(int a, int b, List<Relationship> links) =>
        KinshipSolver.calculateKinship(
          personAId: a,
          personBId: b,
          people: people,
          relationships: links,
        )!;
    for (final type in ['PARENT', 'ADOPTED', 'STEP']) {
      final links = [
        Relationship(id: 1, person1Id: 1, person2Id: 2, relationshipType: type),
      ];
      expect(result(1, 2, links).generationDifference, -1);
      expect(result(2, 1, links).generationDifference, 1);
    }
    final links = [
      Relationship(
        id: 1,
        person1Id: 1,
        person2Id: 2,
        relationshipType: 'PARENT',
      ),
      Relationship(
        id: 2,
        person1Id: 2,
        person2Id: 3,
        relationshipType: 'PARENT',
      ),
    ];
    expect(result(1, 3, links).generationDifference, -2);
    expect(result(3, 1, links).generationDifference, 2);
    expect(result(1, 3, links).path.map((p) => p.id), [1, 2, 3]);
  });
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  Future<
    ({
      WorkflowApi api,
      TreeProvider tree,
      AuthProvider auth,
      Widget Function(Widget) wrap,
    })
  >
  fixture() async {
    final api = WorkflowApi();
    final tree = TreeProvider(api);
    final auth = AuthProvider(api);
    await tree.loadData();
    Widget wrap(Widget child) => MultiProvider(
      providers: [
        ChangeNotifierProvider<ApiService>.value(value: api),
        ChangeNotifierProvider.value(value: tree),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
      ],
      child: child,
    );
    return (api: api, tree: tree, auth: auth, wrap: wrap);
  }

  Future<void> pump(
    WidgetTester tester,
    Widget Function(Widget) wrap,
    Widget child, {
    double scale = 1,
    Size size = const Size(360, 800),
    bool dark = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      wrap(
        MaterialApp(
          theme: dark ? RoyalTheme.darkTheme : RoyalTheme.lightTheme,
          builder: (ctx, child) => MediaQuery(
            data: MediaQuery.of(
              ctx,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('phone welcome opens password login and registration', (
    tester,
  ) async {
    final f = await fixture();
    f.api.signedIn = false;
    await pump(tester, f.wrap, const ShellView());
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginView), findsOneWidget);
    await tester.tap(find.text('Password').first);
    await tester.pumpAndSettle();
    final register = find.text('New here? Create an account');
    await tester.ensureVisible(register);
    await tester.tap(register);
    await tester.pumpAndSettle();
    expect(find.text('Confirm password'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed person save keeps values and prevents duplicate submissions',
    (tester) async {
      final f = await fixture();
      f.api.pendingPerson = Completer<Person?>();
      await pump(tester, f.wrap, const PersonEditorDialog());
      Future<void> fill(String label, String value) async {
        final field = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == label,
        );
        await tester.ensureVisible(field);
        await tester.enterText(field, value);
      }

      await fill('First name *', 'Recorded');
      await fill('Last name *', 'Person');
      final submit = find.widgetWithText(FilledButton, 'Save');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      expect(f.api.createCalls, 1);
      final pendingButton = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(pendingButton.onPressed, isNull);
      f.api.lastError = 'Erreur de validation du serveur.';
      f.api.pendingPerson!.complete(null);
      await tester.pumpAndSettle();
      expect(find.text('Erreur de validation du serveur.'), findsOneWidget);
      expect(find.text('Recorded'), findsOneWidget);
      expect(find.text('Person'), findsOneWidget);
    },
  );

  test(
    'dates reject impossible calendar days without rejecting unknown dates',
    () {
      expect(DateFormField.validateDate(''), isNull);
      expect(DateFormField.validateDate('2024-02-29'), isNull);
      expect(DateFormField.validateDate('2023-02-29'), isNotNull);
      expect(DateFormField.validateDate('2024-13-01'), isNotNull);
      expect(DateFormField.validateDate('0000-01-01'), isNotNull);
    },
  );

  testWidgets(
    'relationship list accurately names sibling adoptive and former-spouse links',
    (tester) async {
      final f = await fixture();
      await pump(tester, f.wrap, const RelationshipListView());
      expect(find.text('Adoptive parent → child'), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -650));
      await tester.pumpAndSettle();
      expect(find.text('Sibling'), findsOneWidget);
      expect(find.text('Former partners'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('public reader cannot add people or edit relationships', (
    tester,
  ) async {
    final f = await fixture();
    f.api.editable = false;
    await f.tree.loadData();
    await pump(tester, f.wrap, const RelationshipListView());
    expect(find.text('Add a connection'), findsNothing);
    expect(find.byTooltip('Connection options'), findsNothing);
    expect(find.text('Explore a relationship'), findsOneWidget);
    await pump(tester, f.wrap, const PeopleListView());
    expect(
      tester
          .widget<FilledButton>(
            find.byWidgetPredicate((w) => w is FilledButton).first,
          )
          .onPressed,
      isNull,
    );
  });

  test('late key response cannot reveal previous account keys', () async {
    final api = WorkflowApi();
    final auth = AuthProvider(api);
    api.pendingKeys = Completer<List<HeritageKey>>();
    final request = auth.fetchHeritageKeys();
    api.user = User(id: 2, username: 'second', email: 'second@example.test');
    api.notifyListeners();
    api.pendingKeys!.complete([
      HeritageKey(
        id: 1,
        key: 'OLD-PRIVATE-KEY',
        name: 'Old',
        role: 'FAMILY_MEMBER',
        isActive: true,
        usageCount: 0,
      ),
    ]);
    await request;
    expect(auth.heritageKeys, isEmpty);
    expect(auth.isLoadingKeys, isFalse);
  });

  test('deleted graph is pruned from nonempty offline chooser', () async {
    final local = LocalStorageService();
    await local.cacheSnapshot(
      [FamilyTree(id: 1, name: 'Deleted'), FamilyTree(id: 2, name: 'Keep')],
      1,
      [Person(id: 1, firstName: 'Private', lastName: 'Record', gender: 'O')],
      [],
      accountScope: 'workflow',
    );
    await local.cacheTrees([
      FamilyTree(id: 2, name: 'Keep'),
    ], accountScope: 'workflow');
    expect((await local.getCachedTrees(accountScope: 'workflow')).single.id, 2);
    expect(await local.getCachedPeople(1, accountScope: 'workflow'), isEmpty);
    expect(await local.getLastActiveTreeId(accountScope: 'workflow'), isNull);
  });

  testWidgets('styled buttons work with keyboard and expose button semantics', (
    tester,
  ) async {
    var count = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoyalButton(label: 'Save record', onPressed: () => count++),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(count, 1);
    expect(
      tester.getSemantics(find.byType(FilledButton)),
      matchesSemantics(
        label: 'Save record',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        isFocused: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
  });

  for (final scale in [1.0, 2.0]) {
    for (final size in [const Size(360, 800), const Size(1280, 900)]) {
      testWidgets(
        'existing screens fit ${size.width}px with text scale $scale',
        (tester) async {
          final f = await fixture();
          final screens = <Widget>[
            const ShellView(),
            const PeopleListView(),
            const RelationshipListView(),
            const KinshipCalculatorView(),
            const TreeView(),
            PersonDetailView(person: f.tree.people.first),
            const HeritageVaultView(),
            const UserProfileSheet(),
            const TreeManagerSheet(),
            const PersonEditorDialog(),
            const RelationshipEditorDialog(),
            RelativeEditorDialog(source: f.tree.people.first),
            MobilePersonSheet(
              person: f.tree.people.first,
              onInspectKinship: () {},
              onCenterInTree: () {},
              onOpenFullProfile: () {},
            ),
            NodeActionSheet(person: f.tree.people.first),
          ];
          for (final screen in screens) {
            await pump(
              tester,
              f.wrap,
              screen,
              scale: scale,
              size: size,
              dark: scale == 1,
            );
            expect(
              tester.takeException(),
              isNull,
              reason: '${screen.runtimeType} at $size and scale $scale',
            );
          }
        },
      );
    }
  }

  testWidgets(
    'family joining stays reachable at large phone text and preserves rejected input',
    (tester) async {
      final f = await fixture();
      f.api.accessFail = true;
      await pump(tester, f.wrap, const FamilyConnectionsView(), scale: 2);
      final code = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Invitation code',
      );
      await tester.ensureVisible(code);
      await tester.pumpAndSettle();
      await tester.enterText(code, 'INVALID-EXAMPLE');
      final submit = find.text('Request to join');
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(
        (tester.widget<TextField>(code).controller!).text,
        'INVALID-EXAMPLE',
      );
      expect(
        find.text('This invitation code is invalid, expired or revoked.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'family owner review and rights fit a small phone at large text',
    (tester) async {
      final f = await fixture();
      f.api.accessData = {
        'discovery_enabled': false,
        'invitations': [],
        'requests': [
          {
            'id': 1,
            'status': 'PENDING',
            'applicant': 'Long applicant family name',
            'person': {'first_name': 'Anna', 'last_name': 'Family'},
            'mode': 'EXISTING',
            'anchor_name': 'Anna recorded family',
            'evidence': {},
          },
        ],
        'members': [
          {
            'user_id': 2,
            'name': 'A member with a long family name',
            'person_name': 'A recorded person',
            'role': 'VIEWER',
          },
        ],
      };
      await pump(
        tester,
        f.wrap,
        const FamilyConnectionsView(treeId: 1),
        scale: 2,
      );
      await tester.ensureVisible(find.text('Approve'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm this member?'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('View only\nA recorded person'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'creation checks known grandparents before creating a duplicate and carries facts to inquiry',
    (tester) async {
      final f = await fixture();
      f.api.matches = [
        {
          'candidate': 'signed-candidate',
          'family_name': 'Possible extended family',
          'reason':
              'Two linked ancestor names match. Family confirmation is required.',
          'ancestor_level': 2,
          'evidence_level': 'NAMES_ONLY',
          'relationship_type': 'PARENT',
        },
      ];
      await pump(tester, f.wrap, const TreeManagerSheet(), scale: 1.6);
      Future<void> tap(String label) async {
        final found = find.text(label).last;
        await tester.ensureVisible(found);
        await tester.pumpAndSettle();
        await tester.tap(found);
        await tester.pumpAndSettle();
      }

      Future<void> enter(String label, String value) async {
        final found = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == label,
        );
        await tester.ensureVisible(found);
        await tester.enterText(found, value);
        await tester.pumpAndSettle();
      }

      await tap('Create a family tree');
      await enter('Family name *', 'My extended family');
      await tap('I know two consecutive ancestors');
      await enter('Grandparent’s full name', 'Mariam Family');
      await enter(
        'Their parent’s full name (your great-grandparent)',
        'Samuel Family',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tap('Save');
      expect(find.text('This family may already exist'), findsOneWidget);
      expect(f.api.treeCreates, 0);
      expect(f.api.accessPayloads.last['ancestor_level'], 2);
      await tap('Explore these connections');
      expect(find.byType(FamilyConnectionsView), findsOneWidget);
      expect(find.text('Mariam Family'), findsOneWidget);
      await tap('Ask if we are related');
      await enter('Message', 'My grandmother came from this branch.');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tap('Send request');
      expect(f.api.accessPayloads.last['purpose'], 'INQUIRE');
      expect(f.api.accessPayloads.last['candidate'], 'signed-candidate');
      expect(
        f.api.accessPayloads.last['message'],
        'My grandmother came from this branch.',
      );
      expect(f.api.treeCreates, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'distant ancestor approval requires a recorded parent and owner reply stays separate',
    (tester) async {
      final f = await fixture();
      f.api.accessData = {
        'discovery_enabled': true,
        'members': [],
        'invitations': [],
        'requests': [
          {
            'id': 7,
            'status': 'PENDING',
            'applicant': 'Relative',
            'person': {'first_name': 'Anna', 'last_name': 'Family'},
            'mode': 'INQUIRY',
            'anchor_name': 'Ancestor',
            'message': 'Could we be related?',
            'evidence': {
              'path_parent_id': 1,
              'ancestor_level': 2,
              'parent_name': 'Grandparent Family',
              'grandparent_name': 'Great Family',
            },
          },
        ],
      };
      await pump(
        tester,
        f.wrap,
        const FamilyConnectionsView(treeId: 1),
        scale: 2,
      );
      final approve = find.text('Approve');
      await tester.ensureVisible(approve);
      await tester.pumpAndSettle();
      await tester.tap(approve);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'No recorded profile fits this generation. Add the missing branch in your tree, then return to this request.',
        ),
        findsOneWidget,
      );
      final mode = find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(DropdownButtonFormField<String>),
          )
          .first;
      await tester.ensureVisible(mode);
      await tester.tap(mode);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Child of a member').last);
      await tester.pumpAndSettle();
      final parent = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(DropdownButtonFormField<int>),
      );
      await tester.ensureVisible(parent);
      await tester.tap(parent);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Child Example').last);
      await tester.pumpAndSettle();
      final confirm = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Approve'),
      );
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(f.api.accessPayloads.last['connection_mode'], 'CHILD');
      expect(f.api.accessPayloads.last['anchor_id'], 2);
      final reply = find.text('Reply');
      await tester.ensureVisible(reply);
      await tester.pumpAndSettle();
      await tester.tap(reply);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'Message',
        ),
        'Please confirm your parents.',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Send reply'));
      await tester.tap(find.text('Send reply'));
      await tester.pumpAndSettle();
      expect(f.api.accessPayloads.last['action'], 'reply');
      expect(tester.takeException(), isNull);
    },
  );
}

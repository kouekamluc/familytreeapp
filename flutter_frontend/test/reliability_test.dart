import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_frontend/widgets/tree_canvas.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_frontend/config/api_config.dart';
import 'package:flutter_frontend/models/family_tree.dart';
import 'package:flutter_frontend/models/person.dart';
import 'package:flutter_frontend/models/relationship.dart';
import 'package:flutter_frontend/providers/tree_provider.dart';
import 'package:flutter_frontend/services/api_service.dart';
import 'package:flutter_frontend/services/local_storage_service.dart';
import 'package:flutter_frontend/utils/genealogy_helper.dart';

class GraphApi extends ApiService {
  bool failSecond = false;
  final second = Completer<List<Person>>();
  @override
  String get identity => 'test-identity';
  @override
  Future<List<FamilyTree>> getTrees() async => [
    FamilyTree(id: 1, name: 'A'),
    FamilyTree(id: 2, name: 'B'),
  ];
  @override
  Future<List<Person>> getPeople({int? treeId}) async {
    if (treeId == 2 && failSecond) throw Exception('Offline');
    return [
      Person(
        id: treeId! * 10,
        firstName: 'Member',
        lastName: '$treeId',
        gender: 'O',
      ),
    ];
  }

  @override
  Future<List<Relationship>> getRelationships({int? treeId}) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });
  test('card roles use recorded links and keep unknown gender neutral', () {
    final parent = Person(
      id: 1,
      firstName: 'Parent',
      lastName: 'Example',
      gender: 'O',
      generationTier: 1,
    );
    final child = Person(
      id: 2,
      firstName: 'Child',
      lastName: 'Example',
      gender: 'O',
      generationTier: 1,
    );
    final sibling = Person(
      id: 3,
      firstName: 'Sibling',
      lastName: 'Example',
      gender: 'O',
      generationTier: 1,
    );
    final people = [parent, child, sibling];
    final links = [
      Relationship(id: 1, person1Id: 1, person2Id: 2, relationshipType: 'STEP'),
      Relationship(
        id: 2,
        person1Id: 2,
        person2Id: 3,
        relationshipType: 'SIBLING',
      ),
    ];
    final summary = GenealogyHelper.getKinshipSummary(parent, people, links);
    expect(summary.lineageRole, 'Parent');
    expect(summary.allChildren, [child]);
    expect(summary.daughters, isEmpty);
    expect(summary.culturalRole, 'Family member');
    final childSummary = GenealogyHelper.getKinshipSummary(
      child,
      people,
      links,
    );
    expect(childSummary.father, isNull);
    expect(childSummary.allSiblings, [sibling]);
    expect(childSummary.lineageRole, 'Child');
  });
  testWidgets('initial phone viewport keeps both linked cards in view', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final parent = Person(
      id: 1,
      firstName: 'Viewport',
      lastName: 'Parent',
      gender: 'O',
    );
    final child = Person(
      id: 2,
      firstName: 'Viewport',
      lastName: 'Child',
      gender: 'F',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 384,
            height: 500,
            child: TreeCanvas(
              people: [parent, child],
              relationships: [
                Relationship(
                  id: 1,
                  person1Id: 1,
                  person2Id: 2,
                  relationshipType: 'PARENT',
                ),
              ],
              onSelectPerson: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final viewport = tester.getRect(find.byType(TreeCanvas));
    expect(
      viewport.contains(tester.getCenter(find.text(parent.fullName))),
      isTrue,
    );
    expect(
      viewport.contains(tester.getCenter(find.text(child.fullName))),
      isTrue,
    );
    expect(find.text('Parent'), findsOneWidget);
    expect(find.text('Child'), findsOneWidget);
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  test('failed tree switch never labels A people as B', () async {
    final api = GraphApi();
    final provider = TreeProvider(api);
    await provider.loadData(targetTreeId: 1);
    expect(provider.people.single.id, 10);
    api.failSecond = true;
    provider.selectTree(provider.trees.last);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(provider.people, isEmpty);
    expect(provider.selectedTree, isNull);
    expect(provider.errorMessage, isNotNull);
    provider.dispose();
  });
  test('explicit siblings appear without recorded parents', () async {
    final api = GraphApi();
    final provider = TreeProvider(api);
    // API relationship fixture uses the same public provider loading path.
    final fixture = SiblingApi();
    final siblings = TreeProvider(fixture);
    await siblings.loadData();
    expect(siblings.getSiblingsOf(1).single.id, 2);
    siblings.dispose();
    provider.dispose();
  });
  test(
    'same usernames and IDs on different servers have separate caches and credentials',
    () async {
      final local = LocalStorageService();
      await ApiConfig.setBaseUrl('https://one.example/api');
      await local.saveAccount(
        SavedAccount(
          userId: 1,
          username: 'same',
          displayName: 'One',
          token: 'one',
        ),
      );
      await local.cacheTrees([FamilyTree(id: 1, name: 'Private one')]);
      await ApiConfig.setBaseUrl('https://two.example/api');
      await local.saveAccount(
        SavedAccount(
          userId: 1,
          username: 'same',
          displayName: 'Two',
          token: 'two',
        ),
      );
      expect(await local.getCachedTrees(), isEmpty);
      expect((await local.getSavedAccounts()).single.token, 'two');
      await ApiConfig.setBaseUrl('https://one.example/api');
      expect((await local.getCachedTrees()).single.name, 'Private one');
      expect((await local.getSavedAccounts()).single.token, 'one');
    },
  );
  test(
    'successful registration uses real required fields and commits a verified user',
    () async {
      await ApiConfig.setBaseUrl('https://family.example/api');
      final api = ApiService();
      await api.init();
      await http.runWithClient(
        () async {
          expect(
            await api.register(
              username: 'new',
              email: 'new@example.test',
              password: 'Test-482!',
              firstName: 'New',
              lastName: 'Person',
            ),
            isTrue,
          );
          expect(api.currentUser?.id, 4);
          expect(api.isAuthenticated, isTrue);
        },
        () => MockClient((request) async {
          if (request.url.path.endsWith('/register/')) {
            final body = jsonDecode(request.body);
            expect(body['password2'], body['password']);
            expect(body['first_name'], 'New');
            return http.Response('{}', 201);
          }
          if (request.url.path.endsWith('/token/')) {
            return http.Response(
              '{"access":"access","refresh":"refresh"}',
              200,
            );
          }
          return http.Response(
            '{"id":4,"username":"new","email":"new@example.test","first_name":"New","last_name":"Person"}',
            200,
          );
        }),
      );
    },
  );
  test(
    'concurrent expired reads refresh once and preserve the verified identity',
    () async {
      await ApiConfig.setBaseUrl('https://refresh.example/api');
      final prefix = base64Url.encode(utf8.encode(ApiConfig.baseUrl));
      SharedPreferences.setMockInitialValues({
        'custom_server_host_url': ApiConfig.baseUrl,
        'session_v2_${prefix}_token': 'expired',
        'session_v2_${prefix}_refresh': 'refresh',
        'session_v2_${prefix}_user': jsonEncode({
          'id': 7,
          'username': 'owner',
          'email': 'owner@example.test',
        }),
      });
      final api = ApiService();
      await api.init();
      var refreshes = 0;
      final gate = Completer<void>();
      await http.runWithClient(
        () async {
          final one = api.getTrees();
          final two = api.getTrees();
          await Future<void>.delayed(Duration.zero);
          await Future<void>.delayed(Duration.zero);
          gate.complete();
          await Future.wait([one, two]);
          expect(refreshes, 1);
          expect(api.currentUser?.id, 7);
          expect(api.isAuthenticated, isTrue);
          final restored = ApiService();
          await restored.init();
          expect(restored.currentUser?.id, 7);
          expect(restored.token, 'renewed');
          expect(
            (await LocalStorageService().getSavedAccounts()).single.token,
            'renewed',
          );
        },
        () => MockClient((request) async {
          if (request.url.path.endsWith('/refresh/')) {
            refreshes++;
            await gate.future;
            return http.Response('{"access":"renewed"}', 200);
          }
          return request.headers['authorization'] == 'Bearer renewed'
              ? http.Response('[]', 200)
              : http.Response('{}', 401);
        }),
      );
    },
  );
  test('failed account switch retains the verified original account', () async {
    await ApiConfig.setBaseUrl('https://switch.example/api');
    final prefix = base64Url.encode(utf8.encode(ApiConfig.baseUrl));
    SharedPreferences.setMockInitialValues({
      'custom_server_host_url': ApiConfig.baseUrl,
      'session_v2_${prefix}_token': 'original',
      'session_v2_${prefix}_user': jsonEncode({
        'id': 7,
        'username': 'owner',
        'email': 'owner@example.test',
      }),
    });
    final api = ApiService();
    await api.init();
    await http.runWithClient(() async {
      expect(
        await api.switchToAccount(
          SavedAccount(
            userId: 8,
            username: 'other',
            displayName: 'Other',
            token: 'invalid',
          ),
        ),
        isFalse,
      );
      expect(api.currentUser?.id, 7);
      expect(api.token, 'original');
    }, () => MockClient((request) async => http.Response('{}', 401)));
  });
  test(
    'empty server tree list invalidates a previously cached graph',
    () async {
      final local = LocalStorageService();
      await local.cacheSnapshot(
        [FamilyTree(id: 1, name: 'Deleted')],
        1,
        [Person(id: 1, firstName: 'Private', lastName: 'Record', gender: 'O')],
        [],
        accountScope: 'test-empty',
      );
      await local.cacheTrees([], accountScope: 'test-empty');
      expect(await local.getCachedTrees(accountScope: 'test-empty'), isEmpty);
      expect(
        await local.getCachedPeople(1, accountScope: 'test-empty'),
        isEmpty,
      );
      expect(
        await local.getLastActiveTreeId(accountScope: 'test-empty'),
        isNull,
      );
    },
  );
  test(
    'all pages load and off-server pagination is rejected before credentials leave',
    () async {
      await ApiConfig.setBaseUrl('https://pages.example/api');
      final api = ApiService();
      await api.init();
      var foreign = false;
      await http.runWithClient(
        () async {
          final trees = await api.getTrees();
          expect(trees.map((t) => t.id), [1, 2]);
          foreign = true;
          await expectLater(api.getTrees(), throwsException);
        },
        () => MockClient((request) async {
          expect(request.url.host, 'pages.example');
          if (request.url.queryParameters['page'] == '2') {
            return http.Response(
              '{"results":[{"id":2,"name":"Second"}],"next":null}',
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'results': [
                {'id': 1, 'name': 'First'},
              ],
              'next': foreign
                  ? 'https://unrelated.example/api/trees/'
                  : 'https://pages.example/api/trees/?page=2',
            }),
            200,
          );
        }),
      );
    },
  );
}

class SiblingApi extends GraphApi {
  @override
  Future<List<Person>> getPeople({int? treeId}) async => [
    Person(id: 1, firstName: 'A', lastName: 'Sibling', gender: 'O'),
    Person(id: 2, firstName: 'B', lastName: 'Sibling', gender: 'O'),
  ];
  @override
  Future<List<Relationship>> getRelationships({int? treeId}) async => [
    Relationship(
      id: 1,
      person1Id: 1,
      person2Id: 2,
      relationshipType: 'SIBLING',
    ),
  ];
}

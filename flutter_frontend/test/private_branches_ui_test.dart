import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/config/royal_theme.dart';
import 'package:flutter_frontend/l10n/app_strings.dart';
import 'package:flutter_frontend/models/family_tree.dart';
import 'package:flutter_frontend/models/person.dart';
import 'package:flutter_frontend/services/api_service.dart';
import 'package:flutter_frontend/views/private_branches_view.dart';
import 'package:flutter_frontend/widgets/tree_canvas.dart';

class BranchApi extends ApiService {
  String account = 'owner';
  Map<String, dynamic>? submitted;
  Map<String, dynamic>? response = {
    'visible': [
      {
        'id': 9,
        'root_id': 1,
        'attachment_id': 3,
        'label': 'Selected branch',
        'status': 'APPROVED',
        'connection': 'EXISTING',
        'revision': 2,
        'people': [
          {
            'id': 1,
            'first_name': 'Visible',
            'last_name': 'Member',
            'gender': 'O',
          },
        ],
        'relationships': [],
      },
    ],
    'incoming': [],
    'outgoing': [],
  };
  @override
  String get identity => account;
  void switchAccount() {
    account = 'other';
    notifyListeners();
  }

  @override
  Future<List<FamilyTree>> getTrees() async => [
    FamilyTree(id: 2, name: 'Extended family'),
  ];
  @override
  Future<List<Person>> getPeople({int? treeId}) async => [
    Person(id: 3, firstName: 'Visible', lastName: 'Member', gender: 'O'),
  ];
  @override
  Future<Map<String, dynamic>?> familyBranches(
    int treeId, {
    Map<String, dynamic>? payload,
  }) async {
    if (payload != null) {
      submitted = payload;
      return null;
    }
    return response;
  }
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  Future<void> pump(WidgetTester tester, BranchApi api, Widget child) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider<ApiService>.value(
        value: api,
        child: MaterialApp(
          theme: RoyalTheme.lightTheme,
          localizationsDelegates: const [AppStrings.delegate],
          home: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'private selection starts with root only and failed save preserves choices',
    (tester) async {
      final api = BranchApi();
      await pump(
        tester,
        api,
        PrivateBranchEditor(
          source: FamilyTree(id: 1, name: 'My private tree'),
          people: [
            Person(
              id: 1,
              firstName: 'Visible',
              lastName: 'Member',
              gender: 'O',
              biography: 'Private story',
            ),
            Person(id: 2, firstName: 'Hidden', lastName: 'Member', gender: 'O'),
          ],
          relationships: const [],
        ),
      );
      Future<void> choose(int index, String value) async {
        final finder = find.byType(DropdownButtonFormField<int>).at(index);
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
        await tester.tap(find.text(value).last);
        await tester.pumpAndSettle();
      }

      await choose(0, 'Extended family');
      await choose(1, 'Visible Member');
      await choose(2, 'Visible Member');
      await tester.ensureVisible(find.text('Choose shared profiles'));
      await tester.tap(find.text('Choose shared profiles'));
      await tester.pumpAndSettle();
      final checks = tester
          .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
          .toList();
      expect(checks.map((c) => c.value), [true, false]);
      expect(checks.first.onChanged, isNull);
      await tester.ensureVisible(find.text('Send branch for confirmation'));
      await tester.tap(find.text('Send branch for confirmation'));
      await tester.pumpAndSettle();
      expect(api.submitted!['shared_ids'], [1]);
      expect(
        find.text('Unable to share this branch. Your selections are kept.'),
        findsOneWidget,
      );
      expect(
        tester
            .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
            .map((c) => c.value),
        [true, false],
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'shared graph removes profiles after withdrawal refresh and account switch',
    (tester) async {
      final api = BranchApi();
      await pump(tester, api, const SharedBranchView(treeId: 2, branchId: 9));
      expect(
        tester
            .widget<TreeCanvas>(find.byType(TreeCanvas))
            .people
            .single
            .fullName,
        'Visible Member',
      );
      api.response = {'visible': [], 'incoming': [], 'outgoing': []};
      final firstCanvas = tester.widget<TreeCanvas>(find.byType(TreeCanvas));
      firstCanvas.onSelectPerson(firstCanvas.people.single);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();
      expect(find.byType(TreeCanvas), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        find.text('This branch is no longer shared or is unavailable.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      api.response = {
        'visible': [
          {
            'id': 9,
            'root_id': 1,
            'attachment_id': 3,
            'label': 'Selected branch',
            'connection': 'EXISTING',
            'revision': 2,
            'status': 'APPROVED',
            'people': [
              {
                'id': 1,
                'first_name': 'Visible',
                'last_name': 'Member',
                'gender': 'O',
              },
            ],
            'relationships': [],
          },
        ],
      };
      await pump(tester, api, const SharedBranchView(treeId: 2, branchId: 9));
      api.switchAccount();
      await tester.pumpAndSettle();
      expect(find.byType(TreeCanvas), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  test('new privacy copy follows the selected language', () {
    const fr = AppStrings(Locale('fr'));
    expect(fr.text('Private branches'), 'Branches privées');
    expect(fr.text('2 selected profiles'), '2 profils sélectionnés');
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/config/royal_theme.dart';
import 'package:flutter_frontend/providers/tree_provider.dart';
import 'package:flutter_frontend/services/api_service.dart';
import 'package:flutter_frontend/services/local_storage_service.dart';
import 'package:flutter_frontend/views/private_branches_view.dart';
import 'package:flutter_frontend/views/tree/tree_view.dart';
import 'package:flutter_frontend/widgets/tree_canvas.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android plural households, explicit sharing, owner approval and withdrawal',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final api = ApiService();
      await api.init();
      await api.logout();
      final tree = TreeProvider(api);
      final suffix = DateTime.now().millisecondsSinceEpoch;
      Future<void> register(String username, String firstName) async {
        expect(
          await api.register(
            username: '${username}_$suffix',
            email: '${username}_$suffix@example.test',
            password: 'Branch-Test-482!',
            firstName: firstName,
            lastName: 'Family',
          ),
          isTrue,
          reason: api.lastError,
        );
        await tree.loadData();
      }

      final navigator = GlobalKey<NavigatorState>();
      Future<void> screen(Widget child) async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ApiService>.value(value: api),
              ChangeNotifierProvider<TreeProvider>.value(value: tree),
            ],
            child: MaterialApp(
              navigatorKey: navigator,
              theme: RoyalTheme.lightTheme,
              home: const Scaffold(),
            ),
          ),
        );
        navigator.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => child),
        );
        await tester.pumpAndSettle();
      }

      Future<void> tap(String label) async {
        final matches = find.text(label);
        for (var i = 0; i < 80 && matches.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(matches, findsWidgets, reason: api.lastError);
        final finder = matches.last;
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      Future<void> choose(int index, String label) async {
        final finder = find.byType(DropdownButtonFormField<int>).at(index);
        for (
          var i = 0;
          i < 80 &&
              tester.widget<DropdownButtonFormField<int>>(finder).onChanged ==
                  null;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(
          tester.widget<DropdownButtonFormField<int>>(finder).onChanged,
          isNotNull,
        );
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
        await tap(label);
      }

      await register('branch_extended', 'Owner');
      final ownerId = api.currentUser!.id;
      final extended = await tree.createTree(
        'Extended family $suffix',
        'Android privacy test',
      );
      expect(extended, isNotNull);
      expect(
        await tree.addPerson({
          'first_name': 'Alex',
          'last_name': 'Family',
          'gender': 'O',
        }),
        isTrue,
      );
      final anchor = tree.people.single;
      final invite = await api.familyAccess({
        'action': 'invite',
        'tree_id': extended!.id,
        'anchor_id': anchor.id,
        'mode': 'EXISTING',
      });
      expect(invite, isNotNull, reason: api.lastError);
      final owner = (await LocalStorageService().getSavedAccounts()).firstWhere(
        (a) => a.userId == ownerId,
      );
      await register('branch_private', 'Alex');
      final privateOwnerId = api.currentUser!.id;
      final request = await api.familyAccess({
        'action': 'redeem',
        'code': invite!['code'],
        'person': {'first_name': 'Alex', 'last_name': 'Family', 'gender': 'O'},
      });
      expect(request, isNotNull, reason: api.lastError);
      final privateOwner = (await LocalStorageService().getSavedAccounts())
          .firstWhere((a) => a.userId == privateOwnerId);
      expect(await api.switchToAccount(owner), isTrue);
      expect(
        await api.familyAccess({
          'action': 'review',
          'tree_id': extended.id,
          'request_id': request!['id'],
          'decision': 'APPROVED',
        }),
        isNotNull,
        reason: api.lastError,
      );
      expect(await api.switchToAccount(privateOwner), isTrue);
      await tree.loadData();
      final private = await tree.createTree(
        'Private household $suffix',
        'Unshared private tree',
      );
      expect(private, isNotNull);
      expect(
        await tree.addPerson({
          'first_name': 'Alex',
          'last_name': 'Family',
          'gender': 'O',
          'biography': 'Never share this story',
        }),
        isTrue,
      );
      final root = tree.people.single;
      Future<dynamic> relative(
        int parentId,
        String role,
        String name, {
        int? coParentId,
      }) => tree.createRelative(
        sourcePersonId: parentId,
        role: role,
        coParentId: coParentId,
        personData: {'first_name': name, 'last_name': 'Family', 'gender': 'O'},
      );
      final sam = await relative(root.id, 'spouse', 'Sam');
      final lee = await relative(root.id, 'spouse', 'Lee');
      expect(sam, isNotNull);
      expect(lee, isNotNull);
      final sharedChild = await relative(
        root.id,
        'child',
        'Shared child',
        coParentId: sam.id,
      );
      final otherChild = await relative(
        root.id,
        'child',
        'Private child',
        coParentId: lee.id,
      );
      expect(sharedChild, isNotNull);
      expect(otherChild, isNotNull);
      final sibling = await relative(root.id, 'sibling', 'Sibling household');
      expect(sibling, isNotNull);
      expect(
        await relative(sibling.id, 'spouse', 'Sibling partner'),
        isNotNull,
      );
      await screen(const Scaffold(body: TreeView()));
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot('phone-plural-households');
      expect(tester.takeException(), isNull);

      await screen(
        PrivateBranchEditor(
          source: private!,
          people: tree.people,
          relationships: tree.relationships,
        ),
      );
      await choose(0, extended.name);
      await choose(1, 'Alex Family');
      await choose(2, 'Alex Family');
      await tap('Choose shared profiles');
      expect(
        tester
            .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
            .where((c) => c.value == true)
            .length,
        1,
      );
      await tap('Shared child Family');
      await binding.takeScreenshot('phone-explicit-profile-sharing');
      await tap('Send branch for confirmation');
      final published = (await api.familyBranches(private.id))!['outgoing'][0];
      expect(published['status'], 'PENDING');
      expect((await api.familyBranches(extended.id))!['visible'], isEmpty);
      await tester.pumpWidget(const SizedBox());
      expect(await api.switchToAccount(owner), isTrue);
      await tree.loadData(targetTreeId: extended.id);
      await screen(PrivateBranchesView(treeId: extended.id));
      await tap('Approve');
      await tap('Confirm');
      expect((await api.familyBranches(extended.id))!['visible'].length, 1);
      expect(
        await api.getPerson(root.id),
        isNull,
        reason: 'The branch must not unlock the private profile endpoint.',
      );
      await screen(const Scaffold(body: TreeView()));
      expect(
        tester.widget<TreeCanvas>(find.byType(TreeCanvas)).branches.length,
        1,
      );
      await binding.takeScreenshot('phone-shared-branch-connection');
      await screen(
        SharedBranchView(treeId: extended.id, branchId: published['id']),
      );
      final canvas = tester.widget<TreeCanvas>(find.byType(TreeCanvas));
      expect(canvas.people.map((p) => p.fullName).toSet(), {
        'Alex Family',
        'Shared child Family',
      });
      expect(
        canvas.people.every(
          (p) =>
              (p.biography ?? '').isEmpty && (p.profilePicture ?? '').isEmpty,
        ),
        isTrue,
      );
      expect(canvas.relationships.length, 1);
      for (final name in ['Alex Family', 'Shared child Family']) {
        final bounds = tester.getRect(find.text(name));
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(
          bounds.right,
          lessThanOrEqualTo(
            tester.view.physicalSize.width / tester.view.devicePixelRatio,
          ),
        );
      }
      await binding.takeScreenshot('phone-selected-shared-branch');
      await tester.pumpWidget(const SizedBox());
      expect(await api.switchToAccount(privateOwner), isTrue);
      await tree.loadData(targetTreeId: private.id);
      await screen(PrivateBranchesView(treeId: private.id));
      await tap('Stop sharing');
      await tap('Confirm');
      expect(
        (await api.familyBranches(private.id))!['outgoing'][0]['status'],
        'WITHDRAWN',
      );
      expect(
        tree.people.length,
        7,
        reason: 'Withdrawal preserves the private household.',
      );
      await tester.pumpWidget(const SizedBox());
      expect(await api.switchToAccount(owner), isTrue);
      await tree.loadData(targetTreeId: extended.id);
      await screen(
        SharedBranchView(treeId: extended.id, branchId: published['id']),
      );
      expect(
        find.text('This branch is no longer shared or is unavailable.'),
        findsOneWidget,
      );
      expect(find.byType(TreeCanvas), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      tree.dispose();
      await api.logout();
      api.dispose();
    },
  );
}

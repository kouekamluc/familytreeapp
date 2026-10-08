import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/config/royal_theme.dart';
import 'package:flutter_frontend/providers/tree_provider.dart';
import 'package:flutter_frontend/providers/auth_provider.dart';
import 'package:flutter_frontend/services/api_service.dart';
import 'package:flutter_frontend/services/local_storage_service.dart';
import 'package:flutter_frontend/views/family_connections_view.dart';
import 'package:flutter_frontend/views/tree/tree_view.dart';
import 'package:flutter_frontend/widgets/tree_manager_sheet.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native family invitation, owner review, viewing rights and ancestry search',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final api = ApiService();
      await api.init();
      await api.logout();
      final tree = TreeProvider(api);
      final suffix = DateTime.now().millisecondsSinceEpoch;
      expect(
        await api.register(
          username: 'joining_owner_$suffix',
          email: 'owner_$suffix@example.test',
          password: 'Joining-Test-482!',
          firstName: 'Owner',
          lastName: 'Family',
        ),
        isTrue,
      );
      final ownerId = api.currentUser!.id;
      final family = await tree.createTree(
        'Joining test family $suffix',
        'Isolated Android test',
      );
      expect(family, isNotNull);
      expect(
        await tree.addPerson({
          'first_name': 'Mariam$suffix',
          'last_name': 'Family',
          'gender': 'F',
        }),
        isTrue,
      );
      final gp = tree.people.single;
      final parent = await tree.createRelative(
        sourcePersonId: gp.id,
        role: 'child',
        personData: {
          'first_name': 'Paul$suffix',
          'last_name': 'Family',
          'gender': 'O',
        },
      );
      expect(parent, isNotNull);
      final anna = await tree.createRelative(
        sourcePersonId: parent!.id,
        role: 'child',
        personData: {
          'first_name': 'Anna',
          'last_name': 'Family',
          'gender': 'F',
          'biography': 'Preserved recorded profile',
        },
      );
      expect(anna, isNotNull);
      final root = GlobalKey<NavigatorState>();
      Widget app() => MultiProvider(
        providers: [
          ChangeNotifierProvider<ApiService>.value(value: api),
          ChangeNotifierProvider<TreeProvider>.value(value: tree),
          ChangeNotifierProvider(create: (_) => AuthProvider(api)),
        ],
        child: MaterialApp(
          navigatorKey: root,
          theme: RoyalTheme.lightTheme,
          home: const Scaffold(body: TreeView()),
        ),
      );
      Future<void> screen({int? treeId}) async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(app());
        root.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => FamilyConnectionsView(treeId: treeId),
          ),
        );
        await tester.pumpAndSettle();
      }

      Future<void> waitFor(Finder finder) async {
        for (
          var attempt = 0;
          attempt < 80 && finder.evaluate().isEmpty;
          attempt++
        ) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(finder, findsWidgets, reason: api.lastError);
        await tester.pumpAndSettle();
      }

      Future<void> tap(String label) async {
        final finder = find.text(label).last;
        await waitFor(finder);
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      Future<void> enter(String label, String value) async {
        final finder = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == label,
        );
        await waitFor(finder);
        await tester.ensureVisible(finder);
        await tester.enterText(finder, value);
        await tester.pumpAndSettle();
      }

      await screen(treeId: family!.id);
      final anchor = find.byWidgetPredicate(
        (w) => w is DropdownButtonFormField<int>,
      );
      await waitFor(anchor);
      await tester.tap(anchor);
      await tester.pumpAndSettle();
      await tap('Anna Family');
      await tap('Create invitation');
      await waitFor(find.text('Invitation created'));
      expect(find.text('Invitation created'), findsOneWidget);
      final code = tester
          .widget<SelectableText>(find.byType(SelectableText))
          .data!;
      await tap('Done');
      expect(
        await api.familyAccess({
          'action': 'discovery',
          'tree_id': family.id,
          'enabled': true,
        }),
        isNotNull,
      );
      final ownerAccount = (await LocalStorageService().getSavedAccounts())
          .firstWhere((a) => a.userId == ownerId);
      expect(
        await api.register(
          username: 'joining_anna_$suffix',
          email: 'anna_$suffix@example.test',
          password: 'Joining-Test-483!',
          firstName: 'Anna',
          lastName: 'Family',
        ),
        isTrue,
      );
      final applicantId = api.currentUser!.id;
      await tree.loadData();
      expect(tree.trees, isEmpty);
      await screen();
      await enter('Invitation code', code);
      FocusManager.instance.primaryFocus?.unfocus();
      await tap('Request to join');
      await waitFor(find.text('Awaiting confirmation'));
      expect(find.text('Awaiting confirmation'), findsOneWidget);
      await tree.loadData();
      expect(
        tree.trees,
        isEmpty,
        reason: 'A pending invitation must not expose the private family.',
      );
      final applicantAccount = (await LocalStorageService().getSavedAccounts())
          .firstWhere((a) => a.userId == applicantId);
      expect(await api.switchToAccount(ownerAccount), isTrue);
      await tree.loadData(targetTreeId: family.id);
      await screen(treeId: family.id);
      await tap('Approve');
      expect(find.text('Confirm this member?'), findsOneWidget);
      await tap('Confirm');
      await waitFor(find.text('Accepted'));
      expect(find.text('Accepted'), findsOneWidget);
      expect(tree.people.length, 3);
      expect(await api.switchToAccount(applicantAccount), isTrue);
      await tree.loadData();
      await screen();
      await tap('Open my family');
      for (
        var attempt = 0;
        attempt < 80 &&
            find.byType(FamilyConnectionsView).evaluate().isNotEmpty;
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      await tester.pumpAndSettle();
      expect(find.byType(FamilyConnectionsView), findsNothing);
      expect(tree.selectedTree?.id, family.id);
      expect(tree.selectedPerson?.id, anna!.id);
      expect(tree.people.length, 3);
      expect(
        tree.people.firstWhere((p) => p.id == anna.id).biography,
        'Preserved recorded profile',
      );
      expect(tree.canEditSelectedTree, isFalse);
      expect(
        await api.createPerson({
          'family_tree': family.id,
          'first_name': 'Forbidden',
          'last_name': 'Write',
          'gender': 'O',
        }),
        isNull,
      );
      expect(tester.takeException(), isNull);
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot('phone-joined-family');
      expect(
        await api.register(
          username: 'joining_search_$suffix',
          email: 'search_$suffix@example.test',
          password: 'Joining-Test-484!',
          firstName: 'Other',
          lastName: 'Family',
        ),
        isTrue,
      );
      await tree.loadData();
      await screen();
      await tap('My ancestors');
      await enter('Parent’s full name', 'Paul$suffix Family');
      await enter(
        'Their parent’s full name (your grandparent)',
        'Mariam$suffix Family',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tap('Find a family');
      await waitFor(find.text('Joining test family $suffix'));
      expect(find.text('Joining test family $suffix'), findsOneWidget);
      await tap('Request confirmation');
      await tap('Send request');
      await waitFor(find.text('Awaiting confirmation'));
      expect(find.text('Awaiting confirmation'), findsOneWidget);
      await tree.loadData();
      expect(tree.trees, isEmpty);
      expect(tester.takeException(), isNull);

      final searchAccount = (await LocalStorageService().getSavedAccounts())
          .firstWhere((a) => a.userId == api.currentUser!.id);
      final oldPending = (await api.getFamilyAccess())!['requests'][0];
      expect(
        await api.familyAccess({
          'action': 'cancel',
          'request_id': oldPending['id'],
        }),
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox());
      expect(await api.switchToAccount(ownerAccount), isTrue);
      await tree.loadData(targetTreeId: family.id);
      final great = await tree.createRelative(
        sourcePersonId: gp.id,
        role: 'parent',
        personData: {
          'first_name': 'Samuel$suffix',
          'last_name': 'Family',
          'gender': 'O',
          'birth_place': 'Bafoussam',
          'date_of_birth': '1900-01-01',
        },
      );
      expect(great, isNotNull);
      expect(await api.switchToAccount(searchAccount), isTrue);
      await tree.loadData();
      await tester.pumpWidget(app());
      root.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: TreeManagerSheet()),
        ),
      );
      await tester.pumpAndSettle();
      await tap('Create a family tree');
      await enter('Family name *', 'A duplicate branch $suffix');
      await tap('I know two consecutive ancestors');
      await enter('Grandparent’s full name', 'Mariam$suffix Family');
      await enter(
        'Their parent’s full name (your great-grandparent)',
        'Samuel$suffix Family',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tap('Save');
      await waitFor(find.text('This family may already exist'));
      expect(tree.trees, isEmpty);
      await binding.takeScreenshot('phone-existing-family-warning');
      await tap('Explore these connections');
      await tap('Ask if we are related');
      await enter('Message', 'My grandmother may be from this branch.');
      FocusManager.instance.primaryFocus?.unfocus();
      await tap('Send request');
      await waitFor(find.text('Awaiting confirmation'));
      final inquiry = (await api.getFamilyAccess())!['requests'][0];
      expect(inquiry['mode'], 'INQUIRY');
      expect(tree.trees, isEmpty);

      await tester.pumpWidget(const SizedBox());
      expect(await api.switchToAccount(ownerAccount), isTrue);
      await tree.loadData(targetTreeId: family.id);
      expect((await api.getFamilyAccess())!['pending_reviews'], 1);
      await screen(treeId: family.id);
      await tap('Reply');
      await enter('Message', 'We have confirmed your recorded parent Paul.');
      FocusManager.instance.primaryFocus?.unfocus();
      await tap('Send reply');
      await tester.pumpWidget(const SizedBox());
      expect(await api.switchToAccount(searchAccount), isTrue);
      await tree.loadData();
      await screen();
      expect(
        find.text('We have confirmed your recorded parent Paul.'),
        findsOneWidget,
      );
      expect(tree.trees, isEmpty);

      await tester.pumpWidget(const SizedBox());
      expect(await api.switchToAccount(ownerAccount), isTrue);
      await tree.loadData(targetTreeId: family.id);
      await screen(treeId: family.id);
      await tap('Approve');
      final connectionMode = find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(DropdownButtonFormField<String>),
          )
          .first;
      await tester.ensureVisible(connectionMode);
      await tester.tap(connectionMode);
      await tester.pumpAndSettle();
      await tap('Child of a member');
      final actualParent = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(DropdownButtonFormField<int>),
      );
      await tester.ensureVisible(actualParent);
      await tester.tap(actualParent);
      await tester.pumpAndSettle();
      await tap('Paul$suffix Family');
      await tap('Approve');
      await waitFor(find.text('Accepted'));
      await tester.pumpWidget(const SizedBox());
      expect(await api.switchToAccount(searchAccount), isTrue);
      await tree.loadData();
      await screen();
      await tap('Open my family');
      final joined = tree.people.singleWhere(
        (p) => p.fullName == 'Other Family',
      );
      expect(
        tree.relationships.any(
          (r) =>
              r.isParent &&
              r.person1Id == parent.id &&
              r.person2Id == joined.id,
        ),
        isTrue,
      );
      expect(
        tree.relationships.any(
          (r) => r.isParent && r.person1Id == gp.id && r.person2Id == joined.id,
        ),
        isFalse,
      );
      expect(tree.canEditSelectedTree, isFalse);
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('phone-extended-family-joined');
      await api.logout();
      debugPrint(
        'NATIVE JOINING PASSED: invitation UI, owner review, existing profile reuse, viewer enforcement, ancestry suggestions, duplicate-tree warning, grandparent inquiry, owner notification and reply, verified parent placement and pending privacy.',
      );
    },
  );
}

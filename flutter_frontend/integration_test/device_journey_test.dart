import 'dart:convert';
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
import 'package:flutter_frontend/services/local_storage_service.dart';
import 'package:flutter_frontend/views/auth/login_view.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native app: welcome, registration, editing, expiry, portraits, transfer and identity isolation',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final api = ApiService();
      await api.init();
      await api.logout();
      final auth = AuthProvider(api);
      final tree = TreeProvider(api);
      final theme = ThemeProvider();
      final accessibility = AccessibilityProvider();
      Widget providers(Widget child) => MultiProvider(
        providers: [
          ChangeNotifierProvider<ApiService>.value(value: api),
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: tree),
          ChangeNotifierProvider.value(value: theme),
          ChangeNotifierProvider.value(value: accessibility),
        ],
        child: child,
      );
      await tester.pumpWidget(providers(const RoyalAncestryApp()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Password').first);
      await tester.pumpAndSettle();
      final create = find.text('New here? Create an account');
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pumpAndSettle();
      final username = 'phone_${DateTime.now().millisecondsSinceEpoch}';
      Future<void> enter(String label, String value) async {
        final field = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == label,
        );
        await tester.ensureVisible(field);
        await tester.enterText(field, value);
        await tester.pump();
      }

      await enter('First name', 'Phone');
      await enter('Last name', 'Test connection');
      await enter('Confirm password', 'Phone-Test-482!');
      await enter('Email address', '$username@example.test');
      await enter('Username', username);
      await enter('Password', 'Phone-Test-482!');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final submit = find.text('Create my account');
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      for (var i = 0; i < 60 && !auth.isAuthenticated; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(auth.isAuthenticated, isTrue, reason: auth.errorMessage);
      expect(api.currentUser?.username, username);
      await tree.loadData();
      await tester.pumpAndSettle();
      expect(find.byType(LoginView), findsNothing);
      final firstIdentity = api.currentUser!.id;
      final created = await tree.createTree(
        'Phone test family',
        'Isolated test',
      );
      expect(created, isNotNull);
      expect(
        await tree.addPerson({
          'first_name': 'Parent',
          'last_name': 'Phone',
          'gender': 'O',
        }),
        isTrue,
      );
      final parent = tree.people.single;
      final child = await tree.createRelative(
        sourcePersonId: parent.id,
        role: 'child',
        personData: {
          'first_name': 'Child',
          'last_name': 'Phone',
          'gender': 'F',
        },
      );
      expect(child, isNotNull);
      expect(tree.getChildrenOf(parent.id).single.id, child!.id);
      await Future<void>.delayed(const Duration(seconds: 6));
      expect(
        await tree.updatePerson(parent.id, {
          'biography': 'Saved after token expiry',
        }),
        isTrue,
      );
      expect(
        api.currentUser?.id,
        firstIdentity,
        reason: 'Token renewal must preserve account identity.',
      );
      await tree.loadData();
      expect(
        tree.people.firstWhere((p) => p.id == parent.id).biography,
        'Saved after token expiry',
      );
      final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAI0lEQVR4nGPc0uPGQApgIkk1w6gG4gATkergYFQDMYDkUAIA3A4Bpot30NoAAAAASUVORK5CYII=',
      );
      expect(await tree.uploadPortrait(parent.id, png, 'portrait.png'), isTrue);
      expect(
        await tree.updatePerson(parent.id, {
          'biography': 'Edited with a portrait',
        }),
        isTrue,
      );
      await tree.loadData();
      expect(
        tree.people.firstWhere((p) => p.id == parent.id).profilePicture,
        isNotNull,
      );
      final data = await api.exportTreeData(treeId: created!.id);
      expect(data, isNotNull);
      final destination = await tree.createTree('Import destination', 'Test');
      expect(destination, isNotNull);
      expect(await api.importTreeData(data!, treeId: destination!.id), isTrue);
      await tree.loadData(targetTreeId: destination.id);
      expect(tree.people.length, 2);
      await tester.pumpWidget(providers(const RoyalAncestryApp()));
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot('phone-family-screen');
      final savedAccounts = await LocalStorageService().getSavedAccounts();
      expect(savedAccounts.any((a) => a.userId == firstIdentity), isTrue);
      expect(
        await api.register(
          username: '${username}_b',
          email: '${username}_b@example.test',
          password: 'Phone-Test-483!',
          firstName: 'Second',
          lastName: 'Test connection',
        ),
        isTrue,
      );
      expect(
        tree.people,
        isEmpty,
        reason: 'Identity change must clear the old graph.',
      );
      await tree.loadData();
      expect(tree.trees, isEmpty);
      expect(
        await api.switchToAccount(
          savedAccounts.firstWhere((a) => a.userId == firstIdentity),
        ),
        isTrue,
      );
      await tree.loadData(targetTreeId: created.id);
      expect(tree.people.length, 2);
      expect(
        await tree.updatePerson(parent.id, {'profile_picture': null}),
        isTrue,
      );
      expect(await tree.deletePerson(child.id), isTrue);
      await tree.loadData();
      expect(tree.people.length, 1);
      expect(tree.relationships, isEmpty);
      final reloaded = ApiService();
      await reloaded.init();
      expect(reloaded.currentUser?.id, firstIdentity);
      final cached = await LocalStorageService().getCachedPeople(
        created.id,
        accountScope: api.cacheScope,
      );
      expect(cached.length, 1);
      await api.logout();
      expect(tree.people, isEmpty);
      expect(api.isAuthenticated, isFalse);
      debugPrint(
        'NATIVE JOURNEY PASSED: welcome and registration UI, persistence, token expiry, portrait upload/remove, import/export, two identities, cache and logout.',
      );
    },
  );
}

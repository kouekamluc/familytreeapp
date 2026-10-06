import 'package:flutter/services.dart';
import 'package:flutter_frontend/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_frontend/services/android_handoff.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'real Android document roundtrip, invitation chooser and selected portrait upload',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Kkevo Family native handoff checks')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> capture(String name) async {
        debugPrint('NATIVE_HANDOFF:$name');
        await Future<void>.delayed(const Duration(seconds: 1));
      }

      final payload = jsonEncode({
        'people': [],
        'relationships': [],
        'audit': 'synthetic UTF-8: é ${DateTime.now().millisecondsSinceEpoch}',
      });
      final completedSave = AndroidHandoff.saveJson(payload);
      await capture('native-save-complete');
      expect(await completedSave, isTrue);
      final completedOpen = AndroidHandoff.openJson();
      await capture('native-open-complete');
      expect(await completedOpen, payload);
      final open = AndroidHandoff.openJson();
      await capture('native-open-cancel');
      expect(await open, isNull);
      final save = AndroidHandoff.saveJson(
        jsonEncode({'people': [], 'relationships': []}),
      );
      await capture('native-save-cancel');
      expect(await save, isFalse);
      await AndroidHandoff.shareInvitation(
        'Kkevo Family synthetic invitation. No real code or recipient.',
        'Share invitation',
      );
      await capture('native-share-cancel');
      await Future<void>.delayed(const Duration(seconds: 4));
      final photo = ImagePicker().pickImage(source: ImageSource.gallery);
      await capture('native-gallery-cancel');
      expect(await photo, isNull);
      final selected = ImagePicker().pickImage(source: ImageSource.gallery);
      await capture('native-gallery-complete');
      final picked = await selected;
      expect(picked, isNotNull);
      final bytes = await picked!.readAsBytes();
      final expected = (await rootBundle.load(
        'assets/logo_badge.png',
      )).buffer.asUint8List();
      expect(bytes, orderedEquals(expected));
      final api = ApiService();
      await api.init();
      await api.logout();
      final suffix = DateTime.now().millisecondsSinceEpoch;
      expect(
        await api.register(
          username: 'native_portrait_$suffix',
          email: 'portrait_$suffix@example.test',
          password: 'Native-Portrait-482!',
          firstName: 'Synthetic',
          lastName: 'Portrait',
        ),
        isTrue,
      );
      final tree = await api.createTree(
        'Native portrait $suffix',
        'Synthetic phone fixture',
      );
      final person = await api.createPerson({
        'family_tree': tree!.id,
        'first_name': 'Synthetic',
        'last_name': 'Portrait',
        'gender': 'O',
      });
      final uploaded = await api.uploadPersonPhoto(
        person!.id,
        bytes,
        'synthetic-portrait.png',
      );
      expect(uploaded, isNotNull, reason: api.lastError);
      expect((await api.getPerson(person.id))!.profilePicture, isNotNull);
      await api.logout();
      expect(tester.takeException(), isNull);
    },
  );
}

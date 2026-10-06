import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_frontend/models/person.dart';
import 'package:flutter_frontend/models/user.dart';
import 'package:flutter_frontend/providers/tree_provider.dart';
import 'package:flutter_frontend/views/people/person_detail_view.dart';
import 'workflow_ui_test.dart' show WorkflowApi;

class PortraitApi extends WorkflowApi {
  int uploads = 0;
  @override
  Future<Person?> uploadPersonPhoto(
    int id,
    List<int> bytes,
    String filename,
  ) async {
    uploads++;
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final changedAccount in [false, true]) {
    testWidgets(
      changedAccount
          ? 'photo selected after an account change is never uploaded'
          : 'cancelling the Android photo picker leaves the portrait dialog usable',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        FlutterSecureStorage.setMockInitialValues({});
        GoogleFonts.config.allowRuntimeFetching = false;
        final requested = Completer<void>();
        final picked = Completer<String?>();
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        const legacy = MethodChannel('plugins.flutter.io/image_picker');
        messenger.setMockMethodCallHandler(legacy, (call) async {
          requested.complete();
          return picked.future;
        });
        const androidChannel =
            'dev.flutter.pigeon.image_picker_android.ImagePickerApi.pickImages';
        messenger.setMockMessageHandler(androidChannel, (message) async {
          requested.complete();
          final path = await picked.future;
          return const StandardMessageCodec().encodeMessage([
            <String>[if (path != null) path],
          ]);
        });
        addTearDown(() {
          messenger.setMockMethodCallHandler(legacy, null);
          messenger.setMockMessageHandler(androidChannel, null);
        });
        final api = PortraitApi();
        final tree = TreeProvider(api);
        await tree.loadData();
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: tree,
            child: MaterialApp(
              home: PersonDetailView(person: tree.people.first),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Change portrait'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Choose a photo'));
        await tester.pump();
        await requested.future;
        if (changedAccount) {
          api.user = User(
            id: 2,
            username: 'owner',
            email: 'other@example.test',
          );
          api.notifyListeners();
          await tree.loadData();
        }
        picked.complete(
          changedAccount ? File('assets/logo.png').absolute.path : null,
        );
        // Flush the platform reply, then allow file I/O outside the fake clock.
        for (var attempt = 0; attempt < 30; attempt++) {
          await tester.pump();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          final cancel = tester.widget<TextButton>(
            find.widgetWithText(TextButton, 'Cancel'),
          );
          if (cancel.onPressed != null) break;
        }
        await tester.pumpAndSettle();
        expect(api.uploads, 0);
        expect(find.text('Cancel'), findsOneWidget);
        expect(
          tester
              .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
              .onPressed,
          isNotNull,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
        tree.dispose();
        api.dispose();
      },
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final directory = Directory(
    Platform.environment['FAMILYTREE_TEST_RESULTS'] ?? 'build/device-results',
  );
  await directory.create(recursive: true);
  final sdk = Platform.environment['ANDROID_HOME'];
  if (sdk == null) {
    throw StateError('ANDROID_HOME is required for native UI checks.');
  }
  final adb = '$sdk/platform-tools/${Platform.isWindows ? "adb.exe" : "adb"}';
  Future<ProcessResult> run(List<String> args) async {
    final result = await Process.run(adb, ['-s', 'emulator-5554', ...args]);
    if (result.exitCode != 0) {
      throw StateError('Native UI check failed: ${args.first}');
    }
    return result;
  }

  Future<String> dump(String name) async {
    await run([
      'shell',
      'uiautomator',
      'dump',
      '/sdcard/kkevo-native-check.xml',
    ]);
    final ui =
        (await run(['shell', 'cat', '/sdcard/kkevo-native-check.xml'])).stdout
            as String;
    await File('${directory.path}/$name.xml').writeAsString(ui);
    return ui;
  }

  Future<void> screen(String name) async {
    final result = await Process.run(adb, [
      '-s',
      'emulator-5554',
      'exec-out',
      'screencap',
      '-p',
    ], stdoutEncoding: null);
    if (result.exitCode != 0) {
      throw StateError('Unable to capture native screen.');
    }
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(result.stdout as List<int>);
  }

  String node(String ui, bool Function(String) matches) =>
      RegExp(r'<node\b[^>]*>')
          .allMatches(ui)
          .map((m) => m.group(0)!)
          .firstWhere(
            matches,
            orElse: () =>
                throw StateError('Expected native control was absent.'),
          );
  Future<void> tap(String element) async {
    final bounds = RegExp(
      r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"',
    ).firstMatch(element)!;
    final n = [for (var i = 1; i <= 4; i++) int.parse(bounds.group(i)!)];
    await run([
      'shell',
      'input',
      'tap',
      '${(n[0] + n[2]) ~/ 2}',
      '${(n[1] + n[3]) ~/ 2}',
    ]);
  }

  final roundtripName =
      "kkevo-audit-roundtrip-${DateTime.now().millisecondsSinceEpoch}.json";
  final portraitPath =
      '/sdcard/Pictures/kkevo-audit-portrait-${DateTime.now().millisecondsSinceEpoch}.png';
  await run(['push', 'assets/logo_badge.png', portraitPath]);
  await run(['shell', 'touch', portraitPath]);
  await run([
    'shell',
    'am',
    'broadcast',
    '-a',
    'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
    '-d',
    'file://$portraitPath',
  ]);
  final failures = <Object>[];
  final checkedActions = <String>[];
  Future<void> queue = Future.value();
  // Flutter's surface is paused behind system activities. Observe test-only
  // log markers and capture Android itself instead of calling PixelCopy there.
  final monitor = await Process.start(adb, [
    '-s',
    'emulator-5554',
    'logcat',
    '-T',
    '1',
    '-v',
    'raw',
    '-s',
    'flutter:I',
  ]);
  final subscription = monitor.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
        final marker = RegExp(
          r'NATIVE_HANDOFF:(native-[a-z-]+)',
        ).firstMatch(line);
        if (marker == null) return;
        final name = marker.group(1)!;
        queue = queue.then((_) async {
          try {
            await Future<void>.delayed(const Duration(milliseconds: 900));
            var ui = await dump(name);
            final expected = name.contains('open') || name.contains('save')
                ? ui.contains('documentsui')
                : name.contains('share')
                ? ui.contains('resolver') || ui.contains('Chooser')
                : ui.contains('photopicker') ||
                      ui.contains('PhotoPicker') ||
                      ui.contains('providers.media') ||
                      ui.contains('documentsui');
            if (!expected) {
              throw StateError(
                'Expected Android system UI did not open: $name',
              );
            }
            await screen(name);
            if (name == 'native-save-complete') {
              final field = node(
                ui,
                (e) => e.contains('class="android.widget.EditText"'),
              );
              final oldText = RegExp(
                r'text="([^"]*)"',
              ).firstMatch(field)!.group(1)!;
              await tap(field);
              await run(['shell', 'input', 'keyevent', '123']);
              await run([
                'shell',
                'input',
                'keyevent',
                ...List.filled(oldText.length + 2, '67'),
              ]);
              await run(['shell', 'input', 'text', roundtripName]);
              ui = await dump('$name-ready');
              await tap(
                node(
                  ui,
                  (e) =>
                      RegExp(
                        r'text="save"',
                        caseSensitive: false,
                      ).hasMatch(e) &&
                      e.contains('enabled="true"'),
                ),
              );
            } else if (name == 'native-open-complete') {
              await tap(node(ui, (e) => e.contains('text="$roundtripName"')));
            } else if (name == 'native-gallery-complete') {
              await tap(
                node(
                  ui,
                  (e) =>
                      e.contains('content-desc="Photo taken on ') &&
                      e.contains('clickable="true"'),
                ),
              );
            } else {
              await run(['shell', 'input', 'keyevent', '4']);
            }
            checkedActions.add(name);
          } catch (error) {
            failures.add(error);
            stderr.writeln('Native action failed for $name: $error');
            await run(['shell', 'input', 'keyevent', '4']);
          }
        });
      });
  try {
    await integrationDriver(
      // The framework exits the process itself, so cleanup and native
      // assertions must run in its completion callback before that exit.
      writeResponseOnFailure: true,
      responseDataCallback: (_) async {
        await queue;
        await subscription.cancel();
        monitor.kill();
        await File('${directory.path}/native-system-result.json').writeAsString(
          jsonEncode({
            'checked': checkedActions,
            'errors': failures.map((e) => '$e').toList(),
          }),
        );
        if (failures.isNotEmpty || checkedActions.length != 7) {
          throw StateError(
            'Native checks were incomplete or failed: $failures',
          );
        }
      },
      onScreenshot: (name, bytes, [args]) async {
        await File('${directory.path}/$name.png').writeAsBytes(bytes);
        return true;
      },
    );
    await queue;
    if (failures.isNotEmpty) {
      throw StateError('Native checks failed: $failures');
    }
  } finally {
    await subscription.cancel();
    monitor.kill();
  }
}

# Run the current Kkevo Family mobile app

Open this `flutter_frontend` folder as the Android Studio project. It contains `pubspec.yaml` and `lib/main.dart`. The repository root is the company/app workspace; opening only `android` selects the native Android wrapper.

Enable the Flutter and Dart plugins. The Flutter SDK on this PC is `C:\Users\kouek\dev\flutter`.

Select **Kkevo Family - PC emulator** in the Run menu. Its shared configuration is `.run/Kkevo_Family_PC.run.xml` and uses:

- Entry point: `lib/main.dart`
- Build flavor: `audit`, supplied in the additional arguments
- Additional arguments: `--flavor audit --dart-define=API_BASE_URL=http://10.0.2.2:18000/api`

From the repository root, run `./scripts/start-pc-test.ps1` to start the isolated test backend and virtual phone. Select that virtual phone in Android Studio, then press Run. The server address `10.0.2.2` is the Android emulator's route to this PC.

The audit app package is `com.kkevo.familytree.audit`. The production package is `com.kkevo.familytree`; installing the audit app does not update a previously installed production app.

The launcher stores its interactive APK separately from integration-test APKs. It now checks the app sources, assets, Android settings, dependencies, server configuration and APK hash before reusing that build. An old or changed build triggers a rebuild automatically. `-Rebuild` remains available to force one.

Do not open an old exported APK to obtain current source changes. APKs are snapshots. Use the current Flutter project and this run configuration.

The current interactive PC test APK is `build/pc-test-results/app-pc-audit-debug.apk`. Obsolete exported APKs and integration-test APK copies have been removed. Generated APK/AAB files are excluded from Git; the repository contains the current app source and reproducible build configuration.

Verified on 8 October 2026: Flutter analysis passed; 32 focused regression tests and five build-cache checks passed; both Android journeys passed using the Android Studio emulator server address. The interactive app was reinstalled after testing. These are development checks, not a production release certification.

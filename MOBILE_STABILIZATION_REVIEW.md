# Kkevo Family mobile stabilization

5 October 2026. Scope: repair and verify existing Android workflows. No new product features, design reset, public deployment, or production signing.

## Defects repaired

- Calendar recovery: manually entering year zero or a year beyond 9999 previously caused the date picker to assert instead of opening. Invalid input now opens the calendar at today; cancelling preserves the typed draft. Invalid calendar dates are not silently normalized. A picker result is ignored if its form has closed.
- Language changes: a delayed Android language refresh previously overwrote a newer in-app selection. Pending native updates now finish in selection order, stale refreshes are ignored, and a refresh cannot notify a disposed provider.
- Portrait selection: selecting a photo after changing accounts previously initiated an upload against the new session. The portrait dialog now checks its original account/family and edit permission before selection, after selection, and after reading the file. Removal uses the same context guard and profile revision. Upload/picker errors remain in the dialog, with English/French copy; cancellation releases the busy state.

The calendar, stale-language, disposed-provider, and account-change portrait failures were reproduced before repairs. Regression tests exercise the user-visible outcome, including preserved drafts, the final native language, no cross-account upload, and a usable Cancel action.

## Verification

- Flutter analysis: no issues.
- Flutter automated tests: **57 passed**, including eight additional stability cases. Existing checks cover rejected saves, revision conflicts, family access, account isolation, offline data, relationship paths, and small-phone layouts with large text.
- PostgreSQL backend: **79 passed** using a separate local test database; Django checks pass and migration detection reports no missing changes. An initial sandboxed run could not access temporary backup folders; rerunning outside the Windows sandbox passed without backend changes.
- Android end-to-end verification: **all four journeys passed** on the already running Android 15 / API 35 virtual phone, in 90 seconds. Coverage includes registration/sign-in, expired-token recovery, portrait API upload/removal, import/export, identity isolation, invitations/owner approval, viewing rights, recorded ancestry search, guided adoption, story persistence, relationship exploration, and English/French/phone-language selection. The guided-family journey now also enters year zero, opens/cancels the calendar, corrects the date, and successfully saves the profile.
- The normal interactive audit APK was rebuilt, installed successfully, and opened after testing. It remains version **1.0.0+1**, package `com.kkevo.familytree.audit`, with isolated local test data. Artifact: `flutter_frontend/build/pc-test-results/app-pc-audit-debug.apk`.

Evidence:

- `flutter_frontend/build/stabilization-analysis.log`
- `flutter_frontend/build/stabilization-flutter-tests.log`
- `flutter_frontend/build/stabilization-reproduction.log`
- `flutter_frontend/build/stabilization-portrait-reproduction.log`
- `flutter_frontend/build/stabilization-portrait.log`
- `.dev-logs/stabilization-backend-tests.log`
- `.dev-logs/stabilization-native.log`
- `flutter_frontend/build/pc-test-results/stabilization-installed-final.png` — screenshot of the installed interactive app, visually checked after relaunch; Android reports its app locale as `en`.

## Release boundary

This is a locally validated Android test build. Public HTTPS configuration, production secrets/storage, private release signing, monitoring, off-device backup recovery, and installed-release verification are still required. Native gallery selection and TalkBack must also be checked on supported physical devices; widget tests mock the picker, while the existing native journey exercises portrait upload/removal through the API. Emulator results do not establish real-device performance or production readiness. See `WORKFLOW_COMPLETION_REVIEW.md` for the existing release requirements.

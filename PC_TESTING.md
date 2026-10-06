# Run the Android app on this PC

The `familytree_pc_test_api35` virtual phone runs the current **1.0.0+1** Android app on Windows. It uses the separate `com.kkevo.familytree.audit` package and an isolated test database/media folder, so a physical phone is not required.

The launcher now runs seven Android journeys: device/account isolation, family joining, guided relationships, language, account security, conflicting memory edits/report receipts and Android system file/photo handoffs. The normal interactive app is rebuilt, installed and opened only after checks pass. See [PRODUCTION_GAP_CLOSURE_REVIEW.md](PRODUCTION_GAP_CLOSURE_REVIEW.md) for current evidence and production requirements; earlier dated notes below remain historical.

## Open the app

Double-click `start-pc-test.bat` in the project folder. The virtual phone window opens and the app starts. First boot can take a few minutes.

To rebuild from the current source before opening:

```powershell
./scripts/start-pc-test.ps1 -Rebuild
```

To run all seven device, family, language, account and finishing journeys, then open the normal app:

```powershell
./scripts/start-pc-test.ps1 -RunChecks
```

The journeys create fake accounts and family records and check registration, persistence, token renewal, editing, relative links, portrait upload/removal, JSON export/import, account isolation, cached data, logout, invitation creation/redemption, owner approval, profile reuse, viewing rights and ancestor matching. It does not modify the main family database. The latest finishing journey also exercises Android file save/open with a real UTF-8 roundtrip, chooser cancellation, native gallery cancellation and a selected synthetic portrait upload. Physical-device access denial/revocation checks remain part of release acceptance.

## Local setup

- Official Android Emulator with the installed Android 15 (API 35) Google APIs x86_64 image and Pixel 5 profile.
- Windows hardware acceleration; software graphics rendering avoids this PC's host-driver startup failure.
- Virtual-phone files: `.dev-logs/avds/` (excluded from Git).
- Isolated test data/media: `backend/.device-test/` (excluded from Git).
- API: `http://127.0.0.1:18000/api`, forwarded to this PC from the virtual phone.
- Interactive app copy: `flutter_frontend/build/pc-test-results/app-pc-audit-debug.apk` (kept separate from the journey test build).
- Test screenshots: `flutter_frontend/build/pc-test-results/`.
- Runtime logs: `.dev-logs/pc-api.*.log` and `.dev-logs/pc-emulator*.log`.

The launcher reuses only the backend process that it started. Rebuilds and test runs restart that owned server and apply migrations to the isolated database, so the app and API use the current source. If another server occupies port 18000 or another virtual phone occupies emulator port 5554, it stops with an explanation rather than attaching to unrelated data.

Close the virtual phone window to stop Android. The isolated API remains available locally while its background process is running. No store release or public deployment is involved.

## Verified on 3 October 2026

The current native Android journey passed on this PC's Android 15 virtual phone, including the actual welcome-to-registration screens, saved records, expired-token renewal, portrait upload/removal, family JSON transfer, two account identities, cached records and logout. A captured family screen is saved in `flutter_frontend/build/pc-test-results/phone-family-screen.png`. Flutter code analysis also passed with no issues.

The launcher refreshes native test-plugin registration before builds, disables Bluetooth only inside this dedicated virtual phone to avoid its emulator HAL crashes, and rebuilds the normal app after a successful test. The PC's Bluetooth settings and real family database are unchanged. This emulator run does not certify the native gallery picker, iOS, or a production deployment.

## Verified on 4 October 2026

Both native journeys passed on Android 15 using the updated source. The joining journey creates an invitation through the owner screen, redeems it under another account, verifies pending privacy, approves it through the owner screen, opens the accepted family and checks that the existing profile is reused with viewing access. It also searches using a recorded parent/grandparent path and submits a matching request without granting private access.

Current screenshots: `phone-family-screen.png` shows the normal app shell; `phone-joined-family.png` shows the accepted tree inside the joining test harness. The complete run is logged in `.dev-logs/pc-joining-checks-final.log`. The launcher builds and opens the normal interactive app after the journeys finish.

## Interface redesign verified on 4 October 2026

The app now uses the redesigned Kkevo Family interface. All three Android journeys passed. The new journey creates a family and person through their screens, reviews and saves an adopted child, checks that Back returns to the previous step without losing the draft, preserves a story, selects the direction of a parentage path and checks real-data progress on the home screen. Earlier account and joining checks remain part of the same run.

Evidence: `.dev-logs/redesign-pc-checks-final.log`. Screenshots: `redesign-welcome.png`, `redesign-home.png`, `redesign-profile.png`, `redesign-relationship-preview.png`, `redesign-kinship.png` and `redesign-tree.png` in `flutter_frontend/build/pc-test-results/`. The welcome image is from the normal interactive APK after the journey tests. The other images use explicitly created test records.

The latest debug APK is `flutter_frontend/build/pc-test-results/app-pc-audit-debug.apk`. It runs against the PC test API at port 18000. The browser preview at `http://127.0.0.1:18085/` uses that same isolated API; it is a local preview, not a public deployment. See `REDESIGN_IMPLEMENTATION.md` for the implemented design and release boundaries.

## Latest Android branding and language pass — 5 October 2026

The launcher now runs four native journeys, including English/French/phone-language switching. The current app uses the supplied Eban symbol, an indigo/coral/amber palette, a real-data next-step card, and short Home/Tree/People/Links/You navigation labels. English is the initial language; language controls are on welcome and in the account/settings screens. Android 13+ App languages and themed launcher icons are supported.

Current evidence: `.dev-logs/mobile-brand-language-native-final.log`, `flutter_frontend/build/mobile-brand-language-tests-final.log` (49 app tests), and `flutter_frontend/build/mobile-language-analysis-final.log`. Latest phone screenshots: `mobile-eban-welcome-en.png`, `mobile-eban-welcome-fr.png`, `mobile-eban-home-en.png`, `mobile-eban-home-fr.png` in `flutter_frontend/build/pc-test-results/`. These are Android screenshots, independent of any browser preview. See `MOBILE_BRAND_LANGUAGE_REVIEW.md` for scope and limitations.

## Green mobile experience — 5 October 2026

The next presentation pass replaces indigo with green-led actions, white surfaces, bundled Nunito lettering, rounded family icons, clearer relationship confirmation and a connected real-data Home journey. The name and Eban symbol remain. No new product features were added.

All 58 app checks and four Android journeys passed. The normal interactive audit APK was rebuilt and installed on the existing virtual phone. Follow-up UI tests and light/dark visual renders verify the final tree-label contrast adjustments. Latest evidence: `.dev-logs/mobile-experience-native.log`, `.dev-logs/mobile-experience-install.log`, and `flutter_frontend/build/mobile-experience-*.log`. Screenshots named `mobile-experience-*-final.png` show the installed app. See [MOBILE_EXPERIENCE_REVIEW.md](MOBILE_EXPERIENCE_REVIEW.md) for the palette, verification and release boundary.


## Account finishing — 5 October 2026

The You tab now opens Account and security directly. Verification/recovery uses the isolated file mailbox at `backend/.device-test/outbox`; these messages are test credentials, not production email. Account deletion is an authenticated pending review request with cancellation, not immediate erasure. Shared family records remain intact. Personal keys are shown once on creation and hidden afterwards.

Current checks: 92 backend tests on PostgreSQL, 67 mobile tests, clean Android analysis and five native journeys. Native evidence: `.dev-logs/account-native.log`; account screenshot: `flutter_frontend/build/pc-test-results/mobile-account-deletion-pending.png`. The account review documents migration compatibility and the operational gaps that still prevent public launch.


## Workflow closure — 5 October 2026

All seven Android journeys passed together, followed by rebuilding/installing the normal app. The native handoff journey saves and reopens uniquely named UTF-8 JSON, cancels open/save/share/gallery, selects the seeded Eban image, compares its exact bytes and uploads it to a synthetic profile. Other journeys prove family joining, existing-profile reuse, account security, preserved corrections and report receipts. This uses the real Android document chooser, sharesheet and photo picker, not browser simulations.

Final application checks: 103 PostgreSQL tests, 79 mobile tests, clean static analysis, clean Django checks and no pending model migrations. Evidence: `.dev-logs/final-release-native.log`, `flutter_frontend/build/final-release-tests.log`, `.dev-logs/final-release-postgres-tests.log`, and native `*.png`/`*.xml` captures in the results folder. The completion callback separately asserts every native system action and terminates its test monitor before the framework exits.

Remaining public-release requirements are recorded in [PRODUCTION_GAP_CLOSURE_REVIEW.md](PRODUCTION_GAP_CLOSURE_REVIEW.md). No real email provider, public domain, support address or reviewed deletion rules have been supplied. Deletion is still a pending review workflow. Emulator and isolated-data success do not certify production deployment, physical-phone quality or operating support.


Final native completion evidence: `flutter_frontend/build/pc-test-results/native-system-result.json` records all seven system handoffs with an empty error list. The focused run passed, and the normal verified APK was then restored/opened; `.dev-logs/final-release-install.log` and `release-installed-welcome.png` record that final state. Android reports version 1.0.0+1, min SDK 24 and target SDK 36.

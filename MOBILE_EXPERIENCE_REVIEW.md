# Kkevo Family mobile experience

5 October 2026. This phase refines the existing Android experience with a Duolingo-inspired visual language. No product features or backend rules were added. The Kkevo Family name and supplied Akan Eban geometry remain intact.

## What changed

- A green-led palette replaces the previous indigo theme. White surfaces make actions and artwork stand out; blue supports connections, coral supports memories, and gold highlights family context. Dark mode uses deep green neutral surfaces.
- Rounded Nunito lettering is bundled locally, with its OFL license and verified font files. Rendering does not depend on downloading fonts at runtime.
- The Eban badge and Android launcher icon use green with a readable dark symbol. Decorative family artwork appears on welcome; relationship previews use actual recorded names and initials rather than invented portraits.
- Shared rounded vector icons make the five existing tabs and family actions consistent. Selected icons, buttons, and status labels remain readable in both themes.
- Raised primary buttons retain keyboard activation, button semantics, press feedback and haptics. Reduced-motion settings apply to the updated choice, success and portrait components.
- Home has a more compact overview, one next-step action, and a connected journey with five milestones. Completion still comes only from saved people, connections, generations, stories and accepted family members. No points, streaks or artificial locks were introduced.
- Existing relative and relationship forms use clearer selection tiles and a directional confirmation preview. Draft recovery, date validation, profile reuse, atomic saving and access checks are preserved.
- Family discovery, pending confirmation and accepted requests have distinct labeled states. A suggested family still requires confirmation; presentation changes do not grant access.
- English remains the initial language, with French and phone-language selection. Family names, personal names and authored stories remain untranslated.

## Palette

| Role | Color |
| --- | --- |
| Primary action | `#58C928` |
| Button depth / strong green | `#329C18` |
| Action label / Eban symbol | `#173B22` |
| Soft green surface | `#EDFAE5` |
| Connection accent | `#1CA7EC` |
| Memory accent | `#FF6B5F` |
| Family accent | `#FFC83D` |
| Main text | `#24322A` |
| Dark background | `#131D1A` |

Bright accents are used as fills and illustrations. Small accent labels use darker or lighter variants for legibility. The white and warm surface alternatives were rendered side by side; the white treatment was selected. Dark-mode icon outlines and small tree role labels were corrected after visual inspection.

## Verification

- Flutter analysis reports no issues.
- All **58 app tests** passed, plus the explicit visual renderer. Checks include contrast for core theme labels, account isolation, failed-save recovery, date fields, language races, portrait account guards, permissions and existing screens at 360 px with doubled text size.
- The final tree-label adjustment was followed by another run of the existing UI workflow tests and analysis.
- All **four Android journeys passed** on the already running Android 15 / API 35 virtual phone in 110 seconds. They exercise account creation/sign-in, expired-token renewal, portrait API upload/removal, import/export, invitations and owner review, viewing rights, recorded ancestry search, guided adoption, preserved drafts, story persistence, relationship exploration and language selection.
- Welcome, Home, tree and relationship choices were rendered in light, warm and dark treatments. Native relationship confirmation, tree and French Home screenshots were inspected separately from the browser preview.
- The normal interactive audit APK was rebuilt, installed and opened. Its welcome, example Home and tree were also inspected directly on the virtual phone. The final small tree-control color adjustment uses the same readable theme-aware accent as other controls.

Evidence:

- `flutter_frontend/build/mobile-experience-analysis.log`
- `flutter_frontend/build/mobile-experience-tests.log` — 58 app checks and one explicit renderer
- `flutter_frontend/build/mobile-experience-render.log` — final dark-mode rendering and palette check
- `flutter_frontend/build/mobile-experience-final-ui.log` — final tree readability follow-up
- `flutter_frontend/build/mobile-experience-tree-render.log` — final light/dark tree-control inspection
- `.dev-logs/mobile-experience-native.log` — four Android journeys
- `.dev-logs/mobile-experience-install.log` — normal app build and installation
- `flutter_frontend/build/mobile-design/` — light/warm/dark comparison screens
- `flutter_frontend/build/pc-test-results/` — native screenshots and the interactive audit APK
- `flutter_frontend/build/pc-test-results/mobile-experience-installed-final.png` — installed welcome
- `flutter_frontend/build/pc-test-results/mobile-experience-home-final.png` — installed example Home
- `flutter_frontend/build/pc-test-results/mobile-experience-tree-final.png` — installed example tree

## Release boundary

This work validates the local Android test build, version **1.0.0+1**, package `com.kkevo.familytree.audit`, against isolated test data. It does not complete public deployment or production signing. Production configuration, secrets, HTTPS, monitoring, backup recovery and release-build verification remain necessary. Native gallery selection, TalkBack and performance still require supported physical-device checks. The native portrait journey verifies upload/removal through the API; it does not certify the gallery picker. See [MOBILE_STABILIZATION_REVIEW.md](MOBILE_STABILIZATION_REVIEW.md) and [WORKFLOW_COMPLETION_REVIEW.md](WORKFLOW_COMPLETION_REVIEW.md) for the existing release requirements.

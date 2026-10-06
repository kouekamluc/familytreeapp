# Existing workflow completion review

Reviewed: 1 October 2026; verified family joining and current PC native validation added 4 October 2026. App version: **1.0.0+1** (not changed).

## Assessment

The existing family-record workflows now have connected screens, consistent save/error handling, permission-aware controls, responsive layouts, typed kinship paths, joining error retention and owner review at large text. The automated backend and app checks pass. This is a substantially improved local release candidate; it is **not yet a verified production deployment**.

The work completes the account, tree, member, relationship, kinship, portrait and JSON-transfer workflows. Following the engineering review and the user’s family participation requirements, it now also implements owner-reviewed invitations, ancestry suggestions and viewing/editing access. See `FAMILY_JOINING_IMPLEMENTATION.md` for the exact behavior and remaining limits. Earlier audit documents describe historical findings.

## Changes completed

| Existing workflow | Result |
|---|---|
| Sign-in and registration | Phone welcome opens the complete sign-in form, with a reachable registration choice. Login modals have bounded height. Connection/authentication errors are surfaced and overlapping attempts are guarded. |
| Remembered accounts | Adding another account opens sign-in. Failed switches retain the current account and show an error. Old account key responses cannot populate a different account. Token persistence no longer writes legacy plaintext session keys. |
| Tree chooser | Real member counts and edit/manage permissions are returned by the backend. Create, rename, description edit, and owner deletion use existing backend capabilities with visible errors and pending states. Deletion asks for the exact tree name. |
| Member create/edit | One shared editor handles names, neutral gender, generation, life status, strict optional dates, places, customary name, village, totem, and biography. Failed saves retain entered values; repeated submission is prevented. |
| Add a relative | New or existing members can be linked from a profile. Optional co-parent and relationship notes are saved in the same backend transaction. Invalid co-parent data rolls back the person and every new link. Retried requests use the existing mutation receipt mechanism. |
| Relationship management | Create/edit/delete screens display parent, adopted, step-parent, sibling, current spouse, and former spouse labels accurately. Dates, current status, and notes can be edited. Read-only users cannot mutate records. |
| Tree and member navigation | Empty states lead to tree/member creation; search, generation filters, layouts, family focus, inspector, full profile, and kinship navigation are connected. The inspector uses actual recorded parents/partners/children/siblings. |
| Kinship | The solver describes recorded paths, retains adoption/step-parent distinctions and former-union status, and no longer invents customary authority or marriage roles. Stale member selections are cleared. Neutral-gender, adoptive, and step-parent generation badges follow the recorded links; general path length is not mistaken for generation distance. Empty customary names fall back to generation labels. |
| Verified joining | Single-use expiring/revocable codes connect existing profiles or children/grandchildren through recorded parents. Pending requests grant no access; owner approval preserves existing records and is atomic. |
| Discovery | Private by default, opt-in ancestry suggestions require a recorded parent/grandparent path. Account-bound suggestions are revalidated at request and approval; confirmation grants viewing access. |
| Family management | The owner reviews requests, grants viewing/editing access, removes membership and transfers ownership. New viewers cannot add, edit or delete people/relationships. Tree ownership is protected from account deletion. |
| Editing and recovery | Person/relationship revisions reject stale form saves. Person edits retain a correction trail. Full backups preserve new joining/access state and still read version 4 archives. |
| Android workflow | Compact family header, overflow actions, full-screen long forms, scrollable tree display sheet and Android back transitions support phone navigation. |
| Responsive access | Screens, forms, inspectors, and buttons fit phone and desktop sizes at normal and 200% text. The desktop menu scrolls when its contents exceed the window. Styled buttons support keyboard activation and button semantics. |
| JSON transfer | Export identifies its tree and explains that file contents are excluded. Import captures its destination tree, validates the JSON object, preserves failed input, and reuses a receipt when retrying the same document in the same dialog. A separately opened import starts a new copy operation. |
| Offline state | Deleted trees are pruned from cached graph snapshots. Tree/account changes clear contextual selections. Writes are disabled in offline and demonstration modes. |
| Graph loading | Tree lists omit nested people; the app requests compact graph records. Relationship queries avoid repeated member lookups. Canvas layout and role calculations are cached until graph/layout inputs change. Explicit sibling links are drawn. |
| Welcome content | Unsupported promises of end-to-end encryption, audio recording/playback, printable exports, and dual-orientation rendering have been replaced with descriptions of the implemented workflows. Showcase records are labelled fictional examples. |

## Verification evidence

- **79 backend tests passed** on a separate PostgreSQL test database, covering existing journeys plus permissions, owner tree management, atomic saves/retries, invitations, expiry/revocation, ancestry path freshness, profile reuse, concurrent competing approvals, access transfer/removal, stale edit conflicts, new/legacy backup recovery and graph-query budgets.
- **43 Flutter tests passed**, including failed-save value retention, disabled duplicate submission, strict dates, accurate relationship labels, read-only controls, delayed-key isolation, deleted-cache pruning, keyboard activation, kinship generation direction, responsive layouts, typed kinship paths, joining error retention and owner review at large text.
- Responsive checks cover 14 existing screens/components at **360 × 800** and **1280 × 900**, with text scale **1.0 and 2.0** and dark/light themes respectively. These are layout and interaction checks, not an accessibility certification.
- Current Flutter code analysis reports no issues. The earlier 1 October web release build passed; this joining pass validates Android and widget layouts rather than a newly built browser release.
- Android **audit debug APK builds successfully**. The connected phone disconnected before installation; the **1 October physical-device journey did not execute**. The earlier 30 September phone pass does not certify these newer screens.
- **4 October: both native Android journeys passed** on the dedicated Android 15 PC emulator using the current source. The existing journey checks real welcome/registration screens, persistence, token expiry/renewal, portrait upload/removal, JSON transfer, account isolation/switching, cache and logout. The new journey operates invitation creation/redemption, owner approval, opening the accepted family, profile reuse, viewing permission enforcement, ancestry search and pending privacy through the real joining screens. All records are isolated test data. The interactive app is launched after testing through `start-pc-test.bat`; setup details are in `PC_TESTING.md`.
- Django migration detection reports no missing model migrations; API schema validation completes without warnings.
- A 2,001-person backend fixture verifies compact response size below 3 MB and no more than five database queries for graph lists. This does not establish large-tree frame rates on the phone.
- Browser testing uses fake records in the isolated local SQLite/media environment at port 18000. It verifies password sign-in, empty-account tree creation, persistence after reload, first-member creation, shared inspector/full-profile navigation, member editing, child linking, and saved relationship notes. No real family data is modified by this browser test.

Current evidence: `.dev-logs/joining-full-backend-final.log`, `flutter_frontend/build/joining-flutter-tests-final.log`, `flutter_frontend/build/joining-analysis-final.log`, `.dev-logs/pc-joining-checks-final.log`, `.dev-logs/joining-api-schema.yml`, and `flutter_frontend/build/pc-test-results/phone-joined-family.png`. Earlier evidence: `flutter_frontend/build/final-tests.log`, `flutter_frontend/build/final-web-build.log`, `flutter_frontend/build/phone-final-journey.log`, `.dev-logs/pc-test-run.log`, `flutter_frontend/build/pc-final-analysis.log`, `flutter_frontend/build/pc-test-results/phone-family-screen.png`, and `.dev-logs/final-schema.yml`. Build outputs and test data are local artifacts, not release credentials.

## What remains before production

1. Keep the phone connected and run the current physical-device journey. Manually verify native gallery selection, cancellation, keyboard behavior, back navigation, and screen-reader use on the supported devices. iOS has not been built or tested here.
2. Configure and verify the public HTTPS backend, production database and media storage, allowed origins/hosts, production secrets, and privately signed Android release package. Exercise the installed release against that environment. No public deployment or store submission was performed.
3. Establish off-device backups and monitoring; rehearse recovery of the production database and media together. The existing local restore tests and mocked storage checks are not proof of an operational production recovery process.
4. Validate performance with representative real family graphs and slower networks, and complete language, contrast, screen-reader, and orientation review. English and French can now be selected explicitly, with phone-language fallback. Family-authored content remains in its original language. Kinship now describes recorded paths rather than fabricated cultural roles. Recorded links are the source of truth.
5. Review historical repository data exposure and rotate affected production credentials if applicable. Removing local database/dump files from current tracking does not erase Git history.

Before discovery is offered widely, define a pending-request retention policy, verify living-person/public-tree privacy rules, and replace the bounded relationship scan with indexed matching appropriate to the expected population. Branch joining currently grants whole-tree access.

JSON import adds records and is not a merge. Retrying within the same dialog reuses its receipt; reopening the dialog creates a new operation which may add duplicates. Portrait binaries are not transferred by JSON alone. This is stated in the interface. Backups remain the mechanism for a complete data-and-media recovery.

Changes remain in the working tree for review. No commit, push, deployment, production signing, or production-data restore was performed.

## Current redesign evidence — 4 October 2026

The active interface has been rebuilt around the same Kkevo Family purpose. The latest requested branding uses the supplied Akan Eban symbol: welcoming account entry, five destinations, guided relationship review, record-based family progress, modern profiles, story preservation and relationship-path exploration. Relative creation now supports adoption/step-parentage and deceased family members directly. Existing invitations, matching, access rules, revisions and recovery paths remain in place.

Current checks: 79 PostgreSQL backend tests, 49 Flutter tests, clean Flutter analysis and all four native Android journeys. Evidence: `.dev-logs/redesign-backend-tests.log`, `flutter_frontend/build/redesign-flutter-tests-final.log`, `flutter_frontend/build/redesign-analysis-final.log` and `.dev-logs/redesign-pc-checks-final.log`. The normal Android test package is installed on the PC emulator. See `REDESIGN_IMPLEMENTATION.md` for the complete scope and production boundaries. Earlier screenshots and descriptions above record earlier stages.

The latest Android branding and English-first language evidence is documented in `MOBILE_BRAND_LANGUAGE_REVIEW.md`, `flutter_frontend/build/mobile-brand-language-tests-final.log`, `flutter_frontend/build/mobile-language-analysis-final.log`, and `.dev-logs/mobile-brand-language-native-final.log`.

## Mobile stabilization — 5 October 2026

The next phase repairs existing calendar, language lifecycle and portrait/account-change behavior without adding features. Current verification and remaining production work are recorded in `MOBILE_STABILIZATION_REVIEW.md`; earlier test totals above describe their respective phases.

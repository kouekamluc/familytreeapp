# Existing-feature end-to-end reliability audit

Date: 28 September 2026. Scope: current working tree, including the previous repair edits. This review adds no product features and changes no application behavior. Existing application changes remain uncommitted.

## Verdict

The app builds and its existing tests pass, but it does not yet work reliably end to end. Registration and portrait editing have confirmed client/server contract defects. Additional API probes reproduced invalid genealogy, malformed import acceptance and file corruption during rejected restore. Passing the present suite is not release acceptance.

## Verification performed

| Check | Result |
| --- | --- |
| Django suite | 35 tests passed, isolated SQLite test database |
| Flutter suite | 7 tests passed |
| Flutter static analysis | No issues found |
| Production web build | Succeeded |
| Actual client registration payload against Django | Failed: HTTP 400, required password2 absent |
| Complete backend API journey | Passed with a corrected registration payload |
| Relationship notes-only update | Failed: HTTP 400 although the existing relationship type should be retained |
| Relationship update to self-link | Incorrectly accepted: HTTP 200 and persisted |
| Death date before birth date | Incorrectly accepted: HTTP 200 |
| Portrait URL submitted as current UI does | Rejected: HTTP 400, expected a file |
| Import with duplicate source person IDs and self-parent link | Incorrectly accepted: HTTP 201 |
| Restore of invalid ZIP with replacement media | Rejected for missing people, but existing test file had already been overwritten |

The backend journey exercised registration, JWT login, current user, private tree creation, first person, transactional child creation, edit/reload, export into another tree, deletion, logout and rejection of the revoked refresh token. Its export fixture contained two people and one relationship; this is not broad round-trip certification.

All additional API probes used an in-memory database. Restore testing used disposable media only. No operational database was restored. Full browser interaction, actual mobile devices, fresh dependency installation, PostgreSQL concurrency and production deployment were not verified. The Flutter smoke test renders a standalone text widget, not the real application.

## Required repairs, in order

### 1. Make registration match its existing backend contract — release blocker

Evidence: `flutter_frontend/lib/services/api_service.dart:228` omits password2; `backend/users/serializers.py:102` requires it and both name fields. Earlier work fixed the URL only. The current mocked registration test exercises an error response, so it cannot establish successful registration.

Repair: align the existing form and request with required fields and password confirmation; preserve server validation messages and user input. Do not introduce a separate onboarding feature.

Acceptance: a new account registers from the actual UI, logs in, creates its first private tree and person, and survives reload. Duplicate username/email, weak password and mismatched confirmation fail clearly without false success.

### 2. Isolate account/server state and make session transitions consistent — release blocker

Source evidence: `local_storage_service.dart:77` scopes by lowercased username, not server plus immutable user ID. Saved accounts and active credentials are global. Server settings changes the endpoint and reloads using the current session. `api_service.dart:401` removes active local values without calling backend logout. Account switching writes candidate credentials before validation and does not consistently clear stale persisted refresh/user data. This audit did not reproduce the complete cross-account UI sequence.

Repair: bind credentials, saved accounts and cached graphs to the server and user; clear transient selections and private state on identity change; reject stale asynchronous results; make logout and remembered-account behavior explicit and consistent with the existing controls. Refresh saved credentials after successful token renewal.

Acceptance: two users, two servers with overlapping IDs, expired sessions, failed switching and offline restart never show another identity's data or send its token to another server. Backend refresh revocation and client logout must be exercised together.

### 3. Keep the selected tree and displayed records consistent — release blocker

Source evidence: `tree_provider.dart:337` selects the new tree before loading its records. The load failure branch retains old people and suppresses the error. Cache hydration has awaits after its version check, and ordinary mutations do not guard against account/tree changes while awaiting a response. Successful mutations update memory without refreshing offline caches.

Repair: commit tree/people/relationships together, guard every asynchronous result with identity and request generation, invalidate stale focus/filter state, and persist a complete successful snapshot after mutations. Failed loads must visibly describe the correct tree/state.

Acceptance: start in A, switch to B with its load forced to fail; A's people must never appear under B. Repeat with rapid switching/logout. Create/edit/delete, restart offline and verify the last committed state, including an empty tree.

### 4. Apply genealogy validation to create, edit and import — release blocker

Reproduced: notes-only relationship PATCH is rejected; a partial PATCH can save a self-parent link; death-before-birth is accepted. Source: `backend/family/serializers.py:163` validates only incoming relationship fields instead of merging existing values. Import follows different validation rules.

Repair: shared rules for API writes and imports, merging persisted values for partial updates. Reject self-links, ancestry cycles, invalid chronological dates and duplicate symmetric links while preserving valid unknown dates and supported family structures.

Acceptance: run the same invalid graph/date fixtures through create, partial edit, import and admin validation; verify rollback. Test valid notes-only edits and parent/child direction. No silent correction of existing historical data.

### 5. Connect existing portrait editing to real file handling — high priority

Reproduced: `person_detail_view.dart:193,590` submits a URL string to an ImageField expecting an uploaded file. General profile edits include the existing portrait URL and therefore can also fail on profiles with photos. A multipart upload service exists, but the reviewed portrait UI does not use it. Signed links expire after 300 seconds. The portrait fallback still assigns preset faces to real records.

Repair: use the existing upload operation for the portrait control, omit unchanged photo fields from normal edits, and define explicit removal. Refresh expired links and use initials where the real person has no photo.

Acceptance: upload, reload, edit an unrelated field, wait beyond link expiry, view again, remove and reload. Unauthorized access must fail. Real people without photos must not receive an unrelated fixture portrait.

### 6. Make imports reject ambiguous or invalid data — high priority

Reproduced: duplicate person IDs silently replace entries in the ID mapping and a self-parent relationship is imported successfully. Source: `backend/data_management/views.py:147,168,192`.

Repair: validate the entire document, expected model labels, unique IDs, references and genealogy rules before committing. Keep import destination explicit and preserve all supported fields consistently. Explain that JSON export omits file contents.

Acceptance: representative valid exports round-trip without losing supported fields; malformed sections, duplicate IDs, cycles, missing references and wrong-model records reject the entire import with no partial data.

### 7. Prevent restore from damaging files or accepting incomplete archives — release blocker

Reproduced: an invalid ZIP overwrites media before required-section validation rejects it (`backend/backup/services.py:140`). Database transactions do not roll back filesystem writes. Source also shows unchecked archive destination paths, optional sections later deleted during restore, ignored expected model arguments, omitted users/keys and local-only backup downloads despite S3 support.

Repair: validate manifest, model types, required sections, references, checksums and archive paths before writes; stage files and provide rollback; include dependencies necessary to recover existing accounts/tree bindings; reset sequences where required; retrieve downloads through the configured storage. Rehearse against a separate empty database/filesystem, never production.

Acceptance: invalid or interrupted restore leaves both database and files unchanged. A valid restore reproduces records, memberships and readable files, preserves the documented credential policy and permits new inserts. Test local and S3 behavior if S3 is supported in the deployment.

### 8. Finish failure handling within existing controls — high priority

Source evidence: most writes collapse validation errors to null/false; refresh is not single-flight; photo upload bypasses normal refresh; multipart timeout does not cover the complete send phase; add-person buttons remain available during pending requests. Transactional relative creation is not idempotent after an ambiguous network timeout.

Repair: consistent bounded request handling, field-level feedback, single-flight token refresh, pending-state controls and safe retry behavior. Never report an unconfirmed write as saved or blindly duplicate it after a timeout.

Acceptance: expired-token saves, offline requests, 403/429/500 responses, repeated clicks and interrupted relative creation leave the UI recoverable and create at most one intended record.

### 9. Reconcile existing family views and access-key descriptions — high priority

Source evidence: `tree_provider.dart:159` derives siblings from shared parents and ignores explicit SIBLING links. The relationship model drops dates/current status; kinship and other views interpret supported relations differently. Existing key role labels do not implement scoped membership permissions; keys authenticate as their owner.

Repair: make canvas, details and solver agree for the relationship types already supported, including explicit siblings, adopted/step relations and former spouses. Correct misleading access-key labels/descriptions to match actual personal-login behavior. A new invitation/role system is outside this audit's scope.

Acceptance: one shared fixture matrix produces consistent results across views. Existing key creation/login/revocation communicates and enforces its actual behavior, without suggesting permissions it cannot enforce.

### 10. Verify startup, real screens and supported scale — release requirement

Source evidence: launchers serve an existing build and announce success after delays without readiness checks. Tree listing uses the first page only; people/relationship endpoints are currently unpaginated. The present tests do not cover real navigation, keyboard behavior or mobile layout.

Repair/verification: build current sources, check backend/frontend readiness, use documented server settings, and make unsupported/unavailable actions clear. Measure the current implementation before changing its architecture.

Acceptance: fresh checkout installs and starts from documentation; desktop and phone widths pass login, tree selection, search, forms, pan/zoom and reload; supported languages, keyboard focus and large text are usable. Exercise more than 500 records, disconnected branches and repeated edits. Run database tests against the deployment's PostgreSQL engine as well as SQLite.

## Completion gate

Keep scope limited to existing functionality. Turn every confirmed failure above into a regression test, repair it, then run a real browser/phone journey against an isolated real API with persistence checks. Repeat the journey with session expiry, network failures and identity switching. Release readiness requires no open data-loss/privacy blockers, a successful restore rehearsal and recorded acceptance results, not just a successful build.

New invitations, new role systems, password-recovery screens, event screens and other absent product journeys are not prerequisites added by this audit. They should remain outside this reliability pass.

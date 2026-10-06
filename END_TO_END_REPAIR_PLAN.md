# Family Tree: end-to-end repair plan

Audit date: 25 September 2026. Scope: Django API, Flutter client, local startup, data protection, genealogy, backup and test coverage. The original audit below is retained as a baseline; see the implementation review for current status.


## Implementation review — 28 September 2026

Reviewed commit `cadb2cf` against actual client/server calls. It adds account-scoped caches, write-token refresh, registration and tree-management UI, portraits, relationship checks and ZIP media packaging. These are partial improvements, not completion of all acceptance criteria.

### Gaps closed in this follow-up

- Registration now calls the mounted `/api/auth/register/` route (the previous URL duplicated `/api` and omitted `/auth`).
- Import/export uses the application's authenticated API service instead of constructing an empty session. Import sends the multipart file expected by Django and explicitly selects the current destination tree.
- Relative creation now runs through a backend transaction. A rejected relationship rolls back the new person. Client-side compensating deletion was not atomic. Existing sibling links now use SIBLING rather than SPOUSE.
- Both shell add-person forms stay open on failure, submit empty traditional names correctly, and no longer invent surname/village values. Surname remains required by the backend; missing required values produce a failed save rather than invented history.
- Startup restores the saved endpoint. Requests no longer fall back to unrelated servers; native development defaults to localhost and requires configuring a phone-accessible server explicitly. HTTPS web defaults to the same origin.
- Removed the untracked upload directory from Django installed apps, declared missing JWT/PostgreSQL dependencies, and corrected database configuration documentation.

### Verified evidence

- Existing backend suite: 31 tests passed against an isolated SQLite test database.
- New relative-creation suite: 4 tests passed, covering parent direction, source-tree binding, unauthorized access, invalid roles and rollback after relationship failure.
- Flutter suite: 7 tests passed, including new registration-route and authenticated multipart-import checks.
- Final Dart analysis: no issues found.
- No live browser journey, fresh dependency installation, production deployment, or restore rehearsal was performed.

### Still open (do not mark complete)

- F01/F02: cache scopes use usernames rather than server plus immutable user ID; saved credentials lack server binding; pending requests and account transitions need stronger isolation. Explicit endpoint selection alone does not resolve this.
- F04/F09: single-flight refresh, structured field errors, write idempotency, tree-list pagination, consistent graph switching and mutation-cache persistence remain incomplete. Relative creation is atomic but not idempotent after an ambiguous timeout.
- F07/F08: relationship PATCH validation, shared import/admin integrity checks, full date validation, neutral kinship labels and temporal relationship semantics still need work.
- F10/F11/F12: recovery/profile/tree rename/delete, invitation memberships and roles, event UI, media lifecycle and import preview remain incomplete. JSON import/export is connected but not fully round-trip certified.
- F13: ZIP packaging alone does not make disaster recovery safe. Account/key coverage, strict archive validation, file staging/rollback, checksums and isolated restore rehearsal remain release blockers.
- F14–F16: dependency security review, CI, production configuration, live accessibility review and measured scale acceptance remain outstanding.

## Evidence and limits

- Existing backend suite: **31 tests passed**, using its isolated test database. Django system checks reported no issues.
- Flutter analyzer: **no issues found**. Existing Flutter suite: **5 tests passed**. These checks do not establish full user-journey coverage.
- Source review identified the defects below. They are not all browser-reproduced defects. Responsive layout, real-device behavior and production deployment still require execution testing.
- Existing screenshot scripts use fixed coordinates, delays and localhost:8080; launchers use port 8085. Screenshot collection is not proof that saved data or permissions work.
- The Flutter smoke test renders a standalone text label rather than the application. Existing kinship and preview tests cover a small subset of behavior.
- No production data repair, restore, deployment or dependency upgrade was performed.

## Target end-to-end experience

A new user can register, sign in, create a private tree, add the first person, add or link relatives, edit records, upload a portrait, inspect accurate relationships, invite another user with explicit permissions, export/import supported data, and sign out. Reloading preserves committed data. Switching accounts never reveals another user's private archive. Network failure and expired sessions produce actionable errors without false success. Administrators can restore a verified backup, including files, into a clean environment.

## Ordered implementation backlog

### Phase 1 — Release blockers: privacy, identity and reproducible startup

**F01 — Isolate cached data and reset state (P0, confirmed).**
`flutter_frontend/lib/services/local_storage_service.dart` uses global tree caches and tree-ID-only record caches. Credentials/accounts are also not scoped to a server. `TreeProvider.loadData` hydrates this cache, and logout does not clear it. This permits stale private data to cross account/server boundaries.

Fix: namespace caches by normalized server and immutable user ID; keep public/demo caches separate; invalidate old unscoped caches; cancel pending reads when identity changes; reset selected tree/person, focus, filters, loading and offline state. Define explicit offline unlock and retained-device-data behavior. Default to read-only offline access for the same verified identity.

Acceptance: A logs out, B signs in with the network unavailable, and none of A's people, tree names, keys or photos appear. Repeat across two servers using overlapping user/tree IDs and rapid account changes.

**F02 — Make authentication transitions atomic (P0, confirmed).**
In `api_service.dart`, `switchToAccount` changes tokens without clearing `_currentUser`; `fetchCurrentUser` returns the old user after failure. A failed account switch can therefore report success with the wrong identity. Token presence alone counts as authentication. Logout clears active preferences but leaves saved credentials and does not call backend logout.

Fix: validate the candidate session before committing identity; clear old identity on failure; distinguish authenticated, expired, offline-unlocked and preview states; clear invitation context; update saved refreshed credentials; implement explicit sign-out versus remember-account behavior and server refresh-token revocation. Protect native credentials with platform storage; choose and document browser session persistence deliberately.

Acceptance: invalid/expired B credentials never return A as B; failed refresh returns to a recoverable sign-in state; logout and forget-account have tested, distinct results.

**F03 — Repair environment and server selection (P0, confirmed).**
`ApiConfig.init()` has no caller, so the saved endpoint is not restored on startup. Web defaults force HTTP port 8000; native defaults contain personal LAN addresses. Discovery accepts any response below 500 as success. Requests can try multiple candidate servers, including credentials. The launchers serve an existing web build without checking whether it exists or matches source.

Fix: initialize configuration before requests; use one explicit production endpoint with HTTPS; keep discovery opt-in and development-only; check a real health endpoint; tie stored credentials to the selected server. Add build/start readiness checks and useful failure messages.

`backend/requirements.txt` omits SimpleJWT and a PostgreSQL driver used by the app. README describes DATABASE_URL while settings read DB_* variables. `media` is listed as a Django app but the media directory is ignored and has no tracked application code. Remove that installed-app entry if it is only upload storage, and separate source from uploaded files.

Acceptance: a fresh checkout installs, migrates, starts and builds using the documented commands; configured endpoint survives restart; HTTPS deployment makes no mixed-content requests; credentials never fall back to unrelated hosts.

**F04 — Centralize API error/session handling (P0, confirmed).**
Only `_getWithAuth` refreshes expired tokens; writes bypass it. Several writes have no timeout and collapse server validation errors to null/false.

Fix: one request layer for all methods; shared single-flight refresh; bounded timeouts; structured validation, authorization, rate-limit and network errors; retry authentication failures once. Do not blindly replay ambiguous writes after timeouts; use idempotency for compound creation.

Acceptance: an expired access token followed immediately by a save succeeds once after refresh; invalid input shows the server's field error; disconnected requests stop loading predictably; double submission creates one record.

### Phase 2 — Complete core records and genealogy

**F05 — Stop false saves and invented data (P1, confirmed).**
Both add-person form variants in `views/shell_view.dart` close regardless of `addPerson` success. An empty traditional name is sent as null although the model is a non-null CharField. Missing surname/village are replaced with Kkevo/Bandjoun.

Fix: one shared validated form; send empty optional text as empty text or omit it; keep unknown information unknown; show loading and field errors; close only after confirmed success. Apply the same result handling to edit/delete/key actions.

Acceptance: create with no traditional name; reject bad input while retaining entered values; failed saves keep the form open; no factual fields are silently fabricated.

**F06 — Make relative creation one operation (P1, confirmed).**
`TreeProvider.createRelative` saves a person, ignores the result of `addRelationship`, then returns success.

Fix: a transactional backend create-relative endpoint, including permissions and validation; one successful response updates the client graph. Validate linking existing people through the same domain rules.

Acceptance: force relationship failure and verify neither record is partially created; retry safely; parent/child direction is correct.

**F07 — Enforce relationship and date integrity (P1, confirmed gaps).**
API saves do not invoke model `clean()`; relationship validation currently checks tree ownership/boundaries but lacks self-link and ancestry-cycle rejection. Model date checks therefore do not reliably protect API writes.

Fix: shared domain validation for API, import and admin: no self-relations, no ancestry cycles, coherent life/relationship dates, valid same-tree endpoints, symmetric spouse/sibling uniqueness. Add database constraints where possible and transaction/concurrency tests. Audit existing invalid rows before any corrective migration; do not silently delete ambiguous family history.

Acceptance: reject A→A and A→B→C→A ancestry, reversed duplicate spouses and invalid dates on create and update. Preserve valid multiple spouses, adoption and unknown dates.

**F08 — Make the client genealogy model match the server (P1, confirmed).**
Backend supports SIBLING, ADOPTED, STEP and relationship dates/current status. The client model drops temporal fields, and the solver builds only PARENT/SPOUSE edges. Other genders fall into male labels. Shared spouses are always described as co-wives.

Fix: define directed and symmetric semantics for each supported relation, preserve dates/current status, handle unknown/other gender neutrally, and keep cultural labels separate from factual relationship calculation. Align detail cards, tree canvas and solver.

Acceptance: fixture matrix for biological/adoptive/step families, half siblings, explicit siblings, former spouses, multiple spouses, cousins, disconnected people, unknown gender and duplicate paths. Display uncertain relationships honestly.

**F09 — Load and update complete, consistent graphs (P1, confirmed).**
List calls consume only the first page (`PAGE_SIZE=500`). Successful mutations update memory but not offline caches. Switching trees changes the selected tree before its people/relations have loaded, leaving old data available on failure.

Fix: consume pagination or provide a documented graph endpoint; commit tree/people/relationships as one consistent snapshot; protect all cache hydration awaits with request identity/version checks; refresh caches after committed writes; invalidate deleted focus and selection. Mark stale/offline data visibly.

Acceptance: 501+ people and relationships remain complete; tree B failure cannot show tree A people as B; deleting/editing and then restarting offline preserves the last committed state.

### Phase 3 — Finish missing user journeys

**F10 — Registration, recovery and tree lifecycle (P1, missing connections).**
Registration exists in the backend, but the client has no registration/recovery flow. `ApiService.createTree` has no UI caller. Backend person creation can implicitly choose/create a tree, which does not provide an intentional onboarding experience.

Implement register → sign in → create private tree → first person; explicit tree selector/create/rename/delete; useful zero-tree/zero-person states; password reset/change and editable profile as account features. Validate mail delivery in a test environment before claiming recovery works.

Acceptance: a brand-new account completes the main journey without admin commands or seeded data; destructive tree deletion requires a clear in-app confirmation and explains consequences.

**F11 — Distinguish personal login keys from invitations (P1, confirmed mismatch).**
Heritage keys issue a token for their owning user. Role labels do not scope JWT permissions; approved tree members have edit access. The UI offers family access language/roles, but client key creation does not send tree/person bindings.

Keep personal keys clearly personal. Add separate expiring, single-use invitations redeemed by the recipient's own account. Introduce tree memberships with enforced owner/editor/viewer roles. Do not implement invitations by sharing an owner's login credential. Hash newly issued personal keys, show the secret once, and plan a compatible migration for existing keys.

Acceptance: viewer cannot write through any endpoint; invitation accepts into exactly one tree under the recipient identity; expired/revoked invitations fail; personal-key revocation behavior for already-issued sessions is explicit and tested.

**F12 — Complete media, events and transfer tools (P1/P2, missing client flows).**
Backend media/events/import/export endpoints exist, but the client service exposes no corresponding operations. The Heritage Vault currently manages keys. Portrait fallback uses unrelated bundled faces selected from name/gender/generation (`portrait_helper.dart`, used by `monogram_medallion.dart`). Signed file links expire after five minutes.

Implement portrait/file upload, association, preview, delete and event timeline; validate file type/size and permissions; refresh expired media links and define offline-media handling. Use initials when no actual portrait exists; reserve fixture photos for demo. Add import preview with errors and explicit destination, versioned export and round-trip verification; clearly state when exports omit files.

Acceptance: upload → reload → view after link expiry → remove works; wrong-tree file access fails; real records never receive an unrelated demo portrait; malformed import rolls back completely.

### Phase 4 — Recoverability and production reliability

**F13 — Make backup claims true (P0 before production, confirmed).**
`backup/services.py` serializes file names but not file contents; users and heritage keys are omitted. Restoring deletes people/trees, which can clear existing key bindings through SET_NULL. S3 backups store object keys, but the download action checks local filesystem paths. Validation requires only people/relationships, so an incomplete file can omit sections that restore subsequently clears. `_restore_model` does not enforce its model argument against each serialized entry.

Fix: separate user export from operator disaster recovery; use a versioned manifest, strict model/section/reference validation, checksums, database snapshot plus actual files and required account/membership records. Preserve key bindings according to documented credential recovery policy; reset database sequences after explicit-ID restore. Implement storage-agnostic streaming downloads. Validate a complete archive before changes and rehearse restore into an isolated environment, with a pre-restore snapshot and failure rollback strategy for both database and files.

Acceptance: clean-environment restore reproduces people, links, memberships, events and readable files; new record creation works afterwards; corrupt/incomplete/wrong-model archives are rejected; both local and S3 downloads work.

**F14 — Release hygiene and operations (P1).**
`backend/db.sqlite3` and `backend/dump_backup.json` are tracked. Review their provenance and contents privately; move actual operational data outside version control and rotate any credentials found exposed. Do not erase history or data automatically.

Add environment examples without secrets, reproducible dependencies, CI, health/readiness checks, deployment configuration, structured error reporting, upload limits and backup monitoring. Check production HTTPS/cookies/proxy/CORS settings. Audit throttling on the actual token endpoint used by Flutter, rather than assuming the custom LoginView's throttle applies. Review dependency support/security against official advisories during implementation; this audit did not perform an advisory scan.

### Phase 5 — Usability, scale and release acceptance

**F15 — Consistent navigation, language and accessibility (P2, needs live UI audit).**
Centralize currently mixed French/English strings and expose a deliberate locale choice; unify desktop/mobile forms and navigation. Test tree pan/zoom/fit, orientation, focus after edits, search/filter reset, browser back/reload, small screens, keyboard focus, screen-reader labels, light/dark contrast and 200% text scaling. Label preview and offline mode clearly and disable unavailable actions with a reason. Inspect real rendered screens before prescribing layout changes.

**F16 — Measure and fix large-tree performance (P2, source-indicated risk).**
Tree lists embed people and person serializers perform related-family queries repeatedly. Add lightweight list serializers, measured query budgets, appropriate prefetching/indexes, graph-layout caching and culling where measurements justify them. Avoid returning repeated full nested family graphs.

Acceptance: benchmark 100/500/2,000-person fixtures and record API query counts, payload sizes, rendering time and interaction latency. Set agreed performance budgets using target devices before release.

## Delivery sequence and dependencies

1. Reproducible setup and failing regression cases: F03, baseline CI.
2. Identity/privacy/request handling: F01, F02, F04. These block safe multi-account work.
3. Core editing/data integrity: F05–F09. These block trustworthy genealogy and imports.
4. Onboarding and memberships: F10–F11, followed by F12.
5. Backup correctness and deployment: F13–F14. Recovery design starts early; release waits for its rehearsal.
6. Live UI review and scale fixes: F15–F16, then full acceptance run.

Each change should include the regression test that demonstrates the original failure, focused implementation, and relevant acceptance evidence. Keep data migrations separate, reversible where possible, and preceded by a verified snapshot. No calendar estimate is assigned before the first baseline and product-scope decisions.

## Release acceptance matrix

| Journey | Required evidence |
| --- | --- |
| Fresh install | Clean checkout installs, migrates, builds and starts using documentation |
| New user | Register, login, create tree, add first person; reload preserves data |
| Family editing | Create/edit/delete people; link/add relatives; refresh and verify persisted graph |
| Invalid graph | Self-link, cycle, invalid dates, cross-tree links and duplicates rejected |
| Sessions | Expired token save, invalid refresh, logout, remembered accounts and rapid switching |
| Privacy | Two accounts/two servers, offline startup and stale requests; no cross-account data |
| Roles | Anonymous, unrelated user, viewer, editor and owner tested for every resource/action |
| Key/invitation | Personal-key lifecycle; separate invitation redemption, expiry and revocation |
| Media/events | Upload, view after expiry, update/delete, permissions and reload |
| Import/export | Valid round trip, malformed file, duplicate IDs, large file and rollback |
| Recovery | Restore into clean database/filesystem; verify all counts, links/files and next inserts |
| UI | Desktop and phone sizes, keyboard, 200% text, both themes and selected languages |
| Resilience | Offline, timeout, 401/403/429/500, repeated click and interrupted compound creation |
| Scale | More than one API page, large families and disconnected branches |

Release only when all P0/P1 items in the agreed product scope are complete, automated checks pass, the main journey passes against a real API, and backup recovery has been demonstrated. A passing backend suite or attractive screenshots alone are insufficient.

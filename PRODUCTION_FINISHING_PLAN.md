# Kkevo Family: production finishing plan

Prepared 5 October 2026. Scope: the Android mobile app and the services needed to run its existing workflows. The original planning pass made no app changes. Implementation has since started; the dated progress note below records its current scope.

## Implementation progress — 5 October 2026

The account pass and subsequent workflow closure now cover private family enforcement, indexed parent/grandparent suggestions, Android invitation sharing and file handoff, pending-state refresh, conflict review, protected expiring drafts, persistent retry receipts, content reporting and Android release checks. See [PRODUCTION_GAP_CLOSURE_REVIEW.md](PRODUCTION_GAP_CLOSURE_REVIEW.md) for the current evidence and exact limits.

The item descriptions below retain the original planning baseline. They should not be read as current missing-code findings. A1 still needs real mail delivery; A2 is still request/review rather than completed erasure; A5 needs reviewed policies, real public resources and staffed handling. Staging, off-device recovery, signed physical-device testing and a family pilot remain release gates. The user confirmed that the domain, support email, mail provider and reviewed privacy/deletion rules do not exist yet. No production deployment or real-data migration has been performed.

## Product direction

Make Kkevo Family the easiest trusted place for a family coordinator to connect relatives to their correct place in a private tree and preserve their stories. Start with adult family coordinators and the relatives they invite, particularly families using English and French across households or countries. This is a proposed launch focus, not a finding that these users have already been validated.

The main journey is:

**Create your own account → start or find your family → record the correct connection → receive family confirmation → preserve a memory → bring another relative into their existing place.**

The product's advantage should be an understandable family relationship, confidence about who can see it, and a straightforward next action. Duolingo is the reference for approachable visuals and interaction; family history should not be rewarded for speed, invented facts, or daily streaks.

Private family collaboration and invitations already exist in established products such as [FamilySearch family group trees](https://www.familysearch.org/en/help/helpcenter/family-group-trees-learning-center). My inference is that those functions alone will not distinguish Kkevo Family. Our launch hypothesis is that simpler Android participation, clear approval, respectful cultural context and trustworthy private records will. Validate that hypothesis with families before claiming market leadership.

## What we have, and what that proves

- The current mobile interface has welcome, account entry, Home, Tree, People, Links and account settings; guided relative creation; stories; portraits; personal login keys; import/export; family invitations; owner review; ancestry suggestions and access management.
- Saved facts drive five Home milestones. Relationships preserve biological, adoptive and step distinctions. Unknown details can remain unknown.
- Local evidence from the previous implementation pass: 58 app tests, clean analysis, four Android emulator journeys, and an installed audit build. The prior backend stabilization reports 79 PostgreSQL tests.
- Those results establish a tested local build. They do not establish a signed production release, operational recovery, physical-phone quality, user adoption, or market readiness. No readiness percentage is assigned.
- Older plans contain defects that have since been repaired. This plan uses current source and the latest reviews rather than reopening every historical item.

## Rule for adding anything

Every proposed addition must identify an existing screen or workflow that cannot yet be completed safely or naturally, describe the missing step, and provide an acceptance test. Use existing models and native Android capabilities where practical. Add a dependency only when it materially improves that specific step, has suitable maintenance/privacy characteristics, and passes release-device checks.

Allowed examples: recovery for existing sign-in, account deletion, sharing an existing invitation, resuming an interrupted existing form, a usable stale-edit resolution, and reporting problems with existing shared stories or portraits.

Outside this release: chat, public social feeds, DNA tools, AI-generated ancestry, points/streaks, subscriptions, new media types, contact harvesting, a separate website product, iOS expansion, and general event timelines merely because dormant backend endpoints exist. Minimal public policy/support/deletion pages are release support resources, not a website redesign. Keep the Kkevo Family name, Akan Eban symbol and current green visual direction.

## Execution order

Priority P0 means a blocker for public release. P1 means necessary to deliver the existing experience well before launch. Each batch ends with evidence and a reviewable result; external publishing remains a separate release decision.

### Batch 1 — Complete account ownership and family privacy

| Item | Current evidence | Work and acceptance |
| --- | --- | --- |
| A1: Recovery and account settings — P0 | `backend/users/urls.py` and `UserView` expose registration/sign-in and account reading; no password-reset/change or account-deletion route. | Add forgot-password and authenticated password change; edit the basic account identity already collected. Recovery must verify control of the email, use expiring single-use tokens, avoid revealing whether an account exists, and invalidate sessions according to a documented policy. Prove delivery through the chosen mail service, expired/reused tokens, and signed-app recovery after logout. Verify email ownership before relying on it for recovery; do not lock existing families out during migration. |
| A2: Safe account exit — P0 | Ownership transfer and protected tree ownership exist; there is no user-facing account-deletion journey. | Add an understandable deletion request and completion path, with recent authentication, a clear data summary and progress/confirmation. A family owner can transfer a shared tree using the existing workflow; a sole owner gets an explicit tree-disposition choice. Provide a supported path when the owner cannot complete transfer. Define deletion/anonymization for account data, profile associations, uploads, requests, logs and backups. Do not assume removing a login satisfies personal-data deletion or silently preserve every shared record. Obtain a reviewed shared-history/retention policy and test deletion as viewer, editor, owner and sole owner. |
| A3: Personal credential hardening — P0 | `HeritageKey.key` stores a readable credential; serializers expose key data. Invitation codes already use digests. | Store a verifier for personal login keys; reveal newly generated secrets once, show masked metadata thereafter, and provide replacement/revocation. Plan a compatible migration and recovery path before changing existing keys. Ensure routine user/profile responses, logs, database admin strings and diagnostic exports do not disclose credentials. Test old/new key transition, expiry, revocation and the effect on existing sessions. Personal keys remain personal sign-in credentials, never family invitations. |
| A4: Private launch boundary — P0 | `can_access_tree` permits public-tree reads; `is_public` and `discovery_enabled` are separate settings. Joining currently grants whole-tree viewing. | Keep the initial release private, enforce that boundary on the server, and audit existing public rows before any visibility migration. Preserve consent and recorded history rather than silently changing existing families. Explain whole-tree visibility before approval; a close-family display filter is not an access boundary. Show precisely what discovery reveals and keep it separately opt-in. Prove an unrelated account cannot fetch people, portraits, stories or transfer files. Do not market branch-only privacy. |
| A5: Policies and shared-content safety — P0 | Shared stories and portraits exist; the account UI has no complete policy/deletion/support journey. | Publish accurate privacy, retention, terms and support information; make it reachable from welcome/settings. Complete the actual SDK/data inventory and Play Data safety disclosures. Add a minimal in-app report path for existing content and users, an operator handling process, and applicable blocking/protection controls following the policy assessment. Existing owner removal is useful access control, not automatically equivalent to user blocking. Decide account age eligibility and protect living-person/minor records; adult pilot recruitment does not itself establish age-policy compliance. |

Google Play requires apps offering account creation to provide an in-app deletion path and an external deletion-request resource. This makes A2 a concrete store requirement, alongside its value to users. [Account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en).

Shared stories and portraits fall within Google's definition of user-generated content because other users can access them. The policy requires accepted terms, ongoing moderation and reporting, with protections depending on the interaction model. Implement controls for the actual private family experience; do not add a public social product. [User-generated content policy](https://support.google.com/googleplay/android-developer/answer/9876937?hl=en-GB).

**Batch exit:** a person can own, recover and leave their account; private family boundaries are demonstrable; credentials are not routinely exposed; the deletion/reporting journeys have operational owners.

### Batch 2 — Close the family participation loop

| Item | Current evidence | Work and acceptance |
| --- | --- | --- |
| B1: Invitation handoff — P1 | Invitations can be created and copied; recipients enter the code separately. | Add the Android share sheet for a short invitation explaining who invited them and what happens next, using the existing code flow. Preserve an entered invitation through sign-in/registration without treating it as a credential or granting access early. Clear secrets on cancellation/expiry; avoid logging them. A share sheet is user initiated; the app does not send messages autonomously. A verified app link may follow only if the code handoff still fails pilot testing; QR scanning is not required for launch. |
| B2: Pending-to-accepted completion — P1 | Requests have states and manual refresh. | Refresh relevant request state when returning to the app/screen, expose a small pending count in the existing account/Home entry, and distinguish waiting for owner approval from a failed request. Approved users open the correct family/profile; rejected, expired and revoked requests have an appropriate existing retry/contact action. Explain viewing versus editing rights and how owners grant the latter. Test with two phones and an owner away from the app. Start with in-app status; push notifications are not required in this scope. |
| B3: Discovery correctness and scale — P0 before broad discovery | `ancestry_candidates` scans the first 10,000 eligible links. A valid later path can therefore be missed. | Replace the bounded scan with indexed normalized name/path queries over opted-in families, preserving account-bound suggestions, exact recorded paths and approval revalidation. Prove a valid path beyond the old cutoff is found and conflicting known facts are rejected. If necessary, expose the optional parent date/place already accepted by the API as disambiguation details. Unknown ancestry leads to invitation/create-family alternatives, not fabricated matches. Keep surname-only and automatic merging out. |
| B4: Corrections and interrupted work — P1 | Revision conflicts retain a draft in an open form; closing/restarting does not provide a full recovery journey. | Add a clear review-latest/reapply-your-change path without silently overwriting either editor. Warn before discarding meaningful unsaved changes. Persist only the drafts that lifecycle tests prove necessary, securely isolated by account/server/family, with expiry and logout/deletion cleanup. Do not introduce queued offline writes or a general merge engine. Test app backgrounding/process death, network loss after submit, changed permissions and two-editor conflicts. |
| B5: Portrait and transfer completion — P1 | Portrait URL refresh, initials, import receipts and JSON warnings exist. Native gallery behavior remains unverified; reopening an import starts a new copy. | Verify gallery cancellation, denied/revoked access, image limits, upload interruption and expired links on real phones. Make existing JSON transfer use Android file open/save/share naturally, with destination, record counts, previewed validation failures and an explicit copy warning. Explain duplicate risk on a repeated import; distinguish retrying the original receipt from explicitly creating another copy where needed. JSON still excludes portrait files and is not a full backup. Test large files and interrupted requests without partial records. |

**Batch exit:** one family coordinator can invite a relative; that relative can reach their correct existing profile, understand their access and contribute or request the appropriate permission. The next family participant can repeat the same journey without assistance.

### Batch 3 — Finish Android usability, wording and performance

This is a consistency pass, not another visual reset. Keep the current palette and finish the remaining legacy screens, sheets, loading/error states and destructive actions using the same components. Replace confusing vault/royal wording where it obscures personal account access. Help appears at the point of uncertainty: parent direction, adoption, an unknown date, pending confirmation, and viewing permission.

Complete English/French error presentation. Backend joining errors currently include French prose, so English-first screens can still show mixed-language messages. Use stable error codes and localizable client copy, including field validation and conflict states, while preserving user-authored names and memories exactly.

Verify Android back behavior, edge-to-edge/insets, keyboards, autofill, TalkBack reading order and labels, reachable tree controls, theme changes, reduced motion, 200% text, permission denial, offline startup, reconnection and account switching. A stale cached view must be recognizable; removed access must not be presented as current authorization. Device tests must include the real native picker, not just the portrait API.

Run release/profile performance measurements with 100, 500 and 2,000 people, disconnected branches, long names and repeated portraits. Inspect startup, graph layout, pan/zoom, search, memory and API query/payload costs on a budget phone as well as a mainstream phone. Apply culling, caching or indexes only where profiling shows a bottleneck.

Proposed initial budgets: cold start to a usable first screen within 3 seconds; cached 100-person graph usable within 2 seconds; 2,000-person graph within 5 seconds; no repeated freezing during pan/zoom. Measure on an agreed approximately 3 GB reference phone; record the device, release mode and network conditions, with at least ten runs and p95 results. These are proposed product targets, not existing measurements. Establish the supported maximum graph size from measurements before making unlimited-tree claims.

Use the [Android core app quality guidelines](https://developer.android.com/docs/quality-guidelines/core-app-quality) for the device acceptance matrix. Monitor release crashes and non-responsive sessions through [Android vitals](https://developer.android.com/topic/performance/vitals/), rather than interpreting emulator frame warnings as production performance results.

**Batch exit:** an unfamiliar user can complete every shipped task on supported physical phones in either language, at large text, without hidden controls, lost drafts or unexplained permission failures.

### Batch 4 — Prove the service and the actual release package

1. Establish separate staging and production configuration: HTTPS domain, PostgreSQL, private media storage, mail delivery, required secrets, host/proxy rules, retention and least-privilege operational access. Use test families in staging. Audit historical repository data exposure privately and rotate affected credentials if found.
2. Set automated off-device database-plus-media backups and demonstrate a restore into a clean environment, including accounts, access roles, profile associations, stories, readable portraits and successful new inserts. Check restored deletion/retention state too. Proposed initial recovery objectives: at most 24 hours of data loss and service recovery within four hours; validate and fund these targets before launch.
3. Add privacy-safe error monitoring, uptime checks and alerts for API failures, mail failures, storage failures and missed backups. Never include tokens, invitation secrets, family names, ancestry inputs, photos or story text in analytics/diagnostic events. Define who responds and how users contact support.
4. Update existing CI to validate Android builds and their supported API compatibility. Its current Flutter job builds the web release, not the Android release. Protect signing secrets; use synthetic fixtures for automated device checks. Recheck supported dependency versions and security advisories during implementation.
5. Build the privately signed production App Bundle and test its delivered APKs through a Play test track. The current `audit` package is not the release package. Verify release HTTPS restrictions, fonts/icons, plugin registration, mail recovery, portrait selection and the four existing journeys against staging, then test upgrade from the prior build without losing account/cache state.
6. Prepare the real store listing, screenshots, content rating, target audience, data disclosures, support/deletion links and reviewer access using synthetic families. Confirm the developer account's actual testing obligations in Play Console before setting a release date.
7. Rehearse a staged rollout and rollback. Keep database/API changes compatible with the prior app during rollout. A software rollback must preserve legitimate user writes; restoring an older database is an incident recovery step, not a routine deployment reversal.

For personal developer accounts created after 13 November 2023, Google currently requires at least 12 continuously opted-in closed-test participants for 14 days before applying for production access. This condition is not assumed to apply to the user's account until its type/date are known. [Testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en-GB).

**Batch exit:** recovery works outside the development PC, an accountable operator can diagnose failures, and the signed installed release works with production-like settings.

### Batch 5 — Validate the value with families, then launch gradually

Recruit three to five consenting families with different levels of Android confidence, including a coordinator, invited viewers and at least one editor per family. Aim for 15–25 adult participants and a two-week pilot; satisfy any separately applicable Play tester requirement. This is a recruitment plan, not authorization to contact people or enroll accounts.

Observe these existing tasks without coaching: create a family; add a parent/child correctly; invite a relative to an existing record; approve and open the family; preserve a story; correct a fact; recover sign-in; export records; leave/delete an account. Ask what feels confusing, unsafe or unnecessary. Fix those failures before considering new features.

Proposed pilot acceptance:

- At least 80% of new coordinators create a person and correct connection within five active minutes without help.
- At least 80% of recipients submit their invitation request without help. Measure owner waiting time separately from recipient interaction time.
- Every tested approval opens the intended existing profile with the correct access; there are no unauthorized disclosures, unintended duplicate claims or silent losses.
- At least four of five pilot families have a second participant successfully view the tree and perform an allowed contribution or owner review during the pilot.
- At least 80% can accurately explain who sees their family and what a suggested match means.
- All P0 blockers are closed, no unresolved data-loss/security defects remain, and support/report/deletion requests have demonstrably functioning handling paths.

These small-sample targets are launch-learning gates, not proof of product-market fit. Measure family-level activation and repeat meaningful contributions after seven and fourteen days, not time spent tapping or daily streaks. Use consented minimal aggregate events or pilot observation; do not add a broad analytics SDK by default.

Market/store language should describe proven capabilities: private family trees, recorded family connections, family-reviewed invitations and preserved stories. Do not promise guaranteed ancestry matching, end-to-end encryption, branch-only access, unlimited scale or features not shipped.

## Release gate and handoff

Maintain one checklist with each item's source finding, owner, acceptance evidence, severity and status. Mark an item done only after its whole journey works, including error and recovery paths. Keep migrations separate and rehearsed against an isolated snapshot.

Release requires all five batch exits, a signed-build device matrix, tested operational recovery, correct store disclosures and a reviewed pilot report. Marketing quality follows from this proof; another visual redesign cannot substitute for it.

External inputs eventually needed: release domain and operator identity; hosting/mail/storage accounts and budget; support owner and response process; reviewed privacy/deletion/retention rules; private signing custody; Play developer account details; supported-device choices; consenting pilot families. Code preparation and local verification can proceed before those inputs are supplied. Do not publish, send invitations to real people or migrate production data as part of this planning turn.

Start implementation with **A1–A3**, while defining A4–A5 and preparing staging. Then complete B1–B5, perform the Android quality pass, prove the signed release and run the family pilot. No calendar completion promise is assigned until provider setup, source changes and physical-device availability are known.

## Current source anchors

- Account lifecycle: `backend/users/urls.py`, `views.py`, `serializers.py`; `flutter_frontend/lib/views/auth/login_view.dart`; `lib/widgets/user_profile_sheet.dart`.
- Personal login keys: `backend/users/models.py`, `serializers.py`; `lib/widgets/heritage_key_sheet.dart`.
- Discovery and access: `backend/family/joining.py`, `permissions.py`, `access_views.py`; `lib/views/family_connections_view.dart`.
- Revision/draft handling: `lib/widgets/person_editor_dialog.dart`, `relationship_editor_dialog.dart`, `relative_editor_dialog.dart`, `story_editor.dart`.
- Release: `flutter_frontend/android/app/build.gradle.kts`; `backend/familytree/settings.py`; `.github/workflows/validate.yml`.
- Existing evidence: [MOBILE_EXPERIENCE_REVIEW.md](MOBILE_EXPERIENCE_REVIEW.md), [MOBILE_STABILIZATION_REVIEW.md](MOBILE_STABILIZATION_REVIEW.md), [FAMILY_JOINING_IMPLEMENTATION.md](FAMILY_JOINING_IMPLEMENTATION.md), [WORKFLOW_COMPLETION_REVIEW.md](WORKFLOW_COMPLETION_REVIEW.md).

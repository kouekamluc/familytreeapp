# Family joining implementation

Updated 4 October 2026. App version remains **1.0.0+1**. This implements the verified family joining direction agreed during the engineering review. The original analysis is in `BUSINESS_LOGIC_EXECUTION_PLAN.md`.

## Implemented workflow

1. Each participant creates or uses their own account. Personal Heritage Keys continue to sign into their owner's account; they are not family invitations.
2. The family owner creates a single-use invitation for an existing recorded person, a child of a recorded parent, or a grandchild through a recorded intermediate parent. Codes expire after seven days, can be revoked, and are stored as digests.
3. The recipient submits a request. No private family access is granted while the request is pending. The recipient can cancel; the owner can approve or reject.
4. Approval reuses the existing profile and its history, or creates a child with a validated parent link. Grandchild joining preserves the two relationships through the intermediate parent. Approval, profile association and membership are one transaction.
5. New members receive viewing access. The owner can deliberately grant editing access, remove access, or transfer ownership. Joining a branch currently grants access to the whole tree; there is no separate branch visibility boundary.
6. Families are excluded from discovery by default. Owners can opt in. Applicants can search using a parent's full name and that parent's parent's full name. Suggestions require a matching recorded path, normalize case/spacing/accents, and distinguish ordinary, adoptive and step-parent links. They do not prove identity or grant access. Known conflicting dates/places are rejected by the API.
7. Candidate responses expose the consented family name and a short-lived, account-bound request token. The owner sees the submitted facts and target profile before confirming. The path and facts are checked again when submitting and approving, preventing stale suggestions from linking an account incorrectly.

## Data and workflow corrections

- Person identity uses record IDs; legitimate namesakes are allowed. Missing imported gender stays unknown.
- Account deletion cannot cascade through owned trees. Linked person records survive deletion of an associated account. Ownership transfer leaves the former owner as an editor.
- Person and relationship edits carry revisions. Editors using a stale form receive a conflict instead of overwriting a newer edit. The draft remains in the open form; closing it to reload still requires manually retaining any desired changes.
- Person edits retain an owner-visible correction trail. This is not a complete audit of every create/delete/media operation and is not per-record undo.
- Import retries in the same dialog retain a request key and reuse their receipt. A changed document gets a new key. Reopening the dialog starts a new copy operation; JSON import does not merge records or include portrait binaries.
- Full backups include roles, profile associations, invitations, requests, revisions, correction records and mutation receipts. Version 4 archives remain readable with private discovery and initial revision defaults.
- Owner changes and graph writes use consistent tree locks. Concurrent claims cannot confirm two accounts against the same recorded profile.

## Android changes

The family joining and access-management screens are reachable from the account menu and tree chooser. Phone headers show the current family and access level, with secondary actions in an overflow menu. Long person and relationship forms fill the phone screen. Tree display controls open in a scrollable options sheet. Material 3 controls, Android back transitions, keyboard-aware scrolling and reachable action buttons support the existing workflows. Joining errors retain input and bring the error into view.

## Scope and production limits

This is a local release candidate. No production database migration, deployment, release signing or store submission was performed.

- Invitations require an owner to check identity; ancestor names are not an authentication factor.
- Discovery currently uses deterministic exact normalized names and scans up to 10,000 eligible relationships, returning at most ten suggestions. Indexed matching, representative load testing and a retention policy for pending requests remain necessary before a large rollout.
- Access removal cannot erase data someone already downloaded. Public tree visibility remains broader than discovery; living-person publication needs an explicit policy before enabling public families in production.
- Release configuration, operational monitoring, off-device recovery rehearsal and physical-device checks remain outstanding. Native gallery selection, screen-reader use and iOS are not certified by the emulator tests.

Verification results are recorded in `WORKFLOW_COMPLETION_REVIEW.md` and the PC setup is documented in `PC_TESTING.md`.

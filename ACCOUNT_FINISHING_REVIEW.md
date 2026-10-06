# Android account finishing pass — 5 October 2026

This implements the first account batch from `PRODUCTION_FINISHING_PLAN.md`. It completes controls around existing accounts and personal sign-in keys. It does not certify the app for public release.

## Implemented behavior

- The Android **You → Account and security** screen exposes email verification, name editing, password change and deletion requests. It is also reachable from the account sheet.
- An authenticated account can request an email verification code and confirm it. Password recovery from sign-in requires a verified email. Recovery requests return the same message for unknown and unverified accounts.
- Codes are random, stored as digests, bound to the current account credentials, expire after 30 minutes and are usable once. Reissuing invalidates the previous code. Failed password validation preserves the valid recovery code.
- Password changes and resets invalidate existing access and refresh sessions on all devices. The Android app signs out after a password change and accepts a fresh sign-in. Personal login keys remain valid until separately revoked; the screen explains this.
- Editing names, requesting deletion and cancelling deletion require the current password. Request submission is idempotent. Owned families link to existing access/ownership management.
- **Deletion requests are pending operator review. This is not completed account or personal-data deletion.** Requesting or cancelling does not erase shared family records. The admin queue prevents marking a request completed while its account still exists. A CSRF-protected credential form is available at `/account/deletion/`; its public hosting and operational handling are still release work.
- Personal login keys are stored as SHA-256 verifiers. Generated secrets are displayed once, can be copied then, and are absent from subsequent lists/profile/sign-in responses and provider state. Key revocation prevents new key sign-ins; existing sessions remain active, as stated in the UI.
- Legacy cached user/key metadata no longer recreates personal secrets. Session credentials continue to use the existing Android secure storage.
- New screens support English and French, phone language preferences, smaller displays and larger text. Failed actions preserve input and prevent duplicate taps. Account switching hides previous-account details and transient keys.
- Backups now use version 6. Version 4/5 conversion preserves old key sign-in compatibility without restoring readable keys. Pending deletion reviews are backed up; email codes are excluded and cleared during restore.

## Migration and release preparation

1. Rehearse against an isolated copy of the actual database and media. Take a protected database/media snapshot first; older backups may contain readable keys and require restricted access.
2. Review case-insensitive duplicate emails and normalized duplicate personal keys with the account owners. Do not silently merge accounts or keys. Key migration refuses normalized collisions; the database email constraint rejects case collisions.
3. Apply `users.0005`, `users.0006` and `users.0007` together with this backend version. The key migration is not reversible to plaintext. Rollback requires restoring the protected snapshot and a compatible application; a reverse migration alone is insufficient.
4. Existing personal secrets remain usable. Existing accounts start with `email_verified=False` and can verify without losing family access. Old JWT sessions lacking the new password binding must sign in again. New registrations no longer create an unviewable automatic key; users create a personal key explicitly.
5. Configure the sender using the mail settings in `backend/.env.example`. Demonstrate delivery, retry behavior, expired/reused codes and password reset with the signed Android app and the real provider. Local tests use an isolated file mailbox or in-memory mailbox; they do not prove production SMTP delivery.
6. Assign an operator for deletion requests, publish reviewed retention/shared-history rules and implement/test the final data-disposition process. Review account data, profile associations, owned families, uploads, logs and backups. Prevent operator account removal from cascading through a shared family: ownership must be resolved first. The current request queue is only the foundation.
7. Schedule expired email-action and JWT blacklist cleanup under the reviewed retention policy. Use protected persistent mail/backup/media configuration and secure production settings; the PC test configuration is intentionally development-only.

## Validation evidence

- Backend: **92 tests passed on PostgreSQL**, including transaction behavior, verification/recovery, credential invalidation, deletion request safety and version 4/5 backup compatibility. The isolated SQLite run also passed 92 tests, with its PostgreSQL-only check skipped. Evidence: `.dev-logs/account-postgres-tests.log` and `.dev-logs/account-backend-tests.log`.
- Mobile: **67 tests passed**; the focused account suite also passed after checking corrected-password payloads. English/French, double text size, rejected input, one-time secrets, mounted API routes, credential-cache metadata and account switching are covered. Evidence: `flutter_frontend/build/account-flutter-tests.log` and `account-focused-tests.log`.
- Android analysis: **no issues**. Evidence: `flutter_frontend/build/account-analysis.log`.
- Migrations: no missing model migrations; Django system checks pass. These checks do not replace rehearsal against an actual production snapshot.
- Virtual phone: **all five journeys passed together on Android 15/API 35**. The account journey creates a key, checks that provider state is masked, edits account details, rejects and corrects a password, requests/cancels deletion, changes the password, rejects the old sign-in and accepts the new one. The four existing family/branding/language journeys also pass. Evidence: `.dev-logs/account-native.log`.
- The native run exposed an incorrect account/recovery URL; the missing separator was repaired and covered by a direct API regression test. Retrying an input in the native harness requires tapping/refocusing the field before replacing its value; the test now does this and asserts input retention before submission.
- The Android account screen was visually inspected using `flutter_frontend/build/pc-test-results/mobile-account-deletion-pending.png`. The normal interactive audit APK was separately rebuilt, installed and opened after the successful run. Foreground activity and version 1.0.0+1 were confirmed, and `account-installed-welcome.png` was captured and visually inspected.

Test records are isolated; no production migration, deployment or real-family invitation is part of this pass. Local mailbox tests prove code generation/validation, not delivery through a production mail provider. Native gallery selection, real-phone/TalkBack testing, release signing and performance certification remain separate release work.

## Remaining release work

The production plan remains the authoritative checklist. A1 still needs real mail delivery and signed-app recovery evidence. A2 still needs policy-reviewed deletion completion and operational handling. A3 has implementation and migration regression coverage; its production snapshot rehearsal remains required. A4/A5, family workflow finishing, physical-device/accessibility/performance checks, signing/staging/store preparation and the family pilot are not closed by this account pass.

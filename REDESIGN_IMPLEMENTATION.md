# Kkevo Family interface redesign

Implemented locally on 4 October 2026. The product remains a private family history app: recorded people and relationships, family invitations and owner review, and optional ancestry discovery. The user’s subsequent branding request replaces the original crest with their Akan Eban reference and an indigo/ivory mark. See MOBILE_BRAND_LANGUAGE_REVIEW.md for the latest Android branding, language and workflow changes. The app name is Kkevo Family across the Android launcher, Flutter app and web metadata; iOS display metadata is updated but iOS has not been built here.

## Product experience

- A welcoming account entry with separate account creation, password sign-in, personal-key sign-in and a clearly labelled example family.
- Five main destinations: Home, Tree, People, Links and You. Android uses Material navigation and Back behavior; larger windows use a navigation rail.
- A new home screen with family counts, an Eban-based connected-family illustration, a compact summary and a suggested next step and progress calculated from actual records. No fabricated streaks, scores or family facts.
- A three-step relationship flow: choose the relationship, identify the people, then review the direction and details before saving. Adding a relative can create a new profile or reuse an existing one. Adoption, step-parentage, optional co-parent and deceased relatives are supported explicitly.
- Person profiles group parents, children, current partners, siblings and former partners, with portrait management, family navigation, facts and a dedicated story editor.
- Member and relationship lists support search and filters. A parentage explorer shows the recorded connection and its path between two selected people, preserving adoption and step-family labels.
- The existing tree layout, pan, zoom, focus and filters remain available, with new cards and typed relationship labels. Mixed parental links use a neutral label.
- Rounded surfaces, readable Inter type, an indigo palette with sky-blue/coral/amber accents, tactile buttons and native transitions replace the previous ornamental interface. The Eban mark appears in the interface and adaptive/themed Android launcher icons. English is the initial language, with French and phone-language options. Saved dark-mode preferences are respected.

## Data and workflow contracts

The redesign reuses the existing API and privacy model. Invitations still require owner approval before access. Viewing accounts cannot edit. Switching account or family invalidates open forms. Failed saves retain draft information and do not celebrate success. Revision and retry protections remain in place.

The relative endpoint now accepts an optional `relationship_type` of `PARENT`, `ADOPTED` or `STEP` for parental roles. The selected type applies to the explicitly chosen co-parent as stated in the review. The person and links are saved in one transaction. Unsupported types/roles return validation errors. Existing clients that omit the type retain parental-link behavior. A missing generation value gets a layout default relative to the source; this does not infer ancestry or prove identity. No database migration is required.

Home progress tracks five independent facts: a person exists, a family link exists, a two-link ancestry path exists, a biography exists, and an accepted family member exists. Profile count is separate from account membership count. It is a guide to using the app, not a claim that a family history is complete.

## Verification

- 79 backend tests passed against a separate PostgreSQL test database, including typed parentage, profile reuse, atomic co-parent links, invalid payloads, rights, joining, ancestry matching, revisions and account isolation.
- 49 Flutter tests passed, including small-phone and desktop screens with double text size, keyboard/button semantics, real-data progress, guided adoption, deceased-relative dates, Android Back behavior and failed-save drafts.
- Flutter code analysis passed with no issues. Migration checks report no model changes.
- All four native Android journeys passed on the dedicated Android 15 virtual phone. The new journey uses the actual family creation, person creation, adoption wizard, Android Back, story editor, relationship selection and navigation screens. The existing journeys cover registration, token renewal, portraits, transfer, account isolation, invitations, owner review, viewing rights and ancestry matching. The fourth journey verifies English/French/phone-language choice and both language entry points. Evidence: `.dev-logs/mobile-brand-language-native-final.log`.
- Native screenshots were inspected for the welcome, home, profile, review, relationship path and tree. The normal interactive APK is installed and running; it uses isolated test data.

## Release boundaries

This is a local implementation and test build, not a published release. The local deployment check still reports development settings: DEBUG, development secret, HTTPS/HSTS and secure-cookie configuration. Production needs an actual deployment configuration, signed release build, backup/restore and monitoring checks. A physical Android check should cover the gallery picker, TalkBack, keyboard and performance. iOS and store submission are not verified by this PC emulator.

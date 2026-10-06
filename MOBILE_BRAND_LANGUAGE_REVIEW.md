# Kkevo Family: Android branding, language and workflow

Updated 5 October 2026; implementation started 4 October. This work targets the Android app and its running PC virtual phone. No website deployment or production records were used.

The subsequent repair-only phase is documented in `MOBILE_STABILIZATION_REVIEW.md`, with current verification and release boundaries. The results below describe the branding/language phase.

## Identity and colour

The user-supplied Akan Eban reference is recreated as a vector: four gridded panels, a central cross and four enclosing loops. The symbol's shape is preserved; the previous royal crest is replaced. The University of Michigan describes [Eban as a symbol of love, safety and security](https://lsa.umich.edu/daas/engagement/adinkra_symbols.html).

The app uses indigo as its primary colour, ivory in the logo, coral for memories and invitations, sky blue for connections and amber for highlights. Dark mode uses a matching dark indigo palette. Family profile initials retain distinct colours independent of gender.

- The source mark is `flutter_frontend/assets/kkevo_eban.svg` and `EbanPainter` in `lib/widgets/kkevo_brand.dart`.
- `tool/render_brand.dart` deterministically renders the PNG logo and older Android launcher icons from the vector painter. It is an explicit asset-generation command, separate from the application test suite.
- Android adaptive icons and Android 13 monochrome/themed icons use the same vector geometry. The launcher name remains Kkevo Family.

## Language behaviour

- English is the initial language.
- The welcome screen and account/settings screens provide English, Français and Use phone language.
- Phone language follows supported English/French locales; unsupported languages fall back to English.
- The preference persists locally. Android 13 and later also register it with the native App languages setting. Older Android versions retain the in-app setting.
- Flutter's Material, Cupertino and Widgets delegates localize native-style controls, including date pickers.
- Shared presentation resources cover navigation, forms, validation, status labels, relationship previews and errors. Names, biographies, notes, customary titles and other family records remain verbatim.
- Switching language preserves an open form's draft and does not change family records or permissions.

## Mobile workflow

Home shows a compact family summary and one suggested next step based on actual records. The full family journey remains available in any order. A grandparent suggestion opens a parent profile when one exists. Viewing-only members cannot use contribution or invitation actions. The five bottom tabs are Home, Tree, People, Links and You; shorter labels fit the phone navigation bar.

Relative creation retains the existing three steps: choose the relationship, create or select a profile, and review the exact direction before confirming. Android Back returns to the previous step with the draft intact. Connections and people are saved together through the existing transaction.

Existing native capabilities remain in use: Android photo picker through image_picker, secure credential storage, system keyboard/autofill, haptic feedback, system text scaling, reduced animations and Android predictive Back. Added platform code is limited to Android's per-app language API; no unrelated plugin was installed.

## Verification

49 app tests pass, including language persistence, Android-setting synchronization, unsupported-phone-language fallback, preserving names in translated relationship sentences, and changing language while keeping an open form and localized validation. Existing account isolation, permissions, failed-save retention and large-text checks also pass.

The Android virtual phone runs four end-to-end journeys: accounts/portraits/import/export; invitations/privacy/viewing access; family creation/adoption/story persistence/relationship paths; and English/French/phone-default language switching from welcome and account screens. Screenshots are saved under `flutter_frontend/build/pc-test-results/`. The English welcome image is captured directly from the final installed interactive app with Android screencap; the French/home/profile/relationship images come from the native journeys. The final English welcome screenshot was visually checked with native system bars, and Android reports the app locale as `en`.

The installed interactive APK is `flutter_frontend/build/pc-test-results/app-pc-audit-debug.apk`. It uses the isolated local testing API and test records. This is not a signed production release or evidence of physical-phone/iOS certification. Production hosting, secrets, release signing, backup restoration and physical-device accessibility/gallery checks remain as described in the existing release review.

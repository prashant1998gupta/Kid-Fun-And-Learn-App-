# 13 — Deployment, Play Store & App Store Checklists

## Firebase setup
1. Create Firebase project; add Android + iOS (+ Web) apps.
2. `dart pub global activate flutterfire_cli` → `flutterfire configure`.
3. Place `google-services.json` in `android/app/` and
   `GoogleService-Info.plist` in `ios/Runner/` (both git-ignored).
4. Enable Auth providers: Google, Apple, Phone, Email/Password.
5. Deploy rules: `firebase deploy --only firestore:rules,storage:rules`
   (files in `firebase/`).
6. Enable App Check; set Remote Config defaults (reward tables, flags).
7. Verify a production build with
   `--dart-define=APP_ENV=production --dart-define=REQUIRE_FIREBASE=true`.
   This fails closed if the native configuration is absent.

## Build
```bash
flutter build appbundle --release        # Android → Play
flutter build ipa --release              # iOS → App Store
flutter build web --release              # teacher/admin web (P3)
```
Set version in `pubspec.yaml`. Configure signing (Android upload keystore, iOS
distribution certificate/provisioning). Android release builds intentionally
fail if `android/key.properties` is absent; they never fall back to debug keys.

Create the Android upload key once and store it outside the repository:

```bash
keytool -genkeypair -v -keystore upload-keystore.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias upload
```

Then create git-ignored `android/key.properties`:

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=upload-keystore.jks
```

CI tag builds use `.github/workflows/android-release.yml`, obfuscate Dart code,
retain split debug symbols, require Firebase, and require protected production
secrets. See `docs/PRODUCTION_READINESS.md` for exact secret names.

## Play Store checklist (Kids)
- [ ] **Designed for Families / Teacher Approved** program enrollment.
- [ ] Target audience = children; complete **Content rating** questionnaire.
- [ ] **Data safety** form: no data sale, COPPA-compliant, list collection.
- [ ] No ads to children (or use only families-certified ad SDKs — we ship none).
- [ ] Privacy policy URL (COPPA/GDPR-K compliant).
- [ ] Android developer identity verification complete where required.
- [ ] Feature graphic, 8 phone + tablet screenshots, short/full description.
- [ ] App bundle < size limits; 64-bit; latest target SDK.

## App Store checklist (Kids Category)
- [ ] **Kids Category** (age band 5 & under / 6–8 / 9–11) → **no third-party
      analytics/ads without consent**, parental gate required for external links
      & purchases (our `ParentGateScreen` covers this).
- [ ] App Privacy "nutrition label" filled; no tracking.
- [ ] Sign in with Apple present (required alongside other social logins).
- [ ] Screenshots for 6.7"/6.5"/iPad; app preview video optional.
- [ ] Privacy policy + support URL; age rating questionnaire.
- [ ] Microphone and speech-recognition purpose strings reviewed on device.

## Compliance summary
- **COPPA:** children have no independent accounts; all data under
  parent/`uid`; parent gate on sensitive areas; no behavioral ads; data
  minimization; verifiable parental consent at account creation.
- **GDPR-K:** lawful basis via parental consent; parent cloud-account deletion
  triggers recursive backend cleanup; choose the Firestore region and DPA
  before collecting production data.
- **Safety:** no open chat, no UGC to public, friends parent-approved only.

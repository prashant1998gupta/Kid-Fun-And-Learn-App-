# 13 — Deployment, Play Store & App Store Checklists

## Firebase setup
1. Create Firebase project; add Android + iOS (+ Web) apps.
2. `dart pub global activate flutterfire_cli` → `flutterfire configure`
   (generates git-ignored `lib/firebase_options.dart`).
3. Place `google-services.json` / `GoogleService-Info.plist` (git-ignored).
4. Enable Auth providers: Google, Apple, Phone, Email/Password.
5. Deploy rules: `firebase deploy --only firestore:rules,storage:rules`
   (files in `firebase/`).
6. Enable App Check; set Remote Config defaults (reward tables, flags).
7. Uncomment `Firebase.initializeApp` in `main.dart`.

## Build
```bash
flutter build appbundle --release        # Android → Play
flutter build ipa --release              # iOS → App Store
flutter build web --release              # teacher/admin web (P3)
```
Set version in `pubspec.yaml`. Configure signing (Android keystore, iOS
provisioning). Enable code shrinking/obfuscation: `--obfuscate --split-debug-info`.

## Play Store checklist (Kids)
- [ ] **Designed for Families / Teacher Approved** program enrollment.
- [ ] Target audience = children; complete **Content rating** questionnaire.
- [ ] **Data safety** form: no data sale, COPPA-compliant, list collection.
- [ ] No ads to children (or use only families-certified ad SDKs — we ship none).
- [ ] Privacy policy URL (COPPA/GDPR-K compliant).
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

## Compliance summary
- **COPPA:** children have no independent accounts; all data under
  parent/`uid`; parent gate on sensitive areas; no behavioral ads; data
  minimization; verifiable parental consent at account creation.
- **GDPR-K:** lawful basis via parental consent; data export/delete (admin
  tooling P3); EU data region for Firestore; DPA in place.
- **Safety:** no open chat, no UGC to public, friends parent-approved only.

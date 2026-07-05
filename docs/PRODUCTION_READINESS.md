# Production Readiness

Last audited: 2026-07-05.

This document separates what the repository enforces from release work that
requires the product owner, store accounts, credentials, or legal decisions.
“Production ready” is not treated as permission to fabricate those inputs.

## Enforced in the repository

- Flutter analysis runs with fatal infos; unit/widget tests and release web plus
  Android debug smoke builds run in CI.
- App dependencies and Cloud Functions dependencies have committed lockfiles.
- Android release builds fail closed without a real upload keystore. R8 and
  resource shrinking are enabled.
- The production Android workflow requires signed secrets, Firebase config,
  obfuscation, split debug symbols, and `REQUIRE_FIREBASE=true`.
- Startup has framework/platform/zone error boundaries. Optional audio or cloud
  failures degrade safely; production-required Firebase fails bootstrap.
- Analytics collection is disabled by default. Notification permission is never
  requested during child-facing startup and requires a parent opt-in.
- Android cleartext traffic and OS backup are disabled. iOS microphone and
  speech-recognition purpose strings are present.
- Corrupt profile/drawing caches cannot block startup. Invalid deep links have
  a safe recovery screen.
- Firestore classroom access is restricted to the owning teacher/admin.
  Storage uploads are owner-only, image-only, and size-capped.
- Parent account deletion triggers recursive cloud cleanup. Local child-profile
  deletion is propagated during the next sync.
- Leaderboard group codes and public fields are bounded and sanitized.
- Cloud Functions use Node.js 22, locked dependencies, syntax/audit CI, and
  BulkWriter for boards beyond Firestore batch limits.

## Required GitHub production secrets

Configure these in the protected `production` environment:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_STORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `GOOGLE_SERVICES_JSON_BASE64`

Protect release tags, require CI approval, restrict environment reviewers, and
retain the upload key and symbol artifacts in a separate secure backup.

## External blockers before store submission

- [ ] Confirm the final legal operator name, privacy contact, support email,
      privacy-policy URL, support URL, and data-retention schedule.
- [ ] Complete a child-privacy legal review for target countries (including
      parental consent, cloud sync, leaderboards, notifications, and deletion).
- [ ] Create production Firebase apps/configs; select the data region; deploy
      rules/functions; enable only required Auth providers; enable and enforce
      App Check after validating real-device traffic.
- [ ] Decide whether to add consent-aware crash reporting. The current boundary
      avoids leaking child data but has no external crash backend.
- [ ] Configure Android Play App Signing, verified developer identity, package
      ownership, Designed for Families declarations, Data safety, age/content
      rating, screenshots, and staged rollout.
- [ ] Configure Apple team, bundle ownership, Sign in with Apple and push
      capabilities, distribution provisioning, Kids Category answers, privacy
      nutrition labels, screenshots, and phased release.
- [ ] Test microphone, speech recognition, TTS, notifications, tilt controls,
      offline/online transitions, account deletion, and restore on physical
      low-end Android phones/tablets and supported iPhone/iPad models.
- [ ] Run accessibility review with VoiceOver/TalkBack, large text, reduced
      motion, color-blind mode, switch control, and one-hand reachability.
- [ ] Execute Firebase emulator rule tests and a production-project smoke test
      before enabling real parent accounts.
- [ ] Track Flutter's announced Built-in Kotlin and Swift Package Manager
      migrations for `flutter_tts`, `speech_to_text`, and
      `sign_in_with_apple`. Current Android/iOS builds pass through the supported
      Gradle/CocoaPods paths, but Flutter reports these future compatibility
      warnings from upstream plugins.

## Release commands

```bash
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test

# Local unsigned smoke coverage
flutter build web --release
flutter build apk --debug

# Signed store build (requires android/key.properties + Firebase config)
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/symbols/android \
  --dart-define=APP_ENV=production \
  --dart-define=REQUIRE_FIREBASE=true

# iOS compile verification; App Store archive still needs Apple signing
flutter build ios --release --no-codesign
```

## Dependency audit notes

Flutter dependencies are intentionally not bulk-upgraded across breaking majors
during release hardening. Those migrations need isolated QA. Cloud Functions
uses current compatible Firebase Functions/Admin majors. `npm audit` currently
reports moderate transitive `uuid` advisories inside Google Cloud dependencies;
the high/critical CI gate passes, and the remaining fix depends on upstream
peer compatibility.

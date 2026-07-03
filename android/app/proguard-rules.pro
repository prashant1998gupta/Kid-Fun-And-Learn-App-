# KidVerse R8/ProGuard keep rules for release builds.
# Most plugins ship their own consumer rules; these are extra safety nets for
# the reflection-heavy bits (Firebase, Play Core deferred components, TTS/STT).

# Flutter engine + embedding.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Play Core (used by Flutter's deferred-components / split install stubs).
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Firebase / Google services (reflection on model classes).
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Keep annotations and generic signatures (Firestore (de)serialization).
-keepattributes Signature, *Annotation*, EnclosingMethod, InnerClasses

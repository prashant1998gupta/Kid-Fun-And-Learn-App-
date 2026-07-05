import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing is read from android/key.properties (git-ignored). Release
// builds fail closed when signing material is absent: a debug-signed artifact
// must never be mistaken for something safe to upload to Play Console.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val requiredSigningKeys = listOf("keyAlias", "keyPassword", "storeFile", "storePassword")
val missingSigningKeys = requiredSigningKeys.filter {
    keystoreProperties.getProperty(it).isNullOrBlank()
}
if (hasReleaseKeystore && missingSigningKeys.isNotEmpty()) {
    throw GradleException(
        "android/key.properties is missing: ${missingSigningKeys.joinToString()}",
    )
}
val requestedReleaseTask = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
if (requestedReleaseTask && !hasReleaseKeystore) {
    throw GradleException(
        "Release signing is not configured. Create android/key.properties " +
            "and an upload keystore; see docs/13_deployment.md.",
    )
}
val releaseStoreFile = if (hasReleaseKeystore) {
    file(keystoreProperties.getProperty("storeFile"))
} else {
    null
}
if (requestedReleaseTask && releaseStoreFile?.exists() != true) {
    throw GradleException("The configured Android release keystore does not exist.")
}

android {
    namespace = "com.kidverse.kidverse"
    // Current Flutter plugins (including speech_to_text) compile against API 36.
    compileSdk = 36
    // Pin to the highest NDK required by native plugins such as speech_to_text
    // and jni. Older NDK pins can fail release symbol stripping.
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.kidverse.kidverse"
        // Firebase Auth/Firestore require a minimum of API 23.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = releaseStoreFile
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Firebase remains optional for offline/debug builds. When a real native
// config is present, apply the plugin that generates Android resources.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Keep the public Android client config in the repository root so all apps can
// share it. Never point this at firebase-service-account.json: that file is a
// private Admin SDK credential and must remain on the backend.
val rootGoogleServices = rootProject.file("../../google-services.json")
val appGoogleServices = file("google-services.json")
val syncRootGoogleServices = tasks.register<Copy>("syncRootGoogleServices") {
    from(rootGoogleServices)
    into(layout.projectDirectory)
    onlyIf { rootGoogleServices.isFile }
}

if (rootGoogleServices.isFile || appGoogleServices.isFile) {
    apply(plugin = "com.google.gms.google-services")
    tasks.configureEach {
        if (name.startsWith("process") && name.endsWith("GoogleServices")) {
            dependsOn(syncRootGoogleServices)
        }
    }
}

android {
    namespace = "com.joerakesh.loyolaerp"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.joerakesh.loyolaerp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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

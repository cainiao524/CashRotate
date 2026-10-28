plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// App name and application ID live in lib/brand.dart so they can be renamed in one place.
val brandSource = file("../../lib/brand.dart").readText()

fun brandConstant(name: String): String =
    Regex("""static const $name = '([^']+)';""").find(brandSource)?.groupValues?.get(1)
        ?: error("lib/brand.dart is missing `static const $name = '...';`")

android {
    // Kotlin package; stays fixed even if the application ID changes.
    namespace = "app.cashrotate"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = brandConstant("applicationId")
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appName"] = brandConstant("appName")
    }

    buildTypes {
        release {
            // TODO(M7): release signing config. Debug keys keep `flutter run --release` working until then.
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

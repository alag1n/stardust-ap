plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

import java.util.Properties

val localProperties = Properties().apply {
    val propsFile = rootProject.file("local.properties")
    if (propsFile.exists()) {
        propsFile.inputStream().use { load(it) }
    }
}

fun localProp(key: String): String = localProperties.getProperty(key) ?: ""

android {
    namespace = "com.stardust.stardust"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.stardust.stardust"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Yandex Cloud Configuration
        buildConfigField("String", "YC_ACCESS_KEY", "\"${localProp("YC_ACCESS_KEY")}\"")
        buildConfigField("String", "YC_SECRET_KEY", "\"${localProp("YC_SECRET_KEY")}\"")
        buildConfigField("String", "YC_BUCKET", "\"${localProp("YC_BUCKET")}\"")
        buildConfigField("String", "YC_ENDPOINT", "\"${localProp("YC_ENDPOINT")}\"")
        buildConfigField("String", "YC_REGION", "\"${localProp("YC_REGION")}\"")
        buildConfigField("String", "YC_FUNCTION_URL", "\"${localProp("YC_FUNCTION_URL")}\"")
        buildConfigField("String", "YC_FUNCTION_TOKEN", "\"${localProp("YC_FUNCTION_TOKEN")}\"")
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

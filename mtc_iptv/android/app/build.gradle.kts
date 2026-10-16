import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// مفتاح التوقيع الرسمي (نفس مفتاح تطبيق React Native، §24.6): من android/key.properties المحلي
// (مستثنى من git) الذي يشير إلى app-keystore/mtc-release.keystore. بدونه يُبنى بمفتاح debug للتطوير فقط،
// وscripts/release.ps1 يرفض نشر أي APK لا تطابق بصمته البصمة الرسمية.
val keyProps = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

android {
    namespace = "com.mtciptv.mtc_iptv"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        // معاينة (قبل R2): معرّف منفصل حتى لا تحلّ محلّ تطبيق React Native الحالي (com.mtciptv).
        // يتحوّل إلى com.mtciptv بمفتاح التوقيع الحالي عند الترحيل في R2 (ADR-16).
        applicationId = "com.mtciptv.preview"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        // §24.6: يجب أن يكون أعلى من آخر إصدار React Native (versionCode 21) حتى تتم الترقية فوقه.
        // 30000 + رقم البناء؛ وFlutter يضيف 1000 × رمز المعمارية عند تقسيم الـ APK.
        versionCode = 30000 + flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keyProps.getProperty("storeFile") != null) {
            create("release") {
                storeFile = file(keyProps.getProperty("storeFile"))
                storePassword = keyProps.getProperty("storePassword")
                keyAlias = keyProps.getProperty("keyAlias")
                keyPassword = keyProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
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

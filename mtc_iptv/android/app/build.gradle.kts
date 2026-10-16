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

// معاينة (قبل R2): معرّف منفصل حتى لا تحلّ محلّ تطبيق React Native الحالي (com.mtciptv).
// يتحوّل إلى com.mtciptv بمفتاح التوقيع الحالي عند الترحيل في R2 (ADR-16).
val appId = "com.mtciptv.preview"

// Firebase (إشعارات Push، §14): نقرأ google-services.json بأنفسنا ونولّد الموارد التي يقرؤها Firebase عند
// التشغيل (google_app_id …) بدل إضافة com.google.gms.google-services (توافقها مع AGP 9 غير مضمون).
// الملف خارج المستودع (key.properties ← googleServices). يُفعَّل فقط إن كان فيه عميل بنفس المعرّف،
// فنسخ المعاينة (com.mtciptv.preview) تُبنى بلا Push، ونسخة com.mtciptv معه.
val firebaseRes: Map<String, String>? = run {
    val path = keyProps.getProperty("googleServices") ?: return@run null
    val f = file(path)
    if (!f.exists()) return@run null
    @Suppress("UNCHECKED_CAST")
    val root = groovy.json.JsonSlurper().parse(f) as Map<String, Any?>
    val project = root["project_info"] as Map<String, Any?>
    val clients = root["client"] as List<Map<String, Any?>>
    val client = clients.firstOrNull {
        val info = (it["client_info"] as Map<String, Any?>)["android_client_info"] as Map<String, Any?>
        info["package_name"] == appId
    } ?: return@run null
    val apiKey = (client["api_key"] as List<Map<String, Any?>>).first()["current_key"] as String
    mapOf(
        "google_app_id" to ((client["client_info"] as Map<String, Any?>)["mobilesdk_app_id"] as String),
        "gcm_defaultSenderId" to (project["project_number"] as String),
        "google_api_key" to apiKey,
        "google_crash_reporting_api_key" to apiKey,
        "project_id" to (project["project_id"] as String),
    )
}

android {
    namespace = "com.mtciptv.mtc_iptv"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // AGP 9 يعطّل resValue افتراضيًا؛ نحتاجه لموارد Firebase أعلاه
    buildFeatures {
        resValues = true
    }

    defaultConfig {
        applicationId = appId
        firebaseRes?.forEach { (k, v) -> resValue("string", k, v) }
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

dependencies {
    // FCM مباشرة من الكود الأصلي (MtcMessagingService) — بلا إضافة Flutter، فلا يمسّ نسخة Windows
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    implementation("com.google.firebase:firebase-messaging")
    implementation("androidx.core:core-ktx:1.13.1")
}

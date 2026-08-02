import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// 🔥 İMZA BİLGİLERİNİ OKUMA BÖLÜMÜ 🔥
// android/key.properties dosyasını buluyoruz
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Dahili test AAB'lerinde -PfastInternal=true ile R8 bekleme süresini atla.
// Normal release derlemeleri küçültme ve gizlemeyi kullanmaya devam eder.
val fastInternalBuild = providers.gradleProperty("fastInternal").orNull == "true"

android {
    namespace = "com.mercansoftware.pomodoro_elite"
    compileSdk = 36
    ndkVersion = "27.0.12077973"  // google_mobile_ads için gerekli

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        applicationId = "com.mercansoftware.pomodoro_elite"
        minSdk = 24
        targetSdk = 36 // Google Play Android 16 (API 36) zorunluluğu için güncellendi
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    // 🔥 İMZA AYARLARI (Release için) 🔥
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("release")
        }
        release {
            // 🔥 BURASI ARTIK 'release' İMZASI KULLANACAK (Debug değil!)
            signingConfig = signingConfigs.getByName("release")

            // Kod küçültme ve gizleme (Opsiyonel ama önerilir)
            isMinifyEnabled = !fastInternalBuild
            isShrinkResources = !fastInternalBuild
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("androidx.multidex:multidex:2.0.1")
    // Keep this aligned with the BillingClient version used by RevenueCat.
    // It is queried read-only as a fallback when RevenueCat and Play ownership
    // temporarily disagree after a refund/restore operation.
    implementation("com.android.billingclient:billing:8.3.0")
}

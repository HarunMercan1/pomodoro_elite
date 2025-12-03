plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.mercansoftware.pomodoro_elite"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8

        // Desugaring AÇIK
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        applicationId = "com.mercansoftware.pomodoro_elite"

        // 🔥 KRİTİK AYAR BURASI 🔥
        // Varsayılan yerine 21'e zorluyoruz.
        minSdk = 21

        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Büyük kütüphaneler için gerekli
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Desugaring Kütüphanesi
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    // Multidex Kütüphanesi (Garanti olsun diye)
    implementation("androidx.multidex:multidex:2.0.1")
}
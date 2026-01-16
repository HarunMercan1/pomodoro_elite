# AdMob için ProGuard kuralları
# google_mobile_ads paketi için gerekli

-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-keep class io.flutter.plugins.googlemobileads.** { *; }

# R8/ProGuard uyarılarını bastır (Genelde güvenlidir)
-dontwarn com.google.android.gms.**
-dontwarn com.google.ads.**
-dontwarn io.flutter.plugins.googlemobileads.**
-dontwarn com.google.android.play.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Flutter için
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Serialization için
-keepattributes Signature
-keepattributes *Annotation*

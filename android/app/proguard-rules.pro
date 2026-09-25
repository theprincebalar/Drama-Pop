# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google & Firebase Services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# RevenueCat In-App Purchases
-keep class com.revenuecat.purchases.** { *; }
-dontwarn com.revenuecat.purchases.**

# Facebook / Meta App Events SDK
-keep class com.facebook.** { *; }
-keepattributes *Annotation*
-dontwarn com.facebook.**

# Google Play In-App Review & Core
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# ExoPlayer / Video Player
-keep class com.google.android.exoplayer2.** { *; }
-keep class androidx.media3.** { *; }
-dontwarn com.google.android.exoplayer2.**
-dontwarn androidx.media3.**

# Gson & Model Serialization
-keepattributes Signature
-keepattributes *Annotation*
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# AndroidX & Security
-dontwarn androidx.**
-keep class androidx.preference.** { *; }
-keep class androidx.security.** { *; }

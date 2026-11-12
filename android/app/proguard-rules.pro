# Flutter Proguard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# MultiCounter Native Code, Widgets & Providers
-keep class com.multicounter.multicounter.** { *; }
-keepclassmembers class com.multicounter.multicounter.** { *; }

# SQLite & Drift
-keep class org.sqlite.** { *; }
-keep class androidx.sqlite.** { *; }

# Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep model classes with serialization
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# AndroidX Core
-dontwarn androidx.core.**
-dontwarn com.google.android.material.**

# Play Core (Deferred components in Flutter)
-dontwarn com.google.android.play.core.**


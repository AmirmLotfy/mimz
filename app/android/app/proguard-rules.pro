# ─── Flutter Wrapper ───────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# ─── Firebase / Google Play Services ───────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ─── Google Sign-In ────────────────────────────────────────
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.auth.api.signin.internal.** { *; }
-keep class com.google.android.gms.common.api.** { *; }

# GoRouter and Riverpod protection
-keep class com.google.android.gms.auth.api.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.firebase.** { *; }
-keep class io.flutter.plugins.firebase.** { *; }

# Keep GoRouter reflection-based lookups
-keep class com.go_router.** { *; }
-keep class io.flutter.embedding.android.** { *; }


# ─── Kotlin / Coroutines ───────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.coroutines.**
-keep class kotlin.Metadata { *; }
-keepattributes RuntimeVisibleAnnotations

# ─── Record Plugin ─────────────────────────────────────────
-keep class com.llfbandit.record.** { *; }
-dontwarn com.llfbandit.record.**

# ─── Just Audio ────────────────────────────────────────────
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.ryanheise.audio_session.** { *; }
-dontwarn com.ryanheise.**

# ─── Camera / CameraX ──────────────────────────────────────
-keep class io.flutter.plugins.camera.** { *; }
-keep class androidx.camera.** { *; }
-dontwarn io.flutter.plugins.camera.**
-dontwarn androidx.camera.**

# ─── Permission Handler ────────────────────────────────────
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# ─── Geolocator ────────────────────────────────────────────
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

# ─── Image Picker ──────────────────────────────────────────
-keep class io.flutter.plugins.imagepicker.** { *; }
-dontwarn io.flutter.plugins.imagepicker.**

# ─── URL Launcher ───────────────────────────────────────────
-keep class io.flutter.plugins.urllauncher.** { *; }
-dontwarn io.flutter.plugins.urllauncher.**

# ─── Google Maps ───────────────────────────────────────────
-keep class com.google.maps.flutter.** { *; }
-dontwarn com.google.maps.flutter.**

# ─── Local Auth / Biometrics ───────────────────────────────
-keep class io.flutter.plugins.localauth.** { *; }
-dontwarn io.flutter.plugins.localauth.**

# ─── Flutter Secure Storage ────────────────────────────────
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**

# ─── OkHttp (used by Dio) ──────────────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**

# ─── Dart Code Mapping Rules ───────────────────────────────
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes RuntimeVisibleAnnotations
-keepattributes LineNumberTable,SourceFile

# ─── Riverpod / Freezed / Serializable ────────────────────
-keep class * implements java.io.Serializable { *; }
-keep @interface com.google.gson.annotations.SerializedName
-keepnames class * { @com.google.gson.annotations.SerializedName <fields>; }
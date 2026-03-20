# Android Release Build Audit - Mimz

## Build Configuration Summary
- **Namespace**: `com.mimz.mimz_app`
- **Application ID**: `com.mimz.mimz_app`
- **Min SDK**: Flutter default (`flutter.minSdkVersion`)
- **Target SDK**: Flutter default (`flutter.targetSdkVersion`)
- **Release APK Build**: SUCCESS (`build/app/outputs/flutter-apk/app-release.apk`, 63.4MB)

## Release Hardening Changes Applied
1. **Signing secrets removed from source**
   - `app/android/app/build.gradle.kts` now loads release signing values from `app/android/key.properties`.
   - If no valid release keystore config exists, build falls back to debug signing for local validation.
2. **Google Maps key externalized**
   - `AndroidManifest.xml` now uses `${googleMapsApiKey}` placeholder.
   - `build.gradle.kts` injects placeholder from `MAPS_API_KEY` (Gradle property or env).
3. **Manifest cleanup**
   - Removed deprecated `USE_FINGERPRINT` permission.
4. **Shrinker hardening**
   - Added URL launcher keep/dontwarn rules in `app/android/app/proguard-rules.pro`.

## Manifest and Permission Audit
- **Internet**: `INTERNET`, `ACCESS_NETWORK_STATE` present
- **Location**: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION` present
- **Audio/Camera**: `RECORD_AUDIO`, `CAMERA` present
- **Biometrics**: `USE_BIOMETRIC` present
- **Security**: `android:networkSecurityConfig="@xml/network_security_config"` present

## Signing Mode Notes
- **Production signing path**: requires `app/android/key.properties` with release keystore references.
- **Local release validation path**: can build with debug signing when production keystore is unavailable.
- This keeps release compilation/test loops functional without committing sensitive signing material.

## Remaining Android Build Risks
- If `MAPS_API_KEY` is not provided at runtime/build-time, Google Maps may not load tiles.
- Production Google Sign-In still depends on Firebase SHA entries matching the final production keystore.
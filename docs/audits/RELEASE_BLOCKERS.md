# Release Blockers - Mimz

## 1. Physical Device Runtime Validation
- **Status**: BLOCKING FOR FULL RELEASE CERTIFICATION
- **Details**: ADB reported no connected devices during this hardening run, so release install/runtime smoke checks could not be executed end-to-end.
- **Resolution Step**:
  1. Connect Android device with USB debugging enabled.
  2. Run `adb devices` and ensure `device` is listed.
  3. Run `bash scripts/release_smoketest.sh`.

## 2. Firebase Console SHA Registration Verification
- **Status**: BLOCKING FOR PRODUCTION GOOGLE SIGN-IN CONFIDENCE
- **Details**: Production keystore exists and fingerprints are extracted, but release Google sign-in still depends on those SHA values being registered in Firebase Console for `com.mimz.mimz_app`.
- **Resolution Step**:
  1. Use `bash scripts/print_android_fingerprints.sh`.
  2. Confirm the reported SHA-1/SHA-256 are present in Firebase Android app settings.
  3. Re-test Google sign-in on release APK.

## 3. Maps API Key Provisioning
- **Status**: BLOCKING FOR GUARANTEED MAP RUNTIME
- **Details**: Manifest key is now externalized via placeholder `${googleMapsApiKey}`. If `MAPS_API_KEY` is not provided during build/runtime setup, map tiles may fail.
- **Resolution Step**:
  - Set `MAPS_API_KEY` as Gradle property or environment variable before building release APK.

## 4. Secure Gemini Live Token Architecture
- **Status**: NON-BLOCKING FOR DEMO, BLOCKING FOR STRICT PRODUCTION SECURITY
- **Details**: Current live flow still returns backend-held Gemini API key as the live token payload. This is functionally compatible but not ideal security posture for production.
- **Resolution Step**:
  - Implement true short-lived scoped token exchange for client live sessions.


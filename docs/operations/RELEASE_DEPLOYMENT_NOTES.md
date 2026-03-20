# Mimz Release Deployment Notes

## Build Artifact
- **APK Path**: `app/build/app/outputs/flutter-apk/app-release.apk`
- **Build Date**: 2026-03-16
- **Version**: 1.0.0+1
- **File Size**: 63.4 MB

## Android Firebase Configuration (CRITICAL)
If you want Google auth to work for any user installing the APK directly, Firebase must contain SHA fingerprints for the **actual signing key used to produce that APK**.

### Current Fingerprints (verify before production)
- Extracted from `app/android/app/mimz-release.keystore`:
  - **SHA-1**: `EF:49:30:A1:6B:F8:E6:40:83:23:FC:36:07:65:41:C1:92:8E:0C:D3`
  - **SHA-256**: `1D:92:50:F4:94:82:A6:78:49:49:68:02:B7:F5:A3:70:7E:E5:5F:EB:D5:D4:66:BF:27:44:AA:7E:FC:38:33:98`
- Re-check at any time with:
  ```bash
  bash scripts/print_android_fingerprints.sh
  ```
- Ensure these exact SHA values are registered in Firebase Console for release Google sign-in.

## Signing Assumptions
- `app/android/app/build.gradle.kts` now loads release signing from `app/android/key.properties`.
- If `key.properties` is missing/incomplete, release build falls back to debug signing for local validation.
- Do not commit keystore files or plaintext signing passwords.

### Example `app/android/key.properties` (local only)
```properties
storeFile=app/mimz-release.keystore
storePassword=<store-password>
keyAlias=<key-alias>
keyPassword=<key-password>
```

---

## Maps and Env Requirements
- Set `MAPS_API_KEY` in local Gradle/property environment before building for map runtime.
- Release backend default in app: `https://mimz-backend-1012962167727.europe-west1.run.app`.
- Backend deploy script default region updated to `europe-west1`.

## Deployment Commands
```bash
# Verify config
bash scripts/check_release_config.sh

# Rebuild if needed
bash scripts/build_release_apk.sh

# Install and Test
bash scripts/release_smoketest.sh
```

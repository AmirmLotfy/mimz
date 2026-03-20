# Android Release Checklist

## Build/Signing

- [ ] `key.properties` present with release keystore values
- [ ] release signing config does not fall back to debug for shipping builds
- [ ] `applicationId` and `namespace` aligned (`com.mimz.mimz_mobile`)
- [ ] versionCode/versionName incremented

## Manifest/Permissions

- [ ] only required permissions remain
- [ ] background location justified or removed
- [ ] network security config validated for release
- [ ] biometric permission aligned with actual feature usage

## Firebase/Google

- [ ] `google-services.json` contains release package and SHA cert config
- [ ] Google Sign-In OAuth clients validated for release certificate
- [ ] backend URL and Firebase project IDs aligned with production

## Runtime Safety

- [ ] no localhost/dev endpoint usage in release
- [ ] no mock/demo paths reachable in release
- [ ] auth/bootstrap/district failure states are recoverable

## Commands

```bash
cd app
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release
flutter build appbundle --release
```

## Device Validation

- [ ] install release APK on physical device
- [ ] sign in with Google and email/password
- [ ] profile + district + live + squad/event critical path works

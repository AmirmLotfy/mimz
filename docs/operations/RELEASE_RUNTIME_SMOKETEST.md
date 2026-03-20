# Mimz Release Runtime Smoke Test

## Automated Validation Attempt (Current Run)
- `adb start-server` executed successfully.
- `adb devices` returned **no connected devices/emulators**.
- `adb install -r build/app/outputs/flutter-apk/app-release.apk` could not execute due to missing device.

## Result
- **Build-time release validation**: PASS
- **Install/runtime validation**: BLOCKED (no ADB target connected during run)

## Prerequisites
1. `adb version`
2. `adb devices` must show at least one `device`
3. Release APK exists at `app/build/app/outputs/flutter-apk/app-release.apk`

## Automated Launch Command
```bash
bash scripts/release_smoketest.sh
```

## Manual Runtime Checklist
| Feature | Expected Behavior | Status |
| :--- | :--- | :--- |
| App launches from launcher icon | No startup crash | [ ] |
| Splash / welcome/auth loads | Smooth transition | [ ] |
| Email sign-in works | Signs in and loads profile/bootstrap | [ ] |
| Google sign-in path | Opens Google flow, handles error gracefully | [ ] |
| Permissions onboarding | Denied/permanent-denied states are clear | [ ] |
| World/map screen | Map loads (valid API key present) | [ ] |
| Backend health/connectivity | No stale offline state when backend reachable | [ ] |
| Live quiz entry | Session starts or clear actionable error | [ ] |
| Vision quest entry | Camera flow works or clear actionable error | [ ] |
| Profile/settings | Opens and allows normal actions | [ ] |
| Sign out | Clears session and returns to auth | [ ] |

## Log Capture
```bash
adb logcat *:E com.mimz.mimz_app:V
```

To see bootstrap/profile load failures after Google sign-in (tag `flutter` or search for `[Mimz]`):
```bash
adb logcat | grep -E "\[Mimz\]|flutter"
```

If app PID is known:
```bash
adb shell pidof -s com.mimz.mimz_app
adb logcat --pid=<PID> -v brief
```

## Troubleshooting: "Could not load your profile" after Google sign-in
- **Cause**: Google sign-in succeeds, but `POST /auth/bootstrap` fails (backend unreachable, 401, or 5xx).
- **Capture real error**: Reproduce the flow, then run `adb logcat -d | grep -E "\[Mimz\]|flutter"` or run a **debug build** (`flutter run`) and watch the console for `[Mimz] bootstrap failed: ...`.
- **Common fixes**: Ensure device has internet; confirm backend URL (release uses `BACKEND_URL` default Cloud Run URL); ensure backend Firebase project matches the app; if 401, check backend env and token verification.

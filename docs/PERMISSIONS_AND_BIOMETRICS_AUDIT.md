# Permissions & Biometrics Audit — Mimz App

## Permissions Flow
The onboarding asks for 3 core permissions: Location, Mic, and Camera. 
Location is via `LocationPermissionScreen`, Mic via `MicrophonePermissionScreen`, Camera via `CameraPermissionScreen`. 

### Current Gaps:
- The persistent `PermissionState` logic (often tied to `_kOnboardingKey`) might not actually check native OS granting. Need to ensure that if a user revokes via settings, the app gracefully degrades or re-requests. 
- Denied permanently fallback logic (e.g., launching iOS settings) needs hardening.

## Biometrics Flow
The `services/biometric_service.dart` exists and uses `local_auth`. 

### Current Gaps:
- It is NOT hooked into `Routing` or the App Lifecycle Observer. A user can enable it, but if they leave the app and return, they are not actually locked out. 
- Need a `LifecycleObserver` at the root App widget that triggers `BiometricService.authenticate()` on `AppLifecycleState.resumed` if `.shouldGateOnResume()` is true.
- `SecurityScreen` configures it, but it needs real-world testing.
- Fails open on errors right now. Ensure users aren't locked out, but are presented with proper PIN fallback.

## Action Plan
1. Add `WidgetsBindingObserver` to `main.dart` or `app.dart` to gate resume events with biometrics.
2. Harden OS permission checking ensuring native requests align with persistent state.

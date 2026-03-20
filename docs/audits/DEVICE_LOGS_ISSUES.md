# Device build, install & log summary

**Date:** 2025-03-17  
**Device:** R58M436LAHA (SM_A205F)  
**App:** com.mimz.mimz_app (Mimz)  
**Last log check:** Same day (app running on mobile)

---

## Build & install

- **Build:** `flutter build apk --release` — **succeeded** (after one retry; first attempt failed with "No space left on device" during packageRelease).
- **APK:** `app/build/app/outputs/flutter-apk/app-release.apk` (≈63.4 MB).
- **Install:** `adb install -r app-release.apk` — **Success**.
- **Launch:** App started successfully (`am start -n com.mimz.mimz_app/.MainActivity`).

---

## Logs gathered

- **Full filtered log:** `app/device_logs_filtered.txt` (logcat filtered for flutter, mimz_app, Firebase, Auth, network, errors).
- **Capture:** `adb logcat -d` then grep; device was at 00:55–00:56 after install and first launch.

---

## Issues found in logs

### 1. **Firebase Auth network error (critical)**

```
E flutter : Unhandled Exception: [firebase_auth/network-request-failed] A network error (such as timeout, interrupted connection or unreachable host) has occurred.
#2  AuthService._cacheToken (package:mimz_app/services/auth_service.dart:292)
```

- **Cause:** `getIdToken()` (used when caching the auth token) fails with a network error on the device.
- **Impact:** Token caching can fail; backend requests that need the Firebase ID token may fail or behave inconsistently.
- **Next steps:** Ensure device has stable internet; consider handling this exception in `AuthService._cacheToken` (e.g. retry with backoff, or surface a “check your connection” message instead of unhandled exception).

### 2. **Firebase App Check not configured**

```
W LocalRequestInterceptor: Error getting App Check token; using placeholder token instead. Error: com.google.firebase.FirebaseException: No AppCheckProvider installed.
```

- **Cause:** No App Check provider is registered (e.g. DeviceCheck / Play Integrity / reCAPTCHA).
- **Impact:** Backend may reject or limit requests if it enforces App Check; placeholder token is not valid for enforcement.
- **Next steps:** If the backend uses App Check, add and register an App Check provider in the app and enable App Check in Firebase Console for the app.

### 3. **Activity lifecycle timeouts**

```
W ActivityTaskManager: Activity top resumed state loss timeout for ActivityRecord{... com.mimz.mimz_app/.MainActivity}
W ActivityTaskManager: Activity pause timeout for ActivityRecord{... com.mimz.mimz_app/.MainActivity}
```

- **Cause:** Activity took longer than the system’s timeout to reach resumed state (e.g. slow startup or work on main thread).
- **Impact:** Usually cosmetic; can contribute to the app feeling slow or “stuck” on first open.
- **Next steps:** Reduce work on main thread at startup; defer token/network calls or do them asynchronously so the first frame and “resumed” state complete quickly.

### 4. **SELinux denial (low priority)**

```
E audit: avc: denied { read } for pid=10221 comm="m.mimz.mimz_app" name="max_map_count" dev="proc" ...
```

- **Cause:** App (or a library) tried to read `/proc/.../max_map_count`; SELinux blocks this for untrusted_app.
- **Impact:** Typically harmless; may only affect a debug or profiling path.
- **Next steps:** No change unless you see crashes or misbehavior tied to this; optional: avoid reading that proc file in release builds.

### 5. **Backend bootstrap 400 — fix applied**

Logs (PID 5880, 11569):

```
I flutter : [Mimz] bootstrap failed: DioException [bad response]: ... status code of 400
I flutter : #1  ApiClient.bootstrap (package:mimz_app/services/api_client.dart:47)
I flutter : #2  CurrentUserNotifier.fetchUser (package:mimz_app/features/auth/providers/auth_provider.dart:102)
```

- **Cause:** Backend returned **400** on `POST /auth/bootstrap`. Common when the client sends `Content-Type: application/json` with no body and the server or proxy rejects it.
- **Fix applied:** App now sends an explicit JSON body `{}` on bootstrap: `_dio.post('/auth/bootstrap', data: <String, dynamic>{})`. Rebuild and test; if 400 persists, check backend/proxy logs for the exact rejection reason.
- **Why it leads to "Connection lost, retry session":** If bootstrap fails, user state is in error. When you start a live quiz, the app still requests an ephemeral token; the backend may reject the request (e.g. auth context wrong) or the session fails later. The live screen then shows **Connection Lost** + **Retry Session** (phase == failed).

### 6. **Camera / ImageReader (Vision Quest or camera screen)**

```
W ImageReader_JNI: Unable to acquire a buffer item, very likely client tried to acquire more than maxImages buffers
E BufferQueueProducer: ... BufferQueue has been abandoned
```

- **Cause:** Camera released or screen closed while frames were still being produced; client acquired more buffers than allowed or abandoned the queue.
- **Impact:** Possible brief glitches or warnings when leaving camera; usually non-fatal.
- **Next steps:** Ensure camera is stopped and ImageReader/listeners are released in the correct order when the screen is disposed.

### 7. **Build disk space**

- First Gradle run failed with: `java.io.FileNotFoundException: ... dex-renamer-state.txt (No space left on device)`.
- Retry succeeded. Worth freeing disk space on the build machine to avoid flaky builds.

---

## Live session

- No log lines in this capture showed **live session** flow (ephemeral token, WebSocket, BidiGenerateContent). So we don’t yet have device logs of “connecting/reconnecting” for the live screen.
- **Recommendation:** Reproduce the live session on device (open Play → start a live quiz), then run:
  ```bash
  adb logcat -c && adb logcat 2>&1 | tee app/device_logs_live.txt
  ```
  Stop after the issue appears and inspect `device_logs_live.txt` for token, WebSocket, and backend errors.

---

## Summary

| Item              | Status / Severity |
|-------------------|-------------------|
| Build             | OK (retry after no space) |
| Install           | OK |
| App launch        | OK |
| Firebase Auth     | **Error** — network failure in `_cacheToken` |
| App Check         | **Warning** — no provider, placeholder token |
| Activity timeouts | **Warning** — slow first resume |
| SELinux           | **Info** — denial, likely harmless |
| Live session logs | Not in this capture — start live quiz then run `adb logcat -c && adb logcat \| tee app/device_logs_live.txt` |
| Bootstrap 400     | Backend returned 400 on /auth/bootstrap in an earlier run — check request/validation |
| Camera buffers    | ImageReader/BufferQueue warnings when leaving camera — cleanup order on dispose |

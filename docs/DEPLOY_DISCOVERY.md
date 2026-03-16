# Deploy Discovery — Mimz

## Project
- **Firebase project ID**: `mimzapp`
- **GCP project number**: `1012962167727`
- **Region**: `europe-west1`

## Flutter App
- **Path**: `app/`
- **Android applicationId**: `com.mimz.mimz_app`
- **iOS bundle identifier**: `com.mimz.mimzApp`
- **Display name**: `Mimz`

## Firebase Apps
| Platform | App ID |
|---|---|
| Android | `1:1012962167727:android:dd7c267a1edf01c0e7bd5a` |
| iOS | `1:1012962167727:ios:45c7af776d18210ce7bd5a` |

- **google-services.json**: `app/android/app/google-services.json` ✅
- **GoogleService-Info.plist**: `app/ios/Runner/GoogleService-Info.plist` ✅
- **firebase_options.dart**: `app/lib/firebase_options.dart` ✅ (real keys)

## Firebase Config Files
- **firebase.json**: root-level (references `firestore.rules`, `storage.rules`)
- **firestore.rules**: root-level ✅
- **storage.rules**: root-level ✅
- **firestore.indexes.json**: not present (none needed currently)

## Auth Implementation
- **Email/password**: ✅ implemented
- **Google Sign-In**: ✅ implemented (androidClientId + iosClientId in firebase_options.dart)
- **Apple Sign-In**: ❌ not implemented
- **Anonymous/Guest**: ❌ explicitly blocked (per app auth rules)

## Backend
- **Path**: `backend/`
- **Runtime**: Node.js 20 (TypeScript, compiled to `dist/`)
- **Dockerfile**: 2-stage build, exposes port 8080
- **Cloud Run service**: `mimz-backend` (europe-west1)
- **Health endpoint**: `GET /readyz`

## Environment Variables Required
| Variable | Source | Notes |
|---|---|---|
| `NODE_ENV` | Cloud Run env | `production` |
| `GCP_PROJECT_ID` | Cloud Run env | `mimzapp` |
| `FIREBASE_PROJECT_ID` | Cloud Run env | `mimzapp` |
| `FIRESTORE_DATABASE` | Cloud Run env | `(default)` |
| `STORAGE_BUCKET` | Cloud Run env | `mimzapp.firebasestorage.app` |
| `GEMINI_API_KEY` | Secret Manager | `GEMINI_API_KEY:latest` |
| `GEMINI_MODEL` | Cloud Run env | `gemini-2.5-flash` |
| `GEMINI_LIVE_MODEL` | Cloud Run env | `gemini-2.5-flash-native-audio-preview-12-2025` |
| `GEMINI_UTILITY_MODEL` | Cloud Run env | `gemini-2.5-flash-lite` |

## No Web Hosting
The app is a Flutter mobile app only. No web companion target exists.
Firebase Hosting is not needed.

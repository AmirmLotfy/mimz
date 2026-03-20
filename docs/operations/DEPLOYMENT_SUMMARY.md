# Deployment Summary — Mimz

**Date**: 2026-03-15  
**Engineer**: Automated via Antigravity  

---

## Project
| Field | Value |
|---|---|
| Firebase/GCP Project ID | `mimzapp` |
| GCP Project Number | `1012962167727` |
| Region | `europe-west1` |

---

## Firebase Apps Created/Confirmed
| Platform | App ID | Package/Bundle |
|---|---|---|
| Android | `1:1012962167727:android:dd7c267a1edf01c0e7bd5a` | `com.mimz.mimz_app` |
| iOS | `1:1012962167727:ios:45c7af776d18210ce7bd5a` | `com.mimz.mimzApp` |

---

## Backend (Cloud Run)
| Field | Value |
|---|---|
| Service Name | `mimz-backend` |
| Region | `europe-west1` |
| URL | `https://mimz-backend-1012962167727.europe-west1.run.app` |
| Revision | `mimz-backend-00001-kts` |
| Traffic | 100% |
| Health | ✅ `/readyz` → `{"status":"ready"}` |
| Min Instances | 0 |
| Max Instances | 10 |
| Memory | 512Mi |
| CPU | 1 |

---

## APIs Enabled
- `firebase.googleapis.com`
- `firestore.googleapis.com`
- `run.googleapis.com`
- `artifactregistry.googleapis.com`
- `cloudbuild.googleapis.com`
- `secretmanager.googleapis.com`
- `generativelanguage.googleapis.com`
- `identitytoolkit.googleapis.com`
- `storage-component.googleapis.com`

---

## Firebase Products Deployed

### Firestore
- Database: `(default)` · region: `us-central` (Firebase default)
- Rules: ✅ Deployed from `firestore.rules`

### Storage
- Bucket: `mimzapp.firebasestorage.app`
- Rules: ✅ Deployed from `storage.rules`

### Authentication
- Email/Password: ⚠️ **Must be enabled manually in Firebase Console**
- Google Sign-In: ⚠️ **Must be enabled manually in Firebase Console**
- See: https://console.firebase.google.com/project/mimzapp/authentication/providers

---

## FlutterFire Configuration
- `firebase_options.dart`: ✅ Regenerated with real API keys
- Android API key: configured in `firebase_options.dart` (redacted in docs)
- iOS API key: configured in `firebase_options.dart` (redacted in docs)
- `google-services.json`: ✅ Downloaded to `app/android/app/`
- `GoogleService-Info.plist`: ✅ Downloaded to `app/ios/Runner/`

---

## Secrets / Env Vars

### Secret Manager
| Secret | Versions | Notes |
|---|---|---|
| `GEMINI_API_KEY` | v3 (latest) | `AIzaSyADYXSTLC9S...` |

### Cloud Run Env Vars (all set)
`NODE_ENV`, `GCP_PROJECT_ID`, `FIREBASE_PROJECT_ID`, `FIRESTORE_DATABASE`, `STORAGE_BUCKET`, `GEMINI_MODEL`, `GEMINI_LIVE_MODEL`, `GEMINI_UTILITY_MODEL`, `EPHEMERAL_TOKEN_TTL_MS`, `MAX_REWARD_PER_HOUR`, `MAX_SECTORS_PER_ROUND`, `MAX_STREAK_BONUS`, `LOG_LEVEL`, `RATE_LIMIT_MAX`

---

## Automation Scripts
| Script | Purpose |
|---|---|
| `scripts/deploy_backend.sh` | Full Cloud Run redeploy |
| `scripts/apply_firebase_rules.sh` | Firestore + Storage rules redeploy |
| `scripts/configure_flutterfire.sh` | Regenerate firebase_options.dart |
| `scripts/deploy_all.sh` | Run all 3 steps above |

---

## What Could Not Be Automated

| Item | Reason | Instructions |
|---|---|---|
| Enable Email/Password auth provider | Firebase Console only | https://console.firebase.google.com/project/mimzapp/authentication/providers → Enable |
| Enable Google Sign-In auth provider | Firebase Console only | Same page → Enable Google |
| Add Android SHA-1 fingerprint | Firebase Console only | Settings → Android app → Add fingerprint: `69:96:33:63:27:1D:EB:88:1C:1F:8D:5F:7C:8C:90:1E:DB:B5:C8:31` |
| iOS URL scheme for Google Sign-In | Xcode required | Runner → Info → URL Types → add `1012962167727-lorb8qhom0cvhe5nnj22ealeajf5uv5a` |
| Release keystore SHA-1 | Requires production keystore | Sign app and add SHA-1 to Firebase |

---

## Redeploy Commands

```bash
# Everything
./scripts/deploy_all.sh

# Backend only
./scripts/deploy_backend.sh

# Firebase rules only
./scripts/apply_firebase_rules.sh

# FlutterFire config only
./scripts/configure_flutterfire.sh
```

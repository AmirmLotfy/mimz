# Production Infrastructure Summary

**Project ID:** mimzapp  
**Last updated:** 2026-03-17

---

## 1. Project and regions

| Item | Value |
|------|--------|
| **GCP / Firebase project** | mimzapp |
| **Cloud Run region** | europe-west1 |
| **Firestore** | (default) database, same project |

---

## 2. Firebase apps

| Platform | App ID | Package / Bundle |
|----------|--------|-------------------|
| Android | 1:1012962167727:android:dd7c267a1edf01c0e7bd5a | com.mimz.mimz_app |
| iOS | 1:1012962167727:ios:45c7af776d18210ce7bd5a | com.mimz.mimzApp |

---

## 3. Backend (Cloud Run)

| Item | Value |
|------|--------|
| **Service name** | mimz-backend |
| **URL** | https://mimz-backend-1012962167727.europe-west1.run.app |
| **Health** | GET /health, GET /readyz (use /readyz for probes) |
| **Deploy** | `./scripts/deploy_backend.sh` |

---

## 4. Auth providers

- **Email/Password** — Enable in Firebase Console → Authentication → Sign-in method.
- **Google** — Enable in Firebase Console; ensure Android/iOS OAuth client IDs and SHA-1 (release) are set where required.

---

## 5. Firestore and Storage

| Service | Status |
|---------|--------|
| **Firestore** | Rules and indexes deployed from firestore.rules and firestore.indexes.json |
| **Storage** | Rules deployed from storage.rules; bucket mimzapp.firebasestorage.app |

---

## 6. Rules and indexes

- **Firestore rules:** Deployed. Paths: users, districts, squads; default deny.
- **Storage rules:** Deployed. Paths: users/{userId}, user-profile-images/{userId}, districts/{districtId}.
- **Firestore indexes:** firestore.indexes.json defines composite indexes for liveSessions, rewards, notifications. Deploy with `./scripts/deploy_rules_and_indexes.sh`.

---

## 7. AI / Live endpoints

- **POST /live/ephemeral-token** — Returns token, model, systemInstruction, tools. Requires auth.
- **POST /live/tool-execute** — Executes live session tools. Requires auth.
- **GET /live/config** — Public session config.
- **Secret:** GEMINI_API_KEY in Secret Manager; Generative Language API enabled for mimzapp.

---

## 8. Key env vars (Cloud Run)

- NODE_ENV=production  
- GCP_PROJECT_ID=mimzapp  
- FIREBASE_PROJECT_ID=mimzapp  
- FIRESTORE_DATABASE=(default)  
- STORAGE_BUCKET=mimzapp.firebasestorage.app  
- GEMINI_API_KEY (from Secret Manager)  
- GEMINI_MODEL, GEMINI_LIVE_MODEL, GEMINI_UTILITY_MODEL  
- EPHEMERAL_TOKEN_TTL_MS, MAX_REWARD_PER_HOUR, MAX_SECTORS_PER_ROUND, MAX_STREAK_BONUS  

---

## 9. Remaining manual steps

1. **Firebase Auth:** In Firebase Console, enable Email/Password and Google and configure OAuth client IDs / SHA-1 for release builds if not already done.
2. **GEMINI_API_KEY:** Create the secret in Secret Manager and add a version with a valid Gemini API key; ensure Generative Language API is enabled for mimzapp.
3. **Flutter app:** After first deploy, confirm BACKEND_URL in the app (dart-define or default in api_client.dart) matches the deployed Cloud Run URL above.

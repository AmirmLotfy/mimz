# Backend + Cloud Infrastructure Audit

**Project ID:** mimzapp  
**Audit date:** 2026-03-17  
**Scope:** Full infrastructure inventory for backend, Google Cloud, Firebase, and deployment.

---

## 1. Backend

### 1.1 Location and stack

| Item | Value |
|------|--------|
| **Path** | `backend/` |
| **Runtime** | Node 20 |
| **Framework** | Fastify |
| **Build** | TypeScript → `dist/` |
| **Entry** | `backend/src/server.ts` → `dist/server.js` |

### 1.2 Route coverage

| Prefix | File | Routes |
|--------|------|--------|
| (none) | health.ts | GET /health, GET /healthz, GET /readyz |
| /auth | auth.ts | POST /auth/bootstrap |
| /live | live.ts | POST /live/ephemeral-token, POST /live/tool-execute, POST /live/session-log, GET /live/config |
| /profile | profile.ts | GET /profile, PATCH /profile |
| /district | district.ts | GET /district, POST /district/expand, POST /district/resources, POST /district/preview-growth, POST /district/unlock-structure |
| /squad | squads.ts | POST /squad, POST /squad/join |
| /events | events.ts | GET /events |
| /leaderboard | leaderboard.ts | GET /leaderboard |
| /rewards | rewards.ts | GET /rewards |
| /notifications | notifications.ts | GET /notifications, PATCH /notifications/read-all |
| /feedback | feedback.ts | POST /feedback |
| /interests | interests.ts | GET /interests/taxonomy |
| (none) | questions.ts | GET /questions, POST /questions/validate |

**Health/readiness:** Use `/health` and `/readyz` for probes. Cloud Run reserves `/healthz`; app defines it but platform may intercept.

### 1.3 Auth and middleware

- **Auth:** `backend/src/middleware/auth.ts` — Bearer token from Firebase ID token; verifies via Firebase Admin Auth. Public routes: /health, /healthz, /readyz. In non-production, falls back to demo user.
- **CORS:** `origin: true`, methods GET/POST/PATCH/DELETE/OPTIONS.
- **Rate limit:** Configurable via RATE_LIMIT_MAX, RATE_LIMIT_WINDOW (default 100 per 1 minute).

### 1.4 Firebase Admin

- **Init:** `backend/src/lib/firebase.ts` — Uses `config.gcpProjectId`; Application Default Credentials on Cloud Run. Supports FIRESTORE_EMULATOR_HOST.
- **Exports:** getDb(), getFirebaseAuth(), initFirebase().

### 1.5 Config and env

- **Schema:** `backend/src/config/index.ts` — Zod-validated. Requires GCP_PROJECT_ID, GEMINI_API_KEY (min length 1). Production fails fast on invalid config.
- **Env loading:** No dotenv in code; relies on process.env (Cloud Run env vars / Secret Manager).

### 1.6 Live / AI

- **Ephemeral token:** `backend/src/modules/live/liveService.ts` — mintEphemeralToken() returns token (currently raw GEMINI_API_KEY), sessionId, model, expiresAt, systemInstruction, tools. **Gap:** `backend/src/routes/live.ts` does not return systemInstruction in HTTP response.
- **Tool execute:** `backend/src/modules/live/executeLiveTool.ts` — executeTool() with ToolContext; session validation via isSessionValid().
- **Model config:** `backend/src/config/models.ts` — LIVE_REALTIME, ASYNC_CHALLENGE, LOW_COST_UTILITY; env GEMINI_LIVE_MODEL, GEMINI_MODEL, GEMINI_UTILITY_MODEL.

### 1.7 Docker

- **Dockerfile:** `backend/Dockerfile` — Multi-stage: builder (npm ci, build), production (node:20-slim, dist), EXPOSE 8080, CMD node dist/server.js.

---

## 2. Flutter app

| Item | Value |
|------|--------|
| **Path** | `app/` |
| **Backend URL** | From dart-define BACKEND_URL or default `https://mimz-backend-1012962167727.europe-west1.run.app` (api_client.dart) |
| **Package (Android)** | com.mimz.mimz_app |
| **Bundle (iOS)** | com.mimz.mimzApp |

---

## 3. Firebase

### 3.1 Config files

| File | Purpose |
|------|--------|
| **firebase.json** | Root: firestore rules path, storage rules path; flutter.platforms android/ios/dart with projectId mimzapp, appIds, fileOutput paths |
| **app/lib/firebase_options.dart** | Generated; projectId mimzapp, storageBucket mimzapp.firebasestorage.app, Android/iOS app IDs and client IDs |
| **google-services.json** | Expected at android/app/google-services.json (per firebase.json); not found in repo (may be gitignored or generated) |
| **GoogleService-Info.plist** | Expected at ios/Runner/GoogleService-Info.plist; not found in repo (may be gitignored or generated) |

### 3.2 FlutterFire

- **Configure script:** `scripts/configure_flutterfire.sh` — Regenerates FlutterFire config for mimzapp; outputs to firebase_options.dart and platform files.

### 3.3 Rules and indexes

| Asset | Path | Status |
|-------|------|--------|
| Firestore rules | firestore.rules | Present; users/districts/squads rules |
| Storage rules | storage.rules | Present; users, user-profile-images, districts |
| Firestore indexes | firestore.indexes.json | **Not present** in repo |

---

## 4. Deployment

### 4.1 Scripts

| Script | Purpose |
|--------|--------|
| scripts/deploy_backend.sh | Cloud Run deploy from backend/ (--source); project mimzapp, region europe-west1; env vars + GEMINI_API_KEY secret |
| scripts/apply_firebase_rules.sh | firebase deploy --only firestore:rules,storage; optional firestore:indexes if file exists |
| scripts/deploy_all.sh | Runs apply_firebase_rules, deploy_backend, configure_flutterfire |
| scripts/configure_flutterfire.sh | FlutterFire CLI for mimzapp |
| scripts/deploy.sh | Alternative deploy script (project/region args); uses gemini-api-key secret name in docs |
| scripts/bootstrap_firebase.sh | gcloud set project, enable APIs for mimzapp |

### 4.2 Cloud Build

- **File:** cloudbuild.yaml — Builds backend Docker image, pushes to gcr.io/$PROJECT_ID/mimz-backend, deploys to Cloud Run.
- **Region in cloudbuild:** us-central1 (deploy_backend.sh uses europe-west1 — **inconsistency**).
- **Secret in cloudbuild:** gemini-api-key:latest (deploy_backend.sh uses GEMINI_API_KEY:latest — **inconsistency**).

### 4.3 Cloud Run (from deploy_backend.sh)

- **Service:** mimz-backend  
- **Region:** europe-west1  
- **Port:** 8080  
- **Auth:** --allow-unauthenticated  
- **Secrets:** GEMINI_API_KEY=GEMINI_API_KEY:latest  
- **Env:** NODE_ENV, GCP_PROJECT_ID, FIREBASE_PROJECT_ID, FIRESTORE_DATABASE, STORAGE_BUCKET, GEMINI_*, EPHEMERAL_TOKEN_TTL_MS, MAX_*, LOG_LEVEL, RATE_LIMIT_MAX

---

## 5. Required secrets and APIs

### 5.1 Secrets

| Secret | Used by | Notes |
|--------|--------|--------|
| GEMINI_API_KEY | Backend (live + any Gemini calls) | Must exist in Secret Manager; deploy_backend.sh uses GEMINI_API_KEY:latest |

### 5.2 APIs (to enable for mimzapp)

- run.googleapis.com (Cloud Run)
- firestore.googleapis.com
- cloudbuild.googleapis.com (if using Cloud Build)
- artifactregistry.googleapis.com or container registry
- secretmanager.googleapis.com
- generativelanguage.googleapis.com (Gemini / Live)

---

## 6. Auth providers (Firebase)

- **Expected by app:** Email/Password, Google Sign-In (firebase_options has android/ios client IDs).
- **Backend:** Verifies Firebase ID token via Firebase Admin Auth.

---

## 7. Service accounts

- Cloud Run uses a default compute service account; must have Secret Manager Secret Accessor for GEMINI_API_KEY and Firestore/Storage as needed (default project permissions often suffice for same-project Firestore).

---

## 8. MCP / CLI

- No MCP deployment helpers found in repo. Deployment is script-based (bash + gcloud + firebase).

---

## 9. Gaps and fixes (see below)

- **Addressed:** Live route returns systemInstruction.
- **Addressed:** cloudbuild.yaml uses europe-west1, GEMINI_API_KEY:latest, /readyz.
- **Remaining:** Firestore indexes Add firestore.indexes.json if any composite index is required by queries.
- Use /readyz in automation. Prefer /readyz in docs and automation (Cloud Run may reserve /healthz).
- Live handshake timeout “connecting forever”:** Add handshake timeout in Flutter live controller; ensure backend returns systemInstruction; validate GEMINI_API_KEY and Generative Language API for Live.

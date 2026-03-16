# Secrets and Environment Variables Audit

**Project ID:** mimzapp  
**Audit date:** 2026-03-17

---

## 1. Backend environment variables

### 1.1 Required (production)

| Variable | Purpose | Where set |
|----------|--------|-----------|
| NODE_ENV | production | deploy_backend.sh, Cloud Run |
| GCP_PROJECT_ID | Firebase/Cloud project | deploy_backend.sh (mimzapp) |
| FIREBASE_PROJECT_ID | Firebase project | deploy_backend.sh (mimzapp) |
| FIRESTORE_DATABASE | Firestore database ID | (default) |
| STORAGE_BUCKET | Firebase Storage bucket | mimzapp.firebasestorage.app |
| GEMINI_API_KEY | Gemini / Live API | Secret Manager (GEMINI_API_KEY:latest), not env literal |

### 1.2 Optional (with defaults)

| Variable | Default | Purpose |
|----------|---------|--------|
| PORT | 8080 | Server port |
| LOG_LEVEL | info | Pino log level |
| RATE_LIMIT_MAX | 100 | Rate limit count |
| RATE_LIMIT_WINDOW | 1 minute | Rate limit window |
| GEMINI_MODEL | gemini-2.5-flash | Async model |
| GEMINI_LIVE_MODEL | gemini-2.5-flash-native-audio-preview-12-2025 | Live model |
| GEMINI_UTILITY_MODEL | gemini-2.5-flash-lite | Utility model |
| EPHEMERAL_TOKEN_TTL_MS | 300000 | Live token TTL (5 min) |
| MAX_REWARD_PER_HOUR | 5000 | Abuse protection |
| MAX_SECTORS_PER_ROUND | 5 | Game balance |
| MAX_STREAK_BONUS | 10 | Game balance |

### 1.3 Local development

- **backend/.env.example** lists all variables; copy to .env and fill in.
- Do not commit .env. Backend does not use dotenv by default; use `node -r dotenv/config dist/server.js` or set env in the shell if loading from .env.

---

## 2. Secret Manager

| Secret | Used by | Cloud Run binding |
|--------|--------|--------------------|
| GEMINI_API_KEY | backend (live + Gemini) | --set-secrets=GEMINI_API_KEY=GEMINI_API_KEY:latest |

**Create/update:**
```bash
# Create (once)
echo -n "YOUR_KEY" | gcloud secrets create GEMINI_API_KEY --data-file=- --project=mimzapp

# New version
echo -n "YOUR_KEY" | gcloud secrets versions add GEMINI_API_KEY --data-file=- --project=mimzapp
```

---

## 3. Flutter app

| Item | How set |
|------|--------|
| **Backend base URL** | Compile-time: dart-define BACKEND_URL=... or default in api_client.dart (https://mimz-backend-1012962167727.europe-west1.run.app) |
| **Firebase** | firebase_options.dart (generated; projectId, apiKey, appId, storageBucket, client IDs). No secrets in repo. |

No runtime secrets in the app; Firebase uses config file and backend URL is build-time.

---

## 4. Duplicates and dead config

- **Resolved:** deploy_backend.sh and cloudbuild.yaml both use secret name GEMINI_API_KEY (cloudbuild was updated from gemini-api-key).
- **Backend:** Single config module (config/index.ts); no duplicate env parsing. Production fails fast on invalid/missing required config.

---

## 5. .env.example

Backend .env.example should list all variables used by config/index.ts. Update it when adding new env vars. Never put real keys in .env.example.

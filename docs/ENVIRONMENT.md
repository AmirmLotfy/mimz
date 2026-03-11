# Environment Variables — Mimz

All environment variables used by the backend and Flutter app.

---

## Backend (`backend/.env`)

Copy from `backend/.env.example`. Descriptions below.

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `GEMINI_API_KEY` | Google AI API key for Gemini Live | `AIza...` |
| `GCP_PROJECT_ID` | Google Cloud project ID | `mimz-prod` |

### Optional (with defaults)

| Variable | Default | Description |
|----------|---------|-------------|
| `NODE_ENV` | `development` | `development`, `production`, or `test` |
| `PORT` | `8080` | Server listen port |
| `LOG_LEVEL` | `info` | `fatal`, `error`, `warn`, `info`, `debug`, `trace` |
| `RATE_LIMIT_MAX` | `100` | Max requests per window per IP |
| `RATE_LIMIT_WINDOW` | `1 minute` | Rate limit window |
| `FIREBASE_PROJECT_ID` | (from GCP_PROJECT_ID) | Firebase project ID if different from GCP |
| `FIRESTORE_DATABASE` | `(default)` | Firestore database name |
| `STORAGE_BUCKET` | (none) | Cloud Storage bucket |
| `GEMINI_MODEL` | `gemini-2.0-flash-exp` | Gemini model for async tasks |
| `GEMINI_LIVE_MODEL` | `gemini-2.0-flash-live-001` | Gemini model for live sessions |
| `EPHEMERAL_TOKEN_TTL_MS` | `300000` | Ephemeral token lifetime (5 min) |
| `MAX_REWARD_PER_HOUR` | `5000` | Anti-abuse: max XP per hour per user |
| `MAX_SECTORS_PER_ROUND` | `3` | Anti-abuse: max territory per round |
| `MAX_STREAK_BONUS` | `10` | Anti-abuse: max streak multiplier |

### Local Development

| Variable | Description |
|----------|-------------|
| `FIRESTORE_EMULATOR_HOST` | Set to `localhost:8081` to use Firebase emulator |
| `FIREBASE_AUTH_EMULATOR_HOST` | Set to `localhost:9099` to use Auth emulator |

---

## Flutter App (dart-define)

Pass via `flutter run --dart-define=KEY=VALUE`.

| Variable | Default | Description |
|----------|---------|-------------|
| `BACKEND_URL` | `http://localhost:8080` | Backend API base URL |
| `USE_MOCK_LIVE` | `false` | Enable mock live adapter (no API key needed) |

---

## Production (Cloud Run)

On Cloud Run, set env vars via `--set-env-vars` or use Secret Manager:

```bash
# Env vars
gcloud run deploy mimz-backend \
  --set-env-vars="NODE_ENV=production,GCP_PROJECT_ID=mimz-prod,LOG_LEVEL=info"

# Secrets (recommended for API keys)
gcloud run services update mimz-backend \
  --set-secrets="GEMINI_API_KEY=gemini-api-key:latest"
```

# Post-Deploy Runbook

**Project:** mimz-490520

---

## 1. Redeploy backend

```bash
./scripts/deploy_backend.sh
```

Uses `backend/` as source; builds with Cloud Build and deploys to Cloud Run (europe-west1). Env vars are set by the script with `GEMINI_AUTH_MODE=vertex` by default.
Live websocket region is controlled separately by `GEMINI_LIVE_VERTEX_LOCATION` (default `us-central1`) to avoid model-region mismatch.

---

## 2. Reapply Firebase rules and indexes

```bash
./scripts/deploy_rules_and_indexes.sh
```

Deploys Firestore rules, Storage rules, and Firestore indexes (if firestore.indexes.json exists) to project mimz-490520. Safe to rerun.

---

## 3. Regenerate FlutterFire config

After adding or changing Firebase apps (e.g. new Android/iOS app):

```bash
./scripts/configure_flutterfire.sh
```

Or from the app directory:

```bash
cd app && dart run flutterfire configure --project=mimz-490520
```

Updates `lib/firebase_options.dart` and platform config file outputs.

---

## 4. Rotate secrets

**GEMINI_API_KEY (new version):**

```bash
echo -n "NEW_KEY_HERE" | gcloud secrets versions add GEMINI_API_KEY \
  --data-file=- \
  --project=mimz-490520
```

Then redeploy the backend so Cloud Run picks up the new version:

```bash
./scripts/deploy_backend.sh
```

---

## 5. Validate health after deploy

```bash
./scripts/validate_deployment.sh
```

Optional: pass the backend base URL if different from default:

```bash
./scripts/validate_deployment.sh https://mimz-backend-glaimgrznq-ew.a.run.app
```

Checks GET /health and GET /readyz; exits 0 if both return 200.

---

## 6. Full redeploy (all steps)

```bash
./scripts/deploy_all.sh
```

Runs in order: deploy_rules_and_indexes, deploy_backend, configure_flutterfire.

---

## 7. Troubleshooting

| Symptom | What to check |
|--------|----------------|
| Backend returns 503 or does not respond | Cloud Run revision may be starting; wait 15–30s and retry. Check Cloud Run logs: `gcloud logging read "resource.type=cloud_run_revision" --project=mimz-490520 --limit=50`. |
| /readyz returns 503 | Firestore may be unreachable (e.g. wrong project, permissions). Ensure GCP_PROJECT_ID and Firestore API are correct; check backend logs. |
| Live session "connecting" forever | Now capped by 18s handshake timeout. If it still fails: confirm Vertex AI API is enabled; verify `GEMINI_LIVE_VERTEX_LOCATION` + `GEMINI_LIVE_MODEL` pairing; check backend logs for ephemeral-token errors; if using api-key mode, confirm GEMINI_API_KEY secret exists. |
| Auth bootstrap fails ("Could not load your profile") | App cannot reach backend or backend returns 401/5xx. Check device network; confirm backend URL in app; check backend logs and Firebase Auth (token verification). |
| Firebase rules or indexes not updating | Run `./scripts/deploy_rules_and_indexes.sh` again. For indexes, check Firebase Console → Firestore → Indexes for build status. |

---

## 8. Reliability gate after deploy (mandatory)

1. Run backend health validation:
```bash
./scripts/validate_deployment.sh
```

2. Run app-side targeted regressions:
```bash
cd app && flutter test test/features/auth/ test/features/live/
```

3. Validate Cloud Run request quality for auth/live:
```bash
gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.service_name="mimz-backend" AND (jsonPayload.url="/auth/bootstrap" OR jsonPayload.url="/live/ephemeral-token")' \
  --project=mimz-490520 --limit=100 \
  --format='table(timestamp,jsonPayload.statusCode,jsonPayload.userId,jsonPayload.url,jsonPayload.traceId)'
```

Release should be blocked if:
- `/auth/bootstrap` shows repeated 401/400 bursts for active users.
- `/live/ephemeral-token` is mostly non-200 for authenticated sessions.
- Mobile smoke gets \"Connection Lost / Retry Session\" loops without explicit fatal reason.

---

## 9. One-time bootstrap (new project)

If setting up from scratch:

1. **Google Cloud:** `./scripts/bootstrap_cloud.sh mimz-490520` (enables required APIs including Vertex AI).
2. **(Optional api-key mode)** Create secret: `echo -n "YOUR_GEMINI_KEY" | gcloud secrets create GEMINI_API_KEY --data-file=- --project=mimz-490520`
3. **Firebase:** Ensure Firebase project `mimz-490520` is created and linked; enable Auth providers.
4. **Deploy:** `./scripts/deploy_all.sh`

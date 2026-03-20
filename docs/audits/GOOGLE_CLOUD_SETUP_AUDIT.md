# Google Cloud Setup Audit

**Project ID:** mimzapp  
**Audit date:** 2026-03-17

---

## 1. Project and region

| Item | Value |
|------|--------|
| **Project ID** | mimzapp |
| **Primary region** | europe-west1 (Cloud Run, recommended for latency and consistency) |
| **Note** | cloudbuild.yaml updated to use europe-west1; deploy_backend.sh uses europe-west1 |

---

## 2. Required APIs

Enable the following for project mimzapp:

| API | Purpose |
|-----|--------|
| run.googleapis.com | Cloud Run |
| firestore.googleapis.com | Firestore |
| cloudbuild.googleapis.com | Cloud Build (if using cloudbuild.yaml) |
| secretmanager.googleapis.com | Secret Manager (GEMINI_API_KEY) |
| generativelanguage.googleapis.com | Gemini / Generative Language (Live API) |

Optional for container image push: artifactregistry.googleapis.com or Container Registry (gcr.io).

**Commands (run once):**
```bash
gcloud config set project mimzapp
gcloud services enable run.googleapis.com firestore.googleapis.com secretmanager.googleapis.com generativelanguage.googleapis.com
# If using Cloud Build:
gcloud services enable cloudbuild.googleapis.com
```

---

## 3. Cloud Run

| Item | Value |
|------|--------|
| **Service name** | mimz-backend |
| **Region** | europe-west1 |
| **Port** | 8080 |
| **Auth** | Allow unauthenticated (public HTTP) |
| **Deploy** | scripts/deploy_backend.sh (--source backend/) |

**Secret:** GEMINI_API_KEY must exist in Secret Manager. Cloud Run service account needs Secret Manager Secret Accessor on that secret.

**Health:** Use GET /readyz for readiness (Cloud Run may reserve /healthz). GET /health is also available.

---

## 4. Secret Manager

| Secret name | Used by | Notes |
|-------------|--------|--------|
| GEMINI_API_KEY | Backend (live + Gemini) | Create and add a version with your Gemini API key |

**Create secret (once):**
```bash
echo -n "YOUR_GEMINI_API_KEY" | gcloud secrets create GEMINI_API_KEY --data-file=- --project=mimzapp
# Or add version to existing:
echo -n "YOUR_GEMINI_API_KEY" | gcloud secrets versions add GEMINI_API_KEY --data-file=- --project=mimzapp
```

---

## 5. IAM

- Default Cloud Run service account: `PROJECT_NUMBER-compute@developer.gserviceaccount.com` typically has roles that allow Firestore and Secret Manager in the same project. If not, grant:
  - roles/secretmanager.secretAccessor (for GEMINI_API_KEY)
  - Firestore/Storage access is usually via default project permissions

---

## 6. Backend URL

After deploy, the service URL is:

```
https://mimz-backend-<PROJECT_NUMBER>.europe-west1.run.app
```

Example (from app default): `https://mimz-backend-1012962167727.europe-west1.run.app`

Flutter app uses this via `BACKEND_URL` dart-define or the default in api_client.dart. Ensure the app’s base URL matches the deployed URL after first deploy.

---

## 7. Consistency and fixes applied

- **cloudbuild.yaml:** Region set to europe-west1; secret set to GEMINI_API_KEY:latest; health check uses /readyz.
- **deploy_backend.sh:** Already uses mimzapp, europe-west1, GEMINI_API_KEY:latest, and /readyz for verification.

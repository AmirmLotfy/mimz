# Production Infra Verification Report

**Date:** 2026-03-17  
**Project:** `mimzapp`  

## Validation executed

### 1) Backend health
- Ran: `./scripts/validate_deployment.sh`
- Result: `GET /health -> 200`, `GET /readyz -> 200`

### 2) Cloud Run runtime env
- Service: `mimz-backend` (region `europe-west1`)
- URL: `https://mimz-backend-qxpmikh5iq-ew.a.run.app`
- Revision: `mimz-backend-00007-4w8` serving 100% traffic
- Verified env vars: `NODE_ENV`, `GCP_PROJECT_ID`, `FIREBASE_PROJECT_ID`, `FIRESTORE_DATABASE`, `STORAGE_BUCKET`, Gemini model vars, token/abuse limits
- Verified secret binding: `GEMINI_API_KEY` from Secret Manager `latest`

### 3) Secret Manager
- Secret exists: `GEMINI_API_KEY`
- Versions present/enabled: 3, 2, 1

### 4) Gemini API enablement
- Enabled service confirmed: `generativelanguage.googleapis.com`

### 5) Firebase app registration
- `firebase apps:list --project mimzapp` returns Android and iOS registrations (Android appears duplicated in listing output).

## Findings
- Core production runtime dependencies for live sessions are present and healthy at infrastructure level.
- User-facing failures are not due to backend outage; they correlate with auth/bootstrap request failures (401/400), confirmed in Cloud Run request logs.
- Live transport hardening now requires independent validation of `GEMINI_LIVE_VERTEX_LOCATION` to ensure model compatibility.

## Operational recommendation
- Treat auth/bootstrap reliability as the highest-severity production blocker for live stability.
- Keep the newly added correlation-id pipeline enabled and use it to tie mobile failures to Cloud Run logs for each release smoke cycle.

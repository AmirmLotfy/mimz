# Deployment Validation Report

**Project ID:** mimzapp  
**Date:** 2026-03-17

---

## 1. What was tested

| Check | Method |
|-------|--------|
| Backend /health | GET https://mimz-backend-1012962167727.europe-west1.run.app/health |
| Backend /readyz | GET https://mimz-backend-1012962167727.europe-west1.run.app/readyz |
| Firebase Firestore rules | firebase deploy --only firestore:rules |
| Firebase Storage rules | firebase deploy --only storage |
| Firebase Firestore indexes | firebase deploy --only firestore:indexes (with firestore.indexes.json) |
| Cloud Run deploy | scripts/deploy_backend.sh |

---

## 2. What passed

- **Backend /health:** 200, `{"status":"ok","timestamp":"..."}`
- **Backend /readyz:** 200, `{"status":"ready","timestamp":"..."}`
- **Firebase rules:** Firestore and Storage rules deployed successfully to mimzapp.
- **Firebase indexes:** Index deployment invoked (indexes may build asynchronously in console).
- **Cloud Run:** Service mimz-backend deployed to europe-west1; revision serving 100% traffic; health check (readyz) passed after deploy.

---

## 3. What failed

- None in this run. All automated checks passed.

---

## 4. What was fixed during this pass

- Live ephemeral-token response now includes `systemInstruction`.
- Live session: 18s handshake timeout in Flutter app; prevents infinite "connecting."
- cloudbuild.yaml: region europe-west1, secret GEMINI_API_KEY:latest, health check /readyz.
- firestore.indexes.json added for liveSessions, rewards, notifications composite queries.
- backend/.env.example: project IDs and STORAGE_BUCKET set to mimzapp; MAX_SECTORS_PER_ROUND=5.

---

## 5. Manual verification recommended

- **Auth bootstrap:** From the Flutter app, sign in (Google or Email) and confirm profile loads (no "Could not load your profile").
- **Live session:** Start a live quiz; confirm either connection within ~18s or a clear timeout error (no infinite connecting).
- **Firebase Auth:** In Firebase Console, confirm Email/Password and Google providers are enabled and that Android/iOS apps are registered with correct package/bundle IDs and SHA-1 if required.
- **Secret GEMINI_API_KEY:** Confirm the secret exists in Secret Manager and has a valid Gemini API key; Live API requires Generative Language API enabled for the project.

---

## 6. Service URL

**Backend:** https://mimz-backend-1012962167727.europe-west1.run.app

The Flutter app default BACKEND_URL matches this. No change needed unless you deploy to a different URL.

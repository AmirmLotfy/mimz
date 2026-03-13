# Mimz Runbook

This document serves as the guide for team members performing operational actions on the Mimz deployed infrastructure.

## Application Architecture Checklist
- **Project Configuration:** All Flutter dependencies point to `mimzapp` Firebase setup.
- **Backend Access:** `mimz-backend` endpoints in Cloud Run.

## 1. How to deploy changes
If you update any logic in `backend/` or `app/`, follow these processes.

**To re-deploy the entire backend stack:**
```bash
./scripts/deploy_backend.sh
```

**To re-deploy security rules to Firebase:**
```bash
./scripts/deploy_firebase.sh
```

**To seamlessly kick off both deployments together:**
```bash
./scripts/deploy_all.sh
```

## 2. How to re-run FlutterFire configuration
If you change the Application Bundle ID, or attach a new web landing page target, configure the client flutter app again:
```bash
cd app
flutterfire configure --project=mimzapp
```
(Be careful to commit `lib/firebase_options.dart` post-generation)

## 3. How to Rotate Application Secrets
Cloud Run is attached to Secret Manager. To change the Gemini API Key or apply other sensitive configuration, apply the new value to Secret Manager:

```bash
echo -n "NEW_API_KEY" | gcloud secrets versions add GEMINI_API_KEY --data-file=-
```
New Revisions to Cloud Run automatically fetch `:latest`. No restart necessary unless changing environment variable static maps entirely. 

## 4. Validating Deployment Health
After applying an update to Cloud Run or Firebase, ping the base endpoint mapping to verify 200 responses. Check Cloud Logging interface connected to `mimz-backend`.

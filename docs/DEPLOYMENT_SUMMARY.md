# Mimz Deployment Summary

**Date**: 2026-03-14  
**Google Cloud Project**: `mimzapp`  
**Region**: `us-central1`

## Deployed Services

### 1. Backend API (Cloud Run)
- **Service Name**: `mimz-backend`
- **Live URL**: `https://mimz-backend-qxpmikh5iq-uc.a.run.app`
- **Environment Variables**: `NODE_ENV=production`, `GCP_PROJECT_ID=mimzapp`, `FIREBASE_PROJECT_ID=mimzapp`, `FIRESTORE_DATABASE=(default)`, `STORAGE_BUCKET=mimzapp.firebasestorage.app`.
- **Secrets Attached**: `GEMINI_API_KEY` (from Secret Manager).

### 2. Firebase
- **Apps Created**:
  - Android: `com.mimz.mimz_app`
  - iOS: `com.mimz.mimzApp`
- **Firestore**: Database `(default)` active. `firestore.rules` deployed.
- **Storage**: Default bucket `mimzapp.firebasestorage.app` active. `storage.rules` deployed.
- **Auth**: Enabled. Google, Apple, and Email/Password providers support aligned in code. Action required in console.

### 3. Enabled Google Cloud APIs
- `firebase.googleapis.com`
- `firestore.googleapis.com`
- `run.googleapis.com`
- `artifactregistry.googleapis.com`
- `cloudbuild.googleapis.com`
- `secretmanager.googleapis.com`
- `identitytoolkit.googleapis.com`
- `generativelanguage.googleapis.com`

---

## Remaining Manual Steps (Important)

Due to OAuth limitations blocking CLI/automation capabilities, you **MUST** complete these steps manually:
1. Turn on the **Email/Password** Auth provider in the Firebase Console.
2. Turn on the **Google Sign-In** Auth provider and retrieve the `Web Client ID`.
3. Link your Android SHA fingerprints to the `mimzapp` Firebase project under **Project Settings > General**.
4. Register the **Apple Sign-In** Service ID / Key in the Firebase Console if you plan to launch on the App Store.

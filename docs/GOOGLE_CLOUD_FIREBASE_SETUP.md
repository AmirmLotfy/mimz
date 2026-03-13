# Google Cloud & Firebase Setup Guide

## Automated Deployment Overview
This repository has been equipped with a fully automated, reproducible cloud provisioning pipeline located in the `scripts/` directory.

### Quick Start
To bootstrap a completely fresh project, run:
```bash
./scripts/deploy_all.sh
```

### Components Deployed
1. **Google Cloud APIs**: Enables `firebase.googleapis.com`, `firestore.googleapis.com`, `run.googleapis.com`, `artifactregistry.googleapis.com`, `cloudbuild.googleapis.com`, `secretmanager.googleapis.com`, `identitytoolkit.googleapis.com`, `generativelanguage.googleapis.com`.
2. **Firebase Rules**: Compiles and pushes `firestore.rules` and `storage.rules` directly to Firebase.
3. **FlutterFire**: Wires Android (`com.mimz.mimz_app`) and iOS (`com.mimz.mimzApp`) runtimes to the Firebase project.
4. **Cloud Run Backend**: Containerizes and hosts the Node/Fastify API, linking `GEMINI_API_KEY` securely from Secret Manager.

## Firebase Auth Requirements
Because of strict OAuth policies, the following providers cannot be configured exclusively via the CLI and require visiting the [Firebase Console](https://console.firebase.google.com/):
- **Email / Password** settings toggling.
- **Google Sign-In** requiring Android SHA-1 + SHA-256 fingerprint attachments.
- **Apple Sign-In** requiring Service ID and .p8 keys.

Please refer to `AUTH_DEPLOYMENT_NOTES.md` for proper configuration.

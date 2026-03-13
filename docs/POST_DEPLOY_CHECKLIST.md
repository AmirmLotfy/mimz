# Post-Deployment Validation Checklist

After running the deployment scripts for the Mimz project, follow this checklist to verify production health.

## 1. Cloud Run Backend
- [ ] Backend is actively running on Cloud Run (`mimz-backend`) in `us-central1`.
- [ ] Visit `https://[CLOUD_RUN_URL]/healthz` — should return `200 OK` with JSON `{"status": "ok"}`.
- [ ] All required environment variables are attached under **Revisions > Variables & Secrets** (including `GEMINI_API_KEY` bound from Secret Manager).

## 2. Firebase Console
- [ ] **Authentication**: Email/Password, Google, and Apple sign-in providers are enabled.
- [ ] **Authentication Settings**: "Link accounts that use the same email" is active.
- [ ] **Project Settings**: Android app `com.mimz.mimz_app` has the correct release/debug SHA-1 fingerprints registered.
- [ ] **Firestore**: Database exists and `firestore.rules` are actively visible in the Rules tab.
- [ ] **Storage**: Default bucket `mimzapp.firebasestorage.app` exists and `storage.rules` are visible.

## 3. Flutter Configuration
- [ ] `lib/firebase_options.dart` successfully generated and defines both `android` and `ios` platforms.
- [ ] Android bundle runs locally or passes CI without `google-services.json` missing project errors.
- [ ] iOS bundle compiles successfully without missing `GoogleService-Info.plist` errors.

## 4. Automation & Scripts
- [ ] All `.sh` scripts in `scripts/` have execute permissions.
- [ ] Executable `deploy_backend.sh` can be reliably rerun to push hotfixes.

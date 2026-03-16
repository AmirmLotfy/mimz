# Post-Deploy Checklist — Mimz

## Firebase
- [ ] `firebase_options.dart` has real API keys (not `YOUR_KEY_HERE`)
- [ ] `google-services.json` exists at `app/android/app/google-services.json`
- [ ] `GoogleService-Info.plist` exists at `app/ios/Runner/GoogleService-Info.plist`
- [ ] Firestore rules deployed (check Firebase console)
- [ ] Storage rules deployed (check Firebase console)
- [ ] Firebase Auth: Email/Password provider **enabled** in console
- [ ] Firebase Auth: Google provider **enabled** in console

## Android Google Sign-In
- [ ] SHA-1 fingerprint added to Firebase Android app in console:
  `69:96:33:63:27:1D:EB:88:1C:1F:8D:5F:7C:8C:90:1E:DB:B5:C8:31`
- [ ] For production: release keystore SHA-1 also added

## iOS Google Sign-In
- [ ] URL scheme added in Xcode → Runner → Info → URL Types:
  `1012962167727-lorb8qhom0cvhe5nnj22ealeajf5uv5a`

## Backend (Cloud Run)
- [ ] `mimz-backend` service is running in `europe-west1`
- [ ] `GET /readyz` returns 200
- [ ] `GEMINI_API_KEY` secret is version 3+ in Secret Manager
- [ ] Cloud Run service has Secret Manager accessor role

## Flutter App
- [ ] `BACKEND_URL` in `live_providers.dart` points to actual Cloud Run URL
  (currently `localhost` for dev — must update for production build)
- [ ] `USE_MOCK_LIVE=false` (default, confirms no mock in production)
- [ ] `flutter analyze lib/` → No issues

## Gemini API
- [ ] API key is active in Secret Manager (do not paste raw key in docs)
- [ ] Generative Language API enabled in GCP project `mimzapp`

## Final Smoke Test
- [ ] Open app on physical device
- [ ] Sign in with email/password
- [ ] Complete onboarding (voice session starts, Gemini responds by name)
- [ ] Start a quiz round (Gemini asks questions, waveform shows amplitude)
- [ ] Answer correctly (XP awarded, district grows)
- [ ] CLAIM REWARDS → world map shows fresh data

# Setup Guide — Mimz

Step-by-step instructions to run Mimz locally. Written for a new developer, not the original author.

---

## Prerequisites

| Tool | Version | Check |
|------|---------|-------|
| Flutter | 3.x+ | `flutter --version` |
| Dart | 3.x+ | Included with Flutter |
| Node.js | 20+ | `node --version` |
| npm | 10+ | `npm --version` |
| Git | Any | `git --version` |
| Google Cloud SDK | Latest | `gcloud --version` (optional, for deploy) |

---

## Order of Operations

```
1. Clone repo
2. Set up backend
3. Set up Flutter app
4. (Optional) Configure Firebase
5. (Optional) Configure Google Maps
6. Run
```

---

## 1. Clone the Repo

```bash
git clone https://github.com/YOUR_ORG/Mimz-Final.git
cd Mimz-Final
```

## 2. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Create environment file
cp .env.example .env
```

Edit `.env` — at minimum set:
```
GEMINI_API_KEY=your-gemini-api-key
GCP_PROJECT_ID=your-gcp-project-id
```

Start the server:
```bash
npm run dev
# Output: 🚀 Mimz backend v1.0.0 listening on port 8080 [development]
```

Verify:
```bash
curl http://localhost:8080/healthz
# {"status":"ok","timestamp":"..."}
```

## 3. Flutter App Setup

```bash
cd app

# Install dependencies
flutter pub get

# Run on connected device or simulator
flutter run
```

For development without a Gemini API key:
```bash
flutter run --dart-define=USE_MOCK_LIVE=true --dart-define=BACKEND_URL=http://localhost:8080
```

## 4. Firebase Setup (Optional for Demo)

The app works in demo mode without Firebase. For real authentication:

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure (from app/ directory)
cd app
flutterfire configure --project=your-firebase-project-id
```

This generates `firebase_options.dart` and configures platform files.

**Firebase Console setup needed**:
- Enable Authentication → Sign-in providers (Apple, Google, Email)
- Enable Firestore Database → Start in test mode
- Note the project ID for backend `.env`

## 5. Google Maps Setup (Optional)

For real map rendering instead of the stylized grid painter:

1. Enable Maps SDK for iOS/Android in Google Cloud Console
2. Create an API key restricted to Maps SDK
3. iOS: Add to `app/ios/Runner/AppDelegate.swift`
4. Android: Add to `app/android/app/src/main/AndroidManifest.xml`

## 6. Run Tests

```bash
# Backend tests
cd backend && npm test
# ✓ 33 tests passing

# Flutter tests (live stack)
cd app && flutter test test/live/
```

---

## What's Mandatory vs Optional

| Step | Required for Demo | Required for Production |
|------|:-:|:-:|
| Backend `.env` + `npm install` | ✅ | ✅ |
| `GEMINI_API_KEY` | ❌ (mock mode) | ✅ |
| Flutter `pub get` | ✅ | ✅ |
| Firebase configure | ❌ (demo auth) | ✅ |
| Google Maps API key | ❌ (grid painter) | ✅ |
| Cloud Run deploy | ❌ | ✅ |

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `npm install` permission error | `npm install --cache /tmp/npm-cache` |
| Flutter SDK not found | `export PATH="$PATH:$HOME/flutter/bin"` |
| Firebase not configured | Backend auto-falls back to demo mode |
| Port 8080 in use | `PORT=3000 npm run dev` |
| Backend can't connect to Firestore | Set `FIRESTORE_EMULATOR_HOST=localhost:8081` or ensure GCP project has Firestore enabled |

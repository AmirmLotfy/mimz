# Mimz Deployment Discovery

## 1. Application Architecture Paths
- **Flutter App**: `app/`
- **Backend API**: `backend/`

## 2. Flutter App Identifiers
- **Android `applicationId`**: `com.mimz.mimz_app`
- **iOS `PRODUCT_BUNDLE_IDENTIFIER`**: `com.mimz.mimzApp`
- **macOS/Web**: No clear macOS or web requirements extracted. Focusing on Mobile targets.

## 3. Firebase & Auth State
- **Firebase Libraries**: `firebase_core`, `firebase_auth` present.
- **`firebase_options.dart`**: Yes, already exists in `app/lib/firebase_options.dart` but will be overwritten by `flutterfire configure` to align with `mimzapp`.
- **Auth Providers**: Google Sign-In and Apple Sign-In libraries are *not* explicitly defined in `pubspec.yaml`, indicating it either uses Email/Password, Anonymous auth, or requires configuration.

## 4. Backend Deployment Config
- **Runtime**: Node.js 20 (TypeScript + Fastify)
- **Deployment Strategy**: Dockerfile exists at `backend/Dockerfile`. Ideal for Cloud Run deployment via Cloud Build.
- **Required Secrets / Environment Variables**:
  - `GCP_PROJECT_ID` (mimzapp)
  - `FIREBASE_PROJECT_ID` (mimzapp)
  - `NODE_ENV` (production)
  - `GEMINI_API_KEY` (Secret Manager)
  - `FIRESTORE_DATABASE`, `STORAGE_BUCKET`, `GEMINI_MODEL`, `GEMINI_LIVE_MODEL`, `GEMINI_UTILITY_MODEL` mapping to standards.

# Cloud Run Deployment

## Prerequisites

1. [Google Cloud SDK](https://cloud.google.com/sdk) installed
2. Firebase project with Auth + Firestore enabled
3. Gemini API key

## Step-by-Step

### 1. Set Up GCP

```bash
# Set project
gcloud config set project YOUR_PROJECT_ID

# Enable APIs
gcloud services enable run.googleapis.com
gcloud services enable firestore.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable artifactregistry.googleapis.com
```

### 2. Create Firestore Database

```bash
gcloud firestore databases create --location=us-central1
```

### 3. Build and Deploy

```bash
cd backend

# Build container
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/mimz-backend

# Deploy to Cloud Run
gcloud run deploy mimz-backend \
  --image gcr.io/YOUR_PROJECT_ID/mimz-backend \
  --region us-central1 \
  --platform managed \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 0 \
  --max-instances 10 \
  --set-env-vars="\
    NODE_ENV=production,\
    GCP_PROJECT_ID=YOUR_PROJECT_ID,\
    GEMINI_API_KEY=YOUR_GEMINI_KEY,\
    GEMINI_LIVE_MODEL=gemini-2.5-flash-native-audio-preview-12-2025,\
    LOG_LEVEL=info"
```

### 4. Verify

```bash
# Get URL
SERVICE_URL=$(gcloud run services describe mimz-backend --region us-central1 --format 'value(status.url)')

# Health check
curl $SERVICE_URL/healthz

# Readiness check
curl $SERVICE_URL/readyz
```

### 5. Configure Flutter App

Update your Flutter app's backend URL:
```bash
flutter run --dart-define=BACKEND_URL=$SERVICE_URL
```

## Firestore Indexes

Create these composite indexes for efficient queries:

```
# liveSessions — active rounds by user
Collection: liveSessions
Fields: userId ASC, status ASC, startedAt DESC

# rewards — recent rewards by user
Collection: rewards
Fields: userId ASC, grantedAt ASC

# squads — lookup by join code
Collection: squads
Fields: joinCode ASC

# districts — lookup by owner
Collection: districts
Fields: ownerId ASC
```

## Secret Management (Production)

For production, use Secret Manager instead of env vars:

```bash
# Create secret
echo -n "YOUR_GEMINI_KEY" | gcloud secrets create gemini-api-key --data-file=-

# Grant access
gcloud secrets add-iam-policy-binding gemini-api-key \
  --member="serviceAccount:YOUR_SERVICE_ACCOUNT" \
  --role="roles/secretmanager.secretAccessor"

# Mount in Cloud Run
gcloud run services update mimz-backend \
  --set-secrets="GEMINI_API_KEY=gemini-api-key:latest"
```

## Local Development

```bash
# Using Firebase emulators
export FIRESTORE_EMULATOR_HOST=localhost:8081
npm run dev
```

#!/bin/bash
set -e

echo "=== Deploying Backend to Cloud Run ==="

gcloud run deploy mimz-backend \
  --source backend/ \
  --region us-central1 \
  --project mimzapp \
  --allow-unauthenticated \
  --set-env-vars="NODE_ENV=production,GCP_PROJECT_ID=mimzapp,FIREBASE_PROJECT_ID=mimzapp,FIRESTORE_DATABASE=(default),STORAGE_BUCKET=mimzapp.firebasestorage.app" \
  --set-secrets="GEMINI_API_KEY=GEMINI_API_KEY:latest"

echo "Backend deployment successful."

#!/usr/bin/env bash
# bootstrap_cloud.sh — Set project mimzapp and enable required GCP APIs.
# Usage: ./scripts/bootstrap_cloud.sh
# Safe to rerun. Does not create secrets (create GEMINI_API_KEY manually).

set -euo pipefail

PROJECT_ID="mimzapp"

echo "☁️  Bootstrap Google Cloud — project $PROJECT_ID"
echo ""

gcloud config set project "$PROJECT_ID"

echo "Enabling APIs..."
gcloud services enable \
  run.googleapis.com \
  firestore.googleapis.com \
  secretmanager.googleapis.com \
  generativelanguage.googleapis.com \
  firebase.googleapis.com \
  firebasestorage.googleapis.com \
  --project="$PROJECT_ID"

# Optional: Cloud Build and Artifact Registry if using cloudbuild.yaml or image builds
echo "Enabling optional APIs (Cloud Build, Artifact Registry)..."
gcloud services enable \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  --project="$PROJECT_ID" 2>/dev/null || true

echo ""
echo "✅ Bootstrap complete."
echo "   Create secret: echo -n 'YOUR_KEY' | gcloud secrets create GEMINI_API_KEY --data-file=- --project=$PROJECT_ID"

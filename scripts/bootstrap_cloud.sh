#!/usr/bin/env bash
# bootstrap_cloud.sh — Enable required GCP + Firebase APIs for a project.
# Usage:
#   ./scripts/bootstrap_cloud.sh                # uses current gcloud project
#   ./scripts/bootstrap_cloud.sh my-project-id  # explicit project
# Safe to rerun. Does not create secrets (create GEMINI_API_KEY manually).

set -euo pipefail

PROJECT_ID="${1:-$(gcloud config get-value project 2>/dev/null)}"

if [[ -z "${PROJECT_ID}" || "${PROJECT_ID}" == "(unset)" ]]; then
  echo "ERROR: No GCP project specified and gcloud has no active project."
  echo "Usage: ./scripts/bootstrap_cloud.sh <PROJECT_ID>"
  exit 1
fi

echo "☁️  Bootstrap Google Cloud — project ${PROJECT_ID}"
echo ""

gcloud config set project "${PROJECT_ID}"

echo "Enabling core APIs..."
gcloud services enable \
  run.googleapis.com \
  firestore.googleapis.com \
  secretmanager.googleapis.com \
  aiplatform.googleapis.com \
  generativelanguage.googleapis.com \
  firebase.googleapis.com \
  firebasestorage.googleapis.com \
  --project="${PROJECT_ID}"

echo "Enabling optional APIs (Cloud Build, Artifact Registry)..."
gcloud services enable \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  --project="${PROJECT_ID}" 2>/dev/null || true

echo ""
echo "✅ Bootstrap complete for project ${PROJECT_ID}."
echo "   Vertex AI mode is enabled by default (no API key needed)."
echo "   Optional (api_key mode):"
echo "   echo -n 'YOUR_GEMINI_KEY' | gcloud secrets create GEMINI_API_KEY --data-file=- --project=${PROJECT_ID}"

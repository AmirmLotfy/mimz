#!/bin/bash
set -euo pipefail

# bootstrap_firebase.sh — Enable Firebase-related APIs on a project.
# Usage:
#   ./scripts/bootstrap_firebase.sh                # uses current gcloud project
#   ./scripts/bootstrap_firebase.sh my-project-id  # explicit project

PROJECT_ID="${1:-$(gcloud config get-value project 2>/dev/null)}"

if [[ -z "${PROJECT_ID}" || "${PROJECT_ID}" == "(unset)" ]]; then
  echo "ERROR: No project specified and gcloud has no active project."
  echo "Usage: ./scripts/bootstrap_firebase.sh <PROJECT_ID>"
  exit 1
fi

echo "=== Bootstrapping Firebase config for project ${PROJECT_ID} ==="

gcloud config set project "${PROJECT_ID}"

echo "Enabling GCP/Firebase APIs..."
gcloud services enable \
  firebase.googleapis.com \
  firestore.googleapis.com \
  aiplatform.googleapis.com \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  secretmanager.googleapis.com \
  identitytoolkit.googleapis.com \
  generativelanguage.googleapis.com \
  firebasestorage.googleapis.com \
  --project="${PROJECT_ID}"

echo "=== Firebase Bootstrap Complete for ${PROJECT_ID} ==="
echo "Note: Auth providers (Google, Email, etc.) must be configured in the Firebase Console."

#!/usr/bin/env bash
set -euo pipefail

# deploy_firebase.sh — Deploy Firestore + Storage rules to a Firebase project.
# Usage:
#   ./scripts/deploy_firebase.sh                # uses current gcloud project
#   ./scripts/deploy_firebase.sh my-project-id  # explicit project

PROJECT_ID="${1:-$(gcloud config get-value project 2>/dev/null)}"

if [[ -z "${PROJECT_ID}" || "${PROJECT_ID}" == "(unset)" ]]; then
  echo "ERROR: No Firebase project specified and gcloud has no active project."
  echo "Usage: ./scripts/deploy_firebase.sh <PROJECT_ID>"
  exit 1
fi

echo "Deploying Firebase rules and storage configs to ${PROJECT_ID}..."

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${REPO_ROOT}"

firebase deploy --only firestore,storage --project "${PROJECT_ID}" --non-interactive

echo "Firebase deployment to ${PROJECT_ID} complete."

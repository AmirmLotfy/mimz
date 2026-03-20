#!/usr/bin/env bash
# apply_firebase_rules.sh — Deploy Firestore and Storage rules + indexes.
# Usage:
#   ./scripts/apply_firebase_rules.sh                # uses current gcloud project
#   ./scripts/apply_firebase_rules.sh my-project-id  # explicit project
# Safe to rerun.

set -euo pipefail

PROJECT_ID="${1:-$(gcloud config get-value project 2>/dev/null)}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ -z "${PROJECT_ID}" || "${PROJECT_ID}" == "(unset)" ]]; then
  echo "ERROR: No Firebase project specified and gcloud has no active project."
  echo "Usage: ./scripts/apply_firebase_rules.sh <PROJECT_ID>"
  exit 1
fi

cd "$REPO_ROOT"

echo "📋 Deploying Firebase rules to ${PROJECT_ID}..."

firebase deploy \
  --only firestore:rules,storage \
  --project="${PROJECT_ID}"

# Deploy indexes if present
if [ -f "firestore.indexes.json" ]; then
  echo "📑 Deploying Firestore indexes..."
  firebase deploy \
    --only firestore:indexes \
    --project="${PROJECT_ID}"
fi

echo "✅ Firebase rules deployed to ${PROJECT_ID}."

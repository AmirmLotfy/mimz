#!/usr/bin/env bash
# deploy_rules_and_indexes.sh — Deploy Firestore rules, Storage rules, and Firestore indexes.
# Usage:
#   ./scripts/deploy_rules_and_indexes.sh                # uses current gcloud project
#   ./scripts/deploy_rules_and_indexes.sh my-project-id  # explicit project
# Safe to rerun.

set -euo pipefail

PROJECT_ID="${1:-$(gcloud config get-value project 2>/dev/null)}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ -z "${PROJECT_ID}" || "${PROJECT_ID}" == "(unset)" ]]; then
  echo "ERROR: No Firebase project specified and gcloud has no active project."
  echo "Usage: ./scripts/deploy_rules_and_indexes.sh <PROJECT_ID>"
  exit 1
fi

cd "${REPO_ROOT}"

echo "📋 Deploying Firebase rules and indexes to ${PROJECT_ID}..."

firebase deploy \
  --only firestore:rules,storage \
  --project="${PROJECT_ID}"

if [ -f "firestore.indexes.json" ]; then
  echo "📑 Deploying Firestore indexes..."
  firebase deploy \
    --only firestore:indexes \
    --project="${PROJECT_ID}"
else
  echo "   (no firestore.indexes.json — skipping indexes)"
fi

echo "✅ Rules and indexes deployed to ${PROJECT_ID}."

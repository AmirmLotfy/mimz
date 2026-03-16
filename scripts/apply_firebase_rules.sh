#!/usr/bin/env bash
# apply_firebase_rules.sh — Deploy Firestore and Storage rules + indexes to mimzapp
# Usage: ./scripts/apply_firebase_rules.sh
# Safe to rerun.

set -euo pipefail

PROJECT_ID="mimzapp"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cd "$REPO_ROOT"

echo "📋 Deploying Firebase rules to $PROJECT_ID..."

firebase deploy \
  --only firestore:rules,storage \
  --project="$PROJECT_ID"

# Deploy indexes if present
if [ -f "firestore.indexes.json" ]; then
  echo "📑 Deploying Firestore indexes..."
  firebase deploy \
    --only firestore:indexes \
    --project="$PROJECT_ID"
fi


echo "✅ Firebase rules deployed."

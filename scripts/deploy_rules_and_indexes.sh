#!/usr/bin/env bash
# deploy_rules_and_indexes.sh — Deploy Firestore rules, Storage rules, and Firestore indexes to mimzapp.
# Usage: ./scripts/deploy_rules_and_indexes.sh
# Safe to rerun.

set -euo pipefail

PROJECT_ID="mimzapp"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cd "$REPO_ROOT"

echo "📋 Deploying Firebase rules and indexes to $PROJECT_ID..."

firebase deploy \
  --only firestore:rules,storage \
  --project="$PROJECT_ID"

if [ -f "firestore.indexes.json" ]; then
  echo "📑 Deploying Firestore indexes..."
  firebase deploy \
    --only firestore:indexes \
    --project="$PROJECT_ID"
else
  echo "   (no firestore.indexes.json — skipping indexes)"
fi

echo "✅ Rules and indexes deployed."

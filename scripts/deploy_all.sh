#!/usr/bin/env bash
# deploy_all.sh — Full Mimz deployment: Firebase rules + backend + FlutterFire config
# Usage: ./scripts/deploy_all.sh
# Safe to rerun.

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ID="${1:-mimz-490520}"
REGION="${CLOUD_RUN_REGION:-europe-west1}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Mimz Full Deployment"
echo "   Project: ${PROJECT_ID}"
echo "   Region:  ${REGION}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Step 1/3 — Firebase rules and indexes"
bash "$SCRIPTS_DIR/deploy_rules_and_indexes.sh" "${PROJECT_ID}"
echo ""

echo "Step 2/3 — Backend to Cloud Run"
bash "$SCRIPTS_DIR/deploy_backend.sh" "${PROJECT_ID}"
echo ""

echo "Step 3/3 — FlutterFire config"
bash "$SCRIPTS_DIR/configure_flutterfire.sh"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All deployments complete."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

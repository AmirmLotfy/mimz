#!/usr/bin/env bash
# deploy_backend.sh — Deploy Mimz backend to Cloud Run
# Usage: ./scripts/deploy_backend.sh
# Safe to rerun.

set -euo pipefail

PROJECT_ID="${1:-mimz-490520}"
REGION="${CLOUD_RUN_REGION:-europe-west1}"
GEMINI_AUTH_MODE="${GEMINI_AUTH_MODE:-vertex}"
GEMINI_LIVE_VERTEX_LOCATION="${GEMINI_LIVE_VERTEX_LOCATION:-us-central1}"
SERVICE_NAME="mimz-backend"
BACKEND_DIR="$(cd "$(dirname "$0")/../backend" && pwd)"

echo "🚀 Deploying $SERVICE_NAME to Cloud Run ($REGION) in project ${PROJECT_ID}..."

SECRET_FLAGS=""
if [[ "${GEMINI_AUTH_MODE}" == "api_key" ]]; then
  SECRET_FLAGS="--set-secrets=GEMINI_API_KEY=GEMINI_API_KEY:latest"
fi

gcloud run deploy "$SERVICE_NAME" \
  --source "$BACKEND_DIR" \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --platform=managed \
  --no-invoker-iam-check \
  --port=8080 \
  --min-instances=0 \
  --max-instances=10 \
  --memory=512Mi \
  --cpu=1 \
  --timeout=60 \
  --set-env-vars="\
NODE_ENV=production,\
GCP_PROJECT_ID=${PROJECT_ID},\
FIREBASE_PROJECT_ID=${PROJECT_ID},\
FIRESTORE_DATABASE=(default),\
STORAGE_BUCKET=${PROJECT_ID}.firebasestorage.app,\
GEMINI_AUTH_MODE=${GEMINI_AUTH_MODE},\
GEMINI_VERTEX_LOCATION=${REGION},\
GEMINI_LIVE_VERTEX_LOCATION=${GEMINI_LIVE_VERTEX_LOCATION},\
GEMINI_MODEL=gemini-2.5-flash,\
GEMINI_LIVE_MODEL=gemini-live-2.5-flash-native-audio,\
GEMINI_UTILITY_MODEL=gemini-2.5-flash-lite,\
EPHEMERAL_TOKEN_TTL_MS=300000,\
MAX_REWARD_PER_HOUR=5000,\
MAX_SECTORS_PER_ROUND=5,\
MAX_STREAK_BONUS=10,\
LOG_LEVEL=info,\
RATE_LIMIT_MAX=100" \
  ${SECRET_FLAGS} \
  --quiet

echo ""
echo "✅ Backend deployed."

# Print the service URL
URL=$(gcloud run services describe "$SERVICE_NAME" \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --format="value(status.url)" 2>/dev/null)

echo "🌐 Service URL: $URL"
echo ""
echo "🔍 Health check:"
curl -sf "$URL/readyz" && echo "  → Healthy" || echo "  → Not responding yet (give it 15s)"

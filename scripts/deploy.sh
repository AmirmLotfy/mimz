#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────
#  Mimz Backend — Automated Cloud Run Deployment
#  Usage:  ./scripts/deploy.sh [--project PROJECT_ID] [--region REGION]
# ───────────────────────────────────────────────────────────
set -euo pipefail

# ─── Defaults ──────────────────────────────────────────────
PROJECT_ID="${GCP_PROJECT_ID:-}"
REGION="${CLOUD_RUN_REGION:-us-central1}"
SERVICE_NAME="mimz-backend"
IMAGE_TAG="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"
MEMORY="512Mi"
CPU="1"
MIN_INSTANCES="0"
MAX_INSTANCES="10"

# ─── Parse Arguments ───────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case $1 in
    --project) PROJECT_ID="$2"; shift 2 ;;
    --region)  REGION="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    *)         echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# ─── Validate ──────────────────────────────────────────────
if [[ -z "$PROJECT_ID" ]]; then
  echo "❌ Error: PROJECT_ID is required."
  echo "   Set GCP_PROJECT_ID env var or pass --project <id>"
  exit 1
fi

IMAGE_TAG="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"

echo "═══════════════════════════════════════════════"
echo "  Mimz Backend — Cloud Run Deploy"
echo "═══════════════════════════════════════════════"
echo "  Project:     ${PROJECT_ID}"
echo "  Region:      ${REGION}"
echo "  Service:     ${SERVICE_NAME}"
echo "  Image:       ${IMAGE_TAG}"
echo "  Memory:      ${MEMORY}"
echo "  CPU:         ${CPU}"
echo "  Instances:   ${MIN_INSTANCES}–${MAX_INSTANCES}"
echo "═══════════════════════════════════════════════"

# ─── Step 1: Enable APIs ───────────────────────────────────
echo ""
echo "🔧 Step 1/5: Enabling required APIs..."
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  firestore.googleapis.com \
  artifactregistry.googleapis.com \
  --project="${PROJECT_ID}" \
  --quiet

# ─── Step 2: Build Container ──────────────────────────────
echo ""
echo "📦 Step 2/5: Building container image..."
gcloud builds submit \
  --tag "${IMAGE_TAG}" \
  --project="${PROJECT_ID}" \
  --quiet \
  ./backend

# ─── Step 3: Deploy to Cloud Run ──────────────────────────
echo ""
echo "🚀 Step 3/5: Deploying to Cloud Run..."

# Check if GEMINI_API_KEY is available as a secret
GEMINI_SECRET_FLAG=""
if gcloud secrets describe gemini-api-key --project="${PROJECT_ID}" &>/dev/null; then
  echo "   Using Secret Manager for GEMINI_API_KEY"
  GEMINI_SECRET_FLAG="--set-secrets=GEMINI_API_KEY=gemini-api-key:latest"
else
  echo "   ⚠️  Secret 'gemini-api-key' not found. Set GEMINI_API_KEY via env vars manually."
fi

gcloud run deploy "${SERVICE_NAME}" \
  --image "${IMAGE_TAG}" \
  --region "${REGION}" \
  --project="${PROJECT_ID}" \
  --platform managed \
  --allow-unauthenticated \
  --memory "${MEMORY}" \
  --cpu "${CPU}" \
  --min-instances "${MIN_INSTANCES}" \
  --max-instances "${MAX_INSTANCES}" \
  --set-env-vars="\
NODE_ENV=production,\
GCP_PROJECT_ID=${PROJECT_ID},\
FIREBASE_PROJECT_ID=${PROJECT_ID},\
LOG_LEVEL=info,\
RATE_LIMIT_MAX=100,\
GEMINI_LIVE_MODEL=gemini-2.0-flash-live-001" \
  ${GEMINI_SECRET_FLAG} \
  --quiet

# ─── Step 4: Get Service URL ──────────────────────────────
echo ""
echo "🔗 Step 4/5: Retrieving service URL..."
SERVICE_URL=$(gcloud run services describe "${SERVICE_NAME}" \
  --region "${REGION}" \
  --project="${PROJECT_ID}" \
  --format='value(status.url)')

echo "   URL: ${SERVICE_URL}"

# ─── Step 5: Verify ──────────────────────────────────────
echo ""
echo "✅ Step 5/5: Verifying deployment..."

HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "${SERVICE_URL}/healthz")
if [[ "$HEALTH_RESPONSE" == "200" ]]; then
  echo "   /healthz → 200 OK ✓"
else
  echo "   /healthz → ${HEALTH_RESPONSE} ✗"
  echo "   ⚠️  Health check failed. Check Cloud Run logs."
fi

READY_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "${SERVICE_URL}/readyz")
if [[ "$READY_RESPONSE" == "200" ]]; then
  echo "   /readyz  → 200 OK ✓"
else
  echo "   /readyz  → ${READY_RESPONSE} ✗"
fi

# ─── Done ─────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════"
echo "  ✅ Deployment complete!"
echo "  Service:  ${SERVICE_URL}"
echo "  Logs:     https://console.cloud.google.com/run/detail/${REGION}/${SERVICE_NAME}/logs?project=${PROJECT_ID}"
echo "  Console:  https://console.cloud.google.com/run?project=${PROJECT_ID}"
echo ""
echo "  Flutter app config:"
echo "  flutter run --dart-define=BACKEND_URL=${SERVICE_URL}"
echo "═══════════════════════════════════════════════"

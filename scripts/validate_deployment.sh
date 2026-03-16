#!/usr/bin/env bash
# validate_deployment.sh — Hit backend health/readyz and report status.
# Usage: ./scripts/validate_deployment.sh [BASE_URL]
# If BASE_URL is omitted, uses the default Mimz backend URL.

set -euo pipefail

BASE_URL="${1:-https://mimz-backend-1012962167727.europe-west1.run.app}"

echo "🔍 Validating deployment at $BASE_URL"
echo ""

HEALTH_URL="$BASE_URL/health"
READYZ_URL="$BASE_URL/readyz"

ok=0
fail=0

if code=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL"); then
  if [ "$code" = "200" ]; then
    echo "✅ GET /health → $code"
    ok=$((ok+1))
  else
    echo "❌ GET /health → $code"
    fail=$((fail+1))
  fi
else
  echo "❌ GET /health → request failed"
  fail=$((fail+1))
fi

if code=$(curl -s -o /dev/null -w "%{http_code}" "$READYZ_URL"); then
  if [ "$code" = "200" ]; then
    echo "✅ GET /readyz → $code"
    ok=$((ok+1))
  else
    echo "❌ GET /readyz → $code"
    fail=$((fail+1))
  fi
else
  echo "❌ GET /readyz → request failed"
  fail=$((fail+1))
fi

echo ""
if [ "$fail" -eq 0 ]; then
  echo "✅ All checks passed."
  exit 0
else
  echo "❌ $fail check(s) failed."
  exit 1
fi

#!/usr/bin/env bash
# validate_deployment.sh — Hit backend health/readyz and report status.
# Usage: ./scripts/validate_deployment.sh [BASE_URL]
# If BASE_URL is omitted, uses the default Mimz backend URL.

set -euo pipefail

# Canonical service URL
BASE_URL="${1:-https://mimz-backend-glaimgrznq-ew.a.run.app}"
AUTH_HEADER=()

# If service is private (403/401), we can retry with an identity token from gcloud.
get_identity_header() {
  if command -v gcloud >/dev/null 2>&1; then
    local token
    token="$(gcloud auth print-identity-token 2>/dev/null || true)"
    if [ -n "${token}" ]; then
      AUTH_HEADER=(-H "Authorization: Bearer ${token}")
    fi
  fi
}

echo "🔍 Validating deployment at $BASE_URL"
echo ""

HEALTH_URL="$BASE_URL/health"
READYZ_URL="$BASE_URL/readyz"

ok=0
fail=0

if code=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL"); then
  if [ "$code" = "401" ] || [ "$code" = "403" ]; then
    get_identity_header
    if [ "${#AUTH_HEADER[@]}" -gt 0 ]; then
      code=$(curl -s -o /dev/null -w "%{http_code}" "${AUTH_HEADER[@]}" "$HEALTH_URL")
    fi
  fi
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
  if [ "$code" = "401" ] || [ "$code" = "403" ]; then
    get_identity_header
    if [ "${#AUTH_HEADER[@]}" -gt 0 ]; then
      code=$(curl -s -o /dev/null -w "%{http_code}" "${AUTH_HEADER[@]}" "$READYZ_URL")
    fi
  fi
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

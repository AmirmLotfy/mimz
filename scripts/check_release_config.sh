#!/bin/bash

# Mimz Release Config Checker
# This script audits the current environment for release readiness.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

echo "🔍 Checking Release Configuration..."

# 1. Check for google-services.json
if [ -f "app/android/app/google-services.json" ]; then
    echo "✅ google-services.json found."
else
    echo "❌ google-services.json MISSING from app/android/app/"
fi

# 2. Check for firebase_options.dart
if [ -f "app/lib/firebase_options.dart" ]; then
    echo "✅ firebase_options.dart found."
else
    echo "❌ firebase_options.dart MISSING from app/lib/"
fi

# 3. Check Android Manifest for critical permissions
echo "🛡️ Checking Android Manifest permissions..."
grep -q "android.permission.INTERNET" app/android/app/src/main/AndroidManifest.xml && echo "  - INTERNET: ✅" || echo "  - INTERNET: ❌ MISSING"
grep -q "android.permission.RECORD_AUDIO" app/android/app/src/main/AndroidManifest.xml && echo "  - RECORD_AUDIO: ✅" || echo "  - RECORD_AUDIO: ❌ MISSING"
grep -q "android.permission.CAMERA" app/android/app/src/main/AndroidManifest.xml && echo "  - CAMERA: ✅" || echo "  - CAMERA: ❌ MISSING"
grep -q "googleMapsApiKey" app/android/app/src/main/AndroidManifest.xml && echo "  - MAPS PLACEHOLDER: ✅" || echo "  - MAPS PLACEHOLDER: ❌ MISSING"

# 4. Check for production URL in ApiClient
echo "🌐 Checking ApiClient URL..."
grep -q "mimz-backend-glaimgrznq-ew.a.run.app" app/lib/services/api_client.dart && echo "✅ Production backend URL found." || echo "⚠️  Production backend URL not found or custom."

# 5. Check LogInterceptor status
echo "📝 Checking LogInterceptor hardening..."
if grep -q "if (kDebugMode)" app/lib/services/api_client.dart && grep -A 5 "if (kDebugMode)" app/lib/services/api_client.dart | grep -q "LogInterceptor"; then
    echo "✅ LogInterceptor is properly guarded."
else
    echo "❌ LogInterceptor is NOT guarded (SECURITY RISK)"
fi

echo "🏁 Audit Complete."

#!/bin/bash
# ─────────────────────────────────────────────────────────────────
# Mimz Release Build Script
# Usage: bash scripts/build_release_apk.sh [--split-abi]
# ─────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_DIR="$ROOT_DIR/app"
ARTIFACTS_DIR="$ROOT_DIR/artifacts/release"
LOG_FILE="$ARTIFACTS_DIR/build_release.log"
APK_OUT="$APP_DIR/build/app/outputs/flutter-apk"

mkdir -p "$ARTIFACTS_DIR"

echo "🚀 Mimz Release Build — $(date)" | tee "$LOG_FILE"
echo "   App dir: $APP_DIR"

cd "$APP_DIR"

# 0. Preflight release config checks
echo "" && echo "🧪 [0/4] Running release preflight checks..." | tee -a "$LOG_FILE"
bash "$ROOT_DIR/scripts/check_release_config.sh" | tee -a "$LOG_FILE"

# 1. Clean build artifacts
echo "" && echo "🧹 [1/4] Cleaning project..." | tee -a "$LOG_FILE"
flutter clean >> "$LOG_FILE" 2>&1

# 2. Fetch dependencies
echo "📦 [2/4] Fetching dependencies..." | tee -a "$LOG_FILE"
flutter pub get >> "$LOG_FILE" 2>&1

# 3. Generate code (Riverpod, Freezed, json_serializable)
echo "⚙️  [3/4] Generating code..." | tee -a "$LOG_FILE"
dart run build_runner build --delete-conflicting-outputs >> "$LOG_FILE" 2>&1

# 4. Build Release APKs
echo "🏗️  [4/4] Building Release APK..." | tee -a "$LOG_FILE"
flutter build apk --release 2>&1 | tee -a "$LOG_FILE"

if [[ "${1:-}" == "--split-abi" ]]; then
  echo "🏗️  Building split-per-ABI APKs..." | tee -a "$LOG_FILE"
  flutter build apk --release --split-per-abi 2>&1 | tee -a "$LOG_FILE"
fi

echo "" && echo "✅ Build complete!" | tee -a "$LOG_FILE"
echo "── APK outputs ──────────────────────────────────────"
ls -lh "$APK_OUT"/*.apk 2>/dev/null || echo "No APKs found at $APK_OUT"
echo "── Build log ────────────────────────────────────────"
echo "   $LOG_FILE"

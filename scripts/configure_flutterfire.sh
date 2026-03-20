#!/usr/bin/env bash
# configure_flutterfire.sh — Regenerate firebase_options.dart
# Usage:
#   ./scripts/configure_flutterfire.sh                # uses current Firebase project
#   ./scripts/configure_flutterfire.sh my-project-id  # explicit project
# Requires: flutterfire CLI installed (dart pub global activate flutterfire_cli)
#
# NOTE: iOS is excluded from the non-interactive run because flutterfire CLI 1.x
# has a known parsing bug with Xcode pbxproj in non-interactive (--yes) mode.
# To regenerate iOS config interactively: flutterfire configure --project=<id> --platforms=ios
#
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/../app" && pwd)"
PROJECT_ID="${1:-mimz-490520}"

echo "🔥 Regenerating FlutterFire configuration for project ${PROJECT_ID}..."

cd "$APP_DIR"

# Android only in automated mode — iOS config is already committed and stable.
if flutterfire configure \
  --project="${PROJECT_ID}" \
  --platforms=android \
  --android-package-name=com.mimz.mimz_mobile \
  --yes; then
  echo "✅ firebase_options.dart regenerated for ${PROJECT_ID}."
  echo "   google-services.json updated for Android."
else
  echo "⚠️  flutterfire configure exited with a non-zero code."
  echo "   Existing firebase_options.dart is still valid — the app will build."
  echo "   To regenerate manually: flutterfire configure --project=${PROJECT_ID}"
fi

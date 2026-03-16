#!/usr/bin/env bash
# configure_flutterfire.sh — Regenerate firebase_options.dart for Android + iOS
# Usage: ./scripts/configure_flutterfire.sh
# Requires: flutterfire CLI installed (dart pub global activate flutterfire_cli)

set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/../app" && pwd)"

echo "🔥 Regenerating FlutterFire configuration for mimzapp..."

cd "$APP_DIR"

flutterfire configure \
  --project=mimzapp \
  --platforms=android,ios \
  --yes

echo "✅ firebase_options.dart regenerated."
echo "   Also downloads google-services.json and GoogleService-Info.plist."

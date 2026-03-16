#!/bin/bash

# Mimz Fingerprint Printer
# This script prints the SHA-1 and SHA-256 fingerprints of the current signing key.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🔑 Extracting Android Fingerprints..."

cd "$ROOT_DIR/app/android"

if [ -f "app/mimz-release.keystore" ]; then
    echo "✅ Found Production Release Keystore: app/mimz-release.keystore"
    keytool -list -v -keystore app/mimz-release.keystore -alias mimz -storepass mimzrelease -keypass mimzrelease
elif [ -f "app/debug.keystore" ]; then
    echo "⚠️  Using debug.keystore (NOT production release keystore)."
    echo "   Release Google Sign-In may still fail until production SHA is added in Firebase."
    keytool -list -v -keystore app/debug.keystore -alias androiddebugkey -storepass android -keypass android
elif [ -f "$HOME/.android/debug.keystore" ]; then
    echo "⚠️  Using default debug.keystore (NOT production release keystore)."
    echo "   Release Google Sign-In may still fail until production SHA is added in Firebase."
    keytool -list -v -keystore "$HOME/.android/debug.keystore" -alias androiddebugkey -storepass android -keypass android
else
    echo "⚠️  No keystore found. Running ./gradlew signingReport..."
    ./gradlew signingReport
fi

echo ""
echo "💡 Copy the SHA-1 and SHA-256 values and add them to your Firebase Console (Project Settings > General > Your Apps > Android app)."

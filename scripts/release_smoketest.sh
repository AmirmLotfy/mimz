#!/bin/bash
# ─────────────────────────────────────────────────────────────────
# Mimz Release Smoke Test Script
# Usage: bash scripts/release_smoketest.sh [optional-apk-path]
# Requires: adb in PATH, Android device or emulator connected.
# ─────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APK="${1:-$ROOT_DIR/app/build/app/outputs/flutter-apk/app-release.apk}"
PKG="com.mimz.mimz_mobile"

echo "🔍 Mimz Release Smoke Test — $(date)"

# 1. Check ADB
if ! command -v adb &>/dev/null; then
  echo "❌ adb not found. Install Android SDK platform-tools and add to PATH."
  exit 1
fi

# 2. Check device
DEVICE=$(adb get-state 2>/dev/null || echo "")
if [[ "$DEVICE" != "device" ]]; then
  echo "❌ No Android device connected. Connect a device or start an emulator."
  echo "   Tip: 'adb start-server' then check 'adb devices'"
  exit 1
fi
echo "✅ Device detected: $(adb devices | grep -v 'List' | grep 'device' | head -1)"

# 3. Check APK exists
if [[ ! -f "$APK" ]]; then
  echo "❌ APK not found: $APK"
  echo "   Run: bash scripts/build_release_apk.sh"
  exit 1
fi
echo "✅ APK: $APK ($(du -sh "$APK" | cut -f1))"

# 4. Install APK
echo "📲 Installing APK..."
adb install -r "$APK"
echo "✅ Installed"

# 5. Launch app
echo "🚀 Launching $PKG..."
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null
sleep 3

# 6. Check if process is running
PID=$(adb shell pidof -s "$PKG" 2>/dev/null || true)
if [[ -n "$PID" ]]; then
  echo "✅ App is running (PID $PID)"
else
  echo "❌ App process not found — may have crashed on startup"
fi

echo ""
echo "── Manual Smoke Test Checklist ──────────────────────"
echo "  1. [ ] Splash screen renders"
echo "  2. [ ] Auth/Welcome screen opens"
echo "  3. [ ] Email sign-in works"
echo "  4. [ ] Google sign-in flow launches"
echo "  5. [ ] Home/Map screen loads"
echo "  6. [ ] Backend connectivity indicator is green"
echo "  7. [ ] Live quiz entry works"
echo "  8. [ ] Vision quest entry works"
echo "  9. [ ] Settings/Profile opens"
echo " 10. [ ] Sign out works"
echo ""
echo "── Logcat (Ctrl+C to stop) ────────────────────────────"
if [[ -n "$PID" ]]; then
  adb logcat --pid="$PID" -v brief 2>/dev/null | grep -v "^-" || adb logcat -v brief 2>/dev/null
else
  adb logcat -v brief 2>/dev/null
fi

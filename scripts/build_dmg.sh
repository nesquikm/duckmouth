#!/bin/bash
set -euo pipefail

APP_NAME="Duckmouth"
BUILD_DIR="build/macos/Build/Products/Release"
DMG_DIR="build/dmg"
VERSION=$(grep 'version:' pubspec.yaml | head -1 | awk '{print $2}' | cut -d'+' -f1)
DMG_FILE="$DMG_DIR/$APP_NAME-$VERSION.dmg"

echo "==> Building $APP_NAME v$VERSION (universal binary: x86_64 + arm64)"

# 1. Build release (universal binary by default)
fvm flutter build macos --release

# Verify universal binary
echo "==> Verifying universal binary..."
ARCHS=$(file "$BUILD_DIR/$APP_NAME.app/Contents/MacOS/duckmouth" | grep -c "architecture")
if [ "$ARCHS" -lt 2 ]; then
  echo "WARNING: Binary is not universal (expected x86_64 + arm64)"
fi

# 2. Ad-hoc sign with entitlements (no Developer ID needed)
# Sign frameworks first (no entitlements for frameworks), then the main app with entitlements.
# Avoid --deep, which Apple discourages and which strips entitlements.
echo "==> Ad-hoc signing..."
find "$BUILD_DIR/$APP_NAME.app/Contents/Frameworks" -name "*.framework" -exec codesign --force -s - {} \;
codesign --force -s - --entitlements macos/Runner/Release.entitlements "$BUILD_DIR/$APP_NAME.app"

# 3. Create DMG
echo "==> Creating DMG..."
mkdir -p "$DMG_DIR"

# Remove existing DMG if present (create-dmg fails otherwise)
rm -f "$DMG_FILE"

create-dmg \
  --volname "$APP_NAME" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "$APP_NAME.app" 175 190 \
  --app-drop-link 425 190 \
  "$DMG_FILE" \
  "$BUILD_DIR/$APP_NAME.app"

echo "==> Done! DMG created at: $DMG_FILE"
echo "    Version: $VERSION"
echo "    SHA256: $(shasum -a 256 "$DMG_FILE" | awk '{print $1}')"

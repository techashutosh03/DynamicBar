#!/usr/bin/env bash
set -euo pipefail

# DynamicBar DMG Packaging & Ad-hoc Signing Utility
# Usage: ./package_dmg.sh [path/to/DynamicBar.app] [output/DynamicBar.dmg]

APP_PATH="${1:-$HOME/Desktop/DynamicBar.app}"
DMG_PATH="${2:-$HOME/Desktop/DynamicBar.dmg}"

echo "=============================================="
echo " Packaging DynamicBar for Distribution ($0)"
echo "=============================================="

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: DynamicBar.app not found at: $APP_PATH"
    echo "Please build the app in Xcode (Product -> Archive or Build) and place DynamicBar.app on your Desktop."
    exit 1
fi

echo "1. Removing quarantine flags from $APP_PATH..."
xattr -cr "$APP_PATH"

echo "2. Deep-signing the app bundle, XPC helper, and internal frameworks with ad-hoc signature..."
codesign --force --deep --sign - "$APP_PATH"

echo "3. Creating UDZO compressed installer DMG at $DMG_PATH..."
hdiutil create -volname "DynamicBar" -srcfolder "$APP_PATH" -ov -format UDZO "$DMG_PATH"

echo "✅ Done! Your downloadable $DMG_PATH is ready for sharing."

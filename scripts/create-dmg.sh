#!/bin/bash

# Create DMG for Swift Browser
# Usage: ./scripts/create-dmg.sh

set -e

APP_NAME="Swift Browser"
OUTPUT_DIR="$HOME/Downloads/SwiftBrowser"
DMG_FINAL="${OUTPUT_DIR}/SwiftBrowser.dmg"
VOLUME_NAME="Swift Browser"

# Find the built app in Xcode's DerivedData
DERIVED_APP=$(find ~/Library/Developer/Xcode/DerivedData -name "Swift Browser.app" -type d | head -1)

if [ -z "$DERIVED_APP" ]; then
    echo "Error: Built app not found. Please build the project first in Xcode."
    exit 1
fi

echo "Found built app at: $DERIVED_APP"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Copy app to output directory
APP_PATH="$OUTPUT_DIR/${APP_NAME}.app"
echo "Copying app to $APP_PATH..."
rm -rf "$APP_PATH"
cp -R "$DERIVED_APP" "$APP_PATH"

# Create staging directory in the same location
STAGING_DIR="${OUTPUT_DIR}/dmg-staging"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

# Copy app to staging
echo "Copying app to staging..."
cp -R "$APP_PATH" "$STAGING_DIR/"

# Create Applications symlink
ln -s /Applications "$STAGING_DIR/Applications"

# Remove old DMG if exists
rm -f "$DMG_FINAL"

# Create DMG directly (no mount needed)
echo "Creating DMG..."
hdiutil create -volname "$VOLUME_NAME" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_FINAL"

# Cleanup staging
rm -rf "$STAGING_DIR"

echo ""
echo "DMG created successfully: ${DMG_FINAL}"
echo "Size: $(du -h "$DMG_FINAL" | cut -f1)"

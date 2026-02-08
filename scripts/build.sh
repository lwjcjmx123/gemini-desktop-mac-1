#!/bin/bash

# Build and optionally package Swift Browser
# Usage:
#   ./scripts/build.sh          # Build only
#   ./scripts/build.sh --dmg    # Build + create DMG
#   ./scripts/build.sh --open   # Build + open app

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$PROJECT_DIR/GeminiDesktop.xcodeproj"
SCHEME="SwiftBrowser"
APP_NAME="Swift Browser"
CONFIGURATION="Debug"
BUILD_DIR="$PROJECT_DIR/build"
APP_PATH="$BUILD_DIR/${APP_NAME}.app"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

log()   { echo -e "${GREEN}[BUILD]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Parse arguments
ACTION="build"
for arg in "$@"; do
    case $arg in
        --dmg)     ACTION="dmg" ;;
        --open)    ACTION="open" ;;
        --clean)   ACTION="clean" ;;
        --release) CONFIGURATION="Release" ;;
        --help|-h)
            echo "Usage: ./scripts/build.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  (none)      Build the app (Debug)"
            echo "  --release   Use Release configuration (requires signing)"
            echo "  --dmg       Build and create DMG"
            echo "  --open      Build and open the app"
            echo "  --clean     Clean build directory"
            echo "  --help      Show this help"
            exit 0
            ;;
        *) error "Unknown option: $arg" ;;
    esac
done

# Clean
if [ "$ACTION" = "clean" ]; then
    log "Cleaning build directory..."
    rm -rf "$BUILD_DIR"
    log "Done."
    exit 0
fi

# Resolve dependencies (Swift Package Manager)
log "Resolving package dependencies..."
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -resolvePackageDependencies -quiet 2>/dev/null || true

# Build
log "Building $APP_NAME ($CONFIGURATION)..."
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    -quiet \
    build

# Find the built app
BUILT_APP=$(find "$BUILD_DIR/DerivedData" -name "${APP_NAME}.app" -type d | head -1)

if [ -z "$BUILT_APP" ]; then
    error "Build succeeded but app not found in DerivedData."
fi

# Copy to build root
rm -rf "$APP_PATH"
cp -R "$BUILT_APP" "$APP_PATH"

log "Build successful: $APP_PATH"

# Post-build actions
case $ACTION in
    open)
        log "Opening $APP_NAME..."
        open "$APP_PATH"
        ;;
    dmg)
        OUTPUT_DIR="$HOME/Downloads/SwiftBrowser"
        DMG_PATH="${OUTPUT_DIR}/SwiftBrowser.dmg"

        log "Creating DMG..."
        mkdir -p "$OUTPUT_DIR"

        # Staging
        STAGING="$BUILD_DIR/dmg-staging"
        rm -rf "$STAGING"
        mkdir -p "$STAGING"
        cp -R "$APP_PATH" "$STAGING/"
        ln -s /Applications "$STAGING/Applications"

        # Create DMG
        rm -f "$DMG_PATH"
        hdiutil create \
            -volname "$APP_NAME" \
            -srcfolder "$STAGING" \
            -ov -format UDZO \
            "$DMG_PATH"

        rm -rf "$STAGING"

        log "DMG created: $DMG_PATH"
        log "Size: $(du -h "$DMG_PATH" | cut -f1)"
        ;;
esac

log "Done."

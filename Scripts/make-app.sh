#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="Rescale"
APP_BUNDLE="$PROJECT_DIR/$APP_NAME.app"

echo "Building $APP_NAME..."
cd "$PROJECT_DIR"
swift build -c release 2>&1

BINARY="$PROJECT_DIR/.build/release/$APP_NAME"
if [[ ! -f "$BINARY" ]]; then
    echo "Error: binary not found at $BINARY"
    exit 1
fi

echo "Assembling $APP_NAME.app..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"

cp "$BINARY" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$PROJECT_DIR/Info.plist" "$APP_BUNDLE/Contents/"

mkdir -p "$APP_BUNDLE/Contents/Resources"
cp "$PROJECT_DIR/Sources/Rescale/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"

echo "Done → $APP_BUNDLE"

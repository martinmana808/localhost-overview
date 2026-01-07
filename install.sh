#!/bin/bash
set -e # Exit on error

# LocalHost Overview Installer
# This script builds the app and installs it to /Applications

APP_NAME="LocalHost Overview"
BUNDLE_ID="com.martinmana.LocalHostOverview"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"

echo "🚀 Building LocalHost Overview in Release mode..."

# Build the release binary
swift build -c release

echo "📦 Packaging into $APP_BUNDLE..."

# Create the app bundle structure
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy the binary
cp "$BUILD_DIR/LocalHostOverview" "$APP_BUNDLE/Contents/MacOS/LocalHostOverview"

# Copy Info.plist
cp "LocalHostOverview/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

echo "🎨 Creating app icon..."
# Create a temporary iconset
ICONSET="AppIcon.iconset"
mkdir -p "$ICONSET"

# Resize the source png into all required sizes ensuring PNG format
sips -z 16 16     -s format png app_icon.png --out "$ICONSET/icon_16x16.png"
sips -z 32 32     -s format png app_icon.png --out "$ICONSET/icon_16x16@2x.png"
sips -z 32 32     -s format png app_icon.png --out "$ICONSET/icon_32x32.png"
sips -z 64 64     -s format png app_icon.png --out "$ICONSET/icon_32x32@2x.png"
sips -z 128 128   -s format png app_icon.png --out "$ICONSET/icon_128x128.png"
sips -z 256 256   -s format png app_icon.png --out "$ICONSET/icon_128x128@2x.png"
sips -z 256 256   -s format png app_icon.png --out "$ICONSET/icon_256x256.png"
sips -z 512 512   -s format png app_icon.png --out "$ICONSET/icon_256x256@2x.png"
sips -z 512 512   -s format png app_icon.png --out "$ICONSET/icon_512x512.png"
sips -z 1024 1024 -s format png app_icon.png --out "$ICONSET/icon_512x512@2x.png"

# Convert iconset to icns
iconutil -c icns "$ICONSET"
cp "AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

# Clean up
rm -rf "$ICONSET"
rm "AppIcon.icns"

echo "🚚 Moving to /Applications..."

# Move to Applications
rm -rf "/Applications/$APP_BUNDLE"
mv "$APP_BUNDLE" "/Applications/"

# Force refresh icon cache
touch "/Applications/$APP_BUNDLE"

echo "✅ Done! You can now find '$APP_NAME' in your Applications folder."
echo "Opening the app..."
open "/Applications/$APP_BUNDLE"

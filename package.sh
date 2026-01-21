#!/bin/bash

# Configuration
APP_NAME="Vocabb"
BUNDLE_ID="com.sonn.vocabb"
VERSION="1.0.0"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"
DMG_NAME="$APP_NAME.dmg"

# Build
echo "🚀 Building $APP_NAME for Release (Universal)..."
swift build -c release --arch arm64 --arch x86_64

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

# Find the binary (handle different SPM output structures)
BINARY_PATH=$(find .build -name "$APP_NAME" -type f | grep -i "release" | head -n 1)

if [ -z "$BINARY_PATH" ]; then
    echo "❌ Binary not found in .build directory!"
    exit 1
fi

echo "📍 Found binary at: $BINARY_PATH"

echo "📦 Creating App Bundle structure..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary and set permissions
cp "$BINARY_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"


# Create PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>

    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.education</string>
</dict>
</plist>
EOF


# Handle Icon
if [ -f "icon.png" ]; then
    echo "🎨 Converting icon.png to AppIcon.icns..."
    mkdir -p "$APP_NAME.iconset"
    sips -z 16 16     icon.png --out "$APP_NAME.iconset/icon_16x16.png"
    sips -z 32 32     icon.png --out "$APP_NAME.iconset/icon_16x16@2x.png"
    sips -z 32 32     icon.png --out "$APP_NAME.iconset/icon_32x32.png"
    sips -z 64 64     icon.png --out "$APP_NAME.iconset/icon_32x32@2x.png"
    sips -z 128 128   icon.png --out "$APP_NAME.iconset/icon_128x128.png"
    sips -z 256 256   icon.png --out "$APP_NAME.iconset/icon_128x128@2x.png"
    sips -z 256 256   icon.png --out "$APP_NAME.iconset/icon_256x256.png"
    sips -z 512 512   icon.png --out "$APP_NAME.iconset/icon_256x256@2x.png"
    sips -z 512 512   icon.png --out "$APP_NAME.iconset/icon_512x512.png"
    sips -z 1024 1024 icon.png --out "$APP_NAME.iconset/icon_512x512@2x.png"
    
    iconutil -c icns "$APP_NAME.iconset"
    cp "$APP_NAME.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    rm -rf "$APP_NAME.iconset" "$APP_NAME.icns"
else
    echo "⚠️ icon.png not found, skipping icon integration."
fi

echo "💾 Creating DMG..."

rm -f "$DMG_NAME"
mkdir -p "dist"
cp -R "$APP_BUNDLE" "dist/"
ln -s /Applications "dist/Applications"

hdiutil create -volname "$APP_NAME" -srcfolder "dist" -ov -format UDZO "$DMG_NAME"

# Cleanup
rm -rf "dist"
echo "✅ Done! Created $DMG_NAME"

#!/bin/bash
set -euo pipefail

APP_NAME="AppsMenu"
BUNDLE_ID="lv.andris.appsmenu"
INSTALL_DIR="/Applications/${APP_NAME}.app"
BUILD_DIR="$(mktemp -d)"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/${BUNDLE_ID}.plist"

echo "Building ${APP_NAME}..."
mkdir -p "$BUILD_DIR/${APP_NAME}.app/Contents/MacOS"
mkdir -p "$BUILD_DIR/${APP_NAME}.app/Contents/Resources"

cat > "$BUILD_DIR/${APP_NAME}.app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>10.0</string>
    <key>CFBundleShortVersionString</key>
    <string>10.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

cp "$(dirname "$0")/AppIcon.icns" "$BUILD_DIR/${APP_NAME}.app/Contents/Resources/AppIcon.icns"

swiftc "$(dirname "$0")/Sources/AppsMenu.swift" -o "$BUILD_DIR/${APP_NAME}.app/Contents/MacOS/${APP_NAME}" -framework Cocoa
chmod +x "$BUILD_DIR/${APP_NAME}.app/Contents/MacOS/${APP_NAME}"

pkill -f "/Applications/${APP_NAME}.app" 2>/dev/null || true
osascript -e "quit app \"${APP_NAME}\"" 2>/dev/null || true
rm -rf "$INSTALL_DIR"
cp -R "$BUILD_DIR/${APP_NAME}.app" "$INSTALL_DIR"

# Ad-hoc sign the local app bundle so macOS treats it as a normal application.
codesign --force --deep --sign - "$INSTALL_DIR" 2>/dev/null || true

# Refresh Launch Services / icon caches where available.
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$INSTALL_DIR" 2>/dev/null || true
touch "$INSTALL_DIR"

mkdir -p "$HOME/Library/LaunchAgents"
cat > "$LAUNCH_AGENT" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${BUNDLE_ID}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/open</string>
        <string>-a</string>
        <string>${INSTALL_DIR}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
PLIST

launchctl bootout gui/$(id -u) "$LAUNCH_AGENT" 2>/dev/null || true
launchctl bootstrap gui/$(id -u) "$LAUNCH_AGENT" 2>/dev/null || true
launchctl enable gui/$(id -u)/${BUNDLE_ID} 2>/dev/null || true

open "$INSTALL_DIR"
echo "Installed. AppsMenu should now start automatically after restart."

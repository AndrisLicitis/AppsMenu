#!/bin/bash
set -euo pipefail
BUNDLE_ID="lv.andris.appsmenu"
APP_NAME="AppsMenu"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/${BUNDLE_ID}.plist"
launchctl bootout gui/$(id -u) "$LAUNCH_AGENT" 2>/dev/null || true
osascript -e "quit app \"${APP_NAME}\"" 2>/dev/null || true
pkill -f "/Applications/${APP_NAME}.app" 2>/dev/null || true
rm -f "$LAUNCH_AGENT"
rm -rf "/Applications/${APP_NAME}.app"
echo "Uninstalled AppsMenu."

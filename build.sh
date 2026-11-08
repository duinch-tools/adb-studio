#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="ADB Studio"
APP_BUNDLE="/Applications/${APP_NAME}.app"

echo "==> Biên dịch ADB Studio (SwiftUI Native)..."
swiftc -parse-as-library -O "$DIR"/Sources/*.swift -o "$DIR/AdbStudioBin"

echo "==> Đóng gói vào $APP_BUNDLE..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
if [ -f "$DIR/Resources/AppIcon.icns" ]; then
    cp "$DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

killall "$APP_NAME" 2>/dev/null || true
mv "$DIR/AdbStudioBin" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Symlink CLI commands
mkdir -p "$HOME/.local/bin"
ln -sf "$APP_BUNDLE/Contents/MacOS/$APP_NAME" "$HOME/.local/bin/adb-studio"
ln -sf "$APP_BUNDLE/Contents/MacOS/$APP_NAME" "$HOME/.local/bin/adb-screenshot"

# Optional dockutil support
if command -v dockutil &> /dev/null; then
    dockutil --find "$APP_NAME" &> /dev/null || dockutil --add "$APP_BUNDLE" &> /dev/null || true
fi

echo "==> Hoàn tất cài đặt ${APP_NAME}! Mở app qua: open -a '$APP_BUNDLE'"

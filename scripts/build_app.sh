#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

echo "==> Building release binary with Cargo..."
cargo build --release

APP_BUNDLE="/Applications/ADB Studio.app"
echo "==> Packaging into $APP_BUNDLE..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Generate minimal Info.plist if missing
cat << 'EOF' > "$APP_BUNDLE/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>ADB Studio</string>
    <key>CFBundleIdentifier</key>
    <string>app.duinch.adbstudio</string>
    <key>CFBundleName</key>
    <string>ADB Studio</string>
    <key>CFBundleDisplayName</key>
    <string>ADB Studio</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
</dict>
</plist>
EOF

if [ -f "$DIR/Resources/AppIcon.icns" ]; then
    cp "$DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

killall "ADB Studio" 2>/dev/null || true
cp "$DIR/target/release/adb-studio" "$APP_BUNDLE/Contents/MacOS/ADB Studio"
chmod +x "$APP_BUNDLE/Contents/MacOS/ADB Studio"

echo "==> Ad-hoc code signing for Apple Silicon macOS..."
codesign --force --deep --sign - "$APP_BUNDLE"
xattr -cr "$APP_BUNDLE" 2>/dev/null || true
touch "$APP_BUNDLE"

# CLI symlink
mkdir -p "$HOME/.local/bin"
ln -sf "$APP_BUNDLE/Contents/MacOS/ADB Studio" "$HOME/.local/bin/adb-studio"

echo "==> Done! App is ready: open -a '$APP_BUNDLE'"

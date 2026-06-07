#!/bin/bash
# Builds ClaudeLimits.app from the SwiftPM executable.
set -euo pipefail
cd "$(dirname "$0")"

APP="ClaudeLimits.app"
BIN_NAME="ClaudeLimits"

echo "→ swift build -c release"
swift build -c release

echo "→ assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp ".build/release/$BIN_NAME" "$APP/Contents/MacOS/$BIN_NAME"
[ -f Resources/AppIcon.icns ] && cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>ClaudeLimits</string>
    <key>CFBundleDisplayName</key>     <string>Claude Limits</string>
    <key>CFBundleExecutable</key>      <string>ClaudeLimits</string>
    <key>CFBundleIdentifier</key>      <string>me.kacharhin.ClaudeLimits</string>
    <key>CFBundleIconFile</key>        <string>AppIcon</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleShortVersionString</key> <string>1.0</string>
    <key>CFBundleVersion</key>         <string>1</string>
    <key>LSMinimumSystemVersion</key>  <string>13.0</string>
    <key>LSUIElement</key>             <true/>
    <key>NSHumanReadableCopyright</key><string>Personal tool</string>
</dict>
</plist>
PLIST

echo "→ ad-hoc codesign (stable identity for keychain access)"
codesign --force --sign - "$APP"

echo "✓ Built $(pwd)/$APP"

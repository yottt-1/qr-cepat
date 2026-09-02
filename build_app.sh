#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h}"
APP_DIR="$PROJECT_DIR/dist/QR Cepat.app"

cd "$PROJECT_DIR"
swift build -c release -Xswiftc -file-prefix-map -Xswiftc "$PROJECT_DIR=."
swiftc "$PROJECT_DIR/Sources/QRCepat/QRBrandArt.swift" \
    "$PROJECT_DIR/Scripts/GenerateIcon.swift" -o "$PROJECT_DIR/.build/generate-icon"
"$PROJECT_DIR/.build/generate-icon" "$PROJECT_DIR/Resources"
iconutil -c icns "$PROJECT_DIR/Resources/AppIcon.iconset" -o "$PROJECT_DIR/Resources/AppIcon.icns"

STAGING_DIR="$(mktemp -d "$PROJECT_DIR/.build/package.XXXXXX")"
CONTENTS_DIR="$STAGING_DIR/QR Cepat.app/Contents"
mkdir -p "$CONTENTS_DIR/MacOS" "$CONTENTS_DIR/Resources" "$PROJECT_DIR/dist"
cp "$PROJECT_DIR/.build/release/QRCepat" "$CONTENTS_DIR/MacOS/QRCepat"
cp "$PROJECT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$CONTENTS_DIR/Resources/AppIcon.icns"
cp "$PROJECT_DIR/LICENSE" "$CONTENTS_DIR/Resources/LICENSE"
chmod +x "$CONTENTS_DIR/MacOS/QRCepat"
strip -S "$CONTENTS_DIR/MacOS/QRCepat"
codesign --force --sign - "$STAGING_DIR/QR Cepat.app"
codesign --verify --deep --strict "$STAGING_DIR/QR Cepat.app"

# Preserve the previous bundle; do not overwrite a running executable in place.
if [[ -d "$APP_DIR" ]]; then
    mv "$APP_DIR" "$STAGING_DIR/previous.app"
fi
mv "$STAGING_DIR/QR Cepat.app" "$APP_DIR"

echo "Selesai: $APP_DIR"

#!/bin/zsh
set -euo pipefail
PROJECT_DIR="${0:A:h}"
cd "$PROJECT_DIR"
RELEASE_VERSION="${1:-v0.1.0-beta.1}"
if [[ ! "$RELEASE_VERSION" =~ '^v[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.]+)?$' ]]; then
    echo "Invalid version, expected e.g. v0.1.0-beta.1" >&2
    exit 1
fi
./test.sh
./build_app.sh
RELEASE_ARCH="$(uname -m)"
ARCHIVE_NAME="QR-Cepat-$RELEASE_VERSION-macOS-$RELEASE_ARCH.zip"
ditto -c -k --sequesterRsrc --keepParent "dist/QR Cepat.app" "dist/$ARCHIVE_NAME"
cd dist
shasum -a 256 "$ARCHIVE_NAME"

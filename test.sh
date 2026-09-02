#!/bin/zsh
set -euo pipefail
PROJECT_DIR="${0:A:h}"
cd "$PROJECT_DIR"
mkdir -p .build
swiftc -swift-version 6 -parse-as-library \
    Sources/QRCepat/QRRenderer.swift Sources/QRCepat/QRExport.swift \
    Sources/QRCepat/QRViewModel.swift Scripts/SmokeTests.swift \
    -o .build/qr-smoke-tests
.build/qr-smoke-tests

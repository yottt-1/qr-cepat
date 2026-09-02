#!/bin/zsh
set -euo pipefail
PROJECT_DIR="${0:A:h}"
cd "$PROJECT_DIR"
mkdir -p .build
swiftc -swift-version 6 -parse-as-library \
    Sources/QRCepat/QRRenderer.swift Sources/QRCepat/QRExport.swift \
    Sources/QRCepat/QRViewModel.swift Sources/QRCepat/QRBrandArt.swift \
    Sources/QRCepat/ContentView.swift Scripts/RenderDemo.swift \
    -o .build/render-demo
.build/render-demo "$PROJECT_DIR/docs"

// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "QRCepat",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "QRCepat", targets: ["QRCepat"])
    ],
    targets: [
        .executableTarget(name: "QRCepat")
    ]
)

import AppKit

@main
struct GenerateIcon {
    @MainActor
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            fatalError("Usage: generate-icon <output-directory>")
        }
        let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        let iconset = output.appendingPathComponent("AppIcon.iconset", isDirectory: true)
        try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

        for points in [16, 32, 128, 256, 512] {
            for scale in [1, 2] {
                let image = QRBrandArt.image(pixelSize: points * scale)
                guard let bitmap = image.representations.first as? NSBitmapImageRep,
                      let data = bitmap.representation(using: .png, properties: [:]) else {
                    fatalError("Could not render app icon")
                }
                let suffix = scale == 2 ? "@2x" : ""
                try data.write(to: iconset.appendingPathComponent("icon_\(points)x\(points)\(suffix).png"))
                if points == 256 && scale == 1 {
                    try data.write(to: output.appendingPathComponent("Logo-preview.png"))
                }
            }
        }
        print("Icon PNGs generated in \(iconset.path)")
    }
}

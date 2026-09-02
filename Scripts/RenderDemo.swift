import AppKit
import SwiftUI
import ImageIO
import UniformTypeIdentifiers

@main
struct RenderDemo {
    @MainActor
    static func main() async throws {
        guard CommandLine.arguments.count == 2 else { fatalError("Pass the output directory") }
        let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        NSApplication.shared.setActivationPolicy(.prohibited)
        let model = QRViewModel()

        func snapshot(_ name: String, scheme: ColorScheme = .light,
                      width: CGFloat = 980, height: CGFloat = 740) async throws -> CGImage {
            let root = ContentView()
                .environmentObject(model)
                .environment(\.colorScheme, scheme)
                .frame(width: width, height: height)
            let hosting = NSHostingView(rootView: root)
            let rect = NSRect(x: 0, y: 0, width: width, height: height)
            let window = NSWindow(contentRect: rect, styleMask: [.borderless], backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
            window.contentView = hosting
            hosting.frame = rect
            hosting.layoutSubtreeIfNeeded()
            try await Task.sleep(for: .milliseconds(350))
            hosting.displayIfNeeded()
            guard let bitmap = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else {
                fatalError("Could not create view bitmap")
            }
            hosting.cacheDisplay(in: hosting.bounds, to: bitmap)
            guard let data = bitmap.representation(using: .png, properties: [:]),
                  let cgImage = bitmap.cgImage else { fatalError("Snapshot failed") }
            try data.write(to: output.appendingPathComponent("\(name).png"))
            window.close()
            return cgImage
        }

        let first = try await snapshot("screenshot-light")
        _ = try await snapshot("screenshot-dark", scheme: .dark)
        model.content = "Halo Indonesia — café 日本語 😀"
        model.refresh()
        let second = try await snapshot("demo-unicode")
        model.foregroundColor = Color(red: 0.10, green: 0.14, blue: 0.35)
        model.backgroundColor = Color(red: 1, green: 0.97, blue: 0.89)
        model.pixelSize = 1024
        model.refresh()
        let third = try await snapshot("demo-color")
        model.foregroundColor = .white
        model.backgroundColor = .white
        model.refresh()
        _ = try await snapshot("qa-error-minimum", scheme: .dark, width: 860, height: 610)
        model.clear()
        model.refresh()
        _ = try await snapshot("qa-empty-minimum", width: 860, height: 610)

        let gifURL = output.appendingPathComponent("demo.gif")
        guard let destination = CGImageDestinationCreateWithURL(gifURL as CFURL, UTType.gif.identifier as CFString, 3, nil) else {
            fatalError("Could not create GIF")
        }
        CGImageDestinationSetProperties(destination, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
        for frame in [first, second, third] {
            CGImageDestinationAddImage(destination, frame, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 2.0]] as CFDictionary)
        }
        guard CGImageDestinationFinalize(destination) else { fatalError("GIF export failed") }
        print("Rendered app-view screenshots and demo GIF at \(output.path)")
    }
}

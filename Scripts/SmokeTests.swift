import AppKit
import SwiftUI
import Vision

struct TestFailure: Error, CustomStringConvertible {
    let description: String
}

@main
struct SmokeTests {
    @MainActor
    static func main() async throws {
        var checks = 0
        func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
            guard condition() else { throw TestFailure(description: message) }
            checks += 1
        }

        func render(_ text: String = "https://example.com", _ size: Int = 512,
                    _ correction: QRCorrectionLevel = .medium,
                    _ dark: NSColor = .black, _ light: NSColor = .white) throws -> RenderedQR {
            try QRRenderer.render(text: text, correction: correction, pixelSize: size,
                                  foreground: dark, background: light)
        }

        func decode(_ data: Data) throws -> String? {
            let request = VNDetectBarcodesRequest()
            request.symbologies = [.qr]
            try VNImageRequestHandler(data: data).perform([request])
            return request.results?.first?.payloadStringValue
        }

        let samples = [
            "https://example.com/qr?source=desktop&lang=id",
            "Halo, QR Cepat! Baris satu.\nBaris dua.",
            "Indonesia — café 日本語 😀",
            "WIFI:T:WPA;S:QR Demo;P:demo-password;;",
            "mailto:hello@example.com",
            "  whitespace preserved  "
        ]

        for text in samples {
            for size in [256, 512, 1024] {
                for correction in QRCorrectionLevel.allCases {
                    let qr = try render(text, size, correction)
                    guard let bitmap = NSBitmapImageRep(data: qr.pngData) else {
                        throw TestFailure(description: "PNG could not be read")
                    }
                    try expect(bitmap.pixelsWide == size && bitmap.pixelsHigh == size, "PNG size mismatch")
                    try expect(qr.quietZonePixels >= qr.pixelsPerModule * 4, "Quiet zone too narrow")
                    try expect(qr.pixelsPerModule >= 3, "Modules too small")
                    let decoded = try decode(qr.pngData)
                    try expect(decoded == text, "Round trip failed: \(size)/\(correction.rawValue), expected \(text), got \(decoded ?? "nil")")
                    for coordinate in [0, size / 2, size - 1] {
                        for (x, y) in [(coordinate, 0), (coordinate, size - 1), (0, coordinate), (size - 1, coordinate)] {
                            let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.sRGB)
                            try expect((color?.redComponent ?? 0) > 0.99, "Quiet zone is not clear")
                        }
                    }
                }
            }
        }

        let navy = NSColor(srgbRed: 0.10, green: 0.14, blue: 0.35, alpha: 1)
        let cream = NSColor(srgbRed: 1, green: 0.97, blue: 0.89, alpha: 1)
        let colored = try render("QR Cepat color test", 512, .high, navy, cream)
        let decodedColor = try decode(colored.pngData)
        try expect(decodedColor == "QR Cepat color test", "Colored QR decode failed")

        func rejects(_ description: String, expected: QRRenderError, _ operation: () throws -> RenderedQR) throws {
            do {
                _ = try operation()
                throw TestFailure(description: "Should reject \(description)")
            } catch let error as QRRenderError {
                try expect(error.localizedDescription == expected.localizedDescription, "Wrong rejection: \(description)")
            }
        }

        try rejects("empty", expected: .emptyContent) { try render("") }
        try rejects("oversized", expected: .contentTooLong) { try render(String(repeating: "x", count: 4000)) }
        try rejects("unicode byte overflow", expected: .contentTooLong) { try render(String(repeating: "😀", count: 1000)) }
        try rejects("bad size", expected: .invalidSize) { try render("hi", -1) }
        try rejects("same colors", expected: .lowContrast) { try render("hi", 512, .medium, .white, .white) }
        try rejects("inverted colors", expected: .lowContrast) { try render("hi", 512, .medium, .white, .black) }
        try rejects("low contrast", expected: .lowContrast) { try render("hi", 512, .medium, .lightGray, .white) }
        try rejects("transparent", expected: .lowContrast) { try render("hi", 512, .medium, .black.withAlphaComponent(0.5), .white) }
        try rejects("dense small PNG", expected: .resolutionTooSmall) { try render(String(repeating: "x", count: 1000), 256, .high) }
        let longText = String(repeating: "x", count: 1000)
        let large = try render(longText, 1024, .high)
        let decodedLarge = try decode(large.pngData)
        try expect(decodedLarge == longText, "Large QR round trip failed")

        // Use an isolated pasteboard; never overwrite the tester's clipboard.
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }
        try expect(QRExport.copy(colored, to: pasteboard), "Clipboard write failed")
        try expect(pasteboard.data(forType: .png) == colored.pngData, "Clipboard PNG mismatch")
        try expect(pasteboard.data(forType: .tiff) != nil, "Clipboard TIFF fallback missing")

        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent("qr-cepat-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporary) }
        let output = temporary.appendingPathComponent("QR.png")
        try QRExport.save(colored, to: output)
        let saved = try Data(contentsOf: output)
        try expect(saved == colored.pngData, "Saved PNG mismatch")
        do {
            try QRExport.save(colored, to: temporary.appendingPathComponent("missing/QR.png"))
            throw TestFailure(description: "Writing to a missing directory should fail")
        } catch is CocoaError {
            checks += 1
        }

        let model = QRViewModel()
        try expect(model.renderedQR != nil, "Initial preview missing")
        model.content = "new payload"
        try expect(model.renderedQR == nil && model.isRendering, "Stale export remains enabled")
        model.content = "latest payload"
        try await Task.sleep(for: .milliseconds(350))
        guard let latest = model.renderedQR else { throw TestFailure(description: "Debounced preview missing") }
        let decodedLatest = try decode(latest.pngData)
        try expect(decodedLatest == "latest payload", "Debounce used stale payload")
        model.foregroundColor = .white
        model.refresh()
        try expect(model.renderedQR == nil && model.errorMessage != nil && model.canResetColors, "Invalid color preview not cleared")
        model.resetColors()
        model.refresh()
        try expect(model.renderedQR != nil && model.errorMessage == nil && !model.canResetColors, "Reset did not recover")
        model.clear()
        model.refresh()
        try expect(model.renderedQR == nil && model.errorMessage == nil, "Empty state is incorrect")

        print("PASS: \(checks) assertions, 74 QR decode round trips, export and model lifecycle checks.")
    }
}

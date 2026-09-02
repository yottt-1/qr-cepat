import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins

enum QRCorrectionLevel: String, CaseIterable, Identifiable {
    case low = "L"
    case medium = "M"
    case quartile = "Q"
    case high = "H"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low: "Rendah"
        case .medium: "Sedang"
        case .quartile: "Tinggi"
        case .high: "Maks"
        }
    }
}

enum QRRenderError: LocalizedError {
    case emptyContent
    case contentTooLong
    case renderFailed
    case pngEncodingFailed
    case invalidSize
    case lowContrast
    case resolutionTooSmall

    var errorDescription: String? {
        switch self {
        case .emptyContent:
            "Masukkan teks atau tautan terlebih dahulu."
        case .contentTooLong:
            "Isi terlalu panjang untuk dibuat menjadi QR. Coba ringkas teksnya."
        case .renderFailed:
            "QR tidak dapat dirender. Coba ubah isinya."
        case .pngEncodingFailed:
            "Gambar PNG tidak dapat dibuat."
        case .invalidSize:
            "Pilih ukuran PNG 256, 512, atau 1024 px."
        case .lowContrast:
            "Gunakan QR gelap dengan latar terang dan kontras tinggi. Klik Reset untuk hitam-putih."
        case .resolutionTooSmall:
            "Isi terlalu padat untuk ukuran ini. Pilih PNG lebih besar atau ringkas teksnya."
        }
    }
}

struct RenderedQR {
    let image: NSImage
    let pngData: Data
    let pixelSize: Int
    let pixelsPerModule: Int
    let quietZonePixels: Int
}

@MainActor
enum QRRenderer {
    private static let context = CIContext()

    static func render(
        text: String,
        correction: QRCorrectionLevel,
        pixelSize: Int,
        foreground: NSColor,
        background: NSColor
    ) throws -> RenderedQR {
        guard !text.isEmpty else { throw QRRenderError.emptyContent }
        guard [256, 512, 1024].contains(pixelSize) else { throw QRRenderError.invalidSize }
        let data = Data(text.utf8)
        guard data.count <= 2953 else { throw QRRenderError.contentTooLong }
        let dark = normalized(foreground)
        let light = normalized(background)
        let darkLuminance = luminance(dark)
        let lightLuminance = luminance(light)
        // Conservative product guard, not a promise that every scanner will succeed.
        guard dark.alphaComponent >= 0.999, light.alphaComponent >= 0.999,
              lightLuminance > darkLuminance,
              (lightLuminance + 0.05) / (darkLuminance + 0.05) >= 4.5 else {
            throw QRRenderError.lowContrast
        }

        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = correction.rawValue

        guard let qrImage = filter.outputImage else {
            throw QRRenderError.contentTooLong
        }
        // Add four clear modules on every side, in addition to any Core Image margin.
        // Integer scaling preserves evenly sized modules without interpolation.
        let modules = Int(qrImage.extent.width)
        let scale = pixelSize / (modules + 8)
        guard scale >= 3 else { throw QRRenderError.resolutionTooSmall }
        let drawingSize = modules * scale
        let inset = (pixelSize - drawingSize) / 2

        guard let foregroundCI = CIColor(color: normalized(foreground)),
              let backgroundCI = CIColor(color: normalized(background)) else {
            throw QRRenderError.renderFailed
        }

        let colorFilter = CIFilter.falseColor()
        colorFilter.inputImage = qrImage
        colorFilter.color0 = foregroundCI
        colorFilter.color1 = backgroundCI

        guard let coloredImage = colorFilter.outputImage,
              let baseCGImage = context.createCGImage(coloredImage, from: coloredImage.extent) else {
            throw QRRenderError.renderFailed
        }

        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelSize,
            pixelsHigh: pixelSize,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw QRRenderError.renderFailed
        }

        let sourceImage = NSImage(
            cgImage: baseCGImage,
            size: NSSize(width: baseCGImage.width, height: baseCGImage.height)
        )

        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }

        guard let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
            throw QRRenderError.renderFailed
        }

        NSGraphicsContext.current = graphicsContext
        graphicsContext.imageInterpolation = .none
        light.setFill()
        NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize).fill()
        sourceImage.draw(
            in: NSRect(x: inset, y: inset, width: drawingSize, height: drawingSize),
            from: .zero,
            operation: .copy,
            fraction: 1
        )
        graphicsContext.flushGraphics()

        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw QRRenderError.pngEncodingFailed
        }

        let finalImage = NSImage(size: NSSize(width: pixelSize, height: pixelSize))
        finalImage.addRepresentation(bitmap)
        return RenderedQR(image: finalImage, pngData: pngData, pixelSize: pixelSize,
                          pixelsPerModule: scale, quietZonePixels: inset)
    }

    private static func normalized(_ color: NSColor) -> NSColor {
        color.usingColorSpace(.sRGB) ?? .black
    }

    private static func luminance(_ color: NSColor) -> Double {
        func linear(_ value: CGFloat) -> Double {
            let value = Double(value)
            return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(color.redComponent)
            + 0.7152 * linear(color.greenComponent)
            + 0.0722 * linear(color.blueComponent)
    }
}

import AppKit

/// Shared vector artwork for the app icon and in-app identity.
/// The mark is decorative, not a scannable QR code.
@MainActor
enum QRBrandArt {
    static let headerImage = image(pixelSize: 128)

    static func image(pixelSize: Int) -> NSImage {
        let bitmap = NSBitmapImageRep(
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
        )!
        let graphics = NSGraphicsContext(bitmapImageRep: bitmap)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphics
        let context = graphics.cgContext
        context.clear(CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize))
        let scale = CGFloat(pixelSize) / 1024
        context.scaleBy(x: scale, y: scale)
        drawMark()
        NSGraphicsContext.restoreGraphicsState()

        let result = NSImage(size: NSSize(width: pixelSize, height: pixelSize))
        result.addRepresentation(bitmap)
        return result
    }

    private static func drawMark() {
        let tile = NSBezierPath(
            roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824),
            xRadius: 184, yRadius: 184
        )

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor(calibratedRed: 0.12, green: 0.08, blue: 0.34, alpha: 0.32)
        shadow.shadowOffset = NSSize(width: 0, height: -14)
        shadow.shadowBlurRadius = 24
        shadow.set()
        NSColor(calibratedRed: 0.30, green: 0.21, blue: 0.78, alpha: 1).setFill()
        tile.fill()
        NSGraphicsContext.restoreGraphicsState()

        NSGradient(colors: [
            NSColor(calibratedRed: 0.26, green: 0.16, blue: 0.72, alpha: 1),
            NSColor(calibratedRed: 0.37, green: 0.32, blue: 0.94, alpha: 1),
            NSColor(calibratedRed: 0.55, green: 0.47, blue: 1, alpha: 1)
        ])!.draw(in: tile, angle: 135)

        let highlight = NSBezierPath(
            roundedRect: NSRect(x: 102, y: 102, width: 820, height: 820),
            xRadius: 182, yRadius: 182
        )
        NSColor.white.withAlphaComponent(0.20).setStroke()
        highlight.lineWidth = 3
        highlight.stroke()

        finder(x: 236, y: 566)
        finder(x: 566, y: 566)
        finder(x: 236, y: 236)

        // A bold lightning bolt makes the fourth quadrant distinct at Dock size.
        let bolt = NSBezierPath()
        bolt.move(to: NSPoint(x: 695, y: 487))
        bolt.line(to: NSPoint(x: 550, y: 326))
        bolt.line(to: NSPoint(x: 648, y: 326))
        bolt.line(to: NSPoint(x: 612, y: 214))
        bolt.line(to: NSPoint(x: 798, y: 397))
        bolt.line(to: NSPoint(x: 701, y: 397))
        bolt.line(to: NSPoint(x: 749, y: 487))
        bolt.close()
        NSColor(calibratedRed: 0.82, green: 1, blue: 0.42, alpha: 1).setFill()
        bolt.fill()
    }

    private static func finder(x: CGFloat, y: CGFloat) {
        let ring = NSBezierPath(
            roundedRect: NSRect(x: x, y: y, width: 222, height: 222),
            xRadius: 44, yRadius: 44
        )
        ring.append(NSBezierPath(
            roundedRect: NSRect(x: x + 45, y: y + 45, width: 132, height: 132),
            xRadius: 17, yRadius: 17
        ))
        ring.windingRule = .evenOdd
        NSColor.white.setFill()
        ring.fill()

        NSBezierPath(
            roundedRect: NSRect(x: x + 86, y: y + 86, width: 50, height: 50),
            xRadius: 9, yRadius: 9
        ).fill()
    }
}

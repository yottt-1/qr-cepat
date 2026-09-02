import AppKit

@MainActor
enum QRExport {
    static func copy(_ qr: RenderedQR, to pasteboard: NSPasteboard) -> Bool {
        let item = NSPasteboardItem()
        guard item.setData(qr.pngData, forType: .png) else { return false }
        if let tiff = qr.image.tiffRepresentation {
            item.setData(tiff, forType: .tiff)
        }
        pasteboard.clearContents()
        return pasteboard.writeObjects([item])
    }

    static func save(_ qr: RenderedQR, to url: URL) throws {
        try qr.pngData.write(to: url, options: .atomic)
    }
}

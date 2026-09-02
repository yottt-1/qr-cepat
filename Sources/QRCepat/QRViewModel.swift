import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class QRViewModel: ObservableObject {
    @Published var content = "https://example.com" {
        didSet { scheduleRefresh() }
    }
    @Published var correction: QRCorrectionLevel = .medium {
        didSet { scheduleRefresh() }
    }
    @Published var pixelSize = 512 {
        didSet { scheduleRefresh() }
    }
    @Published var foregroundColor: Color = .black {
        didSet { scheduleRefresh() }
    }
    @Published var backgroundColor: Color = .white {
        didSet { scheduleRefresh() }
    }

    @Published private(set) var renderedQR: RenderedQR?
    @Published private(set) var errorMessage: String?
    @Published private(set) var canResetColors = false
    @Published var toastMessage: String?
    @Published var operationError: String?
    @Published private(set) var isRendering = false
    private var renderTask: Task<Void, Never>?
    private var toastTask: Task<Void, Never>?

    init() {
        refresh()
    }

    var characterCount: Int { content.count }

    private func scheduleRefresh() {
        renderTask?.cancel()
        renderedQR = nil // Never allow exporting a stale preview while input changes.
        errorMessage = nil
        canResetColors = false
        isRendering = !content.isEmpty
        renderTask = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(120)) } catch { return }
            guard !Task.isCancelled else { return }
            self?.refresh()
        }
    }

    func refresh() {
        renderTask?.cancel()
        isRendering = false
        canResetColors = false
        guard !content.isEmpty else {
            renderedQR = nil
            errorMessage = nil
            return
        }

        do {
            renderedQR = try QRRenderer.render(
                text: content,
                correction: correction,
                pixelSize: pixelSize,
                foreground: NSColor(foregroundColor),
                background: NSColor(backgroundColor)
            )
            errorMessage = nil
        } catch {
            renderedQR = nil
            errorMessage = error.localizedDescription
            if case QRRenderError.lowContrast = error {
                canResetColors = true
            }
        }
    }

    func clear() {
        content = ""
    }

    func resetColors() {
        foregroundColor = .black
        backgroundColor = .white
    }

    func copyToClipboard() {
        guard let renderedQR else { return }
        if QRExport.copy(renderedQR, to: .general) {
            showToast("QR disalin ke clipboard")
        } else {
            operationError = "Clipboard tidak tersedia. Coba lagi atau simpan PNG."
        }
    }

    func savePNG() {
        guard let renderedQR else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "QR-Cepat.png"
        panel.title = "Simpan QR sebagai PNG"
        panel.prompt = "Simpan"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try QRExport.save(renderedQR, to: url)
            showToast("PNG berhasil disimpan")
        } catch {
            operationError = "File tidak dapat disimpan: \(error.localizedDescription)"
        }
    }

    private func showToast(_ message: String) {
        toastMessage = message
        toastTask?.cancel()
        toastTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(2.5)) } catch { return }
            self?.toastMessage = nil
        }
    }
}

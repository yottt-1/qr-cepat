import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: QRViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var editorFocused: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Divider()
                mainContent
            }

            if let toast = model.toastMessage {
                ToastView(message: toast)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: model.toastMessage)
        .frame(minWidth: 860, minHeight: 610)
        .onAppear { editorFocused = true }
        .alert("Tindakan gagal", isPresented: Binding(
            get: { model.operationError != nil },
            set: { if !$0 { model.operationError = nil } }
        )) {
            Button("OK", role: .cancel) { model.operationError = nil }
        } message: {
            Text(model.operationError ?? "Coba lagi.")
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(nsImage: QRBrandArt.headerImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 52, height: 52)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("QR Cepat")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                Text("Generator QR lokal untuk Mac")
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Label("100% offline", systemImage: "lock.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppColors.success)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(AppColors.success.opacity(0.1), in: Capsule())
                .accessibilityLabel("Seratus persen offline")
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .background(AppColors.surface)
    }

    private var mainContent: some View {
        HStack(alignment: .top, spacing: 24) {
            editorPanel
                .frame(minWidth: 340, idealWidth: 390, maxWidth: 430)
            previewPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(28)
    }

    private var editorPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Isi QR")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Text("\(model.characterCount) karakter")
                            .font(.system(size: 11.5, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Button(action: model.clear) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .disabled(model.content.isEmpty)
                        .accessibilityLabel("Kosongkan isi")
                    }

                    Group {
                        TextEditor(text: $model.content)
                            .font(.system(size: 15))
                            .focused($editorFocused)
                            .scrollContentBackground(.hidden)
                            .padding(10)
                            .frame(minHeight: 150)
                            .background(AppColors.input, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(editorFocused ? AppColors.accent : AppColors.border, lineWidth: editorFocused ? 2 : 1)
                            }
                            .accessibilityLabel("Teks atau tautan untuk QR")

                    }

                    Text("Tautan, teks, nomor telepon, atau data lainnya.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                    if let error = model.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.danger)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Ketahanan QR")
                        .font(.system(size: 13, weight: .semibold))
                    Picker("Ketahanan QR", selection: $model.correction) {
                        ForEach(QRCorrectionLevel.allCases) { level in
                            Text(level.title).tag(level)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    Text("Membantu saat QR rusak; tingkat tinggi membuat pola lebih padat.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Ukuran PNG")
                        .font(.system(size: 13, weight: .semibold))
                    Picker("Ukuran PNG", selection: $model.pixelSize) {
                        Text("256 px").tag(256)
                        Text("512 px").tag(512)
                        Text("1024 px").tag(1024)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Warna")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Button("Reset", action: model.resetColors)
                            .buttonStyle(.plain)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppColors.accentText)
                    }

                    HStack(spacing: 12) {
                        ColorPicker("QR", selection: $model.foregroundColor, supportsOpacity: false)
                            .padding(.horizontal, 12)
                            .frame(height: 44)
                            .background(AppColors.input, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        ColorPicker("Latar", selection: $model.backgroundColor, supportsOpacity: false)
                            .padding(.horizontal, 12)
                            .frame(height: 44)
                            .background(AppColors.input, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    Text("QR gelap, latar terang. Selalu coba pindai sebelum dibagikan.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
        }
        .scrollIndicators(.visible)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppColors.border, lineWidth: 1)
        }
    }

    private var previewPanel: some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Pratinjau")
                        .font(.system(size: 15, weight: .semibold))
                    Text(model.isRendering ? "Membuat QR…" : model.renderedQR == nil ? "Belum siap" : "Siap diekspor • \(model.pixelSize) × \(model.pixelSize) px")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if model.renderedQR != nil {
                    Label("Siap", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.success)
                }
            }

            Group {
                if let rendered = model.renderedQR {
                    Image(nsImage: rendered.image)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .accessibilityLabel("Pratinjau kode QR")
                        .padding(28)
                } else if model.isRendering {
                    ProgressView("Membuat QR…")
                } else {
                    VStack(spacing: 14) {
                        Image(systemName: model.errorMessage == nil ? "qrcode" : "exclamationmark.triangle")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(model.errorMessage == nil ? Color.secondary : AppColors.danger)
                            .accessibilityHidden(true)
                        Text(model.errorMessage ?? "Masukkan teks untuk membuat QR")
                            .font(.system(size: 14, weight: .medium))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(model.errorMessage == nil ? Color.secondary : AppColors.danger)
                            .frame(maxWidth: 280)
                        if model.canResetColors {
                            Button("Reset warna", action: model.resetColors)
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.preview, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppColors.border, lineWidth: 1)
            }

            HStack(spacing: 12) {
                Button(action: model.copyToClipboard) {
                    Label("Salin", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(model.renderedQR == nil)
                .keyboardShortcut("c", modifiers: [.command, .shift])

                Button(action: model.savePNG) {
                    Label("Simpan PNG", systemImage: "arrow.down.to.line")
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(model.renderedQR == nil)
                .keyboardShortcut("s", modifiers: .command)
            }
        }
        .padding(20)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppColors.border, lineWidth: 1)
        }
    }
}

private struct ToastView: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "checkmark.circle.fill")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .frame(height: 42)
            .background(Color.black.opacity(0.84), in: Capsule())
            .shadow(color: .black.opacity(0.18), radius: 16, y: 6)
            .accessibilityAddTraits(.isStaticText)
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13.5, weight: .semibold))
            .foregroundStyle(.white)
            .background(AppColors.accent.opacity(configuration.isPressed ? 0.82 : 1), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .contentShape(Rectangle())
            .opacity(isEnabled ? 1 : 0.45)
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13.5, weight: .semibold))
            .foregroundStyle(.primary)
            .background(AppColors.input.opacity(configuration.isPressed ? 0.7 : 1), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(AppColors.border, lineWidth: 1)
            }
            .contentShape(Rectangle())
            .opacity(isEnabled ? 1 : 0.45)
    }
}

enum AppColors {
    static let accent = Color(red: 0.31, green: 0.27, blue: 0.90)
    static let accentText = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.69, green: 0.65, blue: 1, alpha: 1)
            : NSColor(red: 0.31, green: 0.27, blue: 0.90, alpha: 1)
    })
    static let success = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.40, green: 0.85, blue: 0.61, alpha: 1)
            : NSColor(red: 0.04, green: 0.42, blue: 0.23, alpha: 1)
    })
    static let danger = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 1, green: 0.54, blue: 0.54, alpha: 1)
            : NSColor(red: 0.75, green: 0.12, blue: 0.16, alpha: 1)
    })
    static let canvas = Color(nsColor: .windowBackgroundColor)
    static let surface = Color(nsColor: .controlBackgroundColor)
    static let input = Color(nsColor: .textBackgroundColor)
    static let preview = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.15, green: 0.15, blue: 0.17, alpha: 1)
            : NSColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1)
    })
    static let border = Color(nsColor: .separatorColor)
}

import SwiftUI

@main
struct QRCepatApp: App {
    @StateObject private var model = QRViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
        .defaultSize(width: 980, height: 700)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) { }

            CommandGroup(after: .pasteboard) {
                Button("Salin QR") {
                    model.copyToClipboard()
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(model.renderedQR == nil)
            }
        }
    }
}

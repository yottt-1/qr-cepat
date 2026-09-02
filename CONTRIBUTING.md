# Contributing / Berkontribusi

Small, focused contributions are welcome. Open an issue before major features or
architecture changes. Indonesian and English reports are welcome.

1. Fork/clone and use Swift 6 with a macOS SDK.
2. Run `./test.sh` and `./build_app.sh`.
3. Keep processing offline. Do not introduce analytics, uploads, or remote redirects.
4. For renderer changes, add decode round-trip and failure-path tests.
5. For UI changes, check light/dark, minimum window size, keyboard navigation,
   reduced motion, and VoiceOver. State which checks you actually performed.
6. Submit a focused PR with test evidence and screenshots where relevant.

Use synthetic inputs (`example.com`, demo Wi-Fi credentials), never real secrets.
Contributions are under MIT; submit only material you have permission to share.

The app has no network layer or third-party runtime packages. SwiftUI/AppKit
provide the UI, Core Image creates QR symbols, and Vision is used only in tests.

Security-sensitive reports: do not post live credentials or private data in a
public issue. Ask for a private reporting route using a non-sensitive issue first.

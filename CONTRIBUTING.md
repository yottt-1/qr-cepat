# Contributing / Berkontribusi

Small, focused contributions are welcome. Open an issue before major features or
architecture changes. Indonesian and English reports are welcome.

1. Fork/clone. Mac uses Swift 6 and a macOS SDK; Windows uses the .NET 10 SDK.
2. Mac: `./test.sh` and `./build_app.sh`. Windows:
   `dotnet run --project Windows/QRCepat.Tests -c Release`, then
   `./Windows/package.ps1` in PowerShell. See [Windows checks](docs/WINDOWS.md).
3. Keep processing offline. Do not introduce analytics, uploads, or remote redirects.
4. For renderer changes, add decode round-trip and failure-path tests.
5. For UI changes, check light/dark, minimum window size, keyboard navigation,
   reduced motion, and VoiceOver. State which checks you actually performed.
6. Submit a focused PR with test evidence and screenshots where relevant.

Use synthetic inputs (`example.com`, demo Wi-Fi credentials), never real secrets.
Contributions are under MIT; submit only material you have permission to share.

The apps have no network layer. Mac uses SwiftUI/AppKit and Core Image with
Vision only in tests. Windows uses WPF and the MIT-licensed QRCoder package;
ZXing.Net is used only in tests. Commit NuGet lockfiles and retain third-party notices.

Security-sensitive reports: do not post live credentials or private data in a
public issue. Ask for a private reporting route using a non-sensitive issue first.

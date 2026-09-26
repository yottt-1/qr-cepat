# QR Cepat for Windows — 0.2.0-beta.1

## Install / Instalasi

Open a successful [Windows workflow run](https://github.com/yottt-1/qr-cepat/actions/workflows/windows.yml)
and download the QR-Cepat-Windows-x64 artifact (GitHub login required).
Download the Windows x64 ZIP inside it, extract all files to a folder, and open
**QR Cepat.exe**. No installer, administrator permission, or separate .NET
installation is needed. The runtime is bundled with the executable.

Target systems: Windows 10 22H2 and Windows 11, Intel/AMD x64. This beta does
not provide a native ARM64 build. The executable is not Authenticode-signed;
SmartScreen may warn about an unknown publisher. Do not globally disable
Windows protections. Use the official repository and verify the checksum.

In PowerShell, compare this result with the matching SHA256SUMS-Windows file:

```powershell
Get-FileHash .\QR-Cepat-v0.2.0-beta.1-Windows-x64.zip -Algorithm SHA256
```

## Use

Paste text or a link into **Isi QR**. Your text is encoded exactly, including
whitespace and Unicode. Pick error correction and PNG dimensions, optionally
edit the foreground/background hex colors, then copy or save.

| Action | Windows |
| --- | --- |
| Save PNG | Simpan PNG / Ctrl+S |
| Copy image | Salin / Ctrl+Shift+C |
| Reset colors | Reset warna |
| Clear input | Kosongkan |
| Change colors | Hex values, e.g. #211C66 and #FFFFFF |

Exports have a minimum four-module quiet zone, at least three pixels per module,
and no interpolated module edges. The 4.5:1 contrast threshold is a conservative
app rule; always scan the finished image before distributing or printing it.
No QR input, history, analytics, or network requests are saved or sent by the app.
Windows clipboard history/sync and explicitly saved files are outside that scope.

## Build and verify

Install the .NET 10 SDK. From the repository root:

```powershell
dotnet restore Windows/QRCepat.Tests --locked-mode
dotnet run --project Windows/QRCepat.Tests -c Release --no-restore
dotnet build Windows/QRCepat.Windows -c Release
./Windows/package.ps1
```

The ZIP and checksum are written to dist/. The icon is packaged from the
existing QR Cepat artwork. Its reproducible ICO helper accepts a 256 × 256 PNG.

The Windows CI workflow runs the independent decoder tests, publishes a
self-contained x64 executable, then launches that exact executable with
an explicit self-test argument on an isolated runner. It checks the live
preview, stale-export prevention, clipboard formats, PNG decode, invalid-color
recovery, size changes, empty state, and minimum-window controls, and captures
light/dark screenshots. QA artifacts are uploaded separately from the app.
An independent Windows decoder then reads the saved PNG and all five screenshots
to check that the displayed QR is present and decodes to the expected content.
CI captures use software rendering for reproducible headless screenshots.

Renderer tests also run on macOS/Linux with .NET 10. WPF execution, clipboard,
and the save dialog require Windows; cross-compilation alone cannot verify them.

## Verification limits

The Windows renderer passes 73 independent ZXing decode round-trips with URL,
Unicode, whitespace, all three sizes, all four correction levels, and custom
colors. Tests also validate PNG chunks/pixels, quiet zones, invalid input, and
recovery from a QR too dense for the smallest size.

Windows 10/11 consumer-device installation, phone scanning, actual printing,
Narrator, high contrast, real per-monitor DPI changes, and clipboard pasting into
different third-party applications still require beta testing. A 2x off-screen
render checks image scaling, not an actual display DPI switch.

## Dependencies

WPF/.NET 10 and QRCoder 1.8.0 run locally. ZXing.Net 0.16.11 is test-only.
NuGet lockfiles pin the dependency graph. Review THIRD-PARTY-NOTICES.txt in
the download. Keep self-contained runtimes updated when shipping new releases.

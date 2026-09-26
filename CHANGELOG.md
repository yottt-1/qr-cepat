# Changelog

## 0.2.0-beta.1 — Windows preview

- Adds a native Windows x64 WPF app with the existing QR Cepat branding.
- Offline live preview, four correction levels, editable hex colors, and exact
  256/512/1024 px PNG output with integer scaling and clear margins.
- Native PNG save dialog, PNG/bitmap clipboard, Ctrl+S and Ctrl+Shift+C.
- Invalidates pending previews immediately so stale QR images cannot be exported.
- Portable self-contained ZIP with bundled .NET 10 runtime and SHA-256 checksum.
- Independent ZXing decode tests and Windows CI tests of the packaged executable.
- macOS app remains at 0.1.0-beta.1; no Linux release.

Windows beta is unsigned. Physical phone scanning, Narrator, and real Windows
10/11 device/DPI checks remain user beta-validation tasks.

## 0.1.0-beta.1

First public macOS beta, Apple Silicon download.

- Native offline QR generation, PNG export, and PNG/TIFF clipboard support.
- Original app icon and light/dark interface.
- Integer-scaled modules, explicit quiet zones, and contrast/density guards.
- Debounced preview updates with stale-export prevention.
- Separate save/copy error dialogs and visible disabled buttons.
- Standalone Swift/Vision smoke tests and macOS CI checks.
- English/Indonesian documentation, MIT license, beta feedback templates.

Limitations: Indonesian UI, PNG-only export, no scanner/batch processing or
structured Wi-Fi/contact editor. Ad-hoc signed, not notarized. No Windows/Linux
support or Intel runtime verification.

# Roadmap

## Before a stable Mac release

- Gather feedback from 10–20 real volunteers; fix installation and scan failures.
- Test physical prints, multiple phone scanners, older supported macOS versions,
  VoiceOver, keyboard-only use, and reduced motion on real devices.
- Obtain maintainer-provided Developer ID signing and Apple notarization.
- Decide on English UI localization based on feedback.

## Candidate features — not promises

- Dedicated Wi-Fi/contact forms.
- Menu-bar access and a user-configurable shortcut.
- Reading QR from images/clipboard.
- SVG/batch export if actual workflows need them.

## Platforms

Windows x64 now has a separate native WPF edition, requested after the initial
Mac beta. Its portable build includes .NET and uses QRCoder for offline encoding.
Validate installation, phone scanning, clipboard interoperability, Narrator,
high contrast, and real per-monitor DPI on Windows 10/11 devices.

Linux remains deferred. Windows ARM64 and Intel Mac downloads require their own
runtime testing before they are advertised as supported. Mac stays on
SwiftUI/AppKit/Core Image.

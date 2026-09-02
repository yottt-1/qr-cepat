# QR Cepat 0.1.0-beta.1

First public beta: a small offline QR utility for **macOS 13+ on Apple Silicon**.

## Download

- `QR-Cepat-v0.1.0-beta.1-macOS-arm64.zip`: unzip and drag QR Cepat.app to Applications.
- `SHA256SUMS`: verify archive integrity with `shasum -a 256 -c SHA256SUMS`.

**Security notice:** ad-hoc signed, **not Apple-notarized**. macOS may block this
beta; a checksum is not a safety endorsement. Read the README and
[Apple's safe-opening guidance](https://support.apple.com/en-gb/102445), or review
and build from source. Do not disable Gatekeeper globally.

## Included

- Offline live generation, PNG export, and PNG/TIFF clipboard copy.
- Three sizes, four correction levels, custom colors.
- Quiet zones, integer module scaling, contrast/density guards.
- Native light/dark UI, clear error recovery, debounced preview.
- MIT license, English/Indonesian guides, screenshots, and demo GIF.

Local checks passed: 1,174 assertions and 74 QR decode cases, plus export/model
checks. See [verification notes](https://github.com/yottt-1/qr-cepat/blob/main/docs/VERIFICATION.md).

## Known limits

Indonesian UI. No SVG, batch generator, scanner, or structured Wi-Fi/contact
forms. No Windows/Linux support or Intel runtime verification. Physical printing,
phone cameras, older macOS versions, and assistive technology still need testers.

## Help test / Bantu uji

Seeking 10–20 volunteer Mac users; no adoption numbers are claimed.
[Five-minute test guide](https://github.com/yottt-1/qr-cepat/blob/main/docs/BETA.md)
and [feedback form](https://github.com/yottt-1/qr-cepat/issues/new?template=beta-feedback.yml).
Public reports must not include sensitive QR data, passwords, tokens, or private URLs.

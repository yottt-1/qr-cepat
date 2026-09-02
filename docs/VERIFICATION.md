# Verification record — 0.1.0-beta.1

## Local environment

- macOS 26.5.2 (25F84), Apple Silicon arm64.
- Apple Swift 6.3.3, Command Line Tools macOS SDK.
- Deployment target: macOS 13; this is not evidence of execution on macOS 13.

## Automated checks

`./test.sh`: **1,174 assertions passed**, including:

- 72 QR PNG decode cases: six payloads × three sizes × four correction levels.
- Two additional decode cases: custom navy/cream colors and a dense 1,000-byte payload.
- Exact PNG dimensions, clear image edges, >=4-module margin, integer scaling.
- URL, multiline text, Unicode, emoji, Wi-Fi syntax, mailto, and preserved whitespace.
- Empty/oversized/invalid-size input, transparent or low-contrast/inverted colors,
  and insufficient resolution rejected with recoverable errors.
- PNG/TIFF copying on an isolated pasteboard (not the user's clipboard).
- File export byte integrity and missing-directory failure.
- Debounced input, stale-export prevention, latest payload decoding, color reset,
  and empty-state recovery.

The test uses Apple Vision as a decoder, separately from Core Image generation.
This is software round-trip verification, not proof that every phone or print
layout will scan correctly.

## Build and visual checks

- Production build and ad-hoc code-signature verification.
- ZIP archive integrity, SHA-256 checksum, and macOS minimum-target inspection.
- Native app-view snapshots in light/dark at 980 × 740 points.
- Empty/error layouts at the minimum 860 × 610 points; the editor scrolls and
  the preview keeps export actions visible. Color-error recovery is available
  directly in the preview.
- Demo GIF generated from three actual app-view states, not a screen recording.

Reproduce screenshots with `./render-demo.sh`.

## Still needs real-device testing

- Mac hardware/OS combinations other than the local environment above.
- Phone-camera scanning, printing at different physical sizes, and real workflows.
- VoiceOver, keyboard-only interaction, and system Reduce Motion behavior.
- Interactive native save-dialog cancellation and clipboard behavior in each
  destination app. Underlying write/copy logic is automated, those UI flows are not.
- Gatekeeper behavior on a fresh downloaded copy. This beta is not Apple-notarized.
- Intel, Windows, and Linux. No runtime support claims for those platforms.

The macOS CI workflow repeats the core checks on GitHub's selected runner;
consult its actual run result rather than assuming it passed.

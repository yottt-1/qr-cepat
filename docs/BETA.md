# Five-minute beta test / Uji beta lima menit

**Recruitment target: 10–20 volunteers. No participants or responses are claimed yet.**

Need: Apple Silicon Mac with macOS 13+, and optionally a phone camera.
Get the [beta release](https://github.com/yottt-1/qr-cepat/releases) and read the
signing/security notice in the README before installing.

## Tasks / Tugas

1. **Install / Instal:** unzip, drag to Applications, and launch. Report any macOS
   warning or failure. Do not disable system security.
2. **Generate / Buat:** paste `https://example.com`, save 512 px PNG, then scan it
   with a phone. Verify the destination before opening it.
3. **Copy / Salin:** press ⌘⇧C and paste into an image-capable app such as Notes.
4. **Recover / Pulihkan:** choose white QR on white background. Export should be
   unavailable and an error should explain recovery. Click Reset and retry.
5. **Repeat / Ulangi:** try 256/1024 px, another correction level, light/dark mode,
   and this safe sample: `Halo Indonesia — café 日本語 😀`.

Optional: test a physical print, keyboard-only navigation, VoiceOver, and Reduce
Motion. State "not tested" for anything you did not try.

## Feedback

[Submit beta feedback / Kirim feedback](https://github.com/yottt-1/qr-cepat/issues/new?template=beta-feedback.yml).
A GitHub account is needed. Installation failures are useful feedback too.
Reports are public: never submit passwords, tokens, private URLs, customer data,
or sensitive QR images. Use sample data and redact screenshots.

Three questions matter most:

- Did you create and scan your first QR without help?
- Would you use this again instead of your current tool? Why?
- What single missing feature would change that answer?

## Maintainer evaluation plan

Record only voluntary feedback and aggregate counts, not private contact details.
After at least ten real responses, review installation success, scan success,
repeat-use intent, and recurring problems. No telemetry is added to the app.
Fix install/scan failures before expanding platform support. Do not infer demand
from GitHub stars alone.

Suggested mix: general Mac users, designers/print users, and technical users.
Invite people only where project sharing is allowed. No paid campaign or automatic
messaging is attached to this repository.

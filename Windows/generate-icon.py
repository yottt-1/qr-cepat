"""Package the existing brand PNG as a Windows ICO; no new artwork."""
import pathlib
import struct

root = pathlib.Path(__file__).resolve().parent
# ICO PNG entries must be <=256 px; use macOS sips or the CI PowerShell helper
# to resize the existing logo before invoking this script.
import sys
source = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else root / "icon-256.png"
png = source.read_bytes()
width, height = struct.unpack(">II", png[16:24])
if (width, height) != (256, 256):
    raise SystemExit("Expected a 256x256 PNG")
header = struct.pack("<HHH", 0, 1, 1)
entry = struct.pack("<BBBBHHII", 0, 0, 0, 0, 1, 32, len(png), 22)
(root / "QRCepat.Windows" / "AppIcon.ico").write_bytes(header + entry + png)

using System.Buffers.Binary;
using System.IO.Compression;
using QRCepat.Core;
using ZXing;

int checks = 0, roundTrips = 0;
void Check(bool condition, string message) { if (!condition) throw new Exception(message); checks++; }
void Reject(QRRequest request)
{
    try { QRRenderer.Render(request); throw new Exception("Invalid request was accepted"); }
    catch (QRException) { checks++; }
}
byte[] ReadPng(byte[] png, int size)
{
    Check(png.AsSpan(0, 8).SequenceEqual(new byte[] { 137, 80, 78, 71, 13, 10, 26, 10 }), "PNG signature");
    using var idat = new MemoryStream();
    int offset = 8;
    while (offset < png.Length)
    {
        int length = BinaryPrimitives.ReadInt32BigEndian(png.AsSpan(offset, 4));
        string type = System.Text.Encoding.ASCII.GetString(png, offset + 4, 4);
        uint crc = uint.MaxValue;
        foreach (byte b in png.AsSpan(offset + 4, length + 4))
        {
            crc ^= b;
            for (int bit = 0; bit < 8; bit++) crc = (crc >> 1) ^ ((crc & 1) != 0 ? 0xedb88320U : 0);
        }
        Check(~crc == BinaryPrimitives.ReadUInt32BigEndian(png.AsSpan(offset + 8 + length, 4)), "PNG CRC");
        if (type == "IHDR")
        {
            Check(BinaryPrimitives.ReadInt32BigEndian(png.AsSpan(offset + 8, 4)) == size, "PNG width");
            Check(BinaryPrimitives.ReadInt32BigEndian(png.AsSpan(offset + 12, 4)) == size, "PNG height");
        }
        if (type == "IDAT") idat.Write(png, offset + 8, length);
        offset += length + 12;
    }
    idat.Position = 0;
    using var decoder = new ZLibStream(idat, CompressionMode.Decompress);
    using var raw = new MemoryStream(); decoder.CopyTo(raw);
    byte[] rows = raw.ToArray(), pixels = new byte[size * size * 3];
    Check(rows.Length == size * (size * 3 + 1), "PNG scanline size");
    for (int y = 0; y < size; y++)
    {
        Check(rows[y * (size * 3 + 1)] == 0, "PNG filter");
        Array.Copy(rows, y * (size * 3 + 1) + 1, pixels, y * size * 3, size * 3);
    }
    return pixels;
}
string[] samples = ["https://example.com", "Halo Windows 👋", "日本語 العربية café", "  spaces\t\r\nakhir  ", "1234567890", " "];
foreach (string text in samples)
foreach (int size in new[] { 256, 512, 1024 })
foreach (Correction correction in Enum.GetValues<Correction>())
{
    var image = QRRenderer.Render(new(text, correction, size));
    byte[] pixels = ReadPng(image.Png, size);
    Check(pixels.SequenceEqual(image.Rgb), "PNG did not preserve pixels");
    var reader = new BarcodeReaderGeneric();
    reader.Options.TryHarder = true;
    reader.Options.PossibleFormats = [BarcodeFormat.QR_CODE];
    var result = reader.Decode(pixels, size, size, RGBLuminanceSource.BitmapFormat.RGB24);
    Check(result?.Text == text, $"Roundtrip failed: {correction}, {size}, {text}");
    Check(image.PixelsPerModule >= 3 && image.QuietZonePixels >= 4 * image.PixelsPerModule, "Quiet zone / scale");
    for (int y = 0; y < size; y++)
    for (int x = 0; x < size; x++)
        if (x < image.QuietZonePixels || y < image.QuietZonePixels ||
            x >= size - image.QuietZonePixels || y >= size - image.QuietZonePixels)
        {
            int p = (y * size + x) * 3;
            if (pixels[p] != 255 || pixels[p + 1] != 255 || pixels[p + 2] != 255) throw new Exception("Quiet zone contaminated");
        }
    roundTrips++;
}
var colored = QRRenderer.Render(new("Warna QR Cepat", Foreground: "#211C66", Background: "#FFF9E8"));
Check(new BarcodeReaderGeneric().Decode(colored.Rgb, colored.Size, colored.Size, RGBLuminanceSource.BitmapFormat.RGB24)?.Text == "Warna QR Cepat", "Color decode");
roundTrips++;
Reject(new(""));
Reject(new("test", Size: 300));
Reject(new("test", Foreground: "#FFFFFF", Background: "#000000"));
Reject(new("test", Foreground: "#AAAAAA"));
Reject(new("test", Foreground: "oops"));
Reject(new(new string('x', 2954)));
Reject(new(new string('界', 1000)));
Reject(new(new string('x', 1800), Correction.H, 1024));
Reject(new(new string('x', 800), Correction.H, 256));
Check(QRRenderer.Render(new(new string('x', 800), Correction.H, 1024)).Size == 1024, "Dense QR recovery");
Console.WriteLine($"{checks} checks passed; {roundTrips} independent QR decode round-trips passed.");

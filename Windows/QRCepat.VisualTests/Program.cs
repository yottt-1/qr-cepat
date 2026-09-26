using System.IO;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using ZXing;

if (args.Length != 1) throw new ArgumentException("Pass the Windows QA artifact directory.");
int count = 0;
foreach (string name in new[] { "export.png", "windows-light.png", "windows-dark.png",
    "windows-light-2x.png", "windows-dark-2x.png", "windows-minimum.png" })
{
    using var file = File.OpenRead(Path.Combine(args[0], name));
    var decoder = BitmapDecoder.Create(file, BitmapCreateOptions.PreservePixelFormat, BitmapCacheOption.OnLoad);
    var bitmap = new FormatConvertedBitmap(decoder.Frames[0], PixelFormats.Bgr24, null, 0);
    byte[] pixels = new byte[bitmap.PixelWidth * bitmap.PixelHeight * 3];
    bitmap.CopyPixels(pixels, bitmap.PixelWidth * 3, 0);
    var reader = new BarcodeReaderGeneric();
    reader.Options.TryHarder = true;
    reader.Options.PossibleFormats = [BarcodeFormat.QR_CODE];
    var result = reader.Decode(pixels, bitmap.PixelWidth, bitmap.PixelHeight, RGBLuminanceSource.BitmapFormat.BGR24);
    if (result?.Text != "https://example.com/windows?test=final")
        throw new InvalidOperationException($"QR is missing or unreadable in {name}: {result?.Text ?? "(no decode)"}");
    Console.WriteLine($"Decoded {name}: {bitmap.PixelWidth} x {bitmap.PixelHeight}");
    count++;
}
Console.WriteLine($"{count} Windows PNG/screenshot decode checks passed.");

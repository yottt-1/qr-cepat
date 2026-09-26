using System.Buffers.Binary;
using System.IO.Compression;
using System.Text;
using QRCoder;

namespace QRCepat.Core;

public enum Correction { L, M, Q, H }
public sealed class QRException(string message) : Exception(message);
public readonly record struct RGB(byte R, byte G, byte B)
{
    public static RGB Parse(string value)
    {
        if (value.Length != 7 || value[0] != '#' ||
            !uint.TryParse(value.AsSpan(1), System.Globalization.NumberStyles.HexNumber,
                System.Globalization.CultureInfo.InvariantCulture, out var rgb))
            throw new QRException("Warna harus berupa kode hex, misalnya #000000.");
        return new((byte)(rgb >> 16), (byte)(rgb >> 8), (byte)rgb);
    }
    public double Luminance
    {
        get
        {
            static double Linear(byte v) => v / 255.0 <= .04045 ? v / 255.0 / 12.92 : Math.Pow((v / 255.0 + .055) / 1.055, 2.4);
            return .2126 * Linear(R) + .7152 * Linear(G) + .0722 * Linear(B);
        }
    }
}

public sealed record QRRequest(string Text, Correction Correction = Correction.M,
    int Size = 512, string Foreground = "#000000", string Background = "#FFFFFF");
public sealed record QRImage(byte[] Png, byte[] Rgb, int Size, int PixelsPerModule, int QuietZonePixels);

public static class QRRenderer
{
    public static QRImage Render(QRRequest request)
    {
        if (request.Text.Length == 0) throw new QRException("Masukkan teks atau tautan terlebih dahulu.");
        if (Encoding.UTF8.GetByteCount(request.Text) > 2953) throw TooLong();
        if (request.Size is not (256 or 512 or 1024)) throw new QRException("Pilih ukuran PNG 256, 512, atau 1024 px.");
        if (!Enum.IsDefined(request.Correction)) throw new QRException("Pilih tingkat ketahanan QR yang valid.");
        RGB dark = RGB.Parse(request.Foreground), light = RGB.Parse(request.Background);
        if (light.Luminance <= dark.Luminance || (light.Luminance + .05) / (dark.Luminance + .05) < 4.5)
            throw new QRException("Gunakan QR gelap dengan latar terang dan kontras tinggi. Pilih Reset warna untuk hitam-putih.");

        try
        {
            using var data = QRCodeGenerator.GenerateQrCode(request.Text,
                Enum.Parse<QRCodeGenerator.ECCLevel>(request.Correction.ToString()),
                forceUtf8: true, utf8BOM: false, eciMode: QRCodeGenerator.EciMode.Utf8);
            // QRCoder includes a four-module quiet zone on every side.
            int modules = data.ModuleMatrix.Count, scale = request.Size / modules;
            if (scale < 3) throw new QRException("Isi terlalu padat untuk ukuran ini. Pilih PNG lebih besar atau ringkas teksnya.");
            int inset = (request.Size - modules * scale) / 2;
            var pixels = new byte[request.Size * request.Size * 3];
            for (int y = 0; y < request.Size; y++)
            for (int x = 0; x < request.Size; x++)
            {
                int mx = (x - inset) / scale, my = (y - inset) / scale;
                bool inside = x >= inset && y >= inset && x < inset + modules * scale && y < inset + modules * scale;
                RGB color = inside && data.ModuleMatrix[my][mx] ? dark : light;
                int i = (y * request.Size + x) * 3;
                pixels[i] = color.R; pixels[i + 1] = color.G; pixels[i + 2] = color.B;
            }
            return new(EncodePng(pixels, request.Size), pixels, request.Size, scale, inset + 4 * scale);
        }
        catch (QRCoder.Exceptions.DataTooLongException) { throw TooLong(); }
    }

    private static QRException TooLong() => new("Isi terlalu panjang untuk dibuat menjadi QR. Coba ringkas teks atau kurangi ketahanannya.");

    // RGB PNG, lossless, with no interpolation and no platform imaging dependency.
    private static byte[] EncodePng(byte[] rgb, int size)
    {
        using var output = new MemoryStream();
        output.Write(new byte[] { 137, 80, 78, 71, 13, 10, 26, 10 });
        byte[] header = new byte[13];
        BinaryPrimitives.WriteInt32BigEndian(header, size);
        BinaryPrimitives.WriteInt32BigEndian(header.AsSpan(4), size);
        header[8] = 8; header[9] = 2;
        Chunk(output, "IHDR", header);
        using var compressed = new MemoryStream();
        using (var zlib = new ZLibStream(compressed, CompressionLevel.Fastest, leaveOpen: true))
            for (int y = 0; y < size; y++)
            {
                zlib.WriteByte(0);
                zlib.Write(rgb, y * size * 3, size * 3);
            }
        Chunk(output, "IDAT", compressed.ToArray());
        Chunk(output, "IEND", []);
        return output.ToArray();
    }

    private static void Chunk(Stream stream, string type, byte[] data)
    {
        Span<byte> word = stackalloc byte[4];
        BinaryPrimitives.WriteInt32BigEndian(word, data.Length); stream.Write(word);
        byte[] tag = Encoding.ASCII.GetBytes(type); stream.Write(tag); stream.Write(data);
        uint crc = uint.MaxValue;
        foreach (byte value in tag.Concat(data))
        {
            crc ^= value;
            for (int i = 0; i < 8; i++) crc = (crc >> 1) ^ ((crc & 1) != 0 ? 0xedb88320U : 0);
        }
        BinaryPrimitives.WriteUInt32BigEndian(word, ~crc); stream.Write(word);
    }
}

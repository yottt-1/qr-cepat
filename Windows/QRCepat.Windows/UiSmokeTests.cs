using System.IO;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace QRCepat.Windows;

public partial class MainWindow
{
    // Invoked explicitly by CI on an isolated Windows runner, never at normal startup.
    internal async Task RunSmokeTests(string directory)
    {
        Directory.CreateDirectory(directory);
        int checks = 0;
        void Check(bool condition, string message)
        {
            if (!condition) throw new InvalidOperationException(message);
            checks++;
        }
        async Task WaitForPreview()
        {
            for (int i = 0; i < 200 && rendered == null && ErrorText.Text.Length == 0; i++) await Task.Delay(50);
            Check(rendered != null, $"Preview did not render: {ErrorText.Text}");
        }
        await WaitForPreview();
        Check(CopyCommand.CanExecute(null) && SaveCommand.CanExecute(null), "Initial export commands disabled");
        ContentEditor.Text = "  Halo Windows 👋\r\nQR Cepat 日本語  ";
        Check(rendered == null && !SaveCommand.CanExecute(null) && Preview.Source == null, "Stale preview export was possible");
        ContentEditor.Text = "https://example.com/windows?test=final";
        await WaitForPreview();
        Check(rendered!.Size == 512, "Wrong default dimensions");
        CopyCommand.Execute(null);
        Check(Clipboard.ContainsImage(), "Bitmap clipboard format missing");
        Check(Clipboard.ContainsData("PNG"), "PNG clipboard format missing");
        Check(Clipboard.GetImage()?.PixelWidth == 512, "Clipboard size changed");
        File.WriteAllBytes(Path.Combine(directory, "export.png"), rendered.Png);
        Check(ToBitmap(rendered).PixelWidth == 512, "PNG decode failed");
        ForegroundInput.Text = "#FFFFFF";
        Check(!CopyCommand.CanExecute(null), "Stale clipboard command allowed");
        for (int i = 0; i < 100 && ErrorText.Text.Length == 0; i++) await Task.Delay(50);
        Check(ErrorText.Text.Length > 0 && rendered == null, "Low contrast not rejected");
        Reset_Click(this, new RoutedEventArgs());
        await WaitForPreview();
        SizePicker.SelectedIndex = 0; await WaitForPreview();
        Check(rendered!.Size == 256, "Size selection failed");
        SizePicker.SelectedIndex = 2; await WaitForPreview();
        Check(rendered!.Size == 1024, "Large export failed");
        SizePicker.SelectedIndex = 1; await WaitForPreview();

        foreach (var (name, mode) in new[] { ("light", ThemeMode.Light), ("dark", ThemeMode.Dark) })
        {
            // Explicit theme switching is only used for CI screenshots. Normal
            // app startup uses the documented XAML ThemeMode="System" setting.
#pragma warning disable WPF0001
            ThemeMode = mode;
#pragma warning restore WPF0001
            await Task.Delay(400);
            UpdateLayout();
            Screenshot(Path.Combine(directory, $"windows-{name}.png"), 1);
            Screenshot(Path.Combine(directory, $"windows-{name}-2x.png"), 2);
        }
        Width = MinWidth; Height = MinHeight;
        await Task.Delay(100); UpdateLayout();
        Screenshot(Path.Combine(directory, "windows-minimum.png"), 1);
        Check(SaveButton.ActualWidth > 70 && SaveButton.ActualHeight >= 44, "Export controls clipped");
        Clear_Click(this, new RoutedEventArgs());
        Check(rendered == null && !SaveCommand.CanExecute(null) && !CopyCommand.CanExecute(null), "Empty input export allowed");
        Check(EmptyState.Visibility == Visibility.Visible, "Empty state missing");
        Check(ContentEditor.IsKeyboardFocused, "Clear did not restore editor focus");
        Clipboard.Clear();
        File.WriteAllText(Path.Combine(directory, "results.txt"), $"{checks} Windows UI checks passed.\n");
    }

    private void Screenshot(string path, double scale)
    {
        var bitmap = new RenderTargetBitmap((int)(ActualWidth * scale), (int)(ActualHeight * scale),
            96 * scale, 96 * scale, PixelFormats.Pbgra32);
        bitmap.Render(this);
        var encoder = new PngBitmapEncoder();
        encoder.Frames.Add(BitmapFrame.Create(bitmap));
        using var file = File.Create(path); encoder.Save(file);
    }
}

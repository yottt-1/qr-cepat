using System.Globalization;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using Microsoft.Win32;
using QRCepat.Core;

namespace QRCepat.Windows;

public partial class MainWindow : Window
{
    private readonly DispatcherTimer debounce = new() { Interval = TimeSpan.FromMilliseconds(150) };
    private readonly DispatcherTimer feedbackTimer = new() { Interval = TimeSpan.FromSeconds(4) };
    private bool ready;
    private long revision;
    private QRImage? rendered;
    public RelayCommand CopyCommand { get; }
    public RelayCommand SaveCommand { get; }

    public MainWindow()
    {
        CopyCommand = new(Copy, () => rendered != null);
        SaveCommand = new(Save, () => rendered != null);
        InitializeComponent();
        DataContext = this;
        debounce.Tick += async (_, _) => { debounce.Stop(); await RefreshAsync(); };
        feedbackTimer.Tick += (_, _) => { feedbackTimer.Stop(); Feedback.Text = ""; };
        Closed += (_, _) => { revision++; ready = false; debounce.Stop(); feedbackTimer.Stop(); };
        ready = true;
        Loaded += (_, _) => { ContentEditor.Focus(); Invalidate(); };
    }

    private void InputChanged(object sender, RoutedEventArgs e) { if (ready) Invalidate(); }
    private void Invalidate()
    {
        revision++;
        rendered = null;
        Preview.Source = null;
        ErrorText.Text = "";
        Feedback.Text = "";
        CopyCommand.Notify(); SaveCommand.Notify();
        CharacterCount.Text = $"{new StringInfo(ContentEditor.Text).LengthInTextElements} karakter";
        EmptyState.Visibility = Visibility.Visible;
        EmptyState.Text = ContentEditor.Text.Length == 0 ? "Masukkan teks untuk membuat QR" : "Membuat QR…";
        PreviewStatus.Text = ContentEditor.Text.Length == 0 ? "Belum siap" : "Membuat QR…";
        debounce.Stop();
        if (ContentEditor.Text.Length > 0) debounce.Start();
    }

    private async Task RefreshAsync()
    {
        long current = revision;
        var request = new QRRequest(ContentEditor.Text,
            Enum.Parse<Correction>(((ComboBoxItem)CorrectionPicker.SelectedItem).Tag.ToString()!),
            int.Parse(((ComboBoxItem)SizePicker.SelectedItem).Tag.ToString()!, CultureInfo.InvariantCulture),
            ForegroundInput.Text, BackgroundInput.Text);
        try
        {
            QRImage image = await Task.Run(() => QRRenderer.Render(request));
            if (!ready || current != revision) return;
            Preview.Source = ToBitmap(image);
            rendered = image;
            EmptyState.Visibility = Visibility.Collapsed;
            PreviewStatus.Text = $"Siap diekspor • {image.Size} × {image.Size} px";
            ErrorText.Text = "";
            CopyCommand.Notify(); SaveCommand.Notify();
        }
        catch (Exception ex) when (ex is QRException or ArgumentException)
        {
            if (!ready || current != revision) return;
            ErrorText.Text = ex.Message;
            EmptyState.Text = "QR belum bisa dibuat";
            PreviewStatus.Text = "Periksa isi atau pengaturan";
        }
        catch (Exception)
        {
            if (!ready || current != revision) return;
            ErrorText.Text = "QR tidak dapat dibuat. Coba ringkas isinya lalu ulangi.";
            EmptyState.Text = "QR belum bisa dibuat";
            PreviewStatus.Text = "Terjadi kesalahan";
        }
    }

    internal static BitmapSource ToBitmap(QRImage image)
    {
        using var stream = new MemoryStream(image.Png, writable: false);
        var bitmap = new BitmapImage();
        bitmap.BeginInit(); bitmap.CacheOption = BitmapCacheOption.OnLoad; bitmap.StreamSource = stream; bitmap.EndInit();
        bitmap.Freeze();
        return bitmap;
    }

    private void Copy()
    {
        if (rendered is not { } image) return;
        try
        {
            var data = new DataObject();
            data.SetImage(ToBitmap(image));
            using var stream = new MemoryStream(image.Png, writable: false);
            data.SetData("PNG", stream);
            Clipboard.SetDataObject(data, copy: true);
            Toast("QR disalin ke clipboard");
        }
        catch (Exception ex) when (ex is System.Runtime.InteropServices.ExternalException or IOException)
        { Toast("Clipboard sedang dipakai aplikasi lain. Coba lagi atau simpan PNG."); }
    }

    private void Save()
    {
        if (rendered is not { } image) return;
        var dialog = new SaveFileDialog
        {
            Title = "Simpan QR sebagai PNG", FileName = "QR-Cepat.png",
            DefaultExt = ".png", Filter = "Gambar PNG (*.png)|*.png", AddExtension = true, OverwritePrompt = true
        };
        if (dialog.ShowDialog(this) != true) return;
        try { File.WriteAllBytes(dialog.FileName, image.Png); Toast("PNG berhasil disimpan"); }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        { Toast("File tidak dapat disimpan. Pilih folder yang dapat ditulis lalu coba lagi."); }
    }
    private void Toast(string message) { Feedback.Text = message; feedbackTimer.Stop(); feedbackTimer.Start(); }
    private void Clear_Click(object sender, RoutedEventArgs e) { ContentEditor.Clear(); ContentEditor.Focus(); }
    private void Reset_Click(object sender, RoutedEventArgs e) { ForegroundInput.Text = "#000000"; BackgroundInput.Text = "#FFFFFF"; }
}

public sealed class RelayCommand(Action execute, Func<bool> canExecute) : ICommand
{
    public event EventHandler? CanExecuteChanged;
    public bool CanExecute(object? parameter) => canExecute();
    public void Execute(object? parameter) { if (canExecute()) execute(); }
    public void Notify() => CanExecuteChanged?.Invoke(this, EventArgs.Empty);
}

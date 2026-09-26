using System.IO;
using System.Windows;

namespace QRCepat.Windows;
public partial class App : Application
{
    protected override async void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        // Headless CI captures use software rendering to avoid GPU surface
        // caching in RenderTargetBitmap. Normal startup keeps WPF's default.
        if (e.Args.Length == 2 && e.Args[0] == "--self-test")
            System.Windows.Media.RenderOptions.ProcessRenderMode = System.Windows.Interop.RenderMode.SoftwareOnly;
        var window = new MainWindow();
        MainWindow = window;
        window.Show();
        if (e.Args.Length == 2 && e.Args[0] == "--self-test")
        {
            try { await window.RunSmokeTests(e.Args[1]); Shutdown(0); }
            catch (Exception ex)
            {
                Directory.CreateDirectory(e.Args[1]);
                File.WriteAllText(Path.Combine(e.Args[1], "failure.txt"), ex.ToString());
                Shutdown(1);
            }
        }
    }
}

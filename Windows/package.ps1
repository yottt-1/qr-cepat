param(
    [ValidatePattern('^v[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.]+)?$')]
    [string]$Version = "v0.2.0-beta.1"
)
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Push-Location $root
try {
    dotnet publish Windows/QRCepat.Windows -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -p:EnableCompressionInSingleFile=true -p:DebugType=None "-p:Version=$($Version.TrimStart('v'))" -o dist/windows-x64
    if ($LASTEXITCODE -ne 0) { throw "Windows publish failed" }
    Copy-Item LICENSE dist/windows-x64/QR-Cepat-LICENSE.txt
    Copy-Item Windows/THIRD-PARTY-NOTICES.txt dist/windows-x64/
    Copy-Item Windows/DOTNET-THIRD-PARTY-NOTICES.txt dist/windows-x64/
    Copy-Item Windows/README.txt dist/windows-x64/
    $archive = "dist/QR-Cepat-$Version-Windows-x64.zip"
    if (Test-Path $archive) { throw "Archive already exists: $archive" }
    Compress-Archive -Path dist/windows-x64/* -DestinationPath $archive
    $digest = (Get-FileHash $archive -Algorithm SHA256).Hash.ToLowerInvariant()
    "$digest  $(Split-Path $archive -Leaf)" | Set-Content "dist/SHA256SUMS-Windows" -Encoding ascii
    Write-Output "Created $archive"
} finally { Pop-Location }

param(
    [string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$v = $Version.TrimStart('v')
$name = "antigravity-login-patch-v$v"
$dist = Join-Path $root "dist"

if (Test-Path $dist) { Remove-Item $dist -Recurse -Force }
New-Item -ItemType Directory -Path $dist | Out-Null

$files = @("fix-network.bat", "fix-ide.bat", "fix-account.bat", "README.md", "recovery.md", "AGENTS.md", "CHANGELOG.md", "LICENSE")
foreach ($f in $files) {
    $src = Join-Path $root $f
    if (Test-Path $src) { Copy-Item $src (Join-Path $dist $f) }
}

$stage = Join-Path $dist $name
New-Item -ItemType Directory -Path $stage | Out-Null
Get-ChildItem $dist -File | Move-Item -Destination $stage

$zip = Join-Path $dist "$name.zip"
Compress-Archive -Path $stage -DestinationPath $zip -Force
Write-Host "Release ready: $zip"
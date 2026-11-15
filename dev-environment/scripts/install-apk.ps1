$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$apk = Join-Path $repoRoot "mobile\build\app\outputs\flutter-apk\app-release.apk"

if (-not (Test-Path $apk)) {
    throw "APK not found. Run .\scripts\build-android.ps1 first."
}
if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    throw "ADB is not on PATH. Install Android Platform Tools on Windows."
}

adb devices
if ($LASTEXITCODE -ne 0) { throw "Could not query ADB devices." }

adb install -r "$apk"
if ($LASTEXITCODE -ne 0) {
    throw "APK installation failed. Check phone connection and USB debugging."
}

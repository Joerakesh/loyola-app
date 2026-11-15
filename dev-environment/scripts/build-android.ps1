$ErrorActionPreference = "Stop"

Write-Host "Building Android release APK inside Docker..." -ForegroundColor Cyan
docker compose run --rm flutter bash -lc "cd mobile && flutter pub get && flutter build apk --release"
if ($LASTEXITCODE -ne 0) {
    throw "Docker Flutter build failed."
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$apk = Join-Path $repoRoot "mobile\build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apk) {
    Write-Host "APK created: $apk" -ForegroundColor Green
} else {
    throw "Build completed but APK was not found at $apk. Check that the Flutter project is in mobile/."
}

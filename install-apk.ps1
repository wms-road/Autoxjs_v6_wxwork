<#
.SYNOPSIS
  Install the freshly built AutoX APK onto a connected real device via adb.
.DESCRIPTION
  Locates the newest built APK under app\build\outputs\apk\v6 (prefers arm64-v8a debug),
  detects authorized devices, and runs `adb install -r <apk>`.
  Pure ASCII on purpose (run via install-apk.bat with chcp 65001) to avoid GBK/UTF-8 issues.
#>
$ErrorActionPreference = 'Stop'

$PROJECT_DIR  = $PSScriptRoot
$ANDROID_HOME = "D:\Android\Sdk"   # edit to your SDK path if different
$ADB = Join-Path $ANDROID_HOME "platform-tools\adb.exe"
if (-not (Test-Path $ADB)) {
    $adbOnPath = Get-Command adb -ErrorAction SilentlyContinue
    if ($adbOnPath) { $ADB = $adbOnPath.Source }
    else { Write-Error "adb not found at $ADB and not on PATH. Set ANDROID_HOME or add platform-tools to PATH."; exit 1 }
}

# locate built APK
$apkBase = Join-Path $PROJECT_DIR "app\build\outputs\apk\v6"
if (-not (Test-Path $apkBase)) { Write-Error "No build output at $apkBase. Run build-apk.ps1 first."; exit 1 }
$apks = Get-ChildItem $apkBase -Recurse -Filter *.apk
if ($apks.Count -eq 0) { Write-Error "No APK found under $apkBase. Build first."; exit 1 }

# priority: arm64-v8a debug > universal debug > any debug > arm64 release > any release
$priority = @('*arm64-v8a*debug*', '*universal*debug*', '*debug*', '*arm64-v8a*release*', '*release*')
$apk = $null
foreach ($p in $priority) {
    $cand = $apks | Where-Object { $_.Name -like $p } | Select-Object -First 1
    if ($cand) { $apk = $cand; break }
}
if (-not $apk) { $apk = $apks[0] }

Write-Host "Using APK: $($apk.FullName) ($([math]::Round($apk.Length/1MB,1)) MB)"

# list authorized devices only (skip offline/unauthorized/emulator-less lines)
$raw = & $ADB devices 2>&1
$devices = @()
foreach ($line in $raw) {
    if ($line -match '^\s*(\S+)\s+device\s*$') { $devices += $Matches[1] }
}
if ($devices.Count -eq 0) {
    Write-Error "No authorized device connected. Enable USB debugging, accept the prompt on phone, then retry."
    exit 1
}

$serial = $null
if ($devices.Count -eq 1) {
    $serial = $devices[0]
} else {
    Write-Host "Multiple devices found:"
    for ($i = 0; $i -lt $devices.Count; $i++) { Write-Host "  [$($i+1)] $($devices[$i])" }
    $pick = Read-Host "Select device number (1..$($devices.Count))"
    $serial = $devices[[int]$pick - 1]
}

Write-Host "Installing to $serial ..."
& $ADB -s $serial install -r $apk.FullName
if ($LASTEXITCODE -ne 0) { Write-Error "adb install failed (exit $LASTEXITCODE)"; exit $LASTEXITCODE }
Write-Host "DONE. App package: org.autojs.autoxjs.ozobi.v6"

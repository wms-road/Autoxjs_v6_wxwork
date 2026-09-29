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

# adb prints noise (e.g. "* daemon not running; starting now ...") to stderr.
# Under $ErrorActionPreference='Stop' that becomes a terminating NativeCommandError,
# so wrap adb calls here: capture output, keep exit code, never throw on stderr.
function Invoke-Adb {
    param([string[]]$AdbArgs)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { & $ADB @AdbArgs 2>&1 }
    finally { $ErrorActionPreference = $prev }
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

# enumerate devices and classify state (device / unauthorized / offline / none)
$raw = Invoke-Adb -AdbArgs @('devices')
$devices = @(); $unauth = @(); $offline = @()
foreach ($line in $raw) {
    if ($line -match '^\s*(\S+)\s+device\b') { $devices += $Matches[1] }
    elseif ($line -match '^\s*(\S+)\s+unauthorized\b') { $unauth += $Matches[1] }
    elseif ($line -match '^\s*(\S+)\s+offline\b') { $offline += $Matches[1] }
}
Write-Host "adb devices output:"
foreach ($line in $raw) { if ($line.Trim()) { Write-Host "  $line" } }

if ($devices.Count -eq 0) {
    if ($unauth.Count -gt 0) {
        Write-Host "Device(s) detected but UNAUTHORIZED: $($unauth -join ', ')"
        Write-Host "  -> On the phone, tap 'Allow' on the 'Allow USB debugging?' dialog"
        Write-Host "     (tick 'Always allow from this computer' to avoid repeat prompts)."
        Write-Host "  -> If no dialog appears: Developer Options -> 'Revoke USB debugging authorizations',"
        Write-Host "     unplug & re-plug the cable, then tap 'Allow' when prompted."
    } elseif ($offline.Count -gt 0) {
        Write-Host "Device(s) OFFLINE: $($offline -join ', ')."
        Write-Host "  -> Try unplug & re-plug, or run 'adb kill-server' then retry."
    } else {
        Write-Host "No device detected at all."
        Write-Host "  -> Use a DATA-capable USB cable and a working USB port (charger-only cables won't enumerate)."
        Write-Host "  -> On the phone: Developer Options -> 'USB debugging' ON; some brands also need"
        Write-Host "     'USB debugging (Security settings)' and 'USB installation'."
        Write-Host "  -> Set USB mode to 'File Transfer (MTP)' (the CD-drive mode you saw is normal)."
        Write-Host "  -> If still nothing: 'adb kill-server' then 'adb devices' in a terminal to confirm."
    }
    Write-Error "No authorized device connected. Resolve the above, then retry."
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
$installOut = Invoke-Adb -AdbArgs @('-s', $serial, 'install', '-r', $apk.FullName)
Write-Host ($installOut -join "`n")
if ($LASTEXITCODE -ne 0) { Write-Error "adb install failed (exit $LASTEXITCODE)"; exit $LASTEXITCODE }
Write-Host "DONE. App package: org.autojs.autoxjs.ozobi.v6"

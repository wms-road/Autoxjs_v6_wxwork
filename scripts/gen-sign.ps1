<#
.SYNOPSIS
  Auto-generate Autoxjs_v6_wxwork release signing (self-signed jks keystore + sign/sign.properties).
.DESCRIPTION
  app/build.gradle.kts expects propFile at <repo-root>/sign/sign.properties (relative path).
  This script creates <repo-root>/sign/, generates a self-signed jks via JDK keytool, and writes
  sign.properties. The generated secret is for local dev / internal distribution only; sign/ is
  git-ignored (.gitignore), do NOT commit it.
.PARAMETER Alias      key alias, default autoxjs
.PARAMETER Password   keystore + key password, default android
.PARAMETER Validity   cert validity in days, default 10000
.PARAMETER StoreFile  keystore filename, default my-release.jks
.EXAMPLE
  .\scripts\gen-sign.ps1
  .\scripts\gen-sign.ps1 -Alias wxwork -Password "myStrongPwd" -Validity 3650
#>
param(
    [string]$Alias = "autoxjs",
    [string]$Password = "android",
    [int]$Validity = 10000,
    [string]$StoreFile = "my-release.jks"
)

$ErrorActionPreference = "Stop"

# repo root: this script lives at <root>/scripts/gen-sign.ps1, parent is root
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot  = (Resolve-Path (Join-Path $scriptDir "..")).Path
$signDir   = Join-Path $repoRoot "sign"
$keystore  = Join-Path $signDir $StoreFile
$propFile  = Join-Path $signDir "sign.properties"

# locate keytool: prefer JAVA_HOME, else PATH
$keytool = "keytool"
if ($env:JAVA_HOME) {
    $candidate = Join-Path $env:JAVA_HOME "bin\keytool.exe"
    if (Test-Path $candidate) { $keytool = $candidate }
}
if (-not (Get-Command $keytool -ErrorAction SilentlyContinue)) {
    throw "keytool not found. Install JDK and set JAVA_HOME, or add keytool to PATH."
}

New-Item -ItemType Directory -Force -Path $signDir | Out-Null

if (Test-Path $keystore) {
    Write-Host "[skip] keystore already exists: $keystore"
} else {
    Write-Host "[gen ] generating self-signed keystore: $keystore"
    & $keytool -genkeypair -v `
        -keystore $keystore -alias $Alias -keyalg RSA -keysize 2048 -validity $Validity `
        -storepass $Password -keypass $Password `
        -dname "CN=Autoxjs Dev, OU=Dev, O=Autoxjs, L=Unknown, ST=Unknown, C=CN"
    if ($LASTEXITCODE -ne 0) { throw "keytool failed (exit=$LASTEXITCODE)" }
    Write-Host "[ok  ] keystore generated"
}

# sign.properties content matches app/build.gradle.kts (standard Android signing four fields).
# storeFile uses absolute path so Gradle file() resolves reliably; change it to relocate.
$props = @"
storeFile=$keystore
storePassword=$Password
keyAlias=$Alias
keyPassword=$Password
"@
Set-Content -Path $propFile -Value $props -Encoding UTF8
Write-Host "[ok  ] generated: $propFile"
Write-Host ""
Write-Host "Done. Now run: gradlew :app:assembleV6Release  (uses this signing for an installable release APK)."
Write-Host "To adjust: re-run this script with params, or edit sign/sign.properties manually; to replace the keystore, delete sign/$StoreFile then re-run."

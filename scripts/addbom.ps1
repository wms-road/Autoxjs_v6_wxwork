<#
.SYNOPSIS
  Add a UTF-8 BOM to a file (idempotent) so PowerShell reads Chinese source correctly on GBK consoles.
.DESCRIPTION
  PowerShell reads .ps1 as the system ANSI codepage (GBK on zh-CN) unless the file starts with a
  UTF-8 BOM. Without BOM, Chinese string literals get garbled. This script prepends the BOM if missing.
.PARAMETER Path   target file path (required)
.EXAMPLE
  .\scripts\addbom.ps1 -Path build-apk.ps1
#>
param(
    [string]$Path
)

$ErrorActionPreference = "Stop"

if (-not $Path) { Write-Error "Usage: .\addbom.ps1 -Path <file>"; exit 1 }
if (-not (Test-Path $Path)) { Write-Error "File not found: $Path"; exit 1 }

$bytes = [System.IO.File]::ReadAllBytes($Path)
if ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    Write-Output "already has BOM: $Path"
} else {
    $content = [System.Text.Encoding]::UTF8.GetString($bytes)
    [System.IO.File]::WriteAllBytes($Path, ([System.Text.Encoding]::UTF8.GetPreamble() + [System.Text.Encoding]::UTF8.GetBytes($content)))
    Write-Output "BOM added: $Path"
}

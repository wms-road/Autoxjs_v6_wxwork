<#
.SYNOPSIS
  Parse-check a PowerShell script for syntax errors without executing it.
.DESCRIPTION
  Uses the PowerShell language parser to validate a .ps1 file. Exits non-zero if parse errors exist.
  Useful to verify a script after editing/BOM-fixing before handing it to users.
.PARAMETER Path   target .ps1 file path (required)
.EXAMPLE
  .\scripts\verifyscript.ps1 -Path build-apk.ps1
#>
param(
    [string]$Path
)

$ErrorActionPreference = "Stop"

if (-not $Path) { Write-Error "Usage: .\verifyscript.ps1 -Path <ps1 file>"; exit 1 }
if (-not (Test-Path $Path)) { Write-Error "File not found: $Path"; exit 1 }

$errs = $null
[System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$errs)
if ($errs) {
    Write-Error ("PARSE ERRORS: " + $errs.Count)
    $errs | ForEach-Object { Write-Error $_.Message }
    exit 1
} else {
    Write-Output "PARSE OK: $Path"
}

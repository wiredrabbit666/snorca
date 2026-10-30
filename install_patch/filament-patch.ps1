# Unlocks third-party filament brands (Bambu, Elegoo, SUNLU, eSUN, ...) in Snapmaker Orca.
#
# Usage (normally started by the .bat files in the repository root):
#   filament-patch.ps1            apply the patch
#   filament-patch.ps1 -Undo      put the original files back
#   -InstallDir <folder>          only needed if Snapmaker Orca is installed somewhere unusual
#
# What it changes in <Snapmaker Orca install>\resources:
#   profiles\OrcaFilamentLibrary.json        filled-in filament list (shipped empty)
#   profiles\OrcaFilamentLibrary\filament\   adds the profile files that are missing
#   web\guide\22\22.js, web\guide\23\23.js   stops hiding filaments without a printer list
# Snapmaker Orca copies these into %APPDATA%\Snapmaker_Orca\system on every start.

param([switch]$Undo, [string]$InstallDir)

$ErrorActionPreference = 'Stop'
$patchDir  = $PSScriptRoot
$filesDir  = Join-Path $patchDir 'files'
$jsFiles   = @('web\guide\22\22.js', 'web\guide\23\23.js')
$hidden    = '// bFind=true;'
$shown     = 'bFind=true; // filament patch: show filaments without a printer list'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Fail($msg) {
    Write-Host ""
    Write-Host "ERROR: $msg" -ForegroundColor Red
    exit 1
}

function Find-Install {
    if ($InstallDir) { return $InstallDir }
    $candidates = @("$env:ProgramFiles\Snapmaker_Orca")
    $keys = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    foreach ($app in Get-ItemProperty $keys -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq 'Snapmaker_Orca' }) {
        if ($app.UninstallString) { $candidates += Split-Path ($app.UninstallString.Trim('"')) }
    }
    foreach ($dir in $candidates) {
        if (Test-Path (Join-Path $dir 'resources\profiles\OrcaFilamentLibrary.json')) { return $dir }
    }
    return $null
}

$install = Find-Install
if (-not $install) { Fail "Snapmaker Orca was not found. Is it installed?" }
$resources = Join-Path $install 'resources'
$backupDir = Join-Path $install 'filament_patch_backup'
Write-Host "Snapmaker Orca found at: $install"

if (Get-Process -Name 'snapmaker-orca' -ErrorAction SilentlyContinue) {
    Fail "Snapmaker Orca is running. Close it completely, then run this again."
}

$manifest = Join-Path $resources 'profiles\OrcaFilamentLibrary.json'
$addedList = Join-Path $backupDir 'added_files.txt'

if ($Undo) {
    if (-not (Test-Path $backupDir)) { Fail "No backup found in $backupDir. The patch was probably never applied." }
    Copy-Item (Join-Path $backupDir 'OrcaFilamentLibrary.json') $manifest -Force
    foreach ($js in $jsFiles) { Copy-Item (Join-Path $backupDir (Split-Path $js -Leaf)) (Join-Path $resources $js) -Force }
    if (Test-Path $addedList) {
        foreach ($rel in Get-Content $addedList) {
            $target = Join-Path $resources $rel
            if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Force }
        }
    }
    Remove-Item $backupDir -Recurse -Force
    Write-Host ""
    Write-Host "Done. Snapmaker Orca is back to its original filament list." -ForegroundColor Green
    exit 0
}

# --- Apply ---------------------------------------------------------------

# Back up the stock files. Skipped when already patched, so Undo always returns to stock;
# redone after a Snapmaker Orca update (which puts stock files back).
$alreadyPatched = [IO.File]::ReadAllText((Join-Path $resources $jsFiles[0])).Contains($shown)
if (-not $alreadyPatched) {
    if (Test-Path $backupDir) { Remove-Item $backupDir -Recurse -Force }
    New-Item -ItemType Directory $backupDir | Out-Null
    Copy-Item $manifest $backupDir
    foreach ($js in $jsFiles) { Copy-Item (Join-Path $resources $js) $backupDir }
    New-Item -ItemType File $addedList | Out-Null
}

# 1. Dialog scripts: un-comment the line that keeps filaments without a printer list.
foreach ($js in $jsFiles) {
    $path = Join-Path $resources $js
    $text = [IO.File]::ReadAllText($path)
    if ($text.Contains($shown)) {
        Write-Host "  $js already patched"
    } elseif (([regex]::Matches($text, [regex]::Escape($hidden))).Count -eq 1) {
        [IO.File]::WriteAllText($path, $text.Replace($hidden, $shown), $utf8NoBom)
        Write-Host "  $js patched"
    } else {
        Fail "$js does not look like the expected file (Snapmaker Orca may have been updated). Nothing in it was changed."
    }
}

# 2. Profile files: add only the ones that are missing, keep Snapmaker's own versions.
$srcLib = Join-Path $filesDir 'profiles\OrcaFilamentLibrary'
$added = 0
foreach ($file in Get-ChildItem -LiteralPath $srcLib -Recurse -File) {
    $rel = 'profiles\OrcaFilamentLibrary' + $file.FullName.Substring($srcLib.Length)
    $target = Join-Path $resources $rel
    if (-not (Test-Path -LiteralPath $target)) {
        New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
        Copy-Item -LiteralPath $file.FullName $target
        Add-Content $addedList $rel
        $added++
    }
}
Write-Host "  $added filament profile files added"

# 3. Filament list: install the filled-in list, after checking every file it names exists.
$newManifest = Join-Path $filesDir 'profiles\OrcaFilamentLibrary.json'
$entries = (Get-Content $newManifest -Raw -Encoding UTF8 | ConvertFrom-Json).filament_list
$missing = @($entries | Where-Object { -not (Test-Path -LiteralPath (Join-Path $resources "profiles\OrcaFilamentLibrary\$($_.sub_path)")) })
if ($missing.Count -gt 0) { Fail "$($missing.Count) profile files are missing, e.g. $($missing[0].sub_path). The filament list was not changed." }
Copy-Item $newManifest $manifest -Force
Write-Host "  filament list installed ($($entries.Count) entries)"

Write-Host ""
Write-Host "Done. Start Snapmaker Orca and open the filament selection to pick your brands." -ForegroundColor Green

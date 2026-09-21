<#
.SYNOPSIS
    Applies or verifies the local patches to the imported libxml2 and libxslt sources.

.DESCRIPTION
    Patches\*.patch are unified diffs with paths relative to Source (a/libxml2/parser.c),
    applied in the order of their names; a later patch may build on an earlier one. Every
    patch starts with a comment that says what it changes, why, and whether it is
    upstream; git apply skips that text.

    The tool is git apply, run on the Source directory (no repository is needed): it has
    no fuzz at all, every context line must match, and a patch that does not match leaves
    the file untouched and fails the script. Source\PATCHES records the patches applied,
    in order. Import.ps1 removes Source together with the record and runs -Apply after
    copying a release; Build.ps1 runs -Check before compiling, so an unapplied patch (a
    file reverted from SVN, a release imported by hand) stops the build instead of quietly
    producing objects without the change.

.PARAMETER Apply
    Apply, in order, every patch that Source\PATCHES does not list yet.
.PARAMETER Check
    Verify that Source\PATCHES lists exactly the patches, and that the sources really
    carry them: on a copy of Source the patches are removed in reverse order, each must
    come off cleanly. Default.

.EXAMPLE
    .\Patches.ps1 -Check
    .\Patches.ps1 -Apply
#>
[CmdletBinding()]
param(
    [switch]$Apply,
    [switch]$Check
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$Src = Join-Path $Root 'Source'
$Dir = Join-Path $Root 'Patches'
$Record = Join-Path $Src 'PATCHES'

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git is required to apply the patches (git apply, no repository needed)' }
$patches = @(Get-ChildItem $Dir -Filter *.patch | Sort-Object Name)
if ($patches.Count -eq 0) { Write-Host '  patches: none'; return }
$applied = @()
if (Test-Path $Record) { $applied = @(Get-Content $Record | Where-Object { $_.Trim() -ne '' }) }

# The sources keep the line endings they were imported with: git must not rewrite them on
# the way (core.autocrlf of the user's global config would). A mismatch comes back as the
# exit code and stderr text; neither may turn into an exception, on Windows PowerShell
# a native command writing to stderr under 'Stop' does exactly that.
$GitOut = ''
function Invoke-GitApply {
    param([string]$Tree, [string[]]$Extra, [string]$File)
    $eap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $lines = & git -c core.autocrlf=false -c core.safecrlf=false -C $Tree apply --whitespace=nowarn @Extra $File 2>&1 | ForEach-Object { "$_" }
        $script:GitOut = ($lines -join "`n")
        return [bool]($LASTEXITCODE -eq 0)
    }
    finally {
        $ErrorActionPreference = $eap
    }
}

if ($Apply) {
    foreach ($p in $patches) {
        if ($applied -contains $p.Name) { Write-Host "  $($p.Name): already applied"; continue }
        if (-not (Invoke-GitApply -Tree $Src -Extra @('--check') -File $p.FullName)) {
            throw "$($p.Name) does not match the sources; the code it expects has changed:`n$GitOut"
        }
        if (-not (Invoke-GitApply -Tree $Src -Extra @() -File $p.FullName)) { throw "$($p.Name): git apply failed:`n$GitOut" }
        $applied += $p.Name
        Set-Content -Path $Record -Value $applied -Encoding ASCII
        Write-Host "  $($p.Name): applied"
    }
    return
}

# -Check
$names = @($patches | ForEach-Object { $_.Name })
if (($applied -join "`n") -ne ($names -join "`n")) {
    throw "Source\PATCHES lists [$($applied -join ', ')], Patches\ holds [$($names -join ', ')]; run .\Patches.ps1 -Apply or re-import"
}
$tmp = Join-Path ([IO.Path]::GetTempPath()) "lx2-patches-$PID"
try {
    New-Item -ItemType Directory -Force $tmp | Out-Null
    Copy-Item (Join-Path $Src '*') $tmp -Recurse -Force
    for ($i = $patches.Count - 1; $i -ge 0; $i--) {
        $p = $patches[$i]
        if (-not (Invoke-GitApply -Tree $tmp -Extra @('--reverse') -File $p.FullName)) {
            throw "$($p.Name) is recorded as applied but does not come off the sources cleanly (a file reverted or edited underneath it?):`n$GitOut"
        }
        Write-Host "  $($p.Name): applied"
    }
}
finally {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

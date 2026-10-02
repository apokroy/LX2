<#
.SYNOPSIS
    Builds LX2Bench.dpr with dcc64 and runs it.

.DESCRIPTION
    A release build (the C runtime heap for libxml2, --hostmm for the Delphi memory
    manager) unless -DebugBuild is given, which defines DEBUG and so gets the debug
    allocator of libxml2 that LX2Lib.Load installs in debug builds. Everything after the script's own
    parameters goes to the benchmark; see the header of LX2Bench.dpr for its options.

.EXAMPLE
    .\Bench.ps1
    .\Bench.ps1 --file=D:\Test\XML\test.xml --runs=5
    .\Bench.ps1 --hostmm --threads=4
    .\Bench.ps1 --verify > before.txt      (then after a change: > after.txt, and compare)
#>
[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$StudioRoot,
    [string]$BdsVersion,
    [switch]$DebugBuild,
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$BenchArgs
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$LX2Src = Join-Path (Split-Path (Split-Path $Root -Parent) -Parent) 'Source'
# RAD Studio: -StudioRoot, else -BdsVersion, else the BDS variable that rsvars.bat sets, else
# the newest installation the registry knows (HKCU, then HKLM).
function Find-StudioRoot([string]$Root, [string]$Version) {
    if ($Root) { return $Root.TrimEnd('\') }
    if (-not $Version -and $env:BDS -and (Test-Path (Join-Path $env:BDS 'bin\dcc64.exe'))) { return $env:BDS.TrimEnd('\') }
    $found = @()
    foreach ($hive in 'HKCU:\Software\Embarcadero\BDS', 'HKLM:\SOFTWARE\WOW6432Node\Embarcadero\BDS') {
        foreach ($key in Get-ChildItem $hive -ErrorAction SilentlyContinue) {
            $v = $null
            if (-not [version]::TryParse($key.PSChildName, [ref]$v)) { continue }
            if ($Version -and $key.PSChildName -ne $Version) { continue }
            $dir = [string](Get-ItemProperty $key.PSPath -ErrorAction SilentlyContinue).RootDir
            if ($dir -and (Test-Path (Join-Path $dir 'bin\dcc64.exe'))) { $found += [pscustomobject]@{ Version = $v; Root = $dir.TrimEnd('\') } }
        }
    }
    $best = $found | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $best) { throw "RAD Studio $(if ($Version) { $Version } else { '' }) not found in the registry; pass -StudioRoot" }
    return $best.Root
}
$StudioRoot = Find-StudioRoot $StudioRoot $BdsVersion
$StudioShort = (New-Object -ComObject Scripting.FileSystemObject).GetFolder($StudioRoot).ShortPath
$config = if ($DebugBuild) { 'Debug' } else { 'Release' }
$out = Join-Path $Root "Win64\$config"
New-Item -ItemType Directory -Force $out | Out-Null
$argList = @('-B', '-Q', "-E$out", "-N0$out", '-NSSystem;Winapi', "-U$LX2Src",
             ('-U' + (Join-Path $StudioShort 'lib\win64\release')), '-$O+')
if ($DebugBuild) { $argList += '-dDEBUG' }
$argList += (Join-Path $Root 'LX2Bench.dpr')
$res = & (Join-Path $StudioRoot 'bin\dcc64.exe') @argList 2>&1
if ($LASTEXITCODE -ne 0) { throw "dcc64 exited with code $LASTEXITCODE`n$($res -join "`n")" }
& (Join-Path $out 'LX2Bench.exe') @BenchArgs
exit $LASTEXITCODE

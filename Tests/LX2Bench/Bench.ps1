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
    [string]$BdsVersion = '37.0',
    [switch]$DebugBuild,
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$BenchArgs
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$LX2Src = Join-Path (Split-Path (Split-Path $Root -Parent) -Parent) 'Source'
if (-not $StudioRoot) {
    $key = "HKCU:\Software\Embarcadero\BDS\$BdsVersion"
    if (-not (Test-Path $key)) { $key = "HKLM:\SOFTWARE\WOW6432Node\Embarcadero\BDS\$BdsVersion" }
    $StudioRoot = (Get-ItemProperty $key).RootDir
}
$StudioRoot = $StudioRoot.TrimEnd('\')
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

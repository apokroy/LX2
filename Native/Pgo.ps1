<#
.SYNOPSIS
    Profile-guided build of the libxml2 and libxslt objects.

.DESCRIPTION
    The parser loops of libxml2 are branchy and gain 10-30 % from a profile (DOM parse
    about -10 %, push parse -30 %, C14N -20 %), which no -O level reaches. bcc64x builds
    instrumented code but rejects the profile on the way back, so this needs another
    LLVM: clang.exe and llvm-profdata.exe of the same version, upstream LLVM 20 or the
    LLVM that ships with Visual Studio. The final objects are compiled by that clang
    through Build.ps1 -Clang, for the same target and with the same flags and RAD Studio
    headers as the bcc64x build; without a profile they run at the same speed.

    Steps:
      1. Patches.ps1 -Check, Build.ps1 -HeadersOnly (the generated headers);
      2. the training exe: Pgo\train.c with the libxml2 sources and the iconv shim,
         instrumented (-fprofile-generate), a native exe linked against the Visual Studio
         C runtime (vcvars64), built in %TEMP%\lx2-pgo;
      3. the training run over the corpus: every *.xml of the directories and files given,
         each parsed, push-parsed, serialized in UTF-8 and windows-1251, canonicalized,
         queried, and validated when a <name>.xsd lies next to it. The corpus is not part of
         the repository: it should be the documents the applications actually process, in
         the encodings they come in;
      4. llvm-profdata merge; Build.ps1 -Clang ... -Profile ... [-Test].

    The objects in Lib\Win64 and LX2.Static.pas are the result; commit them like after a
    plain build. A later Build.ps1 without -Clang rebuilds plain bcc64x objects.

.PARAMETER Corpus
    Directories (searched for *.xml recursively) or files of the training corpus.
.PARAMETER Llvm
    Directory with clang.exe and llvm-profdata.exe. Default: %ProgramFiles%\LLVM\bin when
    it exists, otherwise the LLVM of the newest Visual Studio (vswhere).
.PARAMETER Rounds
    How many times each document is run through the workloads (default 3).
.PARAMETER Profile
    Where to write the merged profile (default %TEMP%\lx2-pgo\train.profdata).
.PARAMETER Test
    Passed on to Build.ps1: compile and run the smoke test after the build.

.EXAMPLE
    .\Pgo.ps1 -Corpus D:\Corpus\XML -Test
    .\Pgo.ps1 -Corpus D:\Corpus\XML, D:\Test\XML\test.xml -Llvm 'C:\Program Files\LLVM\bin'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$Corpus,
    [string]$Llvm,
    [int]$Rounds = 3,
    [string]$Profile,
    [switch]$Test
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$Work = Join-Path $env:TEMP 'lx2-pgo'
if (-not $Profile) { $Profile = Join-Path $Work 'train.profdata' }

# ---- tools
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$vsRoot = $null
if (Test-Path $vswhere) { $vsRoot = (& $vswhere -latest -products * -property installationPath 2>$null | Select-Object -First 1) }
if (-not $Llvm) {
    $candidates = @((Join-Path $env:ProgramFiles 'LLVM\bin'))
    if ($vsRoot) { $candidates += (Join-Path $vsRoot 'VC\Tools\Llvm\x64\bin') }
    $Llvm = $candidates | Where-Object { Test-Path (Join-Path $_ 'clang.exe') } | Select-Object -First 1
    if (-not $Llvm) { throw 'No LLVM found: install upstream LLVM or the Visual Studio C++ clang tools, or pass -Llvm' }
}
$Clang = Join-Path $Llvm 'clang.exe'
$ProfData = Join-Path $Llvm 'llvm-profdata.exe'
foreach ($tool in $Clang, $ProfData) { if (-not (Test-Path $tool)) { throw "Not found: $tool" } }
if (-not $vsRoot) { throw 'Visual Studio with the C++ tools is needed to link the training exe (vcvars64)' }
$vcvars = Join-Path $vsRoot 'VC\Auxiliary\Build\vcvars64.bat'
if (-not (Test-Path $vcvars)) { throw "Not found: $vcvars" }
Write-Host "LLVM: $Llvm"
Write-Host "  $((& $Clang --version 2>&1 | Select-Object -First 1))"

# ---- corpus
$files = @()
foreach ($c in $Corpus) {
    if (Test-Path $c -PathType Container) { $files += Get-ChildItem $c -Recurse -Filter *.xml -File | ForEach-Object { $_.FullName } }
    elseif (Test-Path $c -PathType Leaf) { $files += (Resolve-Path $c).Path }
    else { throw "Corpus entry not found: $c" }
}
if ($files.Count -eq 0) { throw 'The corpus holds no *.xml files' }
Write-Host "corpus: $($files.Count) documents, $([math]::Round(($files | ForEach-Object { (Get-Item $_).Length } | Measure-Object -Sum).Sum / 1MB, 1)) MB"

# ---- 1. patches and headers
& (Join-Path $Root 'Patches.ps1') -Check
& (Join-Path $Root 'Build.ps1') -HeadersOnly | Out-Null

# ---- 2. training exe: msvc target of the same clang, Visual Studio C runtime
Write-Host '== training exe ==' -ForegroundColor Cyan
$vc = cmd /c "call `"$vcvars`" >nul 2>&1 && set"
foreach ($line in $vc) { if ($line -match '^(INCLUDE|LIB|LIBPATH|PATH)=(.*)$') { Set-Item -Path "env:$($Matches[1])" -Value $Matches[2] } }
$obj = Join-Path $Work 'obj'
if (Test-Path $Work) { Remove-Item $Work -Recurse -Force }
New-Item -ItemType Directory -Force $obj | Out-Null
$inc = @(('-I' + (Join-Path $Root 'Source\shim')), ('-I' + (Join-Path $Root 'Gen\libxml2')),
         ('-I' + (Join-Path $Root 'Source\libxml2\include')), ('-I' + (Join-Path $Root 'Source\libxml2')))
$flags = @('-std=c11', '-O3', '-fno-math-errno', '-DNDEBUG', '-DLIBXML_STATIC', '-DHAVE_CONFIG_H', '-fprofile-generate', '-w') + $inc
function Invoke-Clang([string[]]$ArgList) {
    $out = & $Clang @ArgList 2>&1 | ForEach-Object { "$_" }
    if ($LASTEXITCODE -ne 0) { throw "clang exited with code ${LASTEXITCODE}:`n$($out -join "`n")" }
}
$objs = @()
$sources = @(Get-ChildItem (Join-Path $Root 'Source\libxml2') -Filter *.c) + @(Get-Item (Join-Path $Root 'Source\shim\lx2_iconv.c'))
foreach ($src in $sources) {
    $o = Join-Path $obj ($src.BaseName + '.o')
    Invoke-Clang ($flags + @('-c', $src.FullName, '-o', $o))
    $objs += $o
}
$train = Join-Path $Work 'train.exe'
Invoke-Clang ($flags + @((Join-Path $Root 'Pgo\train.c')) + $objs + @('-lbcrypt', '-o', $train))

# ---- 3. training run
Write-Host '== training run ==' -ForegroundColor Cyan
$env:LLVM_PROFILE_FILE = Join-Path $Work 'train_%p.profraw'
& $train $Rounds @files
if ($LASTEXITCODE -ne 0) { throw 'the training run failed on some documents (see above)' }
$raw = @(Get-ChildItem $Work -Filter *.profraw | ForEach-Object { $_.FullName })
if ($raw.Count -eq 0) { throw 'the training run wrote no profile' }
$merge = & $ProfData merge -o $Profile @raw 2>&1 | ForEach-Object { "$_" }
if ($LASTEXITCODE -ne 0) { throw "llvm-profdata merge failed:`n$($merge -join "`n")" }
Write-Host "profile: $Profile ($([math]::Round((Get-Item $Profile).Length / 1KB)) KB)"

# ---- 4. the objects
& (Join-Path $Root 'Build.ps1') -Clang $Clang -Profile $Profile -Test:$Test

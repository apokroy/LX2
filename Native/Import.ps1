<#
.SYNOPSIS
    Updates the libxml2 and libxslt sources to stable releases from GitHub.

.DESCRIPTION
    The release archives are taken by tag from the GNOME mirrors on GitHub
    (github.com/GNOME/libxml2, github.com/GNOME/libxslt). From libxml2 the library proper is
    copied: the modules of LIBXML2_SRCS in the release's CMakeLists.txt minus those that
    serve features disabled in Build.ps1 (HTTP, dynamic modules, lzma), the headers of
    include\libxml and include\private, the internal headers of the root, Copyright and
    VERSION. From libxslt the libxslt\ directory (the library itself, without libexslt and
    xsltproc) and Copyright; VERSION is written from the m4_define lines of configure.ac
    (libxslt has no VERSION file).

    The files go to Source\libxml2 and Source\libxslt; the previous contents of the
    directories are removed entirely so that a module dropped by a release does not linger
    in the build. After the import the objects are rebuilt with Build.ps1 -Test, and the
    sources are committed together with Lib\ and the generated ..\Source\LX2.Static.pas.

    The version series is pinned in the script ($Series): "latest stable" is searched within
    the series because every minor libxml2 version changes the API, so moving to the next
    series is a deliberate step together with a run of the LX2 tests and, if needed, edits
    to libxml2.API.pas. Upstream fixes only the newest branch (2.15 since autumn 2025);
    older branches are closed the day a new one appears.

.PARAMETER LibXml2
    libxml2 version without the v prefix, e.g. 2.15.4. Without it: the latest tag of the series.
.PARAMETER LibXslt
    libxslt version without the v prefix, e.g. 1.1.45. Without it: the latest tag of the series.

.EXAMPLE
    .\Import.ps1
    .\Import.ps1 -LibXml2 2.15.4 -LibXslt 1.1.45
    .\Build.ps1 -Test
#>
[CmdletBinding()]
param(
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$LibXml2,
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$LibXslt
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$Headers = @{ 'User-Agent' = 'LX2-Import' }
$Series = @{ libxml2 = '2.15'; libxslt = '1.1' }

# Modules that implement the features disabled in Build.ps1 (HTTP, dynamic modules, lzma);
# the rest of the module list is read from the release's CMakeLists.txt, as it changes from
# version to version.
$LibXml2Excluded = @('nanohttp.c', 'xmlmodule.c', 'xzlib.c')

function Get-LibXml2Sources([string]$Src) {
    $cm = Get-Content (Join-Path $Src 'CMakeLists.txt') -Raw
    $base = [regex]::Match($cm, 'set\(\s*LIBXML2_SRCS(.*?)\)', 'Singleline').Groups[1].Value
    $appends = [regex]::Matches($cm, 'list\(APPEND LIBXML2_SRCS ([^)]*)\)') | ForEach-Object { $_.Groups[1].Value }
    $names = (($base + ' ' + ($appends -join ' ')) -split '\s+') | Where-Object { $_ -match '\.c$' } |
        Where-Object { $LibXml2Excluded -notcontains $_ } | Sort-Object -Unique
    if ($names.Count -lt 20) { throw "Only $($names.Count) modules read from the libxml2 CMakeLists.txt; the list format has changed" }
    return $names
}

function Get-LatestTag([string]$Repo, [string]$SeriesPrefix) {
    $tags = Invoke-RestMethod -Uri "https://api.github.com/repos/GNOME/$Repo/tags?per_page=100" -Headers $Headers
    $found = $tags | ForEach-Object { $_.name } | Where-Object { $_ -match "^v$([regex]::Escape($SeriesPrefix))\.(\d+)$" } |
        Sort-Object { [int]($_ -replace '^v\d+\.\d+\.', '') } -Descending | Select-Object -First 1
    if (-not $found) { throw "github.com/GNOME/$Repo has no tags of the $SeriesPrefix series" }
    return $found.TrimStart('v')
}

function Get-Release([string]$Repo, [string]$Version, [string]$Tmp) {
    $zip = Join-Path $Tmp "$Repo.zip"
    $url = "https://github.com/GNOME/$Repo/archive/refs/tags/v$Version.zip"
    Write-Host "Downloading $url"
    Invoke-WebRequest -Uri $url -OutFile $zip
    Expand-Archive -Path $zip -DestinationPath $Tmp -Force
    $dir = Join-Path $Tmp "$Repo-$Version"
    if (-not (Test-Path $dir)) { throw "The archive has no $Repo-$Version directory" }
    return $dir
}

function Reset-Directory([string]$Dir) {
    if (Test-Path $Dir) { Remove-Item $Dir -Recurse -Force }
    New-Item -ItemType Directory -Force $Dir | Out-Null
}

if (-not $LibXml2) { $LibXml2 = Get-LatestTag 'libxml2' $Series.libxml2; Write-Host "libxml2: latest release of the $($Series.libxml2) series is $LibXml2" }
if (-not $LibXslt) { $LibXslt = Get-LatestTag 'libxslt' $Series.libxslt; Write-Host "libxslt: latest release of the $($Series.libxslt) series is $LibXslt" }

$tmp = Join-Path ([IO.Path]::GetTempPath()) "lx2-import-$PID"
New-Item -ItemType Directory -Force $tmp | Out-Null
try {
    # ---- libxml2
    $src = Get-Release 'libxml2' $LibXml2 $tmp
    $dst = Join-Path $Root 'Source\libxml2'
    Reset-Directory $dst
    New-Item -ItemType Directory -Force (Join-Path $dst 'include\libxml'), (Join-Path $dst 'include\private') | Out-Null
    $sources = Get-LibXml2Sources $src
    foreach ($name in $sources + @('Copyright', 'VERSION')) {
        $f = Join-Path $src $name
        if (-not (Test-Path $f)) { throw "libxml2 $LibXml2 does not contain $name listed in its own CMakeLists.txt" }
        Copy-Item $f (Join-Path $dst $name)
    }
    # Internal headers of the root (libxml.h, timsort.h) and the generated tables: *.inc in the
    # root up to 2.14, codegen\*.inc from 2.15 on (the Python generators are not copied).
    Get-ChildItem $src -File | Where-Object { $_.Extension -in '.h', '.inc' } | Copy-Item -Destination $dst
    if (Test-Path (Join-Path $src 'codegen')) {
        New-Item -ItemType Directory -Force (Join-Path $dst 'codegen') | Out-Null
        Copy-Item (Join-Path $src 'codegen\*.inc') (Join-Path $dst 'codegen')
    }
    Copy-Item (Join-Path $src 'include\libxml\*.h') (Join-Path $dst 'include\libxml')
    Copy-Item (Join-Path $src 'include\libxml\xmlversion.h.in') (Join-Path $dst 'include\libxml')
    Copy-Item (Join-Path $src 'include\private\*.h') (Join-Path $dst 'include\private')
    $stamp = (Get-Content (Join-Path $dst 'VERSION') -TotalCount 1).Trim()
    if ($stamp -ne $LibXml2) { throw "libxml2 VERSION says $stamp, expected $LibXml2" }
    Write-Host "libxml2: $($sources.Count) modules from CMakeLists.txt"

    # ---- libxslt
    $src = Get-Release 'libxslt' $LibXslt $tmp
    $dst = Join-Path $Root 'Source\libxslt'
    Reset-Directory $dst
    Copy-Item (Join-Path $src 'libxslt\*.c'), (Join-Path $src 'libxslt\*.h'), (Join-Path $src 'libxslt\xsltconfig.h.in') $dst
    Copy-Item (Join-Path $src 'Copyright') (Join-Path $dst 'Copyright')
    $ac = Get-Content (Join-Path $src 'configure.ac')
    $parts = foreach ($field in 'MAJOR', 'MINOR', 'MICRO') {
        $m = $ac | Select-String -Pattern "m4_define\(\[${field}_VERSION\],\s*\[(\d+)\]\)" | Select-Object -First 1
        if (-not $m) { throw "libxslt configure.ac has no m4_define([${field}_VERSION], [...])" }
        $m.Matches[0].Groups[1].Value
    }
    $stamp = $parts -join '.'
    if ($stamp -ne $LibXslt) { throw "libxslt configure.ac says version $stamp, expected $LibXslt" }
    Set-Content -Path (Join-Path $dst 'VERSION') -Value $stamp -NoNewline -Encoding ASCII

    Write-Host "Imported libxml2 $LibXml2 and libxslt $LibXslt. Next: .\Build.ps1 -Test" -ForegroundColor Green
}
finally {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

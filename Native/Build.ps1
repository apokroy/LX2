<#
.SYNOPSIS
    Static build of libxml2 and libxslt for LX2: Win64 objects, the Linux64 archive and the
    LX2.Static.pas unit.

.DESCRIPTION
    The compiler is bcc64x (clang 20) shipped with RAD Studio, target x86_64-w64-windows-gnu.
    Source\libxml2, Source\libxslt and Source\shim are compiled into COFF objects in
    Lib\Win64; then ..\Source\LX2.Static.pas is generated from the declarations in
    libxml2.API.pas and libxslt.API.pas: one {$L} per object, the C runtime and Win32
    imports, the library entry points and the binding of the API pointer variables to
    them. A program only adds LX2.Static to its uses clause: LX2Lib.Load and XSLTLib.Load
    then bind to the objects instead of loading a DLL.

    The libraries are not freestanding, they need a C runtime. It comes from ucrtbase.dll
    (present on every Windows 10 and later) through external declarations in
    LX2.Static.pas; the names ucrtbase does not export (the printf family) are provided
    by Source\shim\crt_shim.c. The Win32 API is declared by hand in Source\shim\windows.h
    because bcc64x ships no SDK headers. iconv is Source\shim\lx2_iconv.c on top of
    MultiByteToWideChar.

    After compilation the invariants that linking relies on are verified: every
    unresolved symbol of an object is either a symbol of a sibling object or one of the
    names covered by LX2.Static.pas, and no object has global constructor sections.

    Flags: speed over size (-O3). The baseline ISA is x86-64 with SSE2, no -march: the
    libraries do not dispatch on CPUID, and an object with AVX would crash on CPUs
    without it.

    Linux64: the same sources, target x86_64-linux-gnu with a PAServer SDK, go into the
    archive Lib\Linux64\liblx2native.a; dcclinux64 has no {$L}, so LX2.Static.pas declares
    the entry points as external 'liblx2native.a'. The shim directory is not used there:
    the C runtime, iconv and pthreads are glibc. The objects may only reference the glibc
    names listed in $GlibcImports; the youngest of them, statx, sets the floor at glibc 2.28
    (Ubuntu 20.04 has 2.31). stat() goes through Source\shim_linux, see lx2_stat.h.

.PARAMETER Platforms
    Subset of Win64, Linux64 to compile. Both by default. LX2.Static.pas is always generated
    for both from whatever Lib\ holds.
.PARAMETER LinuxSdk
    PAServer SDK directory for Linux64; by default Default_Linux64 from the IDE settings.
.PARAMETER StudioRoot
    RAD Studio directory; by default from the registry key
    HKCU\Software\Embarcadero\BDS\<BdsVersion>.
.PARAMETER Test
    After the build, compile Tests\LX2StaticSmoke.dpr and run it: dcc64 for Win64,
    dcclinux64 and WSL (when present) for Linux64.
.PARAMETER SkipBuild
    Do not compile the objects: only generate LX2.Static.pas and run the tests.
.PARAMETER Clang
    Path to a clang.exe of another LLVM (upstream, or the one of Visual Studio) to compile
    the objects with instead of bcc64x, same target and flags; the headers still come from
    RAD Studio. Pgo.ps1 uses it: bcc64x builds instrumented code but does not read the
    profiles back.
.PARAMETER Profile
    An indexed profile (llvm-profdata merge) to compile with -fprofile-instr-use; needs
    -Clang.
.PARAMETER HeadersOnly
    Only generate the headers in Gen (Pgo.ps1 needs them before the build).

.EXAMPLE
    .\Build.ps1 -Test
#>
[CmdletBinding()]
param(
    [ValidateSet('Win64', 'Linux64')]
    [string[]]$Platforms = @('Win64', 'Linux64'),
    [string]$StudioRoot,
    [string]$LinuxSdk,
    [string]$BdsVersion = '37.0',
    [switch]$Test,
    [switch]$SkipBuild,
    [string]$Clang,
    [string]$Profile,
    [switch]$HeadersOnly
)

$ErrorActionPreference = 'Stop'
$Root    = $PSScriptRoot
$LX2Src  = Join-Path (Split-Path $Root -Parent) 'Source'
$Lib     = Join-Path $Root 'Lib\Win64'
$LibLinux = Join-Path $Root 'Lib\Linux64'
$LinuxArchiveName = 'liblx2native.a'
$LinuxArchive = Join-Path $LibLinux $LinuxArchiveName
$Gen     = Join-Path $Root 'Gen'
$GenLinux = Join-Path $Gen 'Linux64'

# ---------------------------------------------------------------------------
# Tools
# ---------------------------------------------------------------------------

if (-not $StudioRoot) {
    $key = "HKCU:\Software\Embarcadero\BDS\$BdsVersion"
    if (-not (Test-Path $key)) { $key = "HKLM:\SOFTWARE\WOW6432Node\Embarcadero\BDS\$BdsVersion" }
    $StudioRoot = (Get-ItemProperty $key).RootDir
}
$StudioRoot = $StudioRoot.TrimEnd('\')
$Bcc     = Join-Path $StudioRoot 'bin64\bcc64x.exe'
$Nm      = Join-Path $StudioRoot 'bin64\llvm-nm.exe'
$Ar      = Join-Path $StudioRoot 'bin64\llvm-ar.exe'
$Objdump = Join-Path $StudioRoot 'bin64\llvm-objdump.exe'
foreach ($tool in $Bcc, $Nm, $Ar, $Objdump) {
    if (-not (Test-Path $tool)) { throw "Not found: $tool" }
}
$StudioShort = (New-Object -ComObject Scripting.FileSystemObject).GetFolder($StudioRoot).ShortPath

function Resolve-LinuxSdk {
    if ($LinuxSdk) { return $LinuxSdk }
    $sdks = "HKCU:\Software\Embarcadero\BDS\$BdsVersion\PlatformSDKs"
    $name = (Get-ItemProperty $sdks -ErrorAction SilentlyContinue).Default_Linux64
    if (-not $name) { throw 'The IDE has no Linux64 SDK configured; pass -LinuxSdk' }
    $dir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) "Embarcadero\Studio\SDKs\$name"
    if (-not (Test-Path $dir)) { throw "SDK directory not found: $dir" }
    return $dir
}

function Get-LinuxGccDir([string]$Sdk) {
    $gcc = Get-ChildItem (Join-Path $Sdk 'usr\lib\gcc\x86_64-linux-gnu') -Directory | Select-Object -First 1
    if (-not $gcc) { throw "The SDK has no usr\lib\gcc\x86_64-linux-gnu: $Sdk" }
    return $gcc.FullName
}

# Another clang compiles the same sources for the same target with the headers of RAD
# Studio: its own system include directories are replaced by the two bcc64x uses, and
# __CODEGEARC__ takes the header branches bcc64x takes (the mingw headers otherwise ask
# for an SDK file Studio does not ship); _CRTIMP empty keeps the C runtime references
# plain names instead of __imp_ imports, which is what LX2.Static.pas declares.
$Compiler = $Bcc
$ForeignFlags = @()
$ProfileFlags = @()
if ($Clang) {
    if (-not (Test-Path $Clang)) { throw "Not found: $Clang" }
    $Compiler = $Clang
    $ForeignFlags = @('-nostdlibinc', ('-isystem' + (Join-Path $StudioRoot 'include\windows\sdk')),
                      ('-isystem' + (Join-Path $StudioRoot 'include\x86_64-w64-mingw32')),
                      '-D__CODEGEARC__=0x0780', '-D_CRTIMP=')
}
if ($Profile) {
    if (-not $Clang) { throw 'bcc64x does not read profiles: -Profile needs -Clang' }
    if (-not (Test-Path $Profile)) { throw "Not found: $Profile" }
    $ProfileFlags = @("-fprofile-instr-use=$Profile", '-Wno-profile-instr-unprofiled',
                      '-Wno-profile-instr-out-of-date', '-Wno-backend-plugin')
}

# ---------------------------------------------------------------------------
# Library features and generated headers
# ---------------------------------------------------------------------------

# libxml2 feature set (xmlversion.h). HTTP, modules, zlib and lzma are off: documents come
# from memory and streams, LX2 needs neither compressed files nor network loading, and each
# of these features pulls in its own library or a DLL load.
# RelaxNG, Schematron, XPointer, XInclude and the debug dumps are off as well: the binding
# exposes none of them, but dcc links every object whole, and xmlreader pulled RelaxNG and
# XInclude in on its own. xmlWriter stays: xmlTextReaderReadInnerXml/ReadOuterXml are built
# on it. HTML stays because libxslt calls htmlNewDoc and htmlDocContentDumpFormatOutput
# unconditionally (xsl:output method="html"). ISO8859X is meaningless with iconv on:
# encoding.c drops the tables whenever iconv is available.
# Import.ps1 skips the modules of every feature that is off here, so a feature switched back
# on needs its module re-imported first.
$LibXml2Features = @{
    WITH_THREADS = 1; WITH_THREAD_ALLOC = 0; WITH_OUTPUT = 1; WITH_PUSH = 1; WITH_READER = 1
    WITH_PATTERN = 1; WITH_WRITER = 1; WITH_SAX1 = 1; WITH_HTTP = 0; WITH_VALID = 1; WITH_HTML = 1
    WITH_LEGACY = 0; WITH_C14N = 1; WITH_CATALOG = 1; WITH_XPATH = 1; WITH_XPTR = 0
    WITH_XINCLUDE = 0; WITH_ICONV = 1; WITH_ICU = 0; WITH_ISO8859X = 0; WITH_DEBUG = 0
    WITH_REGEXPS = 1; WITH_RELAXNG = 0; WITH_SCHEMAS = 1; WITH_SCHEMATRON = 0
    WITH_MODULES = 0; WITH_ZLIB = 0; WITH_LZMA = 0
}
$LibXsltFeatures = @{
    WITH_XSLT_DEBUG = 0; WITH_TRIO = 0; WITH_DEBUGGER = 0; WITH_PROFILER = 1; WITH_MODULES = 0
}

function Expand-Template([string]$In, [string]$Out, [hashtable]$Values) {
    $t = Get-Content $In -Raw
    $missing = [regex]::Matches($t, '@([A-Z_0-9]+)@') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique |
        Where-Object { -not $Values.ContainsKey($_) }
    if ($missing) { throw "Template $In has placeholders without a value: $($missing -join ', ')" }
    foreach ($k in $Values.Keys) { $t = $t.Replace("@$k@", [string]$Values[$k]) }
    New-Item -ItemType Directory -Force (Split-Path $Out -Parent) | Out-Null
    [IO.File]::WriteAllText($Out, $t)
}

function Write-GeneratedHeaders {
    $xmlVer = (Get-Content (Join-Path $Root 'Source\libxml2\VERSION') -TotalCount 1).Trim()
    $xsltVer = (Get-Content (Join-Path $Root 'Source\libxslt\VERSION') -TotalCount 1).Trim()
    $xv = $xmlVer.Split('.'); $sv = $xsltVer.Split('.')

    $values = @{ VERSION = $xmlVer; LIBXML_VERSION_NUMBER = ([int]$xv[0] * 10000 + [int]$xv[1] * 100 + [int]$xv[2])
                 LIBXML_VERSION_EXTRA = ''; MODULE_EXTENSION = '.dll' } + $LibXml2Features
    Expand-Template (Join-Path $Root 'Source\libxml2\include\libxml\xmlversion.h.in') (Join-Path $Gen 'libxml2\libxml\xmlversion.h') $values
    # libxml2 config.h: mingw target, no dlopen/mmap/getentropy/readline
    [IO.File]::WriteAllText((Join-Path $Gen 'libxml2\config.h'), @"
/* generated by Build.ps1 for x86_64-w64-windows-gnu */
#define HAVE_DECL_GETENTROPY 0
#define HAVE_DECL_GLOB 0
#define HAVE_DECL_MMAP 0
#define HAVE_STDINT_H 1
#define XML_SYSCONFDIR "/etc"
"@)

    $values = @{ VERSION = $xsltVer; LIBXSLT_VERSION_NUMBER = ([int]$sv[0] * 10000 + [int]$sv[1] * 100 + [int]$sv[2])
                 LIBXSLT_VERSION_EXTRA = ''; LIBXSLT_DEFAULT_PLUGINS_PATH = '' } + $LibXsltFeatures
    Expand-Template (Join-Path $Root 'Source\libxslt\xsltconfig.h.in') (Join-Path $Gen 'libxslt\libxslt\xsltconfig.h') $values
    # libxslt config.h: what the mingw runtime offers; locales go through WinAPI (xsltlocale.c picks _WIN32 itself)
    [IO.File]::WriteAllText((Join-Path $Gen 'libxslt\config.h'), @"
/* generated by Build.ps1 for x86_64-w64-windows-gnu */
#define PACKAGE "libxslt"
#define VERSION "$xsltVer"
#define HAVE_INTTYPES_H 1
#define HAVE_LOCALE_H 1
#define HAVE_SNPRINTF 1
#define HAVE_VSNPRINTF 1
#define HAVE_STAT 1
#define HAVE__STAT 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_SYS_TIMEB_H 1
#define HAVE_FTIME 1
"@)
    Write-Host "  headers: libxml2 $xmlVer, libxslt $xsltVer"
}

function Write-GeneratedHeadersLinux {
    # The version headers do not depend on the platform (the feature set is one), the
    # config.h files do: glibc has getentropy, mmap, glob, pthreads, newlocale and strxfrm_l.
    New-Item -ItemType Directory -Force (Join-Path $GenLinux 'libxml2\libxml'), (Join-Path $GenLinux 'libxslt\libxslt') | Out-Null
    Copy-Item (Join-Path $Gen 'libxml2\libxml\xmlversion.h') (Join-Path $GenLinux 'libxml2\libxml\xmlversion.h') -Force
    Copy-Item (Join-Path $Gen 'libxslt\libxslt\xsltconfig.h') (Join-Path $GenLinux 'libxslt\libxslt\xsltconfig.h') -Force
    $xsltVer = (Get-Content (Join-Path $Root 'Source\libxslt\VERSION') -TotalCount 1).Trim()
    [IO.File]::WriteAllText((Join-Path $GenLinux 'libxml2\config.h'), @"
/* generated by Build.ps1 for x86_64-linux-gnu */
#define HAVE_DECL_GETENTROPY 1
#define HAVE_DECL_GLOB 1
#define HAVE_DECL_MMAP 1
#define HAVE_STDINT_H 1
#define XML_SYSCONFDIR "/etc"
"@)
    [IO.File]::WriteAllText((Join-Path $GenLinux 'libxslt\config.h'), @"
/* generated by Build.ps1 for x86_64-linux-gnu */
#define PACKAGE "libxslt"
#define VERSION "$xsltVer"
#define HAVE_INTTYPES_H 1
#define HAVE_LOCALE_H 1
#define HAVE_STRXFRM_L 1
#define HAVE_SNPRINTF 1
#define HAVE_VSNPRINTF 1
#define HAVE_STAT 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_SYS_TIME_H 1
#define HAVE_UNISTD_H 1
#define HAVE_GETTIMEOFDAY 1
#define HAVE_CLOCK_GETTIME 1
"@)
}

# ---------------------------------------------------------------------------
# Compilation
# ---------------------------------------------------------------------------

# Speed over size: -O3 (full inlining and vectorisation of the parser loops) and
# -fno-math-errno, which lets clang treat the XPath math (floor, fmod, pow, sqrt) as pure
# functions and inline what the baseline ISA allows; libxml2 never reads errno after them.
# No -march: the baseline stays x86-64 with SSE2, the libraries do not dispatch on CPUID.
# -fno-zero-initialized-in-bss: zero-initialised globals go to .data instead of .bss;
# dcc treats a .bss symbol as a variable of its own and reports hint H2164 for it.
$CommonFlags = @('--target=x86_64-w64-windows-gnu', '-std=c11', '-O3', '-fno-math-errno', '-DNDEBUG',
                 '-DLIBXML_STATIC', '-DLIBXSLT_STATIC', '-DHAVE_CONFIG_H', '-fno-zero-initialized-in-bss',
                 '-Wno-deprecated-declarations', '-Wno-unused-parameter',
                 ('-I' + (Join-Path $Root 'Source\shim'))) + $ForeignFlags + $ProfileFlags
$LibXml2Include = @(('-I' + (Join-Path $Gen 'libxml2')), ('-I' + (Join-Path $Root 'Source\libxml2\include')), ('-I' + (Join-Path $Root 'Source\libxml2')))
$LibXsltInclude = @(('-I' + (Join-Path $Gen 'libxslt')), ('-I' + (Join-Path $Root 'Source')), ('-I' + (Join-Path $Root 'Source\libxslt'))) + $LibXml2Include

function Invoke-Bcc([string[]]$Arguments) {
    $out = & $Compiler @Arguments 2>&1 | Where-Object { $_ -notmatch '^Embarcadero C\+\+' }
    if ($LASTEXITCODE -ne 0) { throw "$(Split-Path $Compiler -Leaf) exited with code $LASTEXITCODE`n$($out -join "`n")" }
    if ($out) { $out | ForEach-Object { Write-Host "  $_" } }
}

function Build-Group([string]$Prefix, [string]$Dir, [string[]]$Include, [string]$OutDir = $Lib, [string[]]$Flags = $CommonFlags) {
    foreach ($src in Get-ChildItem (Join-Path $Root $Dir) -Filter *.c | Sort-Object Name) {
        $obj = Join-Path $OutDir ($Prefix + '_' + [IO.Path]::GetFileNameWithoutExtension($src.Name) + '.o')
        Invoke-Bcc ($Flags + $Include + @('-c', $src.FullName, '-o', $obj))
    }
}

# Names the Linux objects may take from glibc (libc, libm, libpthread). The youngest is statx
# (glibc 2.28), which is the floor of the archive; stat64 must not come back, it is a function
# only since glibc 2.33 (Source\shim_linux\lx2_stat.h). The list is closed on
# purpose: with _GNU_SOURCE, or with -std=c2x, the glibc 2.38 headers redirect sscanf and
# strtoul to __isoc23_* and the executable stops loading on every older distribution.
$GlibcImports = @(
    '__ctype_toupper_loc', '__errno_location', '__isoc99_sscanf', 'abort', 'calloc', 'ceil', 'clock_gettime', 'close',
    'dup', 'exit', 'fclose', 'ferror', 'fflush', 'floor', 'fmod', 'fopen64', 'fprintf', 'fputc', 'fputs', 'fread',
    'free', 'freelocale', 'fwrite', 'getentropy', 'getenv', 'iconv', 'iconv_close', 'iconv_open', 'log10', 'malloc',
    'memchr', 'memcpy', 'memmove', 'memset', 'mkdir', 'newlocale', 'open64', 'pow',
    'pthread_cond_destroy', 'pthread_cond_init', 'pthread_cond_signal', 'pthread_cond_wait', 'pthread_getspecific',
    'pthread_key_create', 'pthread_key_delete', 'pthread_mutex_destroy', 'pthread_mutex_init', 'pthread_mutex_lock',
    'pthread_mutex_unlock', 'pthread_once', 'pthread_self', 'pthread_setspecific', 'read', 'realloc', 'snprintf',
    'statx', 'stderr', 'stdin', 'stdout', 'strcat', 'strchr', 'strcmp', 'strlen', 'strncmp', 'strncpy', 'strstr',
    'strtoul', 'strxfrm_l', 'time', 'vfprintf', 'vsnprintf', 'write'
)

function Build-Linux64 {
    $sdk = Resolve-LinuxSdk
    Write-GeneratedHeadersLinux
    $tmp = Join-Path ([IO.Path]::GetTempPath()) "lx2-linux64-$PID"
    New-Item -ItemType Directory -Force $tmp, $LibLinux | Out-Null
    try {
        # gnu11 rather than c11 plus _GNU_SOURCE: POSIX names stay visible and the C23
        # redirects stay off. bcc64x does not define __STDC__ in C mode and the glibc headers
        # refuse to compile without it. No shim directory: its iconv.h and windows.h are for
        # the Windows build only.
        $flags = @('--target=x86_64-linux-gnu', "--sysroot=$sdk", '-fPIC', '-D__STDC__=1', '-std=gnu11', '-O3',
                   '-fno-math-errno', '-DNDEBUG', '-DLIBXML_STATIC', '-DLIBXSLT_STATIC', '-DHAVE_CONFIG_H',
                   '-Wno-deprecated-declarations', '-Wno-unused-parameter')
        $xmlInc = @(('-I' + (Join-Path $GenLinux 'libxml2')), ('-I' + (Join-Path $Root 'Source\libxml2\include')), ('-I' + (Join-Path $Root 'Source\libxml2')))
        $xsltInc = @(('-I' + (Join-Path $GenLinux 'libxslt')), ('-I' + (Join-Path $Root 'Source')), ('-I' + (Join-Path $Root 'Source\libxslt'))) + $xmlInc
        # The library sources get lx2_stat.h in front of everything else; the shim itself does
        # not, it needs _GNU_SOURCE before the first system header.
        $libFlags = $flags + @('-include', (Join-Path $Root 'Source\shim_linux\lx2_stat.h'))
        Build-Group 'xml'  'Source\libxml2' $xmlInc  $tmp $libFlags
        Build-Group 'xslt' 'Source\libxslt' $xsltInc $tmp $libFlags
        Build-Group 'shim' 'Source\shim_linux' @() $tmp $flags

        $objs = Get-ChildItem $tmp -Filter *.o | Sort-Object Name | ForEach-Object { $_.FullName }
        $defined = @{}
        foreach ($obj in $objs) { foreach ($d in Get-Symbols $obj 'D') { $defined[$d] = $true } }
        $problems = @()
        foreach ($obj in $objs) {
            $extra = @(Get-Symbols $obj 'U') | Where-Object { (-not $defined.ContainsKey($_)) -and ($GlibcImports -notcontains $_) }
            if ($extra) { $problems += "$(Split-Path $obj -Leaf): $($extra -join ', ')" }
            $sections = & $Objdump -h $obj | Where-Object { $_ -match '\.ctors|\.init_array|\.dtors|\.fini_array' }
            if ($sections) { throw "$obj has global constructor sections:`n$($sections -join "`n")" }
        }
        if ($problems) { throw "Linux objects reference names outside `$GlibcImports:`n  $($problems -join "`n  ")" }

        Remove-Item $LinuxArchive -ErrorAction SilentlyContinue
        & $Ar rcs $LinuxArchive @objs
        if ($LASTEXITCODE -ne 0) { throw "llvm-ar exited with code $LASTEXITCODE" }
        Write-Host ("  {0}: {1} objects, {2:N0} bytes" -f $LinuxArchiveName, $objs.Count, (Get-Item $LinuxArchive).Length)
    }
    finally {
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Get-LinuxDefined {
    # Entry points the archive offers; the generator binds only those.
    $defined = @{}
    if (Test-Path $LinuxArchive) {
        & $Nm --defined-only $LinuxArchive | ForEach-Object {
            if ($_ -match '^\S+\s+[TDRBC]\s+(\S+)$') { $defined[$Matches[1]] = $true }
        }
    }
    return $defined
}

# ---------------------------------------------------------------------------
# Object invariants
# ---------------------------------------------------------------------------

# Names that LX2.Static.pas covers with imports: the C runtime from ucrtbase.dll, Win32 from
# kernel32/bcrypt, the clang stack probe. A new symbol fails the build here rather than at
# link time on a colleague's machine.
$CrtImports = @(
    'memcpy', 'memmove', 'memset', 'memchr', 'memcmp', 'strlen', 'strcmp', 'strncmp', 'strchr',
    'strrchr', 'strstr', 'strcat', 'strcpy', 'strncpy', 'strtol', 'strtoul', 'strtod', 'strtoll',
    'strtoull', 'atoi', 'atol', 'toupper', 'tolower', 'isspace', 'isdigit', 'isalpha', 'isalnum', 'bsearch',
    'qsort', 'abort', 'exit', 'malloc', 'calloc', 'realloc', 'free', 'getenv', '_errno',
    'fopen', 'fclose', 'fread', 'fwrite', 'fputs', 'fputc', 'fflush', 'ftell', 'fseek',
    '_wfopen', '_wopen', '_open', '_close', '_read', '_write', '_dup', 'ferror', '_lseeki64', '_lseek',
    '_wstat64', '_stat64', '_wstat64i32', '_stat64i32', '_fstat64', '_fstat64i32',
    '__acrt_iob_func', '__stdio_common_vsprintf', '__stdio_common_vfprintf', '__stdio_common_vsscanf',
    'floor', 'ceil', 'fmod', 'pow', 'log10', 'fabs', 'trunc', 'round', 'log', 'exp', 'sqrt',
    'clock', 'time', '_time64', 'localtime', '_localtime64', 'gmtime', '_gmtime64', '_ftime64',
    '_mkdir', '_wmkdir', '_unlink', '_wunlink', 'rand', 'srand'
)
$Win32Imports = @{
    'kernel32.dll' = @('InitializeCriticalSection', 'DeleteCriticalSection', 'EnterCriticalSection', 'LeaveCriticalSection',
                       'InitOnceExecuteOnce', 'TlsAlloc', 'TlsFree', 'TlsGetValue', 'TlsSetValue',
                       'RegisterWaitForSingleObject', 'UnregisterWait', 'CloseHandle', 'DuplicateHandle',
                       'GetCurrentProcess', 'GetCurrentThread', 'GetLastError', 'SetLastError',
                       'MultiByteToWideChar', 'WideCharToMultiByte', 'GetACP', 'IsValidCodePage', 'IsDBCSLeadByteEx', 'GetCPInfo',
                       'GetLocaleInfoA', 'EnumSystemLocalesA', 'LCMapStringW',
                       'QueryPerformanceCounter', 'QueryPerformanceFrequency', 'GetFileAttributesA')
    'bcrypt.dll'   = @('BCryptGenRandom')
}
$StackProbe = '___chkstk_ms'

function Get-Symbols([string]$Obj, [string]$Kind) {
    $flag = if ($Kind -eq 'U') { '-u' } else { '--defined-only' }
    & $Nm $flag $Obj | ForEach-Object {
        if ($Kind -eq 'U') { if ($_ -match '^\s*U\s+(\S+)$') { $Matches[1] } }
        elseif ($_ -match '^\S+\s+[TDRBC]\s+(\S+)$') { $Matches[1] }
    } | Sort-Object -Unique
}

function Assert-ObjectInvariants {
    $objs = Get-ChildItem $Lib -Filter *.o | ForEach-Object { $_.FullName }
    $defined = @{}
    foreach ($obj in $objs) { foreach ($d in Get-Symbols $obj 'D') { $defined[$d] = $true } }
    $allowed = $CrtImports + ($Win32Imports.Values | ForEach-Object { $_ }) + @($StackProbe)
    $external = @{}
    $internal = @{}
    $problems = @()
    $total = 0
    foreach ($obj in $objs) {
        $undef = @(Get-Symbols $obj 'U')
        $extra = $undef | Where-Object { (-not $defined.ContainsKey($_)) -and ($allowed -notcontains $_) }
        if ($extra) { $problems += "$(Split-Path $obj -Leaf): $($extra -join ', ')" }
        $sections = & $Objdump -h $obj | Where-Object { $_ -match '\.CRT\$|\.ctors|\.init_array' }
        if ($sections) { throw "$obj has global constructor sections:`n$($sections -join "`n")" }
        foreach ($u in $undef) {
            if ($defined.ContainsKey($u)) { $internal[$u] = $true } else { $external[$u] = $true }
        }
        $total += (Get-Item $obj).Length
    }
    if ($problems) { throw "Objects reference symbols that LX2.Static.pas does not cover:`n  $($problems -join "`n  ")" }
    Write-Host ("  objects: {0}, {1:N0} bytes; external symbols: {2}, cross-object references: {3}" -f $objs.Count, $total, $external.Count, $internal.Count)
    return @{
        External = @($external.Keys | Sort-Object)
        Internal = @($internal.Keys | Sort-Object)
        Defined  = $defined
    }
}

# ---------------------------------------------------------------------------
# Generation of LX2.Static.pas
# ---------------------------------------------------------------------------

function Get-ApiBindings([string]$UnitFile) {
    # The names come from the load region (GetProcAddress): they are the library symbols.
    # The signatures come from the pointer variable declarations of the same unit, either
    # directly as `name: function(...): T; cdecl;` or through a procedural type
    # `name: TFunc;` with `TFunc = function(...): T; cdecl;`. Names compare
    # case-insensitively, as in Pascal.
    $text = Get-Content $UnitFile -Raw
    $names = [regex]::Matches($text, "GetProcAddress\(Handle,\s*'(\w+)'\)") | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
    $sig = '\s*(function|procedure)\s*(\([^()]*\))?\s*(:\s*[^;]+?)?\s*;?\s*cdecl\s*;'
    $types = @{}
    foreach ($m in [regex]::Matches($text, '(?m)^\s*(\w+)\s*=' + $sig)) {
        $types[$m.Groups[1].Value.ToLowerInvariant()] = @{ Kind = $m.Groups[2].Value; Params = $m.Groups[3].Value; Ret = $m.Groups[4].Value }
    }
    $decls = @{}
    foreach ($m in [regex]::Matches($text, '(?m)^\s*(\w+)\s*:' + $sig)) {
        $decls[$m.Groups[1].Value.ToLowerInvariant()] = @{ Kind = $m.Groups[2].Value; Params = $m.Groups[3].Value; Ret = $m.Groups[4].Value }
    }
    foreach ($m in [regex]::Matches($text, '(?m)^\s*(\w+)\s*:\s*(\w+)\s*;')) {
        $k = $m.Groups[1].Value.ToLowerInvariant()
        $ty = $m.Groups[2].Value.ToLowerInvariant()
        if (-not $decls.ContainsKey($k) -and $types.ContainsKey($ty)) { $decls[$k] = $types[$ty] }
    }
    $missing = @($names | Where-Object { -not $decls.ContainsKey($_.ToLowerInvariant()) })
    if ($missing) { throw "${UnitFile}: no declaration of the form 'name: function(...); cdecl;' for: $($missing -join ', ')" }
    return $names | ForEach-Object {
        $d = $decls[$_.ToLowerInvariant()]
        [pscustomobject]@{ Name = $_; Kind = $d.Kind; Params = $d.Params; Ret = $d.Ret }
    }
}

function Write-StaticUnit($Symbols) {
    # dcc matches object references to declarations by the Pascal identifier, so every
    # symbol is declared under its exact name: API entry points with their signature,
    # cross-object references and runtime imports as parameterless procedures (Pascal never
    # calls them). The API pointer variables are assigned through the unit name: inside
    # LX2.Static their identifiers are taken by the symbol declarations.
    $xml = Get-ApiBindings (Join-Path $LX2Src 'libxml2.API.pas')
    $xslt = Get-ApiBindings (Join-Path $LX2Src 'libxslt.API.pas')
    $apiNames = @{}
    foreach ($b in $xml + $xslt) { $apiNames[$b.Name.ToLowerInvariant()] = $true }

    $sb = New-Object System.Text.StringBuilder
    $w = { param($s) [void]$sb.AppendLine($s) }

    & $w "unit LX2.Static;"
    & $w ""
    & $w "// Generated by Native\Build.ps1 - do not edit."
    & $w "//"
    & $w "// Static linking of libxml2 and libxslt. Win64: the objects from Native\Lib\Win64, the C"
    & $w "// runtime from ucrtbase.dll, Win32 from kernel32/bcrypt. Linux64: the archive"
    & $w "// Native\Lib\Linux64\$LinuxArchiveName on the library path, the C runtime is glibc. Adding the"
    & $w "// unit to a uses clause makes LX2Lib.Load and XSLTLib.Load bind to the static code instead"
    & $w "// of loading a library file."
    & $w ""
    & $w "interface"
    & $w ""
    & $w "implementation"
    & $w ""
    & $w "// On the other platforms the unit is empty and Load keeps loading the library file."
    & $w "{`$IFDEF WIN64}"
    & $w ""
    & $w "uses"
    & $w "  Winapi.Windows, System.Types, System.SysUtils, libxml2.API, libxslt.API;"
    & $w ""
    & $w "{`$region 'objects'}"
    foreach ($obj in Get-ChildItem $Lib -Filter *.o | Sort-Object Name) {
        & $w "{`$L ..\Native\Lib\Win64\$($obj.Name)}"
    }
    & $w "{`$endregion}"
    & $w ""
    & $w "{`$region 'C runtime and Win32'}"
    & $w "// The declarations exist for the linker only; Build.ps1 checks the list against the"
    & $w "// unresolved symbols of the objects."
    & $w ""
    foreach ($s in $Symbols.External | Where-Object { $CrtImports -contains $_ }) {
        & $w "procedure $s; cdecl; external 'ucrtbase.dll';"
    }
    & $w ""
    foreach ($dll in $Win32Imports.Keys | Sort-Object) {
        foreach ($s in $Win32Imports[$dll]) {
            if ($Symbols.External -contains $s) { & $w "procedure $s; stdcall; external '$dll';" }
        }
    }
    & $w ""
    & $w "// clang stack probe for frames larger than a page: rax = frame size; it only touches the"
    & $w "// pages one by one, leaves rsp alone and preserves every register except r10/r11."
    & $w "procedure ___chkstk_ms;"
    & $w "asm"
    & $w "        lea     r10, [rsp]"
    & $w "        mov     r11, r10"
    & $w "        sub     r11, rax"
    & $w "        and     r11w, 0f000h"
    & $w "        and     r10w, 0f000h"
    & $w "@@loop1:"
    & $w "        sub     r10, 01000h"
    & $w "        cmp     r10, r11"
    & $w "        jl      @@exit"
    & $w "        mov     qword [r10], 0"
    & $w "        jmp     @@loop1"
    & $w "@@exit:"
    & $w "end;"
    & $w "{`$endregion}"
    & $w ""
    & $w "{`$region 'cross-object references'}"
    foreach ($s in $Symbols.Internal) {
        if (-not $apiNames.ContainsKey($s.ToLowerInvariant())) { & $w "procedure $s; cdecl; external;" }
    }
    & $w "{`$endregion}"
    & $w ""
    $unbound = @()
    foreach ($group in @(@{ Title = 'libxml2'; Unit = 'libxml2.API'; Items = $xml; Binder = 'BindLibXml2' },
                         @{ Title = 'libxslt'; Unit = 'libxslt.API'; Items = $xslt; Binder = 'BindLibXslt' })) {
        $bound = @($group.Items | Where-Object { $Symbols.Defined.ContainsKey($_.Name) })
        $unbound += @($group.Items | Where-Object { -not $Symbols.Defined.ContainsKey($_.Name) } | ForEach-Object { $_.Name })
        & $w "{`$region '$($group.Title)'}"
        foreach ($b in $bound) {
            $sig = if ($b.Kind -eq 'function') { "function $($b.Name)$($b.Params)$($b.Ret); cdecl; external;" }
                   else { "procedure $($b.Name)$($b.Params); cdecl; external;" }
            & $w $sig
        }
        & $w ""
        & $w "procedure $($group.Binder);"
        & $w "begin"
        foreach ($b in $bound) { & $w "  $($group.Unit).$($b.Name) := @$($b.Name);" }
        & $w "end;"
        & $w "{`$endregion}"
        & $w ""
    }
    & $w "{`$ENDIF WIN64}"
    & $w ""
    $linuxDefined = Get-LinuxDefined
    & $w "{`$IFDEF LINUX64}"
    & $w ""
    & $w "uses"
    & $w "  Posix.StdDef, System.Types, System.SysUtils, libxml2.API, libxslt.API;"
    & $w ""
    & $w "const"
    & $w "  NativeLib = '$LinuxArchiveName';"
    & $w ""
    $unboundLinux = @()
    foreach ($group in @(@{ Title = 'libxml2'; Unit = 'libxml2.API'; Items = $xml; Binder = 'BindLibXml2' },
                         @{ Title = 'libxslt'; Unit = 'libxslt.API'; Items = $xslt; Binder = 'BindLibXslt' })) {
        $bound = @($group.Items | Where-Object { $linuxDefined.ContainsKey($_.Name) })
        $unboundLinux += @($group.Items | Where-Object { -not $linuxDefined.ContainsKey($_.Name) } | ForEach-Object { $_.Name })
        & $w "{`$region '$($group.Title)'}"
        foreach ($b in $bound) {
            $sig = if ($b.Kind -eq 'function') { "function $($b.Name)$($b.Params)$($b.Ret); cdecl; external NativeLib name '$($b.Name)';" }
                   else { "procedure $($b.Name)$($b.Params); cdecl; external NativeLib name '$($b.Name)';" }
            & $w $sig
        }
        & $w ""
        & $w "procedure $($group.Binder);"
        & $w "begin"
        foreach ($b in $bound) { & $w "  $($group.Unit).$($b.Name) := @$($b.Name);" }
        & $w "end;"
        & $w "{`$endregion}"
        & $w ""
    }
    & $w "{`$ENDIF LINUX64}"
    & $w ""
    & $w "{`$IF Defined(WIN64) or Defined(LINUX64)}"
    & $w "initialization"
    & $w "  LX2Lib.StaticBinder := BindLibXml2;"
    & $w "  XSLTLib.StaticBinder := BindLibXslt;"
    & $w "{`$ENDIF}"
    & $w ""
    & $w "end."
    $path = Join-Path $LX2Src 'LX2.Static.pas'
    $bytes = [Text.Encoding]::UTF8.GetPreamble() + [Text.Encoding]::UTF8.GetBytes($sb.ToString().Replace("`r`n", "`n").Replace("`n", "`r`n"))
    [IO.File]::WriteAllBytes($path, $bytes)
    Write-Host "  LX2.Static.pas: libxml2 $($xml.Count) entry points, libxslt $($xslt.Count)"
    if ($unbound) {
        Write-Host "  not part of the build (pointers stay nil): $($unbound -join ', ')" -ForegroundColor Yellow
    }
    if (-not $linuxDefined.Count) {
        Write-Host "  no ${LinuxArchiveName}: the Linux64 part of the unit binds nothing" -ForegroundColor Yellow
    }
    else {
        $diff = @(Compare-Object @($unbound | Sort-Object) @($unboundLinux | Sort-Object) | ForEach-Object { "$($_.InputObject) $($_.SideIndicator)" })
        if ($diff) { Write-Host "  bound differently on Win64 (<=) and Linux64 (=>): $($diff -join ', ')" -ForegroundColor Yellow }
    }
}

# ---------------------------------------------------------------------------
# Build steps
# ---------------------------------------------------------------------------

if (-not $SkipBuild) {
    Write-Host '== patches ==' -ForegroundColor Cyan
    & (Join-Path $Root 'Patches.ps1') -Check
    Write-Host '== headers ==' -ForegroundColor Cyan
    Write-GeneratedHeaders
    if ($HeadersOnly) { Write-Host 'Done (headers only).' -ForegroundColor Green; return }
    if ($Platforms -contains 'Win64') {
        Write-Host "== compile Win64 ($(Split-Path $Compiler -Leaf)$(if ($Profile) { ', profile-guided' })) ==" -ForegroundColor Cyan
        if (Test-Path $Lib) { Remove-Item (Join-Path $Lib '*.o') -Force }
        New-Item -ItemType Directory -Force $Lib | Out-Null
        Build-Group 'xml'  'Source\libxml2' $LibXml2Include
        Build-Group 'xslt' 'Source\libxslt' $LibXsltInclude
        Build-Group 'shim' 'Source\shim'    $LibXml2Include
    }
    if ($Platforms -contains 'Linux64') {
        # Always bcc64x: the profile-guided build with another clang is a Win64 matter.
        Write-Host '== compile Linux64 (bcc64x.exe) ==' -ForegroundColor Cyan
        $saved = $Compiler; $Compiler = $Bcc
        try { Build-Linux64 } finally { $Compiler = $saved }
    }
}
Write-Host '== invariants ==' -ForegroundColor Cyan
$symbols = Assert-ObjectInvariants
Write-Host '== LX2.Static.pas ==' -ForegroundColor Cyan
Write-StaticUnit $symbols

if ($Test -and ($Platforms -contains 'Linux64')) {
    Write-Host '== test Linux64 ==' -ForegroundColor Cyan
    # The SDK sits in the user profile and may hold non-ASCII characters, which dcclinux64
    # does not take from PowerShell; the short name has none.
    $sdk = (New-Object -ComObject Scripting.FileSystemObject).GetFolder((Resolve-LinuxSdk)).ShortPath
    $out = Join-Path $Root 'Tests\Linux64'
    New-Item -ItemType Directory -Force $out | Out-Null
    # The IDE takes these paths from the SDK settings; on the command line they are explicit.
    $libPath = @((Join-Path $StudioShort 'lib\linux64\release'),
                 (Join-Path $sdk 'usr\lib\x86_64-linux-gnu'), (Join-Path $sdk 'lib\x86_64-linux-gnu'),
                 (Get-LinuxGccDir $sdk), (Join-Path $sdk 'lib64'), $LibLinux) -join ';'
    $argList = @('-B', '-Q', "-E$out", "-N0$out", '-NSSystem;Posix', "-U$LX2Src", ('-U' + (Join-Path $StudioShort 'lib\linux64\release')),
                 "--syslibroot:$sdk", "--libpath:$libPath", '-$O+', (Join-Path $Root 'Tests\LX2StaticSmoke.dpr'))
    $res = & (Join-Path $StudioRoot 'bin\dcclinux64.exe') @argList 2>&1
    if ($LASTEXITCODE -ne 0) { throw "dcclinux64 exited with code $LASTEXITCODE`n$($res -join "`n")" }
    if (Get-Command wsl.exe -ErrorAction SilentlyContinue) {
        $wslPath = (& wsl.exe wslpath -u ((Join-Path $out 'LX2StaticSmoke') -replace '\\', '/')).Trim()
        & wsl.exe -e bash -c "chmod +x '$wslPath' && '$wslPath'"
        if ($LASTEXITCODE -ne 0) { throw 'Linux64 smoke test failed' }
    }
    else {
        Write-Host '  no WSL: Linux64 is linked but not run' -ForegroundColor Yellow
    }
}

if ($Test -and ($Platforms -contains 'Win64')) {
    Write-Host '== test Win64 ==' -ForegroundColor Cyan
    $out = Join-Path $Root 'Tests\Win64'
    New-Item -ItemType Directory -Force $out | Out-Null
    $argList = @('-B', '-Q', "-E$out", "-N0$out", '-NSSystem;Winapi', "-U$LX2Src", ('-U' + (Join-Path $StudioShort 'lib\win64\release')),
                 '-$O+', (Join-Path $Root 'Tests\LX2StaticSmoke.dpr'))
    $res = & (Join-Path $StudioRoot 'bin\dcc64.exe') @argList 2>&1
    if ($LASTEXITCODE -ne 0) { throw "dcc64 exited with code $LASTEXITCODE`n$($res -join "`n")" }
    & (Join-Path $out 'LX2StaticSmoke.exe')
    if ($LASTEXITCODE -ne 0) { throw 'Smoke test failed' }
}

Write-Host 'Done.' -ForegroundColor Green

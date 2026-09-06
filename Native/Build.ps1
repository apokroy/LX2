<#
.SYNOPSIS
    Static build of libxml2 and libxslt for LX2: Win64 objects and the LX2.Static.pas unit.

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

.PARAMETER StudioRoot
    RAD Studio directory; by default from the registry key
    HKCU\Software\Embarcadero\BDS\<BdsVersion>.
.PARAMETER Test
    After the build, compile Tests\LX2StaticSmoke.dpr with dcc64 and run it.
.PARAMETER SkipBuild
    Do not compile the objects: only generate LX2.Static.pas and run the tests.

.EXAMPLE
    .\Build.ps1 -Test
#>
[CmdletBinding()]
param(
    [string]$StudioRoot,
    [string]$BdsVersion = '37.0',
    [switch]$Test,
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
$Root    = $PSScriptRoot
$LX2Src  = Join-Path (Split-Path $Root -Parent) 'Source'
$Lib     = Join-Path $Root 'Lib\Win64'
$Gen     = Join-Path $Root 'Gen'

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
$Objdump = Join-Path $StudioRoot 'bin64\llvm-objdump.exe'
foreach ($tool in $Bcc, $Nm, $Objdump) {
    if (-not (Test-Path $tool)) { throw "Not found: $tool" }
}
$StudioShort = (New-Object -ComObject Scripting.FileSystemObject).GetFolder($StudioRoot).ShortPath

# ---------------------------------------------------------------------------
# Library features and generated headers
# ---------------------------------------------------------------------------

# libxml2 feature set (xmlversion.h). HTTP, modules, zlib and lzma are off: documents come
# from memory and streams, LX2 needs neither compressed files nor network loading, and each
# of these features pulls in its own library or a DLL load.
$LibXml2Features = @{
    WITH_THREADS = 1; WITH_THREAD_ALLOC = 0; WITH_OUTPUT = 1; WITH_PUSH = 1; WITH_READER = 1
    WITH_PATTERN = 1; WITH_WRITER = 1; WITH_SAX1 = 1; WITH_HTTP = 0; WITH_VALID = 1; WITH_HTML = 1
    WITH_LEGACY = 0; WITH_C14N = 1; WITH_CATALOG = 1; WITH_XPATH = 1; WITH_XPTR = 1
    WITH_XINCLUDE = 1; WITH_ICONV = 1; WITH_ICU = 0; WITH_ISO8859X = 1; WITH_DEBUG = 1
    WITH_REGEXPS = 1; WITH_RELAXNG = 1; WITH_SCHEMAS = 1; WITH_SCHEMATRON = 1
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
                 ('-I' + (Join-Path $Root 'Source\shim')))
$LibXml2Include = @(('-I' + (Join-Path $Gen 'libxml2')), ('-I' + (Join-Path $Root 'Source\libxml2\include')), ('-I' + (Join-Path $Root 'Source\libxml2')))
$LibXsltInclude = @(('-I' + (Join-Path $Gen 'libxslt')), ('-I' + (Join-Path $Root 'Source')), ('-I' + (Join-Path $Root 'Source\libxslt'))) + $LibXml2Include

function Invoke-Bcc([string[]]$Arguments) {
    $out = & $Bcc @Arguments 2>&1 | Where-Object { $_ -notmatch '^Embarcadero C\+\+' }
    if ($LASTEXITCODE -ne 0) { throw "bcc64x exited with code $LASTEXITCODE`n$($out -join "`n")" }
    if ($out) { $out | ForEach-Object { Write-Host "  $_" } }
}

function Build-Group([string]$Prefix, [string]$Dir, [string[]]$Include) {
    foreach ($src in Get-ChildItem (Join-Path $Root $Dir) -Filter *.c | Sort-Object Name) {
        $obj = Join-Path $Lib ($Prefix + '_' + [IO.Path]::GetFileNameWithoutExtension($src.Name) + '.o')
        Invoke-Bcc ($CommonFlags + $Include + @('-c', $src.FullName, '-o', $obj))
    }
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
                       'MultiByteToWideChar', 'WideCharToMultiByte', 'GetACP', 'IsValidCodePage', 'IsDBCSLeadByteEx',
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
    & $w "// Static linking of libxml2 and libxslt: the objects from Native\Lib\Win64, the C runtime"
    & $w "// from ucrtbase.dll, Win32 from kernel32/bcrypt. Adding the unit to a uses clause makes"
    & $w "// LX2Lib.Load and XSLTLib.Load bind to the objects instead of loading a DLL."
    & $w ""
    & $w "interface"
    & $w ""
    & $w "implementation"
    & $w ""
    & $w "// The objects are built for Win64 only; on other platforms the unit is empty and Load"
    & $w "// keeps loading the library file."
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
    & $w "initialization"
    & $w "  LX2Lib.StaticBinder := BindLibXml2;"
    & $w "  XSLTLib.StaticBinder := BindLibXslt;"
    & $w "{`$ENDIF WIN64}"
    & $w ""
    & $w "end."
    $path = Join-Path $LX2Src 'LX2.Static.pas'
    $bytes = [Text.Encoding]::UTF8.GetPreamble() + [Text.Encoding]::UTF8.GetBytes($sb.ToString().Replace("`r`n", "`n").Replace("`n", "`r`n"))
    [IO.File]::WriteAllBytes($path, $bytes)
    Write-Host "  LX2.Static.pas: libxml2 $($xml.Count) entry points, libxslt $($xslt.Count)"
    if ($unbound) {
        Write-Host "  not part of the build (pointers stay nil): $($unbound -join ', ')" -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------------------------
# Build steps
# ---------------------------------------------------------------------------

if (-not $SkipBuild) {
    Write-Host '== headers ==' -ForegroundColor Cyan
    Write-GeneratedHeaders
    Write-Host '== compile ==' -ForegroundColor Cyan
    if (Test-Path $Lib) { Remove-Item (Join-Path $Lib '*.o') -Force }
    New-Item -ItemType Directory -Force $Lib | Out-Null
    Build-Group 'xml'  'Source\libxml2' $LibXml2Include
    Build-Group 'xslt' 'Source\libxslt' $LibXsltInclude
    Build-Group 'shim' 'Source\shim'    $LibXml2Include
}
Write-Host '== invariants ==' -ForegroundColor Cyan
$symbols = Assert-ObjectInvariants
Write-Host '== LX2.Static.pas ==' -ForegroundColor Cyan
Write-StaticUnit $symbols

if ($Test) {
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

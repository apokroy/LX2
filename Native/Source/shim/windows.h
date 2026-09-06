/*
 * Minimal Win32 declarations for the static build of libxml2 and libxslt.
 *
 * bcc64x ships the mingw-w64 C runtime headers but not the Win32 SDK headers, and the
 * Microsoft SDK headers are not usable with the mingw target. The libraries touch a
 * couple of dozen Win32 entry points only, so they are declared here by hand, with
 * plain linkage (no dllimport): the objects then reference the functions by name and
 * the Pascal side resolves them with `external 'kernel32.dll'` declarations.
 *
 * Every declaration mirrors the Windows SDK exactly: types, calling convention and
 * structure layout on x64. Anything not listed here is deliberately absent, so a new
 * dependency in an upstream release fails at compile time, not at link time.
 */
#ifndef LX2_SHIM_WINDOWS_H
#define LX2_SHIM_WINDOWS_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define WINAPI     __stdcall
#define CALLBACK   __stdcall
#define WINBASEAPI
#define WINUSERAPI
#define DECLSPEC_IMPORT

typedef int                 BOOL;
typedef unsigned char       BYTE;
typedef unsigned char       BOOLEAN;
typedef unsigned short      WORD;
typedef unsigned long       DWORD;
typedef long                LONG;
typedef unsigned long       ULONG;
typedef unsigned int        UINT;
typedef long long           LONGLONG;
typedef unsigned long long  ULONGLONG;
typedef uintptr_t           ULONG_PTR;
typedef void               *HANDLE;
typedef void               *HINSTANCE;
typedef void               *HMODULE;
typedef void               *LPVOID;
typedef const void         *LPCVOID;
typedef char               *LPSTR;
typedef const char         *LPCSTR;
typedef wchar_t            *LPWSTR;
typedef const wchar_t      *LPCWSTR;
typedef DWORD              *LPDWORD;
typedef BOOL               *LPBOOL;
typedef DWORD               LCID;
typedef DWORD               LCTYPE;
typedef long                NTSTATUS;

#define TRUE      1
#define FALSE     0
#define INFINITE  0xFFFFFFFFul
#define MAX_PATH  260
#ifndef _MAX_PATH
#define _MAX_PATH 260
#endif

typedef union _LARGE_INTEGER {
    struct { DWORD LowPart; LONG HighPart; } u;
    LONGLONG QuadPart;
} LARGE_INTEGER;

/* RTL_CRITICAL_SECTION: 40 bytes on x64 */
typedef struct _RTL_CRITICAL_SECTION {
    void     *DebugInfo;
    LONG      LockCount;
    LONG      RecursionCount;
    HANDLE    OwningThread;
    HANDLE    LockSemaphore;
    ULONG_PTR SpinCount;
} CRITICAL_SECTION, *LPCRITICAL_SECTION;

typedef union _RTL_RUN_ONCE { void *Ptr; } INIT_ONCE, *PINIT_ONCE;
#define INIT_ONCE_STATIC_INIT { 0 }
typedef BOOL (WINAPI *PINIT_ONCE_FN)(PINIT_ONCE InitOnce, void *Parameter, void **Context);

typedef void (WINAPI *WAITORTIMERCALLBACK)(void *Parameter, BOOLEAN TimerOrWaitFired);
typedef BOOL (CALLBACK *LOCALE_ENUMPROCA)(LPSTR);

#define CP_ACP                    0
#define CP_UTF8                   65001
#define MB_ERR_INVALID_CHARS      0x00000008
#define WC_NO_BEST_FIT_CHARS      0x00000400
#define WC_ERR_INVALID_CHARS      0x00000080

#define LOCALE_SISO639LANGNAME    0x00000059
#define LOCALE_SISO3166CTRYNAME   0x0000005A
#define LCID_SUPPORTED            0x00000002
#define LCMAP_SORTKEY             0x00000400

#define TLS_OUT_OF_INDEXES        0xFFFFFFFFul
#define DUPLICATE_SAME_ACCESS     0x00000002
#define WT_EXECUTEONLYONCE        0x00000008

#define FILE_ATTRIBUTE_DIRECTORY       0x00000010
#define INVALID_FILE_ATTRIBUTES        ((DWORD)-1)

#define ERROR_INVALID_PARAMETER        87
#define ERROR_INSUFFICIENT_BUFFER      122
#define ERROR_INVALID_FLAGS            1004
#define ERROR_NO_UNICODE_TRANSLATION   1113

/* kernel32 */
void   WINAPI InitializeCriticalSection(LPCRITICAL_SECTION);
void   WINAPI DeleteCriticalSection(LPCRITICAL_SECTION);
void   WINAPI EnterCriticalSection(LPCRITICAL_SECTION);
void   WINAPI LeaveCriticalSection(LPCRITICAL_SECTION);
BOOL   WINAPI InitOnceExecuteOnce(PINIT_ONCE, PINIT_ONCE_FN, void *, void **);
DWORD  WINAPI TlsAlloc(void);
BOOL   WINAPI TlsFree(DWORD);
LPVOID WINAPI TlsGetValue(DWORD);
BOOL   WINAPI TlsSetValue(DWORD, LPVOID);
BOOL   WINAPI RegisterWaitForSingleObject(HANDLE *, HANDLE, WAITORTIMERCALLBACK, void *, ULONG, ULONG);
BOOL   WINAPI UnregisterWait(HANDLE);
BOOL   WINAPI CloseHandle(HANDLE);
BOOL   WINAPI DuplicateHandle(HANDLE, HANDLE, HANDLE, HANDLE *, DWORD, BOOL, DWORD);
HANDLE WINAPI GetCurrentProcess(void);
HANDLE WINAPI GetCurrentThread(void);
DWORD  WINAPI GetLastError(void);
void   WINAPI SetLastError(DWORD);
int    WINAPI MultiByteToWideChar(UINT, DWORD, LPCSTR, int, LPWSTR, int);
int    WINAPI WideCharToMultiByte(UINT, DWORD, LPCWSTR, int, LPSTR, int, LPCSTR, LPBOOL);
UINT   WINAPI GetACP(void);
BOOL   WINAPI IsValidCodePage(UINT);
BOOL   WINAPI IsDBCSLeadByteEx(UINT, BYTE);
typedef struct _cpinfo { UINT MaxCharSize; BYTE DefaultChar[2]; BYTE LeadByte[12]; } CPINFO, *LPCPINFO;
BOOL   WINAPI GetCPInfo(UINT, LPCPINFO);
int    WINAPI GetLocaleInfoA(LCID, LCTYPE, LPSTR, int);
BOOL   WINAPI EnumSystemLocalesA(LOCALE_ENUMPROCA, DWORD);
int    WINAPI LCMapStringW(LCID, DWORD, LPCWSTR, int, LPWSTR, int);
BOOL   WINAPI QueryPerformanceCounter(LARGE_INTEGER *);
BOOL   WINAPI QueryPerformanceFrequency(LARGE_INTEGER *);
DWORD  WINAPI GetFileAttributesA(LPCSTR);

#ifdef __cplusplus
}
#endif

#endif /* LX2_SHIM_WINDOWS_H */

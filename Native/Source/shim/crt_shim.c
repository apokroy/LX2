/*
 * printf family for objects compiled against the mingw-w64 headers.
 *
 * The mingw headers declare snprintf/vsnprintf/fprintf/vfprintf/sscanf as ordinary
 * functions that mingw's own runtime library would provide. That library is not linked
 * into a Delphi executable, and ucrtbase.dll does not export these names either: the
 * Universal CRT exposes __stdio_common_v* entry points that the MSVC headers wrap
 * inline. These wrappers do the same, so every remaining CRT reference of the objects
 * is a name ucrtbase.dll exports and the Pascal side declares as an import.
 *
 * No CRT header is included on purpose: the prototypes below are the whole contract.
 */
#include <stdarg.h>
#include <stddef.h>

typedef struct _iobuf FILE;

extern int __cdecl __stdio_common_vsprintf(unsigned long long options, char *buf, size_t n,
                                           const char *fmt, void *locale, va_list args);
extern int __cdecl __stdio_common_vfprintf(unsigned long long options, FILE *f,
                                           const char *fmt, void *locale, va_list args);
extern int __cdecl __stdio_common_vsscanf(unsigned long long options, const char *s, size_t n,
                                          const char *fmt, void *locale, va_list args);

/* _CRT_INTERNAL_PRINTF_STANDARD_SNPRINTF_BEHAVIOR: C99 return value and termination */
#define UCRT_SNPRINTF_OPTIONS 2ULL

int __cdecl vsnprintf(char *buf, size_t n, const char *fmt, va_list ap)
{
    return __stdio_common_vsprintf(UCRT_SNPRINTF_OPTIONS, buf, n, fmt, NULL, ap);
}

int __cdecl snprintf(char *buf, size_t n, const char *fmt, ...)
{
    va_list ap;
    int r;
    va_start(ap, fmt);
    r = __stdio_common_vsprintf(UCRT_SNPRINTF_OPTIONS, buf, n, fmt, NULL, ap);
    va_end(ap);
    return r;
}

int __cdecl vfprintf(FILE *f, const char *fmt, va_list ap)
{
    return __stdio_common_vfprintf(0, f, fmt, NULL, ap);
}

int __cdecl fprintf(FILE *f, const char *fmt, ...)
{
    va_list ap;
    int r;
    va_start(ap, fmt);
    r = __stdio_common_vfprintf(0, f, fmt, NULL, ap);
    va_end(ap);
    return r;
}

int __cdecl printf(const char *fmt, ...)
{
    extern FILE *__cdecl __acrt_iob_func(unsigned);
    va_list ap;
    int r;
    va_start(ap, fmt);
    r = __stdio_common_vfprintf(0, __acrt_iob_func(1), fmt, NULL, ap);
    va_end(ap);
    return r;
}

int __cdecl sscanf(const char *s, const char *fmt, ...)
{
    va_list ap;
    int r;
    va_start(ap, fmt);
    r = __stdio_common_vsscanf(0, s, (size_t)-1, fmt, NULL, ap);
    va_end(ap);
    return r;
}

/* POSIX names of the low-level file functions. The mingw headers declare them as plain
   functions (their runtime provides the aliases); ucrtbase.dll exports only the
   underscore forms, and the file descriptor table must stay within one CRT. */
extern int __cdecl _open(const char *path, int oflag, ...);
extern int __cdecl _close(int fd);
extern int __cdecl _read(int fd, void *buf, unsigned n);
extern int __cdecl _write(int fd, const void *buf, unsigned n);
extern int __cdecl _dup(int fd);

#define UCRT_O_CREAT 0x0100

int __cdecl open(const char *path, int oflag, ...)
{
    int pmode = 0;
    if (oflag & UCRT_O_CREAT) {
        va_list ap;
        va_start(ap, oflag);
        pmode = va_arg(ap, int);
        va_end(ap);
    }
    return _open(path, oflag, pmode);
}

int __cdecl close(int fd)                          { return _close(fd); }
int __cdecl read(int fd, void *buf, unsigned n)    { return _read(fd, buf, n); }
int __cdecl write(int fd, const void *buf, unsigned n) { return _write(fd, buf, n); }
int __cdecl dup(int fd)                            { return _dup(fd); }

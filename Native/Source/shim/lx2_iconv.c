/*
 * iconv for the static libxml2 build on Windows.
 *
 * libxml2 opens every descriptor with UTF-8 on one side and converts the document
 * encoding to or from it, so the implementation is UTF-8 <-> Windows code page through
 * UTF-16 with MultiByteToWideChar/WideCharToMultiByte, plus UTF-16/UTF-32 handled
 * directly. Semantics follow POSIX iconv as libxml2 relies on them:
 *   - input is consumed in whole characters; an incomplete trailing sequence stops the
 *     conversion with EINVAL, the converted part is already in the output;
 *   - an invalid or unmappable character stops with EILSEQ and *inbuf pointing at it
 *     (libxml2 then emits a character reference or reports the position);
 *   - a full output buffer stops with E2BIG after as many whole characters as fit;
 *   - iconv(cd, NULL, ...) resets the (stateless) converter and returns 0.
 * Conversion runs in chunks of whole characters on the stack: no heap allocation.
 */
#include "iconv.h"
#include "windows.h"
#include <errno.h>
#include <string.h>
#include <stdlib.h>

enum {
    LX2_CP_UTF8    = 65001,
    LX2_CP_UTF16LE = 0x7FFF0001,
    LX2_CP_UTF16BE = 0x7FFF0002,
    LX2_CP_UTF32LE = 0x7FFF0003,
    LX2_CP_UTF32BE = 0x7FFF0004
};

typedef struct {
    unsigned from;   /* code page of the input */
    unsigned to;     /* code page of the output */
    int from_sbcs;   /* every input byte is one character: no lead-byte probing needed */
} lx2_iconv;

/* Single-byte code pages (the ANSI, OEM, ISO and KOI8 families) have MaxCharSize 1;
 * the Unicode pseudo code pages and the DBCS/MBCS pages are probed per character. */
static int lx2_is_sbcs(unsigned cp)
{
    CPINFO info;

    if (cp == LX2_CP_UTF8 || cp >= 0x7FFF0000)
        return 0;
    return GetCPInfo(cp, &info) && info.MaxCharSize == 1;
}

/* Alias table: names normalised to upper case without '-', '_' and ' '. */
static const struct { const char *name; unsigned cp; } lx2_aliases[] = {
    { "UTF8", LX2_CP_UTF8 },
    { "UTF16", LX2_CP_UTF16LE }, { "UTF16LE", LX2_CP_UTF16LE }, { "UCS2", LX2_CP_UTF16LE },
    { "UCS2LE", LX2_CP_UTF16LE }, { "UTF16BE", LX2_CP_UTF16BE }, { "UCS2BE", LX2_CP_UTF16BE },
    { "UTF32", LX2_CP_UTF32LE }, { "UTF32LE", LX2_CP_UTF32LE }, { "UCS4", LX2_CP_UTF32LE },
    { "UCS4LE", LX2_CP_UTF32LE }, { "UTF32BE", LX2_CP_UTF32BE }, { "UCS4BE", LX2_CP_UTF32BE },
    { "ASCII", 20127 }, { "USASCII", 20127 }, { "ANSIX3.41968", 20127 }, { "ISO646US", 20127 },
    { "LATIN1", 28591 }, { "L1", 28591 }, { "ISO88591", 28591 }, { "ISO885912", 28592 },
    { "ISO88592", 28592 }, { "LATIN2", 28592 }, { "ISO88593", 28593 }, { "LATIN3", 28593 },
    { "ISO88594", 28594 }, { "LATIN4", 28594 }, { "ISO88595", 28595 }, { "CYRILLIC", 28595 },
    { "ISO88596", 28596 }, { "ARABIC", 28596 }, { "ISO88597", 28597 }, { "GREEK", 28597 },
    { "ISO88598", 28598 }, { "HEBREW", 28598 }, { "ISO88599", 28599 }, { "LATIN5", 28599 },
    { "ISO885913", 28603 }, { "LATIN7", 28603 }, { "ISO885915", 28605 }, { "LATIN9", 28605 },
    { "KOI8R", 20866 }, { "KOI8U", 21866 }, { "KOI8RU", 21866 },
    { "MACINTOSH", 10000 }, { "MACROMAN", 10000 }, { "MACCYRILLIC", 10007 },
    { "SHIFTJIS", 932 }, { "SJIS", 932 }, { "MSKANJI", 932 }, { "EUCJP", 20932 },
    { "ISO2022JP", 50220 }, { "GB2312", 936 }, { "GBK", 936 }, { "EUCCN", 936 },
    { "GB18030", 54936 }, { "BIG5", 950 }, { "BIGFIVE", 950 }, { "EUCKR", 949 },
    { "KSC56011987", 949 }, { "TIS620", 874 }, { "WINDOWS874", 874 },
    { NULL, 0 }
};

static unsigned lx2_codepage(const char *name)
{
    char norm[64];
    size_t n = 0;
    const char *p;
    unsigned cp;

    if (name == NULL || *name == 0)
        return GetACP();
    for (p = name; *p && n < sizeof(norm) - 1; p++) {
        if (*p == '-' || *p == '_' || *p == ' ')
            continue;
        norm[n++] = (char)((*p >= 'a' && *p <= 'z') ? *p - 32 : *p);
    }
    norm[n] = 0;
    if (n == 0)
        return 0;

    for (size_t i = 0; lx2_aliases[i].name; i++)
        if (strcmp(norm, lx2_aliases[i].name) == 0)
            return lx2_aliases[i].cp;

    /* Numbered families: CP1251, WINDOWS1251, IBM866, ISO885916 (only those not listed above). */
    p = NULL;
    if (strncmp(norm, "WINDOWS", 7) == 0) p = norm + 7;
    else if (strncmp(norm, "CP", 2) == 0) p = norm + 2;
    else if (strncmp(norm, "IBM", 3) == 0) p = norm + 3;
    else if (strncmp(norm, "ISO8859", 7) == 0) {
        cp = (unsigned)atoi(norm + 7);
        return (cp >= 1 && cp <= 16 && cp != 12) ? 28590 + cp : 0;
    }
    if (p == NULL || *p < '0' || *p > '9')
        return 0;
    cp = (unsigned)atoi(p);
    if (cp == 0 || cp == LX2_CP_UTF8)
        return cp == LX2_CP_UTF8 ? LX2_CP_UTF8 : 0;
    return IsValidCodePage(cp) ? cp : 0;
}

iconv_t iconv_open(const char *tocode, const char *fromcode)
{
    unsigned to = lx2_codepage(tocode);
    unsigned from = lx2_codepage(fromcode);
    lx2_iconv *cd;

    if (to == 0 || from == 0) {
        errno = EINVAL;
        return (iconv_t)-1;
    }
    cd = (lx2_iconv *)malloc(sizeof(*cd));
    if (cd == NULL) {
        errno = ENOMEM;
        return (iconv_t)-1;
    }
    cd->from = from;
    cd->to = to;
    cd->from_sbcs = lx2_is_sbcs(from);
    return (iconv_t)cd;
}

int iconv_close(iconv_t cd)
{
    if (cd == (iconv_t)-1 || cd == NULL) {
        errno = EINVAL;
        return -1;
    }
    free(cd);
    return 0;
}

/* Byte length of the character starting at p, 0 if the sequence is incomplete (fewer than
 * `left` bytes available), -1 if it cannot start a character in this encoding. Only the
 * shape is checked here; validity is left to the Windows converter. */
static int lx2_charlen(unsigned cp, const unsigned char *p, size_t left)
{
    unsigned c = p[0];
    int n;

    switch (cp) {
    case LX2_CP_UTF8:
        if (c < 0x80) n = 1;
        else if ((c & 0xE0) == 0xC0) n = 2;
        else if ((c & 0xF0) == 0xE0) n = 3;
        else if ((c & 0xF8) == 0xF0) n = 4;
        else return -1;
        if ((size_t)n > left) {
            for (int i = 1; i < (int)left; i++)
                if ((p[i] & 0xC0) != 0x80)
                    return -1;
            return 0;
        }
        for (int i = 1; i < n; i++)
            if ((p[i] & 0xC0) != 0x80)
                return -1;
        return n;
    case LX2_CP_UTF16LE:
    case LX2_CP_UTF16BE: {
        unsigned w;
        if (left < 2) return 0;
        w = (cp == LX2_CP_UTF16LE) ? (p[0] | (p[1] << 8)) : (p[1] | (p[0] << 8));
        if (w >= 0xD800 && w <= 0xDBFF) return left < 4 ? 0 : 4;
        return 2;
    }
    case LX2_CP_UTF32LE:
    case LX2_CP_UTF32BE:
        return left < 4 ? 0 : 4;
    default:
        if (IsDBCSLeadByteEx(cp, (BYTE)c))
            return left < 2 ? 0 : 2;
        return 1;
    }
}

/* Decode one chunk of whole characters (`bytes` long) of code page `cp` into UTF-16. */
static int lx2_to_wide(unsigned cp, const unsigned char *p, int bytes, wchar_t *w, int wcap)
{
    int n = 0;

    switch (cp) {
    case LX2_CP_UTF16LE:
        for (int i = 0; i + 1 < bytes; i += 2)
            w[n++] = (wchar_t)(p[i] | (p[i + 1] << 8));
        return n;
    case LX2_CP_UTF16BE:
        for (int i = 0; i + 1 < bytes; i += 2)
            w[n++] = (wchar_t)(p[i + 1] | (p[i] << 8));
        return n;
    case LX2_CP_UTF32LE:
    case LX2_CP_UTF32BE:
        for (int i = 0; i + 3 < bytes; i += 4) {
            unsigned u = (cp == LX2_CP_UTF32LE)
                ? (p[i] | (p[i + 1] << 8) | (p[i + 2] << 16) | ((unsigned)p[i + 3] << 24))
                : (p[i + 3] | (p[i + 2] << 8) | (p[i + 1] << 16) | ((unsigned)p[i] << 24));
            if (u > 0x10FFFF || (u >= 0xD800 && u <= 0xDFFF))
                return -1;
            if (u >= 0x10000) {
                u -= 0x10000;
                w[n++] = (wchar_t)(0xD800 + (u >> 10));
                w[n++] = (wchar_t)(0xDC00 + (u & 0x3FF));
            } else
                w[n++] = (wchar_t)u;
        }
        return n;
    default:
        n = MultiByteToWideChar(cp, MB_ERR_INVALID_CHARS, (LPCSTR)p, bytes, w, wcap);
        return n > 0 ? n : -1;
    }
}

/* Encode UTF-16 into code page `cp`; -1 on an unmappable character, -2 if it does not fit. */
static int lx2_from_wide(unsigned cp, const wchar_t *w, int wn, unsigned char *out, int cap)
{
    int n = 0;
    BOOL lost = FALSE;

    switch (cp) {
    case LX2_CP_UTF16LE:
    case LX2_CP_UTF16BE:
        if (wn * 2 > cap) return -2;
        for (int i = 0; i < wn; i++) {
            unsigned u = w[i];
            if (cp == LX2_CP_UTF16LE) { out[n++] = (unsigned char)u; out[n++] = (unsigned char)(u >> 8); }
            else { out[n++] = (unsigned char)(u >> 8); out[n++] = (unsigned char)u; }
        }
        return n;
    case LX2_CP_UTF32LE:
    case LX2_CP_UTF32BE:
        for (int i = 0; i < wn; i++) {
            unsigned u = w[i];
            if (u >= 0xD800 && u <= 0xDBFF && i + 1 < wn) {
                u = 0x10000 + ((u - 0xD800) << 10) + (w[i + 1] - 0xDC00);
                i++;
            }
            if (n + 4 > cap) return -2;
            if (cp == LX2_CP_UTF32LE) {
                out[n++] = (unsigned char)u; out[n++] = (unsigned char)(u >> 8);
                out[n++] = (unsigned char)(u >> 16); out[n++] = (unsigned char)(u >> 24);
            } else {
                out[n++] = (unsigned char)(u >> 24); out[n++] = (unsigned char)(u >> 16);
                out[n++] = (unsigned char)(u >> 8); out[n++] = (unsigned char)u;
            }
        }
        return n;
    case LX2_CP_UTF8:
        n = WideCharToMultiByte(cp, 0, w, wn, (LPSTR)out, cap, NULL, NULL);
        break;
    default:
        n = WideCharToMultiByte(cp, WC_NO_BEST_FIT_CHARS, w, wn, (LPSTR)out, cap, NULL, &lost);
        if (n > 0 && lost) return -1;
        break;
    }
    if (n > 0) return n;
    return (GetLastError() == ERROR_INSUFFICIENT_BUFFER) ? -2 : -1;
}

/* 1024 characters keep the stack buffers at 12 KB and the Windows converter calls rare. */
#define LX2_CHUNK_CHARS 1024

size_t iconv(iconv_t cdp, char **inbuf, size_t *inbytesleft, char **outbuf, size_t *outbytesleft)
{
    lx2_iconv *cd = (lx2_iconv *)cdp;
    const unsigned char *in;
    unsigned char *out;
    size_t inleft, outleft;

    if (cd == NULL || cd == (lx2_iconv *)-1) {
        errno = EINVAL;
        return (size_t)-1;
    }
    if (inbuf == NULL || *inbuf == NULL)
        return 0;   /* stateless: nothing to flush */

    in = (const unsigned char *)*inbuf;
    inleft = *inbytesleft;
    out = (unsigned char *)*outbuf;
    outleft = *outbytesleft;

    while (inleft > 0) {
        unsigned char tmp[LX2_CHUNK_CHARS * 4];
        wchar_t wide[LX2_CHUNK_CHARS * 2];
        int chars = 0, bytes = 0, wn, produced, err = 0;

        /* Gather a chunk of whole characters. On any conversion error the chunk is retried
         * character by character below, so the error lands on the exact offender. */
        if (cd->from_sbcs) {
            bytes = (inleft < LX2_CHUNK_CHARS) ? (int)inleft : LX2_CHUNK_CHARS;
            chars = bytes;
        }
        while (chars < LX2_CHUNK_CHARS && (size_t)bytes < inleft) {
            int len = lx2_charlen(cd->from, in + bytes, inleft - bytes);
            if (len < 0) { err = EILSEQ; break; }
            if (len == 0) { err = EINVAL; break; }
            bytes += len;
            chars++;
        }
        if (chars == 0) {
            errno = err;
            goto done;
        }

        wn = lx2_to_wide(cd->from, in, bytes, wide, (int)(sizeof(wide) / sizeof(wide[0])));
        produced = (wn < 0) ? -1 : lx2_from_wide(cd->to, wide, wn, tmp, (int)sizeof(tmp));
        if (produced >= 0 && (size_t)produced <= outleft) {
            memcpy(out, tmp, (size_t)produced);
            out += produced; outleft -= (size_t)produced;
            in += bytes; inleft -= (size_t)bytes;
            if (err) { errno = err; goto done; }
            continue;
        }

        /* Slow path: one character at a time until the output is full or a character fails. */
        for (int i = 0; i < chars; i++) {
            int len = lx2_charlen(cd->from, in, inleft);
            wn = lx2_to_wide(cd->from, in, len, wide, 4);
            produced = (wn < 0) ? -1 : lx2_from_wide(cd->to, wide, wn, tmp, (int)sizeof(tmp));
            if (produced < 0) { errno = EILSEQ; goto done; }
            if ((size_t)produced > outleft) { errno = E2BIG; goto done; }
            memcpy(out, tmp, (size_t)produced);
            out += produced; outleft -= (size_t)produced;
            in += len; inleft -= (size_t)len;
        }
        if (err) { errno = err; goto done; }
    }
    *inbuf = (char *)in; *inbytesleft = inleft;
    *outbuf = (char *)out; *outbytesleft = outleft;
    return 0;

done:
    *inbuf = (char *)in; *inbytesleft = inleft;
    *outbuf = (char *)out; *outbytesleft = outleft;
    return (size_t)-1;
}

/*
 * iconv interface for the static libxml2 build on Windows, implemented in lx2_iconv.c
 * on top of MultiByteToWideChar/WideCharToMultiByte. libxml2 always converts between
 * UTF-8 and the document encoding, so one side of every descriptor is UTF-8.
 */
#ifndef LX2_ICONV_H
#define LX2_ICONV_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void *iconv_t;

iconv_t iconv_open(const char *tocode, const char *fromcode);
size_t  iconv(iconv_t cd, char **inbuf, size_t *inbytesleft, char **outbuf, size_t *outbytesleft);
int     iconv_close(iconv_t cd);

#ifdef __cplusplus
}
#endif

#endif /* LX2_ICONV_H */

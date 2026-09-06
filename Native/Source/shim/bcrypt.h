/* Minimal <bcrypt.h> for the static libxml2 build: xmlInitRandom seeds its PRNG from
 * BCryptGenRandom. See windows.h in this directory for the rationale. */
#ifndef LX2_SHIM_BCRYPT_H
#define LX2_SHIM_BCRYPT_H

#include "windows.h"

#ifdef __cplusplus
extern "C" {
#endif

#define BCRYPT_USE_SYSTEM_PREFERRED_RNG  0x00000002
#define BCRYPT_SUCCESS(Status)           (((NTSTATUS)(Status)) >= 0)

/* bcrypt.dll */
NTSTATUS WINAPI BCryptGenRandom(void *hAlgorithm, unsigned char *pbBuffer, ULONG cbBuffer, ULONG dwFlags);

#ifdef __cplusplus
}
#endif

#endif /* LX2_SHIM_BCRYPT_H */

#ifndef _SHARED_H_
#define _SHARED_H_

/* Fixed-width types — do NOT use `long` here. On LP64 hosts (macOS/Linux
 * x86_64/arm64) unsigned long is 64-bit; SMSPlus render paths treat uint32
 * as a 4-byte dword (linebuf_ptr / write_dword), which otherwise produces
 * vertical black bars. Cortex-M7 is ILP32 so long happened to match. */
#include <stdint.h>
typedef uint8_t  uint8;
typedef uint16_t uint16;
typedef uint32_t uint32;
typedef int8_t   int8;
typedef int16_t  int16;
typedef int32_t  int32;

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <signal.h>
/* malloc.h is glibc/newlib; macOS host builds only have stdlib.h. */
#if defined(__has_include)
#  if __has_include(<malloc.h>)
#    include <malloc.h>
#  endif
#elif !defined(__APPLE__) && !defined(HOST_BUILD)
#  include <malloc.h>
#endif
#include <math.h>
#include <limits.h>
//#include <zlib.h>
#include <porting.h>

#ifndef PATH_MAX
#ifdef  MAX_PATH
#define PATH_MAX    MAX_PATH
#else
#define PATH_MAX    1024
#endif
#endif

#undef PATH_MAX
#define PATH_MAX 255

#include "z80.h"
#include "sms.h"
#include "pio.h"
#include "memz80.h"
#include "vdp.h"
#include "render.h"
#include "tms.h"
#include "sn76489.h"
#include "emu2413.h"
#include "ym2413.h"
#include "fmintf.h"
#include "sms_sound.h"
#include "system.h"
#include "loadrom.h"
// #include "config.h"
#include "state.h"

#endif /* _SHARED_H_ */

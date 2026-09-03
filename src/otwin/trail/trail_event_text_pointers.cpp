#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include "trail_event_text_pointers.h"

extern "C" TrailEventTextPointers g_trailEventTextPointers = { 0, 0 };

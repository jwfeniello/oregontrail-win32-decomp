// Product implementation of OtFormatDelayDaysText @ 0x0041ac20.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include "trail_event_text_runtime.h"

extern "C" void* g_applicationModule_00405a40_20260603;

extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* instance,
    unsigned int string_id,
    char* buffer,
    int buffer_max);
extern "C" __declspec(dllimport) int __cdecl wsprintfA(
    char* buffer,
    const char* format,
    ...);

#pragma comment(lib, "user32.lib")

#pragma code_seg(".otsem")
extern "C" __declspec(allocate(".otsem"))
const char g_delayDaysFormat_0041ac20[] = "%d %s";

#pragma optimize("s", off)
#pragma optimize("t", on)

// Formats the short trail-delay caption using the singular/plural day resource
// selected by the requested delay.
void DelayTextState_0041ac20::OtFormatDelayDaysText_RealCpp(short days)
{
    char unit_text[8];

    LoadStringA(
        g_applicationModule_00405a40_20260603,
        static_cast<unsigned int>((days > 1) + 0x22f),
        unit_text,
        sizeof(unit_text));
    wsprintfA(
        delay_text,
        g_delayDaysFormat_0041ac20,
        static_cast<int>(days),
        unit_text);
}

#pragma optimize("", on)
#pragma code_seg()

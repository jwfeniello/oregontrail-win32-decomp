// Product-owned active-text global storage and cleanup.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "active_text_runtime.h"

extern "C" __declspec(dllimport) int __stdcall GlobalUnlock(void* handle);
extern "C" __declspec(dllimport) void* __stdcall GlobalFree(void* handle);

#pragma comment(lib, "kernel32.lib")

extern "C" void* g_activeTextGlobalHandle_Product = 0;

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

// Releases the global-memory block used for non-edit-control active text.
extern "C" void __cdecl OtReleaseCachedGlobalHandle_Product_0040f840()
{
    void* handle = g_activeTextGlobalHandle_Product;

    if (handle != 0) {
        GlobalUnlock(handle);
        GlobalFree(g_activeTextGlobalHandle_Product);
        g_activeTextGlobalHandle_Product = 0;
    }
}

#pragma optimize("", on)
#pragma code_seg()

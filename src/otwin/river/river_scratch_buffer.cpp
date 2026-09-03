// Canonical product allocator for the shared journal/active-text memory block.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include "../app/active_text_runtime.h"
#include <string.h>

extern "C" __declspec(dllimport) void* __stdcall GlobalAlloc(
    unsigned int flags,
    unsigned long bytes);
extern "C" __declspec(dllimport) void* __stdcall GlobalLock(void* handle);
extern "C" __declspec(dllimport) int __stdcall GlobalUnlock(void* handle);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    void* owner,
    const char* text,
    const char* caption,
    unsigned int type);
extern "C" __declspec(dllimport) void __stdcall PostQuitMessage(int exit_code);

#pragma comment(lib, "kernel32.lib")
#pragma comment(lib, "user32.lib")
#pragma intrinsic(memset)

static const char g_journalAllocationErrorText[] =
    "Can't allocate global memory for journal entries.";
static const char g_memoryErrorCaption[] = "memory error";

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" int __cdecl OtRiverEnsureScratchBuffer_RealCpp()
{
    register void* handle = g_activeTextGlobalHandle_Product;

    if (handle == 0) {
        handle = GlobalAlloc(0x42, 0x7d00);
        g_activeTextGlobalHandle_Product = handle;
        if (handle == 0) {
            MessageBoxA(
                0,
                g_journalAllocationErrorText,
                g_memoryErrorCaption,
                0);
            PostQuitMessage(0);
            return 0;
        }
    }

    g_activeTextGlobalHandle_Product = handle;
    memset(GlobalLock(handle), 0, 0x7d00);
    GlobalUnlock(g_activeTextGlobalHandle_Product);
    return 1;
}

#pragma optimize("", on)
#pragma code_seg()

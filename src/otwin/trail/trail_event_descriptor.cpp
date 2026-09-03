#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This Product source must be compiled with 32-bit MSVC."
#endif

#include "trail_event_descriptor.h"
#include "trail_event_dispatch_tables.h"

extern "C" void* g_resourceModule;

extern "C" __declspec(dllimport) void* __stdcall FindResourceA(
    void* module,
    const void* name,
    const void* type);
extern "C" __declspec(dllimport) void* __stdcall LoadResource(
    void* module,
    void* resource_info);
extern "C" __declspec(dllimport) void* __stdcall LockResource(
    void* resource_handle);
extern "C" __declspec(dllimport) int __stdcall FreeResource(
    void* resource_handle);
extern "C" void* __cdecl memcpy(
    void* destination,
    const void* source,
    unsigned int count);

#pragma intrinsic(memcpy)
#pragma comment(lib, "kernel32.lib")

#pragma optimize("s", off)
#pragma optimize("t", on)

// 00416320
//
// Installs the common two-slot table and copies the 0x26-byte type-0x3e8
// event descriptor.  The original assumes these built-in resources exist, so
// its constructor has no synthetic null/failure path.
TrailEventDescriptor_00416320::TrailEventDescriptor_00416320(
    unsigned int resource_id)
{
    dispatch_table = &g_te_vt_7010_1896d;

    void* resource_info = FindResourceA(
        g_resourceModule,
        reinterpret_cast<const void*>(resource_id & 0xffff),
        reinterpret_cast<const void*>(0x3e8));
    void* resource_handle = LoadResource(g_resourceModule, resource_info);
    const void* source = LockResource(resource_handle);

    memcpy(
        descriptor_dwords,
        source,
        sizeof(descriptor_dwords) + sizeof(descriptor_tail));
    FreeResource(resource_handle);
}

#pragma optimize("", on)

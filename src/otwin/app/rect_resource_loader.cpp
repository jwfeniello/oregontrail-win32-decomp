#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "../graphics/positioned_bitmap_descriptor_state.h"

extern "C" __declspec(dllimport) void* __stdcall FindResourceA(
    void* instance,
    const void* resource_name,
    const void* resource_type);
extern "C" __declspec(dllimport) void* __stdcall LoadResource(
    void* instance,
    void* resource_info);
extern "C" __declspec(dllimport) void* __stdcall LockResource(
    void* resource);
extern "C" __declspec(dllimport) int __stdcall FreeResource(void* resource);

#pragma comment(lib, "kernel32.lib")

#pragma optimize("s", off)
#pragma optimize("t", on)

int RectResource_0040b690::OtLoadRectFromResource_RealCpp(
    void* instance,
    const void* resource_id)
{
    void* module;
    void* resource_handle;
    short* source_rect;

    if (resource_id == 0) {
        return 0;
    }

    module = instance;
    resource_handle = LoadResource(
        module,
        FindResourceA(
            module,
            resource_id,
            reinterpret_cast<const void*>(0x7da)));
    if (resource_handle == 0) {
        return 0;
    }

    source_rect = static_cast<short*>(LockResource(resource_handle));
    left = source_rect[0];
    top = source_rect[1];
    right = source_rect[2] + source_rect[0];
    bottom = source_rect[3] + source_rect[1];
    FreeResource(resource_handle);
    return 1;
}

#pragma optimize("", on)

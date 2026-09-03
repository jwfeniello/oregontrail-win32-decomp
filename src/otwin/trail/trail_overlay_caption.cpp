// Trail-overlay caption resource loader recovered from Oregon32.exe.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This source must be compiled with 32-bit MSVC."
#endif

extern "C" __declspec(dllimport) void* __stdcall FindResourceA(
    void* instance,
    const void* resource_name,
    const void* resource_type);
extern "C" __declspec(dllimport) void* __stdcall LoadResource(
    void* instance,
    void* resource_info);
extern "C" __declspec(dllimport) void* __stdcall LockResource(void* resource);
extern "C" __declspec(dllimport) int __stdcall FreeResource(void* resource);

extern "C" void* g_applicationModule_00405a40_20260603;

#pragma pack(push, 1)
struct TrailOverlayCaptionResource_0042fe90 {
    unsigned int dwords[0x4d];
    unsigned short tail;
};

struct TrailOverlayCaptionState_0042fe90 {
    int line_count;
    TrailOverlayCaptionResource_0042fe90 resource_text;

    int OtFormatTrailOverlayCaption_RealCpp();
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

// Loads the fixed caption table and records its ten rows in the owner object.
int TrailOverlayCaptionState_0042fe90::OtFormatTrailOverlayCaption_RealCpp()
{
    void* resource_info = FindResourceA(
        g_applicationModule_00405a40_20260603,
        reinterpret_cast<const void*>(0x0457),
        reinterpret_cast<const void*>(0x07d4));
    void* resource_handle = LoadResource(g_applicationModule_00405a40_20260603, resource_info);

    if (resource_info != 0 && resource_handle != 0) {
        resource_text =
            *static_cast<TrailOverlayCaptionResource_0042fe90*>(
                LockResource(resource_handle));
        line_count = 10;
        FreeResource(resource_handle);
        return 1;
    }

    return 0;
}

#pragma optimize("", on)

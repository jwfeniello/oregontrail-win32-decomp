// Semantic candidate for OtLoadPositionedBitmapDescriptor (0x0040ba40).

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "positioned_bitmap_descriptor_state.h"

extern "C" __declspec(dllimport) void* __stdcall FindResourceA(
    void* module,
    const void* resource_name,
    const void* resource_type);
extern "C" __declspec(dllimport) void* __stdcall LoadResource(
    void* module,
    void* resource_info);
extern "C" __declspec(dllimport) void* __stdcall LockResource(
    void* resource_data);
extern "C" __declspec(dllimport) int __stdcall FreeResource(
    void* resource_data);
extern "C" __declspec(dllimport) unsigned int __stdcall SizeofResource(
    void* module,
    void* resource_info);
extern "C" __declspec(dllimport) void* __stdcall GlobalAlloc(
    unsigned int flags,
    unsigned long bytes);
extern "C" __declspec(dllimport) void* __stdcall GlobalLock(void* memory);
extern "C" __declspec(dllimport) int __stdcall GlobalUnlock(void* memory);
extern "C" __declspec(dllimport) void* __stdcall GlobalFree(void* memory);

extern "C" void* __cdecl memcpy(
    void* destination,
    const void* source,
    unsigned int count);

#pragma intrinsic(memcpy)
#pragma comment(lib, "kernel32.lib")

#pragma pack(push, 1)
struct PositionedBitmapDescriptorResource_0040ba40 {
    short left;
    short top;
    short width;
    short height;
    short bitmap_resource_id;
};

#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

#pragma code_seg(".otsem")

int PositionedBitmapDescriptorState_0040ba40::
    OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
        void* module,
        unsigned short bitmap_resource_id,
        short left_value,
        short top_value,
        short width_value,
        short height_value)
{
    short requested_width = width_value;

    if (requested_width != 0 && height_value != 0) {
        left = left_value;
        left_int = left_value;

        top = top_value;
        top_int = top_value;

        width = requested_width;
        height = height_value;
        right = left_value + requested_width;
        bottom = top_value + height_value;
    }

    if (bitmap_info_handle != 0) {
        GlobalUnlock(bitmap_info_handle);
        GlobalFree(bitmap_info_handle);
        bitmap_info_handle = 0;
    }

    if (indexed_pixels_handle != 0) {
        FreeResource(indexed_pixels_handle);
        indexed_pixels_handle = 0;
    }

    bitmap_info_handle = GlobalAlloc(0, 0x228);
    if (bitmap_info_handle == 0) {
        return 0;
    }

    bitmap_info =
        static_cast<BitmapInfoHeader_0040b870_ProductWip*>(
            GlobalLock(bitmap_info_handle));
    bitmap_info->size = 0x28;
    bitmap_info->planes = 1;
    bitmap_info->bit_count = 8;
    bitmap_info->width = width;
    bitmap_info->height = height;
    bitmap_info->compression = 0;
    bitmap_info->size_image = 0;
    bitmap_info->x_pels_per_meter = 0;
    bitmap_info->y_pels_per_meter = 0;
    bitmap_info->colors_important = 0;
    bitmap_info->colors_used = 0;

    short palette_index = 0;
    short* palette_cursor = reinterpret_cast<short*>(
        reinterpret_cast<char*>(bitmap_info) + bitmap_info->size);
    do {
        *palette_cursor = palette_index;
        ++palette_cursor;
        ++palette_index;
    } while (palette_index < 0x100);

    if (bitmap_resource_id == 0) {
        return 0;
    }

    void* resource_info = FindResourceA(
        module,
        reinterpret_cast<const void*>(
            static_cast<unsigned short>(bitmap_resource_id)),
        reinterpret_cast<const void*>(0x0a));
    indexed_pixels_handle = LoadResource(module, resource_info);
    if (indexed_pixels_handle != 0) {
        indexed_pixels =
            static_cast<unsigned char*>(LockResource(indexed_pixels_handle));
        if (indexed_pixels != 0) {
            unsigned int resource_bytes = SizeofResource(module, resource_info);
            void* owned_pixels_handle = GlobalAlloc(0, resource_bytes);
            void* owned_pixels = GlobalLock(owned_pixels_handle);
            memcpy(owned_pixels, indexed_pixels, resource_bytes);
            indexed_pixels = static_cast<unsigned char*>(owned_pixels);
            FreeResource(indexed_pixels_handle);
            indexed_pixels_handle = owned_pixels_handle;
            return 1;
        }

        return 0;
    }

    return 0;
}

int PositionedBitmapDescriptorState_0040ba40::
    OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
        void* module,
        short bitmap_resource_id,
        short left_value,
        short top_value,
        short width_value,
        short height_value)
{
    return OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
        module,
        static_cast<unsigned short>(bitmap_resource_id),
        left_value,
        top_value,
        width_value,
        height_value);
}

int PositionedBitmapDescriptorState_0040ba40::
    OtLoadIndexedBitmapFromResourceDependency_0040ba40(
        void* module,
        short bitmap_resource_id,
        short left_value,
        short top_value,
        short width_value,
        short height_value)
{
    return OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
        module,
        static_cast<unsigned short>(bitmap_resource_id),
        left_value,
        top_value,
        width_value,
        height_value);
}

#pragma code_seg()

int PositionedBitmapDescriptorState_0040ba40::
    OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        void* module,
        short descriptor_id)
{
    short local_frame[6];

    if (descriptor_id == 0) {
        return 0;
    }

    void* resource_info = FindResourceA(
        module,
        reinterpret_cast<const void*>(static_cast<int>(descriptor_id)),
        reinterpret_cast<const void*>(0x07d2));
    *reinterpret_cast<void**>(&local_frame[2]) =
        LoadResource(module, resource_info);
    if (*reinterpret_cast<void**>(&local_frame[2]) == 0) {
        return 0;
    }

    PositionedBitmapDescriptorResource_0040ba40* descriptor =
        reinterpret_cast<PositionedBitmapDescriptorResource_0040ba40*>(
            LockResource(
                *reinterpret_cast<void**>(&local_frame[2])));
    if (descriptor == 0) {
        return 0;
    }

    short descriptor_left = descriptor->left;
    left = descriptor_left;
    left_int = descriptor_left;

    short descriptor_top = descriptor->top;
    top = descriptor_top;
    top_int = descriptor_top;

    short descriptor_width = descriptor->width;
    width = descriptor_width;

    local_frame[4] = descriptor->height;
    height = local_frame[4];

    right = static_cast<int>(descriptor->width) +
            static_cast<int>(descriptor->left);
    bottom = static_cast<int>(descriptor->top) + static_cast<int>(descriptor->height);

    short bitmap_resource_id = descriptor->bitmap_resource_id;
    if (bitmap_resource_id > 0) {
        OtLoadIndexedBitmapFromResourceDependency_0040ba40(
            module,
            bitmap_resource_id,
            descriptor_left,
            descriptor_top,
            descriptor_width,
            local_frame[4]);
    }

    FreeResource(*reinterpret_cast<void**>(&local_frame[2]));
    return 1;
}

#pragma optimize("", on)

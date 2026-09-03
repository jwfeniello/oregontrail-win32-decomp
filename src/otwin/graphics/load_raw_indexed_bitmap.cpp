// Product implementation of the raw indexed-bitmap constructor at 0x00410490.

#include "raw_indexed_bitmap_runtime.h"
#include "sprite_blitter_runtime.h"

typedef void* OtGlobalHandle_00410490;
typedef void* OtResourceInfo_00410490;

extern "C" __declspec(dllimport) OtGlobalHandle_00410490 __stdcall GlobalAlloc(
    unsigned int flags,
    unsigned long bytes);
extern "C" __declspec(dllimport) void* __stdcall GlobalLock(
    OtGlobalHandle_00410490 handle);
extern "C" __declspec(dllimport) int __stdcall GlobalUnlock(
    OtGlobalHandle_00410490 handle);
extern "C" __declspec(dllimport) OtGlobalHandle_00410490 __stdcall GlobalFree(
    OtGlobalHandle_00410490 handle);
extern "C" __declspec(dllimport) OtResourceInfo_00410490 __stdcall FindResourceA(
    OtModuleHandle_00410490 module,
    const void* resource_name,
    const void* resource_type);
extern "C" __declspec(dllimport) OtGlobalHandle_00410490 __stdcall LoadResource(
    OtModuleHandle_00410490 module,
    OtResourceInfo_00410490 resource_info);
extern "C" __declspec(dllimport) void* __stdcall LockResource(
    OtGlobalHandle_00410490 resource_data);
extern "C" __declspec(dllimport) unsigned long __stdcall SizeofResource(
    OtModuleHandle_00410490 module,
    OtResourceInfo_00410490 resource_info);
extern "C" __declspec(dllimport) int __stdcall FreeResource(
    OtGlobalHandle_00410490 resource_data);
extern "C" __declspec(dllimport) int __stdcall StretchDIBits(
    void* dc,
    int dest_x,
    int dest_y,
    int dest_width,
    int dest_height,
    int source_x,
    int source_y,
    int source_width,
    int source_height,
    const void* bits,
    const void* bitmap_info,
    unsigned int usage,
    unsigned long raster_operation);

extern "C" void* __cdecl memcpy(
    void* destination,
    const void* source,
    unsigned int bytes);
#pragma intrinsic(memcpy)

#pragma comment(lib, "kernel32.lib")
#pragma comment(lib, "gdi32.lib")

#pragma optimize("s", off)
#pragma optimize("t", on)

RawIndexedBitmap_00410490_Product::RawIndexedBitmap_00410490_Product(
    OtModuleHandle_00410490 module,
    int bitmap_width,
    int bitmap_height,
    const void* bitmap_resource_id)
    : height(bitmap_height),
      width(bitmap_width),
      last_x(0),
      last_y(0)
{
    register RawIndexedBitmap_00410490_Product* bitmap = this;
    register OtResourceInfo_00410490 resource_info;
    unsigned long owned_pixels_handle;
    OtGlobalHandle_00410490 resource_handle;
    unsigned long resource_bytes;
    void* owned_pixels;

    bitmap_info_handle = 0;
    indexed_pixels_handle = 0;
    bitmap_info = 0;
    indexed_pixels = 0;

    bitmap->bitmap_info_handle =
        (unsigned long)GlobalAlloc(0, 0x228);
    bitmap->bitmap_info =
        (SpriteBitmapInfo_004107b0_Product*)GlobalLock(
            (OtGlobalHandle_00410490)bitmap->bitmap_info_handle);

    if (bitmap_resource_id != 0) {
        resource_info = FindResourceA(
            module,
            bitmap_resource_id,
            (const void*)0x0a);
        bitmap->indexed_pixels_handle =
            (unsigned long)LoadResource(module, resource_info);
        bitmap->indexed_pixels = (unsigned char*)LockResource(
            (OtGlobalHandle_00410490)bitmap->indexed_pixels_handle);
        resource_bytes = SizeofResource(module, resource_info);
        owned_pixels_handle = (unsigned long)GlobalAlloc(0, resource_bytes);
        owned_pixels = GlobalLock((OtGlobalHandle_00410490)owned_pixels_handle);
        memcpy(owned_pixels, bitmap->indexed_pixels, resource_bytes);
        resource_handle = (OtGlobalHandle_00410490)indexed_pixels_handle;
        indexed_pixels = (unsigned char*)owned_pixels;
        FreeResource(resource_handle);
        bitmap->indexed_pixels_handle = owned_pixels_handle;
    }
}

#pragma code_seg(".otsem")

extern "C" void __fastcall OtFreeRawIndexedBitmap_RealCpp(void* value)
{
    RawIndexedBitmap_00410490_Product* bitmap =
        (RawIndexedBitmap_00410490_Product*)value;
    OtGlobalHandle_00410490 handle;

    handle = (OtGlobalHandle_00410490)bitmap->bitmap_info_handle;
    if (handle != 0) {
        GlobalUnlock(handle);
        GlobalFree(handle);
        bitmap->bitmap_info_handle = 0;
        bitmap->bitmap_info = 0;
    }

    handle = (OtGlobalHandle_00410490)bitmap->indexed_pixels_handle;
    if (handle != 0) {
        GlobalUnlock(handle);
        GlobalFree(handle);
        bitmap->indexed_pixels_handle = 0;
        bitmap->indexed_pixels = 0;
    }
}

void RawIndexedBitmap_00410490_Product::
    OtBlitRawIndexedBitmap_Product_004105a0(
        void* dc,
        int x,
        int y)
{
    unsigned short* palette_index;
    int palette_slot;

    palette_slot = 0;
    if (indexed_pixels != 0 && bitmap_info != 0) {
        bitmap_info->header.size = 0x28;
        bitmap_info->header.planes = 1;
        bitmap_info->header.bit_count = 8;
        bitmap_info->header.width = width;
        bitmap_info->header.height = height;
        bitmap_info->header.compression = 0;
        bitmap_info->header.size_image = 0;
        bitmap_info->header.x_pels_per_meter = 0;
        bitmap_info->header.y_pels_per_meter = 0;
        bitmap_info->header.colors_important = 0;
        bitmap_info->header.colors_used = 0;

        palette_index =
            (unsigned short*)((char*)bitmap_info + bitmap_info->header.size);
        do {
            *palette_index = (short)palette_slot;
            ++palette_index;
            ++palette_slot;
        } while (palette_slot < 0x100);

        StretchDIBits(
            dc,
            x,
            y,
            width,
            height,
            0,
            0,
            width,
            height,
            indexed_pixels,
            bitmap_info,
            1,
            0x00cc0020ul);
        last_x = x;
        last_y = y;
    }
}

#pragma code_seg()

#pragma optimize("", on)

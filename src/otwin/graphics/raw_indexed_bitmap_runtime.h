#ifndef OTWIN_GRAPHICS_RAW_INDEXED_BITMAP_RUNTIME_H
#define OTWIN_GRAPHICS_RAW_INDEXED_BITMAP_RUNTIME_H

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This recovered runtime requires 32-bit MSVC."
#endif

typedef void* OtModuleHandle_00410490;
struct SpriteBitmapInfo_004107b0_Product;

#pragma pack(push, 1)
struct RawIndexedBitmap_00410490_Product {
    unsigned long indexed_pixels_handle;
    unsigned char* indexed_pixels;
    unsigned long bitmap_info_handle;
    SpriteBitmapInfo_004107b0_Product* bitmap_info;
    int height;
    int width;
    int last_x;
    int last_y;

    static void* __cdecl operator new(unsigned int bytes);

    RawIndexedBitmap_00410490_Product(
        OtModuleHandle_00410490 module,
        int width,
        int height,
        const void* bitmap_resource_id);

    void OtBlitRawIndexedBitmap_Product_004105a0(
        void* dc,
        int x,
        int y);
};
#pragma pack(pop)

typedef char RawIndexedBitmap_00410490_Product_size_must_be_0x20[
    sizeof(RawIndexedBitmap_00410490_Product) == 0x20 ? 1 : -1];

#endif

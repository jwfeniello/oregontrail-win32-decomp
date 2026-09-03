#ifndef OTWIN_GRAPHICS_SPRITE_BLITTER_RUNTIME_H
#define OTWIN_GRAPHICS_SPRITE_BLITTER_RUNTIME_H

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This recovered runtime requires 32-bit MSVC."
#endif

struct RawIndexedBitmap_00410490_Product;

#pragma pack(push, 1)
struct SpriteBitmapInfoHeader_004107b0_Product {
    unsigned long size;
    long width;
    long height;
    unsigned short planes;
    unsigned short bit_count;
    unsigned long compression;
    unsigned long size_image;
    long x_pels_per_meter;
    long y_pels_per_meter;
    unsigned long colors_used;
    unsigned long colors_important;
};

struct SpriteBitmapInfo_004107b0_Product {
    SpriteBitmapInfoHeader_004107b0_Product header;
    unsigned short palette[256];
};

struct SpriteBlitter_00410660_Product {
    void* source_resource_handle;
    int resource_handle_or_state;
    unsigned char* source_pixels;
    unsigned short source_frame;
    unsigned short source_columns_per_row;
    unsigned char transparent_index;
    unsigned char reserved_11;
    unsigned long bitmap_info_handle;
    SpriteBitmapInfo_004107b0_Product* bitmap_info;
    short horizontal_flip;
    short mode_or_variant;
    short active_state;
    short clip_x;
    short clip_y;
    unsigned short clip_width;
    unsigned short clip_height;
    short requested_x;
    short requested_y;
    unsigned short source_width;
    unsigned short source_height;
    short previous_x;
    short previous_y;
    short draw_right;
    short draw_bottom;

    static void* __cdecl operator new(unsigned int bytes);

    SpriteBlitter_00410660_Product();
    void OtBlitSpriteBuffer_Product_004106e0(
        void* dc,
        RawIndexedBitmap_00410490_Product* base_bitmap,
        const void* sprite_buffer);
    void OtResetSpriteBlitterBitmapInfo_Product_004107b0();
    void OtExtractSpriteRegionToBuffer_Product_00410840(
        RawIndexedBitmap_00410490_Product* source,
        unsigned char* scratch_buffer);
    void OtCompositeSpriteIntoBuffer_Product_00410a30(
        SpriteBlitter_00410660_Product* destination_region,
        unsigned char* destination_buffer,
        RawIndexedBitmap_00410490_Product* base_bitmap);
};
#pragma pack(pop)

typedef char SpriteBitmapInfo_004107b0_Product_size_must_be_0x228[
    sizeof(SpriteBitmapInfo_004107b0_Product) == 0x228 ? 1 : -1];
typedef char SpriteBlitter_00410660_Product_size_must_be_0x38[
    sizeof(SpriteBlitter_00410660_Product) == 0x38 ? 1 : -1];

#endif

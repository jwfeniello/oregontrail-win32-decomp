// Product implementation of the wrapped positioned-bitmap blit @ 0x0040b7b0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

extern "C" __declspec(dllimport) int __stdcall StretchDIBits(
    void* dc,
    int x_dest,
    int y_dest,
    int dest_width,
    int dest_height,
    int x_src,
    int y_src,
    int src_width,
    int src_height,
    const void* bits,
    const void* bitmap_info,
    unsigned int usage,
    unsigned long raster_op);

#pragma comment(lib, "gdi32.lib")

#pragma pack(push, 1)
struct IndexedBitmapWidth_0040b7b0_Semantic {
    unsigned long size;
    int width;
};

struct PositionedBitmap_0040b7b0_Semantic {
    unsigned long bitmap_info_handle;
    unsigned long indexed_pixels_handle;
    IndexedBitmapWidth_0040b7b0_Semantic* bitmap_info;
    unsigned char* indexed_pixels;
    short x;
    short y;
    short width;
    short height;

    int x_mirror;
    int y_mirror;
    int right;
    int bottom;

    int OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        void* dc,
        int source_x,
        int source_y);
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)
#pragma code_seg(".otsem")

// Draws a positioned indexed bitmap. A source span crossing the bitmap's
// right edge wraps to x=0 and is emitted as two StretchDIBits operations.
int PositionedBitmap_0040b7b0_Semantic::
    OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        void* dc,
        int source_x,
        int source_y)
{
    void* indexed_pixels_local;
    IndexedBitmapWidth_0040b7b0_Semantic* bitmap_info_local;
    int draw_width;
    int source_width_remaining;

    indexed_pixels_local = indexed_pixels;
    if (indexed_pixels_local == 0) {
        return 0;
    }

    bitmap_info_local = bitmap_info;
    draw_width = width;
    source_width_remaining = bitmap_info_local->width - source_x;
    if (source_width_remaining < draw_width) {
        draw_width = draw_width - source_width_remaining;
        StretchDIBits(
            dc,
            x,
            y,
            source_width_remaining,
            height,
            source_x,
            source_y,
            source_width_remaining,
            height,
            indexed_pixels_local,
            bitmap_info,
            1,
            0x00cc0020ul);
        StretchDIBits(
            dc,
            x + source_width_remaining,
            y,
            draw_width,
            height,
            0,
            source_y,
            draw_width,
            height,
            indexed_pixels,
            bitmap_info,
            1,
            0x00cc0020ul);
    } else {
        StretchDIBits(
            dc,
            x,
            y,
            draw_width,
            height,
            source_x,
            source_y,
            draw_width,
            height,
            indexed_pixels_local,
            bitmap_info,
            1,
            0x00cc0020ul);
    }

    return 1;
}

#pragma code_seg()
#pragma optimize("", on)

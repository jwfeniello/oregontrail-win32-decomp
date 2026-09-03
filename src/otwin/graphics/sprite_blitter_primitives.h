#ifndef OTWIN_GRAPHICS_SPRITE_BLITTER_PRIMITIVES_H
#define OTWIN_GRAPHICS_SPRITE_BLITTER_PRIMITIVES_H

#include "indexed_bitmap_primitives.h"

namespace otwin {
namespace reconstructed {
namespace graphics {

struct SpriteBlitter {
    HGLOBAL source_resource_handle;
    unsigned int unused_flags;
    unsigned char* source_pixels;
    unsigned short source_frame;
    unsigned short source_columns_per_row;
    unsigned char transparent_index;
    unsigned char reserved_11;
    HGLOBAL bitmap_info_handle;
    IndexedBitmapInfo256* bitmap_info;
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
};

SpriteBlitter* OtInitSpriteBlitter(SpriteBlitter* sprite);
void OtFreeSpriteBlitter(SpriteBlitter* sprite);
void OtBlitSpriteBuffer(
    SpriteBlitter* sprite, HDC dc, const RawIndexedBitmap* base_bitmap, const void* sprite_buffer);
void OtResetSpriteBlitterBitmapInfo(SpriteBlitter* sprite);
void OtExtractSpriteRegionToBuffer(
    SpriteBlitter* sprite, const RawIndexedBitmap* source, unsigned char* scratch_buffer);
void OtCompositeSpriteIntoBuffer(const SpriteBlitter* sprite,
                                 const SpriteBlitter* destination_region,
                                 unsigned char* destination_buffer,
                                 const RawIndexedBitmap* base_bitmap);
short OtSampleSpriteBufferPixel(const SpriteBlitter* sprite, short x, short y);

}  // namespace graphics
}  // namespace reconstructed
}  // namespace otwin

#endif

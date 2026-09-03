// Product implementations of the sprite constructor/reset pair at
// 0x00410660 and 0x004107b0.

#include "sprite_blitter_runtime.h"
#include "raw_indexed_bitmap_runtime.h"

typedef void* OtGlobalHandle_00410660;

extern "C" __declspec(dllimport) OtGlobalHandle_00410660 __stdcall GlobalAlloc(
    unsigned int flags,
    unsigned long bytes);
extern "C" __declspec(dllimport) void* __stdcall GlobalLock(
    OtGlobalHandle_00410660 handle);
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

#pragma comment(lib, "kernel32.lib")
#pragma comment(lib, "gdi32.lib")

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

SpriteBlitter_00410660_Product::SpriteBlitter_00410660_Product()
{
    unsigned long zero32 = 0;
    unsigned short zero16 = 0;
    SpriteBlitter_00410660_Product* sprite = this;

    source_frame = zero16;
    source_resource_handle = (void*)zero32;
    source_columns_per_row = zero16;
    resource_handle_or_state = zero32;
    requested_x = zero16;
    source_pixels = (unsigned char*)zero32;
    requested_y = zero16;
    previous_x = zero16;
    previous_y = zero16;
    source_width = zero16;
    source_height = zero16;
    horizontal_flip = zero16;
    mode_or_variant = zero16;
    active_state = zero16;
    draw_right = zero16;
    draw_bottom = zero16;

    bitmap_info_handle = (unsigned long)GlobalAlloc(0, 0x228);
    bitmap_info = (SpriteBitmapInfo_004107b0_Product*)GlobalLock(
        (OtGlobalHandle_00410660)bitmap_info_handle);

    (void)sprite;
}

void SpriteBlitter_00410660_Product::
    OtBlitSpriteBuffer_Product_004106e0(
        void* dc,
        RawIndexedBitmap_00410490_Product* base_bitmap,
        const void* sprite_buffer)
{
    if (sprite_buffer != 0 && bitmap_info != 0) {
        if (clip_x < base_bitmap->width &&
            clip_y < base_bitmap->height &&
            clip_x + clip_width - 1 >= 0 &&
            clip_y + clip_height - 1 >= 0) {
            previous_x = requested_x;
            previous_y = requested_y;
            bitmap_info->header.width = clip_width;
            bitmap_info->header.height = clip_height;
            bitmap_info->header.size_image = clip_width * clip_height;

            StretchDIBits(
                dc,
                base_bitmap->last_x + clip_x,
                clip_y + base_bitmap->last_y,
                clip_width,
                clip_height,
                0,
                0,
                clip_width,
                clip_height,
                sprite_buffer,
                bitmap_info,
                1,
                0x00cc0020ul);
        }
    }
}

void SpriteBlitter_00410660_Product::
    OtResetSpriteBlitterBitmapInfo_Product_004107b0()
{
    unsigned short* palette_index;
    int palette_slot;

    palette_slot = 0;
    if (bitmap_info != 0) {
        previous_x = requested_x;
        previous_y = requested_y;
        bitmap_info->header.size = 0x28;
        bitmap_info->header.planes = 1;
        bitmap_info->header.bit_count = 8;
        bitmap_info->header.width = source_width;
        bitmap_info->header.height = source_height;
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
    }
}

void SpriteBlitter_00410660_Product::
    OtExtractSpriteRegionToBuffer_Product_00410840(
        RawIndexedBitmap_00410490_Product* source,
        unsigned char* scratch_buffer)
{
    int source_stride;
    int clip_x_int;
    int clip_y_int;
    int clip_right;
    int clip_bottom;
    unsigned int width_as_int;
    unsigned int scratch_stride;
    unsigned char* scratch_last_row;
    unsigned char* source_row;
    unsigned int copied;
    unsigned int copy_width;

    if (scratch_buffer != 0 && source != 0) {
        source_stride = source->width;
        if ((source_stride & 3) != 0) {
            source_stride = (source_stride - (source_stride & 3)) + 4;
        }

        clip_x = requested_x;
        if (previous_x <= requested_x) {
            clip_x = previous_x;
        }

        clip_y = requested_y;
        if (previous_y <= requested_y) {
            clip_y = previous_y;
        }

        if (previous_x < requested_x) {
            clip_width =
                (unsigned short)((source_width - previous_x) + requested_x);
        } else {
            clip_width =
                (unsigned short)((source_width - requested_x) + previous_x);
        }

        if (previous_y < requested_y) {
            clip_height =
                (unsigned short)((source_height - previous_y) + requested_y);
        } else {
            clip_height =
                (unsigned short)((source_height - requested_y) + previous_y);
        }

        clip_x_int = clip_x;
        if (clip_x_int < source->width) {
            clip_y_int = clip_y;
            if (clip_y_int < source->height) {
                width_as_int = clip_width;
                clip_right = (clip_x_int + width_as_int) - 1;
                if (-1 < clip_right) {
                    clip_bottom = (clip_y_int + clip_height) - 1;
                    if (-1 < clip_bottom) {
                        if (source->width <= clip_right) {
                            clip_width =
                                (unsigned short)source->width - clip_x;
                        }
                        if (source->height <= clip_bottom) {
                            clip_height =
                                (unsigned short)source->height - clip_y;
                        }
                        if (clip_x < 0) {
                            clip_x = 0;
                            clip_width =
                                (unsigned short)(clip_width + clip_x_int);
                        }
                        if (clip_y < 0) {
                            clip_y = 0;
                            clip_height =
                                (unsigned short)(clip_height + clip_y_int);
                        }

                        width_as_int = clip_width;
                        if (width_as_int == 0 || clip_height == 0) {
                            return;
                        }

                        copy_width = width_as_int;
                        scratch_stride = copy_width;
                        if ((clip_width & 3) != 0) {
                            scratch_stride =
                                (copy_width - (clip_width & 3)) + 4;
                        }

                        scratch_last_row =
                            scratch_buffer +
                            ((unsigned int)clip_height - 1) * scratch_stride;
                        if (source->indexed_pixels == 0) {
                            return;
                        }

                        source_row =
                            source->indexed_pixels +
                            (((source->height - (int)clip_y) -
                              (unsigned int)clip_height) *
                             source_stride) +
                            (int)clip_x;
                        do {
                            copied = 0;
                            do {
                                *scratch_buffer = *source_row;
                                ++scratch_buffer;
                                ++source_row;
                                ++copied;
                            } while (copied < copy_width);
                            source_row += source_stride - copy_width;
                            scratch_buffer += scratch_stride - copied;
                        } while (scratch_buffer <= scratch_last_row);
                        return;
                    }
                }
            }
        }

        clip_width = 0;
        clip_height = 0;
    }
}

void SpriteBlitter_00410660_Product::
    OtCompositeSpriteIntoBuffer_Product_00410a30(
        SpriteBlitter_00410660_Product* destination_region,
        unsigned char* destination_buffer,
        RawIndexedBitmap_00410490_Product* base_bitmap)
{
    int destination_left;
    int destination_top;
    int sprite_left;
    int sprite_top;
    unsigned int destination_width;
    unsigned short destination_height_word;
    unsigned int destination_height;
    unsigned int sprite_width;
    unsigned int sprite_height;
    int destination_stride;
    int destination_x_skip;
    int destination_y_skip;
    unsigned int copy_width;
    unsigned int copy_height;
    int source_stride;
    int destination_start_offset;
    unsigned char* destination_limit;
    int source_start_offset;
    int frame_offset;
    int row_offset;
    unsigned char transparent;
    unsigned char* source_cursor;
    unsigned char* destination_cursor;
    unsigned int column;

    if (source_pixels == 0 || destination_buffer == 0 ||
        destination_region == 0 || base_bitmap == 0) {
        return;
    }

    destination_left = destination_region->clip_x;
    if (base_bitmap->width <= destination_left) {
        return;
    }

    destination_top = destination_region->clip_y;
    if (base_bitmap->height <= destination_top) {
        return;
    }

    destination_width = destination_region->clip_width;
    if ((int)(destination_left + destination_width - 1) < 0) {
        return;
    }

    destination_height_word = destination_region->clip_height;
    destination_height = destination_height_word;
    if ((int)(destination_top + destination_height - 1) < 0) {
        return;
    }

    sprite_left = requested_x;
    sprite_width = source_width;
    if ((int)(sprite_left + sprite_width - 1) < destination_left ||
        (int)(destination_left + destination_width - 1) < sprite_left) {
        return;
    }

    sprite_top = requested_y;
    sprite_height = source_height;
    if ((int)(sprite_height + sprite_top - 1) < destination_top ||
        (int)(destination_top + destination_height - 1) < sprite_top) {
        return;
    }

    destination_stride = destination_width;
    if ((destination_region->clip_width & 3) != 0) {
        destination_stride =
            (destination_width - (destination_region->clip_width & 3)) + 4;
    }

    if (destination_left < sprite_left) {
        destination_x_skip = sprite_left - destination_left;
    } else {
        destination_x_skip = 0;
    }

    if (destination_top < sprite_top) {
        destination_y_skip = sprite_top - destination_top;
    } else {
        destination_y_skip = 0;
    }

    if (sprite_left < destination_left) {
        copy_width = (sprite_left - destination_left) + sprite_width;
        if (destination_width < copy_width) {
            copy_width = destination_width;
        }
    } else {
        copy_width = sprite_width;
        if (destination_width < sprite_width + destination_x_skip) {
            copy_width = destination_width - destination_x_skip;
        }
    }

    if (sprite_top < destination_top) {
        copy_height = (sprite_top - destination_top) + sprite_height;
        if (destination_height < copy_height) {
            copy_height = destination_height;
        }
    } else {
        copy_height = sprite_height;
        if (destination_height < sprite_height + destination_y_skip) {
            copy_height = destination_height - destination_y_skip;
        }
    }

    source_stride = source_width * source_columns_per_row;
    if ((source_width * source_columns_per_row & 3) != 0) {
        source_stride = (source_stride - (source_stride & 3)) + 4;
    }

    if (destination_top < sprite_top) {
        destination_height =
            (destination_top - sprite_top) + destination_height;
    }
    destination_start_offset =
        (destination_height - 1) * destination_stride + destination_x_skip;

    if (destination_top < sprite_top) {
        destination_height_word =
            destination_height_word - (short)destination_y_skip;
    }
    destination_limit =
        destination_buffer +
        (short)((destination_height_word - (short)copy_height) *
                (short)destination_stride);

    if (destination_top < sprite_top) {
        frame_offset = source_frame * source_width;
        row_offset = (sprite_height - 1) * source_stride;
    } else {
        row_offset = source_frame * source_width;
        frame_offset =
            ((sprite_top - destination_top) + sprite_height - 1) *
            source_stride;
    }
    source_start_offset = frame_offset + row_offset - 1;

    if (horizontal_flip == 1) {
        source_start_offset += source_width - copy_width;
        if (destination_left > sprite_left) {
            source_start_offset += sprite_left - destination_left;
        }
    } else if (destination_left >= sprite_left) {
        source_start_offset += destination_left - sprite_left;
    }

    transparent = transparent_index;
    if (horizontal_flip == 0) {
        source_cursor = source_pixels + source_start_offset + 1;
        destination_cursor = destination_buffer + destination_start_offset;
        column = 0;
        do {
            do {
                if (*source_cursor != transparent) {
                    *destination_cursor = *source_cursor;
                }
                ++column;
                ++destination_cursor;
                ++source_cursor;
            } while (column < copy_width);
            destination_cursor -= column;
            source_cursor -= column;
            column = 0;
            source_cursor -= source_stride;
            destination_cursor -= destination_stride;
        } while (destination_limit <= destination_cursor);
        return;
    }

    destination_cursor = destination_buffer + destination_start_offset;
    source_cursor = source_pixels + source_start_offset + copy_width;
    column = 0;
    do {
        do {
            if (*source_cursor != transparent) {
                *destination_cursor = *source_cursor;
            }
            ++column;
            ++destination_cursor;
            --source_cursor;
        } while (column < copy_width);
        destination_cursor -= column;
        column = 0;
        source_cursor += copy_width;
        source_cursor -= source_stride;
        destination_cursor -= destination_stride;
    } while (destination_limit <= destination_cursor);
}

#pragma optimize("", on)
#pragma code_seg()

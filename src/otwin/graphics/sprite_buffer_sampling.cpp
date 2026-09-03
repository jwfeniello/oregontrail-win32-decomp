// Semantic sprite-buffer sampling trials.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct SpriteBufferSampler_00410cf0_47pct {
    char reserved_00[8];
    unsigned char* source_pixels;
    unsigned short source_frame;
    unsigned short source_columns_per_row;
    char reserved_10[0x1c];
    unsigned short source_width;
    unsigned short source_height;

    short OtSampleSpriteBufferPixelAlt1_00410cf0_47pct(short x, short y) const;
    short OtSampleSpriteBufferPixelAlt2_00410cf0_47pct(short x, short y) const;
    short OtSampleSpriteBufferPixelAlt3_00410cf0_47pct(short x, short y) const;
    short OtSampleSpriteBufferPixelAlt4_00410cf0_47pct(short x, short y) const;
    short OtSampleSpriteBufferPixelAlt5_00410cf0_47pct(short x, short y) const;
    short OtSampleSpriteBufferPixelAlt10_00410cf0_47pct(short x, short y) const;
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

/**
 * Purpose: sample one signed palette-index byte from the selected sprite frame.
 *
 * Parameters:
 * - x: local source-frame x coordinate; values outside the frame return -1.
 * - y: local source-frame y coordinate; values outside the frame return -1.
 */
short SpriteBufferSampler_00410cf0_47pct::OtSampleSpriteBufferPixelAlt1_00410cf0_47pct(
    short x,
    short y) const
{
    if (source_pixels == 0) {
        return -1;
    }

    unsigned short width = source_width;
    if (x >= static_cast<short>(width) || x < 0) {
        return -1;
    }

    if (static_cast<int>(static_cast<unsigned short>(source_height)) <= static_cast<int>(y) ||
        y < 0) {
        return -1;
    }

    unsigned short columns = source_columns_per_row;
    unsigned short stride = static_cast<unsigned short>(width * columns);
    if ((static_cast<unsigned int>(static_cast<unsigned short>(columns)) *
         static_cast<unsigned int>(static_cast<unsigned short>(width)) & 3) != 0) {
        unsigned short remainder = static_cast<unsigned short>(stride & 3);
        stride = static_cast<unsigned short>((stride - remainder) + 4);
    }

    unsigned short offset = static_cast<unsigned short>(
        source_frame * width + stride * y + x - 1);
    return static_cast<short>(static_cast<signed char>(source_pixels[offset]));
}

/**
 * Purpose: sample one signed palette-index byte from the selected sprite frame.
 *
 * Parameters:
 * - x: local source-frame x coordinate; values outside the frame return -1.
 * - y: local source-frame y coordinate; values outside the frame return -1.
 */
short SpriteBufferSampler_00410cf0_47pct::OtSampleSpriteBufferPixelAlt2_00410cf0_47pct(
    short x,
    short y) const
{
    if (source_pixels != 0) {
        register unsigned short width = source_width;
        register short x_local = x;
        if (static_cast<int>(x_local) < static_cast<int>(width) && x_local >= 0) {
            register short y_local = y;
            if (static_cast<int>(static_cast<unsigned short>(source_height)) >
                    static_cast<int>(y_local) &&
                y_local >= 0) {
                unsigned short columns = source_columns_per_row;
                unsigned short stride = static_cast<unsigned short>(width * columns);
                unsigned int stride_check =
                    static_cast<unsigned int>(columns) * static_cast<unsigned int>(width);
                if ((stride_check & 3) != 0) {
                    stride = static_cast<unsigned short>((stride - (stride & 3)) + 4);
                }

                unsigned short offset = static_cast<unsigned short>(source_frame * width);
                offset = static_cast<unsigned short>(offset + stride * y_local);
                offset = static_cast<unsigned short>(offset + x_local - 1);
                return static_cast<short>(static_cast<signed char>(source_pixels[offset]));
            }
        }
    }

    return -1;
}

/**
 * Purpose: sample one signed palette-index byte from the selected sprite frame.
 *
 * Parameters:
 * - x: local source-frame x coordinate; values outside the frame return -1.
 * - y: local source-frame y coordinate; values outside the frame return -1.
 */
short SpriteBufferSampler_00410cf0_47pct::OtSampleSpriteBufferPixelAlt3_00410cf0_47pct(
    short x,
    short y) const
{
    if (source_pixels != 0) {
        register unsigned short width = source_width;
        register short x_local = x;
        register unsigned int width_32 = width;
        if (static_cast<int>(x_local) < static_cast<int>(width_32)) {
            if (x_local >= 0) {
                register short y_local = y;
                register int signed_y = y_local;
                unsigned short height = source_height;
                if (static_cast<int>(height) > signed_y) {
                    if (y_local >= 0) {
                        unsigned short columns = source_columns_per_row;
                        unsigned int stride_check =
                            static_cast<unsigned int>(columns) * width_32;
                        unsigned short stride = static_cast<unsigned short>(width * columns);
                        if ((stride_check & 3) != 0) {
                            unsigned short remainder = static_cast<unsigned short>(stride & 3);
                            stride = static_cast<unsigned short>(stride - remainder + 4);
                        }

                        unsigned short offset = static_cast<unsigned short>(source_frame * width);
                        offset = static_cast<unsigned short>(offset + stride * y_local);
                        offset = static_cast<unsigned short>(offset + x_local - 1);
                        return static_cast<short>(
                            static_cast<signed char>(source_pixels[offset]));
                    }
                }
            }
        }
    }

    return -1;
}

/**
 * Purpose: sample one signed palette-index byte from the selected sprite frame.
 *
 * Parameters:
 * - x: local source-frame x coordinate; values outside the frame return -1.
 * - y: local source-frame y coordinate; values outside the frame return -1.
 */
short SpriteBufferSampler_00410cf0_47pct::OtSampleSpriteBufferPixelAlt4_00410cf0_47pct(
    short x,
    short y) const
{
    if (source_pixels == 0) {
        return -1;
    }

    register short x_local = x;
    unsigned short width = source_width;
    unsigned int width_32 = width;
    if (static_cast<int>(x_local) >= static_cast<int>(width_32)) {
        return -1;
    }
    if (x_local < 0) {
        return -1;
    }

    register short y_local = y;
    register int signed_y = y_local;
    unsigned short height = source_height;
    if (static_cast<int>(height) <= signed_y) {
        return -1;
    }
    if (y_local < 0) {
        return -1;
    }

    unsigned short columns = source_columns_per_row;
    unsigned int stride_check = static_cast<unsigned int>(columns) * width_32;
    unsigned short stride = static_cast<unsigned short>(width * columns);
    if ((stride_check & 3) != 0) {
        unsigned short remainder = static_cast<unsigned short>(stride & 3);
        stride = static_cast<unsigned short>(stride - remainder + 4);
    }

    unsigned short offset = static_cast<unsigned short>(source_frame * width);
    offset = static_cast<unsigned short>(offset + stride * y_local);
    offset = static_cast<unsigned short>(offset + x_local - 1);
    return static_cast<short>(static_cast<signed char>(source_pixels[offset]));
}

/**
 * Purpose: sample one signed palette-index byte from the selected sprite frame.
 *
 * Parameters:
 * - x: local source-frame x coordinate; values outside the frame return -1.
 * - y: local source-frame y coordinate; values outside the frame return -1.
 */
short SpriteBufferSampler_00410cf0_47pct::OtSampleSpriteBufferPixelAlt5_00410cf0_47pct(
    short x,
    short y) const
{
    register short y_local;
    int signed_y;
    unsigned short columns;
    unsigned int stride_check;
    unsigned short stride;
    unsigned short offset;

    if (source_pixels == 0) {
        return -1;
    }

    register short x_local = x;
    unsigned short width = source_width;
    if (static_cast<int>(x_local) >= static_cast<int>(static_cast<unsigned short>(width))) {
        goto OutOfBounds;
    }
    if (x_local < 0) {
        goto OutOfBounds;
    }

    y_local = y;
    signed_y = y_local;
    if (static_cast<int>(static_cast<unsigned short>(source_height)) <= signed_y) {
        goto OutOfBounds;
    }
    if (y_local < 0) {
        goto OutOfBounds;
    }

    columns = source_columns_per_row;
    stride_check =
        static_cast<unsigned int>(columns) *
        static_cast<unsigned int>(static_cast<unsigned short>(width));
    stride = static_cast<unsigned short>(width * columns);
    if ((stride_check & 3) != 0) {
        unsigned short remainder = static_cast<unsigned short>(stride & 3);
        stride = static_cast<unsigned short>(stride - remainder + 4);
    }

    offset = static_cast<unsigned short>(source_frame * width);
    offset = static_cast<unsigned short>(offset + stride * y_local);
    offset = static_cast<unsigned short>(offset + x_local - 1);
    return static_cast<short>(static_cast<signed char>(source_pixels[offset]));

OutOfBounds:
    return -1;
}

/**
 * Byte-exact recovered sampler. The signed 16-bit local gives VC4 the original
 * width/x register pairing; explicit unsigned conversions preserve the source
 * dimensions and row-product semantics.
 */
short SpriteBufferSampler_00410cf0_47pct::OtSampleSpriteBufferPixelAlt10_00410cf0_47pct(
    short x,
    short y) const
{
    register short x_local;
    unsigned short columns;
    short stride;

    if (source_pixels == 0) {
        return -1;
    }

    const short width = (short)source_width;
    x_local = x;
    if ((int)x_local < (int)(unsigned int)(unsigned short)width && x_local >= 0) {
        const short y_local = y;
        if ((int)y_local < (int)(unsigned int)source_height && y_local >= 0) {
            columns = source_columns_per_row;
            if (((unsigned int)columns * (unsigned int)(unsigned short)width & 3) == 0) {
                stride = (short)(width * columns);
            } else {
                stride = (short)((width * columns - (width * columns & 3)) + 4);
            }

            return (short)(signed char)source_pixels[
                (unsigned short)(source_frame * width + stride * y_local + x_local - 1)];
        }
    }

    return -1;
}

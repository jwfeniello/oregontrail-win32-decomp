// Focused semantic promotion for river-crossing sprite-layer redraw.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "../graphics/raw_indexed_bitmap_runtime.h"
#include "../graphics/sprite_blitter_runtime.h"

#pragma pack(push, 1)
struct RiverCrossingSpriteLayer_00428520 {
    char reserved_00[0x1e];
    short active;
};

struct RiverCrossingView_00428520 {
    char reserved_00[0x48];
    unsigned char* scratch_pixels;
    char reserved_4c[0x40];
    void* background_bitmap;
    RiverCrossingSpriteLayer_00428520* layers[8];

    void OtRenderRiverCrossingSpriteLayer_00428520_RealCpp(
        void* dc,
        int layer);
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

void RiverCrossingView_00428520::OtRenderRiverCrossingSpriteLayer_00428520_RealCpp(
    void* dc,
    int layer)
{
    register RiverCrossingSpriteLayer_00428520** selected = &layers[layer];
    register RiverCrossingView_00428520* state = this;

    if (*selected != 0) {
        reinterpret_cast<SpriteBlitter_00410660_Product*>(*selected)->
            OtExtractSpriteRegionToBuffer_Product_00410840(
            reinterpret_cast<RawIndexedBitmap_00410490_Product*>(
                state->background_bitmap),
            state->scratch_pixels);

        register int remaining;
        register RiverCrossingSpriteLayer_00428520** current;

        current = state->layers;
        remaining = 8;
        do {
            if (*current != 0 && (*current)->active != 0) {
                reinterpret_cast<SpriteBlitter_00410660_Product*>(*current)->
                    OtCompositeSpriteIntoBuffer_Product_00410a30(
                    reinterpret_cast<SpriteBlitter_00410660_Product*>(
                        *selected),
                    state->scratch_pixels,
                    reinterpret_cast<RawIndexedBitmap_00410490_Product*>(
                        state->background_bitmap));
            }

            ++current;
            --remaining;
        } while (remaining != 0);

        reinterpret_cast<SpriteBlitter_00410660_Product*>(*selected)->
            OtBlitSpriteBuffer_Product_004106e0(
            dc,
            reinterpret_cast<RawIndexedBitmap_00410490_Product*>(
                state->background_bitmap),
            state->scratch_pixels);
    }
}

#pragma optimize("", on)

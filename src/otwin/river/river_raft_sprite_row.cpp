// Focused semantic promotion for the rafting sprite-row redraw helper.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif


#include "../graphics/raw_indexed_bitmap_runtime.h"
#include "../graphics/sprite_blitter_runtime.h"

#pragma pack(push, 1)
struct RaftSprite_00426740 {
    char reserved_00[0x1e];
    short active;
};

struct RaftingState_00426740 {
    char reserved_00[0x70];
    unsigned char* scratch_pixels;
    void* background_bitmap;
    char reserved_78[4];
    RaftSprite_00426740* sprites[4];

    void OtRiver_RenderRaftSpriteRow_00426740_RealCpp(void* dc, int slot);
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

void RaftingState_00426740::OtRiver_RenderRaftSpriteRow_00426740_RealCpp(
    void* dc,
    int slot)
{
    register RaftSprite_00426740** selected = &sprites[slot];
    register RaftingState_00426740* state = this;

    reinterpret_cast<SpriteBlitter_00410660_Product*>(*selected)->
        OtExtractSpriteRegionToBuffer_Product_00410840(
        reinterpret_cast<RawIndexedBitmap_00410490_Product*>(
            state->background_bitmap),
        state->scratch_pixels);

    register int remaining = 3;
    register RaftSprite_00426740** current = &state->sprites[3];
    do {
        if ((*current)->active != 0) {
            reinterpret_cast<SpriteBlitter_00410660_Product*>(*current)->
                OtCompositeSpriteIntoBuffer_Product_00410a30(
                reinterpret_cast<SpriteBlitter_00410660_Product*>(*selected),
                state->scratch_pixels,
                reinterpret_cast<RawIndexedBitmap_00410490_Product*>(
                    state->background_bitmap));
        }

        --current;
        --remaining;
    } while (remaining >= 0);

    reinterpret_cast<SpriteBlitter_00410660_Product*>(*selected)->
        OtBlitSpriteBuffer_Product_004106e0(
        dc,
        reinterpret_cast<RawIndexedBitmap_00410490_Product*>(
            state->background_bitmap),
        state->scratch_pixels);
}

#pragma optimize("", on)

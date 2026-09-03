// Focused semantic trials for hunt sprite redraw helpers.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "../graphics/raw_indexed_bitmap_runtime.h"
#include "../graphics/sprite_blitter_runtime.h"

#pragma pack(push, 1)
struct HuntSprite_00414340 {
    char reserved_00[0x1e];
    short active;

    void OtExtractSpriteRegionToBuffer_00410840(
        void* background,
        void* scratch);
    void OtCompositeSpriteIntoBuffer_00410a30(
        HuntSprite_00414340* selected,
        void* scratch,
        void* background);
    void OtBlitSpriteBuffer_004106e0(
        void* dc,
        void* background,
        void* scratch);
};

struct HuntState_00414340 {
    char reserved_000[8];
    unsigned char* scratch_pixels;
    char reserved_00c[0x16c];
    void* background_bitmap;
    HuntSprite_00414340* active_sprites[1];

    void OtRedrawHuntSpriteSlot_00414340_RealCpp(void* dc, int slot);
    void OtRedrawHuntSceneWithoutSpriteSlot_004143c0_RealCpp(
        void* dc,
        int omitted_slot);
    void OtRedrawHuntSceneWithoutSpriteSlotAlt2_004143c0_RealCpp(
        void* dc,
        int omitted_slot);
    void OtRedrawHuntSceneWithoutSpriteSlotAlt3_004143c0_RealCpp(
        void* dc,
        int omitted_slot);
    void OtRedrawHuntSceneWithoutSpriteSlotAlt4_004143c0_RealCpp(
        void* dc,
        register int omitted_slot);
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

static __inline int OtHuntSlotsDiffer_004143c0(int left, int right)
{
    return left != right;
}

void HuntSprite_00414340::OtExtractSpriteRegionToBuffer_00410840(
    void* background,
    void* scratch)
{
    reinterpret_cast<SpriteBlitter_00410660_Product*>(this)->
        OtExtractSpriteRegionToBuffer_Product_00410840(
        reinterpret_cast<RawIndexedBitmap_00410490_Product*>(background),
        reinterpret_cast<unsigned char*>(scratch));
}

void HuntSprite_00414340::OtCompositeSpriteIntoBuffer_00410a30(
    HuntSprite_00414340* selected,
    void* scratch,
    void* background)
{
    reinterpret_cast<SpriteBlitter_00410660_Product*>(this)->
        OtCompositeSpriteIntoBuffer_Product_00410a30(
        reinterpret_cast<SpriteBlitter_00410660_Product*>(selected),
        reinterpret_cast<unsigned char*>(scratch),
        reinterpret_cast<RawIndexedBitmap_00410490_Product*>(background));
}

void HuntSprite_00414340::OtBlitSpriteBuffer_004106e0(
    void* dc,
    void* background,
    void* scratch)
{
    reinterpret_cast<SpriteBlitter_00410660_Product*>(this)->
        OtBlitSpriteBuffer_Product_004106e0(
        dc,
        reinterpret_cast<RawIndexedBitmap_00410490_Product*>(background),
        scratch);
}

void HuntState_00414340::OtRedrawHuntSpriteSlot_00414340_RealCpp(
    void* dc,
    int slot)
{
    register HuntSprite_00414340** selected = &active_sprites[slot];
    register HuntState_00414340* state = this;

    reinterpret_cast<SpriteBlitter_00410660_Product*>(*selected)->
        OtExtractSpriteRegionToBuffer_Product_00410840(
        reinterpret_cast<RawIndexedBitmap_00410490_Product*>(
            state->background_bitmap),
        state->scratch_pixels);

    register HuntSprite_00414340** current = state->active_sprites;
    while ((*current)->active != 0) {
        reinterpret_cast<SpriteBlitter_00410660_Product*>(*current)->
            OtCompositeSpriteIntoBuffer_Product_00410a30(
            reinterpret_cast<SpriteBlitter_00410660_Product*>(*selected),
            state->scratch_pixels,
            reinterpret_cast<RawIndexedBitmap_00410490_Product*>(
                state->background_bitmap));
        ++current;
    }

    reinterpret_cast<SpriteBlitter_00410660_Product*>(*selected)->
        OtBlitSpriteBuffer_Product_004106e0(
        dc,
        reinterpret_cast<RawIndexedBitmap_00410490_Product*>(
            state->background_bitmap),
        state->scratch_pixels);
}

void HuntState_00414340::OtRedrawHuntSceneWithoutSpriteSlot_004143c0_RealCpp(
    void* dc,
    int omitted_slot)
{
    register int skipped_slot = omitted_slot;
    register HuntState_00414340* state = this;
    int slot_index;

    state->active_sprites[skipped_slot]->OtExtractSpriteRegionToBuffer_00410840(
        state->background_bitmap,
        state->scratch_pixels);

    slot_index = 0;
    register HuntSprite_00414340** current = state->active_sprites;
    while ((*current)->active != 0) {
        if (OtHuntSlotsDiffer_004143c0(slot_index, skipped_slot)) {
            (*current)->OtCompositeSpriteIntoBuffer_00410a30(
                state->active_sprites[skipped_slot],
                state->scratch_pixels,
                state->background_bitmap);
        }

        ++current;
        ++slot_index;
    }

    state->active_sprites[skipped_slot]->OtBlitSpriteBuffer_004106e0(
        dc,
        state->background_bitmap,
        state->scratch_pixels);
}

void HuntState_00414340::OtRedrawHuntSceneWithoutSpriteSlotAlt2_004143c0_RealCpp(
    void* dc,
    int omitted_slot)
{
    register int skipped_slot = omitted_slot;
    register HuntState_00414340* state = this;
    register int slot_index;
    register HuntSprite_00414340** current;

    slot_index = 0;
    current = state->active_sprites;

    reinterpret_cast<SpriteBlitter_00410660_Product*>(
        state->active_sprites[skipped_slot])->
        OtExtractSpriteRegionToBuffer_Product_00410840(
        reinterpret_cast<RawIndexedBitmap_00410490_Product*>(
            state->background_bitmap),
        state->scratch_pixels);

    while ((*current)->active != 0) {
        if (slot_index != skipped_slot) {
            reinterpret_cast<SpriteBlitter_00410660_Product*>(*current)->
                OtCompositeSpriteIntoBuffer_Product_00410a30(
                reinterpret_cast<SpriteBlitter_00410660_Product*>(
                    state->active_sprites[skipped_slot]),
                state->scratch_pixels,
                reinterpret_cast<RawIndexedBitmap_00410490_Product*>(
                    state->background_bitmap));
        }

        ++current;
        ++slot_index;
    }

    reinterpret_cast<SpriteBlitter_00410660_Product*>(
        state->active_sprites[skipped_slot])->OtBlitSpriteBuffer_Product_004106e0(
        dc,
        reinterpret_cast<RawIndexedBitmap_00410490_Product*>(
            state->background_bitmap),
        state->scratch_pixels);
}

void HuntState_00414340::OtRedrawHuntSceneWithoutSpriteSlotAlt3_004143c0_RealCpp(
    void* dc,
    int omitted_slot)
{
    register int skipped_slot = omitted_slot;
    register HuntState_00414340* state = this;
    register int slot_index = 0;
    register HuntSprite_00414340** current = state->active_sprites;
    HuntSprite_00414340* candidate = *current;

    reinterpret_cast<SpriteBlitter_00410660_Product*>(
        state->active_sprites[skipped_slot])->
        OtExtractSpriteRegionToBuffer_Product_00410840(
        reinterpret_cast<RawIndexedBitmap_00410490_Product*>(
            state->background_bitmap),
        state->scratch_pixels);

    if (candidate->active != 0) {
        do {
            if (slot_index != skipped_slot) {
                reinterpret_cast<SpriteBlitter_00410660_Product*>(candidate)->
                    OtCompositeSpriteIntoBuffer_Product_00410a30(
                    reinterpret_cast<SpriteBlitter_00410660_Product*>(
                        state->active_sprites[skipped_slot]),
                    state->scratch_pixels,
                    reinterpret_cast<RawIndexedBitmap_00410490_Product*>(
                        state->background_bitmap));
            }

            ++current;
            ++slot_index;
            candidate = *current;
        } while (candidate->active != 0);
    }

    reinterpret_cast<SpriteBlitter_00410660_Product*>(
        state->active_sprites[skipped_slot])->OtBlitSpriteBuffer_Product_004106e0(
        dc,
        reinterpret_cast<RawIndexedBitmap_00410490_Product*>(
            state->background_bitmap),
        state->scratch_pixels);
}

void HuntState_00414340::OtRedrawHuntSceneWithoutSpriteSlotAlt4_004143c0_RealCpp(
    void* dc,
    register int omitted_slot)
{
    register int skipped_slot = omitted_slot;
    register HuntState_00414340* state = this;
    int slot_index = 0;
    HuntSprite_00414340** current = state->active_sprites;

    reinterpret_cast<SpriteBlitter_00410660_Product*>(
        state->active_sprites[skipped_slot])->
        OtExtractSpriteRegionToBuffer_Product_00410840(
        reinterpret_cast<RawIndexedBitmap_00410490_Product*>(
            state->background_bitmap),
        state->scratch_pixels);

    while ((*current)->active != 0) {
        if (skipped_slot != slot_index) {
            reinterpret_cast<SpriteBlitter_00410660_Product*>(*current)->
                OtCompositeSpriteIntoBuffer_Product_00410a30(
                reinterpret_cast<SpriteBlitter_00410660_Product*>(
                    state->active_sprites[skipped_slot]),
                state->scratch_pixels,
                reinterpret_cast<RawIndexedBitmap_00410490_Product*>(
                    state->background_bitmap));
        }

        ++current;
        ++slot_index;
    }

    reinterpret_cast<SpriteBlitter_00410660_Product*>(
        state->active_sprites[skipped_slot])->OtBlitSpriteBuffer_Product_004106e0(
        dc,
        reinterpret_cast<RawIndexedBitmap_00410490_Product*>(
            state->background_bitmap),
        state->scratch_pixels);
}

#pragma optimize("", on)

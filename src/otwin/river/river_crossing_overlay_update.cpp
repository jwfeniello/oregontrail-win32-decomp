// Focused semantic promotion for river-crossing overlay update/redraw.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct RiverCrossingOverlaySprite_00427e80 {
    char reserved_00[0x28];
    short x;
    short y;
};

struct RiverCrossingOverlayState_00427e80 {
    char reserved_00[0x90];
    RiverCrossingOverlaySprite_00427e80* layers[8];

    void OtUpdateRiverCrossingOverlay_00427e80_RealCpp(
        void* dc,
        void* owner);
};

struct RiverCrossingBackdropState_00428480 {
    void OtRenderRiverCrossingBackdrop_00428480_RealCpp(void* owner);
};

struct RiverCrossingView_00428520 {
    void OtRenderRiverCrossingSpriteLayer_00428520_RealCpp(
        void* dc,
        int layer);
};

struct RiverCrossingState_00428e80 {
    void OtRenderRiverCrossingRemainingLayers_RealCpp(
        void* dc,
        void* owner);
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

void RiverCrossingOverlayState_00427e80::OtUpdateRiverCrossingOverlay_00427e80_RealCpp(
    void* dc,
    void* owner)
{
    register RiverCrossingOverlayState_00427e80* state = this;

    state->layers[1]->x = (short)(state->layers[1]->x + 2);

    register void* owner_window = owner;

    state->layers[1]->y = (short)(state->layers[1]->y + 1);
    state->layers[0]->x = (short)(state->layers[0]->x + 2);
    state->layers[0]->y = (short)(state->layers[0]->y + 1);

    ((RiverCrossingBackdropState_00428480*)state)
        ->OtRenderRiverCrossingBackdrop_00428480_RealCpp(owner_window);

    register void* render_dc = dc;

    ((RiverCrossingView_00428520*)state)
        ->OtRenderRiverCrossingSpriteLayer_00428520_RealCpp(render_dc, 1);
    ((RiverCrossingView_00428520*)state)
        ->OtRenderRiverCrossingSpriteLayer_00428520_RealCpp(render_dc, 0);
    ((RiverCrossingState_00428e80*)state)
        ->OtRenderRiverCrossingRemainingLayers_RealCpp(render_dc, owner_window);
}

#pragma optimize("", on)

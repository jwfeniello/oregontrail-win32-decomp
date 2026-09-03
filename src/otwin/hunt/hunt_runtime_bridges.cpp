// ABI bridges from the unified hunt runtime to recovered graphics owners.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This recovered runtime requires 32-bit MSVC."
#endif

#include "hunt_runtime_state.h"

struct HuntState_00414340 {
    void OtRedrawHuntSpriteSlot_00414340_RealCpp(void* dc, int slot);
    void OtRedrawHuntSceneWithoutSpriteSlot_004143c0_RealCpp(
        void* dc,
        int omitted_slot);
};

#pragma optimize("s", off)
#pragma optimize("t", on)
#pragma code_seg(".otsem")

void HuntRuntimeState_004122b0_Product::
    OtRedrawHuntSceneWithoutSpriteSlot_Product(
        void* draw_context,
        int omitted_slot)
{
    reinterpret_cast<HuntState_00414340*>(this)->
        OtRedrawHuntSceneWithoutSpriteSlot_004143c0_RealCpp(
            draw_context,
            omitted_slot);
}

void HuntRuntimeState_004122b0_Product::OtRedrawHuntSpriteSlot_Product(
    void* draw_context,
    int slot)
{
    reinterpret_cast<HuntState_00414340*>(this)->
        OtRedrawHuntSpriteSlot_00414340_RealCpp(draw_context, slot);
}

#pragma code_seg()
#pragma optimize("", on)

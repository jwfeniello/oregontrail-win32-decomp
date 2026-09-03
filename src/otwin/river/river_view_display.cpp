// Semantic river-view display register-shape trials.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "../graphics/raw_indexed_bitmap_runtime.h"

extern "C" __declspec(dllimport) int __stdcall ShowWindow(
    void* window,
    int command_show);

#pragma comment(lib, "user32.lib")

#pragma pack(push, 1)
struct RiverCrossingOverlayState_00427e80 {
    void OtUpdateRiverCrossingOverlay_00427e80_RealCpp(
        void* dc,
        void* owner);
};

struct RiverCrossingView_00427f00_43pct {
    char reserved_00[0x40];
    void* child_window;
    char reserved_44[0x48];
    RawIndexedBitmap_00410490_Product* base_bitmap;

    void OtShowRiverCrossingViewAlt1_00427f00_43pct(void* dc, void* owner);
    void OtShowRiverCrossingViewAlt2_00427f00_43pct(void* dc, void* owner);
};
#pragma pack(pop)

#pragma optimize("a", on)
#pragma optimize("s", off)
#pragma optimize("t", on)

/**
 * Purpose: show the river-crossing child window, draw the base river bitmap,
 * and then draw the dynamic crossing overlay.
 *
 * Parameters:
 * - dc: destination device context used for both the base bitmap and overlay.
 * - owner: owner window passed through to the overlay refresh helper.
 */
void RiverCrossingView_00427f00_43pct::OtShowRiverCrossingViewAlt1_00427f00_43pct(
    void* dc,
    void* owner)
{
    register void* draw_dc = dc;
    register RiverCrossingView_00427f00_43pct* view = this;

    ShowWindow(view->child_window, 5);
    view->base_bitmap->OtBlitRawIndexedBitmap_Product_004105a0(
        draw_dc,
        0x3b,
        1);
    reinterpret_cast<RiverCrossingOverlayState_00427e80*>(view)->
        OtUpdateRiverCrossingOverlay_00427e80_RealCpp(draw_dc, owner);
}

/**
 * Purpose: show the river-crossing child window, draw the base river bitmap,
 * and then draw the dynamic crossing overlay.
 *
 * Parameters:
 * - dc: destination device context used for both the base bitmap and overlay.
 * - owner: owner window passed through to the overlay refresh helper.
 */
void RiverCrossingView_00427f00_43pct::OtShowRiverCrossingViewAlt2_00427f00_43pct(
    void* dc,
    void* owner)
{
    register void* draw_dc = dc;
    register RiverCrossingView_00427f00_43pct* view = this;
    void* overlay_owner = owner;

    ShowWindow(view->child_window, 5);
    view->base_bitmap->OtBlitRawIndexedBitmap_Product_004105a0(
        draw_dc,
        0x3b,
        1);
    reinterpret_cast<RiverCrossingOverlayState_00427e80*>(view)->
        OtUpdateRiverCrossingOverlay_00427e80_RealCpp(
            draw_dc,
            overlay_owner);
}

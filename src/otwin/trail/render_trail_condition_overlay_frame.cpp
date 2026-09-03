// Semantic candidate for OtRenderTrailConditionOverlayFrame (0x004068a0).

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct JourneyState_000068a0 {
    char reserved_000[0x5a];
    unsigned short route_stop_flags;
    char reserved_05c[0x3a];
    short trail_continue_days;
};

struct PositionedBitmap_0040b7b0_Semantic {
    char reserved_000[0x28];

    int OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        void* dc,
        int source_x,
        int source_y);
};

struct TrailConditionOverlayFrame_000068a0 {
    char reserved_000[0x174];
    PositionedBitmap_0040b7b0_Semantic default_trail_overlay;
    PositionedBitmap_0040b7b0_Semantic no_food_overlay;
    PositionedBitmap_0040b7b0_Semantic no_one_able_overlay;
    PositionedBitmap_0040b7b0_Semantic no_oxen_overlay;
    PositionedBitmap_0040b7b0_Semantic stopped_or_failed_overlay;

    void __declspec(dllexport)
    OtRenderTrailConditionOverlayFrame_000068a0_RealCpp(void* dc);
};
#pragma pack(pop)

extern "C" JourneyState_000068a0* g_journeyState;

#pragma optimize("s", off)
#pragma optimize("t", on)

void TrailConditionOverlayFrame_000068a0::
    OtRenderTrailConditionOverlayFrame_000068a0_RealCpp(void* dc)
{
    unsigned short route_stop_flags;

    route_stop_flags = g_journeyState->route_stop_flags;
    if ((route_stop_flags & 0x50) == 0) {
        if (g_journeyState->trail_continue_days <= 0) {
            stopped_or_failed_overlay.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                dc,
                0,
                0);
            return;
        }
        if ((route_stop_flags & 2) != 0) {
            no_one_able_overlay.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                dc,
                0,
                0);
            return;
        }
        if ((route_stop_flags & 8) != 0) {
            no_oxen_overlay.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                dc,
                0,
                0);
            return;
        }
        if ((route_stop_flags & 4) == 0) {
            goto render_return;
        }

        no_food_overlay.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
            dc,
            0,
            0);
        return;
    }

render_default:
    default_trail_overlay.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        dc,
        0,
        0);
render_return:
    return;
}

#pragma optimize("", on)

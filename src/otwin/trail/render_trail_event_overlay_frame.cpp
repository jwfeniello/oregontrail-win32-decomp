// Semantic candidate for OtRenderTrailEventOverlayFrame (0x00406760).

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

extern "C" __declspec(dllimport) int __stdcall FillRgn(
    void* dc,
    void* region,
    unsigned long brush);
extern "C" __declspec(dllimport) int __stdcall DeleteObject(
    unsigned long object);

#pragma comment(lib, "gdi32.lib")

#pragma pack(push, 1)
struct JourneyState_00006760 {
    char reserved_000[0x96];
    short trail_continue_days;
};

struct PositionedBitmap_0040b7b0_Semantic {
    char reserved_000[0x28];

    int OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        void* dc,
        int source_x,
        int source_y);
};

struct TrailPaletteBrushState_00406940 {
    unsigned long OtCreateTrailGroundBrush_00406940_ProductWip(void* dc);
    unsigned long OtCreateTrailSkyBrush_00406980_ProductWip(void* dc);
};

struct TrailEventOverlayFrame_00006760 {
    char reserved_000[0x10];
    void* event_fill_region;
    char reserved_014[0x98];
    PositionedBitmap_0040b7b0_Semantic travel_frames[5];
    char reserved_174[0x28];
    PositionedBitmap_0040b7b0_Semantic scene_11_overlay;
    PositionedBitmap_0040b7b0_Semantic scene_13_overlay;
    PositionedBitmap_0040b7b0_Semantic scene_12_overlay;
    PositionedBitmap_0040b7b0_Semantic stopped_overlay;
    PositionedBitmap_0040b7b0_Semantic scene_20_overlay;
    int active_frame_index;

    void OtRenderTrailEventOverlayFrame_00006760_RealCpp(
        void* dc,
        int event_overlay);
};
#pragma pack(pop)

extern "C" JourneyState_00006760* g_journeyState;
extern "C" short g_activeTrailEventScene = 0;

#pragma optimize("s", off)
#pragma optimize("t", on)

void TrailEventOverlayFrame_00006760::
    OtRenderTrailEventOverlayFrame_00006760_RealCpp(
        void* dc,
        int)
{
    register TrailEventOverlayFrame_00006760* overlay = this;

    switch (g_activeTrailEventScene) {
    case 0x11:
        overlay->scene_11_overlay.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
            dc,
            0,
            0);
        return;
    case 0x12:
        overlay->scene_12_overlay.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
            dc,
            0,
            0);
        return;
    case 0x13:
        overlay->scene_13_overlay.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
            dc,
            0,
            0);
        return;
    case 0x17:
        overlay->stopped_overlay.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
            dc,
            0,
            0);
        return;
    case 0x19:
    case 0x1f:
    {
        register unsigned long brush =
            reinterpret_cast<TrailPaletteBrushState_00406940*>(overlay)
                ->OtCreateTrailGroundBrush_00406940_ProductWip(dc);
        FillRgn(dc, overlay->event_fill_region, brush);
        DeleteObject(brush);
        return;
    }
    case 0x20:
        overlay->scene_20_overlay.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
            dc,
            0,
            0);
        return;
    }

    if (g_journeyState->trail_continue_days <= 0) {
        overlay->stopped_overlay.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
            dc,
            0,
            0);
        return;
    }

    overlay->travel_frames[overlay->active_frame_index]
        .OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
}

#pragma optimize("", on)

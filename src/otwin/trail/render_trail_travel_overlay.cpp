// Semantic candidate for OtRenderTrailTravelOverlay (0x004066c0).

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct JourneyState_000066c0 {
    char reserved_000[0x5a];
    short route_stop_flags;
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

struct TrailTravelAnimation_00406400_Product {
    void OtAnimateTrailTravelFrames_00406400_Product(
        void* dc,
        unsigned int tick);
};

struct TrailForegroundSpan_20260603_065d0 {
    void OtClipTrailForegroundSpanAlt80_004065d0_RealCpp(
        void* dc,
        unsigned int clip_start,
        unsigned int clip_end);
};

struct TrailEventOverlayFrame_00006760 {
    void OtRenderTrailEventOverlayFrame_00006760_RealCpp(
        void* dc,
        int event_overlay);
};

struct TrailConditionOverlayFrame_000068a0 {
    void OtRenderTrailConditionOverlayFrame_000068a0_RealCpp(void* dc);
};

struct TrailViewportPaletteState_004070a0_ProductWip {
    void OtAnimateTrailViewportFillPalette_004070a0_ProductWip(int frame);
};

struct TrailTravelOverlay_000066c0 {
    char reserved_000[0x174];
    PositionedBitmap_0040b7b0_Semantic default_overlay;

    void OtRenderTrailTravelOverlay_000066c0_RealCpp(
        void* dc,
        int frame,
        unsigned int clip_start,
        unsigned int clip_end,
        void* palette,
        int event_overlay);
};
#pragma pack(pop)

extern "C" JourneyState_000066c0* g_journeyState;
extern "C" int g_usesIndexedColorDisplay;

#pragma optimize("s", off)
#pragma optimize("t", on)

void TrailTravelOverlay_000066c0::
    OtRenderTrailTravelOverlay_000066c0_RealCpp(
        void* dc,
        int frame,
        unsigned int clip_start,
        unsigned int clip_end,
        void* palette,
        int event_overlay)
{
    register TrailTravelOverlay_000066c0* overlay = this;
    register unsigned int first_clip;
    register unsigned int last_clip;

    if (event_overlay > 0) {
        reinterpret_cast<TrailEventOverlayFrame_00006760*>(overlay)
            ->OtRenderTrailEventOverlayFrame_00006760_RealCpp(
                dc,
                event_overlay);
        goto clip_from_start;
    } else {
        JourneyState_000066c0* journey = g_journeyState;
        if (journey->route_stop_flags == 0 && journey->trail_continue_days > 0) {
            last_clip = clip_end;
            first_clip = clip_start;
            if (last_clip > first_clip) {
                reinterpret_cast<TrailTravelAnimation_00406400_Product*>(
                    overlay)
                    ->OtAnimateTrailTravelFrames_00406400_Product(
                        dc,
                        static_cast<unsigned int>(frame));
                reinterpret_cast<TrailForegroundSpan_20260603_065d0*>(
                    overlay)
                    ->OtClipTrailForegroundSpanAlt80_004065d0_RealCpp(
                        dc,
                        first_clip,
                        last_clip);
                goto maybe_animate_palette;
            }

            overlay->default_overlay
                .OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
            goto clip_with_last;
        } else {
            reinterpret_cast<TrailConditionOverlayFrame_000068a0*>(overlay)
                ->OtRenderTrailConditionOverlayFrame_000068a0_RealCpp(dc);
        }
    }

clip_from_start:
    last_clip = clip_end;
clip_with_last:
    reinterpret_cast<TrailForegroundSpan_20260603_065d0*>(overlay)
        ->OtClipTrailForegroundSpanAlt80_004065d0_RealCpp(
            dc,
            0,
            last_clip);

maybe_animate_palette:
    if (g_usesIndexedColorDisplay != 0) {
        reinterpret_cast<TrailViewportPaletteState_004070a0_ProductWip*>(
            overlay)
            ->OtAnimateTrailViewportFillPalette_004070a0_ProductWip(
                reinterpret_cast<int>(palette));
    }
}

#pragma optimize("", on)

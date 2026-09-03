// Active trail-animation frame refresh recovered from Oregon32.exe.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This source must be compiled with 32-bit MSVC."
#endif

extern "C" __declspec(dllimport) void* __stdcall GetDC(void* window);
extern "C" __declspec(dllimport) void* __stdcall SelectPalette(
    void* dc,
    void* palette,
    int force_background);
extern "C" __declspec(dllimport) int __stdcall ReleaseDC(
    void* window,
    void* dc);

#pragma pack(push, 1)
struct JourneyRouteStopFlags_0042a3d0 {
    char reserved_000[0x5a];
    short route_stop_flags;
};

struct RiverCrossingOverlayState_00427e80 {
    void OtUpdateRiverCrossingOverlay_00427e80_RealCpp(
        void* dc,
        void* owner);
};

struct TrailTravelOverlay_000066c0 {
    void OtRenderTrailTravelOverlay_000066c0_RealCpp(
        void* dc,
        int frame,
        unsigned int clip_start,
        unsigned int clip_end,
        void* palette,
        int event_overlay);
};

struct TrailOverlayWindow_00405df0 {
    void OtShowTrailOverlayWindow_RealCpp(void* owner_window, void* dc);
};

struct TrailAnimationFrameState_0042a3d0 {
    char reserved_000[0x0788];
    TrailOverlayWindow_00405df0* trail_stop_overlay;
    char reserved_78c[0x0284];
    TrailTravelOverlay_000066c0* trail_travel_overlay;
    RiverCrossingOverlayState_00427e80* river_crossing_overlay;
    char reserved_a18[8];
    int travel_submode;
    int stop_transition_pause_pending;
    char reserved_a28[8];
    void* overlay_owner;
    char reserved_a34[0x14];
    unsigned int travelled_distance;
    unsigned int total_distance;
    char reserved_a50[4];
    int overlay_phase;

    void OtRefreshTrailAnimationFrame_RealCpp(void* owner_window);
};
#pragma pack(pop)

extern "C" JourneyRouteStopFlags_0042a3d0* g_journeyState;
extern "C" int g_trailProgressStopPending;
extern "C" void* g_gamePalette;

#pragma optimize("s", off)
#pragma optimize("t", on)

// Refreshes only the active animation layer: river crossing, normal travel,
// or the pending-stop overlay selected by the dialog state.
void TrailAnimationFrameState_0042a3d0::OtRefreshTrailAnimationFrame_RealCpp(
    void* owner_window)
{
    void* window = owner_window;
    void* dc = GetDC(window);
    TrailAnimationFrameState_0042a3d0* state = this;

    SelectPalette(dc, g_gamePalette, 0);
    if (state->travel_submode == 2) {
        state->river_crossing_overlay
            ->OtUpdateRiverCrossingOverlay_00427e80_RealCpp(
                dc,
                state->overlay_owner);
    } else if (g_trailProgressStopPending == 0) {
        if (g_journeyState->route_stop_flags == 0) {
            state->trail_travel_overlay
                ->OtRenderTrailTravelOverlay_000066c0_RealCpp(
                    dc,
                    reinterpret_cast<int>(state->overlay_owner),
                    state->travelled_distance,
                    state->total_distance,
                    reinterpret_cast<void*>(state->overlay_phase),
                    0);
        }
    } else if (g_journeyState->route_stop_flags == 0) {
        state->trail_stop_overlay->OtShowTrailOverlayWindow_RealCpp(
            window,
            dc);
    }

    ReleaseDC(window, dc);
}

#pragma optimize("", on)

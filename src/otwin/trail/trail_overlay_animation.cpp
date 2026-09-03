// Canonical semantic trail-overlay state machine and travel-view refresh.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "trail_travel_view_refresh.h"

extern "C" __declspec(dllimport) void* __stdcall GetParent(void* window);
extern "C" __declspec(dllimport) int __stdcall PostMessageA(
    void* window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) void* __stdcall GetDC(void* window);
extern "C" __declspec(dllimport) void* __stdcall SelectPalette(
    void* dc,
    void* palette,
    int force_background);
extern "C" __declspec(dllimport) unsigned int __stdcall RealizePalette(
    void* dc);
extern "C" __declspec(dllimport) int __stdcall ReleaseDC(
    void* window,
    void* dc);

extern "C" int __cdecl OtDispatchTrailScenePhaseCallbacks_00419200_RealCpp(
    void* owner_window,
    int phase);
extern "C" short __fastcall OtCountLivingPartyMembers_RealCpp(
    const void* party);

#pragma pack(push, 1)
struct TrailOverlayWindow_00405df0 {
    void OtShowTrailOverlayWindow_RealCpp(void* owner_window, void* dc);
    void OtHideTrailOverlayWindow_RealCpp();
    void OtPlayCurrentRouteAudioCue_00405e00_ProductWip(
        void* owner_window);
};

struct TrailTravelScene_00006510 {
    void OtRenderTrailTravelScene_00006510_RealCpp(
        void* dc,
        void* animation_frame,
        unsigned int travelled_distance,
        unsigned int total_distance,
        int overlay_phase,
        int caption_id);
};

struct JourneyState_00419f60 {
    char reserved_000[0x5a];
    short route_stop_flags;

    void OtApplyTravelProgressEffectsAlt7_00419f60(
        unsigned int progress_percent);
};

// These methods belong to the shared trail-dialog state. The pause method is
// already Product C++; the two address-qualified declarations deliberately
// expose the remaining real implementation gaps instead of satisfying the
// linker with matcher-only no-op bodies.
struct TrailUiState_0042b370 {
    void OtPauseTrailTravel_RealCpp(void* owner_window);
    void OtRefreshTrailStatusPanel_0042d5d0_ProductWip(
        void* owner_window);
    void OtRestoreTrailViewAfterRiverCrossing_0042c180_ProductWip(
        void* owner_window);
};

struct TrailOverlayStartState_0042dc20 {
    char reserved_000[0x0788];
    TrailOverlayWindow_00405df0* trail_stop_overlay;
    char reserved_78c[0x0284];
    TrailTravelScene_00006510* trail_travel_scene;
    char reserved_a14[8];
    int stop_scene_audio_enabled;
    int river_crossing_mode;
    int stop_transition_pause_pending;
    char reserved_a28[4];
    int trail_animation_active;
    // The shared trail tick is also the animation-frame input to the renderer.
    unsigned int elapsed_ticks;
    unsigned int start_phase_interval;
    unsigned int completion_phase_interval;
    unsigned int flagged_phase_interval;
    unsigned int river_phase_interval;
    char reserved_a44[4];
    unsigned int travelled_distance;
    unsigned int total_distance;
    char reserved_a50[4];
    int overlay_phase;

    void OtRefreshTrailTravelView_0042acc0_RealCpp(void* owner_window);
    int OtAdvanceTrailOverlayStartPhase_RealCpp(void* owner_window);
    int OtAdvanceTrailOverlayCompletionPhase_RealCpp(void* owner_window);
    int OtAdvanceRiverCrossingState_RealCpp(void* owner_window);
    void OtTrailActionGateForwarder_RealCpp(void* owner_window);
};
#pragma pack(pop)

extern "C" JourneyState_00419f60* g_journeyState;
extern "C" int g_trailProgressStopPending;
extern "C" int g_cdMediaMode_00439108;
extern "C" int g_titleThemeEnabled_004390ec;
extern "C" int g_midiPlaybackActive_0040cd60;
extern "C" unsigned int g_wavePlaybackActive_0040d110;
extern "C" void* g_gamePalette;
#pragma data_seg(".otdat")
extern "C" __declspec(allocate(".otdat"))
short g_trailStopOverlayCaptionId_0042acc0 = 0;
#pragma data_seg()

#pragma optimize("s", off)
#pragma optimize("t", on)

// 0042acc0
//
// Refreshes the active trail viewport or stop overlay without repainting the
// whole game dialog.
void TrailOverlayStartState_0042dc20::
    OtRefreshTrailTravelView_0042acc0_RealCpp(void* owner_window)
{
    register void* window = owner_window;
    register TrailOverlayStartState_0042dc20* state = this;
    register void* dc = GetDC(window);

    SelectPalette(dc, g_gamePalette, 0);
    RealizePalette(dc);
    if (g_trailProgressStopPending != 0) {
        state->trail_stop_overlay->OtShowTrailOverlayWindow_RealCpp(
            window,
            dc);
    } else {
        state->trail_stop_overlay->OtHideTrailOverlayWindow_RealCpp();
        if (state->stop_transition_pause_pending != 0) {
            state->trail_travel_scene->OtRenderTrailTravelScene_00006510_RealCpp(
                dc,
                reinterpret_cast<void*>(state->elapsed_ticks),
                state->travelled_distance,
                state->total_distance,
                state->overlay_phase,
                g_trailStopOverlayCaptionId_0042acc0);
        } else {
            state->trail_travel_scene->OtRenderTrailTravelScene_00006510_RealCpp(
                dc,
                reinterpret_cast<void*>(state->elapsed_ticks),
                state->travelled_distance,
                state->total_distance,
                state->overlay_phase,
                0);
        }
    }

    ReleaseDC(window, dc);
}

// Preserve the established one-argument thiscall surface while forwarding all
// Product call paths to the one canonical recovered implementation above.
void TrailAnimationFrameState_0042acc0_Product::
    OtRefreshTrailTravelView_0042acc0_Product(void* owner_window)
{
    reinterpret_cast<TrailOverlayStartState_0042dc20*>(this)->
        OtRefreshTrailTravelView_0042acc0_RealCpp(owner_window);
}

// 0042dc20
//
// Advances the opening phase of the temporary trail overlay sequence.
int TrailOverlayStartState_0042dc20::OtAdvanceTrailOverlayStartPhase_RealCpp(
    void* owner)
{
    register TrailOverlayStartState_0042dc20* state = this;

    if ((state->elapsed_ticks % state->start_phase_interval) == 0) {
        int phase = state->overlay_phase;
        ++phase;
        state->overlay_phase = phase;
        if (phase == 1) {
            OtDispatchTrailScenePhaseCallbacks_00419200_RealCpp(owner, phase);
            state->elapsed_ticks = 1;
        }

        reinterpret_cast<TrailUiState_0042b370*>(state)
            ->OtRefreshTrailStatusPanel_0042d5d0_ProductWip(owner);
    }

    return 0;
}

// 0042dc80
//
// Advances the closing phase and commits pending travel progress when done.
int TrailOverlayStartState_0042dc20::
    OtAdvanceTrailOverlayCompletionPhase_RealCpp(void* owner)
{
    register TrailOverlayStartState_0042dc20* state = this;

    if ((state->elapsed_ticks % state->completion_phase_interval) == 0) {
        int phase = state->overlay_phase;
        ++phase;
        state->overlay_phase = phase;
        if (phase == 3) {
            OtDispatchTrailScenePhaseCallbacks_00419200_RealCpp(owner, phase);
        } else if (phase > 3) {
            g_journeyState->OtApplyTravelProgressEffectsAlt7_00419f60(
                (state->travelled_distance * 100) / state->total_distance);
            state->overlay_phase = 0;
            OtDispatchTrailScenePhaseCallbacks_00419200_RealCpp(owner, 0);
            state->travelled_distance = 1;
            state->trail_animation_active = 1;
            state->OtRefreshTrailTravelView_0042acc0_RealCpp(owner);
        }

        state->elapsed_ticks = 1;
        reinterpret_cast<TrailUiState_0042b370*>(state)
            ->OtRefreshTrailStatusPanel_0042d5d0_ProductWip(owner);
    }

    return 0;
}

// 0042dd40
//
// Advances the active river-crossing timer and posts completion when the party
// has no living members left.
int TrailOverlayStartState_0042dc20::OtAdvanceRiverCrossingState_RealCpp(
    void* owner)
{
    register TrailOverlayStartState_0042dc20* state = this;

    if ((state->elapsed_ticks % state->river_phase_interval) == 0) {
        register void* owner_window = owner;
        TrailUiState_0042b370* trail =
            reinterpret_cast<TrailUiState_0042b370*>(state);
        trail->OtPauseTrailTravel_RealCpp(owner_window);
        trail->OtRestoreTrailViewAfterRiverCrossing_0042c180_ProductWip(
            owner_window);

        int phase = 0;
        if (OtCountLivingPartyMembers_RealCpp(g_journeyState) == 0) {
            PostMessageA(GetParent(owner_window), 0x47d, phase, phase);
            return 0;
        }

        OtDispatchTrailScenePhaseCallbacks_00419200_RealCpp(
            owner_window,
            phase);
        state->elapsed_ticks = 1;
        state->travelled_distance = 1;
    }

    return 0;
}

// 0042d020
//
// Resumes the route cue only when a pending stop is visible and both the route
// state and selected audio backend are idle.
void TrailOverlayStartState_0042dc20::OtTrailActionGateForwarder_RealCpp(
    void* owner)
{
    if (g_trailProgressStopPending != 0 &&
        g_titleThemeEnabled_004390ec != 0 &&
        stop_scene_audio_enabled != 0 &&
        g_journeyState->route_stop_flags == 0 &&
        ((g_cdMediaMode_00439108 != 0 && g_wavePlaybackActive_0040d110 == 0) ||
            (g_cdMediaMode_00439108 == 0 && g_midiPlaybackActive_0040cd60 == 0))) {
        trail_stop_overlay->OtPlayCurrentRouteAudioCue_00405e00_ProductWip(
            owner);
    }
}

#pragma optimize("", on)

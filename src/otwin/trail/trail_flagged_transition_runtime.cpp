// Canonical Product implementation of OtAdvanceTrailFlaggedTransitionPhase
// @ 0x0042de80.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include "trail_travel_view_refresh.h"

#pragma pack(push, 1)
struct RouteDescriptor_0042de80 {
    unsigned short route_stop_index;
    char reserved_002[0x122];
    unsigned short location_bitmap_resource_ids[6];
};

struct JourneyState_00419f60 {
    char reserved_000[0x5a];
    unsigned short route_stop_flags;

    void OtApplyTravelProgressEffectsAlt7_00419f60(
        unsigned int progress_percent);
};

struct LabeledBitmapDisplay_00405f00 {
    void OtUpdateLabeledBitmapDisplay_RealCpp(
        unsigned int bitmap_resource_id,
        unsigned int label_string_id,
        int preserve_label_visibility);
};

struct TrailUiState_0042b370 {
    void OtPauseTrailTravel_RealCpp(void* owner_window);
    void OtRefreshTrailStatusPanel_0042d5d0_ProductWip(
        void* owner_window);
};

struct TrailFlaggedTransitionState_0002de80 {
    char reserved_000[0x0788];
    LabeledBitmapDisplay_00405f00* trail_stop_display;
    char reserved_78c[0x0298];
    int transition_hold;
    char reserved_a28[0x04];
    int special_transition_counter;
    unsigned int trail_tick_counter;
    char reserved_a34[0x08];
    unsigned int transition_tick_divisor;
    char reserved_a40[0x08];
    unsigned int completed_step_ticks;
    unsigned int step_tick_count;
    char reserved_a50[0x04];
    int overlay_phase;

    int OtAdvanceTrailFlaggedTransitionPhase_20260602_Candidate(
        void* owner_window);
};
#pragma pack(pop)

extern "C" JourneyState_00419f60* g_journeyState;
extern "C" RouteDescriptor_0042de80* g_activeRouteDescriptor;
extern "C" int g_trailProgressStopPending;
extern "C" int g_cdMediaMode_00439108;
extern "C" int g_titleThemeEnabled_004390ec;
extern "C" int g_midiPlaybackActive_0040cd60;

extern "C" int __cdecl OtDispatchTrailScenePhaseCallbacks_00419200_RealCpp(
    void* owner_window,
    int phase);
extern "C" unsigned int __fastcall
OtSelectRouteLocationBitmapResourceId_RealCpp(
    RouteDescriptor_0042de80* route);
extern "C" void __cdecl OtCloseWaveAudioDevice_0040d0a0_RealCpp();
extern "C" void __cdecl OtPlayMidiAudio_0000ced0_RealCpp(int play_mode);

#pragma optimize("s", off)
#pragma optimize("t", on)

int TrailFlaggedTransitionState_0002de80::
    OtAdvanceTrailFlaggedTransitionPhase_20260602_Candidate(
        void* owner_window)
{
    register TrailFlaggedTransitionState_0002de80* state = this;

    if ((state->trail_tick_counter % state->transition_tick_divisor) == 0) {
        register int one = 1;
        register void* window = owner_window;

        OtDispatchTrailScenePhaseCallbacks_00419200_RealCpp(window, one);
        OtDispatchTrailScenePhaseCallbacks_00419200_RealCpp(window, 3);
        g_journeyState->OtApplyTravelProgressEffectsAlt7_00419f60(
            (state->completed_step_ticks * 100) / state->step_tick_count);
        OtDispatchTrailScenePhaseCallbacks_00419200_RealCpp(window, 0);

        unsigned int resource_id =
            ((unsigned int)g_activeRouteDescriptor->route_stop_index + 0x0d)
                << 4;
        state->trail_stop_display->OtUpdateLabeledBitmapDisplay_RealCpp(
            OtSelectRouteLocationBitmapResourceId_RealCpp(
                g_activeRouteDescriptor),
            resource_id,
            one);

        reinterpret_cast<TrailAnimationFrameState_0042acc0_Product*>(state)->
            OtRefreshTrailTravelView_0042acc0_Product(window);

        state->trail_tick_counter = one;
        state->completed_step_ticks = one;
        state->special_transition_counter = one;
        state->overlay_phase = one;

        if (g_journeyState->route_stop_flags == 0) {
            if (g_trailProgressStopPending != 0) {
                state->transition_hold = 0;
                reinterpret_cast<TrailUiState_0042b370*>(state)->
                    OtPauseTrailTravel_RealCpp(window);
            } else if (g_cdMediaMode_00439108 != 0 &&
                       g_titleThemeEnabled_004390ec != 0) {
                if (g_midiPlaybackActive_0040cd60 != 0) {
                    OtPlayMidiAudio_0000ced0_RealCpp(-1);
                } else {
                    OtCloseWaveAudioDevice_0040d0a0_RealCpp();
                    OtPlayMidiAudio_0000ced0_RealCpp(0);
                }
            }
        }

        reinterpret_cast<TrailUiState_0042b370*>(state)->
            OtRefreshTrailStatusPanel_0042d5d0_ProductWip(window);
    }

    return 0;
}

#pragma optimize("", on)

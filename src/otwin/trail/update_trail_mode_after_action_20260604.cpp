// Product-tree semantic closure for OtUpdateTrailModeAfterAction @ 0x0042a790.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct JourneyState_0042a790_20260603 {
    char reserved_000[0x5a];
    unsigned char route_stop_flags_low;
    unsigned char route_stop_flags_high;
};

struct RouteStop_0042a790_20260603 {
    short route_id;
    short stop_kind;
};

struct TrailModeState_0042a790_20260603 {
    char reserved_000[0xa20];
    int river_mode;

    int OtUpdateTrailModeAfterAction_20260603_RealCpp(void* window);

    void OtRecomputeTrailTravelMetricsDependency_20260603();
    void OtComputeTrailProgressRangeDependency_20260603(
        int* progress_start,
        int* progress_end);
    int OtValidateTrailContinueRequestDependency_20260603(void* window);
    int OtResolveActiveTrailOverlayDependency_20260603(void* window);
    void OtRunRiverCrossingDecisionFlowDependency_20260603(void* window);
    void OtResetTrailActionStateDependency_20260603(void* window);
    void OtResumeTrailTravelViewDependency_20260603(
        void* window,
        int continue_state,
        int progress_end);
    void OtRefreshTrailStatusPanelDependency_20260603(void* window);
};

struct TrailProgressView_0042c0b0_Product {
    void OtComputeTrailProgressRange_0042c0b0_Product(
        int* progress_start,
        int* progress_end);
};

struct TrailActiveOverlayState_0042a8a0 {
    int OtResolveActiveTrailOverlay_RealCpp(void* owner_window);
};

struct TrailRiverDecisionState_0042cbc0_ProductWip {
    int OtRunRiverCrossingDecisionFlow_0042cbc0_ProductWip(
        void* owner_window);
};

struct TrailAnimationState_0042d460 {
    int OtResetTrailActionState_RealCpp(void* owner_window);
};

struct TrailResumeState_0042a950_20260603 {
    int OtResumeTrailTravelView_20260603_RealCpp(
        void* owner_window,
        int continue_state,
        int progress_end);
};

struct TrailStatusPanelState_0042d5d0_ProductWip {
    void OtRefreshTrailStatusPanel_0042d5d0_ProductWip(
        void* owner_window);
};
#pragma pack(pop)

extern "C" int g_trailProgressStopPending;
extern "C" int g_cdMediaMode_00439108;
extern "C" unsigned int g_wavePlaybackActive_0040d110;
extern "C" JourneyState_0042a790_20260603* g_journeyState;
extern "C" RouteStop_0042a790_20260603* g_activeRouteDescriptor;

extern "C" void __cdecl OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();
extern "C" void __cdecl OtCloseWaveAudioDevice_0040d0a0_RealCpp();
extern "C" void __fastcall
OtRecomputeTrailTravelMetrics_0042ddc0_RealCpp(int state);
extern "C" int __stdcall
OtValidateTrailContinueRequestAlt3_0042a590_RealCpp(void* owner_window);

#define OTWIN_RIVER_MODE_0042A790 g_trailProgressStopPending
#define OTWIN_RIVER_MODE_RECHECK_0042A790 g_trailProgressStopPending

#pragma optimize("s", off)
#pragma optimize("t", on)

int TrailModeState_0042a790_20260603::
    OtUpdateTrailModeAfterAction_20260603_RealCpp(void* window)
{
    register TrailModeState_0042a790_20260603* state = this;
    int progress_end;
    int progress_start;

    if (OTWIN_RIVER_MODE_0042A790 == 0 || g_wavePlaybackActive_0040d110 == 0) {
audio_gate:
        if (g_cdMediaMode_00439108 == 0) {
            OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();
        }
    } else {
        OtCloseWaveAudioDevice_0040d0a0_RealCpp();
        if (g_cdMediaMode_00439108 == 0) {
            OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();
            goto audio_gate;
        }
    }

    state->OtRecomputeTrailTravelMetricsDependency_20260603();
    state->OtComputeTrailProgressRangeDependency_20260603(
        &progress_start,
        &progress_end);
    register int owner_window = (int)window;
    register int continue_state =
        state->OtValidateTrailContinueRequestDependency_20260603(
            (void*)owner_window);

    if (OTWIN_RIVER_MODE_0042A790 != 0 &&
        (g_journeyState->route_stop_flags_low & 0x10) != 0) {
        state->OtResetTrailActionStateDependency_20260603(
            (void*)owner_window);
    } else if (OTWIN_RIVER_MODE_RECHECK_0042A790 != 0 &&
               g_activeRouteDescriptor->stop_kind == 1 &&
               *(short*)&g_journeyState->route_stop_flags_low == 0) {
        state->OtRunRiverCrossingDecisionFlowDependency_20260603(
            (void*)owner_window);
    } else if (OTWIN_RIVER_MODE_RECHECK_0042A790 != 0 &&
               state->OtResolveActiveTrailOverlayDependency_20260603(
                   (void*)owner_window) == 100) {
        return 100;
    }

    if (OTWIN_RIVER_MODE_RECHECK_0042A790 == 0 &&
        state->river_mode != 2 && state->river_mode != 1) {
        state->OtResumeTrailTravelViewDependency_20260603(
            (void*)owner_window,
            continue_state,
            progress_end);
    }

    state->OtRefreshTrailStatusPanelDependency_20260603(
        (void*)owner_window);
    return 0;
}

#pragma optimize("", on)

#pragma code_seg(".otsem")

void TrailModeState_0042a790_20260603::
    OtRecomputeTrailTravelMetricsDependency_20260603()
{
    OtRecomputeTrailTravelMetrics_0042ddc0_RealCpp((int)this);
}

void TrailModeState_0042a790_20260603::
    OtComputeTrailProgressRangeDependency_20260603(
        int* progress_start,
        int* progress_end)
{
    reinterpret_cast<TrailProgressView_0042c0b0_Product*>(this)->
        OtComputeTrailProgressRange_0042c0b0_Product(
            progress_start,
            progress_end);
}

int TrailModeState_0042a790_20260603::
    OtValidateTrailContinueRequestDependency_20260603(void* window)
{
    return OtValidateTrailContinueRequestAlt3_0042a590_RealCpp(window);
}

int TrailModeState_0042a790_20260603::
    OtResolveActiveTrailOverlayDependency_20260603(void* window)
{
    return reinterpret_cast<TrailActiveOverlayState_0042a8a0*>(this)->
        OtResolveActiveTrailOverlay_RealCpp(window);
}

void TrailModeState_0042a790_20260603::
    OtRunRiverCrossingDecisionFlowDependency_20260603(void* window)
{
    reinterpret_cast<TrailRiverDecisionState_0042cbc0_ProductWip*>(this)->
        OtRunRiverCrossingDecisionFlow_0042cbc0_ProductWip(window);
}

void TrailModeState_0042a790_20260603::
    OtResetTrailActionStateDependency_20260603(void* window)
{
    reinterpret_cast<TrailAnimationState_0042d460*>(this)->
        OtResetTrailActionState_RealCpp(window);
}

void TrailModeState_0042a790_20260603::
    OtResumeTrailTravelViewDependency_20260603(
        void* window,
        int continue_state,
        int progress_end)
{
    reinterpret_cast<TrailResumeState_0042a950_20260603*>(this)->
        OtResumeTrailTravelView_20260603_RealCpp(
            window,
            continue_state,
            progress_end);
}

void TrailModeState_0042a790_20260603::
    OtRefreshTrailStatusPanelDependency_20260603(void* window)
{
    reinterpret_cast<TrailStatusPanelState_0042d5d0_ProductWip*>(this)->
        OtRefreshTrailStatusPanel_0042d5d0_ProductWip(window);
}

#pragma code_seg()

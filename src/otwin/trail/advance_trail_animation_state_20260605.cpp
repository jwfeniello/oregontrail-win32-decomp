// Product semantic implementation of OtAdvanceTrailAnimationState @ 0x0042d490.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct JourneyState_0002d490_20260605 {
    char reserved_000[0x5a];
    unsigned short route_stop_flags;
};

struct TrailAnimationState_0002d490_20260605 {
    char reserved_000[0x078c];
    void* progress_meter;
    char reserved_790[0x028c];
    int travel_submode;
    int river_crossing_mode;
    char reserved_a24[0x0c];
    unsigned int elapsed_ticks;
    char reserved_a34[0x14];
    unsigned int travelled_distance;
    unsigned int total_distance;
    unsigned int progress_meter_step;
    int overlay_phase;

    void OtComputeTrailProgressRangeDependency_20260605_2d490(
        int* stop_state,
        unsigned int* progress_percent);
    int OtCheckForTrailStopTransitionDependency_20260605_2d490(
        void* owner_window,
        int* stop_state);
    int OtHandleTrailSceneStopDependency_20260605_2d490(void* owner_window);
    int OtAdvanceRiverCrossingStateDependency_20260605_2d490(
        void* owner_window);
    int OtAdvanceTrailOverlayStartPhaseDependency_20260605_2d490(
        void* owner_window);
    int OtAdvanceTrailOverlayCompletionPhaseDependency_20260605_2d490(
        void* owner_window);
    int OtAdvanceTrailFlaggedTransitionPhaseDependency_20260605_2d490(
        void* owner_window);
    void OtRefreshTrailStatusPanelDependency_20260605_2d490(
        void* owner_window);

    void OtAdvanceTrailAnimationStateWip17_20260605_RealCpp(
        void* owner_window);
};

struct TrailProgressMeterDependency_0002d490_20260605 {
    void OtAdvanceTrailProgressMeterDependency_20260605_2d490(
        void* owner_window,
        unsigned int progress_percent);
};

struct TrailProgressView_0042c0b0_Product {
    void OtComputeTrailProgressRange_0042c0b0_Product(
        int* first_mile,
        int* last_mile);
};

struct TrailStopTransitionState_0042a680 {
    int OtCheckForTrailStopTransition_RealCpp(
        void* owner_window,
        int* stop_state);
};

struct TrailSceneStopState_0042a480 {
    int OtHandleTrailSceneStop_RealCpp(void* owner_window);
};

struct TrailOverlayStartState_0042dc20 {
    int OtAdvanceTrailOverlayStartPhase_RealCpp(void* owner_window);
    int OtAdvanceTrailOverlayCompletionPhase_RealCpp(void* owner_window);
    int OtAdvanceRiverCrossingState_RealCpp(void* owner_window);
};

struct TrailFlaggedTransitionState_0002de80 {
    int OtAdvanceTrailFlaggedTransitionPhase_20260602_Candidate(
        void* owner_window);
};

struct TrailUiState_0042b370 {
    void OtRefreshTrailStatusPanel_0042d5d0_ProductWip(
        void* owner_window);
};

struct TrailMapProgressLine_00406370_Product {
    void OtAdvanceTrailMapProgressLine_00406370_Product(
        void* map_window,
        int travel_progress);
};
#pragma pack(pop)

extern "C" int g_trailProgressStopPending;
extern "C" JourneyState_0002d490_20260605* g_journeyState;
extern "C" unsigned short* g_activeRouteDescriptor;

extern "C" void __fastcall OtRecomputeTrailTravelMetrics_0042ddc0_RealCpp(
    int state);
extern "C" int __fastcall OtCanAdvanceTrailAnimation_RealCpp(void* state);

#pragma code_seg(".otsem")

void TrailAnimationState_0002d490_20260605::
    OtComputeTrailProgressRangeDependency_20260605_2d490(
        int* stop_state,
        unsigned int* progress_percent)
{
    reinterpret_cast<TrailProgressView_0042c0b0_Product*>(this)->
        OtComputeTrailProgressRange_0042c0b0_Product(
            stop_state,
            reinterpret_cast<int*>(progress_percent));
}

int TrailAnimationState_0002d490_20260605::
    OtCheckForTrailStopTransitionDependency_20260605_2d490(
        void* owner_window,
        int* stop_state)
{
    return reinterpret_cast<TrailStopTransitionState_0042a680*>(this)->
        OtCheckForTrailStopTransition_RealCpp(owner_window, stop_state);
}

int TrailAnimationState_0002d490_20260605::
    OtHandleTrailSceneStopDependency_20260605_2d490(void* owner_window)
{
    return reinterpret_cast<TrailSceneStopState_0042a480*>(this)->
        OtHandleTrailSceneStop_RealCpp(owner_window);
}

int TrailAnimationState_0002d490_20260605::
    OtAdvanceRiverCrossingStateDependency_20260605_2d490(
        void* owner_window)
{
    return reinterpret_cast<TrailOverlayStartState_0042dc20*>(this)->
        OtAdvanceRiverCrossingState_RealCpp(owner_window);
}

int TrailAnimationState_0002d490_20260605::
    OtAdvanceTrailOverlayStartPhaseDependency_20260605_2d490(
        void* owner_window)
{
    return reinterpret_cast<TrailOverlayStartState_0042dc20*>(this)->
        OtAdvanceTrailOverlayStartPhase_RealCpp(owner_window);
}

int TrailAnimationState_0002d490_20260605::
    OtAdvanceTrailOverlayCompletionPhaseDependency_20260605_2d490(
        void* owner_window)
{
    return reinterpret_cast<TrailOverlayStartState_0042dc20*>(this)->
        OtAdvanceTrailOverlayCompletionPhase_RealCpp(owner_window);
}

int TrailAnimationState_0002d490_20260605::
    OtAdvanceTrailFlaggedTransitionPhaseDependency_20260605_2d490(
        void* owner_window)
{
    return reinterpret_cast<TrailFlaggedTransitionState_0002de80*>(this)->
        OtAdvanceTrailFlaggedTransitionPhase_20260602_Candidate(owner_window);
}

void TrailAnimationState_0002d490_20260605::
    OtRefreshTrailStatusPanelDependency_20260605_2d490(void* owner_window)
{
    reinterpret_cast<TrailUiState_0042b370*>(this)->
        OtRefreshTrailStatusPanel_0042d5d0_ProductWip(owner_window);
}

void TrailProgressMeterDependency_0002d490_20260605::
    OtAdvanceTrailProgressMeterDependency_20260605_2d490(
        void* owner_window,
        unsigned int progress_percent)
{
    reinterpret_cast<TrailMapProgressLine_00406370_Product*>(this)->
        OtAdvanceTrailMapProgressLine_00406370_Product(
            owner_window,
            static_cast<int>(progress_percent));
}

extern "C" void __fastcall OtRecomputeTrailTravelMetricsDependency_20260605_2d490(
    TrailAnimationState_0002d490_20260605* state)
{
    OtRecomputeTrailTravelMetrics_0042ddc0_RealCpp(
        reinterpret_cast<int>(state));
}

extern "C" int __fastcall OtCanAdvanceTrailAnimationDependency_20260605_2d490(
    TrailAnimationState_0002d490_20260605* state)
{
    int can_advance = OtCanAdvanceTrailAnimation_RealCpp(state);
    return can_advance;
}

#pragma code_seg()

#pragma optimize("s", off)
#pragma optimize("t", on)

// Advances the trail timer and dispatches the active stop/overlay state machine.
void TrailAnimationState_0002d490_20260605::
    OtAdvanceTrailAnimationStateWip17_20260605_RealCpp(void* owner_window)
{
    int stop_state;
    unsigned int progress_percent;
    register TrailAnimationState_0002d490_20260605* state = this;
    register void* owner = owner_window;

    OtRecomputeTrailTravelMetricsDependency_20260605_2d490(state);
    state->OtComputeTrailProgressRangeDependency_20260605_2d490(
        &stop_state,
        &progress_percent);

    if (g_trailProgressStopPending == 0 &&
        state->river_crossing_mode != 2 &&
        state->river_crossing_mode != 1 &&
        state->travelled_distance < state->total_distance) {
        state->OtCheckForTrailStopTransitionDependency_20260605_2d490(
            owner,
            &stop_state);
    }

    if (g_trailProgressStopPending == 0 ||
        state->river_crossing_mode == 2 ||
        state->river_crossing_mode == 1 ||
        g_journeyState->route_stop_flags != 0 ||
        state->total_distance <= state->travelled_distance) {
        if (state->river_crossing_mode == 2) {
            state->OtAdvanceRiverCrossingStateDependency_20260605_2d490(owner);
        } else {
            register unsigned short route_flags =
                g_journeyState->route_stop_flags;
            if (((unsigned char)route_flags & 0x10) == 0 &&
                ((unsigned char)route_flags & 0x20) == 0) {
                if (state->overlay_phase < 2) {
                    state->OtAdvanceTrailOverlayStartPhaseDependency_20260605_2d490(
                        owner);
                } else {
                    state->OtAdvanceTrailOverlayCompletionPhaseDependency_20260605_2d490(
                        owner);
                }
            } else {
                state->OtAdvanceTrailFlaggedTransitionPhaseDependency_20260605_2d490(
                    owner);
            }
        }
    } else if (*g_activeRouteDescriptor != 0x11) {
        state->OtHandleTrailSceneStopDependency_20260605_2d490(owner);
    }

    if (OtCanAdvanceTrailAnimationDependency_20260605_2d490(state) != 0) {
        unsigned int travelled = state->travelled_distance + 1;
        state->travelled_distance = travelled;
        if (state->total_distance <= travelled) {
            state->OtRefreshTrailStatusPanelDependency_20260605_2d490(owner);
        }
    }

    ++state->elapsed_ticks;

    if (OtCanAdvanceTrailAnimationDependency_20260605_2d490(state) != 0 &&
        state->progress_meter_step > 0) {
        static_cast<TrailProgressMeterDependency_0002d490_20260605*>(
            state->progress_meter)
            ->OtAdvanceTrailProgressMeterDependency_20260605_2d490(
                owner,
                progress_percent);
    }
}

#pragma optimize("", on)

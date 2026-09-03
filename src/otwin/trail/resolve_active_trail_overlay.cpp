// Product-tree semantic closure for OtResolveActiveTrailOverlay @ 0x0042a8a0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct RouteDescriptor_0042a8a0 {
    char reserved_000[0x12];
    short primary_successor;
    char reserved_014[2];
    short alternate_successor;
    char reserved_018[0x10a];
    unsigned short route_strip_state;
};

struct JourneyState_0042a8a0 {
    char reserved_000[0x5a];
    unsigned char route_stop_flags;
};

struct TrailBranchVariant_0042a8a0 {
    void OtSelectTrailBranchVariantDependency_0042a8a0();
};

struct TrailMapComposite_00406290 {
    void OtSelectTrailMapPolylineVariantNoAsm2_00406290_RealCpp();
};

struct TrailRouteSceneStrip_0042a8a0 {
    void OtUpdateTrailRouteSceneStripStateDependency_0042a8a0(
        void* resource_module,
        unsigned int route_strip_state);
};

struct TrailTravelViewport_00406f70 {
    void OtUpdateTrailViewportRouteStripStateAlt32_00406f70_RealCpp(
        void* resource_module,
        int route_strip_state);
};

struct JourneyState_004198e0 {
    void OtAdvanceToNextRouteSegment_RealCpp(short branch_choice);
};

struct TrailActiveOverlayState_0042a8a0 {
    char reserved_000[0x078c];
    TrailBranchVariant_0042a8a0* branch_variant;
    char reserved_790[0x0280];
    TrailRouteSceneStrip_0042a8a0* route_scene_strip;

    int OtResolveActiveTrailOverlay_RealCpp(void* owner_window);
    int OtResolveActiveTrailOverlayAlt2_RealCpp(void* owner_window);
    int OtResolveActiveTrailOverlayAlt3_RealCpp(void* owner_window);
};
#pragma pack(pop)

extern "C" RouteDescriptor_0042a8a0* g_activeRouteDescriptor;
extern "C" JourneyState_0042a8a0* g_journeyState;
extern "C" int g_trailProgressStopPending;
extern "C" void* g_resourceModule;

extern "C" __declspec(dllimport) void* __stdcall GetParent(void* window);
extern "C" __declspec(dllimport) int __stdcall PostMessageA(
    void* window,
    unsigned int message,
    unsigned int wparam,
    long lparam);

extern "C" int __stdcall OtRunTrailDivideChoiceDialog_RealCpp(
    void* owner_window);

extern "C" void __stdcall OtAdvanceToNextRouteSegmentDependency_0042a8a0(
    int);

#pragma optimize("s", off)
#pragma optimize("t", on)

// Resolves a pending trail divide, posts the river handoff sentinel, or
// advances the normal trail route and refreshes route-strip state.
int TrailActiveOverlayState_0042a8a0::OtResolveActiveTrailOverlay_RealCpp(
    void* owner_window)
{
    register TrailActiveOverlayState_0042a8a0* state = this;
    register void* window;
    int choice;
    unsigned int strip_state;

    if (g_activeRouteDescriptor->alternate_successor > 0) {
        window = owner_window;
        choice = OtRunTrailDivideChoiceDialog_RealCpp(window);
    } else {
        choice = 0;
        window = owner_window;
    }

    if ((short)choice == 0) {
        if (g_activeRouteDescriptor->primary_successor == 0x12) {
            goto post_handoff;
        }
    } else {
        if (g_activeRouteDescriptor->alternate_successor == 0x12) {
            goto post_handoff;
        }
    }

    goto normal_route;

post_handoff:
    PostMessageA(
        GetParent(window),
        0x475,
        0,
        0);
    return 100;

normal_route:
    if ((g_journeyState->route_stop_flags & 0x10) == 0) {
        OtAdvanceToNextRouteSegmentDependency_0042a8a0(choice);
        g_trailProgressStopPending = 0;
        state->branch_variant->OtSelectTrailBranchVariantDependency_0042a8a0();
        strip_state = g_activeRouteDescriptor->route_strip_state;
        state->route_scene_strip->OtUpdateTrailRouteSceneStripStateDependency_0042a8a0(
            g_resourceModule,
            strip_state);
    }

    return 0;
}

int TrailActiveOverlayState_0042a8a0::OtResolveActiveTrailOverlayAlt2_RealCpp(
    void* owner_window)
{
    int choice;

    if (g_activeRouteDescriptor->alternate_successor < 1) {
        choice = 0;
    } else {
        choice = OtRunTrailDivideChoiceDialog_RealCpp(owner_window);
    }

    if ((short)choice == 0) {
        if (g_activeRouteDescriptor->primary_successor == 0x12) {
            PostMessageA(
                GetParent(owner_window),
                0x475,
                0,
                0);
            return 100;
        }
    } else if (g_activeRouteDescriptor->alternate_successor == 0x12) {
        PostMessageA(
            GetParent(owner_window),
            0x475,
            0,
            0);
        return 100;
    }

    if ((g_journeyState->route_stop_flags & 0x10) == 0) {
        OtAdvanceToNextRouteSegmentDependency_0042a8a0(choice);
        g_trailProgressStopPending = 0;
        branch_variant->OtSelectTrailBranchVariantDependency_0042a8a0();
        route_scene_strip->OtUpdateTrailRouteSceneStripStateDependency_0042a8a0(
            g_resourceModule,
            g_activeRouteDescriptor->route_strip_state);
    }

    return 0;
}

int TrailActiveOverlayState_0042a8a0::OtResolveActiveTrailOverlayAlt3_RealCpp(
    void* owner_window)
{
    int choice;
    short successor;

    if (g_activeRouteDescriptor->alternate_successor <= 0) {
        choice = 0;
    } else {
        choice = OtRunTrailDivideChoiceDialog_RealCpp(owner_window);
    }

    if ((short)choice == 0) {
        successor = g_activeRouteDescriptor->primary_successor;
    } else {
        successor = g_activeRouteDescriptor->alternate_successor;
    }

    if (successor == 0x12) {
        PostMessageA(
            GetParent(owner_window),
            0x475,
            0,
            0);
        return 100;
    }

    if ((g_journeyState->route_stop_flags & 0x10) == 0) {
        OtAdvanceToNextRouteSegmentDependency_0042a8a0(choice);
        g_trailProgressStopPending = 0;
        branch_variant->OtSelectTrailBranchVariantDependency_0042a8a0();
        route_scene_strip->OtUpdateTrailRouteSceneStripStateDependency_0042a8a0(
            g_resourceModule,
            g_activeRouteDescriptor->route_strip_state);
    }

    return 0;
}

#pragma code_seg(".otsem")
extern "C" void __stdcall OtAdvanceToNextRouteSegmentDependency_0042a8a0(
    int branch_choice)
{
    reinterpret_cast<JourneyState_004198e0*>(g_journeyState)->
        OtAdvanceToNextRouteSegment_RealCpp(
            static_cast<short>(branch_choice));
}

void TrailBranchVariant_0042a8a0::OtSelectTrailBranchVariantDependency_0042a8a0()
{
    reinterpret_cast<TrailMapComposite_00406290*>(this)->
        OtSelectTrailMapPolylineVariantNoAsm2_00406290_RealCpp();
}

void TrailRouteSceneStrip_0042a8a0::OtUpdateTrailRouteSceneStripStateDependency_0042a8a0(
    void* resource_module,
    unsigned int route_strip_state)
{
    reinterpret_cast<TrailTravelViewport_00406f70*>(this)->
        OtUpdateTrailViewportRouteStripStateAlt32_00406f70_RealCpp(
            resource_module,
            static_cast<int>(route_strip_state));
}
#pragma code_seg()

#pragma optimize("", on)

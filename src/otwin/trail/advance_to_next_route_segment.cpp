// Semantic candidate for OtAdvanceToNextRouteSegment.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct RouteDescriptor_004198e0 {
    char reserved_000[0x12];
    short primary_successor;
    short primary_distance;
    short alternate_successor;
    short alternate_distance;

    void OtLoadRouteDescriptorDependency_004198e0(short route_id);
};

struct GraveSiteRuntime_004198e0 {
    void OtRefreshGraveSiteTrackerDependency_004198e0();
};

struct JourneyState_004198e0 {
    char reserved_000[0x58];
    short random_route_marker;
    char reserved_05a[4];
    short completed_route_count;
    short completed_route_ids[0x15];
    short segment_distance;
    char reserved_08c[2];
    short current_route_id;

    void OtAdvanceToNextRouteSegment_RealCpp(short branch_choice);
};
#pragma pack(pop)

extern "C" RouteDescriptor_004198e0* g_activeRouteDescriptor;
extern "C" GraveSiteRuntime_004198e0* g_graveSiteRuntime;

extern "C" short __cdecl OtRandomBelowDependency_004198e0(int maximum);
extern "C" int __cdecl OtRandomBelow_RealCpp(int maximum);
extern "C" void __stdcall OtLoadRouteDescriptor_RealCpp(short route_id);
extern "C" void __fastcall OtRefreshGraveEpitaphIniCache_00411fd0_RealCpp(
    void* state);

#pragma optimize("s", off)
#pragma optimize("t", on)

// Advances from an exhausted route segment to the selected successor route.
void JourneyState_004198e0::OtAdvanceToNextRouteSegment_RealCpp(short branch_choice)
{
    register JourneyState_004198e0* journey = this;

    if (journey->segment_distance == 0) {
        journey->random_route_marker = OtRandomBelowDependency_004198e0(3);
        journey->completed_route_ids[journey->completed_route_count] =
            journey->current_route_id;
        ++journey->completed_route_count;

        if (branch_choice == 0) {
            journey->current_route_id = g_activeRouteDescriptor->primary_successor;
        } else {
            journey->current_route_id = g_activeRouteDescriptor->alternate_successor;
        }

        if (branch_choice == 0) {
            journey->segment_distance = g_activeRouteDescriptor->primary_distance;
        } else {
            journey->segment_distance = g_activeRouteDescriptor->alternate_distance;
        }

        g_activeRouteDescriptor->OtLoadRouteDescriptorDependency_004198e0(
            journey->current_route_id);
        g_graveSiteRuntime->OtRefreshGraveSiteTrackerDependency_004198e0();
    }
}

#pragma code_seg(".otsem")
extern "C" short __cdecl OtRandomBelowDependency_004198e0(int maximum)
{
    int random_value = OtRandomBelow_RealCpp(maximum);
    return static_cast<short>(random_value);
}

void RouteDescriptor_004198e0::OtLoadRouteDescriptorDependency_004198e0(
    short route_id)
{
    OtLoadRouteDescriptor_RealCpp(route_id);
}

void GraveSiteRuntime_004198e0::OtRefreshGraveSiteTrackerDependency_004198e0()
{
    OtRefreshGraveEpitaphIniCache_00411fd0_RealCpp(this);
}
#pragma code_seg()

#pragma optimize("", on)

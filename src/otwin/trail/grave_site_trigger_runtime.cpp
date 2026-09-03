// Canonical Product implementation of OtShouldTriggerGraveSiteEvent @ 0x00412220.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

extern "C" int __cdecl OtAreGraveSitesEnabled_00411ef0_RealCpp();

#pragma pack(push, 1)
struct GraveSiteMarker_00412220_Product {
    char reserved_00[2];
    short route_segment_id;
    short landmark_id;
    short mile_marker;
    char reserved_08[0x3c];
    int already_reported;
};

struct JourneyGraveSiteState_00412220_Product {
    char reserved_00[0x5e];
    short current_route_segment_index;
    short route_segment_ids[20];
    short previous_mile_marker;
    short current_mile_marker;
    char reserved_8c[2];
    short landmark_id;
};
#pragma pack(pop)

extern "C" JourneyGraveSiteState_00412220_Product* g_journeyState;

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" int __fastcall OtShouldTriggerGraveSiteEvent_00412220_Product(
    GraveSiteMarker_00412220_Product* marker)
{
    if (OtAreGraveSitesEnabled_00411ef0_RealCpp() == 0 ||
        marker->already_reported == 1) {
        return 0;
    }

    register short route_segment_id = 0;
    short route_segment_index;

    if ((route_segment_index = g_journeyState->current_route_segment_index) !=
        route_segment_id) {
        route_segment_id =
            g_journeyState->route_segment_ids[route_segment_index - 1];
    }

    if (marker->route_segment_id == route_segment_id &&
        marker->landmark_id == g_journeyState->landmark_id &&
        marker->mile_marker <= g_journeyState->current_mile_marker &&
        g_journeyState->current_mile_marker -
                g_journeyState->previous_mile_marker <
            marker->mile_marker) {
        return 1;
    }

    return 0;
}

#pragma optimize("", on)
#pragma code_seg()

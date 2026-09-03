// Semantic recovery for OtSelectTrailMapPolylineVariant @ 0x00406290.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct TrailMapPoint_00406290 {
    short x;
    short y;
};

struct TrailMapRouteWindow_00406290 {
    int words[10];
};

struct TrailMapComposite_00406290 {
    void* base_bitmap;
    int reserved_04[3];
    int selected_polyline_variant;
    int last_progress_segment;
    void* polyline_handles[4];
    const TrailMapPoint_00406290* active_points;
    const TrailMapPoint_00406290* aux_points[4];

    void OtSelectTrailMapPolylineVariant_00406290_RealCpp();
    void OtSelectTrailMapPolylineVariantNoAsm_00406290_RealCpp();
    void OtSelectTrailMapPolylineVariantNoAsm2_00406290_RealCpp();
};

struct TrailJourneyPathState_00406290 {
    char reserved_00[0x5e];
    short route_history_count;
    short route_history[13];
    char reserved_7a[0x14];
    short current_route;
};
#pragma pack(pop)

extern "C" TrailJourneyPathState_00406290* g_journeyState;
#define g_trailJourneyPathState_00406290 g_journeyState

#pragma optimize("s", off)
#pragma optimize("t", on)

void TrailMapComposite_00406290::
OtSelectTrailMapPolylineVariant_00406290_RealCpp()
{
    register TrailMapComposite_00406290* map = this;
    register int has_not_seen_fort_bridger = 1;
    register int has_not_seen_walla_walla = has_not_seen_fort_bridger;
    TrailMapRouteWindow_00406290 copied_window;

    TrailJourneyPathState_00406290* journey =
        g_trailJourneyPathState_00406290;
    copied_window =
        *reinterpret_cast<TrailMapRouteWindow_00406290*>(
            journey->route_history);

    {
        short route_count = g_trailJourneyPathState_00406290->route_history_count;
        if (route_count > 0 && route_count > 7) {
            short* history = reinterpret_cast<short*>(copied_window.words) + 7;
            int count = route_count - 7;
            do {
                short route = *history;
                if (route == 8) {
                    has_not_seen_fort_bridger = 0;
                } else if (route == 0x0f) {
                    has_not_seen_walla_walla = 0;
                }
                ++history;
                --count;
            } while (count != 0);
        }
    }

    {
        short current_route = g_trailJourneyPathState_00406290->current_route;
        if (current_route == 8) {
            has_not_seen_fort_bridger = 0;
        } else if (current_route == 0x0f) {
            has_not_seen_walla_walla = 0;
        }
    }

    if (has_not_seen_fort_bridger) {
        if (has_not_seen_walla_walla) {
            map->active_points = map->aux_points[3];
            map->selected_polyline_variant = 4;
            return;
        }
        map->active_points = map->aux_points[1];
        map->selected_polyline_variant = 2;
        return;
    }
    if (has_not_seen_walla_walla) {
        map->active_points = map->aux_points[2];
        map->selected_polyline_variant = 3;
        return;
    }
    map->active_points = map->aux_points[0];
    map->selected_polyline_variant = 1;
}

void TrailMapComposite_00406290::
OtSelectTrailMapPolylineVariantNoAsm_00406290_RealCpp()
{
    register TrailMapComposite_00406290* map = this;
    register int has_not_seen_fort_bridger = 1;
    TrailMapRouteWindow_00406290 copied_window;

    TrailJourneyPathState_00406290* journey =
        g_trailJourneyPathState_00406290;
    copied_window =
        *reinterpret_cast<TrailMapRouteWindow_00406290*>(
            journey->route_history);

    register int has_not_seen_walla_walla = has_not_seen_fort_bridger;

    {
        short route_count = g_trailJourneyPathState_00406290->route_history_count;
        if (route_count > 0 && route_count > 7) {
            short* history = reinterpret_cast<short*>(copied_window.words) + 7;
            int count = route_count - 7;
            do {
                short route = *history;
                if (route == 8) {
                    has_not_seen_fort_bridger = 0;
                } else if (route == 0x0f) {
                    has_not_seen_walla_walla = 0;
                }
                ++history;
                --count;
            } while (count != 0);
        }
    }

    {
        short current_route = g_trailJourneyPathState_00406290->current_route;
        if (current_route == 8) {
            has_not_seen_fort_bridger = 0;
        } else if (current_route == 0x0f) {
            has_not_seen_walla_walla = 0;
        }
    }

    if (has_not_seen_fort_bridger) {
        if (has_not_seen_walla_walla) {
            map->active_points = map->aux_points[3];
            map->selected_polyline_variant = 4;
            return;
        }
        map->active_points = map->aux_points[1];
        map->selected_polyline_variant = 2;
        return;
    }
    if (has_not_seen_walla_walla) {
        map->active_points = map->aux_points[2];
        map->selected_polyline_variant = 3;
        return;
    }
    map->active_points = map->aux_points[0];
    map->selected_polyline_variant = 1;
}

void TrailMapComposite_00406290::
OtSelectTrailMapPolylineVariantNoAsm2_00406290_RealCpp()
{
    register TrailMapComposite_00406290* map = this;
    register int has_not_seen_fort_bridger = 1;
    register int has_not_seen_walla_walla = has_not_seen_fort_bridger;
    TrailMapRouteWindow_00406290 copied_window;

    TrailJourneyPathState_00406290* journey =
        g_trailJourneyPathState_00406290;
    copied_window =
        *reinterpret_cast<TrailMapRouteWindow_00406290*>(
            journey->route_history);

    {
        short route_count = g_trailJourneyPathState_00406290->route_history_count;
        if (route_count > 0 && route_count > 7) {
            short* history = reinterpret_cast<short*>(copied_window.words) + 7;
            int count = route_count - 7;
            do {
                short route = *history;
                if (route == 8) {
                    has_not_seen_fort_bridger = 0;
                } else if (route == 0x0f) {
                    has_not_seen_walla_walla = 0;
                }
                ++history;
                --count;
            } while (count != 0);
        }
    }

    {
        short current_route = g_trailJourneyPathState_00406290->current_route;
        if (current_route == 8) {
            has_not_seen_fort_bridger = 0;
        } else if (current_route == 0x0f) {
            has_not_seen_walla_walla = 0;
        }
    }

    if (has_not_seen_fort_bridger) {
        if (has_not_seen_walla_walla) {
            map->active_points = map->aux_points[3];
            map->selected_polyline_variant = 4;
            return;
        }
        map->active_points = map->aux_points[1];
        map->selected_polyline_variant = 2;
        return;
    }
    if (has_not_seen_walla_walla) {
        map->active_points = map->aux_points[2];
        map->selected_polyline_variant = 3;
        return;
    }
    map->active_points = map->aux_points[0];
    map->selected_polyline_variant = 1;
}

#pragma optimize("", on)

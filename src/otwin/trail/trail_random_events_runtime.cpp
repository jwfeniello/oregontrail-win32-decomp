// Product semantic WIP for OtRollTrailRandomEvents @ 0x00418d50.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

extern "C" int __cdecl OtRandomBelow_RealCpp(int upper_bound);
extern "C" void __cdecl OtTriggerTrailEventById_RealCpp(short event_id);
extern "C" void __cdecl OtTriggerRandomBrokenWagonPartEvent_RealCpp();

#pragma pack(push, 1)
struct JourneyRandomEventState_00418d50_ProductWip {
    char reserved_000[0x50];
    short weather_code;
    short weather_severity;
    short storm_distance_penalty;
    short river_route_state;
    char reserved_058[0x02];
    short route_stop_flags;
    char reserved_05c[0x2c];
    short daily_miles_available;
    short miles_remaining_in_step;
    char reserved_08c[0x02];
    short terrain_type;
    char reserved_090[0x02];
    short pace;
    short delay_days;
    short oxen_count;
    short oxen_sick;
    short clothing;
    short bullets;
    short wagon_wheels;
    short wagon_axles;
    short wagon_tongues;
    short food_from_plants;
    short food_from_hunting;
    char reserved_0a8[0x16];
    short party_condition_score;
    char reserved_0c0[0x7a];
    short hunt_region;
};

struct RouteStop_00418d50_ProductWip {
    short route_id;
    short route_kind;
};

struct TrailSupplyCounterSlot_00418d50_ProductWip {
    char reserved_00[8];
    short count;
};
#pragma pack(pop)

extern "C" JourneyRandomEventState_00418d50_ProductWip* g_journeyState;
extern "C" RouteStop_00418d50_ProductWip* g_activeRouteDescriptor;
extern "C" int __fastcall OtComputePartyHealthScore_RealCpp(
    JourneyRandomEventState_00418d50_ProductWip* journey);
extern "C" void* OtTrailEventObjectPointers_00418c50[34];

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" void __cdecl OtRollTrailRandomEvents_00418d50_ProductWip()
{
    int blocked_by_active_stop;
    int has_weather_blocker;
    int wagon_event_already_queued = 0;
    int terrain_is_desert = g_journeyState->terrain_type > 11;
    int weather_code;
    int weather_severity;
    int party_health_score;
    int wagon_chance;

    if (g_journeyState->river_route_state > 3000) {
        OtTriggerTrailEventById_RealCpp(0x1d);
    }

    if (g_journeyState->weather_severity >= 3) {
        if (OtRandomBelow_RealCpp(1000) < 7) {
            OtTriggerTrailEventById_RealCpp(0x1c);
        }
        if (OtRandomBelow_RealCpp(1000) < 100) {
            OtTriggerTrailEventById_RealCpp(0x1e);
        }
    }

    if ((short)(g_journeyState->food_from_plants +
                g_journeyState->food_from_hunting) == 0 &&
        OtRandomBelow_RealCpp(1000) < 50) {
        OtTriggerTrailEventById_RealCpp(0x16);
    }

    if (g_journeyState->miles_remaining_in_step > 0 ||
        g_activeRouteDescriptor->route_kind != 2) {
        int hunt_region = g_journeyState->hunt_region;
        if (hunt_region >= 4 && hunt_region <= 8 &&
            OtRandomBelow_RealCpp(1000) < 40) {
            OtTriggerTrailEventById_RealCpp(8);
        }
    }

    if (g_journeyState->delay_days > 0 ||
        g_journeyState->route_stop_flags != 0) {
        blocked_by_active_stop = 1;
    } else {
        blocked_by_active_stop = 0;
    }

    weather_code = g_journeyState->weather_code;
    weather_severity = g_journeyState->weather_severity;
    if (weather_code == 4 || weather_code == 5 || weather_code == 6 ||
        weather_code == 7 || weather_code == 8 || weather_code == 9 ||
        weather_severity == 1 || weather_severity == 0) {
        if (OtRandomBelow_RealCpp(1000) < 150 && !blocked_by_active_stop) {
            if (g_journeyState->storm_distance_penalty < 5 &&
                g_journeyState->river_route_state == 0 &&
                g_journeyState->terrain_type > 3 &&
                g_journeyState->terrain_type <= 12) {
                OtTriggerTrailEventById_RealCpp(6);
            } else {
                if (weather_severity == 0 || weather_severity == 1) {
                    OtTriggerTrailEventById_RealCpp(5);
                }
                if (weather_severity == 5 || weather_severity == 4) {
                    OtTriggerTrailEventById_RealCpp(0x0b);
                }
            }
        }
    }

    if (reinterpret_cast<TrailSupplyCounterSlot_00418d50_ProductWip*>(
            OtTrailEventObjectPointers_00418c50[5])->count != 0 ||
        reinterpret_cast<TrailSupplyCounterSlot_00418d50_ProductWip*>(
            OtTrailEventObjectPointers_00418c50[4])->count != 0 ||
        reinterpret_cast<TrailSupplyCounterSlot_00418d50_ProductWip*>(
            OtTrailEventObjectPointers_00418c50[10])->count != 0) {
        has_weather_blocker = 1;
    } else {
        has_weather_blocker = 0;
    }

    if (!has_weather_blocker && !blocked_by_active_stop &&
        OtRandomBelow_RealCpp(1000) < 60) {
        if (weather_severity < 5 && !terrain_is_desert) {
            OtTriggerTrailEventById_RealCpp(7);
        }
        if (weather_severity == 5 && terrain_is_desert) {
            OtTriggerTrailEventById_RealCpp(0x14);
        }
    }

    if (OtRandomBelow_RealCpp(1000) < 20) {
        if (OtRandomBelow_RealCpp(1000) < 500) {
            OtTriggerTrailEventById_RealCpp(0x19);
        } else {
            OtTriggerTrailEventById_RealCpp(0x1f);
        }
    }

    if (terrain_is_desert && OtRandomBelow_RealCpp(1000) < 50) {
        if (OtRandomBelow_RealCpp(1000) < 500) {
            OtTriggerTrailEventById_RealCpp(0x1b);
        } else {
            OtTriggerTrailEventById_RealCpp(0x15);
        }
    }

    terrain_is_desert = terrain_is_desert ? 70 : 40;
    if (OtRandomBelow_RealCpp(1000) < (short)terrain_is_desert) {
        switch (OtRandomBelow_RealCpp(3)) {
        case 0:
            if (OtRandomBelow_RealCpp(1000) < 500) {
                OtTriggerTrailEventById_RealCpp(0x0f);
            } else {
                OtTriggerTrailEventById_RealCpp(0x10);
            }
            break;
        case 1:
            OtTriggerTrailEventById_RealCpp(0x0a);
            break;
        case 2:
            wagon_event_already_queued = 1;
            OtTriggerRandomBrokenWagonPartEvent_RealCpp();
            break;
        }
    }

    party_health_score =
        (short)OtComputePartyHealthScore_RealCpp(g_journeyState);
    if (party_health_score > 2750) {
        wagon_chance =
            (((int)party_health_score * 4 - 11000) * 125) / 1580;
        if (wagon_chance > 500) {
            wagon_chance = 500;
        }

        if (!wagon_event_already_queued &&
            OtRandomBelow_RealCpp(1000) < (short)wagon_chance) {
            OtTriggerRandomBrokenWagonPartEvent_RealCpp();
        }
        if (reinterpret_cast<TrailSupplyCounterSlot_00418d50_ProductWip*>(
                OtTrailEventObjectPointers_00418c50[9])->count == 0 &&
            OtRandomBelow_RealCpp(1000) < (short)wagon_chance) {
            OtTriggerTrailEventById_RealCpp(0x0a);
        }
    }

    if (OtRandomBelow_RealCpp(1000) < 10) {
        switch (OtRandomBelow_RealCpp(3)) {
        case 0:
            OtTriggerTrailEventById_RealCpp(0x18);
            break;
        case 1:
            OtTriggerTrailEventById_RealCpp(0x17);
            break;
        case 2:
            OtTriggerTrailEventById_RealCpp(0x20);
            break;
        }
    }

    if (OtRandomBelow_RealCpp(1000) < 10) {
        if (OtRandomBelow_RealCpp(1000) < 500) {
            OtTriggerTrailEventById_RealCpp(0x0d);
        } else {
            OtTriggerTrailEventById_RealCpp(0x21);
        }
    }

    if (g_journeyState->storm_distance_penalty <= 10 &&
        OtRandomBelow_RealCpp(1000) < 500) {
        if (OtRandomBelow_RealCpp(1000) < 400) {
            OtTriggerTrailEventById_RealCpp(0x1a);
        } else if (OtRandomBelow_RealCpp(1000) < 400) {
            OtTriggerTrailEventById_RealCpp(9);
        } else {
            OtTriggerTrailEventById_RealCpp(0x0e);
        }
    }

    if (g_journeyState->miles_remaining_in_step > 0 ||
        g_activeRouteDescriptor->route_kind != 2) {
        if ((short)(g_journeyState->party_condition_score / 15) + 1 >
            OtRandomBelow_RealCpp(60)) {
            OtTriggerTrailEventById_RealCpp(0x22);
        }
    }
}

#pragma optimize("", on)
#pragma code_seg()

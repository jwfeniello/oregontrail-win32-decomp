// Product semantic implementations for daily weather, food, and health state.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

extern "C" int __cdecl OtRandomBelow_RealCpp(int upper_bound);
extern "C" short __fastcall OtCountLivingPartyMembers_RealCpp(
    const void* party);
extern "C" void __cdecl OtQueuePartyRecoveryEventForMember_RealCpp(
    short member_index);
extern "C" void __cdecl OtTriggerTrailEventById_RealCpp(short event_id);

#pragma pack(push, 1)
struct JourneyDailyState_004199a0_ProductWip {
    char reserved_000[0x50];
    short weather_code;
    short weather_severity;
    short storm_distance_penalty;
    short river_route_state;
    char reserved_058[0x02];
    unsigned short route_stop_flags;
    char reserved_05c[0x34];
    short ration_level;
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
    int cash_cents;
    short river_crossing_type;
    char reserved_0ae[0x10];
    short party_condition_score;
    char reserved_0c0[0x4c];
    short recovery_days[5];
    short member_state[5];
    short health_pressure;
    short pending_health_penalty;
    char reserved_124[0x16];
    short hunt_region;
};

struct RouteStopWeatherState_004199a0_ProductWip {
    char reserved_00[6];
    short season;
};

struct WeatherEffects_004199a0_Product {
    short storm_distance;
    short river_penalty;

    WeatherEffects_004199a0_Product()
        : storm_distance(0), river_penalty(0)
    {
    }
};

#pragma pack(pop)

// Runtime ownership is one pointer-sized slot.  Modeling that slot as a
// table object keeps its storage ABI while giving both weather lookups the
// same semantic indexed-access operation.
struct TrailWeatherTableStorage_004199a0_Product {
    short* entries;

    __inline short operator[](int index) const
    {
        return entries[index];
    }
};

extern "C" RouteStopWeatherState_004199a0_ProductWip*
    g_activeRouteDescriptor;

// This is canonical runtime storage for the weather-table pointer. The table
// is populated by journey/resource initialization; it is not an import hook.
#pragma data_seg(".otdat")
extern "C" __declspec(allocate(".otdat"))
TrailWeatherTableStorage_004199a0_Product
    g_trailWeatherTable_004199a0 = { 0 };
#pragma data_seg()

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

#pragma optimize("w", on)
extern "C" void __fastcall OtAdvanceWeatherState_004199a0_ProductWip(
    JourneyDailyState_004199a0_ProductWip* journey)
{
    WeatherEffects_004199a0_Product effects;
    short season = g_activeRouteDescriptor->season;
    short reroll_weather = (short)OtRandomBelow_RealCpp(2);
    int weather = journey->weather_code;

    if (weather >= 7 && (weather <= 9 || weather == 11)) {
        reroll_weather = 1;
    }
    if (reroll_weather != 0) {
        journey->weather_code = (short)OtRandomBelow_RealCpp(3);
    }

    int season_offset = (int)season * 12;
    int region_index = journey->hunt_region + season_offset;
    short base_severity = g_trailWeatherTable_004199a0[region_index];
    base_severity =
        (short)(base_severity + OtRandomBelow_RealCpp(40));
    journey->weather_severity = (short)(base_severity / 20);
    int storm_today =
        g_trailWeatherTable_004199a0[
            0x48 + journey->hunt_region + season_offset] >
        OtRandomBelow_RealCpp(1000);

    if (storm_today != 0) {
        if (base_severity <= 1) {
            journey->weather_code = 5;
            if (OtRandomBelow_RealCpp(100) < 30) {
                journey->weather_code = 6;
            }
        } else {
            journey->weather_code = 3;
            if (OtRandomBelow_RealCpp(100) < 30) {
                journey->weather_code = 4;
            }
        }

        switch (journey->weather_code) {
        case 3:
            effects.storm_distance = 20;
            break;
        case 4:
            effects.storm_distance = 80;
            break;
        case 5:
            effects.river_penalty = 160;
            break;
        case 6:
            effects.river_penalty = 640;
            break;
        }
    }

    effects.storm_distance =
        (short)(effects.storm_distance +
                ((int)journey->storm_distance_penalty * 9) / 10);
    journey->storm_distance_penalty = effects.storm_distance;

    {
        int river_decay = ((int)journey->river_route_state * 97) / 100;
        short river_accum = effects.river_penalty;
        river_accum = (short)(river_accum + river_decay);
        journey->river_route_state = river_accum;

        if (journey->weather_severity > 2 || journey->weather_code == 4) {
            short transfer = 500;
            if (river_accum < 500) {
                transfer = river_accum;
            }
            journey->river_route_state = (short)(river_accum - transfer);
            journey->storm_distance_penalty =
                (short)(effects.storm_distance + transfer / 10);
        }
    }
}
#pragma optimize("w", off)

extern "C" void __fastcall OtConsumeDailyFood_00419b50_Product(
    JourneyDailyState_004199a0_ProductWip* journey)
{
    short food_used = (short)(
        OtCountLivingPartyMembers_RealCpp(journey) *
        (3 - journey->ration_level));

    if (food_used >= 10 && journey->food_from_plants > 0) {
        journey->food_from_plants =
            (short)(journey->food_from_plants - 1);
        journey->food_from_hunting =
            (short)(journey->food_from_hunting + (1 - food_used));
    } else {
        journey->food_from_hunting =
            (short)(journey->food_from_hunting - food_used);
    }

    if (journey->food_from_hunting < 0) {
        journey->food_from_plants = (short)(
            journey->food_from_plants + journey->food_from_hunting);
        journey->food_from_hunting = 0;

        if (journey->food_from_plants < 0) {
            journey->food_from_plants = 0;
        }
    }
}

extern "C" void __fastcall OtAdvancePartyHealthState_00419d40_ProductWip(
    JourneyDailyState_004199a0_ProductWip* journey)
{
    register short member_index;
    register short sick_count;
    short pace_pressure;
    short weather_pressure;
    short food_pressure;
    short food_total;
    short ration_pressure;
    short weather;
    short condition;

    sick_count = 0;
    pace_pressure = sick_count;
    weather_pressure = sick_count;
    food_pressure = sick_count;
    member_index = 0;

    do {
        if (journey->member_state[member_index] != 0 &&
            journey->member_state[member_index] != 0x0f) {
            ++sick_count;
            --journey->recovery_days[member_index];
            if (journey->recovery_days[member_index] <= 0) {
                journey->recovery_days[member_index] = 0;
                OtQueuePartyRecoveryEventForMember_RealCpp(member_index);
                journey->member_state[member_index] = 0;
            }
        }
        ++member_index;
    } while (member_index < 5);

    if (journey->delay_days == 0 && journey->route_stop_flags == 0) {
        pace_pressure = (short)(journey->pace * 2 + 2);
        weather = journey->weather_code;
        if (weather >= 3 && weather <= 9) {
            ++pace_pressure;
            if (weather >= 5) {
                ++pace_pressure;
            }
        }
    }

    weather = journey->weather_severity;
    if (weather > 3) {
        weather_pressure = (short)(weather - 3);
    } else if (weather < 2) {
        weather_pressure = (short)(2 - weather);
    }

    if (OtCountLivingPartyMembers_RealCpp(journey) != 0) {
        food_pressure =
            (short)(5 -
                    journey->clothing /
                        OtCountLivingPartyMembers_RealCpp(journey) -
                    journey->weather_severity * 2);
    }
    if (food_pressure < 0) {
        food_pressure = 0;
    }

    food_total =
        (short)(journey->food_from_plants + journey->food_from_hunting);
    ration_pressure = 0x10;
    if (food_total != 0) {
        ration_pressure = (short)(journey->ration_level * 2);
    }

    journey->health_pressure =
        (short)((journey->health_pressure - 1) / 2);
    if (food_pressure != 0 || food_total == 0) {
        ++journey->health_pressure;
    }

    condition =
        (short)(journey->health_pressure +
                (journey->party_condition_score * 9) / 10 +
                journey->pending_health_penalty +
                ration_pressure +
                food_pressure +
                weather_pressure +
                pace_pressure +
                sick_count);
    journey->party_condition_score = condition;

    if (condition > 0x8b) {
        if (OtCountLivingPartyMembers_RealCpp(journey) > 0) {
            OtTriggerTrailEventById_RealCpp(0x22);
            journey->party_condition_score = 0x8b;
        }
    }

    if (journey->party_condition_score > 0x82 &&
        (short)(journey->food_from_plants + journey->food_from_hunting) == 0 &&
        journey->oxen_count != 0) {
        OtTriggerTrailEventById_RealCpp(4);
    }

    journey->pending_health_penalty = 0;
}

#pragma optimize("", on)
#pragma code_seg()

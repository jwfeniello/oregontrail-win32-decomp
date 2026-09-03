// Semantic promotion for applying progress along the current trail segment.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct JourneyState_00419bd0 {
    char reserved_000[0x56];
    short miles_to_destination;
    char reserved_058[0x02];
    unsigned short route_stop_flags;
    short miles_traveled;
    char reserved_05e[0x2a];
    short daily_miles_available;
    short miles_remaining_in_step;
    char reserved_08c[0x02];
    short terrain_type;
    char reserved_090[0x02];
    short pace;
    char reserved_094[0x02];
    short oxen_count;
    short oxen_sick;
    char reserved_09a[0x7c];
    short party_health[5];

    void OtApplyTrailStepProgress_RealCpp(int progress_percent);
};
#pragma pack(pop)

extern "C" short __fastcall OtComputePartyHealthScore_RealCpp(
    JourneyState_00419bd0* journey);

#pragma optimize("s", off)
#pragma optimize("t", on)

void JourneyState_00419bd0::OtApplyTrailStepProgress_RealCpp(
    int progress_percent)
{
    register short remaining_step = miles_remaining_in_step;
    short effective_oxen;
    short weather_factor;
    register short party_factor = 10;
    short member_index;
    short oxen_allowance;
    int travel_capacity;
    int next_allowance;

    if (daily_miles_available > remaining_step) {
        daily_miles_available = remaining_step;
    }

    progress_percent = daily_miles_available * progress_percent;
    miles_traveled = (short)(miles_traveled + (short)(progress_percent / 100));
    miles_remaining_in_step =
        (short)(remaining_step + (short)(progress_percent / -100));

    weather_factor = (short)(4000 - miles_to_destination);
    if (weather_factor < 0) {
        weather_factor = 0;
    }

    member_index = 0;
    do {
        short party_health_state = party_health[member_index];
        if (party_health_state != 0 && party_health_state != 0x0f) {
            --party_factor;
        }
        ++member_index;
    } while (member_index < 5);

    effective_oxen = oxen_count;
    if (oxen_sick != 0) {
        --effective_oxen;
    }
    if (effective_oxen > 4) {
        effective_oxen = 4;
    }
    if (effective_oxen <= 0) {
        route_stop_flags = (unsigned short)(route_stop_flags | 1);
        return;
    }

    if (oxen_count > 8) {
        oxen_allowance = 2400;
    } else {
        oxen_allowance = (short)(oxen_count * 250);
    }

    next_allowance =
        (oxen_allowance * 100) /
        OtComputePartyHealthScore_RealCpp(this);
    if (next_allowance > 125) {
        next_allowance = 125;
    }

    oxen_allowance = (short)((terrain_type <= 5) ? 20 : 12);
    travel_capacity = oxen_allowance;
    travel_capacity *= pace + 2;
    travel_capacity *= weather_factor;
    travel_capacity *= effective_oxen;
    travel_capacity *= party_factor;

    next_allowance = ((travel_capacity / 320000) * next_allowance) / 100;
    if (next_allowance < 1 && weather_factor != 0) {
        next_allowance = 1;
    }
    if (route_stop_flags != 0) {
        next_allowance = 0;
    }

    daily_miles_available = (short)next_allowance;
}

#pragma optimize("", on)

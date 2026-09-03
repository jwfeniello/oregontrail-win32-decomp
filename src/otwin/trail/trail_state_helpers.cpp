// Product semantic recovery for the trail-delay state helper.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct JourneyState_00416380_40pct {
    char reserved_000[0x5a];
    unsigned char route_stop_flags;
    char reserved_05b[0x39];
    short delay_days;
};
#pragma pack(pop)

struct DelayTextState_0041ac20 {
    void OtFormatDelayDaysText_RealCpp(short days);
};

extern "C" JourneyState_00416380_40pct* g_journeyState;
extern "C" DelayTextState_0041ac20 g_trailEventRuntimeState;

#pragma optimize("s", off)
#pragma optimize("t", on)
#pragma optimize("a", off)
#pragma optimize("g", on)

// Adds a pending travel delay, marks the route stopped when it grows, and
// forwards the requested delay to the shared calendar/event text updater.
extern "C" void __stdcall OtAddTrailDelayDays_00416380_RealCpp(short days)
{
    register JourneyState_00416380_40pct* journey = g_journeyState;
    register short requested_delay = days;
    short current_delay = journey->delay_days;
    register short updated_delay = current_delay;
    JourneyState_00416380_40pct* flags_source;

    journey = reinterpret_cast<JourneyState_00416380_40pct*>(
        reinterpret_cast<char*>(journey) + 0x94);

    if (requested_delay > current_delay) {
        updated_delay = static_cast<short>(updated_delay + requested_delay);
        flags_source = g_journeyState;
        *reinterpret_cast<short*>(journey) = updated_delay;
        flags_source->route_stop_flags =
            static_cast<unsigned char>(flags_source->route_stop_flags | 0x20);
    }

    g_trailEventRuntimeState.OtFormatDelayDaysText_RealCpp(requested_delay);
}

#pragma optimize("", on)

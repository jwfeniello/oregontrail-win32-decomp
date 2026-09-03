// Canonical product implementation of Oregon32.exe journey-state defaults
// initialization (RVA 0x0001a000).

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct JourneyStateDefaults_0041a000_20260525 {
    char reserved_000[0x58];
    short daily_distance;
    short daily_pace;
    short daily_rations;
    short daily_health;
    unsigned long route_flags[10];
    short river_state;
    short trail_action;
    short current_zone;
    short oxen_state;
    short rations;
    short health;
    short weather;
    short trade_state;
    short supplies_state;
    short travel_state;
    short location_state;
    short route_event;
    short food_from_plants;
    short event_value_a;
    short event_value_b;
    short event_cooldown;
    int last_random_event;
    short food_from_hunting;
    char reserved_0ae[0x10];
    short event_delay;
    char reserved_0c0[0x4c];
    short party_status[5];
    short party_pending[5];
    short party_pending_tail;
    short trail_screen_state;

    void OtJourneyInitStateDefaultsMaskClosedFELTDR_0041a000();
};
#pragma pack(pop)

extern "C" void __cdecl OtClearTrailEventById_RealCpp(short event_id);

#pragma data_seg(".otdat")
extern "C" short g_firstTrailRoute_00437008 = 1;
extern "C" short g_lastTrailRoute_0043700c = 34;
extern "C" char g_trailStatusDirty_0043b89c = 0;
extern "C" char g_trailDailyStateDirty_0043b70c = 0;
#pragma data_seg()

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)
void JourneyStateDefaults_0041a000_20260525::
    OtJourneyInitStateDefaultsMaskClosedFELTDR_0041a000()
{
    int* random_event_slot = &last_random_event;

    trail_action = 0;
    river_state = 0;
    daily_health = 0;
    daily_rations = 0;
    daily_pace = 0;
    trail_screen_state = 0;
    party_pending_tail = 0;
    event_delay = 0;
    weather = 0;
    health = 0;
    rations = 0;
    food_from_hunting = 0;
    daily_distance = 0;
    supplies_state = 0;
    current_zone = 0;
    event_cooldown = 0;
    event_value_b = 0;
    event_value_a = 0;
    food_from_plants = 0;
    route_event = 0;
    location_state = 0;
    travel_state = 0;
    trade_state = 0;
    last_random_event = 0;

    for (int party_slot = 0; party_slot < 5; ++party_slot) {
        party_pending[party_slot] = 0;
        party_status[party_slot] = 0;
    }

    for (int route_slot = 0; route_slot < 10; ++route_slot) {
        route_flags[route_slot] = 0;
    }

    oxen_state = 0;

    int last_route;
    int route;
    route = g_firstTrailRoute_00437008;
    last_route = g_lastTrailRoute_0043700c;
    while (route <= last_route) {
        OtClearTrailEventById_RealCpp(static_cast<short>(route));
        ++route;
    }

    g_trailStatusDirty_0043b89c = 0;
    g_trailDailyStateDirty_0043b70c = 0;
    (void)random_event_slot;
}
#pragma optimize("", on)
#pragma code_seg()

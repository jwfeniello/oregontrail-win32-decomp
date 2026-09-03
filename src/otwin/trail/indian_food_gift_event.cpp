// Semantic recovery candidate for OtRunIndianFoodGiftEvent @ 0x00417520.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    void* window,
    unsigned int message,
    unsigned int wparam,
    long lparam);

#pragma pack(push, 1)
struct JourneyState_00417520 {
    char reserved_000[0x56];
    short route_progress_marker;
    char reserved_058[0x36];
    short current_route;
    char reserved_090[0x14];
    short food_from_plants;
    short food_from_hunting;
};

struct TrailEventTextState_00417520 {
    void* first_argument;

    void OtSetTrailEventTextDependency_00417520(int string_id);
};

struct TrailEventRunner_00417520 {
    char reserved_00[6];
    short message_count;
    char reserved_08[8];
    unsigned short food_gift_message_ids[8];

    void OtPrimeActiveTrailEventContextDependency_00417520();
    void OtRunIndianFoodGiftEvent_00017520_RealCpp();
};
#pragma pack(pop)

extern "C" JourneyState_00417520* g_journeyState;
extern "C" unsigned int g_trailEventTextArgument;
extern "C" TrailEventTextState_00417520 g_trailEventRuntimeState;
extern "C" void* g_trailEventDialogWindow;
extern "C" char g_trailEventMessageBuffer[];
extern "C" short __fastcall OtCountLivingPartyMembers_RealCpp(const void* party);

struct TrailEventContextSource_004163c0 {
    void OtPrimeActiveTrailEventContext_004163c0_RealCpp();
};

struct TrailEventTextRuntime_0041aac0_20260603 {
    char* OtFormatGameMessageText_0001ac80_ProductWip(int string_id);
};

#pragma code_seg(".otsem")
void TrailEventRunner_00417520::OtPrimeActiveTrailEventContextDependency_00417520()
{
    reinterpret_cast<TrailEventContextSource_004163c0*>(this)->
        OtPrimeActiveTrailEventContext_004163c0_RealCpp();
}

void TrailEventTextState_00417520::OtSetTrailEventTextDependency_00417520(
    int string_id)
{
    reinterpret_cast<TrailEventTextRuntime_0041aac0_20260603*>(this)->
        OtFormatGameMessageText_0001ac80_ProductWip(string_id);
}
#pragma code_seg()

#pragma optimize("s", off)
#pragma optimize("t", on)

// Runs the helpful-Indian food gift event: selects the text variant for the
// current trail segment, adds 30 pounds of food up to the 2000 pound cap, and
// posts the formatted event message.
void TrailEventRunner_00417520::OtRunIndianFoodGiftEvent_00017520_RealCpp()
{
    int message_index;
    int current_route = g_journeyState->current_route;
    TrailEventRunner_00417520* event = this;
    JourneyState_00417520* journey;
    short* food_from_hunting;
    short plant_food;
    short new_hunting_food;

    event->OtPrimeActiveTrailEventContextDependency_00417520();

    if (g_journeyState->route_progress_marker <= 10) {
        switch (current_route) {
        case 0:
        case 1:
        case 2:
        case 3:
            message_index = 2;
            break;

        case 4:
        case 5:
            message_index = 3;
            break;

        case 6:
        case 7:
            message_index = 4;
            break;

        case 8:
        case 9:
        case 10:
            message_index = 5;
            break;

        case 11:
        case 12:
        case 13:
            message_index = 6;
            break;

        default:
            message_index = 7;
            break;
        }
    } else {
        if (g_journeyState->current_route <= 10) {
            message_index = 0;
        } else {
            message_index = 1;
        }
    }

    journey = g_journeyState;
    g_trailEventTextArgument = event->food_gift_message_ids[message_index];
    food_from_hunting = &journey->food_from_hunting;
    journey = g_journeyState;

    new_hunting_food = static_cast<short>(*food_from_hunting + 30);
    plant_food = journey->food_from_plants;
    if (new_hunting_food + plant_food > 2000) {
        *food_from_hunting = static_cast<short>(2000 - plant_food);
    } else {
        *food_from_hunting = new_hunting_food;
    }

    g_trailEventRuntimeState.OtSetTrailEventTextDependency_00417520(0x310);

    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
        event->message_count == 1) {
        SendMessageA(
            g_trailEventDialogWindow,
            0x477,
            static_cast<unsigned short>(event->message_count),
            reinterpret_cast<long>(g_trailEventMessageBuffer));
    }
}

#pragma optimize("", on)

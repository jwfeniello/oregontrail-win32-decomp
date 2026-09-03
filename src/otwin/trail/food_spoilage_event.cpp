// Semantic recovery candidate for OtRunFoodSpoilageEvent @ 0x00417a10.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "trail_runtime.h"
#include "food_spoilage_event_types.h"

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" void* g_trailEventTextArgument;
extern "C" char g_trailEventMessageBuffer[];
extern "C" void* g_trailEventDialogWindow;
extern "C" const char g_foodSpoilageCountFormat_00417a10[] = "%d %s";

extern "C" __declspec(dllimport) int __cdecl wsprintfA(
    char* buffer,
    const char* format,
    ...);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    void* window,
    unsigned int message,
    unsigned int wparam,
    long lparam);

extern "C" short __fastcall OtCountLivingPartyMembers_RealCpp(const void* party);

#pragma pack(push, 1)
struct JourneyState_00417a10 {
    char reserved_000[0xa4];
    short food_from_plants;
    short food_from_hunting;
};
#pragma pack(pop)

extern "C" JourneyState_00417a10* g_journeyState;
extern "C" TrailEventTextState_00417a10 g_trailEventRuntimeState;

#pragma optimize("s", off)
#pragma optimize("t", on)

// Runs the food-spoilage event: remove ten percent of hunting food, clamp the
// total carried food at 2000 pounds, format the lost amount, and post the
// trail-event message when the event has visible text.
void TrailEventRunner_00417a10::OtRunFoodSpoilageEvent_00417a10_RealCpp()
{
    char unit_text[40];
    char quantity_text[40];
    TrailEventRunner_00417a10* event = this;
    short lost_food = static_cast<short>((g_journeyState->food_from_hunting * 10) / 100);

    if (lost_food != 0) {
        short remaining_hunting_food =
            static_cast<short>(g_journeyState->food_from_hunting - lost_food);
        if (remaining_hunting_food + g_journeyState->food_from_plants > 2000) {
            g_journeyState->food_from_hunting =
                static_cast<short>(2000 - g_journeyState->food_from_plants);
        } else {
            g_journeyState->food_from_hunting = remaining_hunting_food;
        }

        event->OtPrimeActiveTrailEventContextDependency_00417a10();
        LoadStringA(
            g_applicationModule_00405a40_20260603,
            (lost_food > 1) + 0x390,
            unit_text,
            0x27);
        wsprintfA(
            quantity_text,
            g_foodSpoilageCountFormat_00417a10,
            static_cast<int>(lost_food),
            unit_text);
        g_trailEventTextArgument = quantity_text;
        g_trailEventRuntimeState.OtFormatGameMessageTextDependency_00417a10(0x330);

        if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
            event->message_count == 1) {
            SendMessageA(
                g_trailEventDialogWindow,
                0x477,
                static_cast<unsigned short>(event->message_count),
                reinterpret_cast<long>(g_trailEventMessageBuffer));
        }
    }
}

#pragma optimize("", on)

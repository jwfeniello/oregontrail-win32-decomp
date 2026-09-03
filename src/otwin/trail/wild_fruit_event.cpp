// Wild-fruit trail event recovered from Oregon32.exe.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This source must be compiled with 32-bit MSVC."
#endif

#include "trail_event_context_source.h"
#include "trail_event_text_runtime.h"

#pragma pack(push, 1)
struct JourneyState_00416b90 {
    char reserved_000[0xa4];
    short food_from_plants;
    short food_from_hunting;
};

struct TrailEventRunner_00416c50 {
    char reserved_00[6];
    short message_count;

    void OtRunWildFruitEvent_RealCpp();
};
#pragma pack(pop)

extern "C" JourneyState_00416b90* g_journeyState;
extern "C" void* g_trailEventDialogWindow;
extern "C" char g_trailEventMessageBuffer[];
extern "C" short __fastcall OtCountLivingPartyMembers_RealCpp(
    const void* party);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    void* window,
    unsigned int message,
    unsigned int wparam,
    long lparam);

#pragma optimize("s", off)
#pragma optimize("t", on)

// Awards up to twenty pounds of plant food without exceeding the combined
// 2,000-pound supply cap, then posts the formatted event message.
void TrailEventRunner_00416c50::OtRunWildFruitEvent_RealCpp()
{
    short bonus = 0x14;
    short total_food = static_cast<short>(
        g_journeyState->food_from_plants + g_journeyState->food_from_hunting);

    reinterpret_cast<TrailEventContextSource_004163c0*>(this)
        ->OtPrimeActiveTrailEventContext_004163c0_RealCpp();
    if (2000 < total_food + 0x14) {
        bonus = static_cast<short>(2000 - total_food);
    }

    short* dst = &g_journeyState->food_from_hunting;
    short new_food_hunting = static_cast<short>(*dst + bonus);

    if (new_food_hunting + g_journeyState->food_from_plants > 2000) {
        *dst = static_cast<short>(
            2000 - g_journeyState->food_from_plants);
    } else {
        *dst = new_food_hunting;
    }

    g_trailEventRuntimeState.
        OtFormatGameMessageText_0001ac80_ProductWip(0x2dc);

    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
        message_count == 1) {
        SendMessageA(
            g_trailEventDialogWindow,
            0x477,
            static_cast<unsigned short>(message_count),
            reinterpret_cast<long>(g_trailEventMessageBuffer));
    }
}

#pragma optimize("", on)

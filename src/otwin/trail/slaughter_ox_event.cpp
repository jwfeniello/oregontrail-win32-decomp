// Product semantic WIP for OtRunSlaughterOxForFoodEvent @ 0x00416680.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This Product source must be compiled with 32-bit MSVC."
#endif

#include "trail_event_text_runtime.h"

extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* instance,
    unsigned int string_id,
    char* buffer,
    int buffer_max);
extern "C" __declspec(dllimport) int __cdecl wsprintfA(
    char* buffer,
    const char* format,
    ...);

extern "C" int __cdecl OtRandomBelow_RealCpp(int upper_bound);
extern "C" short __fastcall OtCountLivingPartyMembers_RealCpp(
    const void* party);
extern "C" void __stdcall OtAddTrailDelayDays_00416380_RealCpp(short days);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    void* window,
    unsigned int message,
    unsigned int wparam,
    long lparam);

struct TrailEventContextSource_004163c0 {
    void OtPrimeActiveTrailEventContext_004163c0_RealCpp();
};

#pragma pack(push, 1)
struct JourneyState_00416680_Product {
    char reserved_000[0x5a];
    unsigned short route_stop_flags;
    char reserved_05c[0x3a];
    short oxen_count;
    short ox_sick;
    short clothing;
    short bullets;
    short wagon_wheels;
    short wagon_axles;
    short wagon_tongues;
    short food_from_plants;
    short food_from_hunting;
};

struct TrailEventRunner_00416680_Product {
    char reserved_00[6];
    short message_count;
    char reserved_08[0x22];
    int no_food_followup_pending;

    void OtPrimeActiveTrailEventContextDependency_00416680();
    void OtSetTrailDelayDaysDependency_00416680(short days);
    void OtRunSlaughterOxForFoodEvent_00416680_ProductWip();
};
#pragma pack(pop)

extern "C" JourneyState_00416680_Product* g_journeyState;
extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" void* g_trailEventDialogWindow;
extern "C" char g_trailEventMessageBuffer[];
extern "C" void* g_trailEventTextArgument;
extern "C" short g_trailEventChoice_00417190;

extern "C" char g_slaughterOxQuantityText_00416680[40] = {0};
extern "C" const char g_slaughterOxCountAndUnitFormat_00416680[] = "%d %s";
extern "C" const char g_slaughterOxCountOnlyFormat_00416680[] = "%d";

#pragma comment(lib, "user32.lib")

#pragma code_seg(".otsem")

void TrailEventRunner_00416680_Product::
    OtPrimeActiveTrailEventContextDependency_00416680()
{
    reinterpret_cast<TrailEventContextSource_004163c0*>(this)
        ->OtPrimeActiveTrailEventContext_004163c0_RealCpp();
}

void TrailEventRunner_00416680_Product::
    OtSetTrailDelayDaysDependency_00416680(short days)
{
    OtAddTrailDelayDays_00416380_RealCpp(days);
}

#pragma code_seg()

#pragma optimize("s", off)
#pragma optimize("t", on)

// Offers to slaughter an ox when bullets are exhausted, converts the accepted
// animal into food, updates the sick/no-oxen state, and posts both messages.
void TrailEventRunner_00416680_Product::
    OtRunSlaughterOxForFoodEvent_00416680_ProductWip()
{
    char ox_unit_text[32];
    TrailEventRunner_00416680_Product* event = this;

    event->OtPrimeActiveTrailEventContextDependency_00416680();
    if (event->no_food_followup_pending != 0 &&
        g_journeyState->bullets == 0) {
        LoadStringA(
            g_applicationModule_00405a40_20260603,
            (g_journeyState->oxen_count > 1) + 0x384,
            ox_unit_text,
            0x1d);
        wsprintfA(
            g_slaughterOxQuantityText_00416680,
            g_slaughterOxCountAndUnitFormat_00416680,
            static_cast<int>(g_journeyState->oxen_count),
            ox_unit_text);

        g_trailEventTextArgument = g_slaughterOxQuantityText_00416680;
        g_trailEventRuntimeState.
            OtSetTrailEventTextDependency_RealCpp(0x2cc);
        g_trailEventChoice_00417190 = -1;

        if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
            event->message_count == 1) {
            SendMessageA(
                g_trailEventDialogWindow,
                0x477,
                static_cast<unsigned short>(event->message_count),
                reinterpret_cast<long>(g_trailEventMessageBuffer));
        }

        if (g_trailEventChoice_00417190 != 6 &&
            g_trailEventChoice_00417190 != 1) {
            event->no_food_followup_pending = 0;
            return;
        }

        event->OtSetTrailDelayDaysDependency_00416680(1);

        short recovered_food =
            static_cast<short>(OtRandomBelow_RealCpp(100) + 0xaf);
        int recovered_food_for_text = recovered_food;
        JourneyState_00416680_Product* food_journey = g_journeyState;
        if (2000 < food_journey->food_from_plants +
                   recovered_food_for_text) {
            recovered_food =
                static_cast<short>(2000 - food_journey->food_from_plants);
        }
        food_journey->food_from_hunting = recovered_food;
        g_journeyState->ox_sick = 0;

        JourneyState_00416680_Product* count_journey = g_journeyState;
        JourneyState_00416680_Product* flag_journey = g_journeyState;
        short* oxen_count = &count_journey->oxen_count;
        short oxen_remaining = *oxen_count;
        --oxen_remaining;
        unsigned short flags = flag_journey->route_stop_flags;
        unsigned short no_oxen_flag = static_cast<unsigned short>(flags & 1);

        if (no_oxen_flag != 0 && oxen_remaining > 0) {
            if (no_oxen_flag != 0) {
                flag_journey->route_stop_flags =
                    static_cast<unsigned short>(flags ^ 1);
            }
            if (flag_journey->ox_sick != 0) {
                flag_journey->ox_sick = 0;
                --oxen_remaining;
            }
        }
        *oxen_count = oxen_remaining;

        if (g_journeyState->oxen_count == 0) {
            *reinterpret_cast<unsigned char*>(
                &g_journeyState->route_stop_flags) =
                static_cast<unsigned char>(
                    *reinterpret_cast<unsigned char*>(
                        &g_journeyState->route_stop_flags) | 1);
        }

        wsprintfA(
            g_slaughterOxQuantityText_00416680,
            g_slaughterOxCountOnlyFormat_00416680,
            recovered_food_for_text);
        g_trailEventRuntimeState.
            OtSetTrailEventTextDependency_RealCpp(0x2cd);

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

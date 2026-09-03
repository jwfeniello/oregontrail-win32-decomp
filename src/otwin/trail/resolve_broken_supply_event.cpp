// Product semantic WIP for OtResolveBrokenSupplyEvent @ 0x00417190.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include "trail_event_text_runtime.h"

extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    void* window,
    unsigned int message,
    unsigned int wparam,
    long lparam);

extern "C" int __cdecl OtRandomBelow_RealCpp(int upper_bound);
extern "C" short __fastcall OtCountLivingPartyMembers_RealCpp(
    const void* party);
extern "C" void __stdcall OtAddTrailDelayDays_00416380_RealCpp(short days);

#pragma comment(lib, "user32.lib")

#pragma pack(push, 1)
struct JourneyState_00417190_ProductWip {
    char reserved_000[0x5a];
    unsigned short route_stop_flags;
    char reserved_05c[0x50];
    short river_crossing_type;
};

struct TrailEventContextSource_004163c0 {
    char reserved_00[6];
    unsigned short message_count;
    char reserved_08[8];
    unsigned short variant_text_ids[4];
    char reserved_18[8];
    unsigned short field_20;
    unsigned short field_22;
    unsigned short field_24;
    unsigned short field_26;

    void OtPrimeActiveTrailEventContext_004163c0_RealCpp();
};
#pragma pack(pop)

extern "C" JourneyState_00417190_ProductWip* g_journeyState;
extern "C" void* g_trailEventDialogWindow;
extern "C" char g_trailEventMessageBuffer[];

#pragma code_seg(".otsem")
// Original dialog-choice storage is 0x0043b66e. The event dialog procedure is
// responsible for replacing the -1 sentinel while SendMessageA runs.
extern "C" __declspec(allocate(".otsem"))
short g_trailEventChoice_00417190 = 0;

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" short __cdecl OtResolveBrokenSupplyEvent_00017190_ProductWip(
    TrailEventContextSource_004163c0* dialog,
    short supply_count,
    unsigned short shortage_flag)
{
    register int event_address = reinterpret_cast<int>(dialog);
    register unsigned short* message_count;
    register int result_text_id = 3;
    short repair_probability;

    reinterpret_cast<TrailEventContextSource_004163c0*>(event_address)->
        OtPrimeActiveTrailEventContext_004163c0_RealCpp();
    g_trailEventRuntimeState.
        OtFormatGameMessageText_0001ac80_ProductWip(0x306);
    g_trailEventChoice_00417190 = -1;

    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0) {
        goto show_initial_message;
    }
    message_count =
        &reinterpret_cast<TrailEventContextSource_004163c0*>(event_address)->
            message_count;
    if (*message_count != 1) {
        goto after_initial_message;
    }

show_initial_message:
    message_count =
        &reinterpret_cast<TrailEventContextSource_004163c0*>(event_address)->
            message_count;
    SendMessageA(
        g_trailEventDialogWindow,
        0x477,
        static_cast<unsigned int>(*message_count),
        reinterpret_cast<long>(g_trailEventMessageBuffer));

after_initial_message:
    repair_probability = 0;
    if (g_trailEventChoice_00417190 == 6 ||
        g_trailEventChoice_00417190 == 1) {
        result_text_id = 0;
        OtAddTrailDelayDays_00416380_RealCpp(1);
        if (g_journeyState->river_crossing_type == 1 ||
            (repair_probability = 50,
             g_journeyState->river_crossing_type == 2)) {
            repair_probability = 75;
        }
    }

    if (OtRandomBelow_RealCpp(100) < repair_probability) {
        result_text_id = 0x303;
    } else if (supply_count != 0) {
        --supply_count;
        result_text_id += 0x304;
    } else {
        result_text_id += 0x305;
        g_journeyState->route_stop_flags =
            static_cast<unsigned short>(
                g_journeyState->route_stop_flags | shortage_flag);
    }

    g_trailEventRuntimeState.
        OtFormatGameMessageText_0001ac80_ProductWip(result_text_id);
    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
        *message_count == 1) {
        SendMessageA(
            g_trailEventDialogWindow,
            0x477,
            static_cast<unsigned int>(*message_count),
            reinterpret_cast<long>(g_trailEventMessageBuffer));
    }

    return supply_count;
}

#pragma optimize("", on)
#pragma code_seg()

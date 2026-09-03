// Product semantic WIPs for river-crossing loss and outcome resolution.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include "../trail/trail_event_text_pointers.h"

extern "C" int __cdecl OtRandomBelow_RealCpp(int upper_bound);
extern "C" short* __fastcall OtClearEventAdjustmentList_RealCpp(
    short* adjustments);
extern "C" int __fastcall OtHasEventAdjustmentEntries_RealCpp(
    const short* adjustments);
extern "C" void __cdecl OtQueuePartyDeathEventForMember_RealCpp(
    short member_index);
extern "C" void __cdecl OtApplyLossEventAdjustmentList_0041a660_ProductWip(
    short* adjustments);
extern "C" void __cdecl
OtRollRiverCrossingPartyCasualties_0040f1e0_RealCpp(
    short probability,
    short* loss_adjustments);

extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* instance,
    unsigned int string_id,
    char* buffer,
    int buffer_max);

#pragma comment(lib, "user32.lib")

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" void* g_journeyState;
extern "C" void* g_activeRouteDescriptor;
extern "C" short g_riverCrossingPromptMode_0040ec30;
extern "C" short g_riverCrossingChoice_0040ec30;
extern "C" short g_riverCrossingDialogResult_0040ec30;

#pragma pack(push, 1)
struct JourneyRiverOutcomeState_0040f000_ProductWip {
    char reserved_000[0x54];
    short river_condition;
    char reserved_056[0x40];
    short oxen_count;
    short oxen_sick;
    short clothing;
    short ammunition;
    short wagon_wheels;
    short wagon_axles;
    short wagon_tongues;
    short food_from_plants;
    short food_from_hunting;
    char reserved_0a8[0x6e];
    short member_state[5];
};

struct RouteRiverOutcomeState_0040f270_ProductWip {
    short route_id;
    short route_stop_kind;
    short store_price_percent;
    short region_id;
    short river_difficulty;
    short base_width;
    short float_hazard;
};

struct EventAdjustmentListFormatter_0041a320 {
    short entries[13];

    void OtApplyLossEventAdjustmentListDependency_0040f000_Product();
    short OtFormatEventAdjustmentList_0041a320_RealCpp(
        const char* person_event_text);
};

struct TrailEventTextRuntime_0041aac0_20260603 {
    void* first_argument;
    char reserved_004[0x68];
    char prompt_text[0x190];
    char followup_text[1];

    char* OtFormatGameMessageText_0001ac80_ProductWip(int string_id);
};
#pragma pack(pop)

extern "C" TrailEventTextRuntime_0041aac0_20260603
    g_trailEventRuntimeState;

static __inline void OtFinalizeRiverCrossingChoice_SetPromptPointers()
{
    TrailEventTextRuntime_0041aac0_20260603& runtime =
        g_trailEventRuntimeState;

    (g_trailEventTextPointers.primary = runtime.prompt_text,
     g_trailEventTextPointers.secondary = runtime.followup_text);
}

#pragma data_seg(".otdat")
extern "C" __declspec(allocate(".otdat"))
short g_riverCrossingSceneMode_0040f270 = 0;
extern "C" __declspec(allocate(".otdat"))
short g_eventAdjustmentFormattedCount_0040f000_Product = 0;
extern "C" __declspec(allocate(".otdat"))
int g_riverResultPromptStringId = 0;
#pragma data_seg()

#pragma code_seg(".otsem")
void EventAdjustmentListFormatter_0041a320::
    OtApplyLossEventAdjustmentListDependency_0040f000_Product()
{
    OtApplyLossEventAdjustmentList_0041a660_ProductWip(entries);
}
#pragma code_seg()

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" void __cdecl OtRollRiverCrossingOxLosses_0040f180_Product(
    short probability,
    short* loss_adjustment)
{
    short roll_index = 0;

    if (static_cast<JourneyRiverOutcomeState_0040f000_ProductWip*>(
            g_journeyState)->oxen_count > 0) {
        do {
            if (OtRandomBelow_RealCpp(100) < probability) {
                *loss_adjustment =
                    static_cast<short>(*loss_adjustment + 1);
                static_cast<JourneyRiverOutcomeState_0040f000_ProductWip*>(
                    g_journeyState)->oxen_sick = 0;
            }
            ++roll_index;
        } while (
            roll_index <
            static_cast<JourneyRiverOutcomeState_0040f000_ProductWip*>(
                g_journeyState)->oxen_count);
    }
}

#pragma optimize("", on)

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" int __cdecl
OtResolveRiverCrossingLossAdjustmentList_0040f000_ProductWip(
    short probability,
    short* loss_adjustments)
{
    register int roll_probability;
    int member_index;
    char drowned_text[12];

    LoadStringA(
        g_applicationModule_00405a40_20260603,
        0x3af,
        drowned_text,
        10);
    roll_probability = probability;

    if (OtRandomBelow_RealCpp(100) < roll_probability) {
        loss_adjustments[1] = static_cast<short>(
            OtRandomBelow_RealCpp(
                static_cast<JourneyRiverOutcomeState_0040f000_ProductWip*>(
                    g_journeyState)->clothing +
                1));
    }
    if (OtRandomBelow_RealCpp(100) < roll_probability) {
        loss_adjustments[2] = static_cast<short>(
            OtRandomBelow_RealCpp(
                static_cast<JourneyRiverOutcomeState_0040f000_ProductWip*>(
                    g_journeyState)->ammunition +
                1));
    }
    if (OtRandomBelow_RealCpp(100) < roll_probability) {
        loss_adjustments[3] = static_cast<short>(
            OtRandomBelow_RealCpp(
                static_cast<JourneyRiverOutcomeState_0040f000_ProductWip*>(
                    g_journeyState)->wagon_wheels +
                1));
    }
    if (OtRandomBelow_RealCpp(100) < roll_probability) {
        loss_adjustments[4] = static_cast<short>(
            OtRandomBelow_RealCpp(
                static_cast<JourneyRiverOutcomeState_0040f000_ProductWip*>(
                    g_journeyState)->wagon_axles +
                1));
    }
    if (OtRandomBelow_RealCpp(100) < roll_probability) {
        loss_adjustments[5] = static_cast<short>(
            OtRandomBelow_RealCpp(
                static_cast<JourneyRiverOutcomeState_0040f000_ProductWip*>(
                    g_journeyState)->wagon_tongues +
                1));
    }
    if (OtRandomBelow_RealCpp(100) < roll_probability) {
        loss_adjustments[6] = static_cast<short>(OtRandomBelow_RealCpp(
            static_cast<short>(
                static_cast<JourneyRiverOutcomeState_0040f000_ProductWip*>(
                    g_journeyState)->food_from_plants +
                static_cast<JourneyRiverOutcomeState_0040f000_ProductWip*>(
                    g_journeyState)->food_from_hunting) +
            1));
    }

    reinterpret_cast<EventAdjustmentListFormatter_0041a320*>(
        loss_adjustments)->
            OtApplyLossEventAdjustmentListDependency_0040f000_Product();
    member_index = 8;
    g_eventAdjustmentFormattedCount_0040f000_Product =
        reinterpret_cast<EventAdjustmentListFormatter_0041a320*>(
            loss_adjustments)->OtFormatEventAdjustmentList_0041a320_RealCpp(
            drowned_text);

    do {
        if (loss_adjustments[member_index] != 0) {
            OtQueuePartyDeathEventForMember_RealCpp(
                static_cast<short>(member_index - 8));
        }
        ++member_index;
    } while (member_index < 13);

    return OtHasEventAdjustmentEntries_RealCpp(loss_adjustments);
}

#pragma optimize("", on)

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" short __cdecl OtResolveFordCrossingOutcome_0040f270_ProductWip();
extern "C" short __cdecl OtResolveFloatCrossingOutcome_0040f4b0_ProductWip();
extern "C" short __cdecl OtResolveFerryCrossingOutcome_0040f650_ProductWip();

extern "C" short __stdcall
OtFinalizeRiverCrossingChoice_0040f760_ProductWip(void*)
{
    int crossing_choice = g_riverCrossingChoice_0040ec30;
    int result_text_id = 0;

    g_riverCrossingDialogResult_0040ec30 = 0;
    g_riverResultPromptStringId = crossing_choice + 0x385;

    switch (crossing_choice) {
    case 100:
        result_text_id = OtResolveFordCrossingOutcome_0040f270_ProductWip();
        break;
    case 101:
        result_text_id = OtResolveFloatCrossingOutcome_0040f4b0_ProductWip();
        break;
    case 102:
        result_text_id = OtResolveFerryCrossingOutcome_0040f650_ProductWip();
        break;
    }

    if (result_text_id != 0) {
        g_trailEventRuntimeState.
            OtFormatGameMessageText_0001ac80_ProductWip(result_text_id);
    }

    OtFinalizeRiverCrossingChoice_SetPromptPointers();
    return g_riverCrossingDialogResult_0040ec30;
}

#pragma optimize("", on)
#pragma code_seg()

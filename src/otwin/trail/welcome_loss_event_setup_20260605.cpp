// Product semantic implementation of the welcome loss-event setup at
// 0x00416120.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include "trail_event_text_runtime.h"
#include "../trade/trade_adjustment_list.h"

extern "C" int __cdecl OtRandomBelow_RealCpp(int upper_bound);
extern "C" void* __cdecl OtAllocateNewBlock_RealCpp(unsigned int bytes);
extern "C" short* __fastcall OtClearEventAdjustmentList_RealCpp(
    short* adjustments);
extern "C" int __fastcall OtHasEventAdjustmentEntries_RealCpp(
    const short* adjustments);
extern "C" short __fastcall OtCountLivingPartyMembers_RealCpp(
    const void* party);

extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* instance,
    unsigned int resource_id,
    char* buffer,
    int buffer_count);

#pragma comment(lib, "user32.lib")

void __cdecl operator delete(void* block);

#pragma pack(push, 1)
struct JourneyState_00416120_20260605 {
    char reserved_000[0x96];
    short party_count;
    char reserved_098[2];
    short oxen_count;
    short food_count;
    short wagon_wheel_count;
    short clothing_count;
    short bullet_count;
    short wagon_axle_count;
    short wagon_tongue_count;

    short OtSparePartCount_20260716() const
    {
        return static_cast<short>(
            wagon_axle_count + wagon_tongue_count);
    }

    short OtCountLivingPartyMembersDependency_00416120() const;
};

struct EventAdjustmentListFormatter_0041a320 {
    short entries[13];

    short OtFormatEventAdjustmentList_0041a320_RealCpp(
        const char* person_event_text);
};

struct WelcomeLossAdjustmentList_00416120 {
    short entries[13];

    static void* __cdecl operator new(unsigned int bytes);
    WelcomeLossAdjustmentList_00416120();
    void OtApplyLossEventAdjustmentListDependency_00416120();
    int OtHasEventAdjustmentEntriesDependency_00416120() const;
    short OtFormatEventAdjustmentListDependency_00416120(
        const char* person_event_text);
};
#pragma pack(pop)

extern "C" JourneyState_00416120_20260605* g_journeyState;
extern "C" void* g_resourceModule;
extern "C" char g_eventAdjustmentText_0041a320[];
extern "C" short g_welcomeLossFormattedAdjustmentCount_00416120 = 0;

#pragma code_seg(".otsem")

void* __cdecl WelcomeLossAdjustmentList_00416120::operator new(
    unsigned int bytes)
{
    return OtAllocateNewBlock_RealCpp(bytes);
}

WelcomeLossAdjustmentList_00416120::WelcomeLossAdjustmentList_00416120()
{
    OtClearEventAdjustmentList_RealCpp(entries);
}

void WelcomeLossAdjustmentList_00416120::
    OtApplyLossEventAdjustmentListDependency_00416120()
{
    reinterpret_cast<TradeAdjustmentList_00427d70*>(this)
        ->OtApplyLossEventAdjustmentList_Product_0041a660();
}

int WelcomeLossAdjustmentList_00416120::
    OtHasEventAdjustmentEntriesDependency_00416120() const
{
    return OtHasEventAdjustmentEntries_RealCpp(entries);
}

short WelcomeLossAdjustmentList_00416120::
    OtFormatEventAdjustmentListDependency_00416120(
        const char* person_event_text)
{
    short count =
        reinterpret_cast<EventAdjustmentListFormatter_0041a320*>(this)
            ->OtFormatEventAdjustmentList_0041a320_RealCpp(
                person_event_text);
    g_trailEventRuntimeState.event_argument_pointer =
        g_eventAdjustmentText_0041a320;
    return count;
}

short JourneyState_00416120_20260605::
    OtCountLivingPartyMembersDependency_00416120() const
{
    return OtCountLivingPartyMembers_RealCpp(this);
}

#pragma code_seg()

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" char* __cdecl OtWelcomePartyNameCommit_20260605_Wip()
{
    WelcomeLossAdjustmentList_00416120* adjustments =
        new WelcomeLossAdjustmentList_00416120;

    short member_index = 0;
    while (member_index < g_journeyState->party_count) {
        if (OtRandomBelow_RealCpp(100) < 40) {
            ++adjustments->entries[0];
        }
        ++member_index;
    }

    adjustments->entries[3] =
        static_cast<short>(
            OtRandomBelow_RealCpp(g_journeyState->wagon_wheel_count + 1));
    short spare_part_count =
        g_journeyState->OtSparePartCount_20260716();
    adjustments->entries[6] =
        static_cast<short>(OtRandomBelow_RealCpp(spare_part_count + 1));
    adjustments->entries[4] =
        static_cast<short>(
            OtRandomBelow_RealCpp(g_journeyState->clothing_count + 1));
    adjustments->entries[5] =
        static_cast<short>(
            OtRandomBelow_RealCpp(g_journeyState->bullet_count + 1));
    adjustments->entries[2] =
        static_cast<short>(
            OtRandomBelow_RealCpp(g_journeyState->food_count + 1));
    adjustments->entries[1] =
        static_cast<short>(
            OtRandomBelow_RealCpp(g_journeyState->oxen_count + 1));

    if (g_journeyState->
            OtCountLivingPartyMembersDependency_00416120() == 1) {
        if (OtRandomBelow_RealCpp(100) < 40) {
            adjustments->entries[8] = 1;
        }
    } else {
        short loss_slot = 1;
        register int loss_value = loss_slot;
        do {
            if (OtRandomBelow_RealCpp(100) < 40) {
                adjustments->entries[8 + loss_slot] =
                    static_cast<short>(loss_value);
            }
            ++loss_slot;
        } while (loss_slot < 5);
    }

    adjustments->OtApplyLossEventAdjustmentListDependency_00416120();

    if (adjustments->OtHasEventAdjustmentEntriesDependency_00416120()) {
        char person_event_text[0x10];
        LoadStringA(g_resourceModule, 0x3af, person_event_text, 0x0b);
        g_welcomeLossFormattedAdjustmentCount_00416120 =
            adjustments->OtFormatEventAdjustmentListDependency_00416120(
                person_event_text);
        g_trailEventRuntimeState.
            OtFormatGameMessageText_0001ac80_ProductWip(0x3ac);
    } else {
        g_trailEventRuntimeState.
            OtFormatGameMessageText_0001ac80_ProductWip(0x3ad);
    }

    delete adjustments;

    return g_trailEventRuntimeState.primary_text;
}

#pragma optimize("", on)

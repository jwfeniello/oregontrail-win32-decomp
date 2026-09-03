// Product semantic recovery for OtRunAbandonedWagonEvent @ 0x00416e40.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This Product source must be compiled with 32-bit MSVC."
#endif

#include "trail_event_context_source.h"
#include "trail_event_text_runtime.h"
#include "../trade/trade_adjustment_list.h"

extern "C" int __cdecl OtRandomBelow_RealCpp(int upper_bound);
extern "C" short* __fastcall OtClearEventAdjustmentList_RealCpp(
    short* adjustments);
extern "C" int __fastcall OtHasEventAdjustmentEntries_RealCpp(
    const short* adjustments);
extern "C" short __fastcall OtCountLivingPartyMembers_RealCpp(
    const void* party);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    void* window,
    unsigned int message,
    unsigned int wparam,
    long lparam);

void* __cdecl operator new(unsigned int bytes);
void __cdecl operator delete(void* block);

struct EventAdjustmentListFormatter_0041a320 {
    short OtFormatEventAdjustmentList_0041a320_RealCpp(
        const char* person_event_text);
};

#pragma pack(push, 1)
struct EventAdjustmentList_00416e40_Product {
    short entries[13];

    EventAdjustmentList_00416e40_Product();
};

struct TrailEventRunner_00416e40_Product {
    char reserved_00[6];
    short message_count;

    void OtRunAbandonedWagonEvent_00416e40_RealCpp();
};
#pragma pack(pop)

extern "C" void* g_journeyState;
extern "C" void* g_trailEventDialogWindow;
extern "C" char g_trailEventMessageBuffer[];
extern "C" short g_abandonedWagonFormattedAdjustmentCount_00416e40 = 0;
extern "C" const char g_emptyString_004395ac[];

#pragma code_seg(".otsem")

EventAdjustmentList_00416e40_Product::
    EventAdjustmentList_00416e40_Product()
{
    OtClearEventAdjustmentList_RealCpp(entries);
}

#pragma code_seg()

#pragma optimize("s", off)
#pragma optimize("t", on)

// Rolls a salvage bundle, applies the capacity-clamped gains, formats the
// recovered items, and posts the matching event text.
void TrailEventRunner_00416e40_Product::
    OtRunAbandonedWagonEvent_00416e40_RealCpp()
{
    EventAdjustmentList_00416e40_Product* adjustments = 0;
    adjustments = new EventAdjustmentList_00416e40_Product;

    if (OtRandomBelow_RealCpp(2) != 0) {
        adjustments->entries[3] =
            static_cast<short>(OtRandomBelow_RealCpp(3) + 1);
    }
    if (OtRandomBelow_RealCpp(2) != 0) {
        adjustments->entries[4] =
            static_cast<short>(OtRandomBelow_RealCpp(3) + 1);
    }
    if (OtRandomBelow_RealCpp(2) != 0) {
        adjustments->entries[5] =
            static_cast<short>(OtRandomBelow_RealCpp(3) + 1);
    }
    if (OtRandomBelow_RealCpp(2) != 0) {
        adjustments->entries[2] =
            static_cast<short>(OtRandomBelow_RealCpp(21) + 20);
    }
    if (OtRandomBelow_RealCpp(2) != 0) {
        adjustments->entries[1] =
            static_cast<short>(OtRandomBelow_RealCpp(3) + 1);
    }

    reinterpret_cast<TrailEventContextSource_004163c0*>(this)
        ->OtPrimeActiveTrailEventContext_004163c0_RealCpp();
    reinterpret_cast<TradeAdjustmentList_00427d70*>(adjustments)
        ->OtApplyEventAdjustmentList_Product_0041a430();
    if (OtHasEventAdjustmentEntries_RealCpp(adjustments->entries) != 0) {
        g_abandonedWagonFormattedAdjustmentCount_00416e40 =
            reinterpret_cast<EventAdjustmentListFormatter_0041a320*>(
                adjustments)
                ->OtFormatEventAdjustmentList_0041a320_RealCpp(
                    g_emptyString_004395ac);
        g_trailEventRuntimeState.
            OtFormatGameMessageText_0001ac80_ProductWip(0x2f2);
    } else {
        g_trailEventRuntimeState.
            OtFormatGameMessageText_0001ac80_ProductWip(0x2f3);
    }

    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
        message_count == 1) {
        SendMessageA(
            g_trailEventDialogWindow,
            0x477,
            static_cast<unsigned short>(message_count),
            reinterpret_cast<long>(g_trailEventMessageBuffer));
    }

    delete adjustments;
}

#pragma optimize("", on)

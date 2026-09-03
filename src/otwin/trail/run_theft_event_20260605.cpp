// Product semantic implementation of OtRunTheftEvent @ 0x00417de0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include "trail_event_text_runtime.h"
#include "../trade/trade_adjustment_list.h"

extern "C" int __cdecl OtRandomBelow_RealCpp(int upper_bound);
extern "C" short* __fastcall OtClearEventAdjustmentList_RealCpp(
    short* adjustments);
extern "C" int __fastcall OtHasEventAdjustmentEntries_RealCpp(
    const short* adjustments);
extern "C" short __fastcall OtCountLivingPartyMembers_RealCpp(
    const void* party);
extern "C" void* __cdecl OtAllocateNewBlock_RealCpp(unsigned int bytes);

extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* instance,
    unsigned int string_id,
    char* buffer,
    int buffer_max);
extern "C" __declspec(dllimport) int __cdecl wsprintfA(
    char* buffer,
    const char* format,
    ...);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    void* window,
    unsigned int message,
    unsigned int wparam,
    long lparam);

#pragma comment(lib, "user32.lib")

void __cdecl operator delete(void* block);

#pragma pack(push, 1)
struct JourneyState_00417de0_20260605 {
    char reserved_000[0x5a];
    unsigned char route_stop_flags;
    char reserved_05b[0x3b];
    short oxen_count;
    short ox_sick;
    short clothing;
    short bullets;
    short wagon_wheels;
    short wagon_axles;
    short wagon_tongues;
    short food_from_plants;
    short food_from_hunting;
    int cash_cents;
};

struct EventAdjustmentList_00417de0_20260605 {
    short entries[13];

    static void* __cdecl operator new(unsigned int bytes);
    EventAdjustmentList_00417de0_20260605();
    void OtApplyLossEventAdjustmentListDependency_20260605();
    int OtHasEventAdjustmentEntriesDependency_20260605() const;
};

struct TrailEventContextSource_004163c0 {
    void OtPrimeActiveTrailEventContext_004163c0_RealCpp();
};

struct TrailEventRunner_00417de0_20260605 {
    char reserved_00[6];
    short message_count;

    void OtPrimeActiveTrailEventContextDependency_20260605();
    void OtRunTheftEventSlotPointer_20260605_ReccmpWip();
};
#pragma pack(pop)

extern "C" JourneyState_00417de0_20260605* g_journeyState;
extern "C" void* g_resourceModule;
extern "C" char g_trailEventMessageBuffer[];
extern "C" void* g_trailEventDialogWindow;
extern "C" const char g_theftCountFormat_00417de0[] = "%d %s";

#pragma code_seg(".otsem")

void* __cdecl EventAdjustmentList_00417de0_20260605::operator new(
    unsigned int bytes)
{
    return OtAllocateNewBlock_RealCpp(bytes);
}

EventAdjustmentList_00417de0_20260605::
    EventAdjustmentList_00417de0_20260605()
{
    OtClearEventAdjustmentList_RealCpp(entries);
}

void EventAdjustmentList_00417de0_20260605::
    OtApplyLossEventAdjustmentListDependency_20260605()
{
    reinterpret_cast<TradeAdjustmentList_00427d70*>(this)
        ->OtApplyLossEventAdjustmentList_Product_0041a660();
}

int EventAdjustmentList_00417de0_20260605::
    OtHasEventAdjustmentEntriesDependency_20260605() const
{
    return OtHasEventAdjustmentEntries_RealCpp(entries);
}

void TrailEventRunner_00417de0_20260605::
    OtPrimeActiveTrailEventContextDependency_20260605()
{
    reinterpret_cast<TrailEventContextSource_004163c0*>(this)
        ->OtPrimeActiveTrailEventContext_004163c0_RealCpp();
}

#pragma optimize("s", off)
#pragma optimize("t", on)

void TrailEventRunner_00417de0_20260605::
    OtRunTheftEventSlotPointer_20260605_ReccmpWip()
{
    char unit_text[40];
    char quantity_text[40];
    TrailEventRunner_00417de0_20260605* event = this;
    int suppress_message = 0;
    short item_slot;
    EventAdjustmentList_00417de0_20260605* adjustments =
        new EventAdjustmentList_00417de0_20260605;

    switch (static_cast<short>(OtRandomBelow_RealCpp(4))) {
    case 0:
        {
            short* stolen_oxen = adjustments->entries;
            *stolen_oxen =
                static_cast<short>(OtRandomBelow_RealCpp(
                    g_journeyState->oxen_count) + 1);
            item_slot = 0;
            if (OtRandomBelow_RealCpp(4) == 0) {
                g_journeyState->ox_sick = 0;
            }
            if (g_journeyState->oxen_count == *stolen_oxen) {
                g_journeyState->ox_sick = 0;
                g_journeyState->route_stop_flags =
                    static_cast<unsigned char>(
                        g_journeyState->route_stop_flags | 1);
            }
        }
        break;

    case 1:
        {
            short amount =
                static_cast<short>(OtRandomBelow_RealCpp(
                    g_journeyState->clothing) + 1);
            adjustments->entries[1] = amount;
            item_slot = 1;
        }
        break;

    case 2:
        item_slot = 2;
        adjustments->entries[2] =
            static_cast<short>(OtRandomBelow_RealCpp(100) + 1);
        break;

    case 3:
        item_slot = 6;
        adjustments->entries[6] =
            static_cast<short>(OtRandomBelow_RealCpp(100) + 1);
        break;
    }

    adjustments->OtApplyLossEventAdjustmentListDependency_20260605();
    if (adjustments->OtHasEventAdjustmentEntriesDependency_20260605() == 0) {
        item_slot = 7;
        adjustments->entries[7] =
            static_cast<short>(OtRandomBelow_RealCpp(100) + 1);
        adjustments->OtApplyLossEventAdjustmentListDependency_20260605();
        if (g_journeyState->cash_cents < 100) {
            --adjustments->entries[7];
            g_journeyState->cash_cents += 100;
            if (adjustments->entries[7] < 1) {
                suppress_message = 1;
            }
        }
    }

    if (suppress_message == 0) {
        event->OtPrimeActiveTrailEventContextDependency_20260605();
        LoadStringA(
            g_resourceModule,
            (adjustments->entries[item_slot] > 1) + 900 + item_slot * 2,
            unit_text,
            0x27);
        wsprintfA(
            quantity_text,
            g_theftCountFormat_00417de0,
            static_cast<int>(adjustments->entries[item_slot]),
            unit_text);
        g_trailEventRuntimeState.event_argument_pointer = quantity_text;
        g_trailEventRuntimeState.
            OtFormatGameMessageText_0001ac80_ProductWip(0x338);
        if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
            event->message_count == 1) {
            SendMessageA(
                g_trailEventDialogWindow,
                0x477,
                static_cast<unsigned short>(event->message_count),
                reinterpret_cast<long>(g_trailEventMessageBuffer));
        }
    }

    delete adjustments;
}

#pragma optimize("", on)
#pragma code_seg()

// Product-tree semantic candidate for OtRunWagonFireEvent @ 0x00418040.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

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

void __cdecl operator delete(void* block);

struct TrailEventContextSource_004163c0 {
    void OtPrimeActiveTrailEventContext_004163c0_RealCpp();
};

struct TrailEventTextRuntime_0041aac0_20260603 {
    char* OtFormatGameMessageText_0001ac80_ProductWip(int string_id);
};

struct EventAdjustmentListFormatter_0041a320 {
    short OtFormatEventAdjustmentList_0041a320_RealCpp(
        const char* person_event_text);
};

#pragma pack(push, 1)
struct JourneyState_00418040_20260604 {
    char reserved_000[0x9a];
    short clothing;
    short bullets;
    short wagon_wheels;
    short wagon_axles;
    short wagon_tongues;
    short food_whole;
    short food_fraction;
};

struct EventAdjustmentList_00418040_20260604 {
    short entries[13];

    EventAdjustmentList_00418040_20260604();
    void OtApplyLossEventAdjustmentListDependency_20260604();
    short OtFormatEventAdjustmentListDependency_20260604(
        const char* person_event_text);
};

struct TrailEventTextState_00418040_20260604 {
    void OtFormatGameMessageTextDependency_20260604(int string_id);
};

struct TrailEventRunner_00418040_20260604 {
    char reserved_00[6];
    short message_count;

    void OtPrimeActiveTrailEventContextDependency_20260604();
    void OtRunWagonFireEvent_20260604_RealCpp();
};
#pragma pack(pop)

extern "C" JourneyState_00418040_20260604* g_journeyState;
extern "C" TrailEventTextState_00418040_20260604 g_trailEventRuntimeState;
extern "C" void* g_trailEventDialogWindow;
extern "C" char g_trailEventMessageBuffer[];
extern "C" short g_wagonFireFormattedAdjustmentCount_00418040_20260604 = 0;
extern "C" const char g_wagonFireDestroyedItemsText_00418040_20260604[] = "";

#pragma code_seg(".otsem")
EventAdjustmentList_00418040_20260604::
    EventAdjustmentList_00418040_20260604()
{
    OtClearEventAdjustmentList_RealCpp(entries);
}

short EventAdjustmentList_00418040_20260604::
    OtFormatEventAdjustmentListDependency_20260604(
        const char* person_event_text)
{
    return reinterpret_cast<EventAdjustmentListFormatter_0041a320*>(this)->
        OtFormatEventAdjustmentList_0041a320_RealCpp(person_event_text);
}

void TrailEventTextState_00418040_20260604::
    OtFormatGameMessageTextDependency_20260604(int string_id)
{
    reinterpret_cast<TrailEventTextRuntime_0041aac0_20260603*>(this)->
        OtFormatGameMessageText_0001ac80_ProductWip(string_id);
}

void TrailEventRunner_00418040_20260604::
    OtPrimeActiveTrailEventContextDependency_20260604()
{
    reinterpret_cast<TrailEventContextSource_004163c0*>(this)->
        OtPrimeActiveTrailEventContext_004163c0_RealCpp();
}
#pragma code_seg()

#pragma optimize("s", off)
#pragma optimize("t", on)

// Rolls which supplies burn in the wagon fire, applies the clamped losses, and
// posts the formatted event message when any loss survived clamping.
void TrailEventRunner_00418040_20260604::
    OtRunWagonFireEvent_20260604_RealCpp()
{
    EventAdjustmentList_00418040_20260604* adjustments =
        new EventAdjustmentList_00418040_20260604;

    if (OtRandomBelow_RealCpp(2) != 0) {
        adjustments->entries[3] =
            static_cast<short>(OtRandomBelow_RealCpp(
                g_journeyState->wagon_wheels + 1));
    }
    if (OtRandomBelow_RealCpp(2) != 0) {
        adjustments->entries[6] =
            static_cast<short>(OtRandomBelow_RealCpp(
                static_cast<short>(
                    g_journeyState->food_whole +
                    g_journeyState->food_fraction) +
                1));
    }
    if (OtRandomBelow_RealCpp(2) != 0) {
        adjustments->entries[4] =
            static_cast<short>(OtRandomBelow_RealCpp(
                g_journeyState->wagon_axles + 1));
    }
    if (OtRandomBelow_RealCpp(2) != 0) {
        adjustments->entries[5] =
            static_cast<short>(OtRandomBelow_RealCpp(
                g_journeyState->wagon_tongues + 1));
    }
    if (OtRandomBelow_RealCpp(2) != 0) {
        adjustments->entries[2] =
            static_cast<short>(OtRandomBelow_RealCpp(
                g_journeyState->bullets + 1));
    }
    if (OtRandomBelow_RealCpp(2) != 0) {
        adjustments->entries[1] =
            static_cast<short>(OtRandomBelow_RealCpp(
                g_journeyState->clothing + 1));
    }

    OtPrimeActiveTrailEventContextDependency_20260604();
    adjustments->OtApplyLossEventAdjustmentListDependency_20260604();
    if (OtHasEventAdjustmentEntries_RealCpp(adjustments->entries) != 0) {
        g_wagonFireFormattedAdjustmentCount_00418040_20260604 =
            adjustments->OtFormatEventAdjustmentListDependency_20260604(
                g_wagonFireDestroyedItemsText_00418040_20260604);
        g_trailEventRuntimeState.OtFormatGameMessageTextDependency_20260604(
            0x33c);

        if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
            message_count == 1) {
            SendMessageA(
                g_trailEventDialogWindow,
                0x477,
                static_cast<unsigned short>(message_count),
                reinterpret_cast<long>(g_trailEventMessageBuffer));
        }
    }

    delete adjustments;
}

#pragma optimize("", on)

// Product-tree semantic closure for OtRunPartyDeathEvent @ 0x004168d0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "trail_event_text_runtime.h"

extern "C" __declspec(dllimport) int __cdecl wsprintfA(
    char* buffer,
    const char* format,
    ...);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    void* window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" char* __cdecl strcpy(char* destination, const char* source);
extern "C" void* __cdecl memset(void* destination, int value, unsigned int size);
#pragma intrinsic(strcpy)
#pragma intrinsic(memset)

extern "C" short __fastcall OtCountLivingPartyMembers_RealCpp(
    const void* party);
extern "C" void __stdcall OtAddTrailDelayDays_00416380_RealCpp(short days);

struct TrailEventContextSource_004163c0 {
    void OtPrimeActiveTrailEventContext_004163c0_RealCpp();
};

#pragma pack(push, 1)
struct JourneyState_004168d0_20260604 {
    char reserved_000[0xc0];
    char party_member_names[5][15];
};

struct TrailEventRunner_004168d0_20260604 {
    char reserved_00[6];
    short message_count;
    char reserved_08[0x22];
    int party_member_death_pending[5];

    void OtPrimeActiveTrailEventContextDependency_004168d0();
    void OtSetTrailDelayDaysDependency_004168d0(short days);
    void OtRunPartyDeathEvent_20260604_RealCpp();
};

struct FollowupNoFoodEvent_004168d0_20260604 {
    char reserved_00[0x2a];
    int pending_member_flag;
};
#pragma pack(pop)

extern "C" JourneyState_004168d0_20260604* g_journeyState;
extern "C" void* g_trailEventDialogWindow;
extern "C" char g_trailEventMessageBuffer[];
extern "C" FollowupNoFoodEvent_004168d0_20260604* g_noFoodEvent_004168d0 = 0;

extern "C" const char g_emptyString_004395ac[];

extern "C" const char g_partyDeathOneFormat_00439ce0_20260604[] =
    "%s has drowned.";
extern "C" const char g_partyDeathTwoFormat_00439cc8_20260604[] =
    "%s and %s have drowned.";
extern "C" const char g_partyDeathThreeFormat_00439cac_20260604[] =
    "%s, %s and %s have drowned.";
extern "C" const char g_partyDeathFourFormat_00439c8c_20260604[] =
    "%s, %s, %s and %s have drowned.";
extern "C" const char g_partyDeathFiveFormat_00439c68_20260604[] =
    "%s, %s, %s, %s and %s have drowned.";

#pragma code_seg(".otsem")
void TrailEventRunner_004168d0_20260604::
    OtPrimeActiveTrailEventContextDependency_004168d0()
{
    reinterpret_cast<TrailEventContextSource_004163c0*>(this)->
        OtPrimeActiveTrailEventContext_004163c0_RealCpp();
}

void TrailEventRunner_004168d0_20260604::
    OtSetTrailDelayDaysDependency_004168d0(short days)
{
    OtAddTrailDelayDays_00416380_RealCpp(days);
}
#pragma code_seg()

#pragma optimize("s", off)
#pragma optimize("t", on)

// Collects queued party-death flags, formats the grouped drowned-member text,
// clears the queue, posts the trail event, and arms the follow-up event.
void TrailEventRunner_004168d0_20260604::
    OtRunPartyDeathEvent_20260604_RealCpp()
{
    char text_and_names[0x78];
    char** name_cursor = reinterpret_cast<char**>(text_and_names);
    int member_count = 0;
    int member_index = 4;
    int* pending = &party_member_death_pending[4];

    do {
        if (*pending != 0) {
            *name_cursor =
                reinterpret_cast<char*>(g_journeyState) +
                static_cast<short>(member_index) * 15 + 0xc0;
            ++name_cursor;
            ++member_count;
        }
        --pending;
        --member_index;
    } while (member_index >= 0);

    if (member_count != 0) {
        char** names = reinterpret_cast<char**>(text_and_names);
        switch (member_count) {
        case 1:
            wsprintfA(
                text_and_names,
                g_partyDeathOneFormat_00439ce0_20260604,
                names[0]);
            break;
        case 2:
            wsprintfA(
                text_and_names,
                g_partyDeathTwoFormat_00439cc8_20260604,
                names[0],
                names[1]);
            break;
        case 3:
            wsprintfA(
                text_and_names,
                g_partyDeathThreeFormat_00439cac_20260604,
                names[0],
                names[1],
                names[2]);
            break;
        case 4:
            wsprintfA(
                text_and_names,
                g_partyDeathFourFormat_00439c8c_20260604,
                names[0],
                names[1],
                names[2],
                names[3]);
            break;
        case 5:
            wsprintfA(
                text_and_names,
                g_partyDeathFiveFormat_00439c68_20260604,
                names[0],
                names[1],
                names[2],
                names[3],
                names[4]);
            break;
        }

        strcpy(g_trailEventRuntimeState.primary_text, text_and_names);
        strcpy(
            g_trailEventRuntimeState.secondary_text,
            g_emptyString_004395ac);

        memset(
            party_member_death_pending,
            0,
            sizeof(party_member_death_pending));
    }

    OtPrimeActiveTrailEventContextDependency_004168d0();
    OtSetTrailDelayDaysDependency_004168d0(1);

    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
        message_count == 1) {
        SendMessageA(
            g_trailEventDialogWindow,
            0x477,
            static_cast<unsigned short>(message_count),
            reinterpret_cast<long>(g_trailEventMessageBuffer));
    }

    g_noFoodEvent_004168d0->pending_member_flag = 1;
}

#pragma optimize("", on)

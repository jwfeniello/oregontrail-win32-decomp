// Product-tree semantic recovery of OtRunOxDeathEvent @ 0x004164f0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "trail_event_context_source.h"
#include "trail_event_text_runtime.h"

extern "C" void* g_trailEventDialogWindow;
extern "C" char g_trailEventMessageBuffer[];
extern "C" short __fastcall OtCountLivingPartyMembers_RealCpp(
    const void* party);
extern "C" __declspec(dllimport) unsigned long __stdcall SendMessageA(
    void* window,
    unsigned int message,
    unsigned int wparam,
    long lparam);

#pragma pack(push, 1)
struct JourneyState_004164f0_20260716 {
    char reserved_000[0x5a];
    unsigned short route_stop_flags;
    char reserved_05c[0x3a];
    short oxen_count;
    short ox_sick;
};

struct TrailEventTextState_004164f0_20260716 {
    void* first_argument;

    void OtFormatGameMessageTextDependency_20260716(int string_id);
};

struct TrailEventRunner_004164f0_20260716 {
    char reserved_00[6];
    short message_count;

    void OtPrimeActiveTrailEventContextDependency_20260716();
    void OtRunOxDeathEvent_20260716_RealCpp();
};
#pragma pack(pop)

extern "C" JourneyState_004164f0_20260716* g_journeyState;

void TrailEventRunner_004164f0_20260716::
    OtPrimeActiveTrailEventContextDependency_20260716()
{
    reinterpret_cast<TrailEventContextSource_004163c0*>(this)->
        OtPrimeActiveTrailEventContext_004163c0_RealCpp();
}

void TrailEventTextState_004164f0_20260716::
    OtFormatGameMessageTextDependency_20260716(int string_id)
{
    reinterpret_cast<TrailEventTextRuntime_0041aac0_20260603*>(this)->
        OtFormatGameMessageText_0001ac80_ProductWip(string_id);
}

#pragma optimize("s", off)
#pragma optimize("t", on)

// Clears the sick-ox state, removes the dead ox team, clears a stale no-oxen
// stop flag while teams remain, and posts the formatted trail-event message.
void TrailEventRunner_004164f0_20260716::
    OtRunOxDeathEvent_20260716_RealCpp()
{
    TrailEventRunner_004164f0_20260716* event = this;
    short no_oxen_flag;
    short route_stop_flags;
    short oxen_remaining;
    JourneyState_004164f0_20260716* state_journey;
    short* stop_flags;
    short* oxen_count;

    event->OtPrimeActiveTrailEventContextDependency_20260716();
    reinterpret_cast<TrailEventTextState_004164f0_20260716*>(
        &g_trailEventRuntimeState)->
            OtFormatGameMessageTextDependency_20260716(0x2e5);
    g_journeyState->ox_sick = 0;

    oxen_count = &g_journeyState->oxen_count;
    state_journey = g_journeyState;
    oxen_remaining = *oxen_count;
    --oxen_remaining;
    stop_flags = reinterpret_cast<short*>(&state_journey->route_stop_flags);
    route_stop_flags = *stop_flags;
    no_oxen_flag = static_cast<short>(route_stop_flags & 1);

    if (no_oxen_flag != 0) {
        if (oxen_remaining > 0) {
            if (no_oxen_flag != 0) {
                *stop_flags = static_cast<short>(route_stop_flags ^ 1);
            }
            if (state_journey->ox_sick != 0) {
                state_journey->ox_sick = 0;
                --oxen_remaining;
            }
        }
    }

    *oxen_count = oxen_remaining;
    if (g_journeyState->oxen_count == 0) {
        *reinterpret_cast<unsigned char*>(&g_journeyState->route_stop_flags) =
            static_cast<unsigned char>(
                *reinterpret_cast<unsigned char*>(
                    &g_journeyState->route_stop_flags) | 1);
    }

    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
        event->message_count == 1) {
        SendMessageA(
            g_trailEventDialogWindow,
            0x477,
            static_cast<unsigned short>(event->message_count),
            reinterpret_cast<long>(g_trailEventMessageBuffer));
    }
}

#pragma optimize("", on)

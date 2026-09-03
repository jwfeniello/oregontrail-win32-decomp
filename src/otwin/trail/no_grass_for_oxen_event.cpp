// No-grass-for-oxen trail event recovered from Oregon32.exe.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This source must be compiled with 32-bit MSVC."
#endif

extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* instance,
    unsigned int string_id,
    char* buffer,
    int buffer_max);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    void* window,
    unsigned int message,
    unsigned int wparam,
    long lparam);

#pragma pack(push, 1)
struct JourneyState_004177e0 {
    char reserved_000[0x96];
    short oxen_count;
};

struct TrailEventTextRuntime_0041aac0_20260603 {
    void* first_argument;

    void OtSetTrailEventTextDependency_RealCpp(int string_id);
};

struct TrailEventRunner_00416c50 {
    char reserved_00[6];
    short message_count;

    void OtPrimeActiveTrailEventContextDependency_RealCpp();
    void OtRunNoGrassForOxenEvent_RealCpp();
};
#pragma pack(pop)

extern "C" JourneyState_004177e0* g_journeyState;
extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" void* g_trailEventTextArgument;
extern "C" void* g_trailEventDialogWindow;
extern "C" char g_trailEventMessageBuffer[];
extern "C" short __fastcall OtCountLivingPartyMembers_RealCpp(
    const void* party);
extern "C" TrailEventTextRuntime_0041aac0_20260603
    g_trailEventRuntimeState;

#pragma optimize("s", off)
#pragma optimize("t", on)

// Formats the current ox count as "ox" or "oxen", then posts the event text.
void TrailEventRunner_00416c50::OtRunNoGrassForOxenEvent_RealCpp()
{
    char ox_text[12];
    TrailEventRunner_00416c50* event = this;

    if (g_journeyState->oxen_count != 0) {
        event->OtPrimeActiveTrailEventContextDependency_RealCpp();

        LoadStringA(
            g_applicationModule_00405a40_20260603,
            (g_journeyState->oxen_count > 1) + 0x384,
            ox_text,
            9);

        g_trailEventTextArgument = ox_text;
        g_trailEventRuntimeState.OtSetTrailEventTextDependency_RealCpp(0x320);

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

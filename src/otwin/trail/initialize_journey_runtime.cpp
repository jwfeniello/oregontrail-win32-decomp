// Product-tree semantic recovery of OtInitializeJourneyRuntime @ 0x0041a120.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

extern "C" __declspec(dllimport) void* __stdcall FindResourceA(
    void* module,
    const void* resource_name,
    const void* resource_type);
extern "C" __declspec(dllimport) void* __stdcall LoadResource(
    void* module,
    void* resource_info);
extern "C" __declspec(dllimport) void* __stdcall LockResource(
    void* resource_handle);

extern "C" void* __cdecl memset(
    void* destination,
    int value,
    unsigned int count);
extern void* __cdecl operator new(unsigned int bytes);

#pragma intrinsic(memset)
#pragma comment(lib, "kernel32.lib")

struct TrailCalendarNameTriple_00419430 {
    TrailCalendarNameTriple_00419430* OtCopyTrailDateNameTriple_RealCpp();
};

struct JourneyStateDefaults_0041a000_20260525 {
    void OtJourneyInitStateDefaultsMaskClosedFELTDR_0041a000();
};

struct GraveEpitaphState_00411fd0_20260603;

extern "C" void* g_journeyState;
extern "C" void* g_activeRouteDescriptor;
extern "C" void* g_graveSiteRuntime;
extern "C" void* g_resourceModule;
extern "C" void* g_cachedTrailResourceHandle;

extern "C" void __cdecl OtInitTrailEventTable_00018230_RealCpp();
extern "C" void __stdcall OtLoadRouteDescriptor_RealCpp(short route_id);
extern "C" void __fastcall OtRefreshGraveEpitaphIniCache_00411fd0_RealCpp(
    GraveEpitaphState_00411fd0_20260603* state);

#pragma data_seg(".otdat")
extern "C" void* g_cachedTrailWeatherResourceData_0041a120_ProductWip = 0;
#pragma data_seg()

#pragma code_seg(".otsem")
extern "C" __declspec(allocate(".otsem"))
const char g_weatherResourceName_0041a120_ProductWip[] = "WEATHER";

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" void __cdecl OtInitializeJourneyRuntime_0001a120_ProductWip()
{
    if (g_journeyState == 0) {
        g_journeyState = operator new(0x158);
        if (g_journeyState != 0) {
            memset(g_journeyState, 0, 0x158);
            reinterpret_cast<TrailCalendarNameTriple_00419430*>(
                g_journeyState)->OtCopyTrailDateNameTriple_RealCpp();
        }
    }

    if (g_activeRouteDescriptor == 0) {
        g_activeRouteDescriptor = operator new(0x13c);
        if (g_activeRouteDescriptor != 0) {
            memset(g_activeRouteDescriptor, 0, 0x13c);
        }
    }

    if (g_graveSiteRuntime == 0) {
        g_graveSiteRuntime = operator new(0x48);
        if (g_graveSiteRuntime != 0) {
            memset(g_graveSiteRuntime, 0, 0x48);
            *static_cast<short*>(g_graveSiteRuntime) = -1;
        }
    }

    void* resource_info = FindResourceA(
        g_resourceModule,
        g_weatherResourceName_0041a120_ProductWip,
        reinterpret_cast<const void*>(0x4b0));
    g_cachedTrailResourceHandle =
        LoadResource(g_resourceModule, resource_info);
    g_cachedTrailWeatherResourceData_0041a120_ProductWip =
        LockResource(g_cachedTrailResourceHandle);

    OtInitTrailEventTable_00018230_RealCpp();
    if (g_journeyState != 0) {
        reinterpret_cast<JourneyStateDefaults_0041a000_20260525*>(
            g_journeyState)->
                OtJourneyInitStateDefaultsMaskClosedFELTDR_0041a000();
    }
    if (g_activeRouteDescriptor != 0) {
        OtLoadRouteDescriptor_RealCpp(0);
    }
    if (g_graveSiteRuntime != 0) {
        OtRefreshGraveEpitaphIniCache_00411fd0_RealCpp(
            reinterpret_cast<GraveEpitaphState_00411fd0_20260603*>(
                g_graveSiteRuntime));
    }
}

#pragma optimize("", on)
#pragma code_seg()

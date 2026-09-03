// Semantic recovery of trail scene phase callback dispatch.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct TrailScenePhaseCallback_00419200 {
    virtual void OtTickPhaseDependency_00419200(int tick);
    virtual void OtDispatchSelectedPhaseDependency_00419200();

    char reserved_04[4];
    short enabled;
    short phase;
    char reserved_0c[0x1c];
    short gated;
};

struct TrailScenePhaseRuntime_00419200 {
    char reserved_00[0x5a];
    short suppress_gated_callbacks;
};
#pragma pack(pop)

typedef void (__fastcall *TrailScenePhaseDispatchProc_00419200)(
    TrailScenePhaseCallback_00419200* callback);

struct TrailScenePhaseVTable_00419200 {
    void* tick;
    TrailScenePhaseDispatchProc_00419200 dispatch;
};

extern "C" TrailScenePhaseCallback_00419200*
    g_trailScenePhaseCallbacks_00419200[0x23] = {0};
extern "C" void* g_trailScenePhaseOwnerWindow_00419200 = 0;
extern "C" TrailScenePhaseRuntime_00419200*
    g_trailScenePhaseRuntime_00419200 = 0;
extern "C" short g_trailScenePhaseDispatchFlag_00419200 = 0;

extern "C" int __cdecl OtIsTrailOverlayActive_RealCpp();

extern "C" int __cdecl OtDispatchTrailScenePhaseCallbacks_00419200_RealCpp(
    void* owner_window,
    int phase)
{
    int zero = 0;
    short callback_index;
    int any_dispatched;

    callback_index = 1;
    any_dispatched = 0;

    g_trailScenePhaseOwnerWindow_00419200 = owner_window;
    do {
        TrailScenePhaseCallback_00419200** slot =
            &g_trailScenePhaseCallbacks_00419200[callback_index];
        TrailScenePhaseCallback_00419200* callback = *slot;

        if (callback->enabled != zero && callback->phase == phase) {
            if (callback->gated == zero ||
                (OtIsTrailOverlayActive_RealCpp() == 0 &&
                 g_trailScenePhaseRuntime_00419200
                         ->suppress_gated_callbacks == zero)) {
                TrailScenePhaseCallback_00419200* selected_callback =
                    *slot;
                g_trailScenePhaseDispatchFlag_00419200 = (short)zero;
                any_dispatched = 1;
                selected_callback
                    ->OtDispatchSelectedPhaseDependency_00419200();
            }

            (*slot)->OtTickPhaseDependency_00419200(zero);
        }

        ++callback_index;
    } while (callback_index <= 0x22);

    return any_dispatched;
}

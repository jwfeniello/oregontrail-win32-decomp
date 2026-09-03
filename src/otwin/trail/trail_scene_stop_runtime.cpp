// Canonical Product implementation of OtHandleTrailSceneStop @ 0x0042a480.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct JourneyStopArrivalState_0042a480 {
    char reserved_000[0x5c];
    short applied_miles;
    char reserved_05e[0x2c];
    short pending_miles;
};

struct RouteDescriptor_00424e80 {
    unsigned short route_stop_index;
    char reserved_002[0x122];
    unsigned short location_bitmap_resource_ids[6];

    char* OtFormatLocationArrivalMessage_00424e80_RealCpp();
};

struct TrailJournalState_0040f950 {
    void OtAppendTrailJournalText_0040f950_ProductWip(
        const char* pending_text);
};

struct LabeledBitmapDisplay_00405f00 {
    void OtUpdateLabeledBitmapDisplay_RealCpp(
        unsigned int bitmap_resource_id,
        unsigned int label_string_id,
        int preserve_label_visibility);
};

struct TrailOverlayWindow_00405df0 {
    void OtPlayCurrentRouteAudioCue_00405e00_ProductWip(
        void* owner_window);
};

struct TrailUiState_0042b370 {
    void OtPauseTrailTravel_RealCpp(void* owner_window);
    void OtRefreshTrailStatusPanel_0042d5d0_ProductWip(
        void* owner_window);
};

struct TrailSceneStopState_0042a480 {
    char reserved_000[0x0788];
    LabeledBitmapDisplay_00405f00* trail_stop_display;
    char reserved_78c[0x0280];
    TrailJournalState_0040f950* trail_journal;
    char reserved_a10[0x0c];
    int stop_scene_audio_enabled;

    int OtHandleTrailSceneStop_RealCpp(void* owner_window);
};
#pragma pack(pop)

extern "C" JourneyStopArrivalState_0042a480* g_journeyState;
extern "C" RouteDescriptor_00424e80* g_activeRouteDescriptor;
extern "C" int g_titleThemeEnabled_004390ec;

extern "C" unsigned int __fastcall
OtSelectRouteLocationBitmapResourceId_RealCpp(
    RouteDescriptor_00424e80* route);

// The accepted semantic 0x41a100 body still resides under _exact. This Product
// bridge implements its recovered state transition without linking that TU.
#pragma code_seg(".otsem")
extern "C" void __fastcall
OtFlushPendingMileageAdjustment_0041a100_ProductBridge(
    JourneyStopArrivalState_0042a480* state)
{
    short pending_miles = state->pending_miles;
    state->pending_miles = 0;
    state->applied_miles =
        static_cast<short>(state->applied_miles + pending_miles);
}
#pragma code_seg()

#pragma optimize("s", off)
#pragma optimize("t", on)

int TrailSceneStopState_0042a480::OtHandleTrailSceneStop_RealCpp(
    void* owner_window)
{
    register TrailSceneStopState_0042a480* state = this;

    OtFlushPendingMileageAdjustment_0041a100_ProductBridge(g_journeyState);
    state->trail_journal->OtAppendTrailJournalText_0040f950_ProductWip(
        g_activeRouteDescriptor->
            OtFormatLocationArrivalMessage_00424e80_RealCpp());

    state->trail_stop_display->OtUpdateLabeledBitmapDisplay_RealCpp(
        OtSelectRouteLocationBitmapResourceId_RealCpp(
            g_activeRouteDescriptor),
        ((g_activeRouteDescriptor->route_stop_index + 0x0d) << 4),
        0);

    register void* window = owner_window;
    reinterpret_cast<TrailUiState_0042b370*>(state)->
        OtPauseTrailTravel_RealCpp(window);
    reinterpret_cast<TrailUiState_0042b370*>(state)->
        OtRefreshTrailStatusPanel_0042d5d0_ProductWip(window);

    if (g_titleThemeEnabled_004390ec != 0 &&
        state->stop_scene_audio_enabled != 0) {
        reinterpret_cast<TrailOverlayWindow_00405df0*>(
            state->trail_stop_display)->
                OtPlayCurrentRouteAudioCue_00405e00_ProductWip(window);
    }

    return 0;
}

#pragma optimize("", on)

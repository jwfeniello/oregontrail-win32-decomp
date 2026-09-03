// Product semantic implementation of OtPaintTrailScene @ 0x0042aad0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

extern "C" __declspec(dllimport) int __stdcall GetClientRect(
    void* window,
    void* rect);
extern "C" __declspec(dllimport) void* __stdcall CreateRectRgn(
    int left,
    int top,
    int right,
    int bottom);
extern "C" __declspec(dllimport) int __stdcall SelectClipRgn(
    void* dc,
    void* region);
extern "C" __declspec(dllimport) int __stdcall ExcludeClipRect(
    void* dc,
    int left,
    int top,
    int right,
    int bottom);
extern "C" __declspec(dllimport) int __stdcall DeleteObject(void* object);

extern "C" int g_trailProgressStopPending;
extern "C" short g_activeTrailEventScene;

#pragma pack(push, 1)
struct Rect_0042aad0_20260605 {
    int left;
    int top;
    int right;
    int bottom;
};

struct PositionedBitmap_0042aad0_20260605 {
    char opaque[1];

    int OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        void* dc,
        int clip_x,
        int clip_y);
};

struct TrailOverlayWindow_0042aad0_20260605 {
    void OtShowTrailOverlayWindowDependency_20260605(
        void* owner,
        void* dc);
    void OtHideTrailOverlayWindowDependency_20260605();
};

struct TrailProgressMeter_0042aad0_20260605 {
    char reserved_000[0x40];
    int left;
    int top;
    int right;
    int bottom;

    void OtResetTrailProgressMeterDependency_20260605(
        void* owner,
        void* dc,
        int progress);
    void OtAdvanceTrailProgressMeterDependency_20260605(
        void* owner,
        int progress);
};

struct TrailDiaryWindow_0042aad0_20260605 {
    char reserved_000[0x10];
    int left;
    int top;
    int right;
    int bottom;

    void OtShowWindowIfHiddenDependency_20260605(void* dc);
    void OtMoveEditCaretToEndDependency_20260605();
};

struct TrailTravelScene_0042aad0_20260605 {
    char reserved_000[0x2a0];
    int clip_left;
    int clip_top;
    int clip_right;
    int clip_bottom;

    void OtRenderTrailTravelSceneDependency_20260605(
        void* dc,
        void* owner,
        unsigned int travelled_distance,
        unsigned int total_distance,
        int overlay_phase,
        int caption_id);
};

struct RiverCrossingView_0042aad0_20260605 {
    void OtShowRiverCrossingViewDependency_20260605(
        void* dc,
        void* render_owner);
};

struct TrailPaintState_0042aad0_20260605 {
    char reserved_000[0x788];
    TrailOverlayWindow_0042aad0_20260605* overlay_window;
    TrailProgressMeter_0042aad0_20260605* progress_meter;
    char reserved_790[0x250];
    PositionedBitmap_0042aad0_20260605 background;
    char reserved_9e1[0xa0c - 0x9e1];
    TrailDiaryWindow_0042aad0_20260605* diary_window;
    TrailTravelScene_0042aad0_20260605* travel_scene;
    RiverCrossingView_0042aad0_20260605* river_view;
    char reserved_a18[8];
    int scene_mode;
    int overlay_phase_active;
    char reserved_a28[8];
    void* render_owner;
    char reserved_a34[0x14];
    unsigned int travelled_distance;
    unsigned int total_distance;
    char reserved_a50[4];
    int overlay_phase;

    void OtPaintTrailScene_20260605_RealCpp(void* owner_window, void* dc);
    void OtRecomputeTrailTravelMetricsDependency_20260605();
    void OtComputeTrailProgressRangeDependency_20260605(
        void* scratch,
        int* progress);
    void OtDrawTrailSceneCaptionDependency_20260605(void* dc);
    void OtDrawTrailConditionGaugeDependency_20260605(void* dc);
};

struct PositionedBitmap_0040b7b0_Semantic {
    int OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        void* dc,
        int source_x,
        int source_y);
};

struct TrailProgressView_0042c0b0_Product {
    void OtComputeTrailProgressRange_0042c0b0_Product(
        int* first_mile,
        int* last_mile);
};

struct TrailSceneCaptionState_0042af80_20260603 {
    void OtDrawTrailSceneCaptionDirect_0042af80_RealCpp(void* dc);
};

struct TrailConditionGaugeState_0042ad80_ProductWip {
    void OtDrawTrailConditionGauge_0042ad80_ProductWip(void* dc);
};

struct TrailOverlayWindow_00405df0 {
    void OtShowTrailOverlayWindow_RealCpp(void* owner_window, void* dc);
    void OtHideTrailOverlayWindow_RealCpp();
};

struct TrailMapProgressState_00405f70 {
    void OtResetTrailMapProgressLine_RealCpp(
        void* map_window,
        void* dc,
        int travel_progress);
};

struct TrailMapProgressLine_00406370_Product {
    void OtAdvanceTrailMapProgressLine_00406370_Product(
        void* map_window,
        int travel_progress);
};

struct WindowVisibilityState_0040fb50 {
    void OtShowWindowIfHidden_RealCpp(void* unused);
};

struct EditCaretState_0040feb0_37pct {
    void OtMoveEditCaretToEndAlt19_0040feb0_37pct();
};

struct TrailTravelScene_00006510 {
    void OtRenderTrailTravelScene_00006510_RealCpp(
        void* dc,
        void* render_owner,
        unsigned int travelled_distance,
        unsigned int total_distance,
        int overlay_phase,
        int caption_id);
};

struct RiverCrossingView_00427f00_43pct {
    void OtShowRiverCrossingViewAlt2_00427f00_43pct(
        void* dc,
        void* owner);
};
#pragma pack(pop)

extern "C" void __fastcall OtRecomputeTrailTravelMetrics_0042ddc0_RealCpp(
    int state);

#pragma code_seg(".otsem")

void TrailPaintState_0042aad0_20260605::
    OtRecomputeTrailTravelMetricsDependency_20260605()
{
    OtRecomputeTrailTravelMetrics_0042ddc0_RealCpp(
        reinterpret_cast<int>(this));
}

void TrailPaintState_0042aad0_20260605::
    OtComputeTrailProgressRangeDependency_20260605(
        void* scratch,
        int* progress)
{
    reinterpret_cast<TrailProgressView_0042c0b0_Product*>(this)->
        OtComputeTrailProgressRange_0042c0b0_Product(
            static_cast<int*>(scratch),
            progress);
}

void TrailPaintState_0042aad0_20260605::
    OtDrawTrailSceneCaptionDependency_20260605(void* dc)
{
    reinterpret_cast<TrailSceneCaptionState_0042af80_20260603*>(this)->
        OtDrawTrailSceneCaptionDirect_0042af80_RealCpp(dc);
}

void TrailPaintState_0042aad0_20260605::
    OtDrawTrailConditionGaugeDependency_20260605(void* dc)
{
    reinterpret_cast<TrailConditionGaugeState_0042ad80_ProductWip*>(this)->
        OtDrawTrailConditionGauge_0042ad80_ProductWip(dc);
}

int PositionedBitmap_0042aad0_20260605::
    OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        void* dc,
        int source_x,
        int source_y)
{
    int result = reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(this)->
        OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
            dc,
            source_x,
            source_y);
    return result;
}

void TrailOverlayWindow_0042aad0_20260605::
    OtShowTrailOverlayWindowDependency_20260605(void* owner, void* dc)
{
    reinterpret_cast<TrailOverlayWindow_00405df0*>(this)->
        OtShowTrailOverlayWindow_RealCpp(owner, dc);
}

void TrailOverlayWindow_0042aad0_20260605::
    OtHideTrailOverlayWindowDependency_20260605()
{
    reinterpret_cast<TrailOverlayWindow_00405df0*>(this)->
        OtHideTrailOverlayWindow_RealCpp();
}

void TrailProgressMeter_0042aad0_20260605::
    OtResetTrailProgressMeterDependency_20260605(
        void* owner,
        void* dc,
        int progress)
{
    reinterpret_cast<TrailMapProgressState_00405f70*>(this)->
        OtResetTrailMapProgressLine_RealCpp(owner, dc, progress);
}

void TrailProgressMeter_0042aad0_20260605::
    OtAdvanceTrailProgressMeterDependency_20260605(
        void* owner,
        int progress)
{
    reinterpret_cast<TrailMapProgressLine_00406370_Product*>(this)->
        OtAdvanceTrailMapProgressLine_00406370_Product(owner, progress);
}

void TrailDiaryWindow_0042aad0_20260605::
    OtShowWindowIfHiddenDependency_20260605(void* dc)
{
    reinterpret_cast<WindowVisibilityState_0040fb50*>(this)->
        OtShowWindowIfHidden_RealCpp(dc);
}

void TrailDiaryWindow_0042aad0_20260605::
    OtMoveEditCaretToEndDependency_20260605()
{
    reinterpret_cast<EditCaretState_0040feb0_37pct*>(this)->
        OtMoveEditCaretToEndAlt19_0040feb0_37pct();
}

void TrailTravelScene_0042aad0_20260605::
    OtRenderTrailTravelSceneDependency_20260605(
        void* dc,
        void* owner,
        unsigned int travelled_distance,
        unsigned int total_distance,
        int overlay_phase,
        int caption_id)
{
    reinterpret_cast<TrailTravelScene_00006510*>(this)->
        OtRenderTrailTravelScene_00006510_RealCpp(
            dc,
            owner,
            travelled_distance,
            total_distance,
            overlay_phase,
            caption_id);
}

void RiverCrossingView_0042aad0_20260605::
    OtShowRiverCrossingViewDependency_20260605(
        void* dc,
        void* render_owner)
{
    reinterpret_cast<RiverCrossingView_00427f00_43pct*>(this)->
        OtShowRiverCrossingViewAlt2_00427f00_43pct(dc, render_owner);
}

#pragma code_seg()

#pragma optimize("s", off)
#pragma optimize("t", on)

// Paints the full trail HUD, travel viewport, stop overlay, or river view.
void TrailPaintState_0042aad0_20260605::OtPaintTrailScene_20260605_RealCpp(
    void* owner_window,
    void* dc)
{
    register TrailPaintState_0042aad0_20260605* state = this;
    register void* owner = owner_window;
    register void* device_context = dc;
    Rect_0042aad0_20260605 client_rect;
    int progress;
    int scratch;

    GetClientRect(owner, &client_rect);
    register void* clip_region = CreateRectRgn(
        client_rect.left,
        client_rect.top,
        client_rect.right,
        client_rect.bottom);
    SelectClipRgn(device_context, clip_region);

    ExcludeClipRect(
        device_context,
        state->diary_window->left + 3,
        state->diary_window->top + 3,
        state->diary_window->right - 3,
        state->diary_window->bottom - 3);

    ExcludeClipRect(
        device_context,
        state->travel_scene->clip_left,
        state->travel_scene->clip_top,
        state->travel_scene->clip_right,
        state->travel_scene->clip_bottom);

    ExcludeClipRect(
        device_context,
        state->progress_meter->left,
        state->progress_meter->top,
        state->progress_meter->right,
        state->progress_meter->bottom);

    state->background.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        device_context,
        0,
        0);
    SelectClipRgn(device_context, clip_region);
    DeleteObject(clip_region);

    state->OtRecomputeTrailTravelMetricsDependency_20260605();
    state->OtComputeTrailProgressRangeDependency_20260605(&scratch, &progress);
    state->OtDrawTrailSceneCaptionDependency_20260605(device_context);
    state->OtDrawTrailConditionGaugeDependency_20260605(device_context);
    state->diary_window->OtShowWindowIfHiddenDependency_20260605(
        device_context);

    if (state->scene_mode == 2) {
        state->overlay_window->OtHideTrailOverlayWindowDependency_20260605();
        state->river_view->OtShowRiverCrossingViewDependency_20260605(
            device_context,
            state->render_owner);
    } else if (g_trailProgressStopPending != 0) {
        state->overlay_window->OtShowTrailOverlayWindowDependency_20260605(
            owner,
            device_context);
    } else {
        state->overlay_window->OtHideTrailOverlayWindowDependency_20260605();
        state->progress_meter->OtResetTrailProgressMeterDependency_20260605(
            owner,
            device_context,
            progress);
        state->progress_meter->OtAdvanceTrailProgressMeterDependency_20260605(
            owner,
            progress);

        if (state->overlay_phase_active != 0) {
            state->travel_scene->OtRenderTrailTravelSceneDependency_20260605(
                device_context,
                state->render_owner,
                state->travelled_distance,
                state->total_distance,
                state->overlay_phase,
                g_activeTrailEventScene);
        } else {
            state->travel_scene->OtRenderTrailTravelSceneDependency_20260605(
                device_context,
                state->render_owner,
                state->travelled_distance,
                state->total_distance,
                state->overlay_phase,
                0);
        }
    }

    state->diary_window->OtMoveEditCaretToEndDependency_20260605();
}

#pragma optimize("", on)

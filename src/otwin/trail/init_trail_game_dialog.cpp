// Product-semantic recovery for OtInitTrailGameDialog @ 0x0042c2e0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This recovery source must be compiled with 32-bit MSVC."
#endif

typedef void* HMODULE_0042c2e0;
typedef void* HWND_0042c2e0;
typedef unsigned int UINT_0042c2e0;
typedef unsigned int UINT_PTR_0042c2e0;

extern "C" __declspec(dllimport) HWND_0042c2e0 __stdcall GetDlgItem(
    HWND_0042c2e0 dialog,
    int control_id);
extern "C" __declspec(dllimport) int __stdcall ShowWindow(
    HWND_0042c2e0 window,
    int command_show);
extern "C" __declspec(dllimport) UINT_PTR_0042c2e0 __stdcall SetTimer(
    HWND_0042c2e0 window,
    UINT_PTR_0042c2e0 timer_id,
    UINT_0042c2e0 interval_ms,
    void* callback);

#pragma comment(lib, "user32.lib")

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" void* g_resourceModule;
extern "C" int g_midiPlaybackActive_0040cd60;
extern "C" int g_titleThemeEnabled_004390ec;
extern "C" int g_trailProgressStopPending;
extern "C" char g_trailStatusDirty_0043b89c;

// This flag is cleared before the trail dialog owns any runtime state.  It is
// distinct from the overlay-active flag updated later in this initializer.
extern "C" int g_trailDialogRefreshPending_0042c2e0 = 0;

#pragma pack(push, 1)

struct PositionedBitmapDescriptorState_0040ba40 {
    void* bitmap_info_handle;
    void* indexed_pixels_handle;
    void* bitmap_info;
    void* indexed_pixels;
    short x;
    short y;
    short width;
    short height;
    int x_mirror;
    int y_mirror;
    int right;
    int bottom;

    int OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
        void* module,
        short bitmap_resource_id,
        short left,
        short top,
        short width,
        short height);
    int OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        void* module,
        short descriptor_id);
};

struct RectResource_0040b690 {
    int left;
    int top;
    int right;
    int bottom;

    int OtLoadRectFromResource_RealCpp(
        void* module,
        const void* resource_id);
};

struct TrailJournalWindow_0040fc00_20260605 {
    char reserved_00[0x20];

    TrailJournalWindow_0040fc00_20260605(
        HMODULE_0042c2e0 module,
        HWND_0042c2e0 parent,
        const char* descriptor_id);
};

struct LabeledBitmapDisplay_00405bd0_20260603 {
    char reserved_00[0x30];

    LabeledBitmapDisplay_00405bd0_20260603(
        HMODULE_0042c2e0 module,
        HWND_0042c2e0 parent,
        const char* descriptor_id);
};

struct TrailMapComposite_00406010_20260603 {
    char reserved_00[0x50];

    TrailMapComposite_00406010_20260603(
        HMODULE_0042c2e0 module,
        const char* descriptor_id);
};

struct TrailTravelViewportInitializer_004069c0 {
    char reserved_00[0x2b0];

    TrailTravelViewportInitializer_004069c0(
        HMODULE_0042c2e0 module,
        HWND_0042c2e0 parent,
        const char* descriptor_id);
};

struct JourneyState_00419bd0 {
    char reserved_000[0x8a];
    short current_segment_distance;
    char reserved_08c[4];
    short ration_level;
    short pace_level;

    void OtApplyTrailStepProgress_RealCpp(int progress_percent);
};

struct RouteDescriptor_0042c2e0 {
    unsigned short route_id;
    char reserved_002[0x120];
    unsigned short route_strip_descriptor_id;

};

struct RouteDescriptor_00424e30;
extern "C" unsigned int __fastcall
OtSelectRouteLocationBitmapResourceId_RealCpp(
    RouteDescriptor_00424e30* route);

struct TrailOverlayWindow_00405df0 {
    void OtPlayCurrentRouteAudioCue_00405e00_ProductWip(
        void* owner_window);
};

struct LabeledBitmapDisplay_00405f00 {
    void OtUpdateLabeledBitmapDisplay_RealCpp(
        unsigned int bitmap_resource_id,
        unsigned int label_string_id,
        int preserve_label_visibility);
};

struct TrailTravelViewport_00406f70 {
    void OtUpdateTrailViewportRouteStripStateAlt32_00406f70_RealCpp(
        void* module,
        int descriptor_id);
};

struct TrailJournalState_0040f950 {
    int OtAppendTrailJournalText_0040f950_RealCpp(char* pending_text);
};

struct TrailAnimationState_0042d460 {
    void OtSyncTrailActionControls_RealCpp(
        void* owner_window,
        int repaint);
};

struct TrailStatusPanelState_0042d5d0_ProductWip {
    void OtRefreshTrailStatusPanel_0042d5d0_ProductWip(
        void* owner_window);
};

struct TrailActionBitmapDimensions_0042c2e0 {
    char reserved_000[0x1c];
    short common_width;
    short common_height;
    char reserved_020[0x68c];
    short travel_width;
    short travel_height;
    char reserved_6b0[0x74];
    short pause_width;
    short pause_height;
};

struct TrailGameDialogState_0042c2e0 {
    int timer_tick;
    int timer_phase;
    PositionedBitmapDescriptorState_0040ba40 action_bitmaps[48];
    LabeledBitmapDisplay_00405bd0_20260603* landmark_display;
    TrailMapComposite_00406010_20260603* map_composite;
    RectResource_0040b690 progress_rect;
    PositionedBitmapDescriptorState_0040ba40 progress_frames[12];
    PositionedBitmapDescriptorState_0040ba40 progress_overlay;
    char reserved_9a8[0x38];
    PositionedBitmapDescriptorState_0040ba40 route_audio_bitmap;
    UINT_PTR_0042c2e0 timer_handle;
    TrailJournalWindow_0040fc00_20260605* trail_journal;
    TrailTravelViewportInitializer_004069c0* travel_viewport;
    int reserved_a14;
    int route_transition_pending;
    int travel_submode;
    int river_crossing_mode;
    int active_action;
    int hovered_action;
    int action_controls_ready;
    int scene_initialized;
    int distance_per_day;
    int terrain_distance_per_day;
    int metric_a;
    int metric_b;
    int metric_unused;
    int redraw_pending;
    int food_cost_per_day;
    int food_cost_per_member;
    int travel_metric_mode;

    void OtInitTrailGameDialog_0042c2e0_RealCpp(
        HMODULE_0042c2e0 module,
        HWND_0042c2e0 dialog);
};

#pragma pack(pop)

typedef char OtTrailGameDialogOffsetCheckA[
    (unsigned int)&(((TrailGameDialogState_0042c2e0*)0)->landmark_display) ==
            0x788
        ? 1
        : -1];
typedef char OtTrailGameDialogOffsetCheckB[
    (unsigned int)&(((TrailGameDialogState_0042c2e0*)0)->route_audio_bitmap) ==
            0x9e0
        ? 1
        : -1];
typedef char OtTrailGameDialogOffsetCheckC[
    (unsigned int)&(((TrailGameDialogState_0042c2e0*)0)->travel_metric_mode) ==
            0xa54
        ? 1
        : -1];

extern "C" JourneyState_00419bd0* g_journeyState;
extern "C" RouteDescriptor_0042c2e0* g_activeRouteDescriptor;
// The original DAT_0043bc00 slot owns the active dialog object itself.  Its
// first action bitmaps also provide the control dimensions read at the end of
// this initializer.
extern "C" void* g_trailGameDialogState_0042edc0;
#define g_trailActionBitmapDimensions_0042c2e0 \
    ((TrailActionBitmapDimensions_0042c2e0*) \
        g_trailGameDialogState_0042edc0)

extern "C" void __cdecl OtMoveControlToDialogCoords_00401480_Product(
    void* dialog,
    int control_id,
    int x,
    int y);
extern "C" void __cdecl OtResizeControl_RealCpp(
    void* dialog,
    int control_id,
    int width,
    int height);
extern "C" void __fastcall
OtRecomputeTrailTravelMetrics_0042ddc0_RealCpp(int state);

#pragma optimize("s", off)
#pragma optimize("t", on)

void TrailGameDialogState_0042c2e0::
    OtInitTrailGameDialog_0042c2e0_RealCpp(
        HMODULE_0042c2e0 module,
        HWND_0042c2e0 dialog)
{
    register TrailGameDialogState_0042c2e0* state = this;
    register HMODULE_0042c2e0 resource_module = module;
    register HWND_0042c2e0 owner_dialog = dialog;

    g_trailDialogRefreshPending_0042c2e0 = 0;
    state->redraw_pending = 1;
    state->scene_initialized = 1;
    state->action_controls_ready = 1;
    g_midiPlaybackActive_0040cd60 = 0;

    state->trail_journal =
        new TrailJournalWindow_0040fc00_20260605(
            resource_module,
            owner_dialog,
            (const char*)0x0fa1);
    state->landmark_display =
        new LabeledBitmapDisplay_00405bd0_20260603(
            resource_module,
            owner_dialog,
            (const char*)0x0fa0);
    state->map_composite =
        new TrailMapComposite_00406010_20260603(
            resource_module,
            (const char*)0x0fa2);
    TrailTravelViewportInitializer_004069c0* travel_viewport =
        new TrailTravelViewportInitializer_004069c0(
            resource_module,
            owner_dialog,
            (const char*)0x0fa7);
    state->reserved_a14 = 0;
    state->travel_viewport = travel_viewport;

    state->route_audio_bitmap.
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603,
            0x2714);

    state->action_bitmaps[0].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1004);
    state->action_bitmaps[1].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1005);
    state->action_bitmaps[2].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1006);
    state->action_bitmaps[3].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1007);
    state->action_bitmaps[4].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1008);
    state->action_bitmaps[5].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1009);
    state->action_bitmaps[6].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x100a);
    state->action_bitmaps[7].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x100b);
    state->action_bitmaps[8].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x100c);
    state->action_bitmaps[9].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x100d);
    state->action_bitmaps[10].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x100e);
    state->action_bitmaps[11].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x100f);
    state->action_bitmaps[12].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1010);
    state->action_bitmaps[13].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1011);
    state->action_bitmaps[14].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1012);
    state->action_bitmaps[15].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1013);
    state->action_bitmaps[16].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1014);
    state->action_bitmaps[17].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1015);
    state->action_bitmaps[18].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1016);
    state->action_bitmaps[19].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1017);
    state->action_bitmaps[20].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1018);

    if (g_journeyState->ration_level != 0) {
        ShowWindow(GetDlgItem(owner_dialog, 0x0fd7), 0);
    }
    if (g_journeyState->ration_level != 1) {
        ShowWindow(GetDlgItem(owner_dialog, 0x0fd8), 0);
    }
    if (g_journeyState->ration_level != 2) {
        ShowWindow(GetDlgItem(owner_dialog, 0x0fd9), 0);
    }

    state->action_bitmaps[21].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1019);
    state->action_bitmaps[22].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x101a);
    state->action_bitmaps[23].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x101b);
    state->action_bitmaps[24].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x101c);
    state->action_bitmaps[25].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x101d);
    state->action_bitmaps[26].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x101e);
    state->action_bitmaps[27].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x101f);
    state->action_bitmaps[28].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1020);
    state->action_bitmaps[29].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1021);
    state->action_bitmaps[30].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1022);
    state->action_bitmaps[31].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1023);
    state->action_bitmaps[32].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1024);
    state->action_bitmaps[33].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1025);
    state->action_bitmaps[34].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1026);
    state->action_bitmaps[35].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1027);
    state->action_bitmaps[36].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1028);
    state->action_bitmaps[37].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1029);
    state->action_bitmaps[38].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x102a);
    state->action_bitmaps[39].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x102b);
    state->action_bitmaps[40].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x102c);
    state->action_bitmaps[41].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x102d);

    if (g_journeyState->pace_level != 0) {
        ShowWindow(GetDlgItem(owner_dialog, 0x0fde), 0);
    }
    if (g_journeyState->pace_level != 1) {
        ShowWindow(GetDlgItem(owner_dialog, 0x0fdf), 0);
    }
    if (g_journeyState->pace_level != 2) {
        ShowWindow(GetDlgItem(owner_dialog, 0x0fe0), 0);
    }

    state->action_bitmaps[42].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x102e);
    state->action_bitmaps[43].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x102f);
    state->action_bitmaps[44].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1030);
    state->action_bitmaps[45].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1031);
    state->action_bitmaps[46].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1032);
    state->action_bitmaps[47].OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(resource_module, 0x1033);

    OtMoveControlToDialogCoords_00401480_Product(owner_dialog, 0x0fd4, 5, 0x00c);
    OtMoveControlToDialogCoords_00401480_Product(owner_dialog, 0x0fd5, 5, 0x060);
    OtMoveControlToDialogCoords_00401480_Product(owner_dialog, 0x0fd6, 5, 0x0b4);
    if (g_journeyState->ration_level == 0) {
        OtMoveControlToDialogCoords_00401480_Product(
            owner_dialog, 0x0fd7, 5, 0x108);
    } else if (g_journeyState->ration_level == 1) {
        OtMoveControlToDialogCoords_00401480_Product(
            owner_dialog, 0x0fd8, 5, 0x108);
    } else {
        OtMoveControlToDialogCoords_00401480_Product(
            owner_dialog, 0x0fd9, 5, 0x108);
    }
    OtMoveControlToDialogCoords_00401480_Product(owner_dialog, 0x0fda, 5, 0x15c);
    OtMoveControlToDialogCoords_00401480_Product(owner_dialog, 0x0fdb, 0x23e, 0x00c);
    OtMoveControlToDialogCoords_00401480_Product(owner_dialog, 0x0fdc, 0x23e, 0x060);
    OtMoveControlToDialogCoords_00401480_Product(owner_dialog, 0x0fdd, 0x23e, 0x0b4);
    if (g_journeyState->pace_level == 0) {
        OtMoveControlToDialogCoords_00401480_Product(
            owner_dialog, 0x0fde, 0x23e, 0x108);
    } else if (g_journeyState->pace_level == 1) {
        OtMoveControlToDialogCoords_00401480_Product(
            owner_dialog, 0x0fdf, 0x23e, 0x108);
    } else {
        OtMoveControlToDialogCoords_00401480_Product(
            owner_dialog, 0x0fe0, 0x23e, 0x108);
    }
    OtMoveControlToDialogCoords_00401480_Product(owner_dialog, 0x0fe1, 0x23e, 0x15c);
    OtMoveControlToDialogCoords_00401480_Product(owner_dialog, 0x0fd2, 0x043, 0x0d2);
    OtMoveControlToDialogCoords_00401480_Product(owner_dialog, 0x0fd3, 0x0d8, 0x0d2);

    state->progress_rect.OtLoadRectFromResource_RealCpp(
        resource_module,
        (const void*)0x0faa);

    int frame_index = 0;
    PositionedBitmapDescriptorState_0040ba40* frame =
        &state->progress_frames[0];
    do {
        frame->OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            resource_module,
            0x109a);
        frame->OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
            resource_module,
            (short)(frame_index + 0x3cf1),
            0,
            0,
            0,
            0);
        ++frame;
        ++frame_index;
    } while (frame_index < 12);

    state->progress_overlay.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        resource_module,
        0x109b);

    g_journeyState->OtApplyTrailStepProgress_RealCpp(0);
    state->river_crossing_mode = 0;
    state->travel_submode = 1;
    reinterpret_cast<TrailAnimationState_0042d460*>(state)->
        OtSyncTrailActionControls_RealCpp(owner_dialog, 1);
    state->active_action = 0;
    state->hovered_action = 0;
    state->route_transition_pending = 0;

    if (g_journeyState->current_segment_distance == 0) {
        g_trailProgressStopPending = 1;
        if (g_titleThemeEnabled_004390ec != 0 && state->travel_submode != 0) {
            reinterpret_cast<TrailOverlayWindow_00405df0*>(
                state->landmark_display)->
                OtPlayCurrentRouteAudioCue_00405e00_ProductWip(owner_dialog);
        }
    } else {
        g_trailProgressStopPending = 0;
    }

    state->travel_metric_mode = 0;
    OtRecomputeTrailTravelMetrics_0042ddc0_RealCpp((int)state);

    reinterpret_cast<LabeledBitmapDisplay_00405f00*>(
        state->landmark_display)->
        OtUpdateLabeledBitmapDisplay_RealCpp(
            OtSelectRouteLocationBitmapResourceId_RealCpp(
                reinterpret_cast<RouteDescriptor_00424e30*>(
                    g_activeRouteDescriptor)),
            (g_activeRouteDescriptor->route_id + 0x0d) * 0x10,
            0);

    reinterpret_cast<TrailTravelViewport_00406f70*>(
        state->travel_viewport)->
        OtUpdateTrailViewportRouteStripStateAlt32_00406f70_RealCpp(
            g_resourceModule,
            g_activeRouteDescriptor->route_strip_descriptor_id);

    reinterpret_cast<TrailStatusPanelState_0042d5d0_ProductWip*>(state)->
        OtRefreshTrailStatusPanel_0042d5d0_ProductWip(owner_dialog);

    reinterpret_cast<TrailJournalState_0040f950*>(state->trail_journal)->
        OtAppendTrailJournalText_0040f950_RealCpp(
            &g_trailStatusDirty_0043b89c);

    state->timer_tick = 0;
    state->timer_phase = 0;
    state->timer_handle = SetTimer(owner_dialog, 0x1324, 0x32, 0);

    reinterpret_cast<TrailAnimationState_0042d460*>(state)->
        OtSyncTrailActionControls_RealCpp(owner_dialog, 0);

    register int control_id = 0x0fd2;
    do {
        OtResizeControl_RealCpp(
            owner_dialog,
            control_id,
            g_trailActionBitmapDimensions_0042c2e0->common_width,
            g_trailActionBitmapDimensions_0042c2e0->common_height);
        ++control_id;
    } while (control_id <= 0x0fe1);

    OtResizeControl_RealCpp(
        owner_dialog,
        0x0fd2,
        g_trailActionBitmapDimensions_0042c2e0->travel_width,
        g_trailActionBitmapDimensions_0042c2e0->travel_height);
    OtResizeControl_RealCpp(
        owner_dialog,
        0x0fd3,
        g_trailActionBitmapDimensions_0042c2e0->pause_width,
        g_trailActionBitmapDimensions_0042c2e0->pause_height);
}

#pragma optimize("", on)

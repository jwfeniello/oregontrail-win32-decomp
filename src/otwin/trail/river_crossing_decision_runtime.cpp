// Product semantic WIP for OtRunRiverCrossingDecisionFlow @ 0x0042cbc0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include "../river/river_crossing_state_runtime.h"
#include "trail_travel_view_refresh.h"

extern "C" __declspec(dllimport) void* __stdcall GetParent(void* window);
extern "C" __declspec(dllimport) void* __stdcall GetMenu(void* window);
extern "C" __declspec(dllimport) unsigned int __stdcall EnableMenuItem(
    void* menu,
    unsigned int item,
    unsigned int flags);
extern "C" __declspec(dllimport) int __stdcall DrawMenuBar(void* window);
extern "C" __declspec(dllimport) void* __stdcall LoadCursorA(
    void* instance,
    const void* cursor_name);
extern "C" __declspec(dllimport) void* __stdcall SetCursor(void* cursor);
extern "C" __declspec(dllimport) void* __stdcall GetDC(void* window);
extern "C" __declspec(dllimport) void* __stdcall SelectPalette(
    void* dc,
    void* palette,
    int force_background);
extern "C" __declspec(dllimport) unsigned int __stdcall RealizePalette(
    void* dc);
extern "C" __declspec(dllimport) int __stdcall ReleaseDC(
    void* window,
    void* dc);

#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "user32.lib")

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" void* g_resourceModule;
extern "C" void* g_gamePalette;
extern "C" void* g_journeyState;
extern "C" void* g_activeRouteDescriptor;
extern "C" int g_trailProgressStopPending;
extern "C" int g_appBusyCursorActive_Product_004034d0;
extern "C" short g_riverCrossingSceneMode_0040f270;

extern "C" int __cdecl OtRunModalDialogAndRefreshParentAlt1_00401530_38pct(
    void* instance,
    void* parent_window,
    void* dialog_proc,
    const char* template_name,
    long init_param);
extern "C" long __stdcall
OtRiverCrossingChoiceDialogProc_004229e0_ProductWip(
    void* dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" short __stdcall
OtProcessRiverCrossingChoice_0040ec30_ProductWip(
    void* parent_window,
    short choice);
extern "C" short __stdcall
OtFinalizeRiverCrossingChoice_0040f760_ProductWip(void* parent_window);
extern "C" unsigned int __fastcall
OtSelectRouteLocationBitmapResourceId_RealCpp(void* route);

#pragma pack(push, 1)
struct RouteDescriptor_0042cbc0_ProductWip {
    unsigned short route_id;
    char reserved_002[0x0c];
    short first_crossing_option;
    short second_crossing_option;
    char reserved_012[0x110];
    unsigned short route_strip_state;
};

struct JourneyState_0042cbc0_ProductWip {
    char reserved_000[0x5a];
    unsigned short route_stop_flags;
    char reserved_05c[0x38];
    short delay_days;
};

struct JourneyState_00419f60 {
    void OtApplyTravelProgressEffectsAlt7_00419f60(
        unsigned int progress_percent);
};

struct JourneyState_004198e0 {
    void OtAdvanceToNextRouteSegment_RealCpp(short branch_choice);
};

struct TrailAnimationState_0042d460 {
    void OtSyncTrailActionControls_RealCpp(
        void* owner_window,
        int repaint);
};

struct TrailUiState_0042b370 {
    void OtPauseTrailTravel_RealCpp(void* owner_window);
};

struct TrailStatusPanelState_0042d5d0_ProductWip {
    void OtRefreshTrailStatusPanel_0042d5d0_ProductWip(
        void* owner_window);
};

struct TimedTransitionState_0042dfa0_ProductWip {
    int OtRunTimedTransitionLoop_0042dfa0_ProductWip(int unused);
};

struct LabeledBitmapDisplay_00405f00 {
    void OtUpdateLabeledBitmapDisplay_RealCpp(
        unsigned int bitmap_resource_id,
        unsigned int label_string_id,
        int preserve_label_visibility);
};

struct TrailOverlayWindow_00405df0 {
    void OtHideTrailOverlayWindow_RealCpp();
};

struct TrailTravelViewport_00406f70 {
    void OtUpdateTrailViewportRouteStripStateAlt32_00406f70_RealCpp(
        void* module,
        int descriptor_id);
};

struct RiverCrossingView_00427f00_43pct {
    void OtShowRiverCrossingViewAlt2_00427f00_43pct(
        void* dc,
        void* owner);
};

struct TrailRiverDecisionState_0042cbc0_ProductWip {
    char reserved_000[0x788];
    LabeledBitmapDisplay_00405f00* trail_stop_display;
    char reserved_78c[0x284];
    TrailTravelViewport_00406f70* trail_viewport;
    RiverCrossingState_004285a0_ProductWip* river_crossing_view;
    char reserved_a18[4];
    int travel_submode;
    int river_crossing_mode;
    char reserved_a24[8];
    int transition_frame;
    int river_view_owner;
    char reserved_a34[0x14];
    int travelled_distance;

    int OtRunRiverCrossingDecisionFlow_0042cbc0_ProductWip(
        void* owner_window);
};
#pragma pack(pop)


#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

int TrailRiverDecisionState_0042cbc0_ProductWip::
    OtRunRiverCrossingDecisionFlow_0042cbc0_ProductWip(
        void* owner_window)
{
    void* window = owner_window;
    RouteDescriptor_0042cbc0_ProductWip* route;
    JourneyState_0042cbc0_ProductWip* journey;
    short choice = 0;
    int crossing_delay_or_status;
    int final_delay_days;

    this->travel_submode = 2;
    this->river_crossing_mode = 1;
    reinterpret_cast<TrailAnimationState_0042d460*>(this)->
        OtSyncTrailActionControls_RealCpp(window, 1);
    EnableMenuItem(GetMenu(GetParent(window)), 0, 0x401);
    EnableMenuItem(GetMenu(GetParent(window)), 1, 0x401);
    EnableMenuItem(GetMenu(GetParent(window)), 2, 0x401);
    EnableMenuItem(GetMenu(GetParent(window)), 3, 0x401);
    DrawMenuBar(GetParent(window));

    for (;;) {
        reinterpret_cast<TrailStatusPanelState_0042d5d0_ProductWip*>(this)->
            OtRefreshTrailStatusPanel_0042d5d0_ProductWip(window);

        route = static_cast<RouteDescriptor_0042cbc0_ProductWip*>(
            g_activeRouteDescriptor);
        int dialog_template;
        if (route->first_crossing_option == 0) {
            dialog_template =
                (route->second_crossing_option == 0) + 0xec;
        } else if (route->second_crossing_option == 0) {
            dialog_template = 0xeb;
        } else {
            dialog_template = 0xea;
        }
        int dialog_result =
            OtRunModalDialogAndRefreshParentAlt1_00401530_38pct(
                g_applicationModule_00405a40_20260603,
                window,
                reinterpret_cast<void*>(
                    OtRiverCrossingChoiceDialogProc_004229e0_ProductWip),
                reinterpret_cast<const char*>(dialog_template),
                reinterpret_cast<long>(&choice));

        if (dialog_result == 0) {
            this->river_crossing_mode = 0;
            reinterpret_cast<TrailUiState_0042b370*>(this)->
                OtPauseTrailTravel_RealCpp(window);
            reinterpret_cast<TrailStatusPanelState_0042d5d0_ProductWip*>(
                this)->OtRefreshTrailStatusPanel_0042d5d0_ProductWip(
                    window);
            EnableMenuItem(GetMenu(GetParent(window)), 0, 0x400);
            EnableMenuItem(GetMenu(GetParent(window)), 1, 0x400);
            EnableMenuItem(GetMenu(GetParent(window)), 2, 0x400);
            EnableMenuItem(GetMenu(GetParent(window)), 3, 0x400);
            DrawMenuBar(GetParent(window));
            return 0;
        }

        crossing_delay_or_status =
            OtProcessRiverCrossingChoice_0040ec30_ProductWip(
                window,
                choice);
        while (crossing_delay_or_status > 0) {
            journey = static_cast<JourneyState_0042cbc0_ProductWip*>(
                g_journeyState);
            ++journey->delay_days;
            journey->route_stop_flags =
                static_cast<unsigned short>(
                    journey->route_stop_flags | 0x40);
            --crossing_delay_or_status;

            reinterpret_cast<TrailStatusPanelState_0042d5d0_ProductWip*>(
                this)->OtRefreshTrailStatusPanel_0042d5d0_ProductWip(
                    window);
            reinterpret_cast<TimedTransitionState_0042dfa0_ProductWip*>(
                this)->OtRunTimedTransitionLoop_0042dfa0_ProductWip(
                    reinterpret_cast<int>(window));
            reinterpret_cast<JourneyState_00419f60*>(g_journeyState)->
                OtApplyTravelProgressEffectsAlt7_00419f60(0);

            route = static_cast<RouteDescriptor_0042cbc0_ProductWip*>(
                g_activeRouteDescriptor);
            this->trail_stop_display->OtUpdateLabeledBitmapDisplay_RealCpp(
                OtSelectRouteLocationBitmapResourceId_RealCpp(route),
                static_cast<unsigned int>((route->route_id + 0x0d) * 0x10),
                1);
            reinterpret_cast<TrailAnimationFrameState_0042acc0_Product*>(
                this)->OtRefreshTrailTravelView_0042acc0_Product(window);
        }

        if (crossing_delay_or_status != -1 && choice != 104) {
            break;
        }
    }

    g_appBusyCursorActive_Product_004034d0 = 1;
    SetCursor(LoadCursorA(0, reinterpret_cast<const void*>(0x7f02)));

    final_delay_days =
        OtFinalizeRiverCrossingChoice_0040f760_ProductWip(window);
    journey = static_cast<JourneyState_0042cbc0_ProductWip*>(g_journeyState);
    if (final_delay_days > 0) {
        journey->delay_days =
            static_cast<short>(journey->delay_days + final_delay_days);
        journey->route_stop_flags =
            static_cast<unsigned short>(journey->route_stop_flags | 0x20);
    }

    this->river_crossing_view =
        new RiverCrossingState_004285a0_ProductWip(
            window,
            choice,
            g_riverCrossingSceneMode_0040f270);

    g_appBusyCursorActive_Product_004034d0 = 0;
    SetCursor(LoadCursorA(0, reinterpret_cast<const void*>(0x7f00)));

    this->travelled_distance = 1;
    this->river_view_owner = 1;
    this->transition_frame = 1;
    g_trailProgressStopPending = 0;

    reinterpret_cast<JourneyState_004198e0*>(g_journeyState)->
        OtAdvanceToNextRouteSegment_RealCpp(0);

    route = static_cast<RouteDescriptor_0042cbc0_ProductWip*>(
        g_activeRouteDescriptor);
    this->trail_viewport->
        OtUpdateTrailViewportRouteStripStateAlt32_00406f70_RealCpp(
            g_resourceModule,
            route->route_strip_state);
    reinterpret_cast<TrailOverlayWindow_00405df0*>(
        this->trail_stop_display)->OtHideTrailOverlayWindow_RealCpp();
    this->trail_stop_display->OtUpdateLabeledBitmapDisplay_RealCpp(
        OtSelectRouteLocationBitmapResourceId_RealCpp(route),
        static_cast<unsigned int>((route->route_id + 0x0d) * 0x10),
        0);

    this->river_crossing_mode = 2;
    this->travel_submode = 0;
    reinterpret_cast<TrailStatusPanelState_0042d5d0_ProductWip*>(this)->
        OtRefreshTrailStatusPanel_0042d5d0_ProductWip(window);

    void* dc = GetDC(window);
    SelectPalette(dc, g_gamePalette, 0);
    RealizePalette(dc);
    reinterpret_cast<RiverCrossingView_00427f00_43pct*>(
        this->river_crossing_view)->
        OtShowRiverCrossingViewAlt2_00427f00_43pct(
            dc,
            reinterpret_cast<void*>(this->river_view_owner));
    ReleaseDC(window, dc);
    return 1;
}

#pragma optimize("", on)
#pragma code_seg()

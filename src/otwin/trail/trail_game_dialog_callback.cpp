// Product-reachable semantic DLGPROC for OtTrailGameDialogProc @ 0x0042dff0.

#include "../app/dialog_callback_runtime.h"

extern "C" __declspec(dllimport) OtDialogHandle_Product __stdcall GetParent(
    OtDialogHandle_Product window);
extern "C" __declspec(dllimport) int __stdcall GetClientRect(
    OtDialogHandle_Product window,
    OtDialogRect_Product* rect);
extern "C" __declspec(dllimport) unsigned int __stdcall GetDialogBaseUnits();
extern "C" __declspec(dllimport) int __stdcall SetWindowPos(
    OtDialogHandle_Product window,
    OtDialogHandle_Product insert_after,
    int x,
    int y,
    int width,
    int height,
    unsigned int flags);
extern "C" __declspec(dllimport) long __stdcall GetWindowLongA(
    OtDialogHandle_Product window,
    int index);
extern "C" __declspec(dllimport) int __stdcall IsWindow(
    OtDialogHandle_Product window);
extern "C" __declspec(dllimport) int __stdcall IsWindowVisible(
    OtDialogHandle_Product window);
extern "C" __declspec(dllimport) int __stdcall DestroyWindow(
    OtDialogHandle_Product window);
extern "C" __declspec(dllimport) int __stdcall HideCaret(
    OtDialogHandle_Product window);
extern "C" __declspec(dllimport) int __stdcall PostMessageA(
    OtDialogHandle_Product window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    OtDialogHandle_Product window,
    const char* text,
    const char* caption,
    unsigned int type);
extern "C" __declspec(dllimport) void __stdcall PostQuitMessage(int exit_code);
extern "C" __declspec(dllimport) unsigned int __stdcall SetTimer(
    OtDialogHandle_Product window,
    unsigned int timer_id,
    unsigned int interval,
    void* callback);
extern "C" __declspec(dllimport) int __stdcall KillTimer(
    OtDialogHandle_Product window,
    unsigned int timer_id);
extern "C" __declspec(dllimport) void* __stdcall LoadAcceleratorsA(
    void* instance,
    const char* table_name);

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" void* g_resourceModule;
extern "C" void* g_journeyState;
extern "C" void* g_activeRouteDescriptor;
extern "C" void* g_trailGameDialogState_0042edc0;
extern "C" void* g_mainAccelerator_00402ed0;
extern "C" OtDialogHandle_Product
    g_sharedModelessDialogWindow_004390cc;
extern "C" OtDialogHandle_Product g_trailStatusNotifyWindow_004390d0;
extern "C" int g_cdMediaMode_00439108;
extern "C" int DAT_004390e0;
extern "C" int DAT_004390e8;
extern "C" int g_titleThemeEnabled_004390ec;
extern "C" int g_generalStorePurchaseCommitted_004390f8;
extern "C" int g_trailProgressStopPending;

extern "C" void __cdecl
OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
    OtDialogHandle_Product dialog,
    int control_id,
    int dialog_unit_width,
    int dialog_unit_height);
extern "C" void __cdecl OtPaintTrailGameDialog_RealCpp(
    OtDialogHandle_Product dialog);
extern "C" void __cdecl
OtRefreshTrailWindowAndDispatchState_0042edc0_RealCpp(
    OtDialogHandle_Product dialog,
    void* draw_state,
    int command);
extern "C" void __cdecl OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();
extern "C" void __cdecl OtCloseWaveAudioDevice_0040d0a0_RealCpp();
extern "C" int __cdecl OtSelectDialogCursor_0040d530_RealCpp(
    int busy_cursor_active,
    OtDialogHandle_Product cursor_window);
extern "C" void __cdecl OtPlayMidiAudio_0000ced0_RealCpp(int track);
extern "C" short __fastcall OtCountLivingPartyMembers_RealCpp(
    const void* party);
extern "C" int __cdecl OtRunSharedMessageDialog_00401e70_RealCpp(
    OtDialogHandle_Product parent,
    void* message_text,
    void* caption_text,
    int use_alternate_template);

#pragma pack(push, 1)
struct TrailGameDialogState_0042efa0_Product {
    int timer_tick;
    int timer_phase;
    PositionedBitmapDescriptorState_0040ba40 action_bitmaps[48];
    void* landmark_display;
    void* map_composite;
    RectResource_0040b690 progress_rect;
    PositionedBitmapDescriptorState_0040ba40 progress_frames[12];
    PositionedBitmapDescriptorState_0040ba40 progress_overlay;
    char reserved_9a8[0x38];
    PositionedBitmapDescriptorState_0040ba40 route_audio_bitmap;
    unsigned int timer_handle;
    void* trail_journal;
    void* travel_viewport;
    int river_crossing_state;
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

    TrailGameDialogState_0042efa0_Product();
};

struct TrailGameDialogState_0042c2e0 {
    void OtInitTrailGameDialog_0042c2e0_RealCpp(
        void* module,
        OtDialogHandle_Product dialog);
};

struct TrailGameDialogOwnedResources_0042a6f0 {
    void OtDestroyTrailGameDialogOwnedResources_RealCpp();
};

struct TrailAnimationState_0042d460 {
    void OtMarkTrailDialogActive_RealCpp(int owner_window);
};

struct TrailAnimationState_0002d490_20260605 {
    void OtAdvanceTrailAnimationStateWip17_20260605_RealCpp(
        void* owner_window);
};

struct TrailAnimationFrameState_0042a3d0 {
    void OtRefreshTrailAnimationFrame_RealCpp(void* owner_window);
};

struct TrailOverlayStartState_0042dc20 {
    void OtTrailActionGateForwarder_RealCpp(void* owner_window);
};

struct TrailUiState_0042b370 {
    void OtPauseTrailTravel_RealCpp(void* owner_window);
    void OtOpenGuideBookDialog_RealCpp(void* owner_window, long guide_page);
    void OtOpenStatusDialog_RealCpp(void* owner_window);
    void OtOpenCyclingTalkDialog_RealCpp(void* owner_window);
    void OtRunTradeSelectionDialog_RealCpp(void* owner_window);
    void OtPlayTrailPaceTheme_0042d3a0_ProductWip(void* owner_window);
};

struct TrailModeState_0042a790_20260603 {
    int OtUpdateTrailModeAfterAction_20260603_RealCpp(void* owner_window);
};

struct TrailDialogState_0042b0b0_20260603 {
    void OtHandleDropSuppliesAction_20260603(void* owner_window);
};

struct TrailDialogState_0042b610_20260605 {
    void OtHandleChangeRationsAction_20260605(void* owner_window);
};

struct TrailDialogState_0042b3d0_20260603 {
    void OtHandleChangePaceAction_20260603(void* owner_window);
};

struct JourneyState_00419f60 {
    void OtApplyTravelProgressEffects_RealCpp(unsigned int progress_percent);
};

struct TrailCommandJourneyState_Product {
    char reserved_000[0x50];
    short current_location;
    char reserved_052[8];
    short route_stop_flags;
    char reserved_05c[0x34];
    short ration_level;
    short pace_level;
    short hunt_count;
    char reserved_096[0x0e];
    short food_a;
    short food_b;
    char reserved_0a8[0x16];
    short health_indicator;
};
#pragma pack(pop)

typedef char OtTrailCallbackStateSizeMustBeA58[
    sizeof(TrailGameDialogState_0042efa0_Product) == 0xa58 ? 1 : -1];

static const char g_trailAllocationText_0042dff0[] =
    "Unable to allocate trail dialog state.";
static const char g_trailAllocationCaption_0042dff0[] = "TrailDlgProc";
static char g_noStoreText_0042dff0[] = "No store here.";
static char g_noStoreCaption_0042dff0[] = "Store";

static void OtSetupTrailGameDialogWindow_Product_0042ee60(
    OtDialogHandle_Product dialog)
{
    OtDialogRect_Product client_rect;
    unsigned int base_units;
    int unit_width;
    int unit_height;
    int control_id;
    TrailGameDialogState_0042efa0_Product* state;

    GetClientRect(GetParent(dialog), &client_rect);
    base_units = GetDialogBaseUnits();
    unit_width = static_cast<unsigned short>(base_units);
    unit_height = static_cast<unsigned short>(base_units >> 16);
    SetWindowPos(
        dialog,
        0,
        client_rect.left + 10,
        client_rect.top + 10,
        client_rect.right - client_rect.left - 20,
        client_rect.bottom - client_rect.top - 20,
        4);

    for (control_id = 0x1068; control_id <= 0x107b; ++control_id) {
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog,
            control_id,
            unit_width,
            unit_height);
    }
    for (control_id = 0x0fd2; control_id <= 0x0fe1; ++control_id) {
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog,
            control_id,
            unit_width,
            unit_height);
    }

    state = new TrailGameDialogState_0042efa0_Product;
    g_trailGameDialogState_0042edc0 = state;
    if (state == 0) {
        MessageBoxA(
            dialog,
            g_trailAllocationText_0042dff0,
            g_trailAllocationCaption_0042dff0,
            0);
        PostQuitMessage(0);
        return;
    }
    reinterpret_cast<TrailGameDialogState_0042c2e0*>(state)->
        OtInitTrailGameDialog_0042c2e0_RealCpp(g_resourceModule, dialog);
}

static void OtUpdateTrailAfterAction_Product_0042dff0(
    TrailGameDialogState_0042efa0_Product* state,
    OtDialogHandle_Product dialog,
    int previous_mode)
{
    TrailCommandJourneyState_Product* journey =
        reinterpret_cast<TrailCommandJourneyState_Product*>(g_journeyState);

    if (previous_mode == 0 &&
        (g_trailProgressStopPending == 0 ||
         journey->route_stop_flags != 0)) {
        reinterpret_cast<TrailModeState_0042a790_20260603*>(state)->
            OtUpdateTrailModeAfterAction_20260603_RealCpp(dialog);
    }
}

static int OtHandleTrailCommand_Product_0042f630(
    OtDialogHandle_Product dialog,
    unsigned int wparam,
    long lparam)
{
    TrailGameDialogState_0042efa0_Product* state =
        reinterpret_cast<TrailGameDialogState_0042efa0_Product*>(
            g_trailGameDialogState_0042edc0);
    unsigned int command = wparam & 0xffff;
    unsigned int notification = wparam >> 16;
    int previous_mode;

    if (state == 0 ||
        state->river_crossing_mode == 1 ||
        state->river_crossing_mode == 2) {
        return 0;
    }
    previous_mode = state->travel_submode;
    reinterpret_cast<TrailAnimationState_0042d460*>(state)->
        OtMarkTrailDialogActive_RealCpp(reinterpret_cast<int>(dialog));
    if (g_cdMediaMode_00439108 == 0) {
        OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();
    } else {
        OtCloseWaveAudioDevice_0040d0a0_RealCpp();
    }

    if (command == 0x10fe) {
        if (notification == 0x0200) {
            PostMessageA(GetParent(dialog), 0x0479, 0, 0);
        } else if (notification == 0x0100) {
            reinterpret_cast<TrailUiState_0042b370*>(state)->
                OtPauseTrailTravel_RealCpp(dialog);
            PostMessageA(
                GetParent(dialog),
                0x0478,
                static_cast<unsigned int>(lparam & 0xffff),
                0);
        }
        return 0;
    }

    switch (command) {
    case 0x0fd2:
        g_generalStorePurchaseCommitted_004390f8 = 1;
        reinterpret_cast<TrailModeState_0042a790_20260603*>(state)->
            OtUpdateTrailModeAfterAction_20260603_RealCpp(dialog);
        break;

    case 0x0fd3:
        reinterpret_cast<TrailUiState_0042b370*>(state)->
            OtPauseTrailTravel_RealCpp(dialog);
        break;

    case 0x0fd4:
        reinterpret_cast<TrailDialogState_0042b0b0_20260603*>(state)->
            OtHandleDropSuppliesAction_20260603(dialog);
        OtUpdateTrailAfterAction_Product_0042dff0(
            state, dialog, previous_mode);
        break;

    case 0x0fd5:
        reinterpret_cast<TrailUiState_0042b370*>(state)->
            OtOpenGuideBookDialog_RealCpp(
                dialog,
                *reinterpret_cast<short*>(
                    static_cast<char*>(g_activeRouteDescriptor) + 0x13a));
        OtUpdateTrailAfterAction_Product_0042dff0(
            state, dialog, previous_mode);
        break;

    case 0x0fd6:
        if (IsWindow(g_trailStatusNotifyWindow_004390d0) == 0) {
            reinterpret_cast<TrailUiState_0042b370*>(state)->
                OtPauseTrailTravel_RealCpp(dialog);
            reinterpret_cast<TrailUiState_0042b370*>(state)->
                OtOpenStatusDialog_RealCpp(dialog);
        }
        break;

    case 0x0fd7:
    case 0x0fd8:
    case 0x0fd9:
        reinterpret_cast<TrailDialogState_0042b610_20260605*>(state)->
            OtHandleChangeRationsAction_20260605(dialog);
        OtUpdateTrailAfterAction_Product_0042dff0(
            state, dialog, previous_mode);
        break;

    case 0x0fda:
        if (g_trailProgressStopPending != 0 &&
            *reinterpret_cast<short*>(
                static_cast<char*>(g_activeRouteDescriptor) + 0x130) != 0) {
            PostMessageA(GetParent(dialog), 0x0471, 0, 0);
        } else {
            OtRunSharedMessageDialog_00401e70_RealCpp(
                dialog,
                g_noStoreText_0042dff0,
                g_noStoreCaption_0042dff0,
                0);
        }
        break;

    case 0x0fdb:
        reinterpret_cast<TrailUiState_0042b370*>(state)->
            OtRunTradeSelectionDialog_RealCpp(dialog);
        OtUpdateTrailAfterAction_Product_0042dff0(
            state, dialog, previous_mode);
        break;

    case 0x0fdc:
        reinterpret_cast<TrailUiState_0042b370*>(state)->
            OtOpenCyclingTalkDialog_RealCpp(dialog);
        OtUpdateTrailAfterAction_Product_0042dff0(
            state, dialog, previous_mode);
        break;

    case 0x0fdd:
        // The rest-choice DLGPROC has not yet been promoted out of recovery.
        // Keep the dialog in a valid paused state without calling that scaffold.
        reinterpret_cast<TrailUiState_0042b370*>(state)->
            OtPauseTrailTravel_RealCpp(dialog);
        break;

    case 0x0fde:
    case 0x0fdf:
    case 0x0fe0:
        reinterpret_cast<TrailDialogState_0042b3d0_20260603*>(state)->
            OtHandleChangePaceAction_20260603(dialog);
        OtUpdateTrailAfterAction_Product_0042dff0(
            state, dialog, previous_mode);
        break;

    case 0x0fe1:
        PostMessageA(GetParent(dialog), 0x0473, 0, 0);
        reinterpret_cast<TrailUiState_0042b370*>(state)->
            OtPauseTrailTravel_RealCpp(dialog);
        {
            TrailCommandJourneyState_Product* journey =
                reinterpret_cast<TrailCommandJourneyState_Product*>(
                    g_journeyState);
            ++journey->hunt_count;
            journey->route_stop_flags = static_cast<short>(
                journey->route_stop_flags | 0x20);
        }
        if (state->food_cost_per_day != 0) {
            reinterpret_cast<JourneyState_00419f60*>(g_journeyState)->
                OtApplyTravelProgressEffects_RealCpp(
                    (state->redraw_pending * 100) /
                    static_cast<unsigned int>(state->food_cost_per_day));
        }
        state->redraw_pending = 1;
        state->action_controls_ready = state->redraw_pending;
        break;
    }

    return 0;
}

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" int __stdcall OtTrailGameDialogProc_0002dff0_Wip(
    OtDialogHandle_Product dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam)
{
    TrailGameDialogState_0042efa0_Product* state =
        reinterpret_cast<TrailGameDialogState_0042efa0_Product*>(
            g_trailGameDialogState_0042edc0);

    switch (message) {
    case 0x0002:
        OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();
        if (g_cdMediaMode_00439108 != 0) {
            OtCloseWaveAudioDevice_0040d0a0_RealCpp();
        }
        if (IsWindow(g_sharedModelessDialogWindow_004390cc) != 0) {
            DestroyWindow(g_sharedModelessDialogWindow_004390cc);
            g_sharedModelessDialogWindow_004390cc = 0;
        }
        if (IsWindow(g_trailStatusNotifyWindow_004390d0) != 0) {
            DestroyWindow(g_trailStatusNotifyWindow_004390d0);
            g_trailStatusNotifyWindow_004390d0 = 0;
        }
        if (state != 0) {
            if (state->timer_handle != 0) {
                KillTimer(dialog, state->timer_handle);
            }
            reinterpret_cast<TrailGameDialogOwnedResources_0042a6f0*>(state)->
                OtDestroyTrailGameDialogOwnedResources_RealCpp();
            delete state;
            g_trailGameDialogState_0042edc0 = 0;
        }
        g_mainAccelerator_00402ed0 = LoadAcceleratorsA(
            g_applicationModule_00405a40_20260603,
            "OTHOTKEYS");
        g_activeScreenDialogWindow_00404dd0 = 0;
        return 1;

    case 0x0006:
        if (static_cast<short>(wparam & 0xffff) == 0 && state != 0) {
            reinterpret_cast<TrailUiState_0042b370*>(state)->
                OtPauseTrailTravel_RealCpp(dialog);
        }
        return 1;

    case 0x000f:
        OtSetDialogBusyCursor_Product();
        OtPaintTrailGameDialog_RealCpp(dialog);
        OtRestoreDialogArrowCursor_Product();
        return 1;

    case 0x0014:
        return 1;

    case 0x0020:
        return OtSelectDialogCursor_0040d530_RealCpp(
            g_appBusyCursorActive_Product_004034d0,
            reinterpret_cast<OtDialogHandle_Product>(wparam));

    case 0x002b:
        OtRefreshTrailWindowAndDispatchState_0042edc0_RealCpp(
            dialog,
            reinterpret_cast<void*>(lparam),
            static_cast<int>(wparam));
        return 1;

    case 0x0110:
        OtSetDialogBusyCursor_Product();
        g_activeScreenDialogWindow_00404dd0 = dialog;
        HideCaret(0);
        g_mainAccelerator_00402ed0 = 0;
        OtSetupTrailGameDialogWindow_Product_0042ee60(dialog);
        return 0;

    case 0x0111:
        return OtHandleTrailCommand_Product_0042f630(
            dialog,
            wparam,
            lparam);

    case 0x0113:
        if (state != 0) {
            if (state->travel_submode == 0) {
                reinterpret_cast<TrailAnimationState_0002d490_20260605*>(
                    state)->
                    OtAdvanceTrailAnimationStateWip17_20260605_RealCpp(
                        dialog);
                reinterpret_cast<TrailAnimationFrameState_0042a3d0*>(state)->
                    OtRefreshTrailAnimationFrame_RealCpp(dialog);
            }
            ++state->action_controls_ready;
        }
        return 1;

    case 0x0138:
        {
            int control_id = static_cast<int>(GetWindowLongA(
                reinterpret_cast<OtDialogHandle_Product>(lparam),
                -12));
            void* font = g_dialogFont_004390d8_00405320;
            unsigned long color = 0;
            TrailCommandJourneyState_Product* journey =
                reinterpret_cast<TrailCommandJourneyState_Product*>(
                    g_journeyState);

            if (control_id >= 0x1069 && control_id <= 0x106b) {
                font = g_optionMenuFont_004390d4_00405320;
            } else if (control_id == 0x1071 &&
                       journey->food_a + journey->food_b < 100) {
                font = g_optionMenuFont_004390d4_00405320;
                color = 0xff;
            } else if (control_id == 0x1073 &&
                       journey->health_indicator / 0x23 == 3) {
                font = g_optionMenuFont_004390d4_00405320;
                color = 0xff;
            } else if (control_id == 0x107b && state != 0 &&
                       state->travel_submode == 1) {
                font = g_optionMenuFont_004390d4_00405320;
            }
            return OtPrepareDialogControlColor_Product(
                reinterpret_cast<OtDialogDeviceContext_Product>(wparam),
                font,
                color);
        }

    case 0x03b9:
        if (wparam == 1 && g_cdMediaMode_00439108 != 0 &&
            g_titleThemeEnabled_004390ec != 0) {
            OtCloseWaveAudioDevice_0040d0a0_RealCpp();
            OtPlayMidiAudio_0000ced0_RealCpp(0);
        }
        return 1;

    case 0x0464:
    case 0x0465:
        if (state != 0 && state->river_crossing_mode == 2) {
            KillTimer(dialog, state->timer_handle);
        } else if (state != 0) {
            reinterpret_cast<TrailUiState_0042b370*>(state)->
                OtPauseTrailTravel_RealCpp(dialog);
        }
        if (message == 0x0465) {
            OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();
            if (g_cdMediaMode_00439108 != 0) {
                OtCloseWaveAudioDevice_0040d0a0_RealCpp();
            }
        }
        return 1;

    case 0x0467:
        if (state != 0 && IsWindowVisible(dialog) != 0) {
            reinterpret_cast<TrailUiState_0042b370*>(state)->
                OtPlayTrailPaceTheme_0042d3a0_ProductWip(dialog);
            state->timer_handle = SetTimer(dialog, 0x1324, 0x32, 0);
            reinterpret_cast<TrailOverlayStartState_0042dc20*>(state)->
                OtTrailActionGateForwarder_RealCpp(dialog);
        }
        return 0;

    case 0x046a:
        if (state != 0) {
            reinterpret_cast<TrailOverlayStartState_0042dc20*>(state)->
                OtTrailActionGateForwarder_RealCpp(dialog);
        }
        return 0;

    case 0x046b:
        OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();
        if (g_cdMediaMode_00439108 != 0) {
            OtCloseWaveAudioDevice_0040d0a0_RealCpp();
        }
        return 1;

    case 0x046c:
        if (state != 0) {
            state->distance_per_day = (DAT_004390e0 * 500) / 0x32;
        }
        return 1;

    case 0x0477:
        if (state != 0) {
            reinterpret_cast<TrailAnimationState_0042d460*>(state)->
                OtMarkTrailDialogActive_RealCpp(
                    reinterpret_cast<int>(dialog));
            state->active_action = 1;
            if (OtCountLivingPartyMembers_RealCpp(g_journeyState) == 0) {
                PostMessageA(GetParent(dialog), 0x047d, 0, 0);
            } else if (state->travel_submode == 0) {
                reinterpret_cast<TrailModeState_0042a790_20260603*>(state)->
                    OtUpdateTrailModeAfterAction_20260603_RealCpp(dialog);
            }
        }
        return 1;

    case 0x047d:
        PostMessageA(GetParent(dialog), 0x047d, 0, 0);
        return 1;
    }

    return 0;
}

#pragma optimize("", on)

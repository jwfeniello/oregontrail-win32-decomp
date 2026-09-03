// Trail event handlers and journey/dialog flow control split out of
// semantic_10pct_functions.cpp during the per-subsystem repartition pass.
//
// Functions here drive the per-day trail-event runner (broken wagons, weather,
// injuries, lost members, etc.), the trail UI dialogs (guidebook, status,
// trade, talk), the trail calendar/date, the route-divide choice, the
// title-attract animation tick, and the WM_PAINT entry point for the trail
// game dialog.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "trail_event_text_runtime.h"

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
extern "C" __declspec(dllimport) void* __stdcall GetMenu(void* window);
extern "C" __declspec(dllimport) void* __stdcall GetSubMenu(
    void* menu,
    int position);
extern "C" __declspec(dllimport) unsigned int __stdcall GetMenuState(
    void* menu,
    unsigned int item_id,
    unsigned int flags);
extern "C" __declspec(dllimport) unsigned int __stdcall CheckMenuItem(
    void* menu,
    unsigned int item_id,
    unsigned int check);
extern "C" __declspec(dllimport) int __stdcall DrawMenuBar(void* window);
extern "C" __declspec(dllimport) int __stdcall IsBadCodePtr(void* procedure);
extern "C" __declspec(dllimport) void* __stdcall CreateDialogParamA(
    void* instance,
    const char* template_name,
    void* parent_window,
    void* dialog_proc,
    long init_param);
extern "C" __declspec(dllimport) int __stdcall FreeResource(void* resource);
extern "C" __declspec(dllimport) int __stdcall InvalidateRect(
    void* window,
    const void* rect,
    int erase);
extern "C" __declspec(dllimport) int __stdcall UpdateWindow(void* window);
extern "C" __declspec(dllimport) int __stdcall ShowWindow(
    void* window,
    int command_show);
extern "C" __declspec(dllimport) int __stdcall SetWindowTextA(
    void* window,
    const char* text);
extern "C" __declspec(dllimport) void* __stdcall GetParent(void* window);
extern "C" __declspec(dllimport) int __stdcall PostMessageA(
    void* window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall GetUpdateRect(
    void* window,
    void* rect,
    int erase);
extern "C" __declspec(dllimport) void* __stdcall BeginPaint(
    void* window,
    void* paint);
extern "C" __declspec(dllimport) void* __stdcall SelectPalette(
    void* dc,
    void* palette,
    int force_background);
extern "C" __declspec(dllimport) int __stdcall UnrealizeObject(void* object);
extern "C" __declspec(dllimport) unsigned int __stdcall RealizePalette(
    void* dc);
extern "C" __declspec(dllimport) int __stdcall EndPaint(
    void* window,
    void* paint);

// ABI-preserving import slots used by the recovered Product event handlers and
// older isolated candidates.  They are bound to the real imports, never null.
extern "C" long (__stdcall *PTR_SendMessageA_0040feb0)(
    void* window,
    unsigned int message,
    unsigned int wparam,
    long lparam) = SendMessageA;
extern "C" int (__stdcall *PTR_LoadStringA_004177e0)(
    void* instance,
    unsigned int string_id,
    char* buffer,
    int buffer_max) = LoadStringA;
extern "C" int (__stdcall *PTR_FreeResource_0040b690)(
    void* resource) = FreeResource;

extern "C" int g_trailProgressStopPending;
extern "C" int g_cdMediaMode_00439108;
extern "C" int g_titleThemeEnabled_004390ec;
extern "C" unsigned int g_midiPlaybackActive_0040cd60;
extern "C" int g_titleAttractAnimationEnabled = 0;
extern "C" int g_titleAttractAlternateFrame = 0;
extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" void* g_resourceModule = 0;
extern "C" void* g_gamePalette = 0;
extern "C" void* g_trailEventTextArgument = 0;
extern "C" char g_trailEventMessageBuffer[0x22] = {0};
extern "C" void* g_trailEventDialogWindow = 0;
extern "C" char g_trailEventTempText[0x1d] = {0};
extern "C" void* g_graveSiteRuntime = 0;
extern "C" long __stdcall OtGuideBookDialogProc_00409e50_RealCpp(
    void* dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" long __stdcall OtStatusDialogProc_0041d040_ProductWip(
    void* dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" long __stdcall OtTalkDialogProc_00421020_ProductWip(
    void* dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" long __stdcall OtTradeSelectionDialogProc_0040ded0_ProductWip(
    void* dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" long __stdcall OtTrailDivideDialogProc_0041c980_ProductWip(
    void* dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam);
#define g_trailEventPromptText (g_trailEventRuntimeState.primary_text)
#define g_trailEventFollowupText (g_trailEventRuntimeState.secondary_text)
extern "C" void* g_activeRouteDescriptor = 0;
extern "C" void* g_cachedTrailResourceHandle = 0;
extern "C" short g_calendarMonthLengths[12] = {
    31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
};

extern "C" int __cdecl OtRandomBelow_RealCpp(int upper_bound);
extern "C" void __cdecl OtTriggerTrailEventById_RealCpp(short event_id);
extern "C" short __cdecl OtResolveBrokenSupplyEvent_00017190_ProductWip(
    void* event,
    short supply_count,
    unsigned short shortage_flag);
extern "C" short __fastcall
OtChooseRandomLivingPartyMemberSlotAlt27NoAsm_004195f0_40pct(
    const void* party);
extern "C" short __fastcall OtCountLivingPartyMembers_RealCpp(const void* party);
void __cdecl operator delete(void* block);
extern "C" void __cdecl OtDeleteTrailEventObjectTable_RealCpp();
extern "C" void __cdecl OtCloseWaveAudioDevice_0040d0a0_RealCpp();
extern "C" void __stdcall OtAddTrailDelayDays_00416380_RealCpp(short days);
extern "C" int __cdecl
OtRunModalDialogAndRefreshParentAlt1_00401530_38pct(
    void* instance,
    void* parent_window,
    void* dialog_proc,
    const char* template_name,
    long init_param);

extern "C" void __cdecl OtOpenMidiAudioFileMaskClosed_0000cd60_RealCpp(
    void* owner_window,
    const char* filename);
extern "C" void __cdecl OtStopMidiAudioDirectImport_0040d010_RealCpp();
extern "C" void __cdecl OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();

#pragma pack(push, 1)
struct JourneyState_00424e30 {
    char reserved_000[0x50];
    short weather_variant;
    char reserved_052[2];
    short storm_distance_penalty;
    short river_route_state;
    char reserved_058[2];
    short route_stop_flags;
    char reserved_05c[0x34];
    short ration_level;
    short trail_pace;
    char reserved_094[2];
    short oxen_count;
    short ox_sick;
    short health_penalty_a;
    short health_penalty_b;
    short wagon_wheels;
    short wagon_axles;
    short wagon_tongues;
    short food_from_plants;
    short food_from_hunting;
    char reserved_0a8[4];
    short trail_condition;
    char reserved_0ae[0x12];
    char party_member_names[5][15];
    char reserved_10b[1];
    short recovery_days[5];
    short member_state[5];
    char reserved_120[2];
    short delay_days;
    char reserved_124[0x16];
    short late_season_marker;
};

struct RouteDescriptor_00424e30 {
    char reserved_000[0x124];
    unsigned short location_bitmap_resource_ids[6];
};

struct TrailAnimationState_0042cfc0 {
    char reserved_000[0xa1c];
    int travel_submode;
    int river_crossing_mode;
    char reserved_a24[0x24];
    unsigned int progress;
    unsigned int progress_end;
};

struct TrailEventRunner_00416c50 {
    char reserved_00[6];
    short message_count;
    char reserved_08[0x22];
    int party_member_event_pending[5];

    void OtPrimeActiveTrailEventContextDependency_RealCpp();
    void OtSetTrailDelayDaysDependency_RealCpp(short days);
    void OtRunPartyRecoveryEvent_RealCpp();
    void OtRunBlizzardEvent_RealCpp();
    void OtRunDustStormEvent_RealCpp();
    void OtRunHeavyFogEvent_RealCpp();
    void OtRunNoWaterEvent_RealCpp();
    void OtRunSevereStormEvent_RealCpp();
    void OtRunGraveSiteEvent_RealCpp();
    void OtRunBadWaterEvent_RealCpp();
    void OtRunHailStormEvent_RealCpp();
    void OtRunTrailImpassableEvent_RealCpp();
    void OtRunWanderingOxEvent_RealCpp();
    void OtRunLostTrailEvent_RealCpp();
    void OtRunLostPartyMemberEvent_RealCpp();
    void OtRunNoGrassForOxenEvent_RealCpp();
    void OtRunRoughTrailEvent_RealCpp();
    void OtRunBrokenArmEvent_RealCpp();
    void OtRunBrokenLegEvent_RealCpp();
    void OtRunSnakeBiteEvent_RealCpp();
    void OtRunSnowboundWagonEvent_RealCpp();
    void OtRunWrongTrailEvent_RealCpp();
    void OtRunOxSickEvent_RealCpp();
    void OtRunBrokenWagonWheelEvent_RealCpp();
    void OtRunBrokenWagonAxleEvent_RealCpp();
    void OtRunBrokenWagonTongueEvent_RealCpp();
    void OtRunWildFruitEvent_RealCpp();
};

struct TrailEventVirtual_00416cb0 {
    virtual void OtUnusedDependency_RealCpp();
    virtual void OtDispatchPendingEventDependency_RealCpp();
};

struct RuntimeWindowState_00405720 {
    char reserved_00[4];
    void* main_window;

    void OtToggleMenuItemCheckState_RealCpp(
        unsigned int menu_item_id,
        int unused);
};

struct TrailEventContextSource_004163c0 {
    void OtPrimeActiveTrailEventContext_004163c0_RealCpp();
};

struct TrailAnimationState_0042d460 {
    void OtSyncTrailActionControls_RealCpp(
        void* owner_window,
        int repaint);
};

struct TrailOverlayWindow_00405df0 {
    void OtPlayCurrentRouteAudioCue_00405e00_ProductWip(
        void* owner_window);
};

struct TrailJournalState_0040f950 {
    void OtAppendTrailJournalText_0040f950_ProductWip(
        const char* pending_text);
};

struct TrailUiState_0042b370 {
    char reserved_000[4];
    void* active_dialog;
    char reserved_008[0x780];
    TrailOverlayWindow_00405df0* route_audio_context;
    char reserved_78c[0x280];
    TrailJournalState_0040f950* trail_journal;
    char reserved_a10[8];
    int cycling_dialog_index;
    int travel_submode;

    void OtOpenGuideBookDialog_RealCpp(void* owner_window, long guide_page);
    void OtOpenStatusDialog_RealCpp(void* owner_window);
    void OtOpenCyclingTalkDialog_RealCpp(void* owner_window);
    void OtRunTradeSelectionDialog_RealCpp(void* owner_window);
    void OtPauseTrailTravel_RealCpp(void* owner_window);
    void OtRefreshTrailStatusPanel_0042d5d0_ProductWip(
        void* owner_window);
};

struct TitleAttractState_0041c920 {
    char reserved_000[0x18];
    char invalid_rect[0x216];
    int frame_index;
};

struct PositionedBitmapDescriptorState_0040ba40 {
    int OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
        void* module,
        short bitmap_resource_id,
        short left,
        short top,
        short width,
        short height);
};

struct LabeledBitmapDisplay_00405f00 {
    PositionedBitmapDescriptorState_0040ba40* bitmap;
    void* label_window;

    void OtUpdateLabeledBitmapDisplay_RealCpp(
        unsigned int bitmap_resource_id,
        unsigned int label_string_id,
        int preserve_label_visibility);
};

struct TrailStopTransitionState_0042a680 {
    char reserved_000[0xa48];
    unsigned int progress;
    unsigned int progress_end;

    int OtCheckForTrailStopTransition_RealCpp(void* owner_window, int* stop_state);
};

struct TrailPaintState_0042aad0_20260605 {
    void OtPaintTrailScene_20260605_RealCpp(void* window, void* dc);
};

struct GameDateTextState_00419300 {
    void OtRefreshGameDateText_00419300_RealCpp();
};

struct TrailDateState_00419280 {
    char reserved_00[0x14];
    short year;
    short month;
    short day;

    void OtAdvanceGameDate_RealCpp();
};

#pragma pack(pop)

extern "C" JourneyState_00424e30* g_journeyState;
extern "C" TrailEventVirtual_00416cb0* g_pendingTrailEventDispatcher = 0;
extern "C" TrailPaintState_0042aad0_20260605* g_trailGamePainter = 0;

#pragma code_seg(".otsem")

// Preserve the recovered call-site ABI while forwarding to the canonical
// Product implementations.  These bridges carry behavior; none are matcher
// no-ops or null import anchors.
void TrailEventRunner_00416c50::
    OtPrimeActiveTrailEventContextDependency_RealCpp()
{
    reinterpret_cast<TrailEventContextSource_004163c0*>(this)
        ->OtPrimeActiveTrailEventContext_004163c0_RealCpp();
}

void TrailEventRunner_00416c50::OtSetTrailDelayDaysDependency_RealCpp(
    short days)
{
    OtAddTrailDelayDays_00416380_RealCpp(days);
}

void TrailEventTextRuntime_0041aac0_20260603::
    OtSetTrailEventTextDependency_RealCpp(int string_id)
{
    OtFormatGameMessageText_0001ac80_ProductWip(string_id);
}

#pragma code_seg()

#pragma optimize("s", off)
#pragma optimize("t", on)

// 00418d10
//
// Picks which broken-wagon-part event should be queued.
extern "C" void __cdecl OtTriggerRandomBrokenWagonPartEvent_RealCpp()
{
    int part = OtRandomBelow_RealCpp(3);

    switch (part) {
    case 0:
        OtTriggerTrailEventById_RealCpp(0x11);
        break;
    case 1:
        OtTriggerTrailEventById_RealCpp(0x12);
        break;
    case 2:
        OtTriggerTrailEventById_RealCpp(0x13);
        break;
    }
}

// 0042cfc0
//
// Tests whether the trail animation can advance in the current global state.
extern "C" int __fastcall OtCanAdvanceTrailAnimation_RealCpp(
    TrailAnimationState_0042cfc0* animation)
{
    if (g_trailProgressStopPending == 0 &&
        g_journeyState->route_stop_flags == 0 &&
        animation->river_crossing_mode != 2 &&
        animation->travel_submode != 1) {
        unsigned int progress_end = animation->progress_end;
        if (animation->progress < progress_end) {
            return 1;
        }
    }

    return 0;
}

// 00424e30
//
// Selects the route/location illustration resource ID for route, weather, and
// late-season variants.
extern "C" unsigned int __fastcall OtSelectRouteLocationBitmapResourceId_RealCpp(
    RouteDescriptor_00424e30* route)
{
    int variant_index = 0;

    if (g_journeyState->river_route_state != 0) {
        variant_index = 2;
    } else if (g_journeyState->late_season_marker >= 8 &&
               g_journeyState->late_season_marker <= 10) {
        variant_index = 4;
    }

    if (g_journeyState->weather_variant > 0) {
        ++variant_index;
    }

    return route->location_bitmap_resource_ids[variant_index];
}

// 0042d400
//
// Pauses trail travel, updates action controls, stops active audio playback,
// and refreshes the trail view after the pause transition.
void TrailUiState_0042b370::OtPauseTrailTravel_RealCpp(void* owner_window)
{
    TrailUiState_0042b370* state = this;
    void* owner = owner_window;

    if (state->travel_submode != 1) {
        state->travel_submode = 1;
        reinterpret_cast<TrailAnimationState_0042d460*>(state)
            ->OtSyncTrailActionControls_RealCpp(owner, 1);

        if (g_midiPlaybackActive_0040cd60 != 0) {
            OtStopMidiAudioDirectImport_0040d010_RealCpp();
        }

        if (g_cdMediaMode_00439108 != 0) {
            OtCloseWaveAudioDevice_0040d0a0_RealCpp();
        } else if (g_midiPlaybackActive_0040cd60 != 0) {
            OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();
        }

        state->OtRefreshTrailStatusPanel_0042d5d0_ProductWip(owner);
    }
}

// 0042b370
//
// Opens the guidebook dialog and resumes route audio when travel is still
// active behind the modal dialog.
void TrailUiState_0042b370::OtOpenGuideBookDialog_RealCpp(
    void* owner_window,
    long guide_page)
{
    void* owner = owner_window;
    TrailUiState_0042b370* state = this;

    OtRunModalDialogAndRefreshParentAlt1_00401530_38pct(
        g_resourceModule,
        owner,
        reinterpret_cast<void*>(OtGuideBookDialogProc_00409e50_RealCpp),
        reinterpret_cast<const char*>(0xfa),
        guide_page);

    if (g_titleThemeEnabled_004390ec != 0 &&
        state->travel_submode != 0 &&
        g_trailProgressStopPending != 0 &&
        g_journeyState->route_stop_flags == 0) {
        state->route_audio_context
            ->OtPlayCurrentRouteAudioCue_00405e00_ProductWip(owner);
    }
}

// 0042b980
//
// Opens the status dialog, recreating the cached status dialog window handle
// if the previous one is invalid.
void TrailUiState_0042b370::OtOpenStatusDialog_RealCpp(void* owner_window)
{
    TrailUiState_0042b370* state = this;
    void* owner = owner_window;

    if (IsBadCodePtr(state->active_dialog) != 0) {
        state->active_dialog =
            reinterpret_cast<void*>(OtStatusDialogProc_0041d040_ProductWip);
    }

    CreateDialogParamA(
        g_applicationModule_00405a40_20260603,
        reinterpret_cast<const char*>(0xf1),
        owner,
        state->active_dialog,
        0);

    if (g_titleThemeEnabled_004390ec != 0 &&
        state->travel_submode != 0 &&
        g_trailProgressStopPending != 0 &&
        g_journeyState->route_stop_flags == 0) {
        state->route_audio_context
            ->OtPlayCurrentRouteAudioCue_00405e00_ProductWip(owner);
    }
}

// 0042b9f0
//
// Opens one of the cycling talk/info dialogs and advances the cycling index.
void TrailUiState_0042b370::OtOpenCyclingTalkDialog_RealCpp(void* owner_window)
{
    TrailUiState_0042b370* state = this;
    void* owner = owner_window;

    OtRunModalDialogAndRefreshParentAlt1_00401530_38pct(
        g_resourceModule,
        owner,
        reinterpret_cast<void*>(OtTalkDialogProc_00421020_ProductWip),
        reinterpret_cast<const char*>(0xf5),
        state->cycling_dialog_index);

    state->cycling_dialog_index = (state->cycling_dialog_index + 1) % 3;

    if (g_titleThemeEnabled_004390ec != 0 &&
        state->travel_submode != 0 &&
        g_trailProgressStopPending != 0 &&
        g_journeyState->route_stop_flags == 0) {
        state->route_audio_context
            ->OtPlayCurrentRouteAudioCue_00405e00_ProductWip(owner);
    }

}

// 0042ba70
//
// Runs the trade-selection dialog and refreshes trail state if a trade was
// accepted.
void TrailUiState_0042b370::OtRunTradeSelectionDialog_RealCpp(void* owner_window)
{
    int accepted;
    TrailUiState_0042b370* state = this;
    void* owner = owner_window;

    OtRunModalDialogAndRefreshParentAlt1_00401530_38pct(
        g_applicationModule_00405a40_20260603,
        owner,
        reinterpret_cast<void*>(OtTradeSelectionDialogProc_0040ded0_ProductWip),
        reinterpret_cast<const char*>(0xfc),
        reinterpret_cast<long>(&accepted));

    if (accepted != 0) {
        state->trail_journal
            ->OtAppendTrailJournalText_0040f950_ProductWip(
                g_trailEventFollowupText);
        state->OtRefreshTrailStatusPanel_0042d5d0_ProductWip(owner);
    }

    if (g_titleThemeEnabled_004390ec != 0 &&
        state->travel_submode != 0 &&
        g_trailProgressStopPending != 0 &&
        g_journeyState->route_stop_flags == 0) {
        state->route_audio_context
            ->OtPlayCurrentRouteAudioCue_00405e00_ProductWip(owner);
    }
}

// 00416c50
//
// Runs the "no water" trail event, applying a ten-day delay and posting the
// event-message text when the party is still alive or the event must be shown.
void TrailEventRunner_00416c50::OtRunNoWaterEvent_RealCpp()
{
    TrailEventRunner_00416c50* event = this;

    event->OtPrimeActiveTrailEventContextDependency_RealCpp();
    g_journeyState->delay_days = 10;
    g_trailEventRuntimeState.OtSetTrailEventTextDependency_RealCpp(0x2e0);

    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
        event->message_count == 1) {
        SendMessageA(
            g_trailEventDialogWindow,
            0x477,
            static_cast<unsigned short>(event->message_count),
            reinterpret_cast<long>(g_trailEventMessageBuffer));
    }
}

// 00416fd0
//
// Runs the bad-water trail event, applying a twenty-day delay.
void TrailEventRunner_00416c50::OtRunBadWaterEvent_RealCpp()
{
    TrailEventRunner_00416c50* event = this;

    event->OtPrimeActiveTrailEventContextDependency_RealCpp();
    g_journeyState->delay_days = 20;
    g_trailEventRuntimeState.OtSetTrailEventTextDependency_RealCpp(0x2f6);

    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
        event->message_count == 1) {
        SendMessageA(
            g_trailEventDialogWindow,
            0x477,
            static_cast<unsigned short>(event->message_count),
            reinterpret_cast<long>(g_trailEventMessageBuffer));
    }
}

// 00417890
//
// Runs the rough-trail event, applying a ten-day delay.
void TrailEventRunner_00416c50::OtRunRoughTrailEvent_RealCpp()
{
    TrailEventRunner_00416c50* event = this;

    event->OtPrimeActiveTrailEventContextDependency_RealCpp();
    g_journeyState->delay_days = 10;
    g_trailEventRuntimeState.OtSetTrailEventTextDependency_RealCpp(0x324);

    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
        event->message_count == 1) {
        SendMessageA(
            g_trailEventDialogWindow,
            0x477,
            static_cast<unsigned short>(event->message_count),
            reinterpret_cast<long>(g_trailEventMessageBuffer));
    }
}

// 00416ab0
//
// Runs the dust-storm event, recording the weather variant and delay.
void TrailEventRunner_00416c50::OtRunDustStormEvent_RealCpp()
{
    TrailEventRunner_00416c50* event = this;

    event->OtPrimeActiveTrailEventContextDependency_RealCpp();
    event->OtSetTrailDelayDaysDependency_RealCpp(1);
    g_journeyState->weather_variant = 10;
    g_trailEventRuntimeState.OtSetTrailEventTextDependency_RealCpp(0x2d4);

    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
        event->message_count == 1) {
        SendMessageA(
            g_trailEventDialogWindow,
            0x477,
            static_cast<unsigned short>(event->message_count),
            reinterpret_cast<long>(g_trailEventMessageBuffer));
    }
}

// 00416b20
//
// Runs the heavy-fog event, recording the weather variant and delay.
void TrailEventRunner_00416c50::OtRunHeavyFogEvent_RealCpp()
{
    TrailEventRunner_00416c50* event = this;

    event->OtPrimeActiveTrailEventContextDependency_RealCpp();
    event->OtSetTrailDelayDaysDependency_RealCpp(1);
    g_journeyState->weather_variant = 11;
    g_trailEventRuntimeState.OtSetTrailEventTextDependency_RealCpp(0x2d8);

    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
        event->message_count == 1) {
        SendMessageA(
            g_trailEventDialogWindow,
            0x477,
            static_cast<unsigned short>(event->message_count),
            reinterpret_cast<long>(g_trailEventMessageBuffer));
    }
}

// 004174b0
//
// Runs an impassable-trail event and applies a random one-to-ten day delay.
void TrailEventRunner_00416c50::OtRunTrailImpassableEvent_RealCpp()
{
    TrailEventRunner_00416c50* event = this;
    short delay_days;

    event->OtPrimeActiveTrailEventContextDependency_RealCpp();
    delay_days = static_cast<short>(OtRandomBelow_RealCpp(10) + 1);
    event->OtSetTrailDelayDaysDependency_RealCpp(delay_days);
    g_trailEventRuntimeState.OtSetTrailEventTextDependency_RealCpp(0x30c);

    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
        event->message_count == 1) {
        SendMessageA(
            g_trailEventDialogWindow,
            0x477,
            static_cast<unsigned short>(event->message_count),
            reinterpret_cast<long>(g_trailEventMessageBuffer));
    }
}

// 00417660
//
// Runs a wandering-ox event and applies a random one-to-three day delay.
void TrailEventRunner_00416c50::OtRunWanderingOxEvent_RealCpp()
{
    TrailEventRunner_00416c50* event = this;
    short delay_days;

    event->OtPrimeActiveTrailEventContextDependency_RealCpp();
    delay_days = static_cast<short>(OtRandomBelow_RealCpp(3) + 1);
    event->OtSetTrailDelayDaysDependency_RealCpp(delay_days);
    g_trailEventRuntimeState.OtSetTrailEventTextDependency_RealCpp(0x314);

    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
        event->message_count == 1) {
        SendMessageA(
            g_trailEventDialogWindow,
            0x477,
            static_cast<unsigned short>(event->message_count),
            reinterpret_cast<long>(g_trailEventMessageBuffer));
    }
}

// 00417770
//
// Runs the lost-trail event and applies a random one-to-five day delay.
void TrailEventRunner_00416c50::OtRunLostTrailEvent_RealCpp()
{
    TrailEventRunner_00416c50* event = this;
    short delay_days;

    event->OtPrimeActiveTrailEventContextDependency_RealCpp();
    delay_days = static_cast<short>(OtRandomBelow_RealCpp(5) + 1);
    event->OtSetTrailDelayDaysDependency_RealCpp(delay_days);
    g_trailEventRuntimeState.OtSetTrailEventTextDependency_RealCpp(0x31c);

    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
        event->message_count == 1) {
        SendMessageA(
            g_trailEventDialogWindow,
            0x477,
            static_cast<unsigned short>(event->message_count),
            reinterpret_cast<long>(g_trailEventMessageBuffer));
    }
}

// 004179a0
//
// Runs the snowbound-wagon event and applies a random one-to-ten day delay.
void TrailEventRunner_00416c50::OtRunSnowboundWagonEvent_RealCpp()
{
    TrailEventRunner_00416c50* event = this;
    short delay_days;

    event->OtPrimeActiveTrailEventContextDependency_RealCpp();
    delay_days = static_cast<short>(OtRandomBelow_RealCpp(10) + 1);
    event->OtSetTrailDelayDaysDependency_RealCpp(delay_days);
    g_trailEventRuntimeState.OtSetTrailEventTextDependency_RealCpp(0x32c);

    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
        event->message_count == 1) {
        SendMessageA(
            g_trailEventDialogWindow,
            0x477,
            static_cast<unsigned short>(event->message_count),
            reinterpret_cast<long>(g_trailEventMessageBuffer));
    }
}

// 00417b20
//
// Runs the wrong-trail event and applies a random one-to-five day delay.
void TrailEventRunner_00416c50::OtRunWrongTrailEvent_RealCpp()
{
    TrailEventRunner_00416c50* event = this;
    short delay_days;

    event->OtPrimeActiveTrailEventContextDependency_RealCpp();
    delay_days = static_cast<short>(OtRandomBelow_RealCpp(5) + 1);
    event->OtSetTrailDelayDaysDependency_RealCpp(delay_days);
    g_trailEventRuntimeState.OtSetTrailEventTextDependency_RealCpp(0x334);

    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
        event->message_count == 1) {
        SendMessageA(
            g_trailEventDialogWindow,
            0x477,
            static_cast<unsigned short>(event->message_count),
            reinterpret_cast<long>(g_trailEventMessageBuffer));
    }
}

// 004173d0
//
// Handles a broken wagon wheel event, consuming the route-stop spare flag when
// possible before committing the remaining wheel count.
void TrailEventRunner_00416c50::OtRunBrokenWagonWheelEvent_RealCpp()
{
    TrailEventRunner_00416c50* event = this;

    PTR_LoadStringA_004177e0(g_applicationModule_00405a40_20260603, 0x38a, g_trailEventTempText, 0x1d);
    JourneyState_00424e30* source = g_journeyState;
    g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText;
    short wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
        event,
        source->wagon_wheels,
        2);
    JourneyState_00424e30* journey = g_journeyState;
    short* flags = &journey->route_stop_flags;
    short route_stop_flags = *flags;
    short spare_flag = static_cast<short>(route_stop_flags & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}

// 004172d0
//
// Handles a broken wagon axle event, using the same broken-supply flow as
// wheels but with the axle inventory and shortage bit.
void TrailEventRunner_00416c50::OtRunBrokenWagonAxleEvent_RealCpp()
{
    TrailEventRunner_00416c50* event = this;

    PTR_LoadStringA_004177e0(g_applicationModule_00405a40_20260603, 0x38c, g_trailEventTempText, 0x1d);
    JourneyState_00424e30* source = g_journeyState;
    g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText;
    short axles = OtResolveBrokenSupplyEvent_00017190_ProductWip(
        event,
        source->wagon_axles,
        4);
    JourneyState_00424e30* journey = g_journeyState;
    short* flags = &journey->route_stop_flags;
    short route_stop_flags = *flags;
    short spare_flag = static_cast<short>(route_stop_flags & 4);

    if (spare_flag != 0 && axles > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 4);
        }
        --axles;
    }

    journey->wagon_axles = axles;
}

// 00417350
//
// Handles a broken wagon tongue event, updating tongue inventory and the
// matching spare/shortage bit after the shared broken-supply resolution.
void TrailEventRunner_00416c50::OtRunBrokenWagonTongueEvent_RealCpp()
{
    TrailEventRunner_00416c50* event = this;

    PTR_LoadStringA_004177e0(g_applicationModule_00405a40_20260603, 0x38e, g_trailEventTempText, 0x1d);
    JourneyState_00424e30* source = g_journeyState;
    g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText;
    short tongues = OtResolveBrokenSupplyEvent_00017190_ProductWip(
        event,
        source->wagon_tongues,
        8);
    JourneyState_00424e30* journey = g_journeyState;
    short* flags = &journey->route_stop_flags;
    short route_stop_flags = *flags;
    short spare_flag = static_cast<short>(route_stop_flags & 8);

    if (spare_flag != 0 && tongues > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 8);
        }
        --tongues;
    }

    journey->wagon_tongues = tongues;
}

// 00416de0
//
// Runs the grave-site event and marks the grave overlay/context as visited.
void TrailEventRunner_00416c50::OtRunGraveSiteEvent_RealCpp()
{
    TrailEventRunner_00416c50* event = this;

    event->OtPrimeActiveTrailEventContextDependency_RealCpp();
    g_trailEventRuntimeState.OtSetTrailEventTextDependency_RealCpp(0x2ee);

    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
        event->message_count == 1) {
        SendMessageA(
            g_trailEventDialogWindow,
            0x477,
            static_cast<unsigned short>(event->message_count),
            reinterpret_cast<long>(g_trailEventMessageBuffer));
    }

    *reinterpret_cast<int*>(static_cast<char*>(g_graveSiteRuntime) + 0x44) = 1;
}

// 004165f0
//
// Emits pending "party member is well again" messages and clears each member's
// queued recovery flag.
void TrailEventRunner_00416c50::OtRunPartyRecoveryEvent_RealCpp()
{
    TrailEventRunner_00416c50* event = this;
    short index = 0;

    event->OtPrimeActiveTrailEventContextDependency_RealCpp();
    do {
        int member_index = index;
        if (event->party_member_event_pending[member_index] == 1) {
            g_trailEventRuntimeState.name_pointer =
                &g_journeyState->party_member_names[member_index][0];
            g_trailEventRuntimeState.OtSetTrailEventTextDependency_RealCpp(0x2c8);
            event->party_member_event_pending[member_index] = 0;

            if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
                event->message_count == 1) {
                PTR_SendMessageA_0040feb0(
                    g_trailEventDialogWindow,
                    0x477,
                    static_cast<unsigned short>(event->message_count),
                    reinterpret_cast<long>(g_trailEventMessageBuffer));
            }
        }
        ++index;
    } while (index < 5);
}

// 004176d0
//
// Runs the lost-party-member event, formats the selected member's name, applies
// a random delay, and chooses one of the lost/found messages.
void TrailEventRunner_00416c50::OtRunLostPartyMemberEvent_RealCpp()
{
    TrailEventRunner_00416c50* event = this;
    short member_index;

    event->OtPrimeActiveTrailEventContextDependency_RealCpp();
    member_index =
        OtChooseRandomLivingPartyMemberSlotAlt27NoAsm_004195f0_40pct(
            g_journeyState);
    if (member_index != 0) {
        g_trailEventRuntimeState.name_pointer =
            &g_journeyState->party_member_names[member_index][0];

        event->OtSetTrailDelayDaysDependency_RealCpp(
            static_cast<short>(OtRandomBelow_RealCpp(5) + 1));

g_trailEventRuntimeState.OtSetTrailEventTextDependency_RealCpp(
            OtRandomBelow_RealCpp(3) + 0x318);

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

// 00417030
//
// Runs the broken-arm event by marking one living party member injured and
// extending their recovery timer.
void TrailEventRunner_00416c50::OtRunBrokenArmEvent_RealCpp()
{
    TrailEventRunner_00416c50* event = this;
    int member_index =
        OtChooseRandomLivingPartyMemberSlotAlt27NoAsm_004195f0_40pct(
            g_journeyState);
    short recovery_days;
    short* recovery_slot;

    g_journeyState->member_state[member_index] = 8;
    recovery_days = static_cast<short>(OtRandomBelow_RealCpp(6) + 0x1c);
    recovery_slot = &g_journeyState->recovery_days[member_index];
    if (*recovery_slot < recovery_days) {
        *recovery_slot = recovery_days;
    }

    event->OtPrimeActiveTrailEventContextDependency_RealCpp();
    g_trailEventRuntimeState.name_pointer =
        &g_journeyState->party_member_names[member_index][0];
    g_trailEventRuntimeState.OtSetTrailEventTextDependency_RealCpp(0x2fa);

    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
        event->message_count == 1) {
        SendMessageA(
            g_trailEventDialogWindow,
            0x477,
            static_cast<unsigned short>(event->message_count),
            reinterpret_cast<long>(g_trailEventMessageBuffer));
    }
}

// 004170e0
//
// Runs the broken-leg event; same recovery-timer path as broken arm with a
// different injury state and message.
void TrailEventRunner_00416c50::OtRunBrokenLegEvent_RealCpp()
{
    TrailEventRunner_00416c50* event = this;
    int member_index =
        OtChooseRandomLivingPartyMemberSlotAlt27NoAsm_004195f0_40pct(
            g_journeyState);
    short recovery_days;
    short* recovery_slot;

    g_journeyState->member_state[member_index] = 7;
    recovery_days = static_cast<short>(OtRandomBelow_RealCpp(6) + 0x1c);
    recovery_slot = &g_journeyState->recovery_days[member_index];
    if (*recovery_slot < recovery_days) {
        *recovery_slot = recovery_days;
    }

    event->OtPrimeActiveTrailEventContextDependency_RealCpp();
    g_trailEventRuntimeState.name_pointer =
        &g_journeyState->party_member_names[member_index][0];
    g_trailEventRuntimeState.OtSetTrailEventTextDependency_RealCpp(0x2fe);

    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
        event->message_count == 1) {
        SendMessageA(
            g_trailEventDialogWindow,
            0x477,
            static_cast<unsigned short>(event->message_count),
            reinterpret_cast<long>(g_trailEventMessageBuffer));
    }
}

// 004178f0
//
// Runs the snake-bite event for a randomly selected living party member.
void TrailEventRunner_00416c50::OtRunSnakeBiteEvent_RealCpp()
{
    TrailEventRunner_00416c50* event = this;
    short member_index;
    int member_index32;
    short recovery_days;
    short* recovery_slot;

    event->OtPrimeActiveTrailEventContextDependency_RealCpp();
    member_index =
        OtChooseRandomLivingPartyMemberSlotAlt27NoAsm_004195f0_40pct(
            g_journeyState);
    recovery_days = static_cast<short>(OtRandomBelow_RealCpp(4) + 9);
    member_index32 = member_index;
    g_journeyState->member_state[member_index32] = 9;
    recovery_slot = &g_journeyState->recovery_days[member_index32];
    if (*recovery_slot < recovery_days) {
        *recovery_slot = recovery_days;
    }

    g_trailEventRuntimeState.name_pointer =
        &g_journeyState->party_member_names[member_index32][0];
    g_trailEventRuntimeState.OtSetTrailEventTextDependency_RealCpp(0x328);

    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
        event->message_count == 1) {
        SendMessageA(
            g_trailEventDialogWindow,
            0x477,
            static_cast<unsigned short>(event->message_count),
            reinterpret_cast<long>(g_trailEventMessageBuffer));
    }
}

// 00416cb0
//
// Runs the sick-ox event, escalating to the ox-death event when the temporary
// sickness flag was already set.
void TrailEventRunner_00416c50::OtRunOxSickEvent_RealCpp()
{
    TrailEventRunner_00416c50* event = this;
    short* sick_flag;

    if (g_journeyState->oxen_count != 0) {
        if (g_journeyState->trail_condition == 4 &&
            static_cast<short>(OtRandomBelow_RealCpp(2)) != 0) {
            return;
        }

        sick_flag = &g_journeyState->ox_sick;
        if (*sick_flag != 0) {
            g_pendingTrailEventDispatcher->OtDispatchPendingEventDependency_RealCpp();
            return;
        }

        *sick_flag = 1;
        event->OtPrimeActiveTrailEventContextDependency_RealCpp();
        g_trailEventRuntimeState.OtSetTrailEventTextDependency_RealCpp(0x2e4);

        if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
            event->message_count == 1) {
            SendMessageA(
                g_trailEventDialogWindow,
                0x477,
                static_cast<unsigned short>(event->message_count),
                reinterpret_cast<long>(g_trailEventMessageBuffer));
        }

        if (g_journeyState->oxen_count == 1) {
            *reinterpret_cast<unsigned char*>(&g_journeyState->route_stop_flags) =
                static_cast<unsigned char>(
                    *reinterpret_cast<unsigned char*>(&g_journeyState->route_stop_flags) | 1);
        }
    }
}

// 00416d70
//
// Runs the severe-storm event, adding a distance penalty and weather state.
void TrailEventRunner_00416c50::OtRunSevereStormEvent_RealCpp()
{
    TrailEventRunner_00416c50* event = this;

    event->OtPrimeActiveTrailEventContextDependency_RealCpp();
    event->OtSetTrailDelayDaysDependency_RealCpp(1);
    g_journeyState->weather_variant = 7;
    g_journeyState->storm_distance_penalty =
        static_cast<short>(g_journeyState->storm_distance_penalty + 100);
    g_trailEventRuntimeState.OtSetTrailEventTextDependency_RealCpp(0x2ea);

    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
        event->message_count == 1) {
        SendMessageA(
            g_trailEventDialogWindow,
            0x477,
            static_cast<unsigned short>(event->message_count),
            reinterpret_cast<long>(g_trailEventMessageBuffer));
    }
}

// 00417440
//
// Runs the hail-storm event, adding a smaller distance penalty.
void TrailEventRunner_00416c50::OtRunHailStormEvent_RealCpp()
{
    TrailEventRunner_00416c50* event = this;

    event->OtPrimeActiveTrailEventContextDependency_RealCpp();
    event->OtSetTrailDelayDaysDependency_RealCpp(1);
    g_journeyState->weather_variant = 9;
    g_journeyState->storm_distance_penalty =
        static_cast<short>(g_journeyState->storm_distance_penalty + 50);
    g_trailEventRuntimeState.OtSetTrailEventTextDependency_RealCpp(0x30a);

    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
        event->message_count == 1) {
        SendMessageA(
            g_trailEventDialogWindow,
            0x477,
            static_cast<unsigned short>(event->message_count),
            reinterpret_cast<long>(g_trailEventMessageBuffer));
    }
}

// 00416480
//
// Runs the blizzard event, setting weather and adding the heavy snow penalty.
void TrailEventRunner_00416c50::OtRunBlizzardEvent_RealCpp()
{
    TrailEventRunner_00416c50* event = this;

    event->OtPrimeActiveTrailEventContextDependency_RealCpp();
    event->OtSetTrailDelayDaysDependency_RealCpp(1);
    g_trailEventRuntimeState.OtSetTrailEventTextDependency_RealCpp(0x2d0);
    g_journeyState->weather_variant = 8;
    g_journeyState->river_route_state =
        static_cast<short>(g_journeyState->river_route_state + 0x320);

    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
        event->message_count == 1) {
        SendMessageA(
            g_trailEventDialogWindow,
            0x477,
            static_cast<unsigned short>(event->message_count),
            reinterpret_cast<long>(g_trailEventMessageBuffer));
    }
}

// 0041a270
//
// Releases the journey/runtime blocks allocated for an active trail session and
// clears the trail-event runtime before freeing the cached resource handle.
extern "C" void __cdecl OtShutdownJourneyRuntime_RealCpp()
{
    void* block;

    block = g_journeyState;
    if (block != 0) {
        ::operator delete(block);
        g_journeyState = 0;
    }

    block = g_activeRouteDescriptor;
    if (block != 0) {
        ::operator delete(block);
        g_activeRouteDescriptor = 0;
    }

    block = g_graveSiteRuntime;
    if (block != 0) {
        ::operator delete(block);
        g_graveSiteRuntime = 0;
    }

    OtDeleteTrailEventObjectTable_RealCpp();
    FreeResource(g_cachedTrailResourceHandle);
}

// 0042c110
//
// Opens the route-divide choice dialog. The current route index selects which
// dialog template and default branch value are shown to the player.
extern "C" int __stdcall OtRunTrailDivideChoiceDialog_RealCpp(void* owner_window)
{
    int route_choice;
    int template_id;
    short route_id = *reinterpret_cast<short*>(
        static_cast<char*>(g_activeRouteDescriptor) + 0x16);

    if (route_id == 9) {
        route_choice = 1;
        template_id = 0xe7;
    } else if (route_id == 0x10) {
        route_choice = 2;
        template_id = 0xe8;
    } else {
        route_choice = 3;
        template_id = 0xe9;
    }

    OtRunModalDialogAndRefreshParentAlt1_00401530_38pct(
        g_applicationModule_00405a40_20260603,
        owner_window,
        reinterpret_cast<void*>(OtTrailDivideDialogProc_0041c980_ProductWip),
        reinterpret_cast<const char*>(template_id),
        reinterpret_cast<long>(&route_choice));

    return route_choice;
}

// 0041c920
//
// Advances the alternating title/attract animation frame and invalidates the
// frame rectangle when the title animation is enabled.
extern "C" void __cdecl OtToggleTitleAttractFrame_RealCpp(
    void* window,
    TitleAttractState_0041c920* title)
{
    void* owner_window;

    if (g_titleAttractAnimationEnabled != 0) {
        if (g_titleAttractAlternateFrame != 0) {
            g_titleAttractAlternateFrame = 0;
            title->frame_index = 1;
        } else {
            g_titleAttractAlternateFrame = 1;
            title->frame_index = 2;
        }

        owner_window = window;
        InvalidateRect(owner_window, &title->invalid_rect, 0);
        UpdateWindow(owner_window);
    }
}

// 00405f00
//
// Updates the caption text associated with a bitmap-backed display and reloads
// the indexed bitmap resource while retaining the display geometry.
void LabeledBitmapDisplay_00405f00::OtUpdateLabeledBitmapDisplay_RealCpp(
    unsigned int bitmap_resource_id,
    unsigned int label_string_id,
    int preserve_label_visibility)
{
    char text[100];
    LabeledBitmapDisplay_00405f00* display = this;

    LoadStringA(g_resourceModule, label_string_id, text, 0x63);
    if (preserve_label_visibility == 0) {
        ShowWindow(display->label_window, 0);
        SetWindowTextA(display->label_window, text);
    }

    display->bitmap->OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
        g_resourceModule,
        static_cast<short>(bitmap_resource_id),
        0,
        0,
        0,
        0);
}

// 0042a680
//
// Checks whether trail progress has reached a stop state, marks the global
// overlay flag for normal progress stops, and notifies the parent window for
// river-stop route nodes.
int TrailStopTransitionState_0042a680::OtCheckForTrailStopTransition_RealCpp(
    void* owner_window,
    int* stop_state)
{
    if (*stop_state <= 0) {
        if (g_journeyState->route_stop_flags == 0 &&
            progress < progress_end) {
            *stop_state = 0;
            g_trailProgressStopPending = 1;
        } else {
            *stop_state = 1;
        }

        {
            short route_node = *static_cast<short*>(g_activeRouteDescriptor);
            if (route_node == 0x12 || route_node == 0x11) {
                PostMessageA(GetParent(owner_window), 0x47b, 0, 0);
            }
        }
    }

    return 0;
}

// 0042f5c0
//
// Handles WM_PAINT for the trail game dialog, applying the game palette before
// delegating the actual scene/control painting to the dialog painter object.
extern "C" void __cdecl OtPaintTrailGameDialog_RealCpp(void* window)
{
    char update_rect[16];
    char paint[64];

    if (GetUpdateRect(window, update_rect, 0) != 0) {
        void* dc = BeginPaint(window, paint);
        SelectPalette(dc, g_gamePalette, 0);
        UnrealizeObject(g_gamePalette);
        RealizePalette(dc);
        g_trailGamePainter->OtPaintTrailScene_20260605_RealCpp(window, dc);
        EndPaint(window, paint);
    }
}

// 00419280
//
// Advances the trail calendar by one day, wrapping month/year state and
// updating February for the original leap-year rule before refreshing UI text.
void TrailDateState_00419280::OtAdvanceGameDate_RealCpp()
{
    register short current_month;
    register short next_day = day;

    ++next_day;
    current_month = month;
    day = next_day;

    if (g_calendarMonthLengths[current_month] < next_day) {
        day = 1;
        current_month = static_cast<short>(current_month + 1);
        month = current_month;

        if (current_month > 0x0b) {
            month = 0;
            year = static_cast<short>(year + 1);

            if (year % 4 != 0) {
                g_calendarMonthLengths[1] = 0x1c;
                reinterpret_cast<GameDateTextState_00419300*>(this)
                    ->OtRefreshGameDateText_00419300_RealCpp();
                return;
            }

            g_calendarMonthLengths[1] = 0x1d;
        }
    }

    reinterpret_cast<GameDateTextState_00419300*>(this)
        ->OtRefreshGameDateText_00419300_RealCpp();
}

#pragma optimize("", on)

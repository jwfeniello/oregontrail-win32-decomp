// Product-tree semantic closure for OtHandleChangePaceAction @ 0x0042b3d0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include <string.h>

#pragma intrinsic(memset, strcpy, strcat)

extern "C" int __cdecl
OtRunModalDialogAndRefreshParentAlt1_00401530_38pct(
    void* instance,
    void* parent_window,
    void* dialog_proc,
    const char* template_name,
    long init_param);
extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* instance,
    unsigned int string_id,
    char* buffer,
    int buffer_max);
extern "C" char* __cdecl _strlwr(char* text);
extern "C" void __cdecl OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();

#pragma pack(push, 1)
struct JourneyState_0042b3d0_20260603 {
    char reserved_000[0x5a];
    short route_stop_flags;
    char reserved_05c[0x36];
    short pace;

    short OtCountLivingPartyMembersDependency_20260603();
};

struct TrailDiary_0042b3d0_20260603 {
    void OtAppendTrailDiaryEntryDependency_20260603(char* message);
};

struct TrailPostAction_0042b3d0_20260603 {
    void OtRunPostPaceActionDependency_20260603(void* owner_window);
};

struct TrailDialogState_0042b3d0_20260603 {
    char reserved_000[0x788];
    TrailPostAction_0042b3d0_20260603* post_action;
    char reserved_78c[0x280];
    TrailDiary_0042b3d0_20260603* diary;
    char reserved_a10[0x0c];
    void* pending_post_action;

    void OtSwapVisiblePaceButtonDependency_20260603(
        void* dialog,
        int old_pace_index,
        int new_pace_index);
    void OtPlayTrailPaceThemeDependency_20260603(void* owner_window);
    void OtHandleChangePaceAction_20260603(void* owner_window);
};
#pragma pack(pop)

extern "C" void* g_resourceModule;
extern "C" JourneyState_0042b3d0_20260603* g_journeyState;
extern "C" int g_titleThemeEnabled_004390ec;
extern "C" int g_cdMediaMode_00439108;
extern "C" int g_trailProgressStopPending;
extern "C" long __stdcall OtPaceDialogProcDependency_20260603(
    void* dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam);

static const char kLessText_0042b3d0[] = "less ";
static const char kMoreText_0042b3d0[] = "more ";
static const char kPaceSuffixText_0042b3d0[] = " pace.";
static const char kSoloPacePrefix_0042b3d0[] =
    "I will now travel at a ";
static const char kPartyPacePrefix_0042b3d0[] =
    "We will now travel at a ";

#pragma optimize("s", off)
#pragma optimize("t", on)

static __inline int OtPaceIncreased_0042b3d0(
    short old_pace,
    short current_pace)
{
    return old_pace < current_pace;
}

void TrailDialogState_0042b3d0_20260603::
    OtHandleChangePaceAction_20260603(void* owner_window)
{
    register TrailDialogState_0042b3d0_20260603* state = this;
    short old_pace = g_journeyState->pace;
    short selected_pace;
    char pace_text[25];
    char diary_message[100];

    OtRunModalDialogAndRefreshParentAlt1_00401530_38pct(
        g_resourceModule,
        owner_window,
        reinterpret_cast<void*>(OtPaceDialogProcDependency_20260603),
        reinterpret_cast<const char*>(0xf4),
        reinterpret_cast<long>(&selected_pace));

    if (-1 < selected_pace) {
        state->OtSwapVisiblePaceButtonDependency_20260603(
            owner_window,
            g_journeyState->pace,
            selected_pace);
        g_journeyState->pace = selected_pace;
    }

    if (g_journeyState->pace != old_pace) {
        memset(diary_message, 0, sizeof(diary_message));
        memset(pace_text, 0, sizeof(pace_text));

        if (g_journeyState->OtCountLivingPartyMembersDependency_20260603() > 1) {
            strcpy(diary_message, kPartyPacePrefix_0042b3d0);
        } else {
            strcpy(diary_message, kSoloPacePrefix_0042b3d0);
        }

        LoadStringA(
            g_resourceModule,
            static_cast<unsigned int>(g_journeyState->pace + 0x60),
            pace_text,
            0x18);
        _strlwr(pace_text);
        strcat(pace_text, kPaceSuffixText_0042b3d0);

        if (g_journeyState->pace != 0) {
            if (OtPaceIncreased_0042b3d0(
                    old_pace,
                    g_journeyState->pace)) {
                strcat(diary_message, kMoreText_0042b3d0);
            } else {
                strcat(diary_message, kLessText_0042b3d0);
            }
        }

        strcat(diary_message, pace_text);
        state->diary->OtAppendTrailDiaryEntryDependency_20260603(
            diary_message);

        if (g_cdMediaMode_00439108 != 0) {
            if (g_titleThemeEnabled_004390ec == 0) {
                return;
            }

            OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();
            state->OtPlayTrailPaceThemeDependency_20260603(owner_window);
        }
    }

    if (g_titleThemeEnabled_004390ec != 0 &&
        state->pending_post_action != 0 &&
        g_trailProgressStopPending != 0 &&
        g_journeyState->route_stop_flags == 0) {
        state->post_action->OtRunPostPaceActionDependency_20260603(
            owner_window);
    }
}

#pragma code_seg(".otsem")

extern "C" __declspec(dllimport) long __stdcall GetWindowLongA(
    void* window,
    int index);
extern "C" __declspec(dllimport) long __stdcall SetWindowLongA(
    void* window,
    int index,
    long value);
extern "C" __declspec(dllimport) int __stdcall EndDialog(
    void* dialog,
    int result);
extern "C" short __fastcall OtCountLivingPartyMembers_RealCpp(
    const void* party);
extern "C" void __stdcall OtSwapVisiblePaceButtonAlt5_0042a510_37pct(
    void* dialog,
    int old_button_index,
    int new_button_index);

#pragma comment(lib, "user32.lib")

struct TrailOverlayWindow_00405df0 {
    void OtPlayCurrentRouteAudioCue_00405e00_ProductWip(
        void* owner_window);
};

struct TrailJournalState_0040f950 {
    void OtAppendTrailJournalText_0040f950_ProductWip(
        const char* pending_text);
};

struct TrailUiState_0042b370 {
    void OtPlayTrailPaceTheme_0042d3a0_ProductWip(void* owner_window);
};

// The original callback owns considerably more bitmap-backed presentation
// state.  This Product implementation retains its observable pace-selection
// contract while that presentation layer is recovered separately.
extern "C" long __stdcall OtPaceDialogProcDependency_20260603(
    void* dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam)
{
    long* selected_pace;
    int selection;

    if (message == 0x0110) {
        SetWindowLongA(dialog, 8, lparam);
        return 0;
    }

    if (message != 0x0111) {
        return 0;
    }

    selection = -2;
    switch (static_cast<unsigned short>(wparam)) {
    case 0x012d:
        selection = -1;
        break;
    case 0x0fde:
        selection = 0;
        break;
    case 0x0fdf:
        selection = 1;
        break;
    case 0x0fe0:
        selection = 2;
        break;
    default:
        break;
    }

    if (selection == -2) {
        return 0;
    }

    selected_pace = reinterpret_cast<long*>(GetWindowLongA(dialog, 8));
    if (selected_pace != 0) {
        *selected_pace = selection;
    }
    EndDialog(dialog, 1);
    return 1;
}

short JourneyState_0042b3d0_20260603::
    OtCountLivingPartyMembersDependency_20260603()
{
    return OtCountLivingPartyMembers_RealCpp(this);
}

void TrailDiary_0042b3d0_20260603::
    OtAppendTrailDiaryEntryDependency_20260603(char* message)
{
    reinterpret_cast<TrailJournalState_0040f950*>(this)->
        OtAppendTrailJournalText_0040f950_ProductWip(message);
}

void TrailDialogState_0042b3d0_20260603::
    OtSwapVisiblePaceButtonDependency_20260603(
        void* dialog,
        int old_pace_index,
        int new_pace_index)
{
    OtSwapVisiblePaceButtonAlt5_0042a510_37pct(
        dialog,
        old_pace_index,
        new_pace_index);
}

void TrailDialogState_0042b3d0_20260603::
    OtPlayTrailPaceThemeDependency_20260603(void* owner_window)
{
    reinterpret_cast<TrailUiState_0042b370*>(this)->
        OtPlayTrailPaceTheme_0042d3a0_ProductWip(owner_window);
}

void TrailPostAction_0042b3d0_20260603::
    OtRunPostPaceActionDependency_20260603(void* owner_window)
{
    reinterpret_cast<TrailOverlayWindow_00405df0*>(this)->
        OtPlayCurrentRouteAudioCue_00405e00_ProductWip(owner_window);
}

#pragma code_seg()
#pragma optimize("", on)

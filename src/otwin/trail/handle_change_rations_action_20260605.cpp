// Product-tree semantic closure for OtHandleChangeRationsAction @ 0x0042b610.

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

#pragma pack(push, 1)
struct JourneyState_0042b610_20260605 {
    char reserved_000[0x5a];
    short route_stop_flags;
    char reserved_05c[0x34];
    short ration_level;

    short OtCountLivingPartyMembersDependency_20260605();
};

struct TrailDiary_0042b610_20260605 {
    void OtAppendTrailDiaryEntryDependency_20260605(char* message);
};

struct TrailPostAction_0042b610_20260605 {
    void OtRunPostRationActionDependency_20260605(void* owner_window);
};

struct TrailDialogState_0042b610_20260605 {
    char reserved_000[0x788];
    TrailPostAction_0042b610_20260605* post_action;
    char reserved_78c[0x280];
    TrailDiary_0042b610_20260605* diary;
    char reserved_a10[0x0c];
    void* pending_post_action;

    void OtSwapVisibleRationButtonDependency_20260605(
        void* dialog,
        int old_ration_index,
        int new_ration_index);
    void OtHandleChangeRationsAction_20260605(void* owner_window);
};
#pragma pack(pop)

extern "C" void* g_resourceModule;
extern "C" JourneyState_0042b610_20260605* g_journeyState;
extern "C" int g_titleThemeEnabled_004390ec;
extern "C" int g_trailProgressStopPending;
extern "C" long __stdcall OtRationsDialogProcProduct_20260605(
    void* dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam);

static const char kRationsPortionsText_0042b610[] = " portions.";
static const char kSoloRationsPrefix_0042b610[] =
    "I decided to ration the food in ";
static const char kPartyRationsPrefix_0042b610[] =
    "We decided to ration the food in ";

#pragma optimize("s", off)
#pragma optimize("t", on)

void TrailDialogState_0042b610_20260605::
    OtHandleChangeRationsAction_20260605(void* owner_window)
{
    register TrailDialogState_0042b610_20260605* state = this;
    int old_rations = g_journeyState->ration_level;
    short selected_rations;
    char ration_text[25];
    char diary_message[100];

    OtRunModalDialogAndRefreshParentAlt1_00401530_38pct(
        g_resourceModule,
        owner_window,
        reinterpret_cast<void*>(OtRationsDialogProcProduct_20260605),
        reinterpret_cast<const char*>(0xf3),
        reinterpret_cast<long>(&selected_rations));

    if (-1 < selected_rations) {
        state->OtSwapVisibleRationButtonDependency_20260605(
            owner_window,
            g_journeyState->ration_level,
            selected_rations);
        g_journeyState->ration_level = selected_rations;
    }

    if (g_journeyState->ration_level != old_rations) {
        memset(diary_message, 0, sizeof(diary_message));
        memset(ration_text, 0, sizeof(ration_text));

        if (g_journeyState->OtCountLivingPartyMembersDependency_20260605() > 1) {
            strcpy(diary_message, kPartyRationsPrefix_0042b610);
        } else {
            strcpy(diary_message, kSoloRationsPrefix_0042b610);
        }

        LoadStringA(
            g_resourceModule,
            static_cast<unsigned int>(g_journeyState->ration_level + 0x50),
            ration_text,
            0x18);
        _strlwr(ration_text);
        strcat(diary_message, ration_text);
        strcat(diary_message, kRationsPortionsText_0042b610);

        state->diary->OtAppendTrailDiaryEntryDependency_20260605(
            diary_message);
    }

    if (g_titleThemeEnabled_004390ec != 0 &&
        state->pending_post_action != 0 &&
        g_trailProgressStopPending != 0 &&
        g_journeyState->route_stop_flags == 0) {
        state->post_action->OtRunPostRationActionDependency_20260605(
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
extern "C" void __stdcall OtSwapVisibleRationButtonAlt5_0042a550_37pct(
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

// The original callback also owns bitmap-backed presentation state. This
// Product implementation preserves its observable modal-selection contract.
extern "C" long __stdcall OtRationsDialogProcProduct_20260605(
    void* dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam)
{
    long* selected_rations;
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
    case 0x0fd7:
        selection = 0;
        break;
    case 0x0fd8:
        selection = 1;
        break;
    case 0x0fd9:
        selection = 2;
        break;
    default:
        break;
    }

    if (selection == -2) {
        return 0;
    }

    selected_rations = reinterpret_cast<long*>(GetWindowLongA(dialog, 8));
    if (selected_rations != 0) {
        *selected_rations = selection;
    }
    EndDialog(dialog, 1);
    return 1;
}

short JourneyState_0042b610_20260605::
    OtCountLivingPartyMembersDependency_20260605()
{
    return OtCountLivingPartyMembers_RealCpp(this);
}

void TrailDiary_0042b610_20260605::
    OtAppendTrailDiaryEntryDependency_20260605(char* message)
{
    reinterpret_cast<TrailJournalState_0040f950*>(this)->
        OtAppendTrailJournalText_0040f950_ProductWip(message);
}

void TrailDialogState_0042b610_20260605::
    OtSwapVisibleRationButtonDependency_20260605(
        void* dialog,
        int old_ration_index,
        int new_ration_index)
{
    OtSwapVisibleRationButtonAlt5_0042a550_37pct(
        dialog,
        old_ration_index,
        new_ration_index);
}

void TrailPostAction_0042b610_20260605::
    OtRunPostRationActionDependency_20260605(void* owner_window)
{
    reinterpret_cast<TrailOverlayWindow_00405df0*>(this)->
        OtPlayCurrentRouteAudioCue_00405e00_ProductWip(owner_window);
}

#pragma code_seg()
#pragma optimize("", on)

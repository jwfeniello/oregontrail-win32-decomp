// Product-tree semantic closure for OtHandleDropSuppliesAction @ 0x0042b0b0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "accepted_semantic_dependencies.h"

#include <stdlib.h>
#include <string.h>

#pragma intrinsic(memset, strcpy, strcat, strlen)

#pragma pack(push, 1)
struct JourneyState_0042b0b0_20260603 {
    char reserved_000[0x5a];
    short route_stop_flags;

    short OtCountLivingPartyMembersDependency_20260603();
};

struct TrailDiary_0042b0b0_20260603 {
    void OtAppendTrailDiaryEntryDependency_20260603(char* message);
};

struct TrailPostAction_0042b0b0_20260603 {
    void OtRunPostDropSuppliesActionDependency_20260603(void* owner_window);
};

struct TrailOverlayWindow_00405df0 {
    void OtPlayCurrentRouteAudioCue_00405e00_ProductWip(
        void* owner_window);
};

struct TrailJournalState_0040f950 {
    void OtAppendTrailJournalText_0040f950_ProductWip(
        const char* pending_text);
};

struct TrailStatusPanelState_0042d5d0_ProductWip {
    void OtRefreshTrailStatusPanel_0042d5d0_ProductWip(
        void* owner_window);
};

struct DropSuppliesDialogResult_0042b0b0_20260603 {
    short selected_item;
    short drop_amount;
};

struct TrailDialogState_0042b0b0_20260603 {
    char reserved_000[0x788];
    TrailPostAction_0042b0b0_20260603* post_action;
    char reserved_78c[0x280];
    TrailDiary_0042b0b0_20260603* diary;
    char reserved_a10[0x0c];
    void* pending_post_action;

    void OtHandleDropSuppliesAction_20260603(void* owner_window);
    void OtRefreshTrailStatusPanelDependency_20260603(void* owner_window);
};
#pragma pack(pop)

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" JourneyState_0042b0b0_20260603* g_journeyState;
extern "C" int g_titleThemeEnabled_004390ec;
extern "C" int g_trailProgressStopPending;
extern "C" short __fastcall OtCountLivingPartyMembers_RealCpp(
    const void* party);

extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* instance,
    unsigned int string_id,
    char* buffer,
    int buffer_max);
extern "C" char* __cdecl _strlwr(char* text);
extern "C" long __stdcall OtDropSuppliesDialogProc_0041ead0_ProductWip(
    void* dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam);

static const char kSpace_0042b0b0[] = " ";
static const char kPeriod_0042b0b0[] = ".";
static const char kPoundOfFoodText_0042b0b0[] = "pound of food";
static const char kSetOfClothesText_0042b0b0[] = "set of clothes";
static const char kBoxOfBulletsText_0042b0b0[] = "box of bullets (20/box)";
static const char kSoloDropPrefix_0042b0b0[] = "I decided to drop ";
static const char kPartyDropPrefix_0042b0b0[] = "We decided to drop ";

#pragma optimize("s", off)
#pragma optimize("t", on)

void TrailDialogState_0042b0b0_20260603::OtHandleDropSuppliesAction_20260603(
    void* owner_window)
{
    register void* owner = owner_window;
    DropSuppliesDialogResult_0042b0b0_20260603 dialog_result;
    char amount_text[10];
    char item_text[40];
    char diary_message[100];

    dialog_result.selected_item = -1;
    dialog_result.drop_amount = 0;
    OtRunModalDialogAndRefreshParentAlt1_00401530_38pct(
        g_applicationModule_00405a40_20260603,
        owner,
        reinterpret_cast<void*>(
            OtDropSuppliesDialogProc_0041ead0_ProductWip),
        (const char*)0xf0,
        (long)&dialog_result);

    if (dialog_result.selected_item != -1) {
        memset(diary_message, 0, sizeof(diary_message));
        memset(amount_text, 0, sizeof(amount_text));

        if (g_journeyState->OtCountLivingPartyMembersDependency_20260603() > 1) {
            strcpy(diary_message, kPartyDropPrefix_0042b0b0);
        } else {
            strcpy(diary_message, kSoloDropPrefix_0042b0b0);
        }

        _itoa((int)dialog_result.drop_amount, amount_text, 10);
        strcat(diary_message, amount_text);
        strcat(diary_message, kSpace_0042b0b0);

        LoadStringA(
            g_applicationModule_00405a40_20260603,
            (unsigned int)((int)dialog_result.selected_item + 500),
            item_text,
            0x27);
        _strlwr(item_text);

        if (dialog_result.drop_amount == 1) {
            if (dialog_result.selected_item == 2) {
                strcpy(item_text, kBoxOfBulletsText_0042b0b0);
            } else if (dialog_result.selected_item == 1) {
                strcpy(item_text, kSetOfClothesText_0042b0b0);
            } else if (dialog_result.selected_item == 6) {
                strcpy(item_text, kPoundOfFoodText_0042b0b0);
            } else {
                item_text[strlen(item_text) - 1] = '\0';
            }
        }

        strncat(diary_message, item_text, 0x62 - strlen(diary_message));
        strcat(diary_message, kPeriod_0042b0b0);

        diary->OtAppendTrailDiaryEntryDependency_20260603(
            diary_message);
        OtRefreshTrailStatusPanelDependency_20260603(owner);
    }

    if (g_titleThemeEnabled_004390ec != 0 &&
        pending_post_action != 0 &&
        g_trailProgressStopPending != 0 &&
        g_journeyState->route_stop_flags == 0) {
        post_action->OtRunPostDropSuppliesActionDependency_20260603(owner);
    }
}

#pragma code_seg(".otsem")
short JourneyState_0042b0b0_20260603::
    OtCountLivingPartyMembersDependency_20260603()
{
    return OtCountLivingPartyMembers_RealCpp(this);
}

void TrailDiary_0042b0b0_20260603::
    OtAppendTrailDiaryEntryDependency_20260603(char* message)
{
    reinterpret_cast<TrailJournalState_0040f950*>(this)->
        OtAppendTrailJournalText_0040f950_ProductWip(message);
}

void TrailDialogState_0042b0b0_20260603::
    OtRefreshTrailStatusPanelDependency_20260603(void* owner_window)
{
    reinterpret_cast<TrailStatusPanelState_0042d5d0_ProductWip*>(this)->
        OtRefreshTrailStatusPanel_0042d5d0_ProductWip(owner_window);
}

void TrailPostAction_0042b0b0_20260603::
    OtRunPostDropSuppliesActionDependency_20260603(void* owner_window)
{
    reinterpret_cast<TrailOverlayWindow_00405df0*>(this)->
        OtPlayCurrentRouteAudioCue_00405e00_ProductWip(owner_window);
}
#pragma code_seg()

#pragma optimize("", on)

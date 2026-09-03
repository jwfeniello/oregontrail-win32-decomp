// Product-reachable semantic DLGPROC for OtWhoAmIDialogProc @ 0x00428f00.

#include <string.h>

#include "dialog_callback_runtime.h"

typedef int (__stdcall *OtWhoAmIDialogProc_Product)(
    OtDialogHandle_Product,
    unsigned int,
    unsigned int,
    long);

extern "C" __declspec(dllimport) long __stdcall GetWindowLongA(
    OtDialogHandle_Product window,
    int index);
extern "C" __declspec(dllimport) long __stdcall SetWindowLongA(
    OtDialogHandle_Product window,
    int index,
    long value);
extern "C" __declspec(dllimport) OtDialogHandle_Product __stdcall GetParent(
    OtDialogHandle_Product window);
extern "C" __declspec(dllimport) OtDialogHandle_Product __stdcall GetDlgItem(
    OtDialogHandle_Product dialog,
    int control_id);
extern "C" __declspec(dllimport) int __stdcall GetWindowTextA(
    OtDialogHandle_Product window,
    char* text,
    int text_length);
extern "C" __declspec(dllimport) int __stdcall SetWindowTextA(
    OtDialogHandle_Product window,
    const char* text);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    OtDialogHandle_Product window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall PostMessageA(
    OtDialogHandle_Product window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall DestroyWindow(
    OtDialogHandle_Product window);
extern "C" __declspec(dllimport) OtDialogHandle_Product __stdcall SetFocus(
    OtDialogHandle_Product window);
extern "C" __declspec(dllimport) OtDialogHandle_Product __stdcall GetFocus();
extern "C" __declspec(dllimport) int __stdcall EndDialog(
    OtDialogHandle_Product dialog,
    int result);
extern "C" __declspec(dllimport) int __stdcall DialogBoxParamA(
    void* instance,
    const void* template_name,
    OtDialogHandle_Product parent,
    OtWhoAmIDialogProc_Product dialog_proc,
    long init_param);

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" void* g_journeyState;

extern "C" void __cdecl OtInitWhoAmIDialog_00429650_RealCpp(
    OtDialogHandle_Product dialog);
extern "C" int __cdecl OtSelectDialogCursor_0040d530_RealCpp(
    int busy,
    OtDialogHandle_Product window);
extern "C" int __cdecl OtRunSharedMessageDialog_00401e70_RealCpp(
    OtDialogHandle_Product parent,
    void* message_text,
    void* caption_text,
    int use_alternate_template);

#pragma pack(push, 1)
struct WhoAmIDialogBitmapState_00429650 {
    PositionedBitmapDescriptorState_0040ba40 leader_name_up;
    PositionedBitmapDescriptorState_0040ba40 leader_name_down;
    PositionedBitmapDescriptorState_0040ba40 continue_up;
    PositionedBitmapDescriptorState_0040ba40 continue_down;
    PositionedBitmapDescriptorState_0040ba40 back_up;
    PositionedBitmapDescriptorState_0040ba40 back_down;
    PositionedBitmapDescriptorState_0040ba40 party_name_frame;
};

struct WhoAmIJourneyState_004294a0_Product {
    char reserved_000[0xc0];
    char party_member_names[5][15];
    char reserved_10b[0x0b];
    short party_member_state[5];
};

struct JourneyOccupationState_00419760 {
    void OtSetOccupationAndStartingCash_00419760_RealCpp(
        short occupation_id);
};
#pragma pack(pop)

typedef char OtWhoAmIStateSizeMustBe118[
    sizeof(WhoAmIDialogBitmapState_00429650) == 0x118 ? 1 : -1];

static char g_whoAmILeaderRequiredText_00428f00[] =
    "You must enter a name for yourself before continuing.";
static char g_whoAmILeaderRequiredCaption_00428f00[] =
    "Wagon Leader Name";

static int __stdcall OtOccupationInfoDialogProc_ProductAdapter(
    OtDialogHandle_Product dialog,
    unsigned int message,
    unsigned int wparam,
    long)
{
    if (message == 0x0110) {
        SetFocus(GetDlgItem(dialog, 300));
        return 0;
    }
    if (message == 0x0111 &&
        ((wparam & 0xffff) == 300 ||
         (wparam & 0xffff) == 1 ||
         (wparam & 0xffff) == 2)) {
        EndDialog(dialog, 0);
        return 1;
    }
    if (message == 0x0138 || message == 0x0136) {
        return OtPrepareDialogControlColor_Product(
            reinterpret_cast<OtDialogDeviceContext_Product>(wparam),
            g_optionMenuFont_004390d4_00405320,
            0);
    }
    return 0;
}

static void OtCommitWhoAmISelections_Product_004294a0(
    OtDialogHandle_Product dialog)
{
    WhoAmIJourneyState_004294a0_Product* journey =
        reinterpret_cast<WhoAmIJourneyState_004294a0_Product*>(
            g_journeyState);
    int source_index;
    int destination_index = 0;
    int occupation;

    for (source_index = 0; source_index < 5; ++source_index) {
        char buffer[15];
        char* text = buffer;

        memset(buffer, 0, sizeof(buffer));
        GetWindowTextA(
            GetDlgItem(dialog, 0x0528 + source_index),
            buffer,
            sizeof(buffer));
        while (*text == ' ') {
            ++text;
        }
        if (*text != 0) {
            strncpy(
                journey->party_member_names[destination_index],
                text,
                14);
            journey->party_member_names[destination_index][14] = 0;
            ++destination_index;
        }
    }

    while (destination_index < 5) {
        journey->party_member_names[destination_index][0] = 0;
        journey->party_member_state[destination_index] = 0x0f;
        ++destination_index;
    }

    for (occupation = 0; occupation < 8; ++occupation) {
        if (SendMessageA(
                GetDlgItem(dialog, 0x051f + occupation),
                0x00f0,
                0,
                0) != 0) {
            reinterpret_cast<JourneyOccupationState_00419760*>(
                g_journeyState)->
                OtSetOccupationAndStartingCash_00419760_RealCpp(
                    static_cast<short>(occupation));
            break;
        }
    }
}

static int OtFocusIsPartyNameControl_00428f00(
    OtDialogHandle_Product dialog)
{
    OtDialogHandle_Product focus = GetFocus();
    int control_id;

    for (control_id = 0x0528; control_id <= 0x052c; ++control_id) {
        if (GetDlgItem(dialog, control_id) == focus) {
            return 1;
        }
    }
    return 0;
}

static void OtLeaveWhoAmIDialog_00428f00(
    OtDialogHandle_Product dialog,
    unsigned int next_message)
{
    PostMessageA(GetParent(dialog), next_message, 0, 0);
    DestroyWindow(dialog);
    g_activeScreenDialogWindow_00404dd0 = 0;
}

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" int __stdcall OtWhoAmIDialogProc_00028f00_Wip(
    OtDialogHandle_Product dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam)
{
    WhoAmIDialogBitmapState_00429650* state =
        reinterpret_cast<WhoAmIDialogBitmapState_00429650*>(
            GetWindowLongA(dialog, 8));

    switch (message) {
    case 0x0002:
        if (state != 0) {
            delete state;
            SetWindowLongA(dialog, 8, 0);
        }
        g_activeScreenDialogWindow_00404dd0 = 0;
        return 0;

    case 0x000f:
        OtSetDialogBusyCursor_Product();
        OtPaintDialogBackground_Product(
            dialog,
            state != 0 ? &state->party_name_frame : 0,
            g_sharedDialogBackgroundBrush_004390c0);
        OtRestoreDialogArrowCursor_Product();
        return 0;

    case 0x0014:
        return 1;

    case 0x0020:
        return OtSelectDialogCursor_0040d530_RealCpp(
            g_appBusyCursorActive_Product_004034d0,
            reinterpret_cast<OtDialogHandle_Product>(wparam));

    case 0x002b:
        if (state == 0) {
            return 0;
        }
        switch (wparam & 0xffff) {
        case 0x012c:
            return OtDrawOwnedBitmapButton_Product(
                reinterpret_cast<OtDialogDrawItem_Product*>(lparam),
                &state->continue_up,
                &state->continue_down);
        case 0x012d:
            return OtDrawOwnedBitmapButton_Product(
                reinterpret_cast<OtDialogDrawItem_Product*>(lparam),
                &state->back_up,
                &state->back_down);
        case 0x0131:
            return OtDrawOwnedBitmapButton_Product(
                reinterpret_cast<OtDialogDrawItem_Product*>(lparam),
                &state->leader_name_up,
                &state->leader_name_down);
        }
        return 1;

    case 0x0110:
        g_activeScreenDialogWindow_00404dd0 = dialog;
        OtInitWhoAmIDialog_00429650_RealCpp(dialog);
        return 0;

    case 0x0111:
        switch (wparam & 0xffff) {
        case 0x012c:
            OtCommitWhoAmISelections_Product_004294a0(dialog);
            if (reinterpret_cast<WhoAmIJourneyState_004294a0_Product*>(
                    g_journeyState)->party_member_names[0][0] == 0) {
                OtRunSharedMessageDialog_00401e70_RealCpp(
                    dialog,
                    g_whoAmILeaderRequiredText_00428f00,
                    g_whoAmILeaderRequiredCaption_00428f00,
                    0);
                SetFocus(GetDlgItem(dialog, 0x0528));
                return 1;
            }
            OtLeaveWhoAmIDialog_00428f00(dialog, 0x0470);
            return 1;

        case 0x012d:
            OtLeaveWhoAmIDialog_00428f00(dialog, 0x046d);
            return 1;

        case 0x0131:
            DialogBoxParamA(
                g_applicationModule_00405a40_20260603,
                reinterpret_cast<const void*>(0x00df),
                dialog,
                OtOccupationInfoDialogProc_ProductAdapter,
                0);
            return 1;
        }

        if ((wparam & 0xffff) >= 0x0528 &&
            (wparam & 0xffff) <= 0x052c) {
            return 1;
        }
        if (!OtFocusIsPartyNameControl_00428f00(dialog)) {
            SetFocus(GetDlgItem(dialog, 0x0528));
        }
        return 1;

    case 0x0133:
        return reinterpret_cast<int>(g_sharedDialogBackgroundBrush_004390c0);

    case 0x0135:
    case 0x0138:
        return OtPrepareDialogControlColor_Product(
            reinterpret_cast<OtDialogDeviceContext_Product>(wparam),
            g_optionMenuFont_004390d4_00405320,
            0);

    case 0x0465:
    case 0x0466:
    case 0x0467:
        if (!OtFocusIsPartyNameControl_00428f00(dialog)) {
            SetFocus(GetDlgItem(dialog, 0x0528));
        }
        return 1;
    }

    return 0;
}

#pragma optimize("", on)

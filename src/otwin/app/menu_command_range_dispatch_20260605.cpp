// Product C++ promotion of FUN_00404b30: dispatches the file/menu command range.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include "active_text_runtime.h"

typedef void* HWND_00404b30_20260605;

extern "C" __declspec(dllimport) int __stdcall IsWindow(
    HWND_00404b30_20260605 window);
extern "C" __declspec(dllimport) int __stdcall PostMessageA(
    HWND_00404b30_20260605 window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    HWND_00404b30_20260605 window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall DestroyWindow(
    HWND_00404b30_20260605 window);

#pragma comment(lib, "user32.lib")

extern "C" HWND_00404b30_20260605 g_activeScreenDialogWindow_00404dd0;
extern "C" int g_generalStorePurchaseCommitted_004390f8;
extern "C" int g_savedGameTextRefreshPending_00404b30 = 0;

extern "C" int __cdecl OtRiverEnsureScratchBuffer_RealCpp();
extern "C" void __cdecl OtReleaseCachedGlobalHandle_Product_0040f840();
extern "C" int __cdecl OtLoadSavedGameFromDialog_0000c4e0_Wip(
    HWND_00404b30_20260605 owner_window);
extern "C" int __cdecl OtSaveGamePathDialogHelper_0000c880_20260605_Wip(
    HWND_00404b30_20260605 owner_window);
extern "C" int __cdecl OtSavedGameTextExport_0000cb20_RealCpp(
    HWND_00404b30_20260605 owner_window);

#pragma pack(push, 1)
struct MainWindowCloseState_00403470 {
    char reserved_00[8];
    int interaction_state;
    int OtIsCloseConfirmationState_RealCpp() const;
};

struct CloseConfirmationState_00403410 {
    char reserved_00[4];
    HWND_00404b30_20260605 main_window;
    int OtConfirmCloseTransition_Product_00403410();
};

struct StateTransitionConfirmation_00003390 {
    char reserved_00[4];
    HWND_00404b30_20260605 main_window;
    int interaction_state;
    int OtConfirmStateTransitionMsgBox_00003390_RealCpp();
};

struct ActiveScreenDialogState_004034d0 {
    char reserved_00[8];
    int interaction_state;
    void OtDestroyActiveScreenDialog_Product_004034d0();
};

struct MenuCommandRangeDispatch_00404b30_20260605 {
    char reserved_00[4];
    HWND_00404b30_20260605 main_window;
    int interaction_state;

    int OtMenuCommandRangeDispatch_00004b30_20260605_Wip(
        unsigned int command_id,
        long notify_code);
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)
#pragma code_seg(".otsem")

int MenuCommandRangeDispatch_00404b30_20260605::
    OtMenuCommandRangeDispatch_00004b30_20260605_Wip(
        unsigned int command_id,
        long)
{
    register MenuCommandRangeDispatch_00404b30_20260605* state = this;

    switch (command_id & 0xffff) {
    case 0x64:
        if (reinterpret_cast<MainWindowCloseState_00403470*>(state)->
                OtIsCloseConfirmationState_RealCpp() != 0) {
            PostMessageA(state->main_window, 0x047c, 0, 0);
            return 0;
        }
        PostMessageA(state->main_window, 0x046e, 0, 0);
        return 0;

    case 0x65:
        if (reinterpret_cast<MainWindowCloseState_00403470*>(state)->
                OtIsCloseConfirmationState_RealCpp() != 0) {
            PostMessageA(state->main_window, 0x047c, 0, 0);
            return 0;
        }
        if (state->interaction_state == 0x0d ||
            state->interaction_state == 0x0b ||
            state->interaction_state == 0x0c) {
            reinterpret_cast<CloseConfirmationState_00403410*>(state)->
                OtConfirmCloseTransition_Product_00403410();
        }
        if (OtRiverEnsureScratchBuffer_RealCpp() == 0) {
            return 0;
        }
        if (OtLoadSavedGameFromDialog_0000c4e0_Wip(state->main_window) != 0) {
            PostMessageA(state->main_window, 0x0472, 0, 0);
            return 0;
        }
        OtReleaseCachedGlobalHandle_Product_0040f840();
        return 0;

    case 0x66:
        if (IsWindow(g_activeScreenDialogWindow_00404dd0) != 0) {
            SendMessageA(g_activeScreenDialogWindow_00404dd0, 0x0465, 0, 0);
        }
        if (OtSaveGamePathDialogHelper_0000c880_20260605_Wip(
                state->main_window) != 0) {
            g_generalStorePurchaseCommitted_004390f8 = 0;
        }
        if (IsWindow(g_activeScreenDialogWindow_00404dd0) != 0) {
            PostMessageA(g_activeScreenDialogWindow_00404dd0, 0x0467, 0, 0);
            return 0;
        }
        break;

    case 0x67:
        if (IsWindow(g_activeScreenDialogWindow_00404dd0) != 0) {
            SendMessageA(g_activeScreenDialogWindow_00404dd0, 0x0465, 0, 0);
        }
        if (OtSavedGameTextExport_0000cb20_RealCpp(state->main_window) != 0) {
            g_savedGameTextRefreshPending_00404b30 = 0;
        }
        if (IsWindow(g_activeScreenDialogWindow_00404dd0) != 0) {
            PostMessageA(g_activeScreenDialogWindow_00404dd0, 0x0467, 0, 0);
            return 0;
        }
        break;

    case 0x68:
        if (reinterpret_cast<MainWindowCloseState_00403470*>(state)->
                OtIsCloseConfirmationState_RealCpp() != 0) {
            PostMessageA(state->main_window, 0x047c, 0, 0);
            return 0;
        }
        if (reinterpret_cast<StateTransitionConfirmation_00003390*>(state)->
                OtConfirmStateTransitionMsgBox_00003390_RealCpp() != 0) {
            reinterpret_cast<ActiveScreenDialogState_004034d0*>(state)->
                OtDestroyActiveScreenDialog_Product_004034d0();
            PostMessageA(state->main_window, 0x046d, 0, 0);
            return 0;
        }
        break;

    case 0x69:
        if (reinterpret_cast<MainWindowCloseState_00403470*>(state)->
                OtIsCloseConfirmationState_RealCpp() != 0) {
            PostMessageA(state->main_window, 0x047c, 0, 0);
            return 0;
        }
        if (reinterpret_cast<StateTransitionConfirmation_00003390*>(state)->
                OtConfirmStateTransitionMsgBox_00003390_RealCpp() != 0) {
            if (state->interaction_state == 0x0d ||
                state->interaction_state == 0x0b ||
                state->interaction_state == 0x0c) {
                reinterpret_cast<CloseConfirmationState_00403410*>(state)->
                    OtConfirmCloseTransition_Product_00403410();
            }
            DestroyWindow(state->main_window);
            return 0;
        }
        if (state->interaction_state == 0x0d ||
            state->interaction_state == 0x0b ||
            state->interaction_state == 0x0c) {
            reinterpret_cast<CloseConfirmationState_00403410*>(state)->
                OtConfirmCloseTransition_Product_00403410();
        }
        break;
    }

    return 0;
}

#pragma code_seg()
#pragma optimize("", on)

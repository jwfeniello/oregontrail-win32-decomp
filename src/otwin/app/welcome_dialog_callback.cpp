// Product-reachable semantic DLGPROC for OtWelcomeDialogProc @ 0x004156c0.

#include "dialog_callback_runtime.h"

extern "C" __declspec(dllimport) long __stdcall GetWindowLongA(
    OtDialogHandle_Product window,
    int index);
extern "C" __declspec(dllimport) long __stdcall SetWindowLongA(
    OtDialogHandle_Product window,
    int index,
    long value);
extern "C" __declspec(dllimport) OtDialogHandle_Product __stdcall GetParent(
    OtDialogHandle_Product window);
extern "C" __declspec(dllimport) int __stdcall PostMessageA(
    OtDialogHandle_Product window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall DestroyWindow(
    OtDialogHandle_Product window);

extern "C" void __cdecl OtInitWelcomeDialog_00415d30_RealCpp(
    OtDialogHandle_Product dialog);
extern "C" int __cdecl OtSelectDialogCursor_0040d530_RealCpp(
    int busy,
    OtDialogHandle_Product window);
extern "C" void __cdecl OtOpenWaveAudioFile_0000d110_RealCpp(
    OtDialogHandle_Product owner,
    const char* path);
extern "C" void __cdecl OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();
extern "C" void __cdecl OtCloseWaveAudioDevice_0040d0a0_RealCpp();
extern "C" void __cdecl OtStopWaveAudioDirectImport_0040d480_RealCpp();

extern "C" int g_cdMediaMode_00439108;
extern "C" int DAT_004390e8;

#pragma pack(push, 1)
struct WelcomeDialogBitmapState_00415d30 {
    PositionedBitmapDescriptorState_0040ba40 intro_first;
    PositionedBitmapDescriptorState_0040ba40 intro_second;
    PositionedBitmapDescriptorState_0040ba40 intro_third;
    PositionedBitmapDescriptorState_0040ba40 intro_fourth;
    PositionedBitmapDescriptorState_0040ba40 continue_up;
    PositionedBitmapDescriptorState_0040ba40 continue_down;
    PositionedBitmapDescriptorState_0040ba40 back_up;
    PositionedBitmapDescriptorState_0040ba40 back_down;
    PositionedBitmapDescriptorState_0040ba40 welcome_frame;
};
#pragma pack(pop)

typedef char OtWelcomeStateSizeMustBe168[
    sizeof(WelcomeDialogBitmapState_00415d30) == 0x168 ? 1 : -1];

static const char g_welcomeWavePath_004156c0[] = "welcome.wav";

static void OtWelcomeLeaveDialog_004156c0(
    OtDialogHandle_Product dialog,
    unsigned int next_message)
{
    PostMessageA(GetParent(dialog), next_message, 0, 0);
    DestroyWindow(dialog);
    g_activeScreenDialogWindow_00404dd0 = 0;
}

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" int __stdcall OtWelcomeDialogProc_000156c0_Wip(
    OtDialogHandle_Product dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam)
{
    WelcomeDialogBitmapState_00415d30* state =
        reinterpret_cast<WelcomeDialogBitmapState_00415d30*>(
            GetWindowLongA(dialog, 8));

    switch (message) {
    case 0x0002:
        if (state != 0) {
            delete state;
            SetWindowLongA(dialog, 8, 0);
        }
        if (g_cdMediaMode_00439108 != 0) {
            OtCloseWaveAudioDevice_0040d0a0_RealCpp();
        }
        return 0;

    case 0x000f:
        OtSetDialogBusyCursor_Product();
        OtPaintDialogBackground_Product(
            dialog,
            state != 0 ? &state->welcome_frame : 0,
            g_sharedDialogBackgroundBrush_004390c0);
        OtRestoreDialogArrowCursor_Product();
        return 1;

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
        case 0x0132:
            return OtDrawOwnedBitmapButton_Product(
                reinterpret_cast<OtDialogDrawItem_Product*>(lparam),
                &state->intro_first,
                &state->intro_second);
        case 0x0133:
            return OtDrawOwnedBitmapButton_Product(
                reinterpret_cast<OtDialogDrawItem_Product*>(lparam),
                &state->intro_third,
                &state->intro_fourth);
        }
        return 1;

    case 0x0110:
        g_activeScreenDialogWindow_00404dd0 = dialog;
        OtInitWelcomeDialog_00415d30_RealCpp(dialog);
        return 0;

    case 0x0111:
        switch (wparam & 0xffff) {
        case 0x012c:
            OtWelcomeLeaveDialog_004156c0(dialog, 0x046f);
            return 1;
        case 0x012d:
            OtWelcomeLeaveDialog_004156c0(dialog, 0x046d);
            return 1;
        case 0x0132:
            if (DAT_004390e8 != 0) {
                OtOpenWaveAudioFile_0000d110_RealCpp(
                    dialog,
                    g_welcomeWavePath_004156c0);
                OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();
            }
            return 1;
        case 0x0133:
            if (DAT_004390e8 != 0) {
                OtCloseWaveAudioDevice_0040d0a0_RealCpp();
            }
            return 1;
        }
        return 1;

    case 0x0138:
        return OtPrepareDialogControlColor_Product(
            reinterpret_cast<OtDialogDeviceContext_Product>(wparam),
            g_optionMenuFont_004390d4_00405320,
            0);

    case 0x03b9:
    case 0x0469:
        if (g_cdMediaMode_00439108 != 0) {
            OtCloseWaveAudioDevice_0040d0a0_RealCpp();
        }
        return 1;

    case 0x0465:
        if (g_cdMediaMode_00439108 != 0 && DAT_004390e8 != 0) {
            OtStopWaveAudioDirectImport_0040d480_RealCpp();
        }
        return 1;
    }

    return 0;
}

#pragma optimize("", on)

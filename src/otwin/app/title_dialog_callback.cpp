// Product-reachable semantic DLGPROC for OtTitleDialogProc @ 0x0041baf0.

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
extern "C" __declspec(dllimport) OtDialogHandle_Product __stdcall GetDlgItem(
    OtDialogHandle_Product dialog,
    int control_id);
extern "C" __declspec(dllimport) int __stdcall PostMessageA(
    OtDialogHandle_Product window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall DestroyWindow(
    OtDialogHandle_Product window);
extern "C" __declspec(dllimport) int __stdcall ShowWindow(
    OtDialogHandle_Product window,
    int show_command);
extern "C" __declspec(dllimport) int __stdcall GetUpdateRect(
    OtDialogHandle_Product window,
    OtDialogRect_Product* rect,
    int erase);
extern "C" __declspec(dllimport) int __stdcall IsIconic(
    OtDialogHandle_Product window);
extern "C" __declspec(dllimport) unsigned int __stdcall SetTimer(
    OtDialogHandle_Product window,
    unsigned int timer_id,
    unsigned int interval_ms,
    void* callback);
extern "C" __declspec(dllimport) int __stdcall KillTimer(
    OtDialogHandle_Product window,
    unsigned int timer_id);

extern "C" int g_cdMediaMode_00439108;
extern "C" int g_titleThemeEnabled_004390ec;
extern "C" int g_titleDialogLeaderboardMode_00439e00 = 0;

extern "C" void __cdecl OtInitTitleDialog_0041c410_RealCpp(
    OtDialogHandle_Product dialog);
extern "C" int __cdecl OtPopulateTitleLeaderboard_0041c210_Product(
    OtDialogHandle_Product dialog,
    void* state);
extern "C" void __cdecl OtToggleTitleAttractFrame_RealCpp(
    OtDialogHandle_Product dialog,
    void* state);
extern "C" int __cdecl OtSelectDialogCursor_0040d530_RealCpp(
    int busy,
    OtDialogHandle_Product window);
extern "C" int __cdecl OtRiverEnsureScratchBuffer_RealCpp();
extern "C" int __cdecl OtLoadSavedGameFromDialog_0000c4e0_Wip(
    OtDialogHandle_Product dialog);
extern "C" void __cdecl OtReleaseCachedGlobalHandle_Product_0040f840();
extern "C" void __cdecl OtOpenMidiAudioFileMaskClosed_0000cd60_RealCpp(
    OtDialogHandle_Product owner,
    const char* path);
extern "C" void __cdecl OtPlayMidiAudio_0000ced0_RealCpp(int restart);
extern "C" void __cdecl OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();
extern "C" void __cdecl OtOpenWaveAudioFile_0000d110_RealCpp(
    OtDialogHandle_Product owner,
    const char* path);
extern "C" void __cdecl OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();
extern "C" void __cdecl OtCloseWaveAudioDevice_0040d0a0_RealCpp();

#pragma pack(push, 1)
struct TitleDialogState_0041baf0_Product {
    PositionedBitmapDescriptorState_0040ba40 frame;
    PositionedBitmapDescriptorState_0040ba40 overlay;
    PositionedBitmapDescriptorState_0040ba40 start_up;
    PositionedBitmapDescriptorState_0040ba40 start_down;
    PositionedBitmapDescriptorState_0040ba40 continue_up;
    PositionedBitmapDescriptorState_0040ba40 continue_down;
    char leaderboard[0x13a];
    unsigned int timer_id;
    unsigned int timer_phase;
    RectResource_0040b690 title_rect;
};
#pragma pack(pop)

typedef char OtTitleCallbackStateSizeMustBe242[
    sizeof(TitleDialogState_0041baf0_Product) == 0x242 ? 1 : -1];

static const char g_titleCallbackMidiPath_0041baf0[] = "theme.mid";
static const char g_titleCallbackWavePath_0041baf0[] = "theme.wav";

static int OtTitleLeaderboardCount_0041baf0(
    const TitleDialogState_0041baf0_Product* state)
{
    return *reinterpret_cast<const int*>(state->leaderboard);
}

static void OtShowTitleLeaderboardControls_0041baf0(
    OtDialogHandle_Product dialog,
    int row_count,
    int show)
{
    int row;

    ShowWindow(GetDlgItem(dialog, 0x03f2), show);
    ShowWindow(GetDlgItem(dialog, 0x03f3), show);
    for (row = 0; row < 10; ++row) {
        int row_show = show != 0 && row < row_count ? 5 : 0;
        ShowWindow(GetDlgItem(dialog, 0x03fc + row), row_show);
        ShowWindow(GetDlgItem(dialog, 0x0406 + row), row_show);
        ShowWindow(GetDlgItem(dialog, 0x0410 + row), row_show);
    }
}

static void OtPaintTitleDialog_Product_0041c760(
    OtDialogHandle_Product dialog,
    TitleDialogState_0041baf0_Product* state)
{
    OtDialogRect_Product update_rect;
    OtDialogPaintStruct_Product paint;
    OtDialogDeviceContext_Product dc;

    if (state == 0 || GetUpdateRect(dialog, &update_rect, 0) == 0) {
        return;
    }

    dc = BeginPaint(dialog, &paint);
    SelectPalette(dc, g_gamePalette, 0);
    UnrealizeObject(g_gamePalette);
    RealizePalette(dc);
    if (g_titleDialogLeaderboardMode_00439e00 != 0) {
        OtShowTitleLeaderboardControls_0041baf0(dialog, 0, 0);
        OtBlitDialogBitmap_Product(&state->frame, dc);
    } else {
        OtBlitDialogBitmap_Product(&state->overlay, dc);
        OtShowTitleLeaderboardControls_0041baf0(
            dialog,
            OtTitleLeaderboardCount_0041baf0(state),
            5);
    }
    FillRect(
        dc,
        reinterpret_cast<OtDialogRect_Product*>(&state->title_rect),
        g_sharedDialogBackgroundBrush_004390c0);
    EndPaint(dialog, &paint);
}

static void OtPlayTitleTheme_Product_0041baf0(
    OtDialogHandle_Product dialog)
{
    if (g_cdMediaMode_00439108 != 0) {
        OtOpenWaveAudioFile_0000d110_RealCpp(
            dialog,
            g_titleCallbackWavePath_0041baf0);
        OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();
    } else {
        OtOpenMidiAudioFileMaskClosed_0000cd60_RealCpp(
            dialog,
            g_titleCallbackMidiPath_0041baf0);
        OtPlayMidiAudio_0000ced0_RealCpp(0);
    }
}

static void OtCloseTitleTheme_Product_0041baf0()
{
    if (g_cdMediaMode_00439108 != 0) {
        OtCloseWaveAudioDevice_0040d0a0_RealCpp();
    } else {
        OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();
    }
}

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" int __stdcall OtTitleDialogProc_0001baf0_Wip(
    OtDialogHandle_Product dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam)
{
    TitleDialogState_0041baf0_Product* state =
        reinterpret_cast<TitleDialogState_0041baf0_Product*>(
            GetWindowLongA(dialog, 8));

    switch (message) {
    case 0x0002:
        OtSetDialogBusyCursor_Product();
        if (state != 0) {
            KillTimer(dialog, state->timer_id);
        }
        OtCloseTitleTheme_Product_0041baf0();
        if (state != 0) {
            delete state;
            SetWindowLongA(dialog, 8, 0);
        }
        g_activeScreenDialogWindow_00404dd0 = 0;
        OtRestoreDialogArrowCursor_Product();
        return 1;

    case 0x000f:
        OtSetDialogBusyCursor_Product();
        OtPaintTitleDialog_Product_0041c760(dialog, state);
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
        if ((wparam & 0xffff) == 0x03e9) {
            return OtDrawOwnedBitmapButton_Product(
                reinterpret_cast<OtDialogDrawItem_Product*>(lparam),
                &state->start_up,
                &state->start_down);
        }
        if ((wparam & 0xffff) == 0x03ea) {
            return OtDrawOwnedBitmapButton_Product(
                reinterpret_cast<OtDialogDrawItem_Product*>(lparam),
                &state->continue_up,
                &state->continue_down);
        }
        return 1;

    case 0x0110:
        g_activeScreenDialogWindow_00404dd0 = dialog;
        g_titleDialogLeaderboardMode_00439e00 = lparam != 0x0c;
        OtInitTitleDialog_0041c410_RealCpp(dialog);
        return 0;

    case 0x0111:
        if ((wparam & 0xffff) == 0x03e9) {
            if (OtRiverEnsureScratchBuffer_RealCpp() != 0) {
                if (OtLoadSavedGameFromDialog_0000c4e0_Wip(dialog) != 0) {
                    PostMessageA(GetParent(dialog), 0x0472, 0, 0);
                } else {
                    OtReleaseCachedGlobalHandle_Product_0040f840();
                }
            }
            return 1;
        }
        if ((wparam & 0xffff) == 0x03ea) {
            PostMessageA(GetParent(dialog), 0x046e, 0, 0);
            DestroyWindow(dialog);
            g_activeScreenDialogWindow_00404dd0 = 0;
            return 1;
        }
        return 1;

    case 0x0113:
        if (state != 0 && wparam == 1000) {
            --state->timer_phase;
            if (state->timer_phase == 0) {
                OtToggleTitleAttractFrame_RealCpp(dialog, state);
            }
        }
        return 0;

    case 0x0135:
    case 0x0138:
        return OtPrepareDialogControlColor_Product(
            reinterpret_cast<OtDialogDeviceContext_Product>(wparam),
            g_optionMenuFont_004390d4_00405320,
            0);

    case 0x0201:
        if (state != 0) {
            OtToggleTitleAttractFrame_RealCpp(dialog, state);
        }
        return 1;

    case 0x03b9:
        if (wparam == 1) {
            if (g_cdMediaMode_00439108 != 0) {
                OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();
            } else {
                OtPlayMidiAudio_0000ced0_RealCpp(0);
            }
        }
        return 1;

    case 0x0465:
        if (state != 0) {
            if (g_titleThemeEnabled_004390ec != 0) {
                OtCloseTitleTheme_Product_0041baf0();
            }
            KillTimer(dialog, state->timer_id);
        }
        return 1;

    case 0x0467:
        if (state != 0) {
            if (g_titleThemeEnabled_004390ec != 0 &&
                IsIconic(GetParent(dialog)) == 0) {
                OtPlayTitleTheme_Product_0041baf0(dialog);
            }
            state->timer_id = SetTimer(dialog, 1000, 30000, 0);
        }
        return 1;

    case 0x046a:
        OtPlayTitleTheme_Product_0041baf0(dialog);
        return 1;

    case 0x046b:
        OtCloseTitleTheme_Product_0041baf0();
        return 1;

    case 0x047f:
        if (state != 0) {
            OtPopulateTitleLeaderboard_0041c210_Product(dialog, state);
        }
        return 0;
    }

    return 0;
}

#pragma optimize("", on)

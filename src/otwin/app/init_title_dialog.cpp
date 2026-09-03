// Product semantic recovery for OtInitTitleDialog @ 0x0041c410.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This recovery source must be compiled with 32-bit MSVC."
#endif

#include <string.h>

#include "../graphics/positioned_bitmap_descriptor_state.h"

#pragma intrinsic(memset)

typedef void* OtHandle_0041c410;

struct OtRect_0041c410 {
    long left;
    long top;
    long right;
    long bottom;

    long Width() const
    {
        return right - left;
    }

    long Height() const
    {
        return bottom - top;
    }
};

extern "C" __declspec(dllimport) OtHandle_0041c410 __stdcall GetParent(
    OtHandle_0041c410 window);
extern "C" __declspec(dllimport) int __stdcall GetClientRect(
    OtHandle_0041c410 window,
    OtRect_0041c410* rect);
extern "C" __declspec(dllimport) unsigned int __stdcall GetDialogBaseUnits();
extern "C" __declspec(dllimport) int __stdcall SetWindowPos(
    OtHandle_0041c410 window,
    OtHandle_0041c410 insert_after,
    int x,
    int y,
    int width,
    int height,
    unsigned int flags);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    OtHandle_0041c410 window,
    const char* text,
    const char* caption,
    unsigned int type);
extern "C" __declspec(dllimport) void __stdcall PostQuitMessage(int exit_code);
extern "C" __declspec(dllimport) unsigned int __stdcall SetTimer(
    OtHandle_0041c410 window,
    unsigned int timer_id,
    unsigned int interval_ms,
    void* callback);
extern "C" __declspec(dllimport) int __stdcall IsIconic(
    OtHandle_0041c410 window);
extern "C" __declspec(dllimport) int __stdcall SetWindowLongA(
    OtHandle_0041c410 window,
    int index,
    long value);
extern "C" __declspec(dllimport) int __stdcall ShowWindow(
    OtHandle_0041c410 window,
    int show_command);

#pragma comment(lib, "user32.lib")

extern void* __cdecl operator new(unsigned int bytes);

extern "C" void __cdecl
OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
    OtHandle_0041c410 dialog,
    int control_id,
    int dialog_unit_width,
    int dialog_unit_height);
extern "C" void __cdecl OtResizeControl_RealCpp(
    OtHandle_0041c410 dialog,
    int control_id,
    int width,
    int height);
extern "C" int __cdecl OtPopulateTitleLeaderboard_0041c210_Product(
    OtHandle_0041c410 dialog,
    void* state);
extern "C" void __cdecl OtOpenMidiAudioFileMaskClosed_0000cd60_RealCpp(
    OtHandle_0041c410 owner,
    const char* path);
extern "C" void __cdecl OtPlayMidiAudio_0000ced0_RealCpp(int restart);
extern "C" void __cdecl OtOpenWaveAudioFile_0000d110_RealCpp(
    OtHandle_0041c410 owner,
    const char* path);
extern "C" void __cdecl OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" int g_cdMediaMode_00439108;
extern "C" int g_titleThemeEnabled_004390ec;

#pragma pack(push, 1)
struct TitleLeaderboardEntry_0041c410 {
    char primary[20];
    char secondary[11];
};

struct TitleLeaderboardState_0042fd80 {
    int count;
    TitleLeaderboardEntry_0041c410 entries[10];

    TitleLeaderboardState_0042fd80();
};

struct TitleDialogState_0041c410 {
    PositionedBitmapDescriptorState_0040ba40 frame;
    PositionedBitmapDescriptorState_0040ba40 overlay;
    PositionedBitmapDescriptorState_0040ba40 start_default;
    PositionedBitmapDescriptorState_0040ba40 start_pressed;
    PositionedBitmapDescriptorState_0040ba40 continue_default;
    PositionedBitmapDescriptorState_0040ba40 continue_pressed;
    TitleLeaderboardState_0042fd80 leaderboard;
    unsigned int timer_id;
    unsigned int timer_phase;
    RectResource_0040b690 title_rect;
};
#pragma pack(pop)

typedef char OtTitlePositionedBitmapLayoutCheck[
    sizeof(PositionedBitmapDescriptorState_0040ba40) == 0x28 ? 1 : -1];
typedef char OtTitleLeaderboardLayoutCheck[
    sizeof(TitleLeaderboardState_0042fd80) == 0x13a ? 1 : -1];
typedef char OtTitleDialogStateLayoutCheck[
    sizeof(TitleDialogState_0041c410) == 0x242 ? 1 : -1];

extern "C" const char g_titleAllocationMessage_0041c410[] =
    "Can't allocate local memory.";
extern "C" const char g_titleAllocationCaption_0041c410[] =
    "TitleDlgProc";
extern "C" const char g_titleMidiPath_0041c410[] = "theme.mid";
extern "C" const char g_titleWavePath_0041c410[] = "theme.wav";

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" void __cdecl OtInitTitleDialog_0041c410_RealCpp(
    OtHandle_0041c410 dialog)
{
    TitleDialogState_0041c410* state = new TitleDialogState_0041c410;
    if (state == 0) {
        MessageBoxA(
            GetParent(dialog),
            g_titleAllocationMessage_0041c410,
            g_titleAllocationCaption_0041c410,
            0);
        PostQuitMessage(0);
        return;
    }

    OtRect_0041c410 client_rect;
    register OtHandle_0041c410 active_dialog = dialog;
    unsigned int dialog_unit_width;
    unsigned int dialog_unit_height;
    register int dialog_left;
    register int dialog_top;

    GetClientRect(GetParent(active_dialog), &client_rect);
    dialog_unit_width = static_cast<unsigned short>(GetDialogBaseUnits());
    dialog_unit_height = static_cast<unsigned short>(
        GetDialogBaseUnits() >> 16);
    dialog_left = client_rect.left + 10;
    dialog_top = client_rect.top + 10;
    SetWindowPos(
        active_dialog,
        0,
        dialog_left,
        dialog_top,
        client_rect.Width() - 20,
        client_rect.Height() - 20,
        4);

    register int control_id = 0x3f2;
    do {
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            active_dialog,
            control_id,
            dialog_unit_width,
            dialog_unit_height);
        ++control_id;
    } while (control_id <= 0x419);

    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        active_dialog, 0x3e9, dialog_unit_width, dialog_unit_height);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        active_dialog, 0x3ea, dialog_unit_width, dialog_unit_height);

    state->start_default.
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603, 0x3eb);
    state->start_pressed.
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603, 0x3ec);
    state->continue_default.
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603, 0x3ed);
    state->continue_pressed.
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603, 0x3ee);
    state->frame.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        g_applicationModule_00405a40_20260603, 0x0fa0);
    state->overlay.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        g_applicationModule_00405a40_20260603, 0x456);
    state->title_rect.OtLoadRectFromResource_RealCpp(
        g_applicationModule_00405a40_20260603,
        reinterpret_cast<const void*>(0x0fa4));

    state->timer_id = SetTimer(active_dialog, 1000, 30000, 0);
    state->timer_phase = 2;

    if (g_titleThemeEnabled_004390ec != 0 &&
        IsIconic(GetParent(active_dialog)) == 0) {
        if (g_cdMediaMode_00439108 != 0) {
            OtOpenWaveAudioFile_0000d110_RealCpp(
                active_dialog,
                g_titleWavePath_0041c410);
            OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();
        } else {
            OtOpenMidiAudioFileMaskClosed_0000cd60_RealCpp(
                active_dialog,
                g_titleMidiPath_0041c410);
            OtPlayMidiAudio_0000ced0_RealCpp(0);
        }
    }

    SetWindowLongA(active_dialog, 8, reinterpret_cast<long>(state));
    OtResizeControl_RealCpp(
        active_dialog,
        0x3e9,
        state->start_default.width,
        state->start_default.height);
    OtResizeControl_RealCpp(
        active_dialog,
        0x3ea,
        state->continue_default.width,
        state->continue_default.height);
    OtPopulateTitleLeaderboard_0041c210_Product(active_dialog, state);
    ShowWindow(active_dialog, 5);
}

TitleLeaderboardState_0042fd80::TitleLeaderboardState_0042fd80()
{
    memset(entries, 0, sizeof(entries));
}

RectResource_0040b690::RectResource_0040b690()
{
    left = 0;
    top = 0;
    right = 0;
    bottom = 0;
}

#pragma optimize("", on)

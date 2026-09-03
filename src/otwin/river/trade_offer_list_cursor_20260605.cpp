// Product implementation of the mask-clean trade-offer dialog setup routine.

#include "river_trade_dialog_state.h"

typedef void* HWND_004277b0_20260604;
typedef void* HPALETTE_004277b0_20260604;

#pragma pack(push, 1)
struct Rect_004277b0_20260604 {
    int left;
    int top;
    int right;
    int bottom;
};
#pragma pack(pop)

extern "C" __declspec(dllimport) int __stdcall GetWindowRect(
    HWND_004277b0_20260604 window,
    Rect_004277b0_20260604* rect);
extern "C" __declspec(dllimport) int __stdcall GetClientRect(
    HWND_004277b0_20260604 window,
    Rect_004277b0_20260604* rect);
extern "C" __declspec(dllimport) HWND_004277b0_20260604 __stdcall GetParent(
    HWND_004277b0_20260604 window);
extern "C" __declspec(dllimport) unsigned int __stdcall GetDialogBaseUnits();
extern "C" __declspec(dllimport) int __stdcall SetWindowPos(
    HWND_004277b0_20260604 window,
    HWND_004277b0_20260604 insert_after,
    int x,
    int y,
    int cx,
    int cy,
    unsigned int flags);
extern "C" __declspec(dllimport) RiverDeviceContext_004277b0 __stdcall GetDC(
    HWND_004277b0_20260604 window);
extern "C" __declspec(dllimport) long __stdcall SetWindowLongA(
    HWND_004277b0_20260604 window,
    int index,
    long value);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    HWND_004277b0_20260604 window,
    const char* text,
    const char* caption,
    unsigned int type);
extern "C" __declspec(dllimport) HPALETTE_004277b0_20260604 __stdcall
    SelectPalette(
        RiverDeviceContext_004277b0 dc,
        HPALETTE_004277b0_20260604 palette,
        int force_background);
extern "C" __declspec(dllimport) unsigned int __stdcall RealizePalette(
    RiverDeviceContext_004277b0 dc);
extern "C" __declspec(dllimport) void __stdcall PostQuitMessage(int exit_code);
extern "C" __declspec(dllimport) unsigned int __stdcall timeBeginPeriod(
    unsigned int period_ms);

extern "C" void* __cdecl OtAllocateNewBlock_RealCpp(unsigned int bytes);
extern "C" HPALETTE_004277b0_20260604 g_gamePalette;
extern "C" const char g_tradeCursorAllocFailText_004277b0_20260604[] =
    "Unable to allocate space for rafting object";
extern "C" const char g_tradeCursorAllocFailCaption_004277b0_20260604[] =
    "InitRaftDlg";

#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "winmm.lib")

#pragma optimize("s", off)
#pragma optimize("t", on)

void* __cdecl RiverTradeDialogState_004277b0_20260604::operator new(
    unsigned int bytes)
{
    return OtAllocateNewBlock_RealCpp(bytes);
}

extern "C" void __cdecl OtTradeOfferListCursor_000277b0_20260604_SetupDialog(
    HWND_004277b0_20260604 dialog)
{
    register HWND_004277b0_20260604 owner_dialog = dialog;
    Rect_004277b0_20260604 client_rect;
    register RiverTradeDialogState_004277b0_20260604* state;
    register int frame_left;
    register int frame_top;

    GetClientRect(GetParent(owner_dialog), &client_rect);
    GetDialogBaseUnits();
    GetDialogBaseUnits();
    frame_left = client_rect.left + 10;
    frame_top = client_rect.top + 10;
    SetWindowPos(
        owner_dialog,
        0,
        frame_left,
        frame_top,
        (client_rect.right - client_rect.left) - 20,
        (client_rect.bottom - client_rect.top) - 20,
        4);
    GetClientRect(owner_dialog, &client_rect);

    state = new RiverTradeDialogState_004277b0_20260604;

    if (state == 0) {
        MessageBoxA(
            GetParent(owner_dialog),
            g_tradeCursorAllocFailText_004277b0_20260604,
            g_tradeCursorAllocFailCaption_004277b0_20260604,
            0);
        PostQuitMessage(0);
    } else {
        state->selected_or_hovered_item = 0;
        timeBeginPeriod(15);
        state->dc = GetDC(owner_dialog);
        SelectPalette(state->dc, g_gamePalette, 0);
        RealizePalette(state->dc);
        state->audio_mode = 1;
        state->sound_started = 0;
        SetWindowLongA(owner_dialog, 8, (long)state);
    }
}

#pragma optimize("", on)

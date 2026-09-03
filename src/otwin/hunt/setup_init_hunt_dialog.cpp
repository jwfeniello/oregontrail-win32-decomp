// Hunt-dialog setup at 0x00415380.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "user32.lib")
#pragma comment(lib, "winmm.lib")

extern "C" __declspec(dllimport) void* __stdcall LoadCursorA(
    void* instance,
    const char* cursor_name);
extern "C" __declspec(dllimport) void* __stdcall SetCursor(void* cursor);
extern "C" __declspec(dllimport) void* __stdcall GetParent(void* window);
extern "C" __declspec(dllimport) int __stdcall GetClientRect(
    void* window,
    void* rect);
extern "C" __declspec(dllimport) int __stdcall SetWindowPos(
    void* window,
    void* insert_after,
    int x,
    int y,
    int cx,
    int cy,
    unsigned int flags);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    void* window,
    const char* text,
    const char* caption,
    unsigned int type);
extern "C" __declspec(dllimport) void __stdcall PostQuitMessage(int exit_code);
extern "C" __declspec(dllimport) unsigned int __stdcall timeBeginPeriod(
    unsigned int period);
extern "C" __declspec(dllimport) void* __stdcall GetDC(void* window);
extern "C" __declspec(dllimport) void* __stdcall SelectPalette(
    void* dc,
    void* palette,
    int force_background);
extern "C" __declspec(dllimport) unsigned int __stdcall RealizePalette(void* dc);
extern "C" __declspec(dllimport) long __stdcall SetWindowLongA(
    void* window,
    int index,
    long value);
extern "C" __declspec(dllimport) unsigned long __stdcall GetDialogBaseUnits();

extern void* __cdecl operator new(unsigned int bytes);
extern void __cdecl operator delete(void* block);

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" void* g_gamePalette;

static const char g_huntSetupAllocMessage_00415380[] =
    "Can't allocate local memory";
static const char g_huntSetupCaption_00415380[] = "InitHuntDlg";

struct Rect_00415380 {
    long left;
    long top;
    long right;
    long bottom;
};

#include "hunt_dialog_state_constructor.h"

extern "C" void __cdecl
OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
    void* dialog,
    int control_id,
    int dialog_unit_width,
    int dialog_unit_height);

extern "C" void __cdecl OtResizeControl_RealCpp(
    void* dialog,
    unsigned int control_id,
    int width,
    int height);

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" void __cdecl OtSetupInitHuntDialog_00015380_RealCpp(
    void* dialog)
{
    void* old_cursor;
    unsigned int base_unit_x;
    unsigned int base_unit_y;
    Rect_00415380 client_rect;
    int dialog_x;
    int dialog_y;
    HuntDialogState_00415380_SetupWip* state;

    old_cursor = SetCursor(LoadCursorA(0, (const char*)0x7f02));
    GetClientRect(GetParent(dialog), &client_rect);

    base_unit_x = (unsigned short)GetDialogBaseUnits();
    base_unit_y = (unsigned short)(GetDialogBaseUnits() >> 16);

    dialog_x = client_rect.left + 10;
    dialog_y = client_rect.top + 10;

    SetWindowPos(
        dialog,
        0,
        dialog_x,
        dialog_y,
        client_rect.right - client_rect.left - 20,
        client_rect.bottom - client_rect.top - 20,
        4);

    GetClientRect(dialog, &client_rect);

    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog,
        0x900,
        base_unit_x,
        base_unit_y);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog,
        0x901,
        base_unit_x,
        base_unit_y);

    state = new HuntDialogState_00415380_SetupWip;

    if (state == 0) {
        MessageBoxA(
            GetParent(dialog),
            g_huntSetupAllocMessage_00415380,
            g_huntSetupCaption_00415380,
            0);
        PostQuitMessage(0);
        return;
    }

    state->next_button.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        g_applicationModule_00405a40_20260603,
        0x903);
    state->start_button.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        g_applicationModule_00405a40_20260603,
        0x904);
    state->action_button.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        g_applicationModule_00405a40_20260603,
        0x905);
    state->disabled_button.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        g_applicationModule_00405a40_20260603,
        0x906);

    state->paint_ready = 0;
    state->active = 1;
    timeBeginPeriod(15);

    state->dc = GetDC(dialog);
    SelectPalette(state->dc, g_gamePalette, 0);
    RealizePalette(state->dc);

    state->command_pressed = 0;
    SetWindowLongA(dialog, 8, (long)state);

    OtResizeControl_RealCpp(
        dialog,
        0x900,
        state->next_button.width,
        state->next_button.height);
    OtResizeControl_RealCpp(
        dialog,
        0x901,
        state->action_button.width,
        state->action_button.height);

    SetCursor(old_cursor);
}

#pragma optimize("", on)

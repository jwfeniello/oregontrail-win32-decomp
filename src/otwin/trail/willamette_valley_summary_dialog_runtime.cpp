// Product-semantic Willamette Valley score-summary dialog callback @ 0x00424f50.
//
// The callback owns the three positioned bitmaps allocated by the companion
// initializer, paints the score sheet and separators, draws the owner-drawn
// close button, and returns the application to the title flow when dismissed.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include "../graphics/positioned_bitmap_descriptor_state.h"

typedef void* OtWillametteHandle_00424f50;

extern "C" OtWillametteHandle_00424f50 g_gamePalette;
extern "C" OtWillametteHandle_00424f50
    g_sharedDialogBackgroundBrush_004390c0;
extern "C" OtWillametteHandle_00424f50
    g_optionMenuFont_004390d4_00405320;
extern "C" OtWillametteHandle_00424f50
    g_dialogFont_004390d8_00405320;
extern "C" OtWillametteHandle_00424f50
    g_activeScreenDialogWindow_00404dd0;
extern "C" int g_appBusyCursorActive_Product_004034d0;

extern "C" __declspec(dllimport) OtWillametteHandle_00424f50 __stdcall BeginPaint(
    OtWillametteHandle_00424f50 window,
    void* paint);
extern "C" __declspec(dllimport) int __stdcall EndPaint(
    OtWillametteHandle_00424f50 window,
    const void* paint);
extern "C" __declspec(dllimport) OtWillametteHandle_00424f50 __stdcall LoadCursorA(
    OtWillametteHandle_00424f50 instance,
    const void* cursor_name);
extern "C" __declspec(dllimport) OtWillametteHandle_00424f50 __stdcall SetCursor(
    OtWillametteHandle_00424f50 cursor);
extern "C" __declspec(dllimport) OtWillametteHandle_00424f50 __stdcall SelectPalette(
    OtWillametteHandle_00424f50 dc,
    OtWillametteHandle_00424f50 palette,
    int force_background);
extern "C" __declspec(dllimport) int __stdcall UnrealizeObject(
    OtWillametteHandle_00424f50 object);
extern "C" __declspec(dllimport) unsigned int __stdcall RealizePalette(
    OtWillametteHandle_00424f50 dc);
extern "C" __declspec(dllimport) OtWillametteHandle_00424f50 __stdcall SelectObject(
    OtWillametteHandle_00424f50 dc,
    OtWillametteHandle_00424f50 object);
extern "C" __declspec(dllimport) unsigned long __stdcall SetTextColor(
    OtWillametteHandle_00424f50 dc,
    unsigned long color);
extern "C" __declspec(dllimport) int __stdcall SetBkMode(
    OtWillametteHandle_00424f50 dc,
    int mode);
extern "C" __declspec(dllimport) long __stdcall GetWindowLongA(
    OtWillametteHandle_00424f50 window,
    int index);
extern "C" __declspec(dllimport) OtWillametteHandle_00424f50 __stdcall GetStockObject(int object);
extern "C" __declspec(dllimport) OtWillametteHandle_00424f50 __stdcall GetDlgItem(
    OtWillametteHandle_00424f50 dialog,
    int control_id);
extern "C" __declspec(dllimport) int __stdcall GetWindowRect(
    OtWillametteHandle_00424f50 window,
    void* rect);
extern "C" __declspec(dllimport) int __stdcall ScreenToClient(
    OtWillametteHandle_00424f50 window,
    void* point);
extern "C" __declspec(dllimport) int __stdcall MoveToEx(
    OtWillametteHandle_00424f50 dc,
    int x,
    int y,
    void* old_point);
extern "C" __declspec(dllimport) int __stdcall LineTo(
    OtWillametteHandle_00424f50 dc,
    int x,
    int y);
extern "C" __declspec(dllimport) OtWillametteHandle_00424f50 __stdcall GetParent(
    OtWillametteHandle_00424f50 window);
extern "C" __declspec(dllimport) int __stdcall PostMessageA(
    OtWillametteHandle_00424f50 window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall EndDialog(
    OtWillametteHandle_00424f50 dialog,
    int result);

#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "user32.lib")

extern void __cdecl operator delete(void* block);

extern "C" int __cdecl OtSelectDialogCursor_0040d530_RealCpp(
    int force_busy_cursor,
    void* window);
extern "C" void __cdecl
OtInitWillametteValleySummaryDialog_004253a0_ProductWip(void* dialog);

#pragma pack(push, 1)
struct OtWillamettePoint_00424f50 {
    int x;
    int y;
};

struct OtWillametteRect_00424f50 {
    int left;
    int top;
    int right;
    int bottom;
};

struct OtWillamettePaintStruct_00424f50 {
    char bytes[0x40];
};

struct OtWillametteDrawItem_00424f50 {
    unsigned int control_type;
    unsigned int control_id;
    unsigned int item_id;
    unsigned int item_action;
    unsigned int item_state;
    OtWillametteHandle_00424f50 item_window;
    OtWillametteHandle_00424f50 dc;
    OtWillametteRect_00424f50 item_rect;
    unsigned long item_data;
};

struct PositionedBitmap_0040b7b0_Semantic {
    char bytes[0x28];

    int OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        void* dc,
        int source_x,
        int source_y);
};

#include "willamette_valley_summary_dialog_state.h"
#pragma pack(pop)

typedef char OtWillametteSummaryStateSizeMustBe78_00424f50[
    sizeof(WillametteValleySummaryDialogState_00424f50_Product) == 0x78
        ? 1
        : -1];

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

static __inline void OtSetWillametteSummaryBusy_00424f50(int busy)
{
    g_appBusyCursorActive_Product_004034d0 = busy;
    SetCursor(LoadCursorA(
        0,
        (const void*)(busy != 0 ? 0x7f02 : 0x7f00)));
}

static __inline void OtDrawWillametteSummarySeparator_00424f50(
    void* dialog,
    void* dc,
    int control_id)
{
    OtWillametteRect_00424f50 rect;
    OtWillamettePoint_00424f50 point;

    GetWindowRect(GetDlgItem(dialog, control_id), &rect);
    point.x = rect.left;
    point.y = rect.top - 1;
    ScreenToClient(dialog, &point);
    MoveToEx(dc, point.x, point.y, 0);
    LineTo(dc, point.x + rect.right - rect.left, point.y);
}

static __inline void OtBlitWillametteSummaryBitmap_00424f50(
    PositionedBitmapDescriptorState_0040ba40* bitmap,
    void* dc)
{
    reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(bitmap)
        ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
}

extern "C" int __stdcall
OtWillametteValleySummaryDialogProc_00424f50_ProductWip(
    void* dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam)
{
    WillametteValleySummaryDialogState_00424f50_Product* state;

    switch (message) {
    default:
    default_return:
        return 0;

    case 0x0002: {
        state =
            reinterpret_cast<WillametteValleySummaryDialogState_00424f50_Product*>(
                GetWindowLongA(dialog, 8));
        if (state != 0) {
            delete state;
        }
        goto default_return;
    }

    case 0x000f: {
        OtWillamettePaintStruct_00424f50 paint;
        void* dc;

        OtSetWillametteSummaryBusy_00424f50(1);
        dc = BeginPaint(dialog, &paint);
        SelectPalette(dc, g_gamePalette, 0);
        UnrealizeObject(g_gamePalette);
        RealizePalette(dc);
        SelectObject(dc, g_optionMenuFont_004390d4_00405320);
        SetTextColor(dc, 0);

        state =
            reinterpret_cast<WillametteValleySummaryDialogState_00424f50_Product*>(
                GetWindowLongA(dialog, 8));
        OtBlitWillametteSummaryBitmap_00424f50(&state->score_sheet, dc);

        SelectObject(dc, GetStockObject(7));
        OtDrawWillametteSummarySeparator_00424f50(
            dialog,
            dc,
            0x1b6f);
        OtDrawWillametteSummarySeparator_00424f50(
            dialog,
            dc,
            0x1b71);
        EndPaint(dialog, &paint);
        OtSetWillametteSummaryBusy_00424f50(0);
        return 1;
    }

    case 0x0014: {
        return 1;
    }

    case 0x0020: {
        return OtSelectDialogCursor_0040d530_RealCpp(
            g_appBusyCursorActive_Product_004034d0,
            reinterpret_cast<void*>(wparam));
    }

    case 0x002b: {
        OtWillametteDrawItem_00424f50* draw_item =
            reinterpret_cast<OtWillametteDrawItem_00424f50*>(lparam);

        state =
            reinterpret_cast<WillametteValleySummaryDialogState_00424f50_Product*>(
                GetWindowLongA(dialog, 8));
        SelectPalette(draw_item->dc, g_gamePalette, 0);
        RealizePalette(draw_item->dc);

        if (draw_item->item_action == 1) {
            if (wparam == 0x12c) {
                OtBlitWillametteSummaryBitmap_00424f50(
                    &state->close_button_up,
                    draw_item->dc);
            }
            return 1;
        }

        if (draw_item->item_action == 2) {
            if (wparam == 0x12c) {
                if ((draw_item->item_state & 1) != 0) {
                    OtBlitWillametteSummaryBitmap_00424f50(
                        &state->close_button_down,
                        draw_item->dc);
                } else {
                    OtBlitWillametteSummaryBitmap_00424f50(
                        &state->close_button_up,
                        draw_item->dc);
                }
            }
            return 1;
        }
        return 1;
    }

    case 0x0110: {
        OtSetWillametteSummaryBusy_00424f50(1);
        g_activeScreenDialogWindow_00404dd0 = dialog;
        OtInitWillametteValleySummaryDialog_004253a0_ProductWip(dialog);
        return 1;
    }

    case 0x0111: {
        if ((wparam & 0xffff) == 0x12c) {
            PostMessageA(GetParent(dialog), 0x046d, 0, 0);
            EndDialog(dialog, 0);
        }
        goto default_return;
    }

    case 0x0135:
    case 0x0138: {
        void* dc = reinterpret_cast<void*>(wparam);
        int control_id;

        SelectPalette(dc, g_gamePalette, 0);
        RealizePalette(dc);
        SetBkMode(dc, 1);
        SetTextColor(dc, 0);
        control_id = static_cast<int>(GetWindowLongA(
            reinterpret_cast<void*>(lparam),
            -12));

        if (message == 0x0135 ||
            control_id == 0x1b59 ||
            control_id == 0x1b5a ||
            control_id == 0x1b5b ||
            control_id == 0x1b71) {
            SelectObject(dc, g_optionMenuFont_004390d4_00405320);
        } else {
            SelectObject(dc, g_dialogFont_004390d8_00405320);
        }
        return reinterpret_cast<long>(
            g_sharedDialogBackgroundBrush_004390c0);
    }
    }
}

#pragma optimize("", on)
#pragma code_seg()

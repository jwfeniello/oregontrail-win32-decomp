// Lane-local rebased Product proposal for the Trade Selection owner cluster.
//
// This retains the accepted external validator and its canonical persisted-state
// owner while restoring the callback's monolithic four-bitmap RAII boundary and
// supplying the Product Trade Selection initializer.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This Product source must be compiled with 32-bit Microsoft C++."
#endif

#include "../graphics/positioned_bitmap_descriptor_state.h"
#include <string.h>
#include <stdlib.h>

#pragma intrinsic(memset, strcpy)

typedef void* OtTradeSelectionHandle_0040ded0;

struct OtTradeSelectionRect_0040ded0 {
    long left;
    long top;
    long right;
    long bottom;
};

struct OtTradeSelectionPoint_0040e350 {
    long x;
    long y;
};

struct OtTradeSelectionDrawItem_0040ded0 {
    unsigned int control_type;
    unsigned int control_id;
    unsigned int item_id;
    unsigned int item_action;
    unsigned int item_state;
    OtTradeSelectionHandle_0040ded0 item_window;
    OtTradeSelectionHandle_0040ded0 dc;
    OtTradeSelectionRect_0040ded0 item_rect;
    unsigned long item_data;
};

#pragma pack(push, 1)
struct PositionedBitmap_0040b7b0_Semantic {
    char bytes[0x28];

    int OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        OtTradeSelectionHandle_0040ded0 dc,
        int source_x,
        int source_y);
};

struct TradeSelectionDialogState_0040ded0_Product {
    PositionedBitmapDescriptorState_0040ba40 okay_default;
    PositionedBitmapDescriptorState_0040ba40 okay_pressed;
    PositionedBitmapDescriptorState_0040ba40 cancel_default;
    PositionedBitmapDescriptorState_0040ba40 cancel_pressed;
    int* accepted_result;
};

struct TradeJourneyInventoryView_0040e350_Product {
    char reserved_000[0x96];
    short oxen;
    short reserved_098;
    short food;
    short clothing;
    short ammunition;
    short wagon_wheels;
    short wagon_axles;
    short wagon_tongues;
    short spare_parts;
    int cash_cents;
};
#pragma pack(pop)

typedef char OtTradeSelectionBitmapSizeMustBe028_0040ded0[
    sizeof(PositionedBitmapDescriptorState_0040ba40) == 0x28 ? 1 : -1];
typedef char OtTradeSelectionPressedOffsetMustBe028_0040ded0[
    (unsigned int)&(((TradeSelectionDialogState_0040ded0_Product*)0)->
        okay_pressed) == 0x028
        ? 1
        : -1];
typedef char OtTradeSelectionCancelOffsetMustBe050_0040ded0[
    (unsigned int)&(((TradeSelectionDialogState_0040ded0_Product*)0)->
        cancel_default) == 0x050
        ? 1
        : -1];
typedef char OtTradeSelectionCancelPressedOffsetMustBe078_0040ded0[
    (unsigned int)&(((TradeSelectionDialogState_0040ded0_Product*)0)->
        cancel_pressed) == 0x078
        ? 1
        : -1];
typedef char OtTradeSelectionResultOffsetMustBe0a0_0040ded0[
    (unsigned int)&(((TradeSelectionDialogState_0040ded0_Product*)0)->
        accepted_result) == 0x0a0
        ? 1
        : -1];
typedef char OtTradeSelectionStateSizeMustBe0a4_0040ded0[
    sizeof(TradeSelectionDialogState_0040ded0_Product) == 0x0a4 ? 1 : -1];

extern "C" __declspec(dllimport) OtTradeSelectionHandle_0040ded0 __stdcall
SelectPalette(
    OtTradeSelectionHandle_0040ded0 dc,
    OtTradeSelectionHandle_0040ded0 palette,
    int force_background);
extern "C" __declspec(dllimport) unsigned int __stdcall RealizePalette(
    OtTradeSelectionHandle_0040ded0 dc);
extern "C" __declspec(dllimport) OtTradeSelectionHandle_0040ded0 __stdcall
LoadCursorA(
    OtTradeSelectionHandle_0040ded0 instance,
    const void* cursor_name);
extern "C" __declspec(dllimport) OtTradeSelectionHandle_0040ded0 __stdcall
SetCursor(OtTradeSelectionHandle_0040ded0 cursor);
extern "C" __declspec(dllimport) int __stdcall GetUpdateRect(
    OtTradeSelectionHandle_0040ded0 window,
    OtTradeSelectionRect_0040ded0* rect,
    int erase);
extern "C" __declspec(dllimport) int __stdcall FillRect(
    OtTradeSelectionHandle_0040ded0 dc,
    const OtTradeSelectionRect_0040ded0* rect,
    OtTradeSelectionHandle_0040ded0 brush);
extern "C" __declspec(dllimport) long __stdcall GetWindowLongA(
    OtTradeSelectionHandle_0040ded0 window,
    int index);
extern "C" __declspec(dllimport) long __stdcall SetWindowLongA(
    OtTradeSelectionHandle_0040ded0 window,
    int index,
    long value);
extern "C" __declspec(dllimport) int __stdcall GetWindowRect(
    OtTradeSelectionHandle_0040ded0 window,
    OtTradeSelectionRect_0040ded0* rect);
extern "C" __declspec(dllimport) int __stdcall GetClientRect(
    OtTradeSelectionHandle_0040ded0 window,
    OtTradeSelectionRect_0040ded0* rect);
extern "C" __declspec(dllimport) OtTradeSelectionHandle_0040ded0 __stdcall
GetParent(OtTradeSelectionHandle_0040ded0 window);
extern "C" __declspec(dllimport) int __stdcall ClientToScreen(
    OtTradeSelectionHandle_0040ded0 window,
    OtTradeSelectionPoint_0040e350* point);
extern "C" __declspec(dllimport) int __stdcall SetWindowPos(
    OtTradeSelectionHandle_0040ded0 window,
    OtTradeSelectionHandle_0040ded0 insert_after,
    int x,
    int y,
    int width,
    int height,
    unsigned int flags);
extern "C" __declspec(dllimport) unsigned int __stdcall GetDialogBaseUnits();
extern "C" __declspec(dllimport) OtTradeSelectionHandle_0040ded0 __stdcall
GetDlgItem(
    OtTradeSelectionHandle_0040ded0 dialog,
    int control_id);
extern "C" __declspec(dllimport) int __stdcall SetWindowTextA(
    OtTradeSelectionHandle_0040ded0 window,
    const char* text);
extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    OtTradeSelectionHandle_0040ded0 instance,
    unsigned int resource_id,
    char* text,
    int text_count);
extern "C" __declspec(dllimport) char* __stdcall CharLowerA(char* text);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    OtTradeSelectionHandle_0040ded0 window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall PostMessageA(
    OtTradeSelectionHandle_0040ded0 window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) OtTradeSelectionHandle_0040ded0 __stdcall
SetFocus(OtTradeSelectionHandle_0040ded0 window);
extern "C" __declspec(dllimport) int __stdcall EndDialog(
    OtTradeSelectionHandle_0040ded0 dialog,
    int result);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    OtTradeSelectionHandle_0040ded0 owner,
    const char* text,
    const char* caption,
    unsigned int type);
extern "C" __declspec(dllimport) void __stdcall PostQuitMessage(int exit_code);
extern "C" __declspec(dllimport) int __stdcall SetBkMode(
    OtTradeSelectionHandle_0040ded0 dc,
    int mode);
extern "C" __declspec(dllimport) unsigned long __stdcall SetTextColor(
    OtTradeSelectionHandle_0040ded0 dc,
    unsigned long color);

#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "user32.lib")

extern "C" void __cdecl OtScaleWindowToDialogCoords_00401370_Product(
    OtTradeSelectionHandle_0040ded0 parent,
    OtTradeSelectionHandle_0040ded0 dialog,
    unsigned int horizontal_base_units,
    unsigned int vertical_base_units);
extern "C" int __cdecl OtLoadSavedDialogPlacement_00401110_RealCpp(
    const char* section,
    OtTradeSelectionRect_0040ded0* rect);
extern "C" void __cdecl
OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
    OtTradeSelectionHandle_0040ded0 dialog,
    int control_id,
    unsigned int horizontal_base_units,
    unsigned int vertical_base_units);
extern "C" void __cdecl OtResizeControl_RealCpp(
    OtTradeSelectionHandle_0040ded0 dialog,
    int control_id,
    int width,
    int height);
extern "C" void __cdecl OtPersistDialogPlacement_00401430_RealCpp(
    const char* section,
    const OtTradeSelectionRect_0040ded0* rect);
extern "C" int __cdecl OtSelectDialogCursor_0040d530_RealCpp(
    int busy,
    OtTradeSelectionHandle_0040ded0 window);
extern "C" void __cdecl OtFilterNumericEditText_00401000_ProductWip(
    OtTradeSelectionHandle_0040ded0 dialog,
    int control_id);
extern "C" OtTradeSelectionHandle_0040ded0
    g_applicationModule_00405a40_20260603;
extern "C" OtTradeSelectionHandle_0040ded0 g_gamePalette;
extern "C" void* g_journeyState;
extern "C" OtTradeSelectionHandle_0040ded0
    g_sharedDialogBackgroundBrush_004390c0;
extern "C" OtTradeSelectionHandle_0040ded0 g_paletteWhiteBrush_004044f0;
extern "C" int g_appBusyCursorActive_Product_004034d0;

// The accepted external validator TU is the sole canonical owner of original
// persisted UI state 0x0043995c; this initializer only consumes it.
extern "C" int g_lastSelectedTradeItem_Product_0043995c;

static const char kTradeSelectionDialogPlacementKey_0040ded0[] =
    "Trade Dialog";
static const char kTradeSelectionAllocationFailure_0040e350[] =
    "Can't allocate local memory";
static const char kTradeSelectionProcedureName_0040e350[] =
    "TradeDudeDlgProc";
static const char kTradeSelectionMoneyLabel_0040e350[] =
    "money (in dollars)";

extern "C" void __cdecl OtInitTradeSelectionDialog_0040e350_ProductWip(
    OtTradeSelectionHandle_0040ded0 dialog,
    int* accepted_result);
extern "C" int __cdecl
OtValidateTradeSelectionAndOpenOfferDialog_0040eb20_Product(
    void* dialog,
    short* selected_item,
    short* wanted_quantity);

#pragma optimize("s", off)
#pragma optimize("t", on)
#pragma code_seg(".otsem")

extern "C" long __stdcall
OtTradeSelectionDialogProc_0040ded0_ProductWip(
    OtTradeSelectionHandle_0040ded0 dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam)
{
    long result;

    switch (message) {
    case 0x0002: { // WM_DESTROY
        OtTradeSelectionRect_0040ded0 placement_rect;
        TradeSelectionDialogState_0040ded0_Product* state;

        GetWindowRect(dialog, &placement_rect);
        state = reinterpret_cast<TradeSelectionDialogState_0040ded0_Product*>(
            GetWindowLongA(dialog, 8));
        if (state != 0) {
            delete state;
        }
        OtPersistDialogPlacement_00401430_RealCpp(
            kTradeSelectionDialogPlacementKey_0040ded0,
            &placement_rect);
        result = 1;
        break;
    }

    case 0x0014: { // WM_ERASEBKGND
        OtTradeSelectionRect_0040ded0 update_rect;
        OtTradeSelectionHandle_0040ded0 dc;

        g_appBusyCursorActive_Product_004034d0 = 1;
        SetCursor(LoadCursorA(
            0,
            reinterpret_cast<const void*>(0x7f02)));
        dc = reinterpret_cast<OtTradeSelectionHandle_0040ded0>(wparam);
        SelectPalette(dc, g_gamePalette, 0);
        RealizePalette(dc);
        if (GetUpdateRect(dialog, &update_rect, 0) != 0) {
            FillRect(
                dc,
                &update_rect,
                g_sharedDialogBackgroundBrush_004390c0);
        }
        g_appBusyCursorActive_Product_004034d0 = 0;
        SetCursor(LoadCursorA(
            0,
            reinterpret_cast<const void*>(0x7f00)));
        result = 1;
        break;
    }

    case 0x0020: // WM_SETCURSOR
        result = OtSelectDialogCursor_0040d530_RealCpp(
            g_appBusyCursorActive_Product_004034d0,
            reinterpret_cast<OtTradeSelectionHandle_0040ded0>(wparam));
        break;

    case 0x002b: { // WM_DRAWITEM
        OtTradeSelectionDrawItem_0040ded0* draw_item;
        TradeSelectionDialogState_0040ded0_Product* state;

        draw_item = reinterpret_cast<OtTradeSelectionDrawItem_0040ded0*>(
            lparam);
        state = reinterpret_cast<TradeSelectionDialogState_0040ded0_Product*>(
            GetWindowLongA(dialog, 8));
        SelectPalette(draw_item->dc, g_gamePalette, 0);
        RealizePalette(draw_item->dc);

        switch (draw_item->item_action) {
        case 1:
            if (wparam == 0x12c) {
                reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                    &state->okay_default)->
                        OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                            draw_item->dc, 0, 0);
            } else if (wparam == 0x12d) {
                reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                    &state->cancel_default)->
                        OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                            draw_item->dc, 0, 0);
            }
            break;

        case 2:
            if ((draw_item->item_state & 1) != 0) {
                if (wparam == 0x12c) {
                    reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                        &state->okay_pressed)->
                            OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                                draw_item->dc, 0, 0);
                } else if (wparam == 0x12d) {
                    reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                        &state->cancel_pressed)->
                            OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                                draw_item->dc, 0, 0);
                }
            } else {
                if (wparam == 0x12c) {
                    reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                        &state->okay_default)->
                            OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                                draw_item->dc, 0, 0);
                } else if (wparam == 0x12d) {
                    reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                        &state->cancel_default)->
                            OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                                draw_item->dc, 0, 0);
                }
            }
            break;
        }
        result = 1;
        break;
    }

    case 0x0110: // WM_INITDIALOG
        g_appBusyCursorActive_Product_004034d0 = 1;
        SetCursor(LoadCursorA(
            0,
            reinterpret_cast<const void*>(0x7f02)));
        SetWindowLongA(dialog, 8, lparam);
        OtInitTradeSelectionDialog_0040e350_ProductWip(
            dialog,
            reinterpret_cast<int*>(lparam));
        result = 0;
        break;

    case 0x0111: { // WM_COMMAND
        TradeSelectionDialogState_0040ded0_Product* state;
        unsigned short control_id;
        short selected_item;
        short wanted_quantity;

        state = reinterpret_cast<TradeSelectionDialogState_0040ded0_Product*>(
            GetWindowLongA(dialog, 8));
        control_id = static_cast<unsigned short>(wparam);
        if (control_id == 0x12c) {
            state = reinterpret_cast<
                TradeSelectionDialogState_0040ded0_Product*>(
                    GetWindowLongA(dialog, 8));
            if (OtValidateTradeSelectionAndOpenOfferDialog_0040eb20_Product(
                    dialog,
                    &selected_item,
                    &wanted_quantity) != 0) {
                EndDialog(dialog, 1);
            }
        } else if (control_id == 0x12d) {
            *state->accepted_result = 0;
            EndDialog(dialog, 1);
        } else if (control_id == 0x64dd) {
            if (static_cast<unsigned short>(wparam >> 16) == 0x400) {
                OtFilterNumericEditText_00401000_ProductWip(
                    dialog,
                    0x64dd);
            }
        } else if (control_id >= 0x64e1 && control_id <= 0x64e8) {
            SetFocus(GetDlgItem(dialog, 0x64dd));
        }
        result = 1;
        break;
    }

    case 0x0133: // WM_CTLCOLOREDIT
        result = reinterpret_cast<long>(g_paletteWhiteBrush_004044f0);
        break;

    case 0x0135: // WM_CTLCOLORBTN
    case 0x0138: { // WM_CTLCOLORSTATIC
        OtTradeSelectionHandle_0040ded0 dc =
            reinterpret_cast<OtTradeSelectionHandle_0040ded0>(wparam);

        SelectPalette(dc, g_gamePalette, 0);
        RealizePalette(dc);
        SetBkMode(dc, 1);
        SetTextColor(dc, 0);
        result = reinterpret_cast<long>(
            g_sharedDialogBackgroundBrush_004390c0);
        break;
    }

    default:
        result = 0;
        break;
    }

    return result;
}

extern "C" void __cdecl OtInitTradeSelectionDialog_0040e350_ProductWip(
    OtTradeSelectionHandle_0040ded0 dialog,
    int* accepted_result)
{
    unsigned int horizontal_base_units;
    unsigned int vertical_base_units;
    OtTradeSelectionRect_0040ded0 dialog_rect;
    OtTradeSelectionRect_0040ded0 saved_rect;
    OtTradeSelectionRect_0040ded0 parent_rect;
    OtTradeSelectionPoint_0040e350 parent_center;
    char text[100];
    int item;
    TradeSelectionDialogState_0040ded0_Product* state;

    horizontal_base_units =
        static_cast<unsigned short>(GetDialogBaseUnits());
    vertical_base_units = static_cast<unsigned short>(
        GetDialogBaseUnits() >> 16);

    OtScaleWindowToDialogCoords_00401370_Product(
        GetParent(dialog),
        dialog,
        horizontal_base_units,
        vertical_base_units);
    GetWindowRect(dialog, &dialog_rect);

    if (OtLoadSavedDialogPlacement_00401110_RealCpp(
            kTradeSelectionDialogPlacementKey_0040ded0,
            &saved_rect) == 0) {
        OtScaleWindowToDialogCoords_00401370_Product(
            GetParent(dialog),
            dialog,
            horizontal_base_units,
            vertical_base_units);
        GetWindowRect(dialog, &dialog_rect);
        GetClientRect(GetParent(dialog), &parent_rect);
        parent_center.x = parent_rect.left +
            (parent_rect.right - parent_rect.left) / 2;
        parent_center.y = parent_rect.top +
            (parent_rect.bottom - parent_rect.top) / 2;
        ClientToScreen(GetParent(dialog), &parent_center);
        SetWindowPos(
            dialog,
            0,
            parent_center.x +
                (dialog_rect.left - dialog_rect.right) / 2,
            parent_center.y +
                (dialog_rect.top - dialog_rect.bottom) / 2,
            dialog_rect.right - dialog_rect.left,
            dialog_rect.bottom - dialog_rect.top,
            4);
    } else {
        SetWindowPos(
            dialog,
            0,
            saved_rect.left,
            saved_rect.top,
            dialog_rect.right - dialog_rect.left,
            dialog_rect.bottom - dialog_rect.top,
            4);
    }

    for (item = 0x64dc; item <= 0x64f0; ++item) {
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog,
            item,
            horizontal_base_units,
            vertical_base_units);
    }
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog,
        0x12d,
        horizontal_base_units,
        vertical_base_units);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog,
        0x12c,
        horizontal_base_units,
        vertical_base_units);

    memset(text, 0, sizeof(text));
    LoadStringA(
        g_applicationModule_00405a40_20260603,
        0x385,
        text,
        sizeof(text));
    SetWindowTextA(GetDlgItem(dialog, 0x64e1), text);

    memset(text, 0, sizeof(text));
    _itoa(
        static_cast<TradeJourneyInventoryView_0040e350_Product*>(
            g_journeyState)->oxen,
        text,
        10);
    SetWindowTextA(GetDlgItem(dialog, 0x64ef), text);

    memset(text, 0, sizeof(text));
    LoadStringA(
        g_applicationModule_00405a40_20260603,
        0x387,
        text,
        sizeof(text));
    SetWindowTextA(GetDlgItem(dialog, 0x64e2), text);

    memset(text, 0, sizeof(text));
    _itoa(
        static_cast<TradeJourneyInventoryView_0040e350_Product*>(
            g_journeyState)->food,
        text,
        10);
    SetWindowTextA(GetDlgItem(dialog, 0x64e9), text);

    memset(text, 0, sizeof(text));
    LoadStringA(
        g_applicationModule_00405a40_20260603,
        0x389,
        text,
        sizeof(text));
    CharLowerA(text);
    SetWindowTextA(GetDlgItem(dialog, 0x64e3), text);

    memset(text, 0, sizeof(text));
    _itoa(
        static_cast<TradeJourneyInventoryView_0040e350_Product*>(
            g_journeyState)->clothing,
        text,
        10);
    SetWindowTextA(GetDlgItem(dialog, 0x64ea), text);

    memset(text, 0, sizeof(text));
    LoadStringA(
        g_applicationModule_00405a40_20260603,
        0x38b,
        text,
        sizeof(text));
    SetWindowTextA(GetDlgItem(dialog, 0x64e4), text);

    memset(text, 0, sizeof(text));
    _itoa(
        static_cast<TradeJourneyInventoryView_0040e350_Product*>(
            g_journeyState)->ammunition,
        text,
        10);
    SetWindowTextA(GetDlgItem(dialog, 0x64eb), text);

    memset(text, 0, sizeof(text));
    LoadStringA(
        g_applicationModule_00405a40_20260603,
        0x38d,
        text,
        sizeof(text));
    SetWindowTextA(GetDlgItem(dialog, 0x64e5), text);

    memset(text, 0, sizeof(text));
    _itoa(
        static_cast<TradeJourneyInventoryView_0040e350_Product*>(
            g_journeyState)->wagon_wheels,
        text,
        10);
    SetWindowTextA(GetDlgItem(dialog, 0x64ec), text);

    memset(text, 0, sizeof(text));
    LoadStringA(
        g_applicationModule_00405a40_20260603,
        0x38f,
        text,
        sizeof(text));
    SetWindowTextA(GetDlgItem(dialog, 0x64e6), text);

    memset(text, 0, sizeof(text));
    _itoa(
        static_cast<TradeJourneyInventoryView_0040e350_Product*>(
            g_journeyState)->wagon_axles,
        text,
        10);
    SetWindowTextA(GetDlgItem(dialog, 0x64ed), text);

    LoadStringA(
        g_applicationModule_00405a40_20260603,
        0x391,
        text,
        sizeof(text));
    SetWindowTextA(GetDlgItem(dialog, 0x64e7), text);

    memset(text, 0, sizeof(text));
    _itoa(
        static_cast<short>(
            static_cast<TradeJourneyInventoryView_0040e350_Product*>(
                g_journeyState)->wagon_tongues +
            static_cast<TradeJourneyInventoryView_0040e350_Product*>(
                g_journeyState)->spare_parts),
        text,
        10);
    SetWindowTextA(GetDlgItem(dialog, 0x64ee), text);

    strcpy(text, kTradeSelectionMoneyLabel_0040e350);
    SetWindowTextA(GetDlgItem(dialog, 0x64e8), text);

    memset(text, 0, sizeof(text));
    _itoa(
        static_cast<TradeJourneyInventoryView_0040e350_Product*>(
            g_journeyState)->cash_cents / 100,
        text,
        10);
    SetWindowTextA(GetDlgItem(dialog, 0x64f0), text);

    if (g_lastSelectedTradeItem_Product_0043995c > -1 &&
        g_lastSelectedTradeItem_Product_0043995c < 8) {
        SendMessageA(
            GetDlgItem(
                dialog,
                g_lastSelectedTradeItem_Product_0043995c + 0x64e1),
            0xf1,
            1,
            0);
    }
    PostMessageA(GetDlgItem(dialog, 0x64dd), 0xc5, 4, 0);

    state = new TradeSelectionDialogState_0040ded0_Product;
    if (state == 0) {
        MessageBoxA(
            GetParent(dialog),
            kTradeSelectionAllocationFailure_0040e350,
            kTradeSelectionProcedureName_0040e350,
            0);
        PostQuitMessage(0);
        return;
    }

    state->okay_default.
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603,
            0x2826);
    state->okay_pressed.
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603,
            0x2827);
    state->cancel_default.
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603,
            0x2828);
    state->cancel_pressed.
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603,
            0x2829);
    state->accepted_result = accepted_result;
    SetWindowLongA(dialog, 8, reinterpret_cast<long>(state));
    OtResizeControl_RealCpp(
        dialog,
        0x12c,
        state->okay_default.width,
        state->okay_default.height);
    OtResizeControl_RealCpp(
        dialog,
        0x12d,
        state->cancel_default.width,
        state->cancel_default.height);
    SetFocus(GetDlgItem(dialog, 0x64dd));
    SendMessageA(dialog, 0x401, 0x12c, 0);
}

#pragma code_seg()
#pragma optimize("", on)

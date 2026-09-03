// Product-semantic recovery of OtTradeOfferDialogProc @ 0x0040d580.
//
// The modal callback owns the trade-offer backdrop, the randomly selected
// offered-item image, and the six normal/pressed button images.  It preserves
// the dialog placement, exposes the caller-owned acceptance result through the
// dialog state, and commits an accepted trade before closing.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This Product source must be compiled with 32-bit Microsoft C++."
#endif

#include "../graphics/positioned_bitmap_descriptor_state.h"

typedef void* OtTradeOfferHandle_0040d580;

struct OtTradeOfferRect_0040d580 {
    long left;
    long top;
    long right;
    long bottom;
};

struct OtTradeOfferPoint_0040d580 {
    long x;
    long y;
};

struct OtTradeOfferPaintStruct_0040d580 {
    char bytes[0x40];
};

struct OtTradeOfferDrawItem_0040d580 {
    unsigned int control_type;
    unsigned int control_id;
    unsigned int item_id;
    unsigned int item_action;
    unsigned int item_state;
    OtTradeOfferHandle_0040d580 item_window;
    OtTradeOfferHandle_0040d580 dc;
    OtTradeOfferRect_0040d580 item_rect;
    unsigned long item_data;
};

extern "C" __declspec(dllimport) OtTradeOfferHandle_0040d580 __stdcall
BeginPaint(
    OtTradeOfferHandle_0040d580 window,
    OtTradeOfferPaintStruct_0040d580* paint);
extern "C" __declspec(dllimport) int __stdcall EndPaint(
    OtTradeOfferHandle_0040d580 window,
    const OtTradeOfferPaintStruct_0040d580* paint);
extern "C" __declspec(dllimport) OtTradeOfferHandle_0040d580 __stdcall
SelectPalette(
    OtTradeOfferHandle_0040d580 dc,
    OtTradeOfferHandle_0040d580 palette,
    int force_background);
extern "C" __declspec(dllimport) unsigned int __stdcall RealizePalette(
    OtTradeOfferHandle_0040d580 dc);
extern "C" __declspec(dllimport) OtTradeOfferHandle_0040d580 __stdcall
LoadCursorA(
    OtTradeOfferHandle_0040d580 instance,
    const void* cursor_name);
extern "C" __declspec(dllimport) OtTradeOfferHandle_0040d580 __stdcall
SetCursor(OtTradeOfferHandle_0040d580 cursor);
extern "C" __declspec(dllimport) int __stdcall GetUpdateRect(
    OtTradeOfferHandle_0040d580 window,
    OtTradeOfferRect_0040d580* rect,
    int erase);
extern "C" __declspec(dllimport) int __stdcall FillRect(
    OtTradeOfferHandle_0040d580 dc,
    const OtTradeOfferRect_0040d580* rect,
    OtTradeOfferHandle_0040d580 brush);
extern "C" __declspec(dllimport) long __stdcall GetWindowLongA(
    OtTradeOfferHandle_0040d580 window,
    int index);
extern "C" __declspec(dllimport) long __stdcall SetWindowLongA(
    OtTradeOfferHandle_0040d580 window,
    int index,
    long value);
extern "C" __declspec(dllimport) int __stdcall GetWindowRect(
    OtTradeOfferHandle_0040d580 window,
    OtTradeOfferRect_0040d580* rect);
extern "C" __declspec(dllimport) int __stdcall GetClientRect(
    OtTradeOfferHandle_0040d580 window,
    OtTradeOfferRect_0040d580* rect);
extern "C" __declspec(dllimport) OtTradeOfferHandle_0040d580 __stdcall
GetParent(OtTradeOfferHandle_0040d580 window);
extern "C" __declspec(dllimport) int __stdcall ClientToScreen(
    OtTradeOfferHandle_0040d580 window,
    OtTradeOfferPoint_0040d580* point);
extern "C" __declspec(dllimport) int __stdcall SetWindowPos(
    OtTradeOfferHandle_0040d580 window,
    OtTradeOfferHandle_0040d580 insert_after,
    int x,
    int y,
    int width,
    int height,
    unsigned int flags);
extern "C" __declspec(dllimport) unsigned int __stdcall GetDialogBaseUnits();
extern "C" __declspec(dllimport) OtTradeOfferHandle_0040d580 __stdcall
GetDlgItem(
    OtTradeOfferHandle_0040d580 dialog,
    int control_id);
extern "C" __declspec(dllimport) int __stdcall SetWindowTextA(
    OtTradeOfferHandle_0040d580 window,
    const char* text);
extern "C" __declspec(dllimport) int __stdcall ShowWindow(
    OtTradeOfferHandle_0040d580 window,
    int command_show);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    OtTradeOfferHandle_0040d580 window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    OtTradeOfferHandle_0040d580 owner,
    const char* text,
    const char* caption,
    unsigned int type);
extern "C" __declspec(dllimport) void __stdcall PostQuitMessage(
    int exit_code);
extern "C" __declspec(dllimport) int __stdcall EndDialog(
    OtTradeOfferHandle_0040d580 dialog,
    int result);
extern "C" __declspec(dllimport) int __stdcall SetBkMode(
    OtTradeOfferHandle_0040d580 dc,
    int mode);
extern "C" __declspec(dllimport) unsigned long __stdcall SetTextColor(
    OtTradeOfferHandle_0040d580 dc,
    unsigned long color);
extern "C" __declspec(dllimport) OtTradeOfferHandle_0040d580 __stdcall
SelectObject(
    OtTradeOfferHandle_0040d580 dc,
    OtTradeOfferHandle_0040d580 object);

#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "user32.lib")

extern void* __cdecl operator new(unsigned int bytes);
extern void __cdecl operator delete(void* block);

extern "C" void __cdecl OtScaleWindowToDialogCoords_00401370_Product(
    OtTradeOfferHandle_0040d580 parent,
    OtTradeOfferHandle_0040d580 child,
    int horizontal_base_units,
    int vertical_base_units);
extern "C" int __cdecl OtLoadSavedDialogPlacement_00401110_RealCpp(
    const char* section,
    OtTradeOfferRect_0040d580* persisted_rect);
extern "C" void __cdecl
OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
    OtTradeOfferHandle_0040d580 dialog,
    int control_id,
    int horizontal_base_units,
    int vertical_base_units);
extern "C" void __cdecl OtPersistDialogPlacement_00401430_RealCpp(
    const char* section,
    const OtTradeOfferRect_0040d580* rect);
extern "C" void __cdecl OtResizeControl_RealCpp(
    OtTradeOfferHandle_0040d580 dialog,
    int control_id,
    int width,
    int height);
extern "C" int __cdecl OtSelectDialogCursor_0040d530_RealCpp(
    int busy,
    OtTradeOfferHandle_0040d580 window);
extern "C" int __cdecl OtChooseRandomTradeItemStringId_RealCpp();
extern "C" const char* __cdecl OtGetTradeOfferPromptText_RealCpp();
extern "C" void __cdecl OtCommitAcceptedTradeOffer_00027d70_RealCpp();

extern "C" OtTradeOfferHandle_0040d580
    g_applicationModule_00405a40_20260603;
extern "C" OtTradeOfferHandle_0040d580 g_resourceModule;
extern "C" OtTradeOfferHandle_0040d580 g_gamePalette;
extern "C" OtTradeOfferHandle_0040d580
    g_sharedDialogBackgroundBrush_004390c0;
extern "C" OtTradeOfferHandle_0040d580
    g_dialogFont_004390d8_00405320;
extern "C" int g_appBusyCursorActive_Product_004034d0;

#pragma pack(push, 1)
struct PositionedBitmap_0040b7b0_Semantic {
    char bytes[0x28];

    int OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        OtTradeOfferHandle_0040d580 dc,
        int source_x,
        int source_y);
};

struct TradeOfferDialogState_0040d580_Product {
    PositionedBitmapDescriptorState_0040ba40 dialog_backdrop;
    PositionedBitmapDescriptorState_0040ba40 offered_item;
    int* accepted_result;
    PositionedBitmapDescriptorState_0040ba40 yes_default;
    PositionedBitmapDescriptorState_0040ba40 yes_pressed;
    PositionedBitmapDescriptorState_0040ba40 no_default;
    PositionedBitmapDescriptorState_0040ba40 no_pressed;
    PositionedBitmapDescriptorState_0040ba40 okay_default;
    PositionedBitmapDescriptorState_0040ba40 okay_pressed;

    TradeOfferDialogState_0040d580_Product();
};
#pragma pack(pop)

typedef char OtTradeOfferBitmapSizeMustBe028_0040d580[
    sizeof(PositionedBitmapDescriptorState_0040ba40) == 0x28 ? 1 : -1];
typedef char OtTradeOfferItemOffsetMustBe028_0040d580[
    (unsigned int)&(((TradeOfferDialogState_0040d580_Product*)0)->
        offered_item) == 0x028
        ? 1
        : -1];
typedef char OtTradeOfferResultOffsetMustBe050_0040d580[
    (unsigned int)&(((TradeOfferDialogState_0040d580_Product*)0)->
        accepted_result) == 0x050
        ? 1
        : -1];
typedef char OtTradeOfferYesOffsetMustBe054_0040d580[
    (unsigned int)&(((TradeOfferDialogState_0040d580_Product*)0)->
        yes_default) == 0x054
        ? 1
        : -1];
typedef char OtTradeOfferNoOffsetMustBe0a4_0040d580[
    (unsigned int)&(((TradeOfferDialogState_0040d580_Product*)0)->
        no_default) == 0x0a4
        ? 1
        : -1];
typedef char OtTradeOfferOkayOffsetMustBe0f4_0040d580[
    (unsigned int)&(((TradeOfferDialogState_0040d580_Product*)0)->
        okay_default) == 0x0f4
        ? 1
        : -1];
typedef char OtTradeOfferStateSizeMustBe144_0040d580[
    sizeof(TradeOfferDialogState_0040d580_Product) == 0x144 ? 1 : -1];

static const char kTradeOfferDialogPlacementKey_0040d580[] =
    "Trade Dialog";
static const char kTradeOfferAllocationFailure_0040d580[] =
    "Can't allocate local memory";
static const char kTradeOfferProcedureName_0040d580[] =
    "TradeDudeDlgProc";

#pragma optimize("s", off)
#pragma optimize("t", on)
#pragma code_seg(".otsem")

extern "C" long __stdcall OtTradeOfferDialogProc_0040d580_ProductWip(
    OtTradeOfferHandle_0040d580 dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam)
{
    OtTradeOfferPaintStruct_0040d580 paint;
    OtTradeOfferRect_0040d580 update_rect;
    OtTradeOfferRect_0040d580 saved_rect;
    OtTradeOfferRect_0040d580 parent_rect;
    OtTradeOfferPoint_0040d580 parent_center;
    OtTradeOfferRect_0040d580 dialog_rect;
    TradeOfferDialogState_0040d580_Product* state;

    switch (message) {
    case 0x0002: { // WM_DESTROY
        state = reinterpret_cast<TradeOfferDialogState_0040d580_Product*>(
            GetWindowLongA(dialog, 8));
        GetWindowRect(dialog, &dialog_rect);
        OtPersistDialogPlacement_00401430_RealCpp(
            kTradeOfferDialogPlacementKey_0040d580,
            &dialog_rect);
        if (state != 0) {
            delete state;
        }
        return 1;
    }

    case 0x000f: { // WM_PAINT
        OtTradeOfferHandle_0040d580 dc;

        g_appBusyCursorActive_Product_004034d0 = 1;
        SetCursor(LoadCursorA(
            0,
            reinterpret_cast<const void*>(0x7f02)));

        dc = BeginPaint(dialog, &paint);
        SelectPalette(dc, g_gamePalette, 0);
        RealizePalette(dc);
        state = reinterpret_cast<TradeOfferDialogState_0040d580_Product*>(
            GetWindowLongA(dialog, 8));
        reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
            &state->offered_item)->
                OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
            &state->dialog_backdrop)->
                OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        EndPaint(dialog, &paint);

        g_appBusyCursorActive_Product_004034d0 = 0;
        SetCursor(LoadCursorA(
            0,
            reinterpret_cast<const void*>(0x7f00)));
        return 1;
    }

    case 0x0014: { // WM_ERASEBKGND
        OtTradeOfferHandle_0040d580 dc;

        dc = reinterpret_cast<OtTradeOfferHandle_0040d580>(wparam);
        SelectPalette(dc, g_gamePalette, 0);
        RealizePalette(dc);
        if (GetUpdateRect(dialog, &update_rect, 0) != 0) {
            FillRect(
                dc,
                &update_rect,
                g_sharedDialogBackgroundBrush_004390c0);
        }
        return 1;
    }

    case 0x0020: // WM_SETCURSOR
        return OtSelectDialogCursor_0040d530_RealCpp(
            g_appBusyCursorActive_Product_004034d0,
            reinterpret_cast<OtTradeOfferHandle_0040d580>(wparam));

    case 0x002b: { // WM_DRAWITEM
        OtTradeOfferDrawItem_0040d580* draw_item;

        state = reinterpret_cast<TradeOfferDialogState_0040d580_Product*>(
            GetWindowLongA(dialog, 8));
        draw_item = reinterpret_cast<OtTradeOfferDrawItem_0040d580*>(lparam);
        RealizePalette(draw_item->dc);
        SelectPalette(draw_item->dc, g_gamePalette, 0);

        if (draw_item->item_action == 1) {
            goto trade_offer_draw_default_action;
        }
        if (draw_item->item_action == 2) {
            goto trade_offer_draw_pressed_action;
        }
        return 1;

    trade_offer_draw_default_action:
        switch (wparam) {
        case 0x12c:
            reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                &state->okay_default)->
                    OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw_item->dc, 0, 0);
            return 1;
        case 0x134:
            reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                &state->yes_default)->
                    OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw_item->dc, 0, 0);
            return 1;
        case 0x135:
            reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                &state->no_default)->
                    OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw_item->dc, 0, 0);
            return 1;
        }
        return 1;

    trade_offer_draw_pressed_action:
        if ((draw_item->item_state & 1) != 0) {
            switch (wparam) {
            case 0x12c:
                reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                    &state->okay_pressed)->
                        OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                            draw_item->dc, 0, 0);
                return 1;
            case 0x134:
                reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                    &state->yes_pressed)->
                        OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                            draw_item->dc, 0, 0);
                return 1;
            case 0x135:
                reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                    &state->no_pressed)->
                        OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                            draw_item->dc, 0, 0);
                return 1;
            }
            return 1;
        }

        switch (wparam) {
        case 0x12c:
            reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                &state->okay_default)->
                    OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw_item->dc, 0, 0);
            return 1;
        case 0x134:
            reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                &state->yes_default)->
                    OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw_item->dc, 0, 0);
            return 1;
        case 0x135:
            reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                &state->no_default)->
                    OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw_item->dc, 0, 0);
            return 1;
        }
        return 1;
    }

    case 0x0110: { // WM_INITDIALOG
        unsigned int horizontal_base_units;
        unsigned int vertical_base_units;
        int dialog_width;
        int dialog_height;
        int* accepted_result;

        g_appBusyCursorActive_Product_004034d0 = 1;
        SetCursor(LoadCursorA(
            0,
            reinterpret_cast<const void*>(0x7f02)));

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
                kTradeOfferDialogPlacementKey_0040d580,
                &saved_rect) == 0) {
            GetClientRect(GetParent(dialog), &parent_rect);
            parent_center.x = parent_rect.left +
                (parent_rect.right - parent_rect.left) / 2;
            parent_center.y = parent_rect.top +
                (parent_rect.bottom - parent_rect.top) / 2;
            ClientToScreen(GetParent(dialog), &parent_center);
            dialog_height = dialog_rect.bottom - dialog_rect.top;
            dialog_width = dialog_rect.right - dialog_rect.left;
            saved_rect.top = parent_center.y +
                (dialog_rect.top - dialog_rect.bottom) / 2;
            saved_rect.left = parent_center.x +
                (dialog_rect.left - dialog_rect.right) / 2;
        } else {
            dialog_height = dialog_rect.bottom - dialog_rect.top;
            dialog_width = dialog_rect.right - dialog_rect.left;
        }
        SetWindowPos(
            dialog,
            0,
            saved_rect.left,
            saved_rect.top,
            dialog_width,
            dialog_height,
            4);

        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog, 0x64fa, horizontal_base_units, vertical_base_units);
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog, 0x134, horizontal_base_units, vertical_base_units);
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog, 0x135, horizontal_base_units, vertical_base_units);
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog, 0x12c, horizontal_base_units, vertical_base_units);

        SetWindowTextA(
            GetDlgItem(dialog, 0x64fa),
            OtGetTradeOfferPromptText_RealCpp());

        state = new TradeOfferDialogState_0040d580_Product;
        if (state == 0) {
            MessageBoxA(
                GetParent(dialog),
                kTradeOfferAllocationFailure_0040d580,
                kTradeOfferProcedureName_0040d580,
                0);
            PostQuitMessage(0);
            return 0;
        }

        state->dialog_backdrop.
            OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                g_resourceModule,
                0x1272);
        state->offered_item.
            OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                g_resourceModule,
                0x1271);
        state->offered_item.
            OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
                g_resourceModule,
                static_cast<unsigned short>(
                    OtChooseRandomTradeItemStringId_RealCpp()),
                0,
                0,
                0,
                0);

        accepted_result = reinterpret_cast<int*>(lparam);
        state->accepted_result = accepted_result;
        if (*accepted_result == 0) {
            ShowWindow(GetDlgItem(dialog, 0x134), 0);
            ShowWindow(GetDlgItem(dialog, 0x135), 0);
            ShowWindow(GetDlgItem(dialog, 0x12c), 5);
            SendMessageA(dialog, 0x401, 0x12c, 0);
        } else {
            ShowWindow(GetDlgItem(dialog, 0x134), 5);
            ShowWindow(GetDlgItem(dialog, 0x135), 5);
            ShowWindow(GetDlgItem(dialog, 0x12c), 0);
        }

        state->yes_default.
            OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                g_applicationModule_00405a40_20260603,
                0x2849);
        state->yes_pressed.
            OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                g_applicationModule_00405a40_20260603,
                0x284a);
        state->no_default.
            OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                g_applicationModule_00405a40_20260603,
                0x284b);
        state->no_pressed.
            OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                g_applicationModule_00405a40_20260603,
                0x284c);
        state->okay_default.
            OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                g_applicationModule_00405a40_20260603,
                0x2826);
        state->okay_pressed.
            OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                g_applicationModule_00405a40_20260603,
                0x2827);

        SetWindowLongA(dialog, 8, reinterpret_cast<long>(state));
        OtResizeControl_RealCpp(
            dialog,
            0x134,
            state->yes_default.width,
            state->yes_default.height);
        OtResizeControl_RealCpp(
            dialog,
            0x135,
            state->no_default.width,
            state->no_default.height);
        OtResizeControl_RealCpp(
            dialog,
            0x12c,
            state->okay_default.width,
            state->okay_default.height);
        return 0;
    }

    case 0x0111: { // WM_COMMAND
        unsigned int command;

        state = reinterpret_cast<TradeOfferDialogState_0040d580_Product*>(
            GetWindowLongA(dialog, 8));
        command = wparam & 0xffff;
        switch (command) {
        case 0x12c:
        case 0x135:
            *state->accepted_result = 0;
            EndDialog(dialog, 1);
            break;
        case 0x134:
            OtCommitAcceptedTradeOffer_00027d70_RealCpp();
            *state->accepted_result = 1;
            EndDialog(dialog, 1);
            break;
        }
        return 1;
    }

    case 0x0138: { // WM_CTLCOLORSTATIC
        OtTradeOfferHandle_0040d580 dc;

        dc = reinterpret_cast<OtTradeOfferHandle_0040d580>(wparam);
        SelectPalette(dc, g_gamePalette, 0);
        RealizePalette(dc);
        SetBkMode(dc, 1);
        SetTextColor(dc, 0);
        SelectObject(dc, g_dialogFont_004390d8_00405320);
        return reinterpret_cast<long>(
            g_sharedDialogBackgroundBrush_004390c0);
    }

    default:
        return 0;
    }
}

#pragma code_seg()
#pragma optimize("", on)

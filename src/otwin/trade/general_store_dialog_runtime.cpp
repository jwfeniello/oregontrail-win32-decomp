// Product-semantic recovery of OtGeneralStoreDialogProc @ 0x00407340.
//
// The modeless General Store callback owns the dialog's seven positioned
// bitmaps and the adjustment list used to commit a purchase.  It paints the
// store surface, dispatches the three owner-drawn buttons, validates Buy,
// launches the store-information child dialog, and forwards application
// lifecycle messages to that child while it is open.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This Product source must be compiled with 32-bit Microsoft C++."
#endif

#include <stddef.h>

#include "general_store_dialog_state.h"
#include "trade_adjustment_list.h"

typedef void* OtGeneralStoreHandle_00407340;

struct OtGeneralStoreRect_00407340 {
    long left;
    long top;
    long right;
    long bottom;
};

struct OtGeneralStorePaintStruct_00407340 {
    char bytes[0x40];
};

struct OtGeneralStoreDrawItem_00407340 {
    unsigned int control_type;
    unsigned int control_id;
    unsigned int item_id;
    unsigned int item_action;
    unsigned int item_state;
    OtGeneralStoreHandle_00407340 item_window;
    OtGeneralStoreHandle_00407340 dc;
    OtGeneralStoreRect_00407340 item_rect;
    unsigned long item_data;
};

typedef long (__stdcall *OtGeneralStoreDialogProc_00407340)(
    OtGeneralStoreHandle_00407340 dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam);

extern "C" __declspec(dllimport) OtGeneralStoreHandle_00407340 __stdcall
BeginPaint(
    OtGeneralStoreHandle_00407340 window,
    OtGeneralStorePaintStruct_00407340* paint);
extern "C" __declspec(dllimport) int __stdcall EndPaint(
    OtGeneralStoreHandle_00407340 window,
    const OtGeneralStorePaintStruct_00407340* paint);
extern "C" __declspec(dllimport) OtGeneralStoreHandle_00407340 __stdcall
LoadCursorA(
    OtGeneralStoreHandle_00407340 instance,
    const void* cursor_name);
extern "C" __declspec(dllimport) OtGeneralStoreHandle_00407340 __stdcall
SetCursor(OtGeneralStoreHandle_00407340 cursor);
extern "C" __declspec(dllimport) OtGeneralStoreHandle_00407340 __stdcall
SelectPalette(
    OtGeneralStoreHandle_00407340 dc,
    OtGeneralStoreHandle_00407340 palette,
    int force_background);
extern "C" __declspec(dllimport) int __stdcall UnrealizeObject(
    OtGeneralStoreHandle_00407340 object);
extern "C" __declspec(dllimport) unsigned int __stdcall RealizePalette(
    OtGeneralStoreHandle_00407340 dc);
extern "C" __declspec(dllimport) long __stdcall GetWindowLongA(
    OtGeneralStoreHandle_00407340 window,
    int index);
extern "C" __declspec(dllimport) int __stdcall FillRect(
    OtGeneralStoreHandle_00407340 dc,
    const OtGeneralStoreRect_00407340* rect,
    OtGeneralStoreHandle_00407340 brush);
extern "C" __declspec(dllimport) OtGeneralStoreHandle_00407340 __stdcall
RemovePropA(
    OtGeneralStoreHandle_00407340 window,
    const char* property_name);
extern "C" __declspec(dllimport) int __stdcall IsWindow(
    OtGeneralStoreHandle_00407340 window);
extern "C" __declspec(dllimport) int __stdcall DestroyWindow(
    OtGeneralStoreHandle_00407340 window);
extern "C" __declspec(dllimport) int __stdcall SetPropA(
    OtGeneralStoreHandle_00407340 window,
    const char* property_name,
    OtGeneralStoreHandle_00407340 value);
extern "C" __declspec(dllimport) OtGeneralStoreHandle_00407340 __stdcall
GetPropA(
    OtGeneralStoreHandle_00407340 window,
    const char* property_name);
extern "C" __declspec(dllimport) OtGeneralStoreHandle_00407340 __stdcall
GetParent(OtGeneralStoreHandle_00407340 window);
extern "C" __declspec(dllimport) int __stdcall PostMessageA(
    OtGeneralStoreHandle_00407340 window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) OtGeneralStoreHandle_00407340 __stdcall
CreateDialogParamA(
    OtGeneralStoreHandle_00407340 instance,
    const void* template_name,
    OtGeneralStoreHandle_00407340 parent,
    OtGeneralStoreDialogProc_00407340 dialog_proc,
    long init_parameter);
extern "C" __declspec(dllimport) OtGeneralStoreHandle_00407340 __stdcall
SetFocus(OtGeneralStoreHandle_00407340 window);
extern "C" __declspec(dllimport) int __stdcall SetBkMode(
    OtGeneralStoreHandle_00407340 dc,
    int mode);
extern "C" __declspec(dllimport) unsigned long __stdcall SetTextColor(
    OtGeneralStoreHandle_00407340 dc,
    unsigned long color);
extern "C" __declspec(dllimport) OtGeneralStoreHandle_00407340 __stdcall
SelectObject(
    OtGeneralStoreHandle_00407340 dc,
    OtGeneralStoreHandle_00407340 object);

#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "user32.lib")

extern void __cdecl operator delete(void* block);

extern "C" int __cdecl OtSelectDialogCursor_0040d530_RealCpp(
    int busy,
    OtGeneralStoreHandle_00407340 window);
extern "C" void __cdecl OtInitGeneralStoreDialog_00408ca0_ProductWip(
    OtGeneralStoreHandle_00407340 dialog,
    int init_parameter);
extern "C" int __cdecl
OtValidateAndCommitGeneralStorePurchase_00007fa0_Product(
    OtGeneralStoreHandle_00407340 dialog,
    void* command_source);
extern "C" void __cdecl
OtRecalculateGeneralStoreTotals_00409560_Product(
    OtGeneralStoreHandle_00407340 dialog);
extern "C" void __cdecl OtFilterNumericEditText_00401000_ProductWip(
    OtGeneralStoreHandle_00407340 dialog,
    unsigned int command);
extern "C" long __stdcall OtStoreExDialogProc_004096b0_ProductWip(
    OtGeneralStoreHandle_00407340 dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam);

extern "C" OtGeneralStoreHandle_00407340 g_resourceModule;
extern "C" OtGeneralStoreHandle_00407340 g_gamePalette;
extern "C" OtGeneralStoreHandle_00407340
    g_sharedDialogBackgroundBrush_004390c0;
extern "C" OtGeneralStoreHandle_00407340
    g_paletteWhiteBrush_004044f0;
extern "C" OtGeneralStoreHandle_00407340
    g_optionMenuFont_004390d4_00405320;
extern "C" OtGeneralStoreHandle_00407340
    g_dialogFont_004390d8_00405320;
extern "C" OtGeneralStoreHandle_00407340
    g_activeScreenDialogWindow_00404dd0;
extern "C" OtGeneralStoreHandle_00407340
    g_sharedModelessDialogWindow_004390cc;
extern "C" int g_appBusyCursorActive_Product_004034d0;
extern "C" const char g_generalStoreFirstVisitProperty_00439574[];

#pragma pack(push, 1)
struct PositionedBitmap_0040b7b0_Semantic {
    char bytes[0x28];

    int OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        OtGeneralStoreHandle_00407340 dc,
        int source_x,
        int source_y);
};

#pragma pack(pop)

typedef char OtGeneralStoreBitmapSizeMustBe028_00407340[
    sizeof(PositionedBitmapDescriptorState_0040ba40) == 0x28 ? 1 : -1];
typedef char OtGeneralStoreBackdropRectSizeMustBe010_00407340[
    sizeof(OtGeneralStoreRect_00407340) == 0x10 ? 1 : -1];
typedef char OtGeneralStoreInformationOffsetMustBe000_00407340[
    offsetof(GeneralStoreDialogState_00407340_Product,
        information_default) == 0x000 ? 1 : -1];
typedef char OtGeneralStoreInformationPressedOffsetMustBe028_00407340[
    offsetof(GeneralStoreDialogState_00407340_Product,
        information_pressed) == 0x028 ? 1 : -1];
typedef char OtGeneralStoreBuyOffsetMustBe050_00407340[
    offsetof(GeneralStoreDialogState_00407340_Product,
        buy_default) == 0x050 ? 1 : -1];
typedef char OtGeneralStoreLeaveOffsetMustBe0a0_00407340[
    offsetof(GeneralStoreDialogState_00407340_Product,
        leave_default) == 0x0a0 ? 1 : -1];
typedef char OtGeneralStoreBackdropOffsetMustBe0f0_00407340[
    offsetof(GeneralStoreDialogState_00407340_Product,
        dialog_backdrop) == 0x0f0 ? 1 : -1];
typedef char OtGeneralStoreFillRectOffsetMustBe118_00407340[
    offsetof(GeneralStoreDialogState_00407340_Product,
        backdrop_fill_rect) == 0x118 ? 1 : -1];
typedef char OtGeneralStoreStateSizeMustBe128_00407340[
    sizeof(GeneralStoreDialogState_00407340_Product) == 0x128 ? 1 : -1];
typedef char OtGeneralStoreAdjustmentSizeMustBe01a_00407340[
    sizeof(TradeAdjustmentList_00427d70) == 0x1a ? 1 : -1];
typedef char OtGeneralStoreDrawItemDcOffsetMustBe018_00407340[
    offsetof(OtGeneralStoreDrawItem_00407340, dc) == 0x18 ? 1 : -1];

// The validator owns the one canonical storage definition.  This callback
// owns the live object's allocation and lifetime.
extern "C" TradeAdjustmentList_00427d70*
    g_generalStorePurchaseAdjustments_00439570;

#pragma data_seg(".otdat")
extern "C" int g_generalStorePurchaseCommitted_004390f8 = 0;
extern "C" OtGeneralStoreDialogProc_00407340
    g_storeExtensionDialogProc_0043b59c = 0;
#pragma data_seg()

enum OtGeneralStoreMessage_00407340 {
    kStoreWmDestroy = 0x0002,
    kStoreWmPaint = 0x000f,
    kStoreWmEraseBackground = 0x0014,
    kStoreWmSetCursor = 0x0020,
    kStoreWmDrawItem = 0x002b,
    kStoreWmInitDialog = 0x0110,
    kStoreWmCommand = 0x0111,
    kStoreWmControlColor = 0x0133,
    kStoreWmControlColorStatic = 0x0138
};

enum OtGeneralStoreControl_00407340 {
    kStoreLeaveButton = 0x012d,
    kStoreInformationButton = 0x0131,
    kStoreBuyButton = 0x0139,
    kStoreFirstCaption = 0x05dc,
    kStoreItemCaptionFirst = 0x05f0,
    kStoreItemCaptionLast = 0x05f4,
    kStoreQuantityFirst = 0x0604,
    kStoreQuantityLast = 0x060a
};

#define OT_GENERAL_STORE_BLIT_00407340(bitmap, dc)                      \
    (reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(&(bitmap))-> \
        OtBlitWrappedPositionedBitmap_0040b7b0_Semantic((dc), 0, 0))

#pragma optimize("s", off)
#pragma optimize("t", on)
#pragma code_seg(".otsem")

extern "C" int __stdcall OtGeneralStoreDialogProc_00407340_ProductWip(
    OtGeneralStoreHandle_00407340 dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam)
{
    switch (message) {
    case kStoreWmDestroy: {
        GeneralStoreDialogState_00407340_Product* state;

        RemovePropA(dialog, g_generalStoreFirstVisitProperty_00439574);

        if (g_generalStorePurchaseAdjustments_00439570 != 0) {
            delete g_generalStorePurchaseAdjustments_00439570;
        }

        state = reinterpret_cast<GeneralStoreDialogState_00407340_Product*>(
            GetWindowLongA(dialog, 8));
        if (state != 0) {
            delete state;
        }

        if (IsWindow(g_sharedModelessDialogWindow_004390cc) != 0) {
            DestroyWindow(g_sharedModelessDialogWindow_004390cc);
        }
        return 1;
    }

    case kStoreWmPaint: {
        GeneralStoreDialogState_00407340_Product* state;
        OtGeneralStorePaintStruct_00407340 paint;
        OtGeneralStoreHandle_00407340 dc;

        g_appBusyCursorActive_Product_004034d0 = 1;
        SetCursor(LoadCursorA(
            0,
            reinterpret_cast<const void*>(0x7f02)));

        dc = BeginPaint(dialog, &paint);
        SelectPalette(dc, g_gamePalette, 0);
        UnrealizeObject(g_gamePalette);
        RealizePalette(dc);
        state = reinterpret_cast<GeneralStoreDialogState_00407340_Product*>(
            GetWindowLongA(dialog, 8));
        OT_GENERAL_STORE_BLIT_00407340(state->dialog_backdrop, dc);
        FillRect(
            dc,
            reinterpret_cast<const OtGeneralStoreRect_00407340*>(
                &state->backdrop_fill_rect),
            g_sharedDialogBackgroundBrush_004390c0);
        EndPaint(dialog, &paint);

        g_appBusyCursorActive_Product_004034d0 = 0;
        SetCursor(LoadCursorA(
            0,
            reinterpret_cast<const void*>(0x7f00)));
        return 0;
    }

    case kStoreWmEraseBackground:
        return 1;

    case kStoreWmSetCursor:
        return OtSelectDialogCursor_0040d530_RealCpp(
            g_appBusyCursorActive_Product_004034d0,
            reinterpret_cast<OtGeneralStoreHandle_00407340>(wparam));

    case kStoreWmDrawItem: {
        GeneralStoreDialogState_00407340_Product* state;
        OtGeneralStoreDrawItem_00407340* draw_item;

        draw_item = reinterpret_cast<OtGeneralStoreDrawItem_00407340*>(
            lparam);
        state = reinterpret_cast<GeneralStoreDialogState_00407340_Product*>(
            GetWindowLongA(dialog, 8));
        SelectPalette(draw_item->dc, g_gamePalette, 0);
        RealizePalette(draw_item->dc);

        switch (draw_item->item_action) {
        case 1:
            switch (wparam) {
            case kStoreLeaveButton:
                OT_GENERAL_STORE_BLIT_00407340(
                    state->leave_default, draw_item->dc);
                break;
            case kStoreInformationButton:
                OT_GENERAL_STORE_BLIT_00407340(
                    state->information_default, draw_item->dc);
                break;
            case kStoreBuyButton:
                OT_GENERAL_STORE_BLIT_00407340(
                    state->buy_default, draw_item->dc);
                break;
            }
            break;
        case 2:
            if ((draw_item->item_state & 1) != 0) {
                switch (wparam) {
                case kStoreLeaveButton:
                    OT_GENERAL_STORE_BLIT_00407340(
                        state->leave_pressed, draw_item->dc);
                    break;
                case kStoreInformationButton:
                    OT_GENERAL_STORE_BLIT_00407340(
                        state->information_pressed, draw_item->dc);
                    break;
                case kStoreBuyButton:
                    OT_GENERAL_STORE_BLIT_00407340(
                        state->buy_pressed, draw_item->dc);
                    break;
                }
            } else {
                switch (wparam) {
                case kStoreLeaveButton:
                    OT_GENERAL_STORE_BLIT_00407340(
                        state->leave_default, draw_item->dc);
                    break;
                case kStoreInformationButton:
                    OT_GENERAL_STORE_BLIT_00407340(
                        state->information_default, draw_item->dc);
                    break;
                case kStoreBuyButton:
                    OT_GENERAL_STORE_BLIT_00407340(
                        state->buy_default, draw_item->dc);
                    break;
                }
            }
            break;
        }
        return 1;
    }

    case kStoreWmInitDialog:
        g_appBusyCursorActive_Product_004034d0 = 1;
        SetCursor(LoadCursorA(
            0,
            reinterpret_cast<const void*>(0x7f02)));
        g_activeScreenDialogWindow_00404dd0 = dialog;
        OtInitGeneralStoreDialog_00408ca0_ProductWip(dialog, (int)lparam);
        SetPropA(
            dialog,
            g_generalStoreFirstVisitProperty_00439574,
            reinterpret_cast<OtGeneralStoreHandle_00407340>(lparam));
        g_generalStorePurchaseAdjustments_00439570 =
            new TradeAdjustmentList_00427d70;
        return 1;

    case kStoreWmCommand: {
        unsigned int command = wparam;
        unsigned short command_id = static_cast<unsigned short>(command);

        switch (command_id) {
        case kStoreLeaveButton: {
            if (GetPropA(
                    dialog,
                    g_generalStoreFirstVisitProperty_00439574) != 0) {
                PostMessageA(
                    GetParent(dialog),
                    0x046d,
                    0,
                    0);
            } else {
                PostMessageA(
                    GetParent(dialog),
                    0x0472,
                    0,
                    0);
            }
            DestroyWindow(dialog);
            g_activeScreenDialogWindow_00404dd0 = 0;
            return 1;
        }

        case kStoreInformationButton:
            g_storeExtensionDialogProc_0043b59c =
                OtStoreExDialogProc_004096b0_ProductWip;
            CreateDialogParamA(
                g_resourceModule,
                reinterpret_cast<const void*>(0x00e0),
                dialog,
                g_storeExtensionDialogProc_0043b59c,
                0);
            SetFocus(g_sharedModelessDialogWindow_004390cc);
            return 1;

        case kStoreBuyButton:
            if (OtValidateAndCommitGeneralStorePurchase_00007fa0_Product(
                    dialog,
                    reinterpret_cast<void*>(lparam)) != 0) {
                g_generalStorePurchaseCommitted_004390f8 = 1;
                PostMessageA(GetParent(dialog), 0x0472, 0, 0);
                DestroyWindow(dialog);
                g_activeScreenDialogWindow_00404dd0 = 0;
            }
            return 1;

        case kStoreQuantityFirst:
        case kStoreQuantityFirst + 1:
        case kStoreQuantityFirst + 2:
        case kStoreQuantityFirst + 3:
        case kStoreQuantityFirst + 4:
        case kStoreQuantityFirst + 5:
        case kStoreQuantityLast:
            switch (static_cast<unsigned short>(command >> 16)) {
            case 0x0300:
                OtRecalculateGeneralStoreTotals_00409560_Product(dialog);
                break;
            case 0x0400:
                OtFilterNumericEditText_00401000_ProductWip(
                    dialog, command);
                break;
            }
            return 0;

        default:
            return 0;
        }
    }

    case kStoreWmControlColor:
    case kStoreWmControlColorStatic: {
        OtGeneralStoreHandle_00407340 dc;
        int control_id;

        control_id = GetWindowLongA(
            reinterpret_cast<OtGeneralStoreHandle_00407340>(lparam),
            -12);
        dc = reinterpret_cast<OtGeneralStoreHandle_00407340>(wparam);
        SelectPalette(dc, g_gamePalette, 0);
        RealizePalette(dc);
        SetBkMode(dc, 1);
        SetTextColor(dc, 0);

        if (control_id >= kStoreQuantityFirst &&
            control_id <= kStoreQuantityLast) {
            return reinterpret_cast<long>(g_paletteWhiteBrush_004044f0);
        }

        if (control_id == kStoreFirstCaption ||
            control_id == kStoreItemCaptionFirst ||
            control_id == kStoreItemCaptionFirst + 1 ||
            control_id == kStoreItemCaptionFirst + 2 ||
            control_id == kStoreItemCaptionFirst + 3 ||
            control_id == kStoreItemCaptionLast) {
            SelectObject(dc, g_optionMenuFont_004390d4_00405320);
        } else {
            SelectObject(dc, g_dialogFont_004390d8_00405320);
        }
        return reinterpret_cast<long>(
            g_sharedDialogBackgroundBrush_004390c0);
    }

    case 0x0464:
    case 0x0465:
    case 0x0469:
        if (IsWindow(g_sharedModelessDialogWindow_004390cc) != 0) {
            PostMessageA(
                g_sharedModelessDialogWindow_004390cc,
                message,
                0,
                0);
        }
        return 1;

    default:
        return 0;
    }
}

#pragma code_seg()
#pragma optimize("", on)

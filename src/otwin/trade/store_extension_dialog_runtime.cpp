// Product-semantic recovery of OtStoreExDialogProc @ 0x004096b0.
//
// This modeless Store Extension dialog owns the six normal/pressed images for
// its narration controls and close button.  It also coordinates narration
// playback with the shared CD-media and wave-audio state.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This Product source must be compiled with 32-bit Microsoft C++."
#endif

#include "../graphics/positioned_bitmap_descriptor_state.h"

typedef void* OtStoreExtensionHandle_004096b0;

struct OtStoreExtensionRect_004096b0 {
    long left;
    long top;
    long right;
    long bottom;
};

struct OtStoreExtensionPoint_004096b0 {
    long x;
    long y;
};

struct OtStoreExtensionDrawItem_004096b0 {
    unsigned int control_type;
    unsigned int control_id;
    unsigned int item_id;
    unsigned int item_action;
    unsigned int item_state;
    OtStoreExtensionHandle_004096b0 item_window;
    OtStoreExtensionHandle_004096b0 dc;
    OtStoreExtensionRect_004096b0 item_rect;
    unsigned long item_data;
};

extern "C" __declspec(dllimport) OtStoreExtensionHandle_004096b0 __stdcall
LoadCursorA(
    OtStoreExtensionHandle_004096b0 instance,
    const void* cursor_name);
extern "C" __declspec(dllimport) OtStoreExtensionHandle_004096b0 __stdcall
SetCursor(OtStoreExtensionHandle_004096b0 cursor);
extern "C" __declspec(dllimport) OtStoreExtensionHandle_004096b0 __stdcall
SelectPalette(
    OtStoreExtensionHandle_004096b0 dc,
    OtStoreExtensionHandle_004096b0 palette,
    int force_background);
extern "C" __declspec(dllimport) int __stdcall UnrealizeObject(
    OtStoreExtensionHandle_004096b0 object);
extern "C" __declspec(dllimport) unsigned int __stdcall RealizePalette(
    OtStoreExtensionHandle_004096b0 dc);
extern "C" __declspec(dllimport) int __stdcall GetClientRect(
    OtStoreExtensionHandle_004096b0 window,
    OtStoreExtensionRect_004096b0* rect);
extern "C" __declspec(dllimport) int __stdcall FillRect(
    OtStoreExtensionHandle_004096b0 dc,
    const OtStoreExtensionRect_004096b0* rect,
    OtStoreExtensionHandle_004096b0 brush);
extern "C" __declspec(dllimport) long __stdcall GetWindowLongA(
    OtStoreExtensionHandle_004096b0 window,
    int index);
extern "C" __declspec(dllimport) unsigned int __stdcall GetDialogBaseUnits();
extern "C" __declspec(dllimport) OtStoreExtensionHandle_004096b0 __stdcall
GetParent(OtStoreExtensionHandle_004096b0 window);
extern "C" __declspec(dllimport) int __stdcall GetWindowRect(
    OtStoreExtensionHandle_004096b0 window,
    OtStoreExtensionRect_004096b0* rect);
extern "C" __declspec(dllimport) int __stdcall ClientToScreen(
    OtStoreExtensionHandle_004096b0 window,
    OtStoreExtensionPoint_004096b0* point);
extern "C" __declspec(dllimport) int __stdcall SetWindowPos(
    OtStoreExtensionHandle_004096b0 window,
    OtStoreExtensionHandle_004096b0 insert_after,
    int x,
    int y,
    int width,
    int height,
    unsigned int flags);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    OtStoreExtensionHandle_004096b0 owner,
    const char* text,
    const char* caption,
    unsigned int type);
extern "C" __declspec(dllimport) void __stdcall PostQuitMessage(int exit_code);
extern "C" __declspec(dllimport) long __stdcall SetWindowLongA(
    OtStoreExtensionHandle_004096b0 window,
    int index,
    long value);
extern "C" __declspec(dllimport) OtStoreExtensionHandle_004096b0 __stdcall
GetDlgItem(
    OtStoreExtensionHandle_004096b0 dialog,
    int control_id);
extern "C" __declspec(dllimport) OtStoreExtensionHandle_004096b0 __stdcall
SetFocus(OtStoreExtensionHandle_004096b0 window);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    OtStoreExtensionHandle_004096b0 window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall DestroyWindow(
    OtStoreExtensionHandle_004096b0 window);
extern "C" __declspec(dllimport) OtStoreExtensionHandle_004096b0 __stdcall
SelectObject(
    OtStoreExtensionHandle_004096b0 dc,
    OtStoreExtensionHandle_004096b0 object);
extern "C" __declspec(dllimport) int __stdcall SetBkMode(
    OtStoreExtensionHandle_004096b0 dc,
    int mode);
extern "C" __declspec(dllimport) unsigned long __stdcall SetTextColor(
    OtStoreExtensionHandle_004096b0 dc,
    unsigned long color);

#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "user32.lib")

extern void* __cdecl operator new(unsigned int bytes);
extern void __cdecl operator delete(void* block);

extern "C" void __cdecl OtScaleWindowToDialogCoords_00401370_Product(
    OtStoreExtensionHandle_004096b0 parent,
    OtStoreExtensionHandle_004096b0 child,
    int horizontal_base_units,
    int vertical_base_units);
extern "C" void __cdecl
OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
    OtStoreExtensionHandle_004096b0 dialog,
    int control_id,
    int horizontal_base_units,
    int vertical_base_units);
extern "C" void __cdecl OtResizeControl_RealCpp(
    OtStoreExtensionHandle_004096b0 dialog,
    int control_id,
    int width,
    int height);
extern "C" int __cdecl OtSelectDialogCursor_0040d530_RealCpp(
    int busy,
    OtStoreExtensionHandle_004096b0 window);
extern "C" void __cdecl OtCloseWaveAudioDevice_0040d0a0_RealCpp();
extern "C" void __cdecl OtOpenWaveAudioFile_0000d110_RealCpp(
    OtStoreExtensionHandle_004096b0 owner,
    const char* logical_name);
extern "C" void __cdecl OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();
extern "C" void __cdecl OtStopWaveAudioDirectImport_0040d480_RealCpp();

extern "C" OtStoreExtensionHandle_004096b0
    g_applicationModule_00405a40_20260603;
extern "C" OtStoreExtensionHandle_004096b0 g_gamePalette;
extern "C" OtStoreExtensionHandle_004096b0
    g_sharedDialogBackgroundBrush_004390c0;
extern "C" OtStoreExtensionHandle_004096b0
    g_sharedModelessDialogWindow_004390cc;
extern "C" OtStoreExtensionHandle_004096b0
    g_dialogFont_004390d8_00405320;
extern "C" int g_cdMediaMode_00439108;
extern "C" int g_appBusyCursorActive_Product_004034d0;
extern "C" int DAT_004390e8;

#pragma pack(push, 1)
struct PositionedBitmap_0040b7b0_Semantic {
    char bytes[0x28];

    int OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        OtStoreExtensionHandle_004096b0 dc,
        int source_x,
        int source_y);
};

// bitmap_0/1 are play normal/pressed, bitmap_2/3 are stop normal/pressed,
// and bitmap_4/5 are close normal/pressed.  The generic member names preserve
// the definition used by the already-matched Product constructor TU.
struct StoreExtensionDialogState_004096b0_Product {
    PositionedBitmapDescriptorState_0040ba40 bitmap_0;
    PositionedBitmapDescriptorState_0040ba40 bitmap_1;
    PositionedBitmapDescriptorState_0040ba40 bitmap_2;
    PositionedBitmapDescriptorState_0040ba40 bitmap_3;
    PositionedBitmapDescriptorState_0040ba40 bitmap_4;
    PositionedBitmapDescriptorState_0040ba40 bitmap_5;
};
#pragma pack(pop)

typedef char OtStoreExtensionBitmapSizeMustBe028_004096b0[
    sizeof(PositionedBitmapDescriptorState_0040ba40) == 0x28 ? 1 : -1];
typedef char OtStoreExtensionStopOffsetMustBe050_004096b0[
    (unsigned int)&(((StoreExtensionDialogState_004096b0_Product*)0)->
        bitmap_2) == 0x050
        ? 1
        : -1];
typedef char OtStoreExtensionCloseOffsetMustBe0a0_004096b0[
    (unsigned int)&(((StoreExtensionDialogState_004096b0_Product*)0)->
        bitmap_4) == 0x0a0
        ? 1
        : -1];
typedef char OtStoreExtensionStateSizeMustBe0f0_004096b0[
    sizeof(StoreExtensionDialogState_004096b0_Product) == 0x0f0 ? 1 : -1];

extern "C" const char g_welcomeAllocationMessage_00415d30[];
extern "C" const char g_storeExtensionNarrationWave_004395c4[] =
    "matthelp.wav";
extern "C" const char g_storeExtensionProcedureName_004395d4[] =
    "StoreExDlgProc";

#pragma optimize("s", off)
#pragma optimize("t", on)
#pragma code_seg(".otsem")

extern "C" long __stdcall OtStoreExDialogProc_004096b0_ProductWip(
    void* dialog_parameter,
    unsigned int message,
    unsigned int wparam,
    long lparam)
{
    OtStoreExtensionHandle_004096b0 dialog;
    OtStoreExtensionRect_004096b0 parent_rect;
    OtStoreExtensionPoint_004096b0 parent_center;
    OtStoreExtensionRect_004096b0 dialog_rect;
    StoreExtensionDialogState_004096b0_Product* state;

    dialog = dialog_parameter;

    switch (message) {
    case 0x0002: { // WM_DESTROY
        state = reinterpret_cast<StoreExtensionDialogState_004096b0_Product*>(
            GetWindowLongA(dialog, 8));
        if (state != 0) {
            delete state;
        }
        if (g_cdMediaMode_00439108 != 0 &&
            DAT_004390e8 != 0) {
            OtCloseWaveAudioDevice_0040d0a0_RealCpp();
        }
        return 1;
    }

    case 0x0014: { // WM_ERASEBKGND
        OtStoreExtensionHandle_004096b0 dc;

        g_appBusyCursorActive_Product_004034d0 = 1;
        SetCursor(LoadCursorA(
            0,
            reinterpret_cast<const void*>(0x7f02)));
        dc = reinterpret_cast<OtStoreExtensionHandle_004096b0>(wparam);
        SelectPalette(dc, g_gamePalette, 0);
        UnrealizeObject(g_gamePalette);
        RealizePalette(dc);
        GetClientRect(dialog, &dialog_rect);
        FillRect(
            dc,
            &dialog_rect,
            g_sharedDialogBackgroundBrush_004390c0);
        g_appBusyCursorActive_Product_004034d0 = 0;
        SetCursor(LoadCursorA(
            0,
            reinterpret_cast<const void*>(0x7f00)));
        return 1;
    }

    case 0x0020: // WM_SETCURSOR
        return OtSelectDialogCursor_0040d530_RealCpp(
            g_appBusyCursorActive_Product_004034d0,
            reinterpret_cast<OtStoreExtensionHandle_004096b0>(wparam));

    case 0x002b: { // WM_DRAWITEM
        OtStoreExtensionDrawItem_004096b0* draw_item;

        draw_item = reinterpret_cast<OtStoreExtensionDrawItem_004096b0*>(
            lparam);
        state = reinterpret_cast<StoreExtensionDialogState_004096b0_Product*>(
            GetWindowLongA(dialog, 8));
        SelectPalette(draw_item->dc, g_gamePalette, 0);
        RealizePalette(draw_item->dc);

        switch (draw_item->item_action) {
        case 1:
            if (wparam == 0x12c) {
                reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                    &state->bitmap_4)->
                        OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                            draw_item->dc, 0, 0);
            } else if (wparam == 0x132) {
                reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                    &state->bitmap_0)->
                        OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                            draw_item->dc, 0, 0);
            } else if (wparam == 0x133) {
                reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                    &state->bitmap_2)->
                        OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                            draw_item->dc, 0, 0);
            }
            break;

        case 2:
            if ((draw_item->item_state & 1) != 0) {
                if (wparam == 0x12c) {
                    reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                        &state->bitmap_5)->
                            OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                                draw_item->dc, 0, 0);
                }
                if (wparam == 0x132) {
                    reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                        &state->bitmap_1)->
                            OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                                draw_item->dc, 0, 0);
                }
                if (wparam == 0x133) {
                    reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                        &state->bitmap_3)->
                            OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                                draw_item->dc, 0, 0);
                }
            } else {
                if (wparam == 0x12c) {
                    reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                        &state->bitmap_4)->
                            OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                                draw_item->dc, 0, 0);
                }
                if (wparam == 0x132) {
                    reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                        &state->bitmap_0)->
                            OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                                draw_item->dc, 0, 0);
                }
                if (wparam == 0x133) {
                    reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                        &state->bitmap_2)->
                            OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                                draw_item->dc, 0, 0);
                }
            }
            break;
        }
        return 1;
    }

    case 0x0110: { // WM_INITDIALOG
        int horizontal_base_units;
        int vertical_base_units;

        g_appBusyCursorActive_Product_004034d0 = 1;
        SetCursor(LoadCursorA(
            0,
            reinterpret_cast<const void*>(0x7f02)));
        g_sharedModelessDialogWindow_004390cc = dialog;

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

        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog, 0x640, horizontal_base_units, vertical_base_units);
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog, 0x641, horizontal_base_units, vertical_base_units);
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog, 0x642, horizontal_base_units, vertical_base_units);
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog, 0x643, horizontal_base_units, vertical_base_units);
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog, 0x132, horizontal_base_units, vertical_base_units);
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog, 0x133, horizontal_base_units, vertical_base_units);
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog, 0x12c, horizontal_base_units, vertical_base_units);

        state = new StoreExtensionDialogState_004096b0_Product;
        if (state == 0) {
            MessageBoxA(
                GetParent(dialog),
                g_welcomeAllocationMessage_00415d30,
                g_storeExtensionProcedureName_004395d4,
                0);
            PostQuitMessage(0);
            return 0;
        }

        if (g_cdMediaMode_00439108 != 0) {
            state->bitmap_0.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603,
                    0x282c);
            state->bitmap_1.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603,
                    0x282d);
            state->bitmap_2.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603,
                    0x282e);
            state->bitmap_3.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603,
                    0x282f);
            OtResizeControl_RealCpp(
                dialog,
                0x132,
                state->bitmap_0.width,
                state->bitmap_0.height);
            OtResizeControl_RealCpp(
                dialog,
                0x133,
                state->bitmap_2.width,
                state->bitmap_2.height);
        }

        state->bitmap_4.
            OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                g_applicationModule_00405a40_20260603,
                0x2826);
        state->bitmap_5.
            OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                g_applicationModule_00405a40_20260603,
                0x2827);
        OtResizeControl_RealCpp(
            dialog,
            0x12c,
            state->bitmap_4.width,
            state->bitmap_4.height);

        SetWindowLongA(dialog, 8, reinterpret_cast<long>(state));
        SetFocus(GetDlgItem(dialog, 0x12c));
        SendMessageA(dialog, 0x401, 0x12c, 0);
        return 0;
    }

    case 0x0111: { // WM_COMMAND
        switch (static_cast<unsigned short>(wparam)) {
        case 0x12c:
            DestroyWindow(dialog);
            g_sharedModelessDialogWindow_004390cc = 0;
            break;

        case 0x132:
            if (DAT_004390e8 != 0) {
                OtOpenWaveAudioFile_0000d110_RealCpp(
                    dialog,
                    g_storeExtensionNarrationWave_004395c4);
                OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();
            }
            break;

        case 0x133:
            if (DAT_004390e8 != 0) {
                OtStopWaveAudioDirectImport_0040d480_RealCpp();
            }
            break;
        }
        return 1;
    }

    case 0x0138: { // WM_CTLCOLORSTATIC
        OtStoreExtensionHandle_004096b0 dc;

        dc = reinterpret_cast<OtStoreExtensionHandle_004096b0>(wparam);
        SelectPalette(dc, g_gamePalette, 0);
        RealizePalette(dc);
        SelectObject(dc, g_dialogFont_004390d8_00405320);
        SetBkMode(dc, 1);
        SetTextColor(dc, 0);
        return reinterpret_cast<long>(
            g_sharedDialogBackgroundBrush_004390c0);
    }

    case 0x0464:
    case 0x0465:
        if (g_cdMediaMode_00439108 != 0 &&
            DAT_004390e8 != 0) {
            OtStopWaveAudioDirectImport_0040d480_RealCpp();
        }
        return 1;

    case 0x0469:
        if (g_cdMediaMode_00439108 != 0) {
            OtStopWaveAudioDirectImport_0040d480_RealCpp();
        }
        return 1;

    default:
        return 0;
    }
}

#pragma code_seg()
#pragma optimize("", on)

// Product-reachable semantic recovery of OtTalkDialogProc @ 0x00421020.
// The source is intentionally monolithic: the original VC4 callback owns the
// message topology, positioned-bitmap construction/destruction unwind graph,
// and allocation cleanup funclet in one /GX translation unit. Exact source
// shaping remains WIP.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This Product source must be compiled with 32-bit Microsoft C++."
#endif

#include <string.h>

typedef void* OtTalkHandle_00421020;

struct OtTalkRect_00421020 {
    long left;
    long top;
    long right;
    long bottom;
};

struct OtTalkPoint_00421020 {
    long x;
    long y;
};

struct OtTalkPaintStruct_00421020 {
    char bytes[0x40];
};

struct OtTalkDrawItemStruct_00421020 {
    unsigned int control_type;
    unsigned int control_id;
    unsigned int item_id;
    unsigned int item_action;
    unsigned int item_state;
    OtTalkHandle_00421020 item_window;
    OtTalkHandle_00421020 dc;
    OtTalkRect_00421020 item_rect;
    unsigned long item_data;
};

extern "C" __declspec(dllimport) OtTalkHandle_00421020 __stdcall BeginPaint(
    OtTalkHandle_00421020 window,
    OtTalkPaintStruct_00421020* paint);
extern "C" __declspec(dllimport) int __stdcall EndPaint(
    OtTalkHandle_00421020 window,
    const OtTalkPaintStruct_00421020* paint);
extern "C" __declspec(dllimport) OtTalkHandle_00421020 __stdcall SelectPalette(
    OtTalkHandle_00421020 dc,
    OtTalkHandle_00421020 palette,
    int force_background);
extern "C" __declspec(dllimport) int __stdcall UnrealizeObject(
    OtTalkHandle_00421020 object);
extern "C" __declspec(dllimport) unsigned int __stdcall RealizePalette(
    OtTalkHandle_00421020 dc);
extern "C" __declspec(dllimport) OtTalkHandle_00421020 __stdcall LoadCursorA(
    OtTalkHandle_00421020 instance,
    const void* cursor_name);
extern "C" __declspec(dllimport) OtTalkHandle_00421020 __stdcall SetCursor(
    OtTalkHandle_00421020 cursor);
extern "C" __declspec(dllimport) int __stdcall GetUpdateRect(
    OtTalkHandle_00421020 window,
    OtTalkRect_00421020* rect,
    int erase);
extern "C" __declspec(dllimport) int __stdcall FillRect(
    OtTalkHandle_00421020 dc,
    const OtTalkRect_00421020* rect,
    OtTalkHandle_00421020 brush);
extern "C" __declspec(dllimport) unsigned int __stdcall GetDialogBaseUnits();
extern "C" __declspec(dllimport) OtTalkHandle_00421020 __stdcall GetParent(
    OtTalkHandle_00421020 window);
extern "C" __declspec(dllimport) int __stdcall GetWindowRect(
    OtTalkHandle_00421020 window,
    OtTalkRect_00421020* rect);
extern "C" __declspec(dllimport) int __stdcall GetClientRect(
    OtTalkHandle_00421020 window,
    OtTalkRect_00421020* rect);
extern "C" __declspec(dllimport) int __stdcall ClientToScreen(
    OtTalkHandle_00421020 window,
    OtTalkPoint_00421020* point);
extern "C" __declspec(dllimport) int __stdcall SetWindowPos(
    OtTalkHandle_00421020 window,
    OtTalkHandle_00421020 insert_after,
    int x,
    int y,
    int width,
    int height,
    unsigned int flags);
extern "C" __declspec(dllimport) long __stdcall GetWindowLongA(
    OtTalkHandle_00421020 window,
    int index);
extern "C" __declspec(dllimport) long __stdcall SetWindowLongA(
    OtTalkHandle_00421020 window,
    int index,
    long value);
extern "C" __declspec(dllimport) OtTalkHandle_00421020 __stdcall GetDlgItem(
    OtTalkHandle_00421020 dialog,
    int control_id);
extern "C" __declspec(dllimport) int __stdcall SetWindowTextA(
    OtTalkHandle_00421020 window,
    const char* text);
extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    OtTalkHandle_00421020 instance,
    unsigned int resource_id,
    char* text,
    int text_count);
extern "C" __declspec(dllimport) OtTalkHandle_00421020 __stdcall SetFocus(
    OtTalkHandle_00421020 window);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    OtTalkHandle_00421020 window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall EndDialog(
    OtTalkHandle_00421020 dialog,
    int result);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    OtTalkHandle_00421020 owner,
    const char* text,
    const char* caption,
    unsigned int type);
extern "C" __declspec(dllimport) void __stdcall PostQuitMessage(int exit_code);
extern "C" __declspec(dllimport) OtTalkHandle_00421020 __stdcall SelectObject(
    OtTalkHandle_00421020 dc,
    OtTalkHandle_00421020 object);
extern "C" __declspec(dllimport) int __stdcall SetBkMode(
    OtTalkHandle_00421020 dc,
    int mode);
extern "C" __declspec(dllimport) unsigned long __stdcall SetTextColor(
    OtTalkHandle_00421020 dc,
    unsigned long color);

#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "user32.lib")

extern "C" void __cdecl OtScaleWindowToDialogCoords_00401370_Product(
    OtTalkHandle_00421020 parent,
    OtTalkHandle_00421020 child,
    int horizontal_base_units,
    int vertical_base_units);
extern "C" int __cdecl OtLoadSavedDialogPlacement_00401110_RealCpp(
    const char* section,
    OtTalkRect_00421020* persisted_rect);
extern "C" void __cdecl
OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
    OtTalkHandle_00421020 dialog,
    int control_id,
    int horizontal_base_units,
    int vertical_base_units);
extern "C" void __cdecl OtPersistDialogPlacement_00401430_RealCpp(
    const char* section,
    const OtTalkRect_00421020* rect);
extern "C" void __cdecl OtResizeControl_RealCpp(
    OtTalkHandle_00421020 dialog,
    int control_id,
    int width,
    int height);
extern "C" int __cdecl OtSelectDialogCursor_0040d530_RealCpp(
    int busy,
    OtTalkHandle_00421020 window);
extern "C" void __cdecl OtCloseWaveAudioDevice_0040d0a0_RealCpp();
extern "C" void __cdecl OtOpenWaveAudioFile_0000d110_RealCpp(
    OtTalkHandle_00421020 owner,
    const char* logical_name);
extern "C" void __cdecl OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();
extern "C" void __cdecl OtStopWaveAudioDirectImport_0040d480_RealCpp();

extern "C" void* __fastcall OtInitPositionedBitmap_RealCpp(void* bitmap);

struct PositionedBitmapFree_0040b760_42pct {
    void OtFreePositionedBitmapAlt5_0040b760_42pct();
};

struct PositionedBitmap_0040b7b0_Semantic {
    int OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        OtTalkHandle_00421020 dc,
        int source_x,
        int source_y);
};

struct PositionedBitmapDescriptorState_0040ba40 {
    int OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
        OtTalkHandle_00421020 module,
        unsigned short bitmap_resource_id,
        short left,
        short top,
        short width,
        short height);
    int OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        OtTalkHandle_00421020 module,
        short descriptor_id);
};

extern void* __cdecl operator new(unsigned int bytes);
extern void __cdecl operator delete(void* block);

extern "C" OtTalkHandle_00421020
    g_applicationModule_00405a40_20260603;
extern "C" OtTalkHandle_00421020 g_resourceModule;
extern "C" OtTalkHandle_00421020 g_gamePalette;
extern "C" OtTalkHandle_00421020 g_sharedDialogBackgroundBrush_004390c0;
extern "C" OtTalkHandle_00421020 g_dialogFont_004390d8_00405320;
extern "C" OtTalkHandle_00421020 g_activeScreenDialogWindow_00404dd0;
extern "C" void* g_activeRouteDescriptor;
extern "C" int g_appBusyCursorActive_Product_004034d0;
extern "C" int g_cdMediaMode_00439108;
extern "C" int DAT_004390e8;

#pragma pack(push, 1)
struct TalkDialogPositionedBitmap_00421020 {
    unsigned long bitmap_info_handle;
    unsigned long indexed_pixels_handle;
    void* bitmap_info;
    void* indexed_pixels;
    short left;
    short top;
    short width;
    short height;
    int left_int;
    int top_int;
    int right;
    int bottom;

    TalkDialogPositionedBitmap_00421020()
    {
        OtInitPositionedBitmap_RealCpp(this);
    }

    ~TalkDialogPositionedBitmap_00421020()
    {
        reinterpret_cast<PositionedBitmapFree_0040b760_42pct*>(this)->
            OtFreePositionedBitmapAlt5_0040b760_42pct();
    }
};

// A distinct proposal-only type name keeps the currently accepted standalone
// constructor object linkable while the callback's own inline EH graph is
// validated.  The final promotion may unify the owner after re-anchoring the
// eight accepted cleanup rows.
struct TalkDialogRuntimeState_00421020 {
    TalkDialogPositionedBitmap_00421020 play_audio_up;
    TalkDialogPositionedBitmap_00421020 play_audio_down;
    TalkDialogPositionedBitmap_00421020 stop_audio_up;
    TalkDialogPositionedBitmap_00421020 stop_audio_down;
    TalkDialogPositionedBitmap_00421020 close_up;
    TalkDialogPositionedBitmap_00421020 close_down;
    TalkDialogPositionedBitmap_00421020 dialog_backdrop;
    TalkDialogPositionedBitmap_00421020 speaker_portrait;
    int talk_variant;

    TalkDialogRuntimeState_00421020()
    {
    }
};

struct TalkRouteDescriptor_00421020 {
    unsigned short route_id;
    char reserved_002[0x130];
    short talk_bitmap_resource_ids[3];
};
#pragma pack(pop)

typedef char OtTalkBitmapSizeMustBe028_00421020[
    sizeof(TalkDialogPositionedBitmap_00421020) == 0x28 ? 1 : -1];
typedef char OtTalkBackdropOffsetMustBe0f0_00421020[
    (unsigned int)&(((TalkDialogRuntimeState_00421020*)0)->dialog_backdrop) ==
            0x0f0
        ? 1
        : -1];
typedef char OtTalkPortraitOffsetMustBe118_00421020[
    (unsigned int)&(((TalkDialogRuntimeState_00421020*)0)->speaker_portrait) ==
            0x118
        ? 1
        : -1];
typedef char OtTalkVariantOffsetMustBe140_00421020[
    (unsigned int)&(((TalkDialogRuntimeState_00421020*)0)->talk_variant) ==
            0x140
        ? 1
        : -1];
typedef char OtTalkStateSizeMustBe144_00421020[
    sizeof(TalkDialogRuntimeState_00421020) == 0x144 ? 1 : -1];
typedef char OtTalkRouteBitmapIdsOffsetMustBe132_00421020[
    (unsigned int)&(((TalkRouteDescriptor_00421020*)0)->
        talk_bitmap_resource_ids) == 0x132
        ? 1
        : -1];

static const char kTalkDialogPlacementKey_00421020[] = "Talk Dialog";
static const char kTalkDialogAllocationFailure_00421020[] =
    "Can't allocate local memory";
static const char kTalkDialogProcedureName_00421020[] = "TalkDlgProc";

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" long __stdcall OtTalkDialogProc_00421020_ProductWip(
    OtTalkHandle_00421020 dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam)
{
    switch (message) {
    case 0x0002: { // WM_DESTROY
        OtTalkRect_00421020 dialog_rect;
        TalkDialogRuntimeState_00421020* state;
        state = reinterpret_cast<TalkDialogRuntimeState_00421020*>(
            GetWindowLongA(dialog, 8));
        GetWindowRect(dialog, &dialog_rect);
        OtPersistDialogPlacement_00401430_RealCpp(
            kTalkDialogPlacementKey_00421020,
            &dialog_rect);
        if (state != 0) {
            delete state;
        }
        g_appBusyCursorActive_Product_004034d0 = 0;
        SetCursor(LoadCursorA(0, reinterpret_cast<const void*>(0x7f00)));
        return 1;
    }

    case 0x000f: { // WM_PAINT
        OtTalkPaintStruct_00421020 paint;
        TalkDialogRuntimeState_00421020* state;
        OtTalkHandle_00421020 dc;
        g_appBusyCursorActive_Product_004034d0 = 1;
        SetCursor(LoadCursorA(0, reinterpret_cast<const void*>(0x7f02)));
        dc = BeginPaint(dialog, &paint);
        SelectPalette(dc, g_gamePalette, 0);
        UnrealizeObject(g_gamePalette);
        RealizePalette(dc);
        state = reinterpret_cast<TalkDialogRuntimeState_00421020*>(
            GetWindowLongA(dialog, 8));
        reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
            &state->speaker_portrait)->
                OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
            &state->dialog_backdrop)->
                OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        EndPaint(dialog, &paint);
        g_appBusyCursorActive_Product_004034d0 = 0;
        SetCursor(LoadCursorA(0, reinterpret_cast<const void*>(0x7f00)));
        return 1;
    }

    case 0x0014: { // WM_ERASEBKGND
        OtTalkRect_00421020 update_rect;
        OtTalkHandle_00421020 dc;
        dc = reinterpret_cast<OtTalkHandle_00421020>(wparam);
        SelectPalette(dc, g_gamePalette, 0);
        RealizePalette(dc);
        if (GetUpdateRect(dialog, &update_rect, 0) != 0) {
            FillRect(dc, &update_rect, g_sharedDialogBackgroundBrush_004390c0);
        }
        return 1;
    }

    case 0x0020: // WM_SETCURSOR
        return OtSelectDialogCursor_0040d530_RealCpp(
            g_appBusyCursorActive_Product_004034d0,
            reinterpret_cast<OtTalkHandle_00421020>(wparam));

    case 0x002b: { // WM_DRAWITEM
        TalkDialogRuntimeState_00421020* state;
        OtTalkDrawItemStruct_00421020* draw_item;
        draw_item = reinterpret_cast<OtTalkDrawItemStruct_00421020*>(lparam);
        state = reinterpret_cast<TalkDialogRuntimeState_00421020*>(
            GetWindowLongA(dialog, 8));
        SelectPalette(draw_item->dc, g_gamePalette, 0);
        RealizePalette(draw_item->dc);

        switch (draw_item->item_action) {
        case 1:
            switch (wparam) {
            case 0x12c:
                reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                    &state->close_up)->
                        OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                            draw_item->dc, 0, 0);
                return 1;
            case 0x132:
                reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                    &state->play_audio_up)->
                        OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                            draw_item->dc, 0, 0);
                return 1;
            case 0x133:
                reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                    &state->stop_audio_up)->
                        OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                            draw_item->dc, 0, 0);
                return 1;
            default:
                return 1;
            }

        case 2:
            if ((draw_item->item_state & 1) != 0) {
                switch (wparam) {
                case 0x12c:
                    reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                        &state->close_down)->
                            OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                                draw_item->dc, 0, 0);
                    return 1;
                case 0x132:
                    reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                        &state->play_audio_down)->
                            OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                                draw_item->dc, 0, 0);
                    return 1;
                case 0x133:
                    reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                        &state->stop_audio_down)->
                            OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                                draw_item->dc, 0, 0);
                    return 1;
                default:
                    return 1;
                }
            }

            switch (wparam) {
            case 0x12c:
                reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                    &state->close_up)->
                        OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                            draw_item->dc, 0, 0);
                return 1;
            case 0x132:
                reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                    &state->play_audio_up)->
                        OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                            draw_item->dc, 0, 0);
                return 1;
            case 0x133:
                reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                    &state->stop_audio_up)->
                        OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                            draw_item->dc, 0, 0);
                return 1;
            default:
                return 1;
            }

        default:
            return 1;
        }
    }

    case 0x0110: { // WM_INITDIALOG
        char text[500];
        OtTalkRect_00421020 saved_rect;
        OtTalkRect_00421020 parent_client_rect;
        OtTalkRect_00421020 dialog_rect;
        OtTalkPoint_00421020 parent_center;
        TalkDialogRuntimeState_00421020* state;
        TalkRouteDescriptor_00421020* route;
        unsigned int horizontal_base_units;
        unsigned int vertical_base_units;
        unsigned int string_id;
        int talk_variant;
        g_appBusyCursorActive_Product_004034d0 = 1;
        SetCursor(LoadCursorA(0, reinterpret_cast<const void*>(0x7f02)));

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
                kTalkDialogPlacementKey_00421020,
                &saved_rect) == 0) {
            GetClientRect(GetParent(dialog), &parent_client_rect);
            parent_center.x = parent_client_rect.left +
                (parent_client_rect.right - parent_client_rect.left) / 2;
            parent_center.y = parent_client_rect.top +
                (parent_client_rect.bottom - parent_client_rect.top) / 2;
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

        if (g_cdMediaMode_00439108 != 0) {
            OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
                dialog, 0x132, horizontal_base_units, vertical_base_units);
            OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
                dialog, 0x133, horizontal_base_units, vertical_base_units);
        }
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog, 0x1270, horizontal_base_units, vertical_base_units);
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog, 0x12c, horizontal_base_units, vertical_base_units);

        state = new TalkDialogRuntimeState_00421020;
        if (state == 0) {
            MessageBoxA(
                GetParent(dialog),
                kTalkDialogAllocationFailure_00421020,
                kTalkDialogProcedureName_00421020,
                0);
            PostQuitMessage(0);
            return 0;
        }

        memset(state, 0, sizeof(*state));
        reinterpret_cast<PositionedBitmapDescriptorState_0040ba40*>(
            &state->dialog_backdrop)->
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_resourceModule, 0x1272);
        reinterpret_cast<PositionedBitmapDescriptorState_0040ba40*>(
            &state->speaker_portrait)->
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_resourceModule, 0x1271);

        route = reinterpret_cast<TalkRouteDescriptor_00421020*>(
            g_activeRouteDescriptor);
        talk_variant = static_cast<short>(lparam);
        reinterpret_cast<PositionedBitmapDescriptorState_0040ba40*>(
            &state->speaker_portrait)->
                OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
                    g_resourceModule,
                    static_cast<unsigned short>(
                        route->talk_bitmap_resource_ids[talk_variant]),
                    0,
                    0,
                    0,
                    0);
        state->talk_variant = lparam;

        string_id = static_cast<unsigned int>(route->route_id) * 0x10 +
            talk_variant * 3 + 0xd2;
        LoadStringA(g_resourceModule, string_id, text, sizeof(text));
        SetWindowTextA(dialog, text);

        memset(text, 0, sizeof(text));
        string_id = static_cast<unsigned int>(route->route_id) * 0x10 +
            talk_variant * 3 + 0xd3;
        LoadStringA(g_resourceModule, string_id, text, sizeof(text));
        SetWindowTextA(GetDlgItem(dialog, 0x1270), text);

        if (g_cdMediaMode_00439108 != 0) {
            reinterpret_cast<PositionedBitmapDescriptorState_0040ba40*>(
                &state->play_audio_up)->
                    OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                        g_applicationModule_00405a40_20260603, 0x282c);
            reinterpret_cast<PositionedBitmapDescriptorState_0040ba40*>(
                &state->play_audio_down)->
                    OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                        g_applicationModule_00405a40_20260603, 0x282d);
            reinterpret_cast<PositionedBitmapDescriptorState_0040ba40*>(
                &state->stop_audio_up)->
                    OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                        g_applicationModule_00405a40_20260603, 0x282e);
            reinterpret_cast<PositionedBitmapDescriptorState_0040ba40*>(
                &state->stop_audio_down)->
                    OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                        g_applicationModule_00405a40_20260603, 0x282f);
            OtResizeControl_RealCpp(
                dialog,
                0x132,
                state->play_audio_up.width,
                state->play_audio_up.height);
            OtResizeControl_RealCpp(
                dialog,
                0x133,
                state->stop_audio_up.width,
                state->stop_audio_up.height);
        }

        reinterpret_cast<PositionedBitmapDescriptorState_0040ba40*>(
            &state->close_up)->
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603, 0x2826);
        reinterpret_cast<PositionedBitmapDescriptorState_0040ba40*>(
            &state->close_down)->
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603, 0x2827);
        OtResizeControl_RealCpp(
            dialog,
            0x12c,
            state->close_up.width,
            state->close_up.height);

        SetWindowLongA(dialog, 8, reinterpret_cast<long>(state));
        SetFocus(GetDlgItem(dialog, 0x12c));
        SendMessageA(dialog, 0x401, 0x12c, 0);
        return 0;
    }

    case 0x0111: { // WM_COMMAND
        char text[500];
        TalkDialogRuntimeState_00421020* state;
        TalkRouteDescriptor_00421020* route;
        unsigned int command;
        unsigned int string_id;
        state = reinterpret_cast<TalkDialogRuntimeState_00421020*>(
            GetWindowLongA(dialog, 8));
        command = wparam & 0xffff;
        switch (command) {
        case 0x12c:
            if (g_cdMediaMode_00439108 != 0 &&
                DAT_004390e8 != 0) {
                OtCloseWaveAudioDevice_0040d0a0_RealCpp();
            }
            EndDialog(dialog, 1);
            return 1;

        case 0x132:
            if (g_cdMediaMode_00439108 != 0 &&
                DAT_004390e8 != 0) {
                memset(text, 0, 20);
                route = reinterpret_cast<TalkRouteDescriptor_00421020*>(
                    g_activeRouteDescriptor);
                string_id = static_cast<unsigned int>(route->route_id) * 0x10 +
                    static_cast<short>(state->talk_variant) * 3 + 0xd4;
                LoadStringA(g_resourceModule, string_id, text, 0x13);
                OtOpenWaveAudioFile_0000d110_RealCpp(
                    g_activeScreenDialogWindow_00404dd0,
                    text);
                OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();
            }
            return 1;

        case 0x133:
            if (g_cdMediaMode_00439108 != 0 &&
                DAT_004390e8 != 0) {
                OtStopWaveAudioDirectImport_0040d480_RealCpp();
            }
            return 1;

        default:
            return 1;
        }
    }

    case 0x0138: { // WM_CTLCOLORSTATIC
        OtTalkHandle_00421020 dc;
        dc = reinterpret_cast<OtTalkHandle_00421020>(wparam);
        SelectPalette(dc, g_gamePalette, 0);
        RealizePalette(dc);
        SetBkMode(dc, 1);
        SetTextColor(dc, 0);
        SelectObject(dc, g_dialogFont_004390d8_00405320);
        return reinterpret_cast<long>(g_sharedDialogBackgroundBrush_004390c0);
    }

    case 0x03b9:
        return 0;

    default:
        return 0;
    }
}

#pragma optimize("", on)

// Product semantic WIP for OtRiverCrossingChoiceDialogProc @ 0x004229e0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This Product source must be compiled with 32-bit Microsoft Visual C++."
#endif

#include <stdlib.h>
#include <string.h>

#pragma intrinsic(memset)
#pragma intrinsic(strlen)

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" void* g_resourceModule;
extern "C" void* g_gamePalette;
extern "C" void* g_activeRouteDescriptor;
extern "C" void* g_journeyState;
extern "C" void* g_sharedDialogBackgroundBrush_004390c0;
extern "C" void* g_dialogFont_004390d8_00405320;
extern "C" int g_appBusyCursorActive_Product_004034d0;

extern void* __cdecl operator new(unsigned int bytes);
void __cdecl operator delete(void* block);

typedef long (__stdcall *OtDialogProc_004229e0)(
    void* dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam);

extern "C" long __stdcall
OtRiverCrossingHelpDialogProc_00423880_ProductWip(
    void* dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam);

extern "C" __declspec(dllimport) void* __stdcall BeginPaint(
    void* window,
    void* paint);
extern "C" __declspec(dllimport) int __stdcall EndPaint(
    void* window,
    const void* paint);
extern "C" __declspec(dllimport) void* __stdcall SelectPalette(
    void* dc,
    void* palette,
    int force_background);
extern "C" __declspec(dllimport) int __stdcall UnrealizeObject(void* object);
extern "C" __declspec(dllimport) unsigned int __stdcall RealizePalette(
    void* dc);
extern "C" __declspec(dllimport) void* __stdcall LoadCursorA(
    void* instance,
    const void* cursor_name);
extern "C" __declspec(dllimport) void* __stdcall SetCursor(void* cursor);
extern "C" __declspec(dllimport) int __stdcall GetUpdateRect(
    void* window,
    void* rect,
    int erase);
extern "C" __declspec(dllimport) int __stdcall FillRect(
    void* dc,
    const void* rect,
    void* brush);
extern "C" __declspec(dllimport) unsigned int __stdcall GetDialogBaseUnits(
    void);
extern "C" __declspec(dllimport) void* __stdcall GetParent(void* window);
extern "C" __declspec(dllimport) int __stdcall GetWindowRect(
    void* window,
    void* rect);
extern "C" __declspec(dllimport) int __stdcall GetClientRect(
    void* window,
    void* rect);
extern "C" __declspec(dllimport) int __stdcall ClientToScreen(
    void* window,
    void* point);
extern "C" __declspec(dllimport) int __stdcall SetWindowPos(
    void* window,
    void* insert_after,
    int x,
    int y,
    int width,
    int height,
    unsigned int flags);
extern "C" __declspec(dllimport) long __stdcall GetWindowLongA(
    void* window,
    int index);
extern "C" __declspec(dllimport) long __stdcall SetWindowLongA(
    void* window,
    int index,
    long value);
extern "C" __declspec(dllimport) void* __stdcall GetDlgItem(
    void* dialog,
    int control_id);
extern "C" __declspec(dllimport) int __stdcall GetWindowTextA(
    void* window,
    char* buffer,
    int max_count);
extern "C" __declspec(dllimport) int __stdcall SetWindowTextA(
    void* window,
    const char* text);
extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* module,
    unsigned int id,
    char* buffer,
    int max_count);
extern "C" __declspec(dllimport) int __stdcall EndDialog(
    void* dialog,
    int result);
extern "C" __declspec(dllimport) int __stdcall DialogBoxParamA(
    void* instance,
    const void* template_name,
    void* parent_window,
    OtDialogProc_004229e0 dialog_proc,
    long init_param);
extern "C" __declspec(dllimport) void __stdcall PostQuitMessage(
    int exit_code);
extern "C" __declspec(dllimport) void* __stdcall SelectObject(
    void* dc,
    void* object);
extern "C" __declspec(dllimport) int __stdcall SetBkMode(
    void* dc,
    int mode);
extern "C" __declspec(dllimport) unsigned long __stdcall SetTextColor(
    void* dc,
    unsigned long color);

extern "C" void __cdecl
OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
    void* dialog,
    int control_id,
    int dialog_unit_width,
    int dialog_unit_height);
extern "C" void __cdecl OtScaleWindowToDialogCoords_00401370_Product(
    void* parent,
    void* child,
    int dialog_unit_width,
    int dialog_unit_height);
extern "C" void __cdecl OtResizeControl_RealCpp(
    void* dialog,
    int control_id,
    int width,
    int height);
extern "C" int __cdecl OtSelectDialogCursor_0040d530_RealCpp(
    int force_busy_cursor,
    void* window);

#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "user32.lib")

#pragma pack(push, 1)
struct RiverChoiceRect_004229e0 {
    int left;
    int top;
    int right;
    int bottom;
};

struct RiverChoicePoint_004229e0 {
    int x;
    int y;
};

struct RiverChoicePaint_004229e0 {
    unsigned char data[0x40];
};

struct RiverChoiceDrawItem_004229e0 {
    unsigned int control_type;
    unsigned int control_id;
    unsigned int item_id;
    unsigned int item_action;
    unsigned int item_state;
    void* item_window;
    void* dc;
    RiverChoiceRect_004229e0 item_rect;
    unsigned long item_data;
};

struct PositionedBitmapDescriptorState_0040ba40 {
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

    PositionedBitmapDescriptorState_0040ba40();
    ~PositionedBitmapDescriptorState_0040ba40();

    int OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        void* module,
        short descriptor_id);
};

struct PositionedBitmap_0040b7b0_Semantic {
    unsigned char data[0x28];

    int OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        void* dc,
        int source_x,
        int source_y);
};

// No user-provided constructor or destructor is intentional.  VC4 must emit
// the fourteen member constructions and reverse-order cleanup implied by this
// aggregate, including /GX unwind state for a partially constructed object.
struct RiverCrossingChoiceDialogState_004229e0_ProductWip {
    short* selected_choice;
    PositionedBitmapDescriptorState_0040ba40 ford_up;
    PositionedBitmapDescriptorState_0040ba40 ford_down;
    PositionedBitmapDescriptorState_0040ba40 float_up;
    PositionedBitmapDescriptorState_0040ba40 float_down;
    PositionedBitmapDescriptorState_0040ba40 ferry_up;
    PositionedBitmapDescriptorState_0040ba40 ferry_down;
    PositionedBitmapDescriptorState_0040ba40 guide_up;
    PositionedBitmapDescriptorState_0040ba40 guide_down;
    PositionedBitmapDescriptorState_0040ba40 wait_up;
    PositionedBitmapDescriptorState_0040ba40 wait_down;
    PositionedBitmapDescriptorState_0040ba40 help_up;
    PositionedBitmapDescriptorState_0040ba40 help_down;
    PositionedBitmapDescriptorState_0040ba40 cancel_up;
    PositionedBitmapDescriptorState_0040ba40 cancel_down;
};

struct RiverChoiceRoute_004229e0 {
    unsigned short route_id;
    short route_stop_kind;
    short store_price_percent;
    short region_id;
    short river_difficulty;
    short base_width_feet;
};

struct RiverChoiceJourney_004229e0 {
    unsigned char reserved_000[0x54];
    short river_condition;
};
#pragma pack(pop)

typedef char RiverChoiceBitmapSizeCheck_004229e0[
    sizeof(PositionedBitmapDescriptorState_0040ba40) == 0x28 ? 1 : -1];
typedef char RiverChoiceStateSizeCheck_004229e0[
    sizeof(RiverCrossingChoiceDialogState_004229e0_ProductWip) == 0x234
        ? 1
        : -1];
typedef char RiverChoiceFirstBitmapOffsetCheck_004229e0[
    (unsigned int)&(((RiverCrossingChoiceDialogState_004229e0_ProductWip*)0)
        ->ford_up) == 0x4
        ? 1
        : -1];
typedef char RiverChoiceLastBitmapOffsetCheck_004229e0[
    (unsigned int)&(((RiverCrossingChoiceDialogState_004229e0_ProductWip*)0)
        ->cancel_down) == 0x20c
        ? 1
        : -1];
typedef char RiverChoiceDrawItemActionOffsetCheck_004229e0[
    (unsigned int)&(((RiverChoiceDrawItem_004229e0*)0)->item_action) == 0x0c
        ? 1
        : -1];
typedef char RiverChoiceDrawItemDcOffsetCheck_004229e0[
    (unsigned int)&(((RiverChoiceDrawItem_004229e0*)0)->dc) == 0x18
        ? 1
        : -1];
typedef char RiverChoiceRouteDifficultyOffsetCheck_004229e0[
    (unsigned int)&(((RiverChoiceRoute_004229e0*)0)->river_difficulty) == 0x8
        ? 1
        : -1];
typedef char RiverChoiceRouteWidthOffsetCheck_004229e0[
    (unsigned int)&(((RiverChoiceRoute_004229e0*)0)->base_width_feet) == 0x0a
        ? 1
        : -1];
typedef char RiverChoiceJourneyConditionOffsetCheck_004229e0[
    (unsigned int)&(((RiverChoiceJourney_004229e0*)0)->river_condition) == 0x54
        ? 1
        : -1];

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" long __stdcall
OtRiverCrossingChoiceDialogProc_004229e0_ProductWip(
    void* dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam)
{
    RiverChoicePaint_004229e0 paint;
    char text[200];
    RiverChoiceRect_004229e0 update_rect;
    RiverChoiceRect_004229e0 parent_rect;
    RiverChoiceRect_004229e0 dialog_rect;
    RiverChoicePoint_004229e0 center;
    unsigned int dialog_units;
    unsigned int dialog_unit_width;
    unsigned int dialog_unit_height;
    RiverCrossingChoiceDialogState_004229e0_ProductWip* state;
    RiverChoiceDrawItem_004229e0* draw_item;
    void* dc;
    int control_id;

    switch (message) {
    case 0x0002: {
        state = (RiverCrossingChoiceDialogState_004229e0_ProductWip*)
            GetWindowLongA(dialog, 8);

        if (state != 0) {
            delete state;
        }
        g_appBusyCursorActive_Product_004034d0 = 0;
        SetCursor(LoadCursorA(0, (const void*)0x7f00));
        return 1;
    }

    case 0x000f: {
        g_appBusyCursorActive_Product_004034d0 = 1;
        SetCursor(LoadCursorA(0, (const void*)0x7f02));
        dc = BeginPaint(dialog, &paint);
        SelectPalette(dc, g_gamePalette, 0);
        UnrealizeObject(g_gamePalette);
        RealizePalette(dc);
        EndPaint(dialog, &paint);
        g_appBusyCursorActive_Product_004034d0 = 0;
        SetCursor(LoadCursorA(0, (const void*)0x7f00));
        return 1;
    }

    case 0x0014: {
        dc = (void*)wparam;

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

    case 0x0020:
        return OtSelectDialogCursor_0040d530_RealCpp(
            g_appBusyCursorActive_Product_004034d0,
            (void*)wparam);

    case 0x002b: {
        draw_item = (RiverChoiceDrawItem_004229e0*)lparam;
        state = (RiverCrossingChoiceDialogState_004229e0_ProductWip*)
            GetWindowLongA(dialog, 8);

        SelectPalette(draw_item->dc, g_gamePalette, 0);
        RealizePalette(draw_item->dc);

        switch (draw_item->item_action) {
        case 1:
            switch (wparam) {
            case 0x12d:
                ((PositionedBitmap_0040b7b0_Semantic*)&state->cancel_up)
                    ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw_item->dc, 0, 0);
                return 1;
            case 0x131:
                ((PositionedBitmap_0040b7b0_Semantic*)&state->help_up)
                    ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw_item->dc, 0, 0);
                return 1;
            case 0x1168:
                ((PositionedBitmap_0040b7b0_Semantic*)&state->ford_up)
                    ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw_item->dc, 0, 0);
                return 1;
            case 0x1169:
                ((PositionedBitmap_0040b7b0_Semantic*)&state->float_up)
                    ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw_item->dc, 0, 0);
                return 1;
            case 0x116a:
                ((PositionedBitmap_0040b7b0_Semantic*)&state->ferry_up)
                    ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw_item->dc, 0, 0);
                return 1;
            case 0x116b:
                ((PositionedBitmap_0040b7b0_Semantic*)&state->guide_up)
                    ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw_item->dc, 0, 0);
                return 1;
            case 0x116c:
                ((PositionedBitmap_0040b7b0_Semantic*)&state->wait_up)
                    ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw_item->dc, 0, 0);
                return 1;
            }
            break;

        case 2:
            if ((draw_item->item_state & 1) != 0) {
                switch (wparam) {
            case 0x12d:
                ((PositionedBitmap_0040b7b0_Semantic*)&state->cancel_down)
                    ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw_item->dc, 0, 0);
                return 1;
            case 0x131:
                ((PositionedBitmap_0040b7b0_Semantic*)&state->help_down)
                    ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw_item->dc, 0, 0);
                return 1;
            case 0x1168:
                ((PositionedBitmap_0040b7b0_Semantic*)&state->ford_down)
                    ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw_item->dc, 0, 0);
                return 1;
            case 0x1169:
                ((PositionedBitmap_0040b7b0_Semantic*)&state->float_down)
                    ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw_item->dc, 0, 0);
                return 1;
            case 0x116a:
                ((PositionedBitmap_0040b7b0_Semantic*)&state->ferry_down)
                    ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw_item->dc, 0, 0);
                return 1;
            case 0x116b:
                ((PositionedBitmap_0040b7b0_Semantic*)&state->guide_down)
                    ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw_item->dc, 0, 0);
                return 1;
            case 0x116c:
                ((PositionedBitmap_0040b7b0_Semantic*)&state->wait_down)
                    ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw_item->dc, 0, 0);
                return 1;
                }
            } else {
                switch (wparam) {
        case 0x12d:
            ((PositionedBitmap_0040b7b0_Semantic*)&state->cancel_up)
                ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                    draw_item->dc, 0, 0);
            return 1;
        case 0x131:
            ((PositionedBitmap_0040b7b0_Semantic*)&state->help_up)
                ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                    draw_item->dc, 0, 0);
            return 1;
        case 0x1168:
            ((PositionedBitmap_0040b7b0_Semantic*)&state->ford_up)
                ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                    draw_item->dc, 0, 0);
            return 1;
        case 0x1169:
            ((PositionedBitmap_0040b7b0_Semantic*)&state->float_up)
                ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                    draw_item->dc, 0, 0);
            return 1;
        case 0x116a:
            ((PositionedBitmap_0040b7b0_Semantic*)&state->ferry_up)
                ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                    draw_item->dc, 0, 0);
            return 1;
        case 0x116b:
            ((PositionedBitmap_0040b7b0_Semantic*)&state->guide_up)
                ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                    draw_item->dc, 0, 0);
            return 1;
        case 0x116c:
            ((PositionedBitmap_0040b7b0_Semantic*)&state->wait_up)
                ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                    draw_item->dc, 0, 0);
            return 1;
                }
            }
            break;
        }

        return 1;
    }

    case 0x0110: {
        RiverChoiceRoute_004229e0* route =
            (RiverChoiceRoute_004229e0*)g_activeRouteDescriptor;
        RiverChoiceJourney_004229e0* journey =
            (RiverChoiceJourney_004229e0*)g_journeyState;
        g_appBusyCursorActive_Product_004034d0 = 1;
        SetCursor(LoadCursorA(0, (const void*)0x7f02));

        state = new RiverCrossingChoiceDialogState_004229e0_ProductWip;
        if (state == 0) {
            PostQuitMessage(0);
            return 0;
        }

        dialog_units = GetDialogBaseUnits();
        dialog_unit_width = (unsigned short)dialog_units;
        dialog_units = GetDialogBaseUnits();
        dialog_unit_height = (unsigned short)(dialog_units >> 16);
        OtScaleWindowToDialogCoords_00401370_Product(
            GetParent(dialog),
            dialog,
            dialog_unit_width,
            dialog_unit_height);

        GetWindowRect(dialog, &dialog_rect);
        GetClientRect(GetParent(dialog), &parent_rect);
        center.x = parent_rect.left +
            (parent_rect.right - parent_rect.left) / 2;
        center.y = parent_rect.top +
            (parent_rect.bottom - parent_rect.top) / 2;
        ClientToScreen(GetParent(dialog), &center);
        SetWindowPos(
            dialog,
            0,
            center.x + (dialog_rect.left - dialog_rect.right) / 2,
            center.y + (dialog_rect.top - dialog_rect.bottom) / 2,
            dialog_rect.right - dialog_rect.left,
            dialog_rect.bottom - dialog_rect.top,
            4);

        control_id = 0x1162;
        do {
            OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
                dialog,
                control_id,
                dialog_unit_width,
                dialog_unit_height);
            ++control_id;
        } while (control_id <= 0x116c);
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog, 0x131, dialog_unit_width, dialog_unit_height);
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog, 0x12d, dialog_unit_width, dialog_unit_height);

        state->selected_choice = (short*)lparam;
        state->ford_up.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603, 0x280b);
        state->ford_down.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603, 0x280c);
        state->float_up.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603, 0x280e);
        state->float_down.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603, 0x280f);
        state->ferry_up.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603, 0x2811);
        state->ferry_down.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603, 0x2812);
        state->guide_up.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603, 0x2814);
        state->guide_down.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603, 0x2815);
        state->wait_up.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603, 0x2824);
        state->wait_down.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603, 0x2825);
        state->help_up.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603, 0x2808);
        state->help_down.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603, 0x2809);
        state->cancel_up.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603, 0x2828);
        state->cancel_down.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603, 0x2829);

        SetWindowLongA(dialog, 8, (long)state);

        memset(text, 0, sizeof(text));
        GetWindowTextA(GetDlgItem(dialog, 0x1162), text, 199);
        _itoa(
            (int)(short)(route->base_width_feet +
                (short)((journey->river_condition * 15) / 100)),
            text + strlen(text),
            10);
        strncat(text, " feet across and ", 199 - strlen(text));
        _itoa(
            (int)(short)((short)(
                (short)((journey->river_condition * 2) / 10) +
                route->river_difficulty * 10) / 10),
            text + strlen(text),
            10);
        strncat(text, ".", 199 - strlen(text));
        _itoa(
            (int)(short)((short)(
                (short)((((RiverChoiceJourney_004229e0*)g_journeyState)->
                    river_condition * 2) / 10) +
                ((RiverChoiceRoute_004229e0*)g_activeRouteDescriptor)->
                    river_difficulty * 10) % 10),
            text + strlen(text),
            10);
        strncat(
            text,
            " feet deep in the middle.",
            199 - strlen(text));
        SetWindowTextA(GetDlgItem(dialog, 0x1162), text);

        control_id = 0x1168;
        do {
            OtResizeControl_RealCpp(
                dialog,
                control_id,
                state->ford_up.width,
                state->ford_up.height);
            ++control_id;
        } while (control_id <= 0x116c);
        OtResizeControl_RealCpp(
            dialog, 0x131, state->help_up.width, state->help_up.height);
        OtResizeControl_RealCpp(
            dialog, 0x12d, state->cancel_up.width, state->cancel_up.height);

        memset(text, 0, sizeof(text));
        LoadStringA(
            g_resourceModule,
            (route->route_id + 0x0d) * 0x10,
            text,
            199);
        SetWindowTextA(dialog, text);
        return 0;
    }

    case 0x0111: {
        state = (RiverCrossingChoiceDialogState_004229e0_ProductWip*)
            GetWindowLongA(dialog, 8);

        switch ((unsigned short)wparam) {
        case 0x12d:
            *state->selected_choice = -1;
            EndDialog(dialog, 0);
            return 1;
        case 0x131:
            DialogBoxParamA(
                g_applicationModule_00405a40_20260603,
                (const void*)0x00ee,
                dialog,
                OtRiverCrossingHelpDialogProc_00423880_ProductWip,
                0);
            return 1;
        case 0x1168:
            *state->selected_choice = 100;
            EndDialog(dialog, 1);
            return 1;
        case 0x1169:
            *state->selected_choice = 101;
            EndDialog(dialog, 1);
            return 1;
        case 0x116a:
            *state->selected_choice = 102;
            EndDialog(dialog, 1);
            return 1;
        case 0x116b:
            *state->selected_choice = 103;
            EndDialog(dialog, 1);
            return 1;
        case 0x116c:
            *state->selected_choice = 104;
            EndDialog(dialog, 1);
            return 1;
        default:
            return 1;
        }
    }

    case 0x0138: {
        dc = (void*)wparam;

        SelectPalette(dc, g_gamePalette, 0);
        RealizePalette(dc);
        SetBkMode(dc, 1);
        SetTextColor(dc, 0);
        SelectObject(dc, g_dialogFont_004390d8_00405320);
        return (long)g_sharedDialogBackgroundBrush_004390c0;
    }
    }

    return 0;
}

#pragma optimize("", on)
#pragma code_seg()

// Product semantic WIP for OtTrailDivideDialogProc @ 0x0041c980.
//
// This is the modal callback used when a route offers two successors.  It
// preserves the original four-argument Win32 dialog-proc ABI and the route
// choice/toll semantics while using normal Product-owned UI state.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include <string.h>

#pragma intrinsic(memset)

extern "C" void* g_activeRouteDescriptor;
extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" void* g_gamePalette;
extern "C" void* g_journeyState;
extern "C" void* g_sharedDialogBackgroundBrush_004390c0;
extern "C" void* g_optionMenuFont_004390d4_00405320;
extern "C" int g_appBusyCursorActive_Product_004034d0;

extern void* __cdecl operator new(unsigned int bytes);
void __cdecl operator delete(void* block);

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
extern "C" __declspec(dllimport) int __stdcall GetClientRect(
    void* window,
    void* rect);
extern "C" __declspec(dllimport) int __stdcall GetWindowRect(
    void* window,
    void* rect);
extern "C" __declspec(dllimport) void* __stdcall GetParent(void* window);
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
extern "C" __declspec(dllimport) unsigned int __stdcall GetDialogBaseUnits();
extern "C" __declspec(dllimport) long __stdcall GetWindowLongA(
    void* window,
    int index);
extern "C" __declspec(dllimport) long __stdcall SetWindowLongA(
    void* window,
    int index,
    long value);
extern "C" __declspec(dllimport) int __stdcall EndDialog(
    void* dialog,
    int result);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    void* owner,
    const char* text,
    const char* caption,
    unsigned int type);
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
    int width_scale,
    int height_scale);
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
struct TrailDivideRect_0041c980 {
    int left;
    int top;
    int right;
    int bottom;
};

struct TrailDividePoint_0041c980 {
    int x;
    int y;
};

struct TrailDividePaint_0041c980 {
    char data[0x40];
};

struct TrailDivideDrawItem_0041c980 {
    unsigned int control_type;
    unsigned int control_id;
    unsigned int item_id;
    unsigned int item_action;
    unsigned int item_state;
    void* item_window;
    void* dc;
    TrailDivideRect_0041c980 item_rect;
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

    int OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        void* dc,
        int source_x,
        int source_y);
};

struct TrailDivideDialogState_0041c980 {
    short* result;
    PositionedBitmapDescriptorState_0040ba40 primary_default;
    PositionedBitmapDescriptorState_0040ba40 primary_pressed;
    PositionedBitmapDescriptorState_0040ba40 alternate_default;
    PositionedBitmapDescriptorState_0040ba40 alternate_pressed;
};

struct TrailDivideRouteState_0041c980 {
    char reserved_000[0x12];
    short stop_kind;
};

struct TrailDivideJourneyState_0041c980 {
    char reserved_000[0xa8];
    int cash;
};
#pragma pack(pop)

typedef char TrailDivideBitmapSizeCheck_0041c980[
    sizeof(PositionedBitmapDescriptorState_0040ba40) == 0x28 ? 1 : -1];
typedef char TrailDivideDialogStateSizeCheck_0041c980[
    sizeof(TrailDivideDialogState_0041c980) == 0xa4 ? 1 : -1];

static const char kTrailDivideAllocationMessage_0041c980[] =
    "Can't allocate local memory.";
static const char kTrailDivideAllocationCaption_0041c980[] =
    "Trail Divides";
static const char kTrailDivideTollMessage_0041c980[] =
    "You don't have enough money for the Barlow Toll Road.  "
    "You will have to raft down the Columbia River.";
static const char kTrailDivideTollCaption_0041c980[] =
    "Too Expensive";

static inline TrailDivideDialogState_0041c980*
OtGetTrailDivideDialogState_0041c980(void* dialog)
{
    return (TrailDivideDialogState_0041c980*)GetWindowLongA(dialog, 8);
}

static inline TrailDivideDrawItem_0041c980*
OtGetTrailDivideDrawItem_0041c980(long item_data)
{
    return (TrailDivideDrawItem_0041c980*)item_data;
}

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" long __stdcall OtTrailDivideDialogProc_0041c980_ProductWip(
    void* dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam)
{
    void* dc;
    unsigned int command_id;
    int control_id;
    TrailDivideDialogState_0041c980* state;
    TrailDivideRouteState_0041c980* route;
    TrailDivideDrawItem_0041c980* draw_item;
    TrailDividePaint_0041c980 paint;
    TrailDivideRect_0041c980 update_rect;
    TrailDivideRect_0041c980 parent_rect;
    TrailDivideRect_0041c980 dialog_rect;
    TrailDividePoint_0041c980 center;
    unsigned int dialog_unit_width;
    unsigned int dialog_unit_height;

    switch (message) {
    case 0x0002: {
        state = (TrailDivideDialogState_0041c980*)GetWindowLongA(dialog, 8);

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
        draw_item = OtGetTrailDivideDrawItem_0041c980(lparam);
        state = OtGetTrailDivideDialogState_0041c980(dialog);

        SelectPalette(draw_item->dc, g_gamePalette, 0);
        RealizePalette(draw_item->dc);

        switch (draw_item->item_action) {
        case 1:
            if (wparam == 0x1132) {
                dc = draw_item->dc;
                ((PositionedBitmap_0040b7b0_Semantic*)
                    &state->primary_default)->
                    OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        dc, 0, 0);
                return 1;
            }
            dc = draw_item->dc;
            ((PositionedBitmap_0040b7b0_Semantic*)
                &state->alternate_default)->
                OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                dc, 0, 0);
            return 1;

        case 2:
            if ((draw_item->item_state & 1) != 0) {
                if (wparam == 0x1132) {
                    dc = draw_item->dc;
                    ((PositionedBitmap_0040b7b0_Semantic*)
                        &state->primary_pressed)->
                        OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                            dc, 0, 0);
                    return 1;
                }
                dc = draw_item->dc;
                ((PositionedBitmap_0040b7b0_Semantic*)
                    &state->alternate_pressed)->
                    OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                    dc, 0, 0);
                return 1;
            }

            if (wparam == 0x1132) {
                dc = draw_item->dc;
                ((PositionedBitmap_0040b7b0_Semantic*)
                    &state->primary_default)->
                    OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        dc, 0, 0);
                return 1;
            }
            dc = draw_item->dc;
            ((PositionedBitmap_0040b7b0_Semantic*)
                &state->alternate_default)->
                OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                dc, 0, 0);
            return 1;

        default:
            return 1;
        }
    }

    case 0x0110: {
        g_appBusyCursorActive_Product_004034d0 = 1;
        SetCursor(LoadCursorA(0, (const void*)0x7f02));

        dialog_unit_width =
            (unsigned short)GetDialogBaseUnits();
        dialog_unit_height =
            (unsigned short)(GetDialogBaseUnits() >> 16);
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

        state = new TrailDivideDialogState_0041c980;
        if (state == 0) {
            MessageBoxA(
                GetParent(dialog),
                kTrailDivideAllocationMessage_0041c980,
                kTrailDivideAllocationCaption_0041c980,
                0);
            PostQuitMessage(0);
        }

        control_id = 0x1130;
        do {
            OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
                dialog,
                control_id,
                dialog_unit_width,
                dialog_unit_height);
            ++control_id;
        } while (control_id <= 0x1136);

        memset(state, 0, sizeof(*state));
        state->result = (short*)lparam;
        if (*state->result < 3) {
            state->primary_default.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603, 0x281b);
            state->primary_pressed.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603, 0x281c);
            state->alternate_default.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603, 0x281d);
            state->alternate_pressed.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603, 0x281e);
        } else {
            state->primary_default.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603, 0x281f);
            state->primary_pressed.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603, 0x2820);
            state->alternate_default.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603, 0x2821);
            state->alternate_pressed.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603, 0x2822);
        }

        SetWindowLongA(dialog, 8, (long)state);
        OtResizeControl_RealCpp(
            dialog,
            0x1132,
            state->primary_default.width,
            state->primary_default.height);
        OtResizeControl_RealCpp(
            dialog,
            0x1135,
            state->alternate_default.width,
            state->alternate_default.height);
        return 0;
    }

    case 0x0111: {
        state = (TrailDivideDialogState_0041c980*)GetWindowLongA(dialog, 8);
        command_id = (unsigned short)wparam;

        switch (command_id) {
        case 0x1132: {
            *state->result = 0;
            route = (TrailDivideRouteState_0041c980*)g_activeRouteDescriptor;
            if (route->stop_kind == 0x11) {
                TrailDivideJourneyState_0041c980* journey =
                    (TrailDivideJourneyState_0041c980*)g_journeyState;
                int cash = journey->cash;

                if (cash < 500) {
                    MessageBoxA(
                        dialog,
                        kTrailDivideTollMessage_0041c980,
                        kTrailDivideTollCaption_0041c980,
                        0);
                    return 1;
                }
                journey->cash = cash - 500;
                EndDialog(dialog, 1);
                return 1;
            }
            EndDialog(dialog, 1);
            return 1;
        }

        case 0x1135:
            *state->result = 1;
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
        SelectObject(dc, g_optionMenuFont_004390d4_00405320);
        return (long)g_sharedDialogBackgroundBrush_004390c0;
    }
    }

    return 0;
}

#pragma optimize("", on)
#pragma code_seg()

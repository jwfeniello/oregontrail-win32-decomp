// Product semantic WIP for OtRiverCrossingHelpDialogProc @ 0x00423880.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This Product source must be compiled with 32-bit Microsoft Visual C++."
#endif

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" void* g_gamePalette;
extern "C" void* g_sharedDialogBackgroundBrush_004390c0;
extern "C" void* g_dialogFont_004390d8_00405320;
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
extern "C" __declspec(dllimport) void* __stdcall SetFocus(void* window);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    void* window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall EndDialog(
    void* dialog,
    int result);
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
struct RiverHelpRect_00423880 {
    int left;
    int top;
    int right;
    int bottom;
};

struct RiverHelpPoint_00423880 {
    int x;
    int y;
};

struct RiverHelpPaint_00423880 {
    unsigned char data[0x40];
};

struct RiverHelpDrawItem_00423880 {
    unsigned int control_type;
    unsigned int control_id;
    unsigned int item_id;
    unsigned int item_action;
    unsigned int item_state;
    void* item_window;
    void* dc;
    RiverHelpRect_00423880 item_rect;
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

// The implicit constructor/destructor are required: VC4 must construct both
// members in order and destroy them in reverse order under /GX.
struct RiverCrossingHelpDialogState_00423880_ProductWip {
    PositionedBitmapDescriptorState_0040ba40 close_button_up;
    PositionedBitmapDescriptorState_0040ba40 close_button_down;
};
#pragma pack(pop)

typedef char RiverHelpBitmapSizeCheck_00423880[
    sizeof(PositionedBitmapDescriptorState_0040ba40) == 0x28 ? 1 : -1];
typedef char RiverHelpStateSizeCheck_00423880[
    sizeof(RiverCrossingHelpDialogState_00423880_ProductWip) == 0x50 ? 1 : -1];
typedef char RiverHelpSecondBitmapOffsetCheck_00423880[
    (unsigned int)&(((RiverCrossingHelpDialogState_00423880_ProductWip*)0)
        ->close_button_down) == 0x28
        ? 1
        : -1];
typedef char RiverHelpDrawActionOffsetCheck_00423880[
    (unsigned int)&(((RiverHelpDrawItem_00423880*)0)->item_action) == 0x0c
        ? 1
        : -1];
typedef char RiverHelpDrawStateOffsetCheck_00423880[
    (unsigned int)&(((RiverHelpDrawItem_00423880*)0)->item_state) == 0x10
        ? 1
        : -1];
typedef char RiverHelpDrawDcOffsetCheck_00423880[
    (unsigned int)&(((RiverHelpDrawItem_00423880*)0)->dc) == 0x18
        ? 1
        : -1];

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" long __stdcall
OtRiverCrossingHelpDialogProc_00423880_ProductWip(
    void* dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam)
{
    RiverHelpPaint_00423880 paint;
    RiverHelpRect_00423880 update_rect;
    RiverHelpRect_00423880 parent_rect;
    RiverHelpRect_00423880 dialog_rect;
    RiverHelpPoint_00423880 center;
    unsigned int dialog_units;
    unsigned int dialog_unit_width;
    unsigned int dialog_unit_height;
    RiverCrossingHelpDialogState_00423880_ProductWip* state;
    RiverHelpDrawItem_00423880* draw_item;
    void* dc;
    int control_id;

    switch (message) {
    case 0x0002: {
        state = (RiverCrossingHelpDialogState_00423880_ProductWip*)
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
        draw_item = (RiverHelpDrawItem_00423880*)lparam;
        state = (RiverCrossingHelpDialogState_00423880_ProductWip*)
            GetWindowLongA(dialog, 8);

        SelectPalette(draw_item->dc, g_gamePalette, 0);
        RealizePalette(draw_item->dc);

        switch (draw_item->item_action) {
        case 1:
            if (wparam == 0x12c) {
                ((PositionedBitmap_0040b7b0_Semantic*)
                    &state->close_button_up)
                    ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw_item->dc, 0, 0);
            }
            break;

        case 2:
            if ((draw_item->item_state & 1) != 0) {
                if (wparam == 0x12c) {
                    ((PositionedBitmap_0040b7b0_Semantic*)
                        &state->close_button_down)
                        ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                            draw_item->dc, 0, 0);
                }
            } else if (wparam == 0x12c) {
                ((PositionedBitmap_0040b7b0_Semantic*)
                    &state->close_button_up)
                    ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw_item->dc, 0, 0);
            }
            break;
        }
        return 1;
    }

    case 0x0110: {
        g_appBusyCursorActive_Product_004034d0 = 1;
        SetCursor(LoadCursorA(0, (const void*)0x7f02));

        state = new RiverCrossingHelpDialogState_00423880_ProductWip;
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

        control_id = 0x116d;
        do {
            OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
                dialog,
                control_id,
                dialog_unit_width,
                dialog_unit_height);
            ++control_id;
        } while (control_id <= 0x1171);
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog, 0x12c, dialog_unit_width, dialog_unit_height);

        state->close_button_up.
            OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                g_applicationModule_00405a40_20260603, 0x2826);
        state->close_button_down.
            OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                g_applicationModule_00405a40_20260603, 0x2827);
        SetWindowLongA(dialog, 8, (long)state);
        OtResizeControl_RealCpp(
            dialog,
            0x12c,
            state->close_button_up.width,
            state->close_button_up.height);
        SetFocus(GetDlgItem(dialog, 0x12c));
        SendMessageA(dialog, 0x401, 0x12c, 0);
        return 0;
    }

    case 0x0111:
        if ((wparam & 0xffff) == 0x12c) {
            EndDialog(dialog, 0);
        }
        return 1;

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

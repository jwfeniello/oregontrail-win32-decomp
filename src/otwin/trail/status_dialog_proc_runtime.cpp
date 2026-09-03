// Product semantic WIP for OtStatusDialogProc @ 0x0041d040.
//
// The original is a four-argument Win32 dialog procedure.  This recovery
// preserves its palette-aware paint path, owner-drawn close button, owned
// bitmap lifetime, modeless-window registration, and custom status refresh.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" void* g_gamePalette;
extern "C" void* g_journeyState;
extern "C" void* g_sharedDialogBackgroundBrush_004390c0;
extern "C" void* g_optionMenuFont_004390d4_00405320;
extern "C" void* g_dialogFont_004390d8_00405320;
extern "C" void* g_trailStatusNotifyWindow_004390d0;
extern "C" int g_appBusyCursorActive_Product_004034d0;

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
extern "C" __declspec(dllimport) int __stdcall DestroyWindow(void* window);
extern "C" __declspec(dllimport) void* __stdcall SelectObject(
    void* dc,
    void* object);
extern "C" __declspec(dllimport) int __stdcall SetBkMode(
    void* dc,
    int mode);
extern "C" __declspec(dllimport) unsigned long __stdcall SetTextColor(
    void* dc,
    unsigned long color);
extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* instance,
    unsigned int resource_id,
    char* text,
    int text_count);
extern "C" __declspec(dllimport) int __stdcall SetWindowTextA(
    void* window,
    const char* text);
extern "C" __declspec(dllimport) int __stdcall SendMessageA(
    void* window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall InvalidateRect(
    void* window,
    const void* rect,
    int erase);
extern "C" __declspec(dllimport) int __stdcall UpdateWindow(void* window);

#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "user32.lib")

extern void* __cdecl operator new(unsigned int bytes);
extern void __cdecl operator delete(void* block);

extern "C" void* __fastcall OtInitPositionedBitmap_RealCpp(void* bitmap);
extern "C" void __cdecl OtResizeControl_RealCpp(
    void* dialog,
    int control_id,
    int width,
    int height);
extern "C" int __cdecl OtSelectDialogCursor_0040d530_RealCpp(
    int force_busy_cursor,
    void* window);

#pragma pack(push, 1)
struct StatusRect_0041d040 {
    int left;
    int top;
    int right;
    int bottom;
};

struct StatusPaint_0041d040 {
    char data[0x40];
};

struct StatusDrawItem_0041d040 {
    unsigned int control_type;
    unsigned int control_id;
    unsigned int item_id;
    unsigned int item_action;
    unsigned int item_state;
    void* item_window;
    void* dc;
    StatusRect_0041d040 item_rect;
    unsigned long item_data;
};

struct PositionedBitmapDescriptorState_0040ba40 {
    char reserved_00[0x10];
    short left;
    short top;
    short width;
    short height;
    int left_int;
    int top_int;
    int right;
    int bottom;

    int OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        void* module,
        short descriptor_id);
};

struct PositionedBitmap_0040b7b0_Semantic {
    char data[0x28];

    int OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        void* dc,
        int source_x,
        int source_y);
};

struct PositionedBitmapFree_0040b760_42pct {
    unsigned long bitmap_info_handle;
    unsigned long indexed_pixels_handle;

    void OtFreePositionedBitmapAlt5_0040b760_42pct();
};

struct StatusDialogState_0041d040 {
    PositionedBitmap_0040b7b0_Semantic close_normal;
    PositionedBitmap_0040b7b0_Semantic close_pressed;
};

struct StatusJourneyView_0041d040 {
    char reserved_000[0xac];
    short status_string_index;
};
#pragma pack(pop)

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

static void OtSetStatusDialogBusy_0041d040(int busy)
{
    g_appBusyCursorActive_Product_004034d0 = busy;
    SetCursor(LoadCursorA(
        0,
        (const void*)(busy != 0 ? 0x7f02 : 0x7f00)));
}

static void OtDestroyStatusDialogState_0041d040(
    StatusDialogState_0041d040* state)
{
    if (state == 0) {
        return;
    }

    reinterpret_cast<PositionedBitmapFree_0040b760_42pct*>(
        &state->close_pressed)->OtFreePositionedBitmapAlt5_0040b760_42pct();
    reinterpret_cast<PositionedBitmapFree_0040b760_42pct*>(
        &state->close_normal)->OtFreePositionedBitmapAlt5_0040b760_42pct();
    operator delete(state);
}

static StatusDialogState_0041d040* OtInitializeStatusDialog_0041d040(
    void* dialog)
{
    StatusDialogState_0041d040* state =
        static_cast<StatusDialogState_0041d040*>(
            operator new(sizeof(StatusDialogState_0041d040)));

    if (state == 0) {
        return 0;
    }

    OtInitPositionedBitmap_RealCpp(&state->close_normal);
    OtInitPositionedBitmap_RealCpp(&state->close_pressed);
    reinterpret_cast<PositionedBitmapDescriptorState_0040ba40*>(
        &state->close_normal)
        ->OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603,
            0x2826);
    reinterpret_cast<PositionedBitmapDescriptorState_0040ba40*>(
        &state->close_pressed)
        ->OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603,
            0x2827);

    SetWindowLongA(dialog, 8, reinterpret_cast<long>(state));
    OtResizeControl_RealCpp(
        dialog,
        0x12c,
        reinterpret_cast<PositionedBitmapDescriptorState_0040ba40*>(
            &state->close_normal)->width,
        reinterpret_cast<PositionedBitmapDescriptorState_0040ba40*>(
            &state->close_normal)->height);
    SetFocus(GetDlgItem(dialog, 0x12c));
    SendMessageA(dialog, 0x401, 0x12c, 0);
    return state;
}

static void OtRefreshStatusDialog_0041d040(void* dialog)
{
    StatusJourneyView_0041d040* journey =
        static_cast<StatusJourneyView_0041d040*>(g_journeyState);
    char text[100];

    if (journey != 0) {
        text[0] = '\0';
        if (LoadStringA(
                g_applicationModule_00405a40_20260603,
                static_cast<unsigned int>(
                    static_cast<int>(journey->status_string_index) + 0xa0),
                text,
                sizeof(text)) != 0) {
            SetWindowTextA(GetDlgItem(dialog, 0x10cc), text);
        }
    }

    InvalidateRect(dialog, 0, 0);
    UpdateWindow(dialog);
}

static long OtDrawStatusCloseButton_0041d040(
    void* dialog,
    unsigned int control_id,
    StatusDrawItem_0041d040* draw_item)
{
    StatusDialogState_0041d040* state =
        reinterpret_cast<StatusDialogState_0041d040*>(
            GetWindowLongA(dialog, 8));
    PositionedBitmap_0040b7b0_Semantic* bitmap;

    if (state == 0 || draw_item == 0 || control_id != 0x12c) {
        return 1;
    }

    SelectPalette(draw_item->dc, g_gamePalette, 0);
    RealizePalette(draw_item->dc);
    bitmap = &state->close_normal;
    if (draw_item->control_type == 2 &&
        (draw_item->item_state & 1) != 0) {
        bitmap = &state->close_pressed;
    }
    bitmap->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        draw_item->dc,
        0,
        0);
    return 1;
}

extern "C" long __stdcall OtStatusDialogProc_0041d040_ProductWip(
    void* dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam)
{
    switch (message) {
    case 0x0002:
        OtDestroyStatusDialogState_0041d040(
            reinterpret_cast<StatusDialogState_0041d040*>(
                GetWindowLongA(dialog, 8)));
        SetWindowLongA(dialog, 8, 0);
        g_trailStatusNotifyWindow_004390d0 = 0;
        OtSetStatusDialogBusy_0041d040(0);
        return 1;

    case 0x000f: {
        StatusPaint_0041d040 paint;
        void* dc;

        OtSetStatusDialogBusy_0041d040(1);
        dc = BeginPaint(dialog, &paint);
        SelectPalette(dc, g_gamePalette, 0);
        UnrealizeObject(g_gamePalette);
        RealizePalette(dc);
        EndPaint(dialog, &paint);
        OtSetStatusDialogBusy_0041d040(0);
        return 1;
    }

    case 0x0014: {
        StatusRect_0041d040 rect;
        void* dc = reinterpret_cast<void*>(wparam);

        SelectPalette(dc, g_gamePalette, 0);
        RealizePalette(dc);
        if (GetUpdateRect(dialog, &rect, 0) != 0) {
            FillRect(dc, &rect, g_sharedDialogBackgroundBrush_004390c0);
        }
        return 1;
    }

    case 0x0020:
        return OtSelectDialogCursor_0040d530_RealCpp(
            g_appBusyCursorActive_Product_004034d0,
            reinterpret_cast<void*>(wparam));

    case 0x002b:
        return OtDrawStatusCloseButton_0041d040(
            dialog,
            wparam,
            reinterpret_cast<StatusDrawItem_0041d040*>(lparam));

    case 0x0110:
        OtSetStatusDialogBusy_0041d040(1);
        g_trailStatusNotifyWindow_004390d0 = dialog;
        OtInitializeStatusDialog_0041d040(dialog);
        OtRefreshStatusDialog_0041d040(dialog);
        OtSetStatusDialogBusy_0041d040(0);
        return 0;

    case 0x0111:
        if ((wparam & 0xffff) == 0x12c) {
            DestroyWindow(dialog);
        }
        return 1;

    case 0x0138: {
        void* dc = reinterpret_cast<void*>(wparam);
        long control_id;

        SelectPalette(dc, g_gamePalette, 0);
        RealizePalette(dc);
        SetBkMode(dc, 1);
        SetTextColor(dc, 0);
        control_id = GetWindowLongA(reinterpret_cast<void*>(lparam), -12);
        if (control_id == 0x10cc || control_id == 0x10cd ||
            control_id == 0x10ce || control_id == 0x10ef) {
            SelectObject(dc, g_optionMenuFont_004390d4_00405320);
        } else {
            SelectObject(dc, g_dialogFont_004390d8_00405320);
        }
        return reinterpret_cast<long>(
            g_sharedDialogBackgroundBrush_004390c0);
    }

    case 0x047e:
        OtRefreshStatusDialog_0041d040(dialog);
        return 1;
    }

    return 0;
}

#pragma optimize("", on)
#pragma code_seg()

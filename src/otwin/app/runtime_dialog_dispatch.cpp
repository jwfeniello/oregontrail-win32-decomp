// Product implementation of the shared message-dialog callback @ 0x00401570.
//
// The callback is still a byte-match WIP, but every path below has real C++
// behavior: Win32 calls are direct imports, bitmap resources are owned, and the
// launcher/callback state is shared with the product launcher.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include "../graphics/positioned_bitmap_descriptor_state.h"

typedef void* OtHandle_00401570;

extern "C" __declspec(dllimport) OtHandle_00401570 __stdcall BeginPaint(
    OtHandle_00401570 window,
    void* paint);
extern "C" __declspec(dllimport) int __stdcall EndPaint(
    OtHandle_00401570 window,
    const void* paint);
extern "C" __declspec(dllimport) int __stdcall GetClientRect(
    OtHandle_00401570 window,
    void* rect);
extern "C" __declspec(dllimport) int __stdcall GetWindowRect(
    OtHandle_00401570 window,
    void* rect);
extern "C" __declspec(dllimport) OtHandle_00401570 __stdcall GetParent(
    OtHandle_00401570 window);
extern "C" __declspec(dllimport) int __stdcall ClientToScreen(
    OtHandle_00401570 window,
    void* point);
extern "C" __declspec(dllimport) OtHandle_00401570 __stdcall GetDC(
    OtHandle_00401570 window);
extern "C" __declspec(dllimport) int __stdcall ReleaseDC(
    OtHandle_00401570 window,
    OtHandle_00401570 dc);
extern "C" __declspec(dllimport) long __stdcall GetWindowLongA(
    OtHandle_00401570 window,
    int index);
extern "C" __declspec(dllimport) long __stdcall SetWindowLongA(
    OtHandle_00401570 window,
    int index,
    long value);
extern "C" __declspec(dllimport) int __stdcall GetUpdateRect(
    OtHandle_00401570 window,
    void* rect,
    int erase);
extern "C" __declspec(dllimport) int __stdcall SetWindowPos(
    OtHandle_00401570 window,
    OtHandle_00401570 insert_after,
    int x,
    int y,
    int width,
    int height,
    unsigned int flags);
extern "C" __declspec(dllimport) OtHandle_00401570 __stdcall GetDlgItem(
    OtHandle_00401570 dialog,
    int control_id);
extern "C" __declspec(dllimport) int __stdcall IsWindow(
    OtHandle_00401570 window);
extern "C" __declspec(dllimport) OtHandle_00401570 __stdcall SetFocus(
    OtHandle_00401570 window);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    OtHandle_00401570 window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall SetWindowTextA(
    OtHandle_00401570 window,
    const char* text);
extern "C" __declspec(dllimport) unsigned long __stdcall GetDialogBaseUnits();
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    OtHandle_00401570 window,
    const char* text,
    const char* caption,
    unsigned int type);
extern "C" __declspec(dllimport) void __stdcall PostQuitMessage(int exit_code);
extern "C" __declspec(dllimport) int __stdcall EndDialog(
    OtHandle_00401570 dialog,
    int result);

extern "C" __declspec(dllimport) OtHandle_00401570 __stdcall SelectPalette(
    OtHandle_00401570 dc,
    OtHandle_00401570 palette,
    int force_background);
extern "C" __declspec(dllimport) unsigned int __stdcall RealizePalette(
    OtHandle_00401570 dc);
extern "C" __declspec(dllimport) int __stdcall SetBkMode(
    OtHandle_00401570 dc,
    int mode);
extern "C" __declspec(dllimport) unsigned long __stdcall SetTextColor(
    OtHandle_00401570 dc,
    unsigned long color);
extern "C" __declspec(dllimport) int __stdcall DrawTextA(
    OtHandle_00401570 dc,
    const char* text,
    int text_length,
    void* rect,
    unsigned int format);
extern "C" __declspec(dllimport) int __stdcall GetTextMetricsA(
    OtHandle_00401570 dc,
    void* metrics);
extern "C" __declspec(dllimport) OtHandle_00401570 __stdcall SelectObject(
    OtHandle_00401570 dc,
    OtHandle_00401570 object);
extern "C" __declspec(dllimport) int __stdcall FillRect(
    OtHandle_00401570 dc,
    const void* rect,
    OtHandle_00401570 brush);

#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "user32.lib")

extern void* __cdecl operator new(unsigned int bytes);
extern void __cdecl operator delete(void* block);

extern "C" void* __fastcall OtInitPositionedBitmap_RealCpp(void* bitmap);
extern "C" void __cdecl OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
    void* dialog,
    int control_id,
    int dialog_unit_width,
    int dialog_unit_height);
extern "C" void __cdecl OtResizeControl_RealCpp(
    void* dialog,
    int control_id,
    int width,
    int height);

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" void* g_gamePalette;
extern "C" void* g_optionMenuFont_004390d4_00405320;
extern "C" int g_sharedMessageDialogResult;
extern "C" void* g_sharedMessageDialogCaption;
extern "C" void* g_sharedMessageDialogText;
extern "C" int g_sharedMessageDialogUseAlternateTemplate;

// Canonical owner for the palette-derived dialog background brush at the
// original DAT_004390c0 slot. Palette initialization will supply its writer.
extern "C" void* g_sharedDialogBackgroundBrush_004390c0 = 0;

#pragma code_seg(".otsem")
extern "C" __declspec(allocate(".otsem"))
const char g_runtimeDialogAllocMessage_00401570[] =
    "Can't allocate local memory";
extern "C" __declspec(allocate(".otsem"))
const char g_runtimeDialogAllocCaption_00401570[] = "OTMsgInfo";

#pragma pack(push, 1)
struct OtRect_00401570 {
    int left;
    int top;
    int right;
    int bottom;
};

struct OtPoint_00401570 {
    int x;
    int y;
};

struct OtPaintStruct_00401570 {
    char bytes[0x40];
};

struct OtTextMetricA_00401570 {
    int height;
    char bytes[0x34];
};

struct OtBitmapInfoHeader_00401570 {
    unsigned long size;
    int width;
    int height;
    unsigned short planes;
    unsigned short bit_count;
    unsigned long compression;
    unsigned long image_size;
    int x_pixels_per_meter;
    int y_pixels_per_meter;
    unsigned long colors_used;
    unsigned long colors_important;
};

// This name intentionally matches the product blit implementation's owning
// type, allowing a normal C++ member call without a linker alias or wrapper.
struct PositionedBitmap_0040b7b0_Semantic {
    OtHandle_00401570 bitmap_info_handle;
    OtHandle_00401570 indexed_pixels_handle;
    OtBitmapInfoHeader_00401570* bitmap_info;
    unsigned char* indexed_pixels;
    short x;
    short y;
    short width;
    short height;
    int x_mirror;
    int y_mirror;
    int right;
    int bottom;

    int OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        OtHandle_00401570 dc,
        int source_x,
        int source_y);
};

struct PositionedBitmapFree_0040b760_42pct {
    void OtFreePositionedBitmapAlt5_0040b760_42pct();
};

struct PositionedBitmapDescriptorState_00401570 {
    OtHandle_00401570 bitmap_info_handle;
    OtHandle_00401570 indexed_pixels_handle;
    OtBitmapInfoHeader_00401570* bitmap_info;
    unsigned char* indexed_pixels;
    short x;
    short y;
    short width;
    short height;
    int x_mirror;
    int y_mirror;
    int right;
    int bottom;

    PositionedBitmapDescriptorState_00401570();
    ~PositionedBitmapDescriptorState_00401570();

    int LoadDescriptor(
        OtHandle_00401570 module,
        unsigned short descriptor_id);
};

struct RuntimeDialogBitmapState_00401570 {
    PositionedBitmapDescriptorState_00401570 ok_default;
    PositionedBitmapDescriptorState_00401570 ok_pressed;
    PositionedBitmapDescriptorState_00401570 yes_default;
    PositionedBitmapDescriptorState_00401570 yes_pressed;
    PositionedBitmapDescriptorState_00401570 no_default;
    PositionedBitmapDescriptorState_00401570 no_pressed;

    RuntimeDialogBitmapState_00401570();
};

#pragma pack(pop)

typedef char OtRuntimeDialogBitmapMemberSizeMustBe028[
    sizeof(PositionedBitmapDescriptorState_00401570) == 0x28 ? 1 : -1];
typedef char OtRuntimeDialogBitmapStateSizeMustBe0f0[
    sizeof(RuntimeDialogBitmapState_00401570) == 0xf0 ? 1 : -1];

#pragma optimize("s", off)
#pragma optimize("t", on)
#pragma code_seg(".otsem")

PositionedBitmapDescriptorState_00401570::
    PositionedBitmapDescriptorState_00401570()
{
    OtInitPositionedBitmap_RealCpp(this);
}

PositionedBitmapDescriptorState_00401570::
    ~PositionedBitmapDescriptorState_00401570()
{
    reinterpret_cast<PositionedBitmapFree_0040b760_42pct*>(this)->
        OtFreePositionedBitmapAlt5_0040b760_42pct();
}

RuntimeDialogBitmapState_00401570::
    RuntimeDialogBitmapState_00401570()
{
    // The six members perform their own resource-safe initialization.
}

int PositionedBitmapDescriptorState_00401570::LoadDescriptor(
    OtHandle_00401570 module,
    unsigned short descriptor_id)
{
    return reinterpret_cast<PositionedBitmapDescriptorState_0040ba40*>(this)->
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            module,
            static_cast<short>(descriptor_id));
}

#pragma inline_depth(255)

static __inline void OtRuntimeDialogBlitButton_00401570(
    PositionedBitmapDescriptorState_00401570* bitmap,
    OtHandle_00401570 dc)
{
    ((PositionedBitmap_0040b7b0_Semantic*)bitmap)->
        OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
}

static __inline long OtRuntimeDialogPaint_00401570(
    OtHandle_00401570 dialog)
{
    OtHandle_00401570 dc;
    OtPaintStruct_00401570 paint;
    OtRect_00401570 client_rect;

    dc = BeginPaint(dialog, &paint);
    GetClientRect(dialog, &client_rect);
    client_rect.left += 0x0c;
    client_rect.top += 0x0c;
    client_rect.right -= 0x0c;
    SetBkMode(dc, 1);
    SetTextColor(dc, 0);
    DrawTextA(
        dc,
        (const char*)g_sharedMessageDialogText,
        -1,
        &client_rect,
        g_sharedMessageDialogUseAlternateTemplate | 0x0110);
    EndPaint(dialog, &paint);
    return 1;
}

static __inline long OtRuntimeDialogErase_00401570(
    OtHandle_00401570 dialog,
    OtHandle_00401570 dc)
{
    OtRect_00401570 rect;

    SelectPalette(dc, g_gamePalette, 0);
    RealizePalette(dc);
    if (GetUpdateRect(dialog, &rect, 0) != 0) {
        FillRect(dc, &rect, g_sharedDialogBackgroundBrush_004390c0);
    }
    return 1;
}

static __inline long OtRuntimeDialogDrawButton_00401570(
    OtHandle_00401570 dialog,
    unsigned int control_id,
    long draw_item)
{
    RuntimeDialogBitmapState_00401570* state;
    OtHandle_00401570 dc;

    state = (RuntimeDialogBitmapState_00401570*)
        GetWindowLongA(dialog, 8);
    dc = *(OtHandle_00401570*)(draw_item + 0x18);
    SelectPalette(dc, g_gamePalette, 0);

    if (*(int*)(draw_item + 0x0c) == 1) {
        if (control_id == 0x012c) {
            OtRuntimeDialogBlitButton_00401570(&state->ok_default, dc);
        } else if (control_id == 0x0134) {
            OtRuntimeDialogBlitButton_00401570(&state->yes_default, dc);
        } else if (control_id == 0x0135) {
            OtRuntimeDialogBlitButton_00401570(&state->no_default, dc);
        }
        return 1;
    }

    if (*(int*)(draw_item + 0x0c) != 2) {
        return 1;
    }

    if ((*(unsigned char*)(draw_item + 0x10) & 1) != 0) {
        if (control_id == 0x012c) {
            OtRuntimeDialogBlitButton_00401570(&state->ok_pressed, dc);
        } else if (control_id == 0x0134) {
            OtRuntimeDialogBlitButton_00401570(&state->yes_pressed, dc);
        } else if (control_id == 0x0135) {
            OtRuntimeDialogBlitButton_00401570(&state->no_pressed, dc);
        }
        return 1;
    }

    if (control_id == 0x012c) {
        OtRuntimeDialogBlitButton_00401570(&state->ok_default, dc);
    } else if (control_id == 0x0134) {
        OtRuntimeDialogBlitButton_00401570(&state->yes_default, dc);
    } else if (control_id == 0x0135) {
        OtRuntimeDialogBlitButton_00401570(&state->no_default, dc);
    }
    return 1;
}

static __inline long OtRuntimeDialogCommand_00401570(
    OtHandle_00401570 dialog,
    unsigned int command)
{
    switch (command & 0xffff) {
    case 0x012c:
        EndDialog(dialog, 0);
        g_sharedMessageDialogResult = 1;
        return 1;
    case 0x0134:
        EndDialog(dialog, 0);
        g_sharedMessageDialogResult = 6;
        return 1;
    case 0x0135:
        EndDialog(dialog, 0);
        g_sharedMessageDialogResult = 7;
        return 1;
    default:
        return 0;
    }
}

static __inline long OtRuntimeDialogColor_00401570(
    OtHandle_00401570 dc)
{
    SelectPalette(dc, g_gamePalette, 0);
    RealizePalette(dc);
    SetBkMode(dc, 1);
    SetTextColor(dc, 0);
    SelectObject(dc, g_optionMenuFont_004390d4_00405320);
    return (long)g_sharedDialogBackgroundBrush_004390c0;
}

extern "C" long __stdcall OtSharedMessageDialogProcDependency_00401570(
    OtHandle_00401570 dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam)
{
    RuntimeDialogBitmapState_00401570* state;

    switch (message) {
    case 0x0002:
        state = (RuntimeDialogBitmapState_00401570*)
            GetWindowLongA(dialog, 8);
        if (state != 0) {
            delete state;
        }
        return 1;

    case 0x000f:
        return OtRuntimeDialogPaint_00401570(dialog);

    case 0x0014:
        return OtRuntimeDialogErase_00401570(
            dialog,
            (OtHandle_00401570)wparam);

    case 0x002b:
        return OtRuntimeDialogDrawButton_00401570(
            dialog,
            wparam,
            lparam);

    case 0x0110: {
        OtHandle_00401570 dc;
        OtHandle_00401570 control;
        unsigned long dialog_units;
        int dialog_unit_width;
        int dialog_unit_height;
        int text_height;
        OtRect_00401570 window_rect;
        OtRect_00401570 parent_rect;
        OtRect_00401570 client_rect;
        OtRect_00401570 draw_rect;
        OtRect_00401570 control_rect;
        OtPoint_00401570 center;
        OtTextMetricA_00401570 metrics;

        GetWindowRect(dialog, &window_rect);
        GetClientRect(GetParent(dialog), &parent_rect);
        center.x = parent_rect.left +
            (parent_rect.right - parent_rect.left) / 2;
        center.y = parent_rect.top +
            (parent_rect.bottom - parent_rect.top) / 2;
        ClientToScreen(GetParent(dialog), &center);

        dc = GetDC(dialog);
        GetClientRect(dialog, &client_rect);
        draw_rect.left = 0x0c;
        draw_rect.top = 0x0c;
        draw_rect.right = client_rect.right - 0x0c;
        text_height = DrawTextA(
            dc,
            (const char*)g_sharedMessageDialogText,
            -1,
            &draw_rect,
            0x0411);
        GetTextMetricsA(dc, &metrics);
        g_sharedMessageDialogUseAlternateTemplate =
            (text_height <= metrics.height * 3);
        window_rect.bottom += text_height + 0x0c;
        ReleaseDC(dialog, dc);

        SetWindowPos(
            dialog,
            0,
            center.x + (window_rect.left - window_rect.right) / 2,
            center.y + (window_rect.top - window_rect.bottom) / 2,
            window_rect.right - window_rect.left,
            window_rect.bottom - window_rect.top,
            4);

        GetClientRect(dialog, &client_rect);
        SetWindowTextA(dialog, (const char*)g_sharedMessageDialogCaption);
        dialog_units = GetDialogBaseUnits();
        dialog_unit_width = (unsigned short)dialog_units;
        dialog_unit_height = (unsigned short)(GetDialogBaseUnits() >> 16);

        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog,
            0x012c,
            dialog_unit_width,
            dialog_unit_height);
        control = GetDlgItem(dialog, 0x012c);
        if (IsWindow(control) != 0) {
            GetClientRect(control, &control_rect);
            SetWindowPos(
                control,
                0,
                (client_rect.right - control_rect.right) / 2,
                client_rect.bottom - control_rect.bottom - 0x0c,
                0,
                0,
                1);
            SetFocus(GetDlgItem(dialog, 0x012c));
            SendMessageA(dialog, 0x0401, 0x012c, 0);
        }

        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog,
            0x0134,
            dialog_unit_width,
            dialog_unit_height);
        control = GetDlgItem(dialog, 0x0134);
        if (IsWindow(control) != 0) {
            GetClientRect(control, &control_rect);
            SetWindowPos(
                control,
                0,
                (client_rect.right / 2) -
                    ((control_rect.right +
                        ((control_rect.right >> 31) & 3)) >> 2) -
                    control_rect.right,
                client_rect.bottom - control_rect.bottom - 0x0c,
                0,
                0,
                1);
        }

        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog,
            0x0135,
            dialog_unit_width,
            dialog_unit_height);
        control = GetDlgItem(dialog, 0x0135);
        if (IsWindow(control) != 0) {
            GetClientRect(control, &control_rect);
            SetWindowPos(
                control,
                0,
                ((control_rect.right +
                    ((control_rect.right >> 31) & 3)) >> 2) +
                    client_rect.right / 2,
                client_rect.bottom - control_rect.bottom - 0x0c,
                0,
                0,
                1);
        }

        state = new RuntimeDialogBitmapState_00401570;
        if (state == 0) {
            MessageBoxA(
                GetParent(dialog),
                g_runtimeDialogAllocMessage_00401570,
                g_runtimeDialogAllocCaption_00401570,
                0);
            PostQuitMessage(0);
            return 0;
        }
        state->yes_default.LoadDescriptor(g_applicationModule_00405a40_20260603, 0x2849);
        state->yes_pressed.LoadDescriptor(g_applicationModule_00405a40_20260603, 0x284a);
        state->no_default.LoadDescriptor(g_applicationModule_00405a40_20260603, 0x284b);
        state->no_pressed.LoadDescriptor(g_applicationModule_00405a40_20260603, 0x284c);
        state->ok_default.LoadDescriptor(g_applicationModule_00405a40_20260603, 0x2826);
        state->ok_pressed.LoadDescriptor(g_applicationModule_00405a40_20260603, 0x2827);

        SetWindowLongA(dialog, 8, (long)state);
        OtResizeControl_RealCpp(
            dialog,
            0x012c,
            state->ok_default.width,
            state->ok_default.height);
        OtResizeControl_RealCpp(
            dialog,
            0x0135,
            state->no_default.width,
            state->no_default.height);
        OtResizeControl_RealCpp(
            dialog,
            0x0134,
            state->yes_default.width,
            state->yes_default.height);
        return 0;
    }

    case 0x0111:
        return OtRuntimeDialogCommand_00401570(dialog, wparam);

    case 0x0136:
    case 0x0138:
        return OtRuntimeDialogColor_00401570(
            (OtHandle_00401570)wparam);

    default:
        return 0;
    }
}

#pragma code_seg()
#pragma optimize("", on)

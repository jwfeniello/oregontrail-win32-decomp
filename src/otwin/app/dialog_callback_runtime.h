#ifndef OTWIN_DIALOG_CALLBACK_RUNTIME_H
#define OTWIN_DIALOG_CALLBACK_RUNTIME_H

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This Product dialog runtime requires 32-bit Microsoft C++."
#endif

#include "../graphics/positioned_bitmap_descriptor_state.h"

typedef void* OtDialogHandle_Product;
typedef void* OtDialogDeviceContext_Product;

#pragma pack(push, 1)
struct OtDialogRect_Product {
    long left;
    long top;
    long right;
    long bottom;
};

struct OtDialogPoint_Product {
    long x;
    long y;
};

struct OtDialogPaintStruct_Product {
    OtDialogDeviceContext_Product dc;
    int erase_background;
    OtDialogRect_Product paint_rect;
    int restore;
    int update_region_changed;
    unsigned char reserved[32];
};

struct OtDialogDrawItem_Product {
    unsigned int control_type;
    unsigned int control_id;
    unsigned int item_id;
    unsigned int item_action;
    unsigned int item_state;
    OtDialogHandle_Product control;
    OtDialogDeviceContext_Product dc;
    OtDialogRect_Product rect;
    unsigned long item_data;
};
#pragma pack(pop)

typedef char OtDialogPaintStructSizeMustBe40[
    sizeof(OtDialogPaintStruct_Product) == 0x40 ? 1 : -1];
typedef char OtDialogDrawItemSizeMustBe30[
    sizeof(OtDialogDrawItem_Product) == 0x30 ? 1 : -1];

extern "C" __declspec(dllimport) OtDialogDeviceContext_Product __stdcall
BeginPaint(OtDialogHandle_Product window, OtDialogPaintStruct_Product* paint);
extern "C" __declspec(dllimport) int __stdcall EndPaint(
    OtDialogHandle_Product window,
    const OtDialogPaintStruct_Product* paint);
extern "C" __declspec(dllimport) int __stdcall GetClientRect(
    OtDialogHandle_Product window,
    OtDialogRect_Product* rect);
extern "C" __declspec(dllimport) int __stdcall FillRect(
    OtDialogDeviceContext_Product dc,
    const OtDialogRect_Product* rect,
    void* brush);
extern "C" __declspec(dllimport) void* __stdcall SelectPalette(
    OtDialogDeviceContext_Product dc,
    void* palette,
    int force_background);
extern "C" __declspec(dllimport) int __stdcall UnrealizeObject(void* object);
extern "C" __declspec(dllimport) unsigned int __stdcall RealizePalette(
    OtDialogDeviceContext_Product dc);
extern "C" __declspec(dllimport) void* __stdcall SelectObject(
    OtDialogDeviceContext_Product dc,
    void* object);
extern "C" __declspec(dllimport) int __stdcall SetBkMode(
    OtDialogDeviceContext_Product dc,
    int mode);
extern "C" __declspec(dllimport) unsigned long __stdcall SetTextColor(
    OtDialogDeviceContext_Product dc,
    unsigned long color);
extern "C" __declspec(dllimport) void* __stdcall LoadCursorA(
    void* instance,
    const void* cursor_name);
extern "C" __declspec(dllimport) void* __stdcall SetCursor(void* cursor);

#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")

extern "C" void* g_gamePalette;
extern "C" void* g_sharedDialogBackgroundBrush_004390c0;
extern "C" void* g_optionMenuFont_004390d4_00405320;
extern "C" void* g_dialogFont_004390d8_00405320;
extern "C" int g_appBusyCursorActive_Product_004034d0;
extern "C" OtDialogHandle_Product g_activeScreenDialogWindow_00404dd0;

struct PositionedBitmap_0040b7b0_Semantic {
    int OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        OtDialogDeviceContext_Product dc,
        int source_x,
        int source_y);
};

static void OtSetDialogBusyCursor_Product()
{
    g_appBusyCursorActive_Product_004034d0 = 1;
    SetCursor(LoadCursorA(0, (const void*)0x7f02));
}

static void OtRestoreDialogArrowCursor_Product()
{
    g_appBusyCursorActive_Product_004034d0 = 0;
    SetCursor(LoadCursorA(0, (const void*)0x7f00));
}

static void OtSelectDialogPalette_Product(OtDialogDeviceContext_Product dc)
{
    SelectPalette(dc, g_gamePalette, 0);
    RealizePalette(dc);
}

static int OtBlitDialogBitmap_Product(
    PositionedBitmapDescriptorState_0040ba40* bitmap,
    OtDialogDeviceContext_Product dc)
{
    return reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(bitmap)->
        OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
}

static int OtDrawOwnedBitmapButton_Product(
    OtDialogDrawItem_Product* draw,
    PositionedBitmapDescriptorState_0040ba40* normal_bitmap,
    PositionedBitmapDescriptorState_0040ba40* pressed_bitmap)
{
    PositionedBitmapDescriptorState_0040ba40* bitmap = normal_bitmap;

    OtSelectDialogPalette_Product(draw->dc);
    if ((draw->item_state & 1) != 0) {
        bitmap = pressed_bitmap;
    }
    OtBlitDialogBitmap_Product(bitmap, draw->dc);
    return 1;
}

static void OtPaintDialogBackground_Product(
    OtDialogHandle_Product dialog,
    PositionedBitmapDescriptorState_0040ba40* background,
    void* fill_brush)
{
    OtDialogPaintStruct_Product paint;
    OtDialogRect_Product rect;
    OtDialogDeviceContext_Product dc = BeginPaint(dialog, &paint);

    SelectPalette(dc, g_gamePalette, 0);
    UnrealizeObject(g_gamePalette);
    RealizePalette(dc);
    GetClientRect(dialog, &rect);
    if (fill_brush != 0) {
        FillRect(dc, &rect, fill_brush);
    }
    if (background != 0) {
        OtBlitDialogBitmap_Product(background, dc);
    }
    EndPaint(dialog, &paint);
}

static long OtPrepareDialogControlColor_Product(
    OtDialogDeviceContext_Product dc,
    void* font,
    unsigned long text_color)
{
    OtSelectDialogPalette_Product(dc);
    if (font != 0) {
        SelectObject(dc, font);
    }
    SetBkMode(dc, 1);
    SetTextColor(dc, text_color);
    return reinterpret_cast<long>(g_sharedDialogBackgroundBrush_004390c0);
}

#endif

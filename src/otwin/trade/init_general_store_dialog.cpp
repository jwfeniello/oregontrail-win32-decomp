// Product-semantic recovery of OtInitGeneralStoreDialog at 0x00408ca0.
//
// The initializer sizes the modeless store to its parent, populates its
// controls, allocates the dialog-owned bitmap state, loads the route-specific
// artwork, stores that state on the window, and sizes the owner-drawn buttons.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This Product source must be compiled with 32-bit Microsoft C++."
#endif

#include <stddef.h>

#include "general_store_dialog_state.h"

typedef void* OtGeneralStoreHandle_00408ca0;

struct OtGeneralStoreRect_00408ca0 {
    long left;
    long top;
    long right;
    long bottom;
};

extern "C" __declspec(dllimport) OtGeneralStoreHandle_00408ca0 __stdcall
GetParent(OtGeneralStoreHandle_00408ca0 window);
extern "C" __declspec(dllimport) int __stdcall GetClientRect(
    OtGeneralStoreHandle_00408ca0 window,
    OtGeneralStoreRect_00408ca0* rect);
extern "C" __declspec(dllimport) int __stdcall SetWindowPos(
    OtGeneralStoreHandle_00408ca0 window,
    OtGeneralStoreHandle_00408ca0 insert_after,
    int x,
    int y,
    int width,
    int height,
    unsigned int flags);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    OtGeneralStoreHandle_00408ca0 owner,
    const char* text,
    const char* caption,
    unsigned int type);
extern "C" __declspec(dllimport) void __stdcall PostQuitMessage(
    int exit_code);
extern "C" __declspec(dllimport) long __stdcall SetWindowLongA(
    OtGeneralStoreHandle_00408ca0 window,
    int index,
    long value);

#pragma comment(lib, "user32.lib")

extern void* __cdecl operator new(unsigned int bytes);

#pragma pack(push, 1)
struct GeneralStoreRouteDescriptor_00408ca0_Product {
    short landmark_id;
    short route_stop_kind;
    short store_price_percent;
    char reserved_006[0x12a];
    unsigned short store_backdrop_bitmap_resource_id;
};
#pragma pack(pop)

typedef char OtGeneralStoreStateSizeMustBe128_00408ca0[
    sizeof(GeneralStoreDialogState_00407340_Product) == 0x128 ? 1 : -1];
typedef char OtGeneralStoreBackdropOffsetMustBe118_00408ca0[
    offsetof(GeneralStoreDialogState_00407340_Product, backdrop_fill_rect) ==
            0x118
        ? 1
        : -1];
typedef char OtGeneralStoreRouteBitmapOffsetMustBe130_00408ca0[
    offsetof(
        GeneralStoreRouteDescriptor_00408ca0_Product,
        store_backdrop_bitmap_resource_id) == 0x130
        ? 1
        : -1];

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" void* g_resourceModule;
extern "C" GeneralStoreRouteDescriptor_00408ca0_Product*
    g_activeRouteDescriptor;
extern "C" const char g_welcomeAllocationMessage_00415d30[];
extern "C" const char g_welcomeAllocationCaption_00415d30[];

extern "C" void __cdecl OtLayoutGeneralStoreControls_00408f80_RealCpp(
    OtGeneralStoreHandle_00408ca0 dialog,
    int show_ok_button);
extern "C" void __cdecl OtPopulateGeneralStoreForm_00407a10_ProductWip(
    OtGeneralStoreHandle_00408ca0 dialog,
    int show_capacity_limits);
extern "C" void __cdecl OtRecalculateGeneralStoreTotals_00409560_Product(
    OtGeneralStoreHandle_00408ca0 dialog);
extern "C" void __cdecl OtResizeControl_RealCpp(
    OtGeneralStoreHandle_00408ca0 dialog,
    int control_id,
    int width,
    int height);

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" void __cdecl OtInitGeneralStoreDialog_00408ca0_ProductWip(
    OtGeneralStoreHandle_00408ca0 dialog,
    int show_capacity_limits)
{
    OtGeneralStoreRect_00408ca0 parent_rect;
    GeneralStoreDialogState_00407340_Product* state;

    GetClientRect(GetParent(dialog), &parent_rect);
    int x = parent_rect.left + 10;
    int y = parent_rect.top + 10;
    SetWindowPos(
        dialog,
        0,
        x,
        y,
        parent_rect.right - parent_rect.left - 20,
        parent_rect.bottom - parent_rect.top - 20,
        4);

    OtLayoutGeneralStoreControls_00408f80_RealCpp(
        dialog,
        show_capacity_limits);
    OtPopulateGeneralStoreForm_00407a10_ProductWip(
        dialog,
        show_capacity_limits);
    OtRecalculateGeneralStoreTotals_00409560_Product(dialog);

    state = new GeneralStoreDialogState_00407340_Product;
    if (state == 0) {
        MessageBoxA(
            GetParent(dialog),
            g_welcomeAllocationMessage_00415d30,
            g_welcomeAllocationCaption_00415d30,
            0);
        PostQuitMessage(0);
        return;
    }

    state->information_default.
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        g_applicationModule_00405a40_20260603,
        0x2808);
    state->information_pressed.
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        g_applicationModule_00405a40_20260603,
        0x2809);
    state->buy_default.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        g_applicationModule_00405a40_20260603,
        0x282a);
    state->buy_pressed.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        g_applicationModule_00405a40_20260603,
        0x282b);
    state->leave_default.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        g_applicationModule_00405a40_20260603,
        0x2828);
    state->leave_pressed.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        g_applicationModule_00405a40_20260603,
        0x2829);
    state->dialog_backdrop.
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        g_resourceModule,
        0x5dd);
    state->dialog_backdrop.
        OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
        g_resourceModule,
        g_activeRouteDescriptor->store_backdrop_bitmap_resource_id,
        0,
        0,
        0,
        0);
    state->backdrop_fill_rect.OtLoadRectFromResource_RealCpp(
        g_resourceModule,
        (const void*)0x5de);

    SetWindowLongA(dialog, 8, (long)state);
    OtResizeControl_RealCpp(
        dialog,
        0x131,
        state->information_default.width,
        state->information_default.height);
    OtResizeControl_RealCpp(
        dialog,
        0x139,
        state->buy_default.width,
        state->buy_default.height);
    OtResizeControl_RealCpp(
        dialog,
        0x12d,
        state->leave_default.width,
        state->leave_default.height);
}

#pragma optimize("", on)
#pragma code_seg()

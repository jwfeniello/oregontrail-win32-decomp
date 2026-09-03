// Product-reachable semantic DLGPROC for OtHuntResultsDialogProc @ 0x004023b0.

#include "../app/dialog_callback_runtime.h"

extern "C" __declspec(dllimport) long __stdcall GetWindowLongA(
    OtDialogHandle_Product window,
    int index);
extern "C" __declspec(dllimport) long __stdcall SetWindowLongA(
    OtDialogHandle_Product window,
    int index,
    long value);
extern "C" __declspec(dllimport) int __stdcall GetWindowRect(
    OtDialogHandle_Product window,
    OtDialogRect_Product* rect);
extern "C" __declspec(dllimport) int __stdcall GetUpdateRect(
    OtDialogHandle_Product window,
    OtDialogRect_Product* rect,
    int erase);
extern "C" __declspec(dllimport) OtDialogHandle_Product __stdcall GetParent(
    OtDialogHandle_Product window);
extern "C" __declspec(dllimport) int __stdcall ClientToScreen(
    OtDialogHandle_Product window,
    OtDialogPoint_Product* point);
extern "C" __declspec(dllimport) int __stdcall SetWindowPos(
    OtDialogHandle_Product window,
    OtDialogHandle_Product insert_after,
    int x,
    int y,
    int width,
    int height,
    unsigned int flags);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    OtDialogHandle_Product window,
    const char* text,
    const char* caption,
    unsigned int type);
extern "C" __declspec(dllimport) void __stdcall PostQuitMessage(int exit_code);
extern "C" __declspec(dllimport) OtDialogHandle_Product __stdcall GetDlgItem(
    OtDialogHandle_Product dialog,
    int control_id);
extern "C" __declspec(dllimport) OtDialogHandle_Product __stdcall SetFocus(
    OtDialogHandle_Product window);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    OtDialogHandle_Product window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall EndDialog(
    OtDialogHandle_Product dialog,
    int result);

extern "C" void* g_applicationModule_00405a40_20260603;
extern void* __cdecl operator new(unsigned int bytes);
extern void __cdecl operator delete(void* block);

extern "C" void __cdecl OtResizeControl_RealCpp(
    OtDialogHandle_Product dialog,
    int control_id,
    int width,
    int height);
extern "C" void __cdecl OtPaintHuntResultsText_000027b0_Product(
    OtDialogHandle_Product dialog,
    const void* result_state);

#pragma pack(push, 1)
/*
 * Keep this owner implicit in the callback.  Under VC4 /GX the two member
 * lifetimes expand at the new/delete sites, including the original normal
 * and constructor-unwind cleanup funclets.
 */
struct HuntResultsDialogInlineState_004023b0_Product {
    PositionedBitmapDescriptorState_0040ba40 continue_up;
    PositionedBitmapDescriptorState_0040ba40 continue_down;
    const void* result_state;
};
#pragma pack(pop)

typedef char OtHuntResultsStateSizeMustBe54[
    sizeof(HuntResultsDialogInlineState_004023b0_Product) == 0x54 ? 1 : -1];
typedef char OtHuntResultsDownOffsetMustBe28[
    (unsigned int)&(
        ((HuntResultsDialogInlineState_004023b0_Product*)0)->
            continue_down) == 0x28
        ? 1
        : -1];
typedef char OtHuntResultsResultOffsetMustBe50[
    (unsigned int)&(
        ((HuntResultsDialogInlineState_004023b0_Product*)0)->
            result_state) == 0x50
        ? 1
        : -1];

static const char g_huntResultsAllocationText_004023b0[] =
    "Unable to allocate dialog information.";
static const char g_huntResultsAllocationCaption_004023b0[] =
    "HuntResultsDlgProc";

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" int __stdcall OtHuntResultsDialogProc_000023b0_Wip(
    OtDialogHandle_Product dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam)
{
    HuntResultsDialogInlineState_004023b0_Product* state;
    OtDialogRect_Product dialog_rect;
    OtDialogPoint_Product center;
    OtDialogRect_Product parent_rect;

    switch (message) {
    default:
    hunt_results_default_return:
        return 0;

    case 0x000f:
        state = reinterpret_cast<
            HuntResultsDialogInlineState_004023b0_Product*>(
                GetWindowLongA(dialog, 8));
        OtPaintHuntResultsText_000027b0_Product(
            dialog,
            state->result_state);
        return 1;

    case 0x0002:
        state = reinterpret_cast<
            HuntResultsDialogInlineState_004023b0_Product*>(
                GetWindowLongA(dialog, 8));
        if (state != 0) {
            delete state;
        }
        goto hunt_results_default_return;

    case 0x0014:
        {
            OtDialogDeviceContext_Product dc =
                reinterpret_cast<OtDialogDeviceContext_Product>(wparam);

            SelectPalette(dc, g_gamePalette, 0);
            RealizePalette(dc);
            if (GetUpdateRect(dialog, &dialog_rect, 0) != 0) {
                FillRect(
                    dc,
                    &dialog_rect,
                    g_sharedDialogBackgroundBrush_004390c0);
            }
            return 1;
        }

    case 0x002b:
        {
            OtDialogDrawItem_Product* draw =
                reinterpret_cast<OtDialogDrawItem_Product*>(lparam);

            state = reinterpret_cast<
                HuntResultsDialogInlineState_004023b0_Product*>(
                    GetWindowLongA(dialog, 8));
            SelectPalette(draw->dc, g_gamePalette, 0);
            RealizePalette(draw->dc);

            switch (draw->item_action) {
            case 1:
                if (wparam == 300) {
                    reinterpret_cast<
                        PositionedBitmap_0040b7b0_Semantic*>(
                            &state->continue_up)->
                                OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                                    draw->dc,
                                    0,
                                    0);
                }
                break;

            case 2:
                if ((draw->item_state & 1) != 0) {
                    if (wparam == 300) {
                        reinterpret_cast<
                            PositionedBitmap_0040b7b0_Semantic*>(
                                &state->continue_down)->
                                    OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                                        draw->dc,
                                        0,
                                        0);
                    }
                } else if (wparam == 300) {
                    reinterpret_cast<
                        PositionedBitmap_0040b7b0_Semantic*>(
                            &state->continue_up)->
                                OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                                    draw->dc,
                                    0,
                                    0);
                }
                break;

            default:
                break;
            }
            return 1;
        }

    case 0x0110:
        {
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

            state = new HuntResultsDialogInlineState_004023b0_Product;
            if (state == 0) {
                MessageBoxA(
                    GetParent(dialog),
                    g_huntResultsAllocationText_004023b0,
                    g_huntResultsAllocationCaption_004023b0,
                    0);
                PostQuitMessage(0);
                goto hunt_results_default_return;
            }

            state->result_state = reinterpret_cast<const void*>(lparam);
            state->continue_up.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603,
                    0x2826);
            state->continue_down.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603,
                    0x2827);
            OtResizeControl_RealCpp(
                dialog,
                300,
                state->continue_up.width,
                state->continue_up.height);
            SetWindowLongA(dialog, 8, reinterpret_cast<long>(state));
            SetFocus(GetDlgItem(dialog, 300));
            SendMessageA(dialog, 0x0401, 300, 0);
            goto hunt_results_default_return;
        }

    case 0x0111:
        if ((wparam & 0xffff) == 300) {
            EndDialog(dialog, 0);
            return 1;
        }
        goto hunt_results_default_return;

    case 0x0136:
        {
            OtDialogDeviceContext_Product dc =
                reinterpret_cast<OtDialogDeviceContext_Product>(wparam);

            SelectPalette(dc, g_gamePalette, 0);
            RealizePalette(dc);
            SetBkMode(dc, 1);
            SetTextColor(dc, 0);
            SelectObject(dc, g_optionMenuFont_004390d4_00405320);
            return reinterpret_cast<int>(
                g_sharedDialogBackgroundBrush_004390c0);
        }
    }
}

#pragma optimize("", on)

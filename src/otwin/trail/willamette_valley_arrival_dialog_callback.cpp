// Ignored, hash-bound source-shape proposal only.  This file is not part of
// the Product graph.  A bounded trial should replace the complete contents of
// src/otwin/trail/willamette_valley_arrival_dialog_callback.cpp with this
// source, then use the normal generated-plan/runner path.

#include "../app/dialog_callback_runtime.h"

extern "C" __declspec(dllimport) long __stdcall GetWindowLongA(
    OtDialogHandle_Product window,
    int index);
extern "C" __declspec(dllimport) long __stdcall SetWindowLongA(
    OtDialogHandle_Product window,
    int index,
    long value);
extern "C" __declspec(dllimport) OtDialogHandle_Product __stdcall GetParent(
    OtDialogHandle_Product window);
extern "C" __declspec(dllimport) unsigned int __stdcall GetDialogBaseUnits();
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
extern "C" __declspec(dllimport) int __stdcall PostMessageA(
    OtDialogHandle_Product window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall DestroyWindow(
    OtDialogHandle_Product window);

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" int g_cdMediaMode_00439108;
extern "C" int g_titleThemeEnabled_004390ec;

extern "C" void __cdecl
OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
    OtDialogHandle_Product dialog,
    int control_id,
    int dialog_unit_width,
    int dialog_unit_height);
extern "C" void __cdecl OtResizeControl_RealCpp(
    OtDialogHandle_Product dialog,
    int control_id,
    int width,
    int height);
extern "C" int __cdecl OtSelectDialogCursor_0040d530_RealCpp(
    int busy,
    OtDialogHandle_Product window);
extern "C" void __cdecl OtOpenMidiAudioFileMaskClosed_0000cd60_RealCpp(
    OtDialogHandle_Product owner,
    const char* path);
extern "C" void __cdecl OtPlayMidiAudio_0000ced0_RealCpp(int restart);
extern "C" void __cdecl OtOpenWaveAudioFile_0000d110_RealCpp(
    OtDialogHandle_Product owner,
    const char* path);
extern "C" void __cdecl OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();
extern "C" void __cdecl OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();
extern "C" void __cdecl OtCloseWaveAudioDevice_0040d0a0_RealCpp();
extern "C" void __cdecl OtStopMidiAudioDirectImport_0040d010_RealCpp();
extern "C" void __cdecl OtStopWaveAudioDirectImport_0040d480_RealCpp();

#pragma pack(push, 1)
struct BeveledRect_0000b4c0 {
    int left;
    int top;
    int right;
    int bottom;

    void OtDrawBeveledRect_0000b4c0_RealCpp(void* dc);
};

// A callback-specific owner is intentional for this recovery: its inline empty
// constructor lets VC4 lower the three member constructions and /GX cleanup
// graph inside the callback envelope.  The already accepted canonical owner
// and its three independently matched cleanup thunks remain untouched in
// construct_dialog_bitmap_owner_states.cpp.
struct WillametteValleyArrivalDialogState_0040fee0_InlineProduct {
    PositionedBitmapDescriptorState_0040ba40 continue_up;
    PositionedBitmapDescriptorState_0040ba40 continue_down;
    PositionedBitmapDescriptorState_0040ba40 arrival_background;

    WillametteValleyArrivalDialogState_0040fee0_InlineProduct()
    {
    }
};
#pragma pack(pop)

typedef char OtWillametteArrivalInlineStateSizeMustBe78[
    sizeof(WillametteValleyArrivalDialogState_0040fee0_InlineProduct) == 0x78
        ? 1
        : -1];
typedef char OtWillametteArrivalBeveledRectSizeMustBe10[
    sizeof(BeveledRect_0000b4c0) == 0x10 ? 1 : -1];

static const char g_willametteArrivalMidi_0040fee0[] = "land18.mid";
static const char g_willametteArrivalWave_0040fee0[] = "land18.wav";
static const char g_willametteArrivalAllocationText_0040fee0[] =
    "Unable to allocate dialog information.";
static const char g_willametteArrivalAllocationCaption_0040fee0[] =
    "WillVallDlgProc";

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" int __stdcall
OtWillametteValleyArrivalDialogProc_0000fee0_Wip(
    OtDialogHandle_Product dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam)
{
    switch (message) {
    case 0x0002:
        {
            WillametteValleyArrivalDialogState_0040fee0_InlineProduct* state =
                reinterpret_cast<
                    WillametteValleyArrivalDialogState_0040fee0_InlineProduct*>(
                        GetWindowLongA(dialog, 8));
            if (state != 0) {
                delete state;
            }
            if (g_titleThemeEnabled_004390ec != 0) {
                if (g_cdMediaMode_00439108 == 0) {
                    OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();
                } else {
                    OtCloseWaveAudioDevice_0040d0a0_RealCpp();
                }
            }
        }
        return 1;

    case 0x000f:
        {
            RectResource_0040b690 background_rect;
            OtDialogPaintStruct_Product paint;
            OtDialogDeviceContext_Product dc;
            WillametteValleyArrivalDialogState_0040fee0_InlineProduct* state;

            g_appBusyCursorActive_Product_004034d0 = 1;
            SetCursor(LoadCursorA(0, reinterpret_cast<const void*>(0x7f02)));
            dc = BeginPaint(dialog, &paint);
            SelectPalette(dc, g_gamePalette, 0);
            UnrealizeObject(g_gamePalette);
            RealizePalette(dc);
            SelectObject(dc, g_optionMenuFont_004390d4_00405320);
            state = reinterpret_cast<
                WillametteValleyArrivalDialogState_0040fee0_InlineProduct*>(
                    GetWindowLongA(dialog, 8));
            reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                &state->arrival_background)->
                OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
            background_rect.OtLoadRectFromResource_RealCpp(
                g_applicationModule_00405a40_20260603,
                reinterpret_cast<const void*>(0x445d));
            FillRect(
                dc,
                reinterpret_cast<const OtDialogRect_Product*>(
                    &background_rect),
                g_sharedDialogBackgroundBrush_004390c0);
            reinterpret_cast<BeveledRect_0000b4c0*>(&background_rect)->
                OtDrawBeveledRect_0000b4c0_RealCpp(dc);
            EndPaint(dialog, &paint);
            g_appBusyCursorActive_Product_004034d0 = 0;
            SetFocus(GetDlgItem(dialog, 300));
            SendMessageA(dialog, 0x0401, 300, 0);
            SetCursor(LoadCursorA(0, reinterpret_cast<const void*>(0x7f00)));
        }
        return 1;

    case 0x0014:
        return 1;

    case 0x0020:
        return OtSelectDialogCursor_0040d530_RealCpp(
            g_appBusyCursorActive_Product_004034d0,
            reinterpret_cast<OtDialogHandle_Product>(wparam));

    case 0x002b:
        {
            WillametteValleyArrivalDialogState_0040fee0_InlineProduct* state =
                reinterpret_cast<
                    WillametteValleyArrivalDialogState_0040fee0_InlineProduct*>(
                        GetWindowLongA(dialog, 8));
            OtDialogDrawItem_Product* draw =
                reinterpret_cast<OtDialogDrawItem_Product*>(lparam);

            SelectPalette(draw->dc, g_gamePalette, 0);
            RealizePalette(draw->dc);
            if (draw->item_action == 1) {
                if (wparam == 300) {
                    reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                        &state->continue_up)->
                        OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                            draw->dc, 0, 0);
                }
            } else if (draw->item_action == 2) {
                if ((draw->item_state & 1) == 0) {
                    if (wparam == 300) {
                        reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                            &state->continue_up)->
                            OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                                draw->dc, 0, 0);
                    }
                } else if (wparam == 300) {
                    reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                        &state->continue_down)->
                        OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                            draw->dc, 0, 0);
                }
            }
        }
        return 1;

    case 0x0110:
        {
            OtDialogRect_Product dialog_rect;
            unsigned int horizontal_base_units;
            unsigned int vertical_base_units;
            WillametteValleyArrivalDialogState_0040fee0_InlineProduct* state;

            g_appBusyCursorActive_Product_004034d0 = 1;
            SetCursor(LoadCursorA(0, reinterpret_cast<const void*>(0x7f02)));
            g_activeScreenDialogWindow_00404dd0 = dialog;
            GetClientRect(GetParent(dialog), &dialog_rect);
            horizontal_base_units = GetDialogBaseUnits();
            vertical_base_units = GetDialogBaseUnits();
            SetWindowPos(
                dialog,
                0,
                dialog_rect.left + 10,
                dialog_rect.top + 10,
                dialog_rect.right - dialog_rect.left - 20,
                dialog_rect.bottom - dialog_rect.top - 20,
                4);
            GetClientRect(dialog, &dialog_rect);
            OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
                dialog,
                300,
                static_cast<unsigned short>(horizontal_base_units),
                static_cast<unsigned short>(vertical_base_units >> 16));

            if (g_titleThemeEnabled_004390ec != 0) {
                if (g_cdMediaMode_00439108 == 0) {
                    OtOpenMidiAudioFileMaskClosed_0000cd60_RealCpp(
                        dialog,
                        g_willametteArrivalMidi_0040fee0);
                    OtPlayMidiAudio_0000ced0_RealCpp(0);
                } else {
                    OtOpenWaveAudioFile_0000d110_RealCpp(
                        dialog,
                        g_willametteArrivalWave_0040fee0);
                    OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();
                }
            }

            state =
                new WillametteValleyArrivalDialogState_0040fee0_InlineProduct;
            if (state == 0) {
                MessageBoxA(
                    GetParent(dialog),
                    g_willametteArrivalAllocationText_0040fee0,
                    g_willametteArrivalAllocationCaption_0040fee0,
                    0);
                PostQuitMessage(0);
                return 0;
            }

            state->continue_up.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603,
                    0x2826);
            state->continue_down.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603,
                    0x2827);
            state->arrival_background.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603,
                    0x445c);
            OtResizeControl_RealCpp(
                dialog,
                300,
                state->continue_up.width,
                state->continue_up.height);
            SetWindowLongA(dialog, 8, reinterpret_cast<long>(state));
            SetFocus(GetDlgItem(dialog, 300));
            SendMessageA(dialog, 0x0401, 300, 0);
        }
        return 0;

    case 0x0111:
        if (static_cast<short>(wparam) == 300) {
            PostMessageA(GetParent(dialog), 0x047c, 0, 0);
            DestroyWindow(dialog);
        }
        return 1;

    case 0x0136:
        {
            OtDialogDeviceContext_Product dc =
                reinterpret_cast<OtDialogDeviceContext_Product>(wparam);
            SelectPalette(dc, g_gamePalette, 0);
            RealizePalette(dc);
            SetBkMode(dc, 1);
            SetTextColor(dc, 0);
            SelectObject(dc, g_optionMenuFont_004390d4_00405320);
            return reinterpret_cast<long>(
                g_sharedDialogBackgroundBrush_004390c0);
        }

    case 0x0465:
        if (g_cdMediaMode_00439108 == 0) {
            OtStopMidiAudioDirectImport_0040d010_RealCpp();
        } else {
            OtStopWaveAudioDirectImport_0040d480_RealCpp();
        }
        return 1;

    case 0x046b:
        if (g_cdMediaMode_00439108 == 0) {
            OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();
        } else {
            OtCloseWaveAudioDevice_0040d0a0_RealCpp();
        }
        return 1;
    }

    return 0;
}

#pragma optimize("", on)

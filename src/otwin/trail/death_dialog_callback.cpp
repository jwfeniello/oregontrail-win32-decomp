// Product-reachable semantic DLGPROC for OtDeathDialogProc @ 0x00410da0.
//
// This is deliberately one monolithic callback.  In particular, do not move
// the new/delete expressions or any message arm into a helper: VC4 /GX must
// emit both seven-member cleanup families inside this callback's envelope.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file requires 32-bit Microsoft C++."
#endif

#include "../app/dialog_callback_runtime.h"
#include "epitaph_dialog_callback.h"

typedef int (__stdcall *OtDialogProc_00410da0_Abi)(
    OtDialogHandle_Product,
    unsigned int,
    unsigned int,
    long);

#pragma pack(push, 1)
// Keep this type distinct from DeathDialogState_00410da0_Product.  The latter
// owns seven already-accepted cleanup-thunk identities in
// construct_death_dialog_state.cpp.  This owner intentionally has no declared
// constructor or destructor, so VC4 synthesizes and inlines member lifetime
// handling at the new/delete sites below.
struct DeathDialogBitmapOwner_00410da0_Implicit {
    PositionedBitmapDescriptorState_0040ba40 epitaph_up;
    PositionedBitmapDescriptorState_0040ba40 epitaph_down;
    PositionedBitmapDescriptorState_0040ba40 alternate_up;
    PositionedBitmapDescriptorState_0040ba40 alternate_down;
    PositionedBitmapDescriptorState_0040ba40 continue_up;
    PositionedBitmapDescriptorState_0040ba40 continue_down;
    PositionedBitmapDescriptorState_0040ba40 death_background;
};
#pragma pack(pop)

typedef char OtDeathIntWidthMustBe4[sizeof(int) == 4 ? 1 : -1];
typedef char OtDeathLongWidthMustBe4[sizeof(long) == 4 ? 1 : -1];
typedef char OtDeathPointerWidthMustBe4[sizeof(void*) == 4 ? 1 : -1];
typedef char OtDeathDialogArgumentsMustBe10[
    sizeof(OtDialogHandle_Product) + sizeof(unsigned int) +
        sizeof(unsigned int) + sizeof(long) == 0x10
        ? 1
        : -1];
typedef char OtDeathRectSizeMustBe10[
    sizeof(OtDialogRect_Product) == 0x10 ? 1 : -1];
typedef char OtDeathPaintSizeMustBe40[
    sizeof(OtDialogPaintStruct_Product) == 0x40 ? 1 : -1];
typedef char OtDeathDrawItemSizeMustBe30[
    sizeof(OtDialogDrawItem_Product) == 0x30 ? 1 : -1];
typedef char OtDeathDrawActionOffsetMustBe0c[
    (unsigned int)&(((OtDialogDrawItem_Product*)0)->item_action) == 0x0c
        ? 1
        : -1];
typedef char OtDeathDrawStateOffsetMustBe10[
    (unsigned int)&(((OtDialogDrawItem_Product*)0)->item_state) == 0x10
        ? 1
        : -1];
typedef char OtDeathDrawDcOffsetMustBe18[
    (unsigned int)&(((OtDialogDrawItem_Product*)0)->dc) == 0x18
        ? 1
        : -1];
typedef char OtDeathOwnerSizeMustBe118[
    sizeof(DeathDialogBitmapOwner_00410da0_Implicit) == 0x118 ? 1 : -1];
typedef char OtDeathOwnerBitmap0OffsetMustBe00[
    (unsigned int)&(
        ((DeathDialogBitmapOwner_00410da0_Implicit*)0)->epitaph_up) == 0x00
        ? 1
        : -1];
typedef char OtDeathOwnerBitmap1OffsetMustBe28[
    (unsigned int)&(
        ((DeathDialogBitmapOwner_00410da0_Implicit*)0)->epitaph_down) == 0x28
        ? 1
        : -1];
typedef char OtDeathOwnerBitmap2OffsetMustBe50[
    (unsigned int)&(
        ((DeathDialogBitmapOwner_00410da0_Implicit*)0)->alternate_up) == 0x50
        ? 1
        : -1];
typedef char OtDeathOwnerBitmap3OffsetMustBe78[
    (unsigned int)&(
        ((DeathDialogBitmapOwner_00410da0_Implicit*)0)->alternate_down) == 0x78
        ? 1
        : -1];
typedef char OtDeathOwnerBitmap4OffsetMustBea0[
    (unsigned int)&(
        ((DeathDialogBitmapOwner_00410da0_Implicit*)0)->continue_up) == 0xa0
        ? 1
        : -1];
typedef char OtDeathOwnerBitmap5OffsetMustBec8[
    (unsigned int)&(
        ((DeathDialogBitmapOwner_00410da0_Implicit*)0)->continue_down) == 0xc8
        ? 1
        : -1];
typedef char OtDeathOwnerBitmap6OffsetMustBef0[
    (unsigned int)&(
        ((DeathDialogBitmapOwner_00410da0_Implicit*)0)->death_background) ==
        0xf0
        ? 1
        : -1];

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
extern "C" __declspec(dllimport) OtDialogHandle_Product __stdcall GetDlgItem(
    OtDialogHandle_Product dialog,
    int control_id);
extern "C" __declspec(dllimport) int __stdcall ShowWindow(
    OtDialogHandle_Product window,
    int show_command);
extern "C" __declspec(dllimport) OtDialogHandle_Product __stdcall SetFocus(
    OtDialogHandle_Product window);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    OtDialogHandle_Product window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    OtDialogHandle_Product window,
    const char* text,
    const char* caption,
    unsigned int type);
extern "C" __declspec(dllimport) void __stdcall PostQuitMessage(int exit_code);
extern "C" __declspec(dllimport) int __stdcall PostMessageA(
    OtDialogHandle_Product window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall EndDialog(
    OtDialogHandle_Product dialog,
    int result);
extern "C" __declspec(dllimport) int __stdcall DialogBoxParamA(
    void* instance,
    const void* template_name,
    OtDialogHandle_Product parent,
    OtDialogProc_00410da0_Abi dialog_proc,
    long init_param);
extern "C" __declspec(dllimport) OtDialogDeviceContext_Product __stdcall
BeginPaint(
    OtDialogHandle_Product window,
    OtDialogPaintStruct_Product* paint);
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
extern "C" __declspec(dllimport) void* __stdcall GetStockObject(int object_id);
extern "C" __declspec(dllimport) void* __stdcall LoadCursorA(
    void* instance,
    const void* cursor_name);
extern "C" __declspec(dllimport) void* __stdcall SetCursor(void* cursor);

#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" void* g_gamePalette;
extern "C" void* g_optionMenuFont_004390d4_00405320;
extern "C" int g_appBusyCursorActive_Product_004034d0;
extern "C" OtDialogHandle_Product g_activeScreenDialogWindow_00404dd0;
extern "C" int g_cdMediaMode_00439108;
extern "C" int g_titleThemeEnabled_004390ec;
extern "C" int g_graveSitesEnabled_004390f4;

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

extern "C" int __stdcall OtDeathDialogProc_00010da0_Wip(
    OtDialogHandle_Product dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam);

// This unevaluated call checks the Death definition against the typed
// stdcall DLGPROC slot without emitting a helper or data.
extern char __cdecl OtDialogProcAbiProbe_00410da0(
    OtDialogProc_00410da0_Abi);
typedef char OtDeathDialogProcAbiMustMatch[
    sizeof(OtDialogProcAbiProbe_00410da0(
        OtDeathDialogProc_00010da0_Wip)) == 1
        ? 1
        : -1];
static const char g_deathMidiPath_00410da0[] = "bury.mid";
static const char g_deathWavePath_00410da0[] = "deathsng.wav";
static const char g_deathAllocationText_00410da0[] =
    "Unable to allocate dialog information.";
static const char g_deathAllocationCaption_00410da0[] = "DeathDlgProc";

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" int __stdcall OtDeathDialogProc_00010da0_Wip(
    OtDialogHandle_Product dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam)
{
    OtDialogPaintStruct_Product paint;
    OtDialogRect_Product paint_rect;
    OtDialogRect_Product parent_rect;
    OtDialogDeviceContext_Product dc;
    DeathDialogBitmapOwner_00410da0_Implicit* state;
    unsigned int vertical_units;
    unsigned int horizontal_units;
    unsigned int command;

    switch (message) {
    case 0x0002:
        state =
            reinterpret_cast<DeathDialogBitmapOwner_00410da0_Implicit*>(
                GetWindowLongA(dialog, 8));
        if (state != 0) {
            delete state;
        }
        if (g_titleThemeEnabled_004390ec != 0) {
            if (g_cdMediaMode_00439108 != 0) {
                OtCloseWaveAudioDevice_0040d0a0_RealCpp();
            } else {
                OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();
            }
        }
        return 1;

    case 0x000f:
        g_appBusyCursorActive_Product_004034d0 = 1;
        SetCursor(LoadCursorA(0, reinterpret_cast<const void*>(0x7f02)));
        state =
            reinterpret_cast<DeathDialogBitmapOwner_00410da0_Implicit*>(
                GetWindowLongA(dialog, 8));
        dc = BeginPaint(dialog, &paint);
        SelectPalette(dc, g_gamePalette, 0);
        UnrealizeObject(g_gamePalette);
        RealizePalette(dc);
        SelectObject(dc, g_optionMenuFont_004390d4_00405320);
        GetClientRect(dialog, &paint_rect);
        FillRect(dc, &paint_rect, GetStockObject(4));
        reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
            &state->death_background)->
            OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        EndPaint(dialog, &paint);
        g_appBusyCursorActive_Product_004034d0 = 0;
        SetCursor(LoadCursorA(0, reinterpret_cast<const void*>(0x7f00)));
        return 1;

    case 0x0014:
        return 1;

    case 0x0020:
        return OtSelectDialogCursor_0040d530_RealCpp(
            g_appBusyCursorActive_Product_004034d0,
            reinterpret_cast<OtDialogHandle_Product>(wparam));

    case 0x002b: {
        OtDialogDrawItem_Product* draw =
            reinterpret_cast<OtDialogDrawItem_Product*>(lparam);

        state =
            reinterpret_cast<DeathDialogBitmapOwner_00410da0_Implicit*>(
                GetWindowLongA(dialog, 8));
        SelectPalette(draw->dc, g_gamePalette, 0);
        RealizePalette(draw->dc);

        switch (draw->item_action) {
        case 1:
            switch (wparam) {
            case 0x012c:
                reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                    &state->continue_up)->
                    OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw->dc, 0, 0);
                return 1;
            case 0x0134:
                reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                    &state->epitaph_up)->
                    OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw->dc, 0, 0);
                return 1;
            case 0x0135:
                reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                    &state->alternate_up)->
                    OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw->dc, 0, 0);
                return 1;
            default:
                return 1;
            }

        case 2:
            if ((draw->item_state & 1) != 0) {
                switch (wparam) {
                case 0x012c:
                    reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                        &state->continue_down)->
                        OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                            draw->dc, 0, 0);
                    return 1;
                case 0x0134:
                    reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                        &state->epitaph_down)->
                        OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                            draw->dc, 0, 0);
                    return 1;
                case 0x0135:
                    reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                        &state->alternate_down)->
                        OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                            draw->dc, 0, 0);
                    return 1;
                default:
                    return 1;
                }
            }

            switch (wparam) {
            case 0x012c:
                reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                    &state->continue_up)->
                    OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw->dc, 0, 0);
                return 1;
            case 0x0134:
                reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                    &state->epitaph_up)->
                    OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw->dc, 0, 0);
                return 1;
            case 0x0135:
                reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
                    &state->alternate_up)->
                    OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                        draw->dc, 0, 0);
                return 1;
            default:
                return 1;
            }

        default:
            return 1;
        }
    }

    case 0x0110:
        g_appBusyCursorActive_Product_004034d0 = 1;
        SetCursor(LoadCursorA(0, reinterpret_cast<const void*>(0x7f02)));
        g_activeScreenDialogWindow_00404dd0 = dialog;
        GetClientRect(GetParent(dialog), &parent_rect);
        horizontal_units =
            static_cast<unsigned short>(GetDialogBaseUnits());
        vertical_units =
            static_cast<unsigned short>(GetDialogBaseUnits() >> 16);
        {
            int window_x = parent_rect.left + 10;
            int window_y = parent_rect.top + 10;
            SetWindowPos(
                dialog,
                0,
                window_x,
                window_y,
                parent_rect.right - parent_rect.left - 20,
                parent_rect.bottom - parent_rect.top - 20,
                4);
        }
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog, 0x4652, horizontal_units, vertical_units);
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog, 0x4653, horizontal_units, vertical_units);
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog, 18000, horizontal_units, vertical_units);
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog, 0x0134, horizontal_units, vertical_units);
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog, 0x0135, horizontal_units, vertical_units);
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog, 300, horizontal_units, vertical_units);

        if (lparam == 7 && g_graveSitesEnabled_004390f4 != 0) {
            ShowWindow(GetDlgItem(dialog, 18000), 5);
            ShowWindow(GetDlgItem(dialog, 0x0134), 5);
            ShowWindow(GetDlgItem(dialog, 0x0135), 5);
            ShowWindow(GetDlgItem(dialog, 300), 0);
        } else {
            ShowWindow(GetDlgItem(dialog, 18000), 0);
            ShowWindow(GetDlgItem(dialog, 0x0134), 0);
            ShowWindow(GetDlgItem(dialog, 0x0135), 0);
            ShowWindow(GetDlgItem(dialog, 300), 5);
            SetFocus(GetDlgItem(dialog, 300));
            SendMessageA(dialog, 0x0401, 300, 0);
        }

        if (g_titleThemeEnabled_004390ec != 0) {
            if (g_cdMediaMode_00439108 != 0) {
                OtOpenWaveAudioFile_0000d110_RealCpp(
                    dialog,
                    g_deathWavePath_00410da0);
                OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();
            } else {
                OtOpenMidiAudioFileMaskClosed_0000cd60_RealCpp(
                    dialog,
                    g_deathMidiPath_00410da0);
                OtPlayMidiAudio_0000ced0_RealCpp(0);
            }
        }

        state = new DeathDialogBitmapOwner_00410da0_Implicit;
        if (state == 0) {
            MessageBoxA(
                GetParent(dialog),
                g_deathAllocationText_00410da0,
                g_deathAllocationCaption_00410da0,
                0);
            PostQuitMessage(0);
        } else {
            state->epitaph_up.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603,
                    0x284d);
            state->epitaph_down.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603,
                    0x284e);
            state->alternate_up.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603,
                    0x284f);
            state->alternate_down.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603,
                    0x2850);
            state->continue_up.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603,
                    0x2851);
            state->continue_down.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603,
                    0x2852);
            state->death_background.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603,
                    0x4651);
            state->death_background.
                OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
                    g_applicationModule_00405a40_20260603,
                    static_cast<short>(0x3cd6),
                    0,
                    0,
                    0,
                    0);
            OtResizeControl_RealCpp(
                dialog,
                300,
                state->continue_up.width,
                state->continue_up.height);
            OtResizeControl_RealCpp(
                dialog,
                0x0135,
                state->alternate_up.width,
                state->alternate_up.height);
            OtResizeControl_RealCpp(
                dialog,
                0x0134,
                state->epitaph_up.width,
                state->epitaph_up.height);
            SetWindowLongA(dialog, 8, reinterpret_cast<long>(state));
        }
        break;

    case 0x0111:
        command = wparam & 0xffff;
        switch (command) {
        case 0x0134:
            if (g_titleThemeEnabled_004390ec != 0) {
                if (g_cdMediaMode_00439108 != 0) {
                    OtCloseWaveAudioDevice_0040d0a0_RealCpp();
                } else {
                    OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();
                }
            }
            DialogBoxParamA(
                g_applicationModule_00405a40_20260603,
                reinterpret_cast<const void*>(0x00de),
                dialog,
                OtEpitaphDialogProc_000116e0_Product,
                0);
            break;

        case 300:
        case 0x0135:
            break;

        default:
            return 1;
        }
        PostMessageA(GetParent(dialog), 0x046d, 0, 0);
        EndDialog(dialog, 0);
        return 1;

    case 0x0136:
        dc = reinterpret_cast<OtDialogDeviceContext_Product>(wparam);
        SelectPalette(dc, g_gamePalette, 0);
        RealizePalette(dc);
        return reinterpret_cast<int>(GetStockObject(4));

    case 0x0138:
        dc = reinterpret_cast<OtDialogDeviceContext_Product>(wparam);
        SelectPalette(dc, g_gamePalette, 0);
        RealizePalette(dc);
        SelectObject(dc, g_optionMenuFont_004390d4_00405320);
        SetBkMode(dc, 1);
        SetTextColor(dc, 0x00ffffff);
        return reinterpret_cast<int>(GetStockObject(4));

    case 0x0465:
        if (g_titleThemeEnabled_004390ec != 0) {
            if (g_cdMediaMode_00439108 != 0) {
                OtStopWaveAudioDirectImport_0040d480_RealCpp();
            } else {
                OtStopMidiAudioDirectImport_0040d010_RealCpp();
            }
        }
        break;
    }

    return 0;
}

#pragma optimize("", on)

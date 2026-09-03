// Product semantic DLGPROC for OtEpitaphDialogProc @ 0x004116e0.

#include "epitaph_dialog_callback.h"
#include "grave_site_runtime.h"

extern "C" void* __cdecl memset(
    void* destination,
    int value,
    unsigned int count);
extern "C" unsigned int __cdecl strlen(const char* text);
extern "C" char* __cdecl strcat(char* destination, const char* source);
#pragma intrinsic(memset, strlen, strcat)

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
extern "C" __declspec(dllimport) int __stdcall GetWindowRect(
    OtDialogHandle_Product window,
    OtDialogRect_Product* rect);
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
extern "C" __declspec(dllimport) OtDialogHandle_Product __stdcall GetDlgItem(
    OtDialogHandle_Product dialog,
    int control_id);
extern "C" __declspec(dllimport) int __stdcall GetWindowTextA(
    OtDialogHandle_Product window,
    char* text,
    int text_capacity);
extern "C" __declspec(dllimport) int __stdcall SetWindowTextA(
    OtDialogHandle_Product window,
    const char* text);
extern "C" __declspec(dllimport) int __stdcall PostMessageA(
    OtDialogHandle_Product window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
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
extern "C" __declspec(dllimport) int __stdcall EndDialog(
    OtDialogHandle_Product dialog,
    int result);

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" void* g_journeyState;

extern "C" void __cdecl OtScaleWindowToDialogCoords_00401370_Product(
    OtDialogHandle_Product parent,
    OtDialogHandle_Product child,
    int width_scale,
    int height_scale);
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

#pragma pack(push, 1)
struct EpitaphJourneyNameView_004116e0 {
    char reserved_000[0xc0];
    char party_member_names[5][15];
};

/*
 * Deliberately has no user-declared constructor or destructor. With /GX,
 * VC4 can expand the four PositionedBitmap member lifetimes at new/delete
 * and emit both four-thunk unwind sets in the callback's extent. The distinct
 * name avoids colliding with the accepted out-of-line surrogate constructor.
 */
struct EpitaphDialogInlineState_004116e0_Product {
    PositionedBitmapDescriptorState_0040ba40 okay_button_up;
    PositionedBitmapDescriptorState_0040ba40 okay_button_down;
    PositionedBitmapDescriptorState_0040ba40 cancel_button_up;
    PositionedBitmapDescriptorState_0040ba40 cancel_button_down;
};
#pragma pack(pop)

typedef char OtEpitaphInlineStateSizeMustBeA0[
    sizeof(EpitaphDialogInlineState_004116e0_Product) == 0xa0
        ? 1
        : -1];
typedef char OtEpitaphCancelUpOffsetMustBe50[
    (unsigned int)&(
        ((EpitaphDialogInlineState_004116e0_Product*)0)->
            cancel_button_up) == 0x50
        ? 1
        : -1];
typedef char OtEpitaphCancelDownOffsetMustBe78[
    (unsigned int)&(
        ((EpitaphDialogInlineState_004116e0_Product*)0)->
            cancel_button_down) == 0x78
        ? 1
        : -1];

static const char g_epitaphAllocationText_004116e0[] =
    "Unable to allocate dialog information.";
static const char g_epitaphAllocationCaption_004116e0[] =
    "EpitaphDlgProc";

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" int __stdcall OtEpitaphDialogProc_000116e0_Product(
    OtDialogHandle_Product dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam)
{
    /*
     * Models the original 0xa8 local frame: PAINTSTRUCT 0x40, a 45-byte text
     * buffer rounded to 0x30, three RECTs, and one POINT.
     */
    char text[45];
    OtDialogRect_Product parent_rect;
    OtDialogRect_Product dialog_rect;
    OtDialogPoint_Product parent_center;
    int result;

    switch (message) {
    case 0x000f:
        {
            OtDialogDeviceContext_Product dc;
            OtDialogPaintStruct_Product paint;
            OtDialogRect_Product client_rect;

            g_appBusyCursorActive_Product_004034d0 = 1;
            SetCursor(LoadCursorA(
                0,
                reinterpret_cast<const void*>(0x7f02)));
            dc = BeginPaint(dialog, &paint);
            SelectPalette(dc, g_gamePalette, 0);
            UnrealizeObject(g_gamePalette);
            RealizePalette(dc);
            SetTextColor(dc, 0);
            SelectObject(dc, g_dialogFont_004390d8_00405320);
            GetClientRect(dialog, &client_rect);
            FillRect(
                dc,
                &client_rect,
                g_sharedDialogBackgroundBrush_004390c0);
            EndPaint(dialog, &paint);
            g_appBusyCursorActive_Product_004034d0 = 0;
            SetCursor(LoadCursorA(
                0,
                reinterpret_cast<const void*>(0x7f00)));
            result = 1;
        }
        break;

    case 0x0002:
        {
            EpitaphDialogInlineState_004116e0_Product* state =
                reinterpret_cast<
                    EpitaphDialogInlineState_004116e0_Product*>(
                        GetWindowLongA(dialog, 8));
            if (state != 0) {
                delete state;
            }
            result = 1;
        }
        break;

    case 0x0020:
        result = OtSelectDialogCursor_0040d530_RealCpp(
            g_appBusyCursorActive_Product_004034d0,
            reinterpret_cast<OtDialogHandle_Product>(wparam));
        break;

    case 0x0014:
        result = 0;
        break;

    case 0x0110:
        {

            EpitaphDialogInlineState_004116e0_Product* state;

            int dialog_unit_width;
            int dialog_unit_height;
            int prefix_capacity;

            g_appBusyCursorActive_Product_004034d0 = 1;
            SetCursor(LoadCursorA(
                0,
                reinterpret_cast<const void*>(0x7f02)));
            g_activeScreenDialogWindow_00404dd0 = dialog;

            dialog_unit_width =
                static_cast<unsigned short>(GetDialogBaseUnits());
            dialog_unit_height =
                static_cast<unsigned short>(GetDialogBaseUnits() >> 16);
            OtScaleWindowToDialogCoords_00401370_Product(
                GetParent(dialog),
                dialog,
                dialog_unit_width,
                dialog_unit_height);

            GetClientRect(GetParent(dialog), &parent_rect);
            GetWindowRect(dialog, &dialog_rect);
            parent_center.x = parent_rect.left +
                (parent_rect.right - parent_rect.left) / 2;
            parent_center.y = parent_rect.top +
                (parent_rect.bottom - parent_rect.top) / 2;
            ClientToScreen(GetParent(dialog), &parent_center);
            SetWindowPos(
                dialog,
                0,
                parent_center.x +
                    (dialog_rect.left - dialog_rect.right) / 2,
                parent_center.y +
                    (dialog_rect.top - dialog_rect.bottom) / 2,
                dialog_rect.right - dialog_rect.left,
                dialog_rect.bottom - dialog_rect.top,
                4);

            memset(text, 0, sizeof(text));
            prefix_capacity =
                0x2c - static_cast<int>(
                    strlen(
                        reinterpret_cast<EpitaphJourneyNameView_004116e0*>(
                            g_journeyState)->party_member_names[0]));
            GetWindowTextA(
                GetDlgItem(dialog, 0x465b),
                text,
                prefix_capacity);
            strcat(
                text,
                reinterpret_cast<EpitaphJourneyNameView_004116e0*>(
                    g_journeyState)->party_member_names[0]);
            SetWindowTextA(GetDlgItem(dialog, 0x465b), text);
            memset(text, 0, sizeof(text));

            OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
                dialog,
                0x465a,
                dialog_unit_width,
                dialog_unit_height);
            OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
                dialog,
                0x465b,
                dialog_unit_width,
                dialog_unit_height);
            OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
                dialog,
                0x465d,
                dialog_unit_width,
                dialog_unit_height);
            OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
                dialog,
                300,
                dialog_unit_width,
                dialog_unit_height);
            OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
                dialog,
                0x12d,
                dialog_unit_width,
                dialog_unit_height);

            PostMessageA(
                GetDlgItem(dialog, 0x465d),
                0x00c5,
                0x2c,
                0);
            PostMessageA(
                GetDlgItem(dialog, 0x465d),
                0x0030,
                reinterpret_cast<unsigned int>(
                    g_optionMenuFont_004390d4_00405320),
                0);
            SetFocus(GetDlgItem(dialog, 0x465d));

            state = new EpitaphDialogInlineState_004116e0_Product;
            if (state == 0) {
                MessageBoxA(
                    GetParent(dialog),
                    g_epitaphAllocationText_004116e0,
                    g_epitaphAllocationCaption_004116e0,
                    0);
                PostQuitMessage(0);
                result = 0;
                break;
            }

            state->okay_button_up.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603,
                    0x2826);
            state->okay_button_down.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603,
                    0x2827);
            state->cancel_button_up.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603,
                    0x2828);
            state->cancel_button_down.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603,
                    0x2829);

            OtResizeControl_RealCpp(
                dialog,
                300,
                state->okay_button_up.width,
                state->okay_button_up.height);
            OtResizeControl_RealCpp(
                dialog,
                0x12d,
                state->cancel_button_up.width,
                state->cancel_button_up.height);
            SetWindowLongA(
                dialog,
                8,
                reinterpret_cast<long>(state));
            SetFocus(GetDlgItem(dialog, 0x465d));
            SendMessageA(dialog, 0x0401, 300, 0);
            result = 0;
        }
        break;

    case 0x002b:
        {
            OtDialogDrawItem_Product* draw =
                reinterpret_cast<OtDialogDrawItem_Product*>(lparam);
            EpitaphDialogInlineState_004116e0_Product* state =
                reinterpret_cast<
                    EpitaphDialogInlineState_004116e0_Product*>(
                        GetWindowLongA(dialog, 8));

            SelectPalette(draw->dc, g_gamePalette, 0);
            RealizePalette(draw->dc);

            switch (draw->item_action) {
            case 1:
                switch (wparam) {
                case 0x12c:
                    reinterpret_cast<
                        PositionedBitmap_0040b7b0_Semantic*>(
                            &state->okay_button_up)->
                                OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                                    draw->dc,
                                    0,
                                    0);
                    break;

                case 0x12d:
                    reinterpret_cast<
                        PositionedBitmap_0040b7b0_Semantic*>(
                            &state->cancel_button_up)->
                                OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                                    draw->dc,
                                    0,
                                    0);
                    break;

                default:
                    break;
                }
                break;

            case 2:
                if ((draw->item_state & 1) != 0) {
                    switch (wparam) {
                    case 0x12c:
                        reinterpret_cast<
                            PositionedBitmap_0040b7b0_Semantic*>(
                                &state->okay_button_down)->
                                    OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                                        draw->dc,
                                        0,
                                        0);
                        break;

                    case 0x12d:
                        reinterpret_cast<
                            PositionedBitmap_0040b7b0_Semantic*>(
                                &state->cancel_button_down)->
                                    OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                                        draw->dc,
                                        0,
                                        0);
                        break;

                    default:
                        break;
                    }
                } else {
                    switch (wparam) {
                    case 0x12c:
                        reinterpret_cast<
                            PositionedBitmap_0040b7b0_Semantic*>(
                                &state->okay_button_up)->
                                    OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                                        draw->dc,
                                        0,
                                        0);
                        break;

                    case 0x12d:
                        reinterpret_cast<
                            PositionedBitmap_0040b7b0_Semantic*>(
                                &state->cancel_button_up)->
                                    OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                                        draw->dc,
                                        0,
                                        0);
                        break;

                    default:
                        break;
                    }
                }
                break;

            default:
                break;
            }
            result = 1;
        }
        break;

    case 0x0111:
        {
            unsigned int control_id = wparam & 0xffff;

            if (control_id != 300) {
                if (control_id != 0x12d) {
                    result = 1;
                    break;
                }
            } else {
                char* character;

                GetWindowTextA(
                    GetDlgItem(dialog, 0x465d),
                    text,
                    0x2d);
                character = text;
                while (*character != '\0') {
                    if (*character == '\n' || *character == '\r') {
                        *character = ' ';
                    }
                    ++character;
                }
                g_graveSiteRuntime->
                    OtWriteGraveRecordToIni_000120b0_Product(text);
            }
            EndDialog(dialog, 0);
            result = 1;
        }
        break;

    case 0x0136:
        {
            OtDialogDeviceContext_Product dc =
                reinterpret_cast<OtDialogDeviceContext_Product>(wparam);

            SelectPalette(dc, g_gamePalette, 0);
            RealizePalette(dc);
            SelectObject(dc, g_optionMenuFont_004390d4_00405320);
        }
        goto epitaph_dialog_brush_result;

    case 0x0138:
        {
            OtDialogDeviceContext_Product dc =
                reinterpret_cast<OtDialogDeviceContext_Product>(wparam);
            void* font;

            SelectPalette(dc, g_gamePalette, 0);
            RealizePalette(dc);
            SetTextColor(dc, 0);
            if (GetWindowLongA(
                    reinterpret_cast<OtDialogHandle_Product>(lparam),
                    -12) == 0x465b) {
                font = g_optionMenuFont_004390d4_00405320;
            } else {
                font = g_dialogFont_004390d8_00405320;
            }
            SelectObject(dc, font);
            SetBkMode(dc, 1);
        }

    epitaph_dialog_brush_result:
        result = reinterpret_cast<int>(
            g_sharedDialogBackgroundBrush_004390c0);
        break;

    default:
        result = 0;
        break;
    }

    return result;
}




#pragma optimize("", on)

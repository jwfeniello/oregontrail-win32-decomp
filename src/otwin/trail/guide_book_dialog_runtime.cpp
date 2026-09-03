// Product-reachable semantic recovery of the original Guide Book translation
// unit at Oregon32.exe 0x00409e50..0x0040b4b0.  The implementation remains WIP
// while its VC4 stack layout and adjacent helper boundaries are recovered.
// It deliberately contains no ASM, _emit, naked functions, embedded
// instruction bytes, raw-address calls, or storage-class codegen shaping.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This Product recovery source requires 32-bit Visual C++."
#endif

#include <stdlib.h>
#include <string.h>

#pragma intrinsic(memset, strcpy, strcat, strlen)

typedef void* OtGuideHandle;
typedef const void* OtGuideResourceName;

struct OtGuidePoint {
    long x;
    long y;
};

struct OtGuideRect {
    long left;
    long top;
    long right;
    long bottom;
};

struct OtGuidePaintStruct {
    char bytes[0x40];
};

struct OtGuideDrawItemStruct {
    unsigned int control_type;
    unsigned int control_id;
    unsigned int item_id;
    unsigned int item_action;
    unsigned int item_state;
    OtGuideHandle item_window;
    OtGuideHandle dc;
    OtGuideRect item_rect;
    unsigned long item_data;
};

extern "C" __declspec(dllimport) unsigned int __stdcall GetDialogBaseUnits();
extern "C" __declspec(dllimport) OtGuideHandle __stdcall GetParent(
    OtGuideHandle window);
extern "C" __declspec(dllimport) int __stdcall GetWindowRect(
    OtGuideHandle window,
    OtGuideRect* rect);
extern "C" __declspec(dllimport) int __stdcall GetClientRect(
    OtGuideHandle window,
    OtGuideRect* rect);
extern "C" __declspec(dllimport) int __stdcall ClientToScreen(
    OtGuideHandle window,
    OtGuidePoint* point);
extern "C" __declspec(dllimport) int __stdcall SetWindowPos(
    OtGuideHandle window,
    OtGuideHandle insert_after,
    int x,
    int y,
    int width,
    int height,
    unsigned int flags);
extern "C" __declspec(dllimport) long __stdcall GetWindowLongA(
    OtGuideHandle window,
    int index);
extern "C" __declspec(dllimport) long __stdcall SetWindowLongA(
    OtGuideHandle window,
    int index,
    long value);
extern "C" __declspec(dllimport) OtGuideHandle __stdcall GetDlgItem(
    OtGuideHandle dialog,
    int control_id);
extern "C" __declspec(dllimport) int __stdcall ShowWindow(
    OtGuideHandle window,
    int show_command);
extern "C" __declspec(dllimport) OtGuideHandle __stdcall SetFocus(
    OtGuideHandle window);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    OtGuideHandle window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) long __stdcall SendDlgItemMessageA(
    OtGuideHandle dialog,
    int control_id,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall SetWindowTextA(
    OtGuideHandle window,
    const char* text);
extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    OtGuideHandle module,
    unsigned int string_id,
    char* text,
    int text_capacity);
extern "C" __declspec(dllimport) int __stdcall EndDialog(
    OtGuideHandle dialog,
    int result);
extern "C" __declspec(dllimport) int __stdcall DialogBoxParamA(
    OtGuideHandle module,
    const char* template_name,
    OtGuideHandle parent,
    void* dialog_proc,
    long init_parameter);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    OtGuideHandle owner,
    const char* text,
    const char* caption,
    unsigned int type);
extern "C" __declspec(dllimport) void __stdcall PostQuitMessage(int exit_code);

extern "C" __declspec(dllimport) OtGuideHandle __stdcall LoadCursorA(
    OtGuideHandle instance,
    OtGuideResourceName cursor_name);
extern "C" __declspec(dllimport) OtGuideHandle __stdcall SetCursor(
    OtGuideHandle cursor);
extern "C" __declspec(dllimport) OtGuideHandle __stdcall BeginPaint(
    OtGuideHandle window,
    OtGuidePaintStruct* paint);
extern "C" __declspec(dllimport) int __stdcall EndPaint(
    OtGuideHandle window,
    const OtGuidePaintStruct* paint);
extern "C" __declspec(dllimport) int __stdcall GetUpdateRect(
    OtGuideHandle window,
    OtGuideRect* rect,
    int erase);
extern "C" __declspec(dllimport) int __stdcall FillRect(
    OtGuideHandle dc,
    const OtGuideRect* rect,
    OtGuideHandle brush);

extern "C" __declspec(dllimport) OtGuideHandle __stdcall SelectPalette(
    OtGuideHandle dc,
    OtGuideHandle palette,
    int force_background);
extern "C" __declspec(dllimport) unsigned int __stdcall RealizePalette(
    OtGuideHandle dc);
extern "C" __declspec(dllimport) int __stdcall SetBkMode(
    OtGuideHandle dc,
    int mode);
extern "C" __declspec(dllimport) unsigned long __stdcall SetTextColor(
    OtGuideHandle dc,
    unsigned long color);
extern "C" __declspec(dllimport) OtGuideHandle __stdcall SelectObject(
    OtGuideHandle dc,
    OtGuideHandle object);

extern "C" __declspec(dllimport) OtGuideHandle __stdcall FindResourceA(
    OtGuideHandle module,
    OtGuideResourceName resource_name,
    OtGuideResourceName resource_type);
extern "C" __declspec(dllimport) OtGuideHandle __stdcall LoadResource(
    OtGuideHandle module,
    OtGuideHandle resource_info);
extern "C" __declspec(dllimport) void* __stdcall LockResource(
    OtGuideHandle resource_data);
extern "C" __declspec(dllimport) int __stdcall FreeResource(
    OtGuideHandle resource_data);

#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "kernel32.lib")
#pragma comment(lib, "user32.lib")

extern void* __cdecl operator new(unsigned int bytes);
extern void __cdecl operator delete(void* block);

extern "C" void __cdecl OtScaleWindowToDialogCoords_00401370_Product(
    OtGuideHandle parent,
    OtGuideHandle child,
    int width_scale,
    int height_scale);
extern "C" int __cdecl OtLoadSavedDialogPlacement_00401110_RealCpp(
    const char* section,
    OtGuideRect* persisted_rect);
extern "C" void __cdecl
OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
    OtGuideHandle dialog,
    int control_id,
    int dialog_unit_width,
    int dialog_unit_height);
extern "C" void __cdecl OtPersistDialogPlacement_00401430_RealCpp(
    const char* section,
    const OtGuideRect* rect);
extern "C" void __cdecl OtResizeControl_RealCpp(
    OtGuideHandle dialog,
    int control_id,
    int width,
    int height);
extern "C" int __cdecl OtSelectDialogCursor_0040d530_RealCpp(
    int force_busy_cursor,
    OtGuideHandle window);

extern "C" void __cdecl OtCloseWaveAudioDevice_0040d0a0_RealCpp();
extern "C" void __cdecl OtOpenWaveAudioFile_0000d110_RealCpp(
    OtGuideHandle owner,
    char* logical_name);
extern "C" void __cdecl OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();
extern "C" void __cdecl OtStopWaveAudioDirectImport_0040d480_RealCpp();

struct PositionedBitmap_0040b7b0_Semantic {
    int OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        OtGuideHandle dc,
        int source_x,
        int source_y);
};

#pragma pack(push, 1)
struct PositionedBitmapDescriptorState_0040ba40 {
    OtGuideHandle bitmap_info_handle;
    OtGuideHandle indexed_pixels_handle;
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
        OtGuideHandle module,
        short descriptor_id);
};

struct GuideBookDialogState_00409e50_Proposal {
    PositionedBitmapDescriptorState_0040ba40 previous_page_up;
    PositionedBitmapDescriptorState_0040ba40 previous_page_down;
    PositionedBitmapDescriptorState_0040ba40 next_page_up;
    PositionedBitmapDescriptorState_0040ba40 next_page_down;
    PositionedBitmapDescriptorState_0040ba40 contents_up;
    PositionedBitmapDescriptorState_0040ba40 contents_down;
    PositionedBitmapDescriptorState_0040ba40 play_audio_up;
    PositionedBitmapDescriptorState_0040ba40 play_audio_down;
    PositionedBitmapDescriptorState_0040ba40 stop_audio_up;
    PositionedBitmapDescriptorState_0040ba40 stop_audio_down;
    PositionedBitmapDescriptorState_0040ba40 close_up;
    PositionedBitmapDescriptorState_0040ba40 close_down;
};

struct GuideBookIndexDialogState_0040ae50_Proposal {
    PositionedBitmapDescriptorState_0040ba40 close_up;
    PositionedBitmapDescriptorState_0040ba40 close_down;
    PositionedBitmapDescriptorState_0040ba40 cancel_up;
    PositionedBitmapDescriptorState_0040ba40 cancel_down;
};
#pragma pack(pop)

typedef char OtGuideDrawItemSizeMustBe30[
    sizeof(OtGuideDrawItemStruct) == 0x30 ? 1 : -1];
typedef char OtGuideBitmapSizeMustBe28[
    sizeof(PositionedBitmapDescriptorState_0040ba40) == 0x28 ? 1 : -1];
typedef char OtGuideDialogStateSizeMustBe1e0[
    sizeof(GuideBookDialogState_00409e50_Proposal) == 0x1e0 ? 1 : -1];
typedef char OtGuideIndexStateSizeMustBeA0[
    sizeof(GuideBookIndexDialogState_0040ae50_Proposal) == 0xa0 ? 1 : -1];

extern "C" OtGuideHandle g_applicationModule_00405a40_20260603;
extern "C" OtGuideHandle g_resourceModule;
extern "C" OtGuideHandle g_gamePalette;
extern "C" OtGuideHandle g_sharedDialogBackgroundBrush_004390c0;
extern "C" OtGuideHandle g_optionMenuFont_004390d4_00405320;
extern "C" OtGuideHandle g_dialogFont_004390d8_00405320;
extern "C" int g_appBusyCursorActive_Product_004034d0;
extern "C" int g_cdMediaMode_00439108;
extern "C" int DAT_004390e8;

// Both are real shared globals in the original image.  The current Product WIP
// incorrectly makes the page index TU-local and does not model the shared
// modeless-dialog handle at all.
extern "C" OtGuideHandle g_sharedModelessDialogWindow_004390cc = 0;
extern "C" int g_guideBookCurrentPage_0043b5a0 = 0;

extern "C" const char g_guideBookAllocationFailure_00439068[] =
    "Can't allocate local memory";
extern "C" const char g_guideBookPlacementWriteKey_004395f0[] = "Guide Book";
extern "C" const char g_guideBookDialogCaption_004395fc[] =
    "GuideBookDlgProc";
extern "C" const char g_guideBookPlacementReadKey_00439610[] = "Guide book";
extern "C" const char g_guideBookTitlePrefix_0043961c[] = "Guide book: ";
extern "C" const char g_guideBookIndexTitle_0043962c[] = "Guide Book Index";

enum OtGuideBookControlId {
    kGuideBookClose = 0x12c,
    kGuideBookPlay = 0x132,
    kGuideBookStop = 0x133,
    kGuideBookContents = 0x136,
    kGuideBookPrevious = 0x13b,
    kGuideBookNext = 0x13c,
    kGuideBookBody = 0x59d8,
    kGuideBookIndexList = 0x59d9
};

#define OtBlitGuideBookBitmap_Proposal(bitmap, dc)                         \
    (((PositionedBitmap_0040b7b0_Semantic*)(bitmap))                      \
         ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic((dc), 0, 0))

extern "C" void __cdecl OtRefreshGuideBookPage_0040ad80_RealCpp(
    OtGuideHandle dialog,
    int page_argument);
extern "C" long __stdcall OtGuideBookIndexDialogProc_0040ae50_RealCpp(
    OtGuideHandle dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam);

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" long __stdcall OtGuideBookDialogProc_00409e50_RealCpp(
    OtGuideHandle dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam)
{
    GuideBookDialogState_00409e50_Proposal* state;
    OtGuideRect dialog_rect;
    OtGuidePoint parent_center;
    OtGuideRect parent_rect;
    OtGuideRect saved_rect;
    OtGuideRect update_rect;
    OtGuidePaintStruct paint;

    switch (message) {
    case 2: {
        state = (GuideBookDialogState_00409e50_Proposal*)
            GetWindowLongA(dialog, 8);

        GetWindowRect(dialog, &dialog_rect);
        g_sharedModelessDialogWindow_004390cc = 0;
        GetWindowRect(dialog, &dialog_rect);
        OtPersistDialogPlacement_00401430_RealCpp(
            g_guideBookPlacementWriteKey_004395f0,
            &dialog_rect);

        if (state != 0) {
            delete state;
        }
        return 1;
    }

    case 6:
        if ((short)wparam == 0 &&
            DAT_004390e8 != 0 &&
            g_cdMediaMode_00439108 != 0) {
            OtCloseWaveAudioDevice_0040d0a0_RealCpp();
        }
        return 1;

    case 0x0f: {
        g_appBusyCursorActive_Product_004034d0 = 1;
        SetCursor(LoadCursorA(0, (OtGuideResourceName)0x7f02));
        BeginPaint(dialog, &paint);
        EndPaint(dialog, &paint);
        g_appBusyCursorActive_Product_004034d0 = 0;
        SetCursor(LoadCursorA(0, (OtGuideResourceName)0x7f00));
        return 1;
    }

    case 0x14: {
        OtGuideHandle dc = (OtGuideHandle)wparam;

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

    case 0x20:
        return OtSelectDialogCursor_0040d530_RealCpp(
            g_appBusyCursorActive_Product_004034d0,
            (OtGuideHandle)wparam);

    case 0x2b: {
        state = (GuideBookDialogState_00409e50_Proposal*)
            GetWindowLongA(dialog, 8);
        OtGuideDrawItemStruct* draw = (OtGuideDrawItemStruct*)lparam;

        SelectPalette(draw->dc, g_gamePalette, 0);
        RealizePalette(draw->dc);

        if (draw->item_action == 1) {
            switch (wparam) {
            case kGuideBookClose:
                OtBlitGuideBookBitmap_Proposal(&state->close_up, draw->dc);
                break;
            case kGuideBookPlay:
                OtBlitGuideBookBitmap_Proposal(&state->play_audio_up, draw->dc);
                break;
            case kGuideBookStop:
                OtBlitGuideBookBitmap_Proposal(&state->stop_audio_up, draw->dc);
                break;
            case kGuideBookContents:
                OtBlitGuideBookBitmap_Proposal(&state->contents_up, draw->dc);
                break;
            case kGuideBookPrevious:
                OtBlitGuideBookBitmap_Proposal(&state->previous_page_up, draw->dc);
                break;
            case kGuideBookNext:
                OtBlitGuideBookBitmap_Proposal(&state->next_page_up, draw->dc);
                break;
            }
        } else if (draw->item_action == 2) {
            if ((draw->item_state & 1) != 0) {
                switch (wparam) {
                case kGuideBookClose:
                    OtBlitGuideBookBitmap_Proposal(&state->close_down, draw->dc);
                    break;
                case kGuideBookPlay:
                    OtBlitGuideBookBitmap_Proposal(
                        &state->play_audio_down,
                        draw->dc);
                    break;
                case kGuideBookStop:
                    OtBlitGuideBookBitmap_Proposal(
                        &state->stop_audio_down,
                        draw->dc);
                    break;
                case kGuideBookContents:
                    OtBlitGuideBookBitmap_Proposal(&state->contents_down, draw->dc);
                    break;
                case kGuideBookPrevious:
                    OtBlitGuideBookBitmap_Proposal(
                        &state->previous_page_down,
                        draw->dc);
                    break;
                case kGuideBookNext:
                    OtBlitGuideBookBitmap_Proposal(
                        &state->next_page_down,
                        draw->dc);
                    break;
                }
            } else {
                switch (wparam) {
                case kGuideBookClose:
                    OtBlitGuideBookBitmap_Proposal(&state->close_up, draw->dc);
                    break;
                case kGuideBookPlay:
                    OtBlitGuideBookBitmap_Proposal(&state->play_audio_up, draw->dc);
                    break;
                case kGuideBookStop:
                    OtBlitGuideBookBitmap_Proposal(&state->stop_audio_up, draw->dc);
                    break;
                case kGuideBookContents:
                    OtBlitGuideBookBitmap_Proposal(&state->contents_up, draw->dc);
                    break;
                case kGuideBookPrevious:
                    OtBlitGuideBookBitmap_Proposal(
                        &state->previous_page_up,
                        draw->dc);
                    break;
                case kGuideBookNext:
                    OtBlitGuideBookBitmap_Proposal(&state->next_page_up, draw->dc);
                    break;
                }
            }
        }
        return 1;
    }

    case 0x110: {
        unsigned int dialog_unit_width;
        unsigned int dialog_unit_height;

        g_appBusyCursorActive_Product_004034d0 = 1;
        SetCursor(LoadCursorA(0, (OtGuideResourceName)0x7f02));

        dialog_unit_width = (unsigned short)GetDialogBaseUnits();
        dialog_unit_height = (unsigned short)(GetDialogBaseUnits() >> 16);

        OtScaleWindowToDialogCoords_00401370_Product(
            GetParent(dialog),
            dialog,
            dialog_unit_width,
            dialog_unit_height);

        GetWindowRect(dialog, &dialog_rect);
        if (OtLoadSavedDialogPlacement_00401110_RealCpp(
                g_guideBookPlacementReadKey_00439610,
                &saved_rect) == 0) {
            GetClientRect(GetParent(dialog), &parent_rect);
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
        } else {
            SetWindowPos(
                dialog,
                0,
                saved_rect.left,
                saved_rect.top,
                dialog_rect.right - dialog_rect.left,
                dialog_rect.bottom - dialog_rect.top,
                4);
        }

        if (DAT_004390e8 != 0) {
            OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
                dialog,
                kGuideBookPlay,
                dialog_unit_width,
                dialog_unit_height);
            OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
                dialog,
                kGuideBookStop,
                dialog_unit_width,
                dialog_unit_height);
        }
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog,
            kGuideBookBody,
            dialog_unit_width,
            dialog_unit_height);
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog,
            kGuideBookClose,
            dialog_unit_width,
            dialog_unit_height);
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog,
            kGuideBookContents,
            dialog_unit_width,
            dialog_unit_height);
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog,
            kGuideBookPrevious,
            dialog_unit_width,
            dialog_unit_height);
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog,
            kGuideBookNext,
            dialog_unit_width,
            dialog_unit_height);

        state = new GuideBookDialogState_00409e50_Proposal;
        if (state == 0) {
            MessageBoxA(
                GetParent(dialog),
                g_guideBookAllocationFailure_00439068,
                g_guideBookDialogCaption_004395fc,
                0);
            PostQuitMessage(0);
            return 0;
        }

        if (DAT_004390e8 != 0) {
            state->play_audio_up.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603,
                    0x282c);
            state->play_audio_down.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603,
                    0x282d);
            state->stop_audio_up.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603,
                    0x282e);
            state->stop_audio_down.
                OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                    g_applicationModule_00405a40_20260603,
                    0x282f);

            OtResizeControl_RealCpp(
                dialog,
                kGuideBookPlay,
                state->play_audio_up.width,
                state->play_audio_up.height);
            OtResizeControl_RealCpp(
                dialog,
                kGuideBookStop,
                state->stop_audio_up.width,
                state->stop_audio_up.height);
        }

        state->previous_page_up.
            OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                g_applicationModule_00405a40_20260603,
                0x2830);
        state->previous_page_down.
            OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                g_applicationModule_00405a40_20260603,
                0x2831);
        state->next_page_up.
            OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                g_applicationModule_00405a40_20260603,
                0x2832);
        state->next_page_down.
            OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                g_applicationModule_00405a40_20260603,
                0x2833);
        state->contents_up.
            OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                g_applicationModule_00405a40_20260603,
                0x2834);
        state->contents_down.
            OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                g_applicationModule_00405a40_20260603,
                0x2835);
        state->close_up.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603,
            0x2826);
        state->close_down.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603,
            0x2827);

        SetWindowLongA(dialog, 8, (long)state);

        OtResizeControl_RealCpp(
            dialog,
            kGuideBookClose,
            state->close_up.width,
            state->close_up.height);
        OtResizeControl_RealCpp(
            dialog,
            kGuideBookContents,
            state->contents_up.width,
            state->contents_up.height);
        OtResizeControl_RealCpp(
            dialog,
            kGuideBookPrevious,
            state->previous_page_up.width,
            state->previous_page_up.height);
        OtResizeControl_RealCpp(
            dialog,
            kGuideBookNext,
            state->next_page_up.width,
            state->next_page_up.height);

        g_guideBookCurrentPage_0043b5a0 = (int)lparam;
        ShowWindow(
            GetDlgItem(dialog, kGuideBookPrevious),
            g_guideBookCurrentPage_0043b5a0 == 0 ? 0 : 5);
        ShowWindow(
            GetDlgItem(dialog, kGuideBookNext),
            g_guideBookCurrentPage_0043b5a0 == 0x48 ? 0 : 5);
        OtRefreshGuideBookPage_0040ad80_RealCpp(
            dialog,
            g_guideBookCurrentPage_0043b5a0);
        SetFocus(GetDlgItem(dialog, kGuideBookClose));
        SendMessageA(dialog, 0x401, kGuideBookClose, 0);

        // The original leaves the busy flag set here.  Its paint path clears
        // the flag and restores the arrow cursor.
        return 0;
    }

    case 0x111:
        switch (wparam & 0xffff) {
        case kGuideBookClose:
            if (DAT_004390e8 != 0 && g_cdMediaMode_00439108 != 0) {
                OtCloseWaveAudioDevice_0040d0a0_RealCpp();
            }
            EndDialog(dialog, 1);
            break;

        case kGuideBookPlay:
            if (DAT_004390e8 != 0 && g_cdMediaMode_00439108 != 0) {
                char wave_suffix[5] = ".wav";
                char wave_name[21] = "gb";
                char page_number[3];

                _itoa(
                    g_guideBookCurrentPage_0043b5a0 + 1,
                    page_number,
                    10);
                strcat(wave_name, page_number);
                strcat(wave_name, wave_suffix);
                OtOpenWaveAudioFile_0000d110_RealCpp(dialog, wave_name);
                OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();
            }
            break;

        case kGuideBookStop:
            if (DAT_004390e8 != 0 && g_cdMediaMode_00439108 != 0) {
                OtStopWaveAudioDirectImport_0040d480_RealCpp();
            }
            break;

        case kGuideBookContents:
            if (DAT_004390e8 != 0 && g_cdMediaMode_00439108 != 0) {
                OtStopWaveAudioDirectImport_0040d480_RealCpp();
            }
            DialogBoxParamA(
                g_resourceModule,
                (const char*)0xfb,
                dialog,
                (void*)OtGuideBookIndexDialogProc_0040ae50_RealCpp,
                0);
            ShowWindow(
                GetDlgItem(dialog, kGuideBookPrevious),
                g_guideBookCurrentPage_0043b5a0 == 0 ? 0 : 5);
            ShowWindow(
                GetDlgItem(dialog, kGuideBookNext),
                g_guideBookCurrentPage_0043b5a0 == 0x48 ? 0 : 5);
            OtRefreshGuideBookPage_0040ad80_RealCpp(
                dialog,
                g_guideBookCurrentPage_0043b5a0);
            break;

        case kGuideBookPrevious:
            if (DAT_004390e8 != 0 && g_cdMediaMode_00439108 != 0) {
                OtStopWaveAudioDirectImport_0040d480_RealCpp();
            }
            if (g_guideBookCurrentPage_0043b5a0 > 0) {
                --g_guideBookCurrentPage_0043b5a0;
            }
            ShowWindow(
                GetDlgItem(dialog, kGuideBookPrevious),
                g_guideBookCurrentPage_0043b5a0 == 0 ? 0 : 5);
            ShowWindow(
                GetDlgItem(dialog, kGuideBookNext),
                g_guideBookCurrentPage_0043b5a0 == 0x48 ? 0 : 5);
            OtRefreshGuideBookPage_0040ad80_RealCpp(
                dialog,
                g_guideBookCurrentPage_0043b5a0);
            break;

        case kGuideBookNext:
            if (DAT_004390e8 != 0 && g_cdMediaMode_00439108 != 0) {
                OtStopWaveAudioDirectImport_0040d480_RealCpp();
            }
            if (g_guideBookCurrentPage_0043b5a0 < 0x48) {
                ++g_guideBookCurrentPage_0043b5a0;
            }
            ShowWindow(
                GetDlgItem(dialog, kGuideBookPrevious),
                g_guideBookCurrentPage_0043b5a0 == 0 ? 0 : 5);
            ShowWindow(
                GetDlgItem(dialog, kGuideBookNext),
                g_guideBookCurrentPage_0043b5a0 == 0x48 ? 0 : 5);
            OtRefreshGuideBookPage_0040ad80_RealCpp(
                dialog,
                g_guideBookCurrentPage_0043b5a0);
            break;
        }
        return 1;

    case 0x136: {
        OtGuideHandle dc = (OtGuideHandle)wparam;
        SelectPalette(dc, g_gamePalette, 0);
        RealizePalette(dc);
        SetBkMode(dc, 1);
        SetTextColor(dc, 0);
        SelectObject(dc, g_optionMenuFont_004390d4_00405320);
        return (long)g_sharedDialogBackgroundBrush_004390c0;
    }

    case 0x138: {
        OtGuideHandle dc = (OtGuideHandle)wparam;
        SelectPalette(dc, g_gamePalette, 0);
        RealizePalette(dc);
        SetBkMode(dc, 1);
        SetTextColor(dc, 0);
        SelectObject(dc, g_dialogFont_004390d8_00405320);
        return (long)g_sharedDialogBackgroundBrush_004390c0;
    }

    case 0x3b9:
        return 1;

    case 0x464:
        if (DAT_004390e8 != 0 && g_cdMediaMode_00439108 != 0) {
            OtCloseWaveAudioDevice_0040d0a0_RealCpp();
        }
        return 1;

    case 0x466:
        OtRefreshGuideBookPage_0040ad80_RealCpp(
            dialog,
            g_guideBookCurrentPage_0043b5a0);
        return 1;
    }

    return 0;
}

// 0x0040ad80.  Callers pass the current page as a second cdecl argument, but
// the original body reads the shared page global.  Retaining the ABI and the
// shared read is evidence-based, not an artificial dependency.
extern "C" void __cdecl OtRefreshGuideBookPage_0040ad80_RealCpp(
    OtGuideHandle dialog,
    int page_argument)
{
    char title[52];
    OtGuideHandle module = g_resourceModule;
    OtGuideHandle resource_info = FindResourceA(
        g_resourceModule,
        (OtGuideResourceName)(g_guideBookCurrentPage_0043b5a0 + 0x5654),
        (OtGuideResourceName)10);
    OtGuideHandle resource_data = LoadResource(module, resource_info);

    // The second argument is part of the observed two-argument caller ABI.
    // The original implementation intentionally uses the shared global.
    (void)page_argument;

    memset(title, 0, 50);
    strcpy(title, g_guideBookTitlePrefix_0043961c);
    LoadStringA(
        g_resourceModule,
        g_guideBookCurrentPage_0043b5a0 + 2000,
        title + strlen(title),
        30);
    SetWindowTextA(dialog, title);
    SetWindowTextA(
        GetDlgItem(dialog, kGuideBookBody),
        (const char*)LockResource(resource_data));
    FreeResource(resource_data);
}

// 0x0040ae50.  This callback is the Guide Book Index dialog, not a bitmap
// array loader.  It fills a 73-row list with the page-title string resources,
// selects the current page, and writes LB_GETCURSEL back to the shared page.
extern "C" long __stdcall OtGuideBookIndexDialogProc_0040ae50_RealCpp(
    OtGuideHandle dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam)
{
    GuideBookIndexDialogState_0040ae50_Proposal* state;
    OtGuidePoint parent_center;
    OtGuideRect dialog_rect;
    OtGuideRect parent_rect;
    OtGuideRect update_rect;
    char page_title[30];
    OtGuidePaintStruct paint;

    switch (message) {
    case 2: {
        state =
            (GuideBookIndexDialogState_0040ae50_Proposal*)GetWindowLongA(
                dialog,
                8);
        if (state != 0) {
            delete state;
        }
        return 1;
    }

    case 0x0f: {
        g_appBusyCursorActive_Product_004034d0 = 1;
        SetCursor(LoadCursorA(0, (OtGuideResourceName)0x7f02));
        BeginPaint(dialog, &paint);
        EndPaint(dialog, &paint);
        g_appBusyCursorActive_Product_004034d0 = 0;
        SetCursor(LoadCursorA(0, (OtGuideResourceName)0x7f00));
        return 1;
    }

    case 0x14: {
        OtGuideHandle dc = (OtGuideHandle)wparam;

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

    case 0x2b: {
        OtGuideDrawItemStruct* draw = (OtGuideDrawItemStruct*)lparam;
        state =
            (GuideBookIndexDialogState_0040ae50_Proposal*)GetWindowLongA(
                dialog,
                8);

        SelectPalette(draw->dc, g_gamePalette, 0);
        RealizePalette(draw->dc);

        if (draw->item_action == 1) {
            if (wparam == kGuideBookClose) {
                OtBlitGuideBookBitmap_Proposal(&state->close_up, draw->dc);
            }
            if (wparam == 0x12d) {
                OtBlitGuideBookBitmap_Proposal(&state->cancel_up, draw->dc);
            }
        }
        if (draw->item_action == 2) {
            if ((draw->item_state & 1) != 0) {
                if (wparam == kGuideBookClose) {
                    OtBlitGuideBookBitmap_Proposal(&state->close_down, draw->dc);
                }
                if (wparam == 0x12d) {
                    OtBlitGuideBookBitmap_Proposal(
                        &state->cancel_down,
                        draw->dc);
                }
            } else {
                if (wparam == kGuideBookClose) {
                    OtBlitGuideBookBitmap_Proposal(&state->close_up, draw->dc);
                }
                if (wparam == 0x12d) {
                    OtBlitGuideBookBitmap_Proposal(&state->cancel_up, draw->dc);
                }
            }
        }
        return 1;
    }

    case 0x110: {
        unsigned int dialog_unit_width;
        unsigned int dialog_unit_height;
        int page_index;

        g_appBusyCursorActive_Product_004034d0 = 1;
        SetCursor(LoadCursorA(0, (OtGuideResourceName)0x7f02));

        dialog_unit_width = (unsigned short)GetDialogBaseUnits();
        dialog_unit_height = (unsigned short)(GetDialogBaseUnits() >> 16);
        OtScaleWindowToDialogCoords_00401370_Product(
            GetParent(dialog),
            dialog,
            dialog_unit_width,
            dialog_unit_height);

        GetWindowRect(dialog, &dialog_rect);
        GetClientRect(GetParent(dialog), &parent_rect);
        parent_center.x = parent_rect.left +
            (parent_rect.right - parent_rect.left) / 2;
        parent_center.y = parent_rect.top +
            (parent_rect.bottom - parent_rect.top) / 2;
        ClientToScreen(GetParent(dialog), &parent_center);
        SetWindowPos(
            dialog,
            0,
            parent_center.x + (dialog_rect.left - dialog_rect.right) / 2,
            parent_center.y + (dialog_rect.top - dialog_rect.bottom) / 2,
            dialog_rect.right - dialog_rect.left,
            dialog_rect.bottom - dialog_rect.top,
            4);

        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog,
            kGuideBookIndexList,
            dialog_unit_width,
            dialog_unit_height);
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog,
            kGuideBookClose,
            dialog_unit_width,
            dialog_unit_height);
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog,
            0x12d,
            dialog_unit_width,
            dialog_unit_height);

        SendDlgItemMessageA(
            dialog,
            kGuideBookIndexList,
            0x30,
            (unsigned int)g_optionMenuFont_004390d4_00405320,
            0);
        for (page_index = 0; page_index < 73; ++page_index) {
            LoadStringA(
                g_resourceModule,
                page_index + 2000,
                page_title,
                30);
            SendDlgItemMessageA(
                dialog,
                kGuideBookIndexList,
                0x180,
                0,
                (long)page_title);
        }
        SetWindowTextA(dialog, g_guideBookIndexTitle_0043962c);
        SendDlgItemMessageA(
            dialog,
            kGuideBookIndexList,
            0x186,
            g_guideBookCurrentPage_0043b5a0,
            0);

        state = new GuideBookIndexDialogState_0040ae50_Proposal;
        if (state == 0) {
            MessageBoxA(
                GetParent(dialog),
                g_guideBookAllocationFailure_00439068,
                g_guideBookDialogCaption_004395fc,
                0);
            PostQuitMessage(0);
            return 0;
        }

        state->close_up.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603,
            0x2826);
        state->close_down.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603,
            0x2827);
        state->cancel_up.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603,
            0x2828);
        state->cancel_down.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603,
            0x2829);

        OtResizeControl_RealCpp(
            dialog,
            kGuideBookClose,
            state->close_up.width,
            state->close_up.height);
        OtResizeControl_RealCpp(
            dialog,
            0x12d,
            state->cancel_up.width,
            state->cancel_up.height);
        SetWindowLongA(dialog, 8, (long)state);
        SetFocus(GetDlgItem(dialog, kGuideBookClose));
        SendMessageA(dialog, 0x401, kGuideBookClose, 0);
        return 0;
    }

    case 0x111:
        switch (wparam & 0xffff) {
        case kGuideBookClose:
            g_guideBookCurrentPage_0043b5a0 = (int)SendDlgItemMessageA(
                dialog,
                kGuideBookIndexList,
                0x188,
                0,
                0);
            EndDialog(dialog, 1);
            break;

        case 0x12d:
            EndDialog(dialog, 1);
            break;
        }
        return 1;

    case 0x136: {
        OtGuideHandle dc = (OtGuideHandle)wparam;
        SetBkMode(dc, 1);
        SetTextColor(dc, 0);
        SelectObject(dc, g_optionMenuFont_004390d4_00405320);
        return (long)g_sharedDialogBackgroundBrush_004390c0;
    }

    case 0x138: {
        OtGuideHandle dc = (OtGuideHandle)wparam;
        SetBkMode(dc, 1);
        SetTextColor(dc, 0);
        SelectObject(dc, g_dialogFont_004390d8_00405320);
        return (long)g_sharedDialogBackgroundBrush_004390c0;
    }

    case 0x3b9:
        return 1;
    }

    return 0;
}

#pragma optimize("", on)

#undef OtBlitGuideBookBitmap_Proposal

// Product semantic recovery for OtInitTrailEventDialog @ 0x00422120.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This Product source must be compiled with 32-bit MSVC."
#endif

#include "../graphics/positioned_bitmap_descriptor_state.h"

typedef void* OtHandle_00422120;
typedef const char* OtResourceId_00422120;

struct OtPoint_00422120 {
    long x;
    long y;
};

struct OtRect_00422120 {
    long left;
    long top;
    long right;
    long bottom;

    long Height() const
    {
        return bottom - top;
    }
};

extern "C" __declspec(dllimport) unsigned int __stdcall GetDialogBaseUnits();
extern "C" __declspec(dllimport) OtHandle_00422120 __stdcall GetParent(
    OtHandle_00422120 window);
extern "C" __declspec(dllimport) int __stdcall GetWindowRect(
    OtHandle_00422120 window,
    OtRect_00422120* rect);
extern "C" __declspec(dllimport) int __stdcall GetClientRect(
    OtHandle_00422120 window,
    OtRect_00422120* rect);
extern "C" __declspec(dllimport) int __stdcall ClientToScreen(
    OtHandle_00422120 window,
    OtPoint_00422120* point);
extern "C" __declspec(dllimport) int __stdcall ScreenToClient(
    OtHandle_00422120 window,
    OtPoint_00422120* point);
extern "C" __declspec(dllimport) int __stdcall SetWindowPos(
    OtHandle_00422120 window,
    OtHandle_00422120 insert_after,
    int x,
    int y,
    int width,
    int height,
    unsigned int flags);
extern "C" __declspec(dllimport) OtHandle_00422120 __stdcall GetDlgItem(
    OtHandle_00422120 dialog,
    int control_id);
extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    OtHandle_00422120 module,
    unsigned int string_id,
    char* text,
    int text_capacity);
extern "C" __declspec(dllimport) int __stdcall SetWindowTextA(
    OtHandle_00422120 window,
    const char* text);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    OtHandle_00422120 window,
    const char* text,
    const char* caption,
    unsigned int type);
extern "C" __declspec(dllimport) void __stdcall PostQuitMessage(int exit_code);
extern "C" __declspec(dllimport) int __stdcall SetWindowLongA(
    OtHandle_00422120 window,
    int index,
    long value);
extern "C" __declspec(dllimport) OtHandle_00422120 __stdcall FindResourceA(
    OtHandle_00422120 module,
    OtResourceId_00422120 resource_id,
    OtResourceId_00422120 resource_type);
extern "C" __declspec(dllimport) OtHandle_00422120 __stdcall LoadResource(
    OtHandle_00422120 module,
    OtHandle_00422120 resource_info);
extern "C" __declspec(dllimport) void* __stdcall LockResource(
    OtHandle_00422120 resource);
extern "C" __declspec(dllimport) int __stdcall GlobalUnlock(
    OtHandle_00422120 memory);
extern "C" __declspec(dllimport) OtHandle_00422120 __stdcall GlobalFree(
    OtHandle_00422120 memory);
extern "C" __declspec(dllimport) int __stdcall sndPlaySoundA(
    const char* sound,
    unsigned int flags);
extern "C" __declspec(dllimport) OtHandle_00422120 __stdcall SetFocus(
    OtHandle_00422120 window);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    OtHandle_00422120 window,
    unsigned int message,
    unsigned int wparam,
    long lparam);

#pragma comment(lib, "kernel32.lib")
#pragma comment(lib, "user32.lib")
#pragma comment(lib, "winmm.lib")

extern void* __cdecl operator new(unsigned int bytes);

extern "C" void __cdecl OtScaleWindowToDialogCoords_00401370_Product(
    OtHandle_00422120 parent,
    OtHandle_00422120 child,
    int width_scale,
    int height_scale);
extern "C" int __cdecl OtLoadSavedDialogPlacement_00401110_RealCpp(
    const char* section,
    OtRect_00422120* persisted_rect);
extern "C" void __cdecl
OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
    OtHandle_00422120 dialog,
    int control_id,
    int dialog_unit_width,
    int dialog_unit_height);
extern "C" void __cdecl OtResizeControl_RealCpp(
    OtHandle_00422120 dialog,
    int control_id,
    int width,
    int height);

extern "C" void __cdecl OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();
extern "C" void __cdecl OtOpenMidiAudioFileMaskClosed_0000cd60_RealCpp(
    OtHandle_00422120 owner,
    const char* path);
extern "C" void __cdecl OtPlayMidiAudio_0000ced0_RealCpp(int restart);
extern "C" void __cdecl OtCloseWaveAudioDevice_0040d0a0_RealCpp();
extern "C" void __cdecl OtOpenWaveAudioFile_0000d110_RealCpp(
    OtHandle_00422120 owner,
    const char* path);
extern "C" void __cdecl OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" void* g_resourceModule;
extern "C" int g_cdMediaMode_00439108;
extern "C" int g_titleThemeEnabled_004390ec;
extern "C" int DAT_004390e8;

#pragma pack(push, 1)
struct TrailEventDialogRuntime_00422120 {
    short frame_kind;
    char reserved_02[4];
    unsigned int bitmap_resource_id;
    const char* embedded_sound_resource_id;
    int play_device_audio;
    unsigned int title_string_id;
    const char* body_text;
    char reserved_1a[8];
    short vertical_extension_lines;
};

struct TrailEventDialogBitmapState_00422120 {
    PositionedBitmapDescriptorState_0040ba40 yes_default;
    PositionedBitmapDescriptorState_0040ba40 yes_pressed;
    PositionedBitmapDescriptorState_0040ba40 no_default;
    PositionedBitmapDescriptorState_0040ba40 no_pressed;
    PositionedBitmapDescriptorState_0040ba40 ok_default;
    PositionedBitmapDescriptorState_0040ba40 ok_pressed;
    PositionedBitmapDescriptorState_0040ba40 guide_default;
    PositionedBitmapDescriptorState_0040ba40 guide_pressed;
    PositionedBitmapDescriptorState_0040ba40 event_frame;
};

struct TrailEventDialogSoundResource_00422120 {
    OtHandle_00422120 resource;
    const char* bytes;
};
#pragma pack(pop)

typedef char OtTrailEventDialogRuntimeLayoutCheck[
    sizeof(TrailEventDialogRuntime_00422120) == 0x24 ? 1 : -1];
typedef char OtPositionedBitmapLayoutCheck[
    sizeof(PositionedBitmapDescriptorState_0040ba40) == 0x28 ? 1 : -1];
typedef char OtTrailEventDialogBitmapStateLayoutCheck[
    sizeof(TrailEventDialogBitmapState_00422120) == 0x168 ? 1 : -1];

extern "C" TrailEventDialogRuntime_00422120
    g_trailEventDialogRuntime_00422120 = { 0 };
extern "C" TrailEventDialogSoundResource_00422120
    g_trailEventDialogSoundResource_00422120 = { 0 };

extern "C" const char g_trailEventDialogPositionKey_00422120[] =
    "Event Dialog";
extern "C" const char g_trailEventDialogAllocationError_00422120[] =
    "Can't allocate local memory.";
extern "C" const char g_trailEventDialogAllocationCaption_00422120[] =
    "Trail Divides";
extern "C" const char g_trailEventDirgeMidiPath_00422120[] = "dirge.mid";
extern "C" const char g_trailEventBurialMidiPath_00422120[] = "bury.mid";

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" void __cdecl OtInitTrailEventDialog_00422120_RealCpp(
    OtHandle_00422120 dialog)
{
    char title[152];
    OtRect_00422120 saved_rect;
    OtRect_00422120 parent_client_rect;
    OtPoint_00422120 parent_center;
    OtRect_00422120 dialog_rect;
    OtRect_00422120 control_rect;

    register OtHandle_00422120 active_dialog = dialog;
    register unsigned int dialog_unit_width;
    register unsigned int dialog_unit_height;
    dialog_unit_width = static_cast<unsigned short>(GetDialogBaseUnits());
    dialog_unit_height = static_cast<unsigned short>(
        GetDialogBaseUnits() >> 16);

    OtScaleWindowToDialogCoords_00401370_Product(
        GetParent(active_dialog),
        active_dialog,
        dialog_unit_width,
        dialog_unit_height);

    GetWindowRect(active_dialog, &dialog_rect);
    if (OtLoadSavedDialogPlacement_00401110_RealCpp(
            g_trailEventDialogPositionKey_00422120,
            &saved_rect) == 0) {
        GetClientRect(GetParent(active_dialog), &parent_client_rect);
        parent_center.x = parent_client_rect.left +
            (parent_client_rect.right - parent_client_rect.left) / 2;
        parent_center.y = parent_client_rect.top +
            (parent_client_rect.bottom - parent_client_rect.top) / 2;
        ClientToScreen(GetParent(active_dialog), &parent_center);
        SetWindowPos(
            active_dialog,
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
            active_dialog,
            0,
            saved_rect.left,
            saved_rect.top,
            dialog_rect.right - dialog_rect.left,
            dialog_rect.bottom - dialog_rect.top,
            4);
    }

    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        active_dialog,
        0x12c1,
        dialog_unit_width,
        dialog_unit_height);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        active_dialog,
        300,
        dialog_unit_width,
        dialog_unit_height);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        active_dialog,
        0x13a,
        dialog_unit_width,
        dialog_unit_height);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        active_dialog,
        0x134,
        dialog_unit_width,
        dialog_unit_height);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        active_dialog,
        0x135,
        dialog_unit_width,
        dialog_unit_height);

    if (g_trailEventDialogRuntime_00422120.vertical_extension_lines > 0) {
        GetWindowRect(active_dialog, &dialog_rect);
        dialog_rect.bottom +=
            g_trailEventDialogRuntime_00422120.vertical_extension_lines * 16;
        SetWindowPos(
            active_dialog,
            0,
            dialog_rect.left,
            dialog_rect.top,
            dialog_rect.right - dialog_rect.left,
            dialog_rect.bottom - dialog_rect.top,
            4);

        GetClientRect(active_dialog, &dialog_rect);
        GetWindowRect(GetDlgItem(active_dialog, 300), &control_rect);
        ScreenToClient(
            active_dialog,
            reinterpret_cast<OtPoint_00422120*>(&control_rect.left));
        ScreenToClient(
            active_dialog,
            reinterpret_cast<OtPoint_00422120*>(&control_rect.right));

        int button_height = control_rect.bottom - control_rect.top;
        unsigned int window_position_flags = 4;
        control_rect.top =
            dialog_rect.Height() - button_height - 10;
        control_rect.bottom = control_rect.top + button_height;
        SetWindowPos(
            GetDlgItem(active_dialog, 300),
            0,
            control_rect.left,
            control_rect.top,
            control_rect.right - control_rect.left,
            control_rect.bottom - control_rect.top,
            window_position_flags);

        GetWindowRect(GetDlgItem(active_dialog, 0x12c1), &control_rect);
        ScreenToClient(
            active_dialog,
            reinterpret_cast<OtPoint_00422120*>(&control_rect.left));
        ScreenToClient(
            active_dialog,
            reinterpret_cast<OtPoint_00422120*>(&control_rect.right));
        control_rect.bottom =
            dialog_rect.Height() - button_height - 15;
        SetWindowPos(
            GetDlgItem(active_dialog, 0x12c1),
            0,
            control_rect.left,
            control_rect.top,
            control_rect.right - control_rect.left,
            control_rect.bottom - control_rect.top,
            window_position_flags);
    }

    LoadStringA(
        g_applicationModule_00405a40_20260603,
        g_trailEventDialogRuntime_00422120.title_string_id,
        title,
        150);
    SetWindowTextA(active_dialog, title);
    SetWindowTextA(
        GetDlgItem(active_dialog, 0x12c1),
        g_trailEventDialogRuntime_00422120.body_text);

    TrailEventDialogBitmapState_00422120* bitmaps =
        new TrailEventDialogBitmapState_00422120;
    if (bitmaps == 0) {
        MessageBoxA(
            GetParent(active_dialog),
            g_trailEventDialogAllocationError_00422120,
            g_trailEventDialogAllocationCaption_00422120,
            0);
        PostQuitMessage(0);
    }

    bitmaps->yes_default.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        g_applicationModule_00405a40_20260603,
        0x2849);
    bitmaps->yes_pressed.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        g_applicationModule_00405a40_20260603,
        0x284a);
    bitmaps->no_default.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        g_applicationModule_00405a40_20260603,
        0x284b);
    bitmaps->no_pressed.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        g_applicationModule_00405a40_20260603,
        0x284c);
    bitmaps->ok_default.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        g_applicationModule_00405a40_20260603,
        0x2826);
    bitmaps->ok_pressed.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        g_applicationModule_00405a40_20260603,
        0x2827);
    bitmaps->guide_default.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        g_applicationModule_00405a40_20260603,
        0x2836);
    bitmaps->guide_pressed.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        g_applicationModule_00405a40_20260603,
        0x2837);
    if (g_trailEventDialogRuntime_00422120.frame_kind == 1) {
        bitmaps->event_frame.
            OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                g_applicationModule_00405a40_20260603,
                0x12c3);
    } else {
        bitmaps->event_frame.
            OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                g_applicationModule_00405a40_20260603,
                0x12c0);
    }

    bitmaps->event_frame.OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
        g_resourceModule,
        static_cast<short>(
            g_trailEventDialogRuntime_00422120.bitmap_resource_id),
        0,
        0,
        0,
        0);

    SetWindowLongA(active_dialog, 8, reinterpret_cast<long>(bitmaps));
    OtResizeControl_RealCpp(
        active_dialog,
        300,
        bitmaps->ok_default.width,
        bitmaps->ok_default.height);
    OtResizeControl_RealCpp(
        active_dialog,
        0x13a,
        bitmaps->guide_default.width,
        bitmaps->guide_default.height);
    OtResizeControl_RealCpp(
        active_dialog,
        0x134,
        bitmaps->yes_default.width,
        bitmaps->yes_default.height);
    OtResizeControl_RealCpp(
        active_dialog,
        0x135,
        bitmaps->no_default.width,
        bitmaps->no_default.height);

    if (g_titleThemeEnabled_004390ec != 0 &&
        g_trailEventDialogRuntime_00422120.play_device_audio != 0) {
        if (g_cdMediaMode_00439108 != 0) {
            OtCloseWaveAudioDevice_0040d0a0_RealCpp();
            g_trailEventDialogSoundResource_00422120.resource = 0;
            if (g_trailEventDialogRuntime_00422120.frame_kind == 1) {
                LoadStringA(g_applicationModule_00405a40_20260603, 0x4ba, title, 0x13);
            } else {
                LoadStringA(g_applicationModule_00405a40_20260603, 0x4bb, title, 0x13);
            }
            OtOpenWaveAudioFile_0000d110_RealCpp(active_dialog, title);
            OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();
        } else {
            OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();
            g_trailEventDialogSoundResource_00422120.resource = 0;
            if (g_trailEventDialogRuntime_00422120.frame_kind == 1) {
                OtOpenMidiAudioFileMaskClosed_0000cd60_RealCpp(
                    active_dialog,
                    g_trailEventDirgeMidiPath_00422120);
            } else {
                OtOpenMidiAudioFileMaskClosed_0000cd60_RealCpp(
                    active_dialog,
                    g_trailEventBurialMidiPath_00422120);
            }
            OtPlayMidiAudio_0000ced0_RealCpp(0);
        }
    } else if (DAT_004390e8 != 0 &&
               g_trailEventDialogRuntime_00422120.embedded_sound_resource_id !=
                   0) {
        sndPlaySoundA(0, 0);
        g_trailEventDialogSoundResource_00422120.resource = LoadResource(
            g_applicationModule_00405a40_20260603,
            FindResourceA(
                g_applicationModule_00405a40_20260603,
                g_trailEventDialogRuntime_00422120.embedded_sound_resource_id,
                reinterpret_cast<OtResourceId_00422120>(10)));
        if (g_trailEventDialogSoundResource_00422120.resource != 0) {
            g_trailEventDialogSoundResource_00422120.bytes =
                static_cast<const char*>(LockResource(
                    g_trailEventDialogSoundResource_00422120.resource));
            sndPlaySoundA(g_trailEventDialogSoundResource_00422120.bytes, 5);
        }
    } else {
        g_trailEventDialogSoundResource_00422120.resource = 0;
    }

    SetFocus(GetDlgItem(active_dialog, 300));
    SendMessageA(active_dialog, 0x401, 300, 0);
}

PositionedBitmapDescriptorState_0040ba40::
    PositionedBitmapDescriptorState_0040ba40()
{
    bitmap_info_handle = 0;
    indexed_pixels_handle = 0;
    bitmap_info = 0;
    indexed_pixels = 0;
}

PositionedBitmapDescriptorState_0040ba40::
    ~PositionedBitmapDescriptorState_0040ba40()
{
    if (bitmap_info_handle != 0) {
        GlobalUnlock(bitmap_info_handle);
        GlobalFree(bitmap_info_handle);
        bitmap_info_handle = 0;
        bitmap_info = 0;
    }
    if (indexed_pixels_handle != 0) {
        GlobalUnlock(indexed_pixels_handle);
        GlobalFree(indexed_pixels_handle);
        indexed_pixels_handle = 0;
        indexed_pixels = 0;
    }
}

#pragma optimize("", on)

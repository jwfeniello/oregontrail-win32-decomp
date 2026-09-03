// Product semantic recovery for OtInitWelcomeDialog @ 0x00415d30.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This recovery source must be compiled with 32-bit MSVC."
#endif

typedef void* OtHandle_00415d30;

struct OtRect_00415d30 {
    long left;
    long top;
    long right;
    long bottom;

    long Width() const
    {
        return right - left;
    }

    long Height() const
    {
        return bottom - top;
    }
};

extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    OtHandle_00415d30 window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) OtHandle_00415d30 __stdcall GetParent(
    OtHandle_00415d30 window);
extern "C" __declspec(dllimport) int __stdcall GetClientRect(
    OtHandle_00415d30 window,
    OtRect_00415d30* rect);
extern "C" __declspec(dllimport) unsigned int __stdcall GetDialogBaseUnits();
extern "C" __declspec(dllimport) int __stdcall SetWindowPos(
    OtHandle_00415d30 window,
    OtHandle_00415d30 insert_after,
    int x,
    int y,
    int width,
    int height,
    unsigned int flags);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    OtHandle_00415d30 window,
    const char* text,
    const char* caption,
    unsigned int type);
extern "C" __declspec(dllimport) void __stdcall PostQuitMessage(int exit_code);
extern "C" __declspec(dllimport) int __stdcall SetWindowLongA(
    OtHandle_00415d30 window,
    int index,
    long value);
extern "C" __declspec(dllimport) OtHandle_00415d30 __stdcall GetDlgItem(
    OtHandle_00415d30 dialog,
    int control_id);
extern "C" __declspec(dllimport) OtHandle_00415d30 __stdcall SetFocus(
    OtHandle_00415d30 window);

#pragma comment(lib, "user32.lib")

extern void* __cdecl operator new(unsigned int bytes);

extern "C" void __cdecl
OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
    OtHandle_00415d30 dialog,
    int control_id,
    int dialog_unit_width,
    int dialog_unit_height);
extern "C" void __cdecl OtResizeControl_RealCpp(
    OtHandle_00415d30 dialog,
    int control_id,
    int width,
    int height);

extern "C" void* g_optionMenuFont_004390d4_00405320;
extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" void* g_resourceModule;
extern "C" int g_cdMediaMode_00439108;

#pragma pack(push, 1)
struct PositionedBitmapDescriptorState_0040ba40 {
    OtHandle_00415d30 bitmap_info_handle;
    OtHandle_00415d30 indexed_pixels_handle;
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
        void* module,
        short descriptor_id);
};

struct WelcomeDialogBitmapState_00415d30 {
    PositionedBitmapDescriptorState_0040ba40 intro_first;
    PositionedBitmapDescriptorState_0040ba40 intro_second;
    PositionedBitmapDescriptorState_0040ba40 intro_third;
    PositionedBitmapDescriptorState_0040ba40 intro_fourth;
    PositionedBitmapDescriptorState_0040ba40 continue_default;
    PositionedBitmapDescriptorState_0040ba40 continue_pressed;
    PositionedBitmapDescriptorState_0040ba40 back_default;
    PositionedBitmapDescriptorState_0040ba40 back_pressed;
    PositionedBitmapDescriptorState_0040ba40 welcome_frame;
};
#pragma pack(pop)

typedef char OtWelcomePositionedBitmapLayoutCheck[
    sizeof(PositionedBitmapDescriptorState_0040ba40) == 0x28 ? 1 : -1];
typedef char OtWelcomeBitmapStateLayoutCheck[
    sizeof(WelcomeDialogBitmapState_00415d30) == 0x168 ? 1 : -1];

extern "C" const char g_welcomeAllocationMessage_00415d30[] =
    "Unable to allocate dialog information.";
extern "C" const char g_welcomeAllocationCaption_00415d30[] =
    "WelcomeDlgProc";

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" void __cdecl OtInitWelcomeDialog_00415d30_RealCpp(
    OtHandle_00415d30 dialog)
{
    OtRect_00415d30 client_rect;
    register OtHandle_00415d30 active_dialog = dialog;
    register unsigned int dialog_unit_width;
    register unsigned int dialog_unit_height;
    register int dialog_left;
    register int dialog_top;

    SendMessageA(
        active_dialog,
        0x30,
        reinterpret_cast<unsigned int>(g_optionMenuFont_004390d4_00405320),
        1);
    GetClientRect(GetParent(active_dialog), &client_rect);

    dialog_unit_width = static_cast<unsigned short>(GetDialogBaseUnits());
    dialog_unit_height = static_cast<unsigned short>(
        GetDialogBaseUnits() >> 16);
    dialog_left = client_rect.left + 10;
    dialog_top = client_rect.top + 10;
    SetWindowPos(
        active_dialog,
        0,
        dialog_left,
        dialog_top,
        client_rect.Width() - 20,
        client_rect.Height() - 20,
        4);
    GetClientRect(active_dialog, &client_rect);

    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        active_dialog, 0x4b3, dialog_unit_width, dialog_unit_height);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        active_dialog, 0x4b4, dialog_unit_width, dialog_unit_height);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        active_dialog, 0x4b5, dialog_unit_width, dialog_unit_height);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        active_dialog, 0x4b6, dialog_unit_width, dialog_unit_height);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        active_dialog, 0x4b7, dialog_unit_width, dialog_unit_height);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        active_dialog, 0x132, dialog_unit_width, dialog_unit_height);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        active_dialog, 0x133, dialog_unit_width, dialog_unit_height);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        active_dialog, 0x12c, dialog_unit_width, dialog_unit_height);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        active_dialog, 0x12d, dialog_unit_width, dialog_unit_height);

    WelcomeDialogBitmapState_00415d30* bitmaps =
        new WelcomeDialogBitmapState_00415d30;
    if (bitmaps == 0) {
        MessageBoxA(
            GetParent(active_dialog),
            g_welcomeAllocationMessage_00415d30,
            g_welcomeAllocationCaption_00415d30,
            0);
        PostQuitMessage(0);
        return;
    }

    if (g_cdMediaMode_00439108 != 0) {
        bitmaps->intro_first.
            OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                g_applicationModule_00405a40_20260603, 0x282c);
        bitmaps->intro_second.
            OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                g_applicationModule_00405a40_20260603, 0x282d);
        bitmaps->intro_third.
            OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                g_applicationModule_00405a40_20260603, 0x282e);
        bitmaps->intro_fourth.
            OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
                g_applicationModule_00405a40_20260603, 0x282f);
        OtResizeControl_RealCpp(
            active_dialog,
            0x132,
            bitmaps->intro_first.width,
            bitmaps->intro_first.height);
        OtResizeControl_RealCpp(
            active_dialog,
            0x133,
            bitmaps->intro_third.width,
            bitmaps->intro_third.height);
    }

    bitmaps->continue_default.
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603, 0x2826);
    bitmaps->continue_pressed.
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603, 0x2827);
    bitmaps->back_default.
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603, 0x2828);
    bitmaps->back_pressed.
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603, 0x2829);
    bitmaps->welcome_frame.
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_resourceModule, 0x4b1);

    SetWindowLongA(active_dialog, 8, reinterpret_cast<long>(bitmaps));
    OtResizeControl_RealCpp(
        active_dialog,
        0x12c,
        bitmaps->continue_default.width,
        bitmaps->continue_default.height);
    OtResizeControl_RealCpp(
        active_dialog,
        0x12d,
        bitmaps->back_default.width,
        bitmaps->back_default.height);
    SetFocus(GetDlgItem(active_dialog, 0x12c));
    SendMessageA(active_dialog, 0x401, 0x12c, 0);
}

#pragma optimize("", on)

// Product semantic recovery for OtInitWhoAmIDialog @ 0x00429650.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This recovery source must be compiled with 32-bit MSVC."
#endif

typedef void* OtHandle_00429650;

struct OtRect_00429650 {
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

extern "C" __declspec(dllimport) OtHandle_00429650 __stdcall GetParent(
    OtHandle_00429650 window);
extern "C" __declspec(dllimport) int __stdcall GetClientRect(
    OtHandle_00429650 window,
    OtRect_00429650* rect);
extern "C" __declspec(dllimport) unsigned int __stdcall GetDialogBaseUnits();
extern "C" __declspec(dllimport) int __stdcall SetWindowPos(
    OtHandle_00429650 window,
    OtHandle_00429650 insert_after,
    int x,
    int y,
    int width,
    int height,
    unsigned int flags);
extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    OtHandle_00429650 module,
    unsigned int string_id,
    char* buffer,
    int buffer_length);
extern "C" __declspec(dllimport) OtHandle_00429650 __stdcall GetDlgItem(
    OtHandle_00429650 dialog,
    int control_id);
extern "C" __declspec(dllimport) int __stdcall SetWindowTextA(
    OtHandle_00429650 window,
    const char* text);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    OtHandle_00429650 window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall PostMessageA(
    OtHandle_00429650 window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
typedef int (__stdcall *OtPostMessageFunction_00429650)(
    OtHandle_00429650,
    unsigned int,
    unsigned int,
    long);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    OtHandle_00429650 window,
    const char* text,
    const char* caption,
    unsigned int type);
extern "C" __declspec(dllimport) void __stdcall PostQuitMessage(int exit_code);
extern "C" __declspec(dllimport) int __stdcall SetWindowLongA(
    OtHandle_00429650 window,
    int index,
    long value);
extern "C" __declspec(dllimport) OtHandle_00429650 __stdcall SetFocus(
    OtHandle_00429650 window);

#pragma comment(lib, "user32.lib")

extern void* __cdecl operator new(unsigned int bytes);
extern "C" void* __cdecl memset(void* destination, int value, unsigned int size);
#pragma intrinsic(memset)

extern "C" void __cdecl
OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
    OtHandle_00429650 dialog,
    int control_id,
    int dialog_unit_width,
    int dialog_unit_height);
extern "C" void __cdecl OtResizeControl_RealCpp(
    OtHandle_00429650 dialog,
    int control_id,
    int width,
    int height);

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" void* g_journeyState;

#pragma pack(push, 1)
struct PositionedBitmapDescriptorState_0040ba40 {
    OtHandle_00429650 bitmap_info_handle;
    OtHandle_00429650 indexed_pixels_handle;
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

struct WhoAmIDialogBitmapState_00429650 {
    PositionedBitmapDescriptorState_0040ba40 leader_name_default;
    PositionedBitmapDescriptorState_0040ba40 leader_name_pressed;
    PositionedBitmapDescriptorState_0040ba40 continue_default;
    PositionedBitmapDescriptorState_0040ba40 continue_pressed;
    PositionedBitmapDescriptorState_0040ba40 back_default;
    PositionedBitmapDescriptorState_0040ba40 back_pressed;
    PositionedBitmapDescriptorState_0040ba40 party_name_frame;
};

struct WhoAmIJourneyState_00429650 {
    char reserved_000[0xc0];
    char party_member_names[5][15];
};
#pragma pack(pop)

typedef char OtWhoAmIPositionedBitmapLayoutCheck[
    sizeof(PositionedBitmapDescriptorState_0040ba40) == 0x28 ? 1 : -1];
typedef char OtWhoAmIBitmapStateLayoutCheck[
    sizeof(WhoAmIDialogBitmapState_00429650) == 0x118 ? 1 : -1];

extern "C" const char g_welcomeAllocationMessage_00415d30[];
extern "C" const char g_whoAmIAllocationCaption_00429650[] =
    "WhoAmIDlgProc";

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" void __cdecl OtInitWhoAmIDialog_00429650_RealCpp(
    OtHandle_00429650 dialog)
{
    OtRect_00429650 client_rect;
    char member_label[100];
    register int dialog_unit_width;
    register int dialog_unit_height;
    int control_index;

    GetClientRect(GetParent(dialog), &client_rect);
    dialog_unit_width = static_cast<unsigned short>(GetDialogBaseUnits());
    dialog_unit_height = static_cast<unsigned short>(
        GetDialogBaseUnits() >> 16);
    int window_y = client_rect.top + 10;
    register int window_x = client_rect.left + 10;
    SetWindowPos(
        dialog,
        0,
        window_x,
        window_y,
        client_rect.Width() - 20,
        client_rect.Height() - 20,
        4);
    GetClientRect(dialog, &client_rect);

    for (control_index = 0x514; control_index <= 0x517; ++control_index) {
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog, control_index, dialog_unit_width, dialog_unit_height);
    }
    for (control_index = 0; control_index < 8; ++control_index) {
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog,
            control_index + 0x51f,
            dialog_unit_width,
            dialog_unit_height);
    }
    for (control_index = 0; control_index < 5; ++control_index) {
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog,
            control_index + 0x528,
            dialog_unit_width,
            dialog_unit_height);
    }
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog, 0x131, dialog_unit_width, dialog_unit_height);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog, 0x12c, dialog_unit_width, dialog_unit_height);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog, 0x12d, dialog_unit_width, dialog_unit_height);

    for (control_index = 0; control_index < 8; ++control_index) {
        memset(member_label, 0, sizeof(member_label));
        LoadStringA(
            reinterpret_cast<OtHandle_00429650>(g_applicationModule_00405a40_20260603),
            control_index + 0xa0,
            member_label,
            sizeof(member_label));
        SetWindowTextA(
            GetDlgItem(dialog, control_index + 0x51f),
            member_label);
    }

    SendMessageA(GetDlgItem(dialog, 0x51f), 0xf1, 1, 0);

    int party_index = 1;
    for (;;) {
        if (party_index >= 5) {
            break;
        }
        SetWindowTextA(
            GetDlgItem(dialog, party_index + 0x528),
            &reinterpret_cast<WhoAmIJourneyState_00429650*>(g_journeyState)->
                party_member_names[static_cast<short>(party_index)][0]);
        ++party_index;
    }

    register OtPostMessageFunction_00429650 post_message;
    int post_index = 0;
    post_message = PostMessageA;
    while (post_index < 5) {
        post_message(
            GetDlgItem(dialog, post_index + 0x528),
            0xc5,
            0xe,
            0);
        ++post_index;
    }

    WhoAmIDialogBitmapState_00429650* bitmaps =
        new WhoAmIDialogBitmapState_00429650;
    if (bitmaps == 0) {
        MessageBoxA(
            GetParent(dialog),
            g_welcomeAllocationMessage_00415d30,
            g_whoAmIAllocationCaption_00429650,
            0);
        PostQuitMessage(0);
        return;
    }

    bitmaps->leader_name_default.
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603, 0x2808);
    bitmaps->leader_name_pressed.
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603, 0x2809);
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
    bitmaps->party_name_frame.
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603, 0x519);

    SetWindowLongA(dialog, 8, reinterpret_cast<long>(bitmaps));
    OtResizeControl_RealCpp(
        dialog,
        0x12c,
        bitmaps->continue_default.width,
        bitmaps->continue_default.height);
    OtResizeControl_RealCpp(
        dialog,
        0x131,
        bitmaps->leader_name_default.width,
        bitmaps->leader_name_default.height);
    OtResizeControl_RealCpp(
        dialog,
        0x12d,
        bitmaps->back_default.width,
        bitmaps->back_default.height);
    SetFocus(GetDlgItem(dialog, 0x528));
}

#pragma optimize("", on)

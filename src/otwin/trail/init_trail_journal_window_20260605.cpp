// Product-tree semantic recovery of the trail-journal edit-window initializer
// at 0x0040fc00.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

typedef void* HGLOBAL_0040fc00;
typedef void* HMODULE_0040fc00;
typedef void* HMENU_0040fc00;
typedef void* HWND_0040fc00;
typedef void* HRSRC_0040fc00;
typedef const char* LPCSTR_0040fc00;
typedef long LPARAM_0040fc00;
typedef long LONG_0040fc00;
typedef unsigned int UINT_0040fc00;
typedef unsigned int WPARAM_0040fc00;

extern "C" __declspec(dllimport) HRSRC_0040fc00 __stdcall FindResourceA(
    HMODULE_0040fc00 module,
    LPCSTR_0040fc00 resource_name,
    LPCSTR_0040fc00 resource_type);
extern "C" __declspec(dllimport) HGLOBAL_0040fc00 __stdcall LoadResource(
    HMODULE_0040fc00 module,
    HRSRC_0040fc00 resource_info);
extern "C" __declspec(dllimport) void* __stdcall LockResource(HGLOBAL_0040fc00 resource);
extern "C" __declspec(dllimport) int __stdcall FreeResource(HGLOBAL_0040fc00 resource);
extern "C" __declspec(dllimport) void* __stdcall GlobalLock(HGLOBAL_0040fc00 handle);
extern "C" __declspec(dllimport) int __stdcall GlobalUnlock(HGLOBAL_0040fc00 handle);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    HWND_0040fc00 window,
    LPCSTR_0040fc00 text,
    LPCSTR_0040fc00 caption,
    unsigned int type);
extern "C" __declspec(dllimport) int __stdcall OpenClipboard(HWND_0040fc00 window);
extern "C" __declspec(dllimport) int __stdcall EmptyClipboard();
extern "C" __declspec(dllimport) int __stdcall CloseClipboard();
extern "C" __declspec(dllimport) LONG_0040fc00 __stdcall GetWindowLongA(
    HWND_0040fc00 window,
    int index);
extern "C" __declspec(dllimport) LONG_0040fc00 __stdcall SetWindowLongA(
    HWND_0040fc00 window,
    int index,
    LONG_0040fc00 value);
extern "C" __declspec(dllimport) HWND_0040fc00 __stdcall CreateWindowExA(
    unsigned long ex_style,
    LPCSTR_0040fc00 class_name,
    LPCSTR_0040fc00 window_name,
    unsigned long style,
    int x,
    int y,
    int width,
    int height,
    HWND_0040fc00 parent,
    HMENU_0040fc00 menu,
    HMODULE_0040fc00 instance,
    void* parameter);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    HWND_0040fc00 window,
    UINT_0040fc00 message,
    WPARAM_0040fc00 wparam,
    LPARAM_0040fc00 lparam);
extern "C" __declspec(dllimport) int __stdcall SetWindowTextA(
    HWND_0040fc00 window,
    LPCSTR_0040fc00 text);

#pragma comment(lib, "KERNEL32.LIB")
#pragma comment(lib, "USER32.LIB")

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" HWND_0040fc00 g_activeTextEditWindow;
extern "C" HGLOBAL_0040fc00 g_activeTextGlobalHandle_Product;
extern "C" void* g_dialogFont_004390d8_00405320;
extern "C" LONG_0040fc00 g_trailJournalPreviousWndProc_0040fc00;

#define g_trailJournalEditControl_0040fc00 g_activeTextEditWindow
#define g_trailJournalTextHandle_0040fc00 g_activeTextGlobalHandle_Product
#define g_trailJournalFont_0040fc00 g_dialogFont_004390d8_00405320

extern "C" int g_trailJournalTextLength_0040fc00 = 0;
extern "C" int g_trailJournalTextHeight_0040fc00 = 0;

extern "C" const char g_trailJournalEditClass_0040fc00[] = "EDIT";
extern "C" const char g_trailJournalLoadErrorText_0040fc00[] =
    "Couldn't load the trail journal resource";
extern "C" const char g_trailJournalCreateErrorText_0040fc00[] =
    "Couldn't create trail journal window";
extern "C" const char g_trailJournalErrorCaption_0040fc00[] =
    "LogClass constructor";

extern "C" long __stdcall OtTrailJournalEditWndProc_0040f870_RealCpp(
    HWND_0040fc00 window,
    UINT_0040fc00 message,
    WPARAM_0040fc00 wparam,
    LPARAM_0040fc00 lparam);

#pragma pack(push, 1)
struct TrailJournalDescriptor_0040fc00 {
    short control_id;
    short left;
    short top;
    short width;
    short height;
};

struct EditCaretState_0040feb0_37pct {
    HWND_0040fc00 edit_control;

    void OtMoveEditCaretToEndAlt19_0040feb0_37pct();
};

struct TrailJournalWindow_0040fc00_20260605 {
    HWND_0040fc00 edit_control;
    int text_length;
    LONG_0040fc00 edit_window_proc;
    int reserved_0c;
    int left;
    int top;
    int right;
    int bottom;

    TrailJournalWindow_0040fc00_20260605* OtInitTrailJournalWindow_20260605_RealCpp(
        HMODULE_0040fc00 module,
        HWND_0040fc00 parent,
        LPCSTR_0040fc00 descriptor_id);
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

TrailJournalWindow_0040fc00_20260605*
TrailJournalWindow_0040fc00_20260605::OtInitTrailJournalWindow_20260605_RealCpp(
    HMODULE_0040fc00 module,
    HWND_0040fc00 parent,
    LPCSTR_0040fc00 descriptor_id)
{
    register HMODULE_0040fc00 resource_module = module;
    register HWND_0040fc00 parent_window;
    register TrailJournalDescriptor_0040fc00* descriptor;

    HRSRC_0040fc00 resource_info = FindResourceA(
        resource_module,
        descriptor_id,
        (LPCSTR_0040fc00)0x07d5);
    register HGLOBAL_0040fc00 resource_handle =
        LoadResource(resource_module, resource_info);
    if (resource_handle == 0) {
        MessageBoxA(
            parent,
            g_trailJournalLoadErrorText_0040fc00,
            g_trailJournalErrorCaption_0040fc00,
            0);
        return this;
    }

    descriptor = (TrailJournalDescriptor_0040fc00*)LockResource(resource_handle);
    left = descriptor->left;
    top = descriptor->top;
    right = descriptor->left + descriptor->width;
    bottom = descriptor->top + descriptor->height;

    parent_window = parent;
    if (OpenClipboard(parent_window) != 0) {
        EmptyClipboard();
        CloseClipboard();
    }

    g_trailJournalTextHeight_0040fc00 = descriptor->height - 6;

    g_trailJournalEditControl_0040fc00 =
        (edit_control = CreateWindowExA(
            0,
            g_trailJournalEditClass_0040fc00,
            0,
            0x40201044ul,
            descriptor->left + 3,
            descriptor->top + 3,
            descriptor->width - 6,
            g_trailJournalTextHeight_0040fc00,
            parent_window,
            (HMENU_0040fc00)(int)descriptor->control_id,
            (HMODULE_0040fc00)g_applicationModule_00405a40_20260603,
            0));
    if (edit_control == 0) {
        MessageBoxA(
            parent_window,
            g_trailJournalCreateErrorText_0040fc00,
            g_trailJournalErrorCaption_0040fc00,
            0);
        FreeResource(resource_handle);
        return this;
    } else {
        SendMessageA(
            edit_control,
            0x30,
            (WPARAM_0040fc00)g_trailJournalFont_0040fc00,
            0);

        LPCSTR_0040fc00 text =
            (LPCSTR_0040fc00)GlobalLock(g_trailJournalTextHandle_0040fc00);
        SetWindowTextA(edit_control, text);

        text_length = SendMessageA(edit_control, 0x00bd, 0, 0);
        g_trailJournalTextLength_0040fc00 = text_length;

        GlobalUnlock(g_trailJournalTextHandle_0040fc00);

        SendMessageA(edit_control, 0x00c5, 0x7cff, 0);

        g_trailJournalPreviousWndProc_0040fc00 = GetWindowLongA(edit_control, -4);
        edit_window_proc =
            (LONG_0040fc00)OtTrailJournalEditWndProc_0040f870_RealCpp;
        SetWindowLongA(
            edit_control,
            -4,
            (LONG_0040fc00)OtTrailJournalEditWndProc_0040f870_RealCpp);

        reinterpret_cast<EditCaretState_0040feb0_37pct*>(this)->
            OtMoveEditCaretToEndAlt19_0040feb0_37pct();
    }
    FreeResource(resource_handle);
    return this;
}

#pragma optimize("", on)

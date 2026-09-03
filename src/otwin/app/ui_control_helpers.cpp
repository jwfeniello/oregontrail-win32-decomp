// Small USER32 control helpers recovered from Oregon32.exe.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "app_runtime.h"

extern "C" __declspec(dllimport) int __stdcall IsWindowEnabled(void*);
extern "C" __declspec(dllimport) int __stdcall EnableWindow(void*, int);
extern "C" __declspec(dllimport) void* __stdcall GetDlgItem(void*, int);
extern "C" __declspec(dllimport) int __stdcall ShowWindow(void*, int);

#pragma comment(lib, "user32.lib")

#pragma pack(push, 1)
struct EditCaretState_0040feb0_37pct {
    void* edit_control;

    void OtMoveEditCaretToEndAlt19_0040feb0_37pct();
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" void __stdcall OtSwapVisiblePaceButtonAlt5_0042a510_37pct(
    void* dialog,
    int old_button_index,
    int new_button_index)
{
    void* dialog_window = dialog;

    ShowWindow(
        GetDlgItem(dialog_window, old_button_index + 0x0fde),
        0);
    ShowWindow(
        GetDlgItem(dialog_window, new_button_index + 0x0fde),
        5);
}

extern "C" void __stdcall OtSwapVisibleRationButtonAlt5_0042a550_37pct(
    void* dialog,
    int old_button_index,
    int new_button_index)
{
    void* (__stdcall *get_dlg_item)(void*, int) = GetDlgItem;
    void* dialog_window = dialog;

    ShowWindow(
        get_dlg_item(dialog_window, old_button_index + 0x0fd7),
        0);
    ShowWindow(
        get_dlg_item(dialog_window, new_button_index + 0x0fd7),
        5);
}

void EditCaretState_0040feb0_37pct::OtMoveEditCaretToEndAlt19_0040feb0_37pct()
{
    int text_length = GetWindowTextLengthA(edit_control);

    SendMessageA(
        edit_control,
        0x00b1,
        static_cast<unsigned int>(text_length),
        text_length);
    SendMessageA(edit_control, 0x00b7, 0, 0);
}

#pragma optimize("", on)

// Product-tree semantic recovery for Oregon32.exe RVA 0x00008f80.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

typedef void* HWND_00408f80;

extern "C" void* __cdecl memset(
    void* destination,
    int value,
    unsigned int count);
extern "C" unsigned int __cdecl strlen(const char* text);
extern "C" char* __cdecl _itoa(int value, char* text, int radix);

#pragma intrinsic(memset, strlen)

extern "C" __declspec(dllimport) unsigned int __stdcall GetDialogBaseUnits();
extern "C" __declspec(dllimport) HWND_00408f80 __stdcall GetDlgItem(
    HWND_00408f80 dialog,
    int control_id);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    HWND_00408f80 window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) long __stdcall SetWindowLongA(
    HWND_00408f80 window,
    int index,
    long value);
extern "C" __declspec(dllimport) int __stdcall ShowWindow(
    HWND_00408f80 window,
    int command);

extern "C" void* g_dialogFont_004390d8_00405320;

extern "C" void __cdecl OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
    HWND_00408f80 dialog,
    int control_id,
    int dialog_unit_width,
    int dialog_unit_height);

#pragma comment(lib, "user32.lib")

#pragma optimize("s", off)
#pragma optimize("t", on)
#pragma code_seg(".otsem")

extern "C" void __cdecl OtLayoutGeneralStoreControls_00408f80_RealCpp(
    HWND_00408f80 dialog,
    int show_ok_button)
{
    char limit_text[10];
    int dialog_unit_width;
    int dialog_unit_height;
    int item_index;

    dialog_unit_width = (unsigned short)GetDialogBaseUnits();
    dialog_unit_height = (unsigned short)(GetDialogBaseUnits() >> 16);

    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog, 0x5dc, dialog_unit_width, dialog_unit_height);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog, 0x5f0, dialog_unit_width, dialog_unit_height);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog, 0x5f1, dialog_unit_width, dialog_unit_height);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog, 0x5f2, dialog_unit_width, dialog_unit_height);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog, 0x5f3, dialog_unit_width, dialog_unit_height);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog, 0x5f4, dialog_unit_width, dialog_unit_height);

    for (item_index = 0; item_index < 7; ++item_index) {
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog,
            item_index + 0x5fa,
            dialog_unit_width,
            dialog_unit_height);
        SendMessageA(
            GetDlgItem(dialog, item_index + 0x5fa),
            0x30,
            (unsigned int)g_dialogFont_004390d8_00405320,
            0);
        SetWindowLongA(
            GetDlgItem(dialog, item_index + 0x5fa),
            -16,
            0x50800802L);

        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog,
            item_index + 0x60e,
            dialog_unit_width,
            dialog_unit_height);
        SendMessageA(
            GetDlgItem(dialog, item_index + 0x60e),
            0x30,
            (unsigned int)g_dialogFont_004390d8_00405320,
            0);
        SetWindowLongA(
            GetDlgItem(dialog, item_index + 0x60e),
            -16,
            0x50800800L);

        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog,
            item_index + 0x618,
            dialog_unit_width,
            dialog_unit_height);
        SendMessageA(
            GetDlgItem(dialog, item_index + 0x618),
            0x30,
            (unsigned int)g_dialogFont_004390d8_00405320,
            0);
        SetWindowLongA(
            GetDlgItem(dialog, item_index + 0x618),
            -16,
            0x50800802L);

        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog,
            item_index + 0x622,
            dialog_unit_width,
            dialog_unit_height);
        SendMessageA(
            GetDlgItem(dialog, item_index + 0x622),
            0x30,
            (unsigned int)g_dialogFont_004390d8_00405320,
            0);
        SetWindowLongA(
            GetDlgItem(dialog, item_index + 0x622),
            -16,
            0x50800802L);
    }

    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog, 0x604, dialog_unit_width, dialog_unit_height);
    SendMessageA(
        GetDlgItem(dialog, 0x604),
        0x30,
        (unsigned int)g_dialogFont_004390d8_00405320,
        0);
    memset(limit_text, 0, sizeof(limit_text));
    _itoa(20, limit_text, 10);
    SendMessageA(
        GetDlgItem(dialog, 0x604),
        0xc5,
        strlen(limit_text),
        0);

    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog, 0x605, dialog_unit_width, dialog_unit_height);
    SendMessageA(
        GetDlgItem(dialog, 0x605),
        0x30,
        (unsigned int)g_dialogFont_004390d8_00405320,
        0);
    memset(limit_text, 0, sizeof(limit_text));
    _itoa(50, limit_text, 10);
    SendMessageA(
        GetDlgItem(dialog, 0x605),
        0xc5,
        strlen(limit_text),
        0);

    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog, 0x606, dialog_unit_width, dialog_unit_height);
    SendMessageA(
        GetDlgItem(dialog, 0x606),
        0x30,
        (unsigned int)g_dialogFont_004390d8_00405320,
        0);
    memset(limit_text, 0, sizeof(limit_text));
    _itoa(100, limit_text, 10);
    SendMessageA(
        GetDlgItem(dialog, 0x606),
        0xc5,
        strlen(limit_text),
        0);

    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog, 0x607, dialog_unit_width, dialog_unit_height);
    SendMessageA(
        GetDlgItem(dialog, 0x607),
        0x30,
        (unsigned int)g_dialogFont_004390d8_00405320,
        0);
    memset(limit_text, 0, sizeof(limit_text));
    _itoa(3, limit_text, 10);
    SendMessageA(
        GetDlgItem(dialog, 0x607),
        0xc5,
        strlen(limit_text),
        0);

    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog, 0x608, dialog_unit_width, dialog_unit_height);
    SendMessageA(
        GetDlgItem(dialog, 0x608),
        0x30,
        (unsigned int)g_dialogFont_004390d8_00405320,
        0);
    memset(limit_text, 0, sizeof(limit_text));
    _itoa(3, limit_text, 10);
    SendMessageA(
        GetDlgItem(dialog, 0x608),
        0xc5,
        strlen(limit_text),
        0);

    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog, 0x609, dialog_unit_width, dialog_unit_height);
    SendMessageA(
        GetDlgItem(dialog, 0x609),
        0x30,
        (unsigned int)g_dialogFont_004390d8_00405320,
        0);
    memset(limit_text, 0, sizeof(limit_text));
    _itoa(3, limit_text, 10);
    SendMessageA(
        GetDlgItem(dialog, 0x609),
        0xc5,
        strlen(limit_text),
        0);

    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog, 0x60a, dialog_unit_width, dialog_unit_height);
    SendMessageA(
        GetDlgItem(dialog, 0x60a),
        0x30,
        (unsigned int)g_dialogFont_004390d8_00405320,
        0);
    memset(limit_text, 0, sizeof(limit_text));
    _itoa(2000, limit_text, 10);
    SendMessageA(
        GetDlgItem(dialog, 0x60a),
        0xc5,
        strlen(limit_text),
        0);

    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog, 0x62c, dialog_unit_width, dialog_unit_height);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog, 0x62d, dialog_unit_width, dialog_unit_height);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog, 0x62e, dialog_unit_width, dialog_unit_height);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog, 0x62f, dialog_unit_width, dialog_unit_height);

    if (show_ok_button != 0) {
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog, 0x131, dialog_unit_width, dialog_unit_height);
    } else {
        ShowWindow(GetDlgItem(dialog, 0x131), 0);
    }

    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog, 0x139, dialog_unit_width, dialog_unit_height);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog, 0x12d, dialog_unit_width, dialog_unit_height);
}

#pragma code_seg()
#pragma optimize("", on)

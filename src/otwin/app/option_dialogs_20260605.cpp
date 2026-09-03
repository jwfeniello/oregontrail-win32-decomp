// Semantic recovery for compact option dialog procedures at 0x00401f00/0x00402140.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include <stdlib.h>

#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "kernel32.lib")

extern "C" __declspec(dllimport) int __stdcall GetWindowRect(
    void* window,
    void* rect);
extern "C" __declspec(dllimport) void* __stdcall GetParent(void* window);
extern "C" __declspec(dllimport) int __stdcall GetClientRect(
    void* window,
    void* rect);
extern "C" __declspec(dllimport) int __stdcall ClientToScreen(
    void* window,
    void* point);
extern "C" __declspec(dllimport) int __stdcall SetWindowPos(
    void* window,
    void* insert_after,
    int x,
    int y,
    int cx,
    int cy,
    unsigned int flags);
extern "C" __declspec(dllimport) unsigned int __stdcall IsDlgButtonChecked(
    void* dialog,
    int id);
extern "C" __declspec(dllimport) int __stdcall CheckDlgButton(
    void* dialog,
    int id,
    unsigned int check);
extern "C" __declspec(dllimport) int __stdcall EndDialog(
    void* dialog,
    int result);
extern "C" __declspec(dllimport) void* __stdcall GetStockObject(int object);
extern "C" __declspec(dllimport) int __stdcall WritePrivateProfileStringA(
    const char* section,
    const char* key,
    const char* value,
    const char* file_name);

extern "C" int DAT_004390e0;
extern "C" int DAT_004390e4;
extern "C" const char* PTR_s_oregon_ini_004390dc;

extern "C" const char s_Game_Configuration_00439124[] = "Game Configuration";
extern "C" const char s_simulation_speed_00439138[] = "simulation speed";
extern "C" const char s_hunt_time_0043914c[] = "hunt time";

#pragma pack(push, 1)
struct OtPoint_20260605 {
    int x;
    int y;
};

struct OtRect_20260605 {
    int left;
    int top;
    int right;
    int bottom;
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" int __stdcall OtSimulationSpeedDialogProcA_00401f00(
    void* dialog,
    unsigned int message,
    unsigned int wparam,
    long)
{
    char value_text[2];
    OtPoint_20260605 center;
    OtRect_20260605 dialog_rect;
    OtRect_20260605 parent_rect;
    int value;

    switch (message) {
    case 0x0110:
        GetWindowRect(dialog, &dialog_rect);
        GetClientRect(GetParent(dialog), &parent_rect);
        center.x = parent_rect.left + (parent_rect.right - parent_rect.left) / 2;
        center.y = parent_rect.top + (parent_rect.bottom - parent_rect.top) / 2;
        ClientToScreen(GetParent(dialog), &center);
        SetWindowPos(
            dialog,
            0,
            center.x + (dialog_rect.left - dialog_rect.right) / 2,
            center.y + (dialog_rect.top - dialog_rect.bottom) / 2,
            dialog_rect.right - dialog_rect.left,
            dialog_rect.bottom - dialog_rect.top,
            4);

        if (DAT_004390e0 >= 8) {
            CheckDlgButton(dialog, 0x015e, 1);
            return 0;
        }

        if (DAT_004390e0 >= 4) {
            CheckDlgButton(dialog, 0x015f, 1);
            return 0;
        }

        CheckDlgButton(dialog, 0x0160, 1);
        return 0;

    case 0x0111:
        switch (wparam & 0xffff) {
        case 300:
            if (IsDlgButtonChecked(dialog, 0x015e) != 0) {
                value = 8;
            } else {
                value = (IsDlgButtonChecked(dialog, 0x015f) == 0) ? 2 : 4;
            }

            DAT_004390e0 = value;
            _itoa(value, value_text, 10);
            WritePrivateProfileStringA(
                s_Game_Configuration_00439124,
                s_simulation_speed_00439138,
                value_text,
                PTR_s_oregon_ini_004390dc);
            EndDialog(dialog, value);
            return 1;

        case 0x012d:
            EndDialog(dialog, 0);
            return 1;

        default:
            return 0;
        }

    case 0x0135:
    case 0x0136:
    case 0x0138:
        return (int)GetStockObject(0);

    default:
        return 0;
    }
}

extern "C" int __stdcall OtHuntTimeDialogProcA_00402140(
    void* dialog,
    unsigned int message,
    unsigned int wparam,
    long)
{
    OtPoint_20260605 center;
    OtRect_20260605 dialog_rect;
    char value_text[4];
    OtRect_20260605 parent_rect;
    int value;

    switch (message) {
    case 0x0110:
        GetWindowRect(dialog, &dialog_rect);
        GetClientRect(GetParent(dialog), &parent_rect);
        center.x = parent_rect.left + (parent_rect.right - parent_rect.left) / 2;
        center.y = parent_rect.top + (parent_rect.bottom - parent_rect.top) / 2;
        ClientToScreen(GetParent(dialog), &center);
        SetWindowPos(
            dialog,
            0,
            center.x + (dialog_rect.left - dialog_rect.right) / 2,
            center.y + (dialog_rect.top - dialog_rect.bottom) / 2,
            dialog_rect.right - dialog_rect.left,
            dialog_rect.bottom - dialog_rect.top,
            4);

        if (DAT_004390e4 >= 120) {
            CheckDlgButton(dialog, 0x0162, 1);
            return 1;
        }

        if (DAT_004390e4 >= 60) {
            CheckDlgButton(dialog, 0x0163, 1);
            return 1;
        }

        if (DAT_004390e4 >= 40) {
            CheckDlgButton(dialog, 0x0164, 1);
            return 1;
        }

        CheckDlgButton(dialog, 0x0165, 1);
        return 1;

    case 0x0111:
        switch (wparam & 0xffff) {
        case 300:
            if (IsDlgButtonChecked(dialog, 0x0162) != 0) {
                value = 120;
            } else if (IsDlgButtonChecked(dialog, 0x0163) != 0) {
                value = 60;
            } else {
                value = (IsDlgButtonChecked(dialog, 0x0164) == 0) ? 20 : 40;
            }

            DAT_004390e4 = value;
            _itoa(value, value_text, 10);
            WritePrivateProfileStringA(
                s_Game_Configuration_00439124,
                s_hunt_time_0043914c,
                value_text,
                PTR_s_oregon_ini_004390dc);
            EndDialog(dialog, value);
            return 1;

        case 0x012d:
            EndDialog(dialog, 0);
            return 1;

        default:
            return 0;
        }

    case 0x0135:
    case 0x0136:
    case 0x0138:
        return (int)GetStockObject(0);

    default:
        return 0;
    }
}

#pragma optimize("", on)

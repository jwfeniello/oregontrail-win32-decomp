// Standalone product promotion for the hunt-result dialog procedure at
// 0x00402d50. This is the accepted Alt14 source shape without a textual
// dependency on a recovery translation unit.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")

#pragma pack(push, 1)
struct OtRect_00002d50_20260604 {
    long left;
    long top;
    long right;
    long bottom;
};
#pragma pack(pop)

extern "C" __declspec(dllimport) int __stdcall GetWindowRect(
    void* window,
    OtRect_00002d50_20260604* rect);
extern "C" __declspec(dllimport) void* __stdcall GetDesktopWindow();
extern "C" __declspec(dllimport) int __stdcall SetWindowPos(
    void* window,
    void* insert_after,
    int x,
    int y,
    int width,
    int height,
    unsigned int flags);
extern "C" __declspec(dllimport) void* __stdcall GetDlgItem(
    void* dialog,
    int control_id);
extern "C" __declspec(dllimport) void* __stdcall SetFocus(void* window);
extern "C" __declspec(dllimport) int __stdcall EndDialog(
    void* dialog,
    int result);
extern "C" __declspec(dllimport) void* __stdcall GetStockObject(int object_id);

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" int __stdcall
OtHuntResultDialogProc_00002d50_20260604_HuntAlt14(
    void* dialog,
    unsigned int message,
    unsigned int wParam,
    long lParam)
{
    OtRect_00002d50_20260604 dialog_rect;
    OtRect_00002d50_20260604 desktop_rect;
    register int desktop_center_x;
    register int desktop_center_y;
    register int command;
    int control_id;

    switch (message) {
    case 0x110:
        GetWindowRect(dialog, &dialog_rect);
        GetWindowRect(GetDesktopWindow(), &desktop_rect);

        desktop_center_x =
            desktop_rect.left +
            ((desktop_rect.right - desktop_rect.left) / 2);
        desktop_center_y =
            desktop_rect.top +
            ((desktop_rect.bottom - desktop_rect.top) / 2);

        SetWindowPos(
            dialog,
            0,
            desktop_center_x -
                ((dialog_rect.right - dialog_rect.left) / 2),
            desktop_center_y -
                ((dialog_rect.bottom - dialog_rect.top) / 2),
            dialog_rect.right - dialog_rect.left,
            dialog_rect.bottom - dialog_rect.top,
            4);
        SetFocus(GetDlgItem(dialog, 0x134));
        return 0;

    case 0x111:
        command = (int)wParam;
        control_id = (unsigned short)command;
        switch (control_id) {
        case 0x12d:
            EndDialog(dialog, command);
            return 1;

        case 0x134:
        case 0x135:
            EndDialog(dialog, command);
            return 1;
        }
        return 0;

    case 0x136:
    case 0x138:
        return (int)GetStockObject(0);
    }

    return 0;
}

#pragma optimize("", on)

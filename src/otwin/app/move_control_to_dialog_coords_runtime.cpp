#include <windows.h>

#pragma comment(lib, "user32.lib")

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" void __cdecl OtMoveControlToDialogCoords_00401480_Product(
    HWND dialog,
    int control_id,
    int new_x,
    int new_y)
{
    if (!IsWindow(dialog)) {
        return;
    }

    if (!IsWindow(GetDlgItem(dialog, control_id))) {
        return;
    }

    RECT rect;
    GetWindowRect(GetDlgItem(dialog, control_id), &rect);
    ScreenToClient(dialog, reinterpret_cast<POINT*>(&rect.left));
    ScreenToClient(dialog, reinterpret_cast<POINT*>(&rect.right));

    const LONG width = rect.right - rect.left;
    const LONG height = rect.bottom - rect.top;
    rect.left = new_x;
    rect.top = new_y;
    rect.right = rect.left + width;
    rect.bottom = rect.top + height;

    SetWindowPos(
        GetDlgItem(dialog, control_id),
        0,
        new_x,
        new_y,
        rect.right - new_x,
        rect.bottom - new_y,
        SWP_NOZORDER);
}

#pragma optimize("", on)

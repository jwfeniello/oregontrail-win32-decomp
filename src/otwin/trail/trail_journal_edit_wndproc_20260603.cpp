// Product-tree semantic closure for FUN_0040f870_0000f870.
//
// This row is the trail-journal edit control subclass procedure installed by
// OtInitTrailJournalWindow, not Willamette arrival text layout.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

typedef void* HWND_0040f870;
typedef long LPARAM_0040f870;
typedef long LRESULT_0040f870;
typedef unsigned int UINT_0040f870;
typedef unsigned int WPARAM_0040f870;
typedef LRESULT_0040f870 (__stdcall *WNDPROC_0040f870)(
    HWND_0040f870 window,
    UINT_0040f870 message,
    WPARAM_0040f870 wparam,
    LPARAM_0040f870 lparam);

extern "C" __declspec(dllimport) LRESULT_0040f870 __stdcall SendMessageA(
    HWND_0040f870 window,
    UINT_0040f870 message,
    WPARAM_0040f870 wparam,
    LPARAM_0040f870 lparam);
extern "C" __declspec(dllimport) int __stdcall GetDlgCtrlID(
    HWND_0040f870 window);
extern "C" __declspec(dllimport) HWND_0040f870 __stdcall GetParent(
    HWND_0040f870 window);
extern "C" __declspec(dllimport) int __stdcall PostMessageA(
    HWND_0040f870 window,
    UINT_0040f870 message,
    WPARAM_0040f870 wparam,
    LPARAM_0040f870 lparam);
extern "C" __declspec(dllimport) int __stdcall IsWindow(
    HWND_0040f870 window);
extern "C" __declspec(dllimport) HWND_0040f870 __stdcall GetFocus();
extern "C" __declspec(dllimport) HWND_0040f870 __stdcall SetFocus(
    HWND_0040f870 window);
extern "C" __declspec(dllimport) LRESULT_0040f870 __stdcall CallWindowProcA(
    WNDPROC_0040f870 previous_proc,
    HWND_0040f870 window,
    UINT_0040f870 message,
    WPARAM_0040f870 wparam,
    LPARAM_0040f870 lparam);

#pragma comment(lib, "USER32.LIB")

extern "C" int g_trailJournalEditHasSelection_0040f870 = 0;
extern "C" int g_trailJournalEditSelectionDirty_0040f870 = 0;
extern "C" WNDPROC_0040f870 g_trailJournalPreviousWndProc_0040fc00 = 0;

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" LRESULT_0040f870 __stdcall
OtTrailJournalEditWndProc_0040f870_RealCpp(
    HWND_0040f870 window,
    UINT_0040f870 message,
    WPARAM_0040f870 wparam,
    LPARAM_0040f870 lparam)
{
    register UINT_0040f870 current_message = message;
    register HWND_0040f870 edit_window;
    UINT_0040f870 no_selection_notify_code;

    switch (current_message) {
    case 8:
        edit_window = window;
        if (SendMessageA(edit_window, 0x00b8, 0, 0) != 0) {
            unsigned int control_id;

            g_trailJournalEditHasSelection_0040f870 = 1;
            g_trailJournalEditSelectionDirty_0040f870 = 1;
            control_id =
                (unsigned short)GetDlgCtrlID(edit_window);
            PostMessageA(
                GetParent(edit_window),
                0x0111,
                control_id | 0x04020000,
                (LPARAM_0040f870)edit_window);
        } else {
            PostMessageA(
                GetParent(edit_window),
                0x0111,
                (no_selection_notify_code & 0xffff) | 0x02000000,
                (LPARAM_0040f870)edit_window);
        }
        break;

    case 0x0115:
        if (IsWindow((HWND_0040f870)lparam) == 0) {
            edit_window = GetFocus();
            if (edit_window != window) {
                SetFocus(window);
            }
        }
        break;
    }

    return CallWindowProcA(
        g_trailJournalPreviousWndProc_0040fc00,
        window,
        current_message,
        wparam,
        lparam);
}

#pragma optimize("", on)
